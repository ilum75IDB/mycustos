# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos preflight [--test-connection]": checks the prerequisites of a
# backup and suggests what to change. Read-only: it creates no file and no
# directory (the cnf isolation uses a temporary file, removed at the end).
# Sourced by bin/mycustos.
#
# When a problem can be fixed with a command, the hint is that command, ready
# to copy (cp, sed, printf on mycustos.conf, chmod, mkdir): it is printed,
# never run.
#
# With --test-connection it also checks the identity of the instance and its
# topology (core/target.sh, core/topology.sh). A SECONDARY is a warning: the
# backup would be skipped there.
#
# Exit codes: 0 no failure (warnings allowed), 3 a configuration problem,
# 4 an environment problem (command, directory, permission, MySQL server),
# 9 wrong or unsupported target. With several kinds, the first in this order.

PF_OK=0
PF_WARN=0
PF_FAIL_CONFIG=0
PF_FAIL_ENV=0
PF_FAIL_TARGET=0

cmd_preflight() {
  local test_connection=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --test-connection) test_connection=1 ;;
      *) die_usage cli.cmd_unknown_option preflight "$1" ;;
    esac
    shift
  done

  if ! mc_config_load; then
    if [ ! -f "$MC_CONFIG_FILE" ] || [ ! -r "$MC_CONFIG_FILE" ]; then
      _pf_missing_config
      return "$MC_EX_CONFIG"
    fi
    mc_config_print_errors
    exit "$MC_EX_CONFIG"
  fi
  say pf.header "${MC_CONF[instance]}"
  _pf_ok "$(mc_t pf.configuration "$MC_CONFIG_FILE")"

  local auth_ok=0
  _pf_check_auth && auth_ok=1
  _pf_check_dirs
  _pf_check_commands

  if [ "$test_connection" -eq 1 ]; then
    if [ "$auth_ok" -eq 1 ] && command -v mysql >/dev/null 2>&1; then
      _pf_check_server
    else
      _pf_fail env "$(mc_t pf.conn_skipped)"
    fi
  elif [ "${MC_CONF[engine]}" = auto ]; then
    _pf_ok "$(mc_t pf.engine_auto_later)" "$(mc_t pf.engine_auto_hint)"
  fi
  mc_auth_cleanup

  _pf_result
}

_pf_result() {
  msg ''
  say pf.result "$PF_OK" "$PF_WARN" "$((PF_FAIL_CONFIG + PF_FAIL_ENV + PF_FAIL_TARGET))"
  if [ "$PF_FAIL_CONFIG" -gt 0 ]; then return "$MC_EX_CONFIG"; fi
  if [ "$PF_FAIL_ENV" -gt 0 ]; then return "$MC_EX_ENVIRONMENT"; fi
  if [ "$PF_FAIL_TARGET" -gt 0 ]; then return "$MC_EX_TARGET"; fi
  return "$MC_EX_OK"
}

# No configuration file: the only check left is how to create it. The
# templates come with the installation, also when --home points elsewhere.
_pf_missing_config() {
  local example="${MYCUSTOS_MODULES%/bin/modules}/config/mycustos.conf.example" hints=()
  say pf.header '-'
  if [ -r "$example" ]; then
    hints+=("$(mc_t pf.hint_copy_example)" "cp -p -- $(_pf_q "$example") $(_pf_q "$MC_CONFIG_FILE")")
  fi
  if mc_is_implemented setup; then
    hints+=("$(mc_t pf.hint_setup)" "mycustos setup")
  fi
  _pf_fail config "$(mc_t pf.config_missing "$MC_CONFIG_FILE")" "${hints[@]}"
  _pf_result
}

# --- checks ------------------------------------------------------------------

_pf_check_auth() {
  local w e rc=0
  mc_auth_select || rc=$?
  if [ ${#MC_AUTH_WARNINGS[@]} -gt 0 ]; then
    for w in "${MC_AUTH_WARNINGS[@]}"; do _pf_warn "$w"; done
  fi
  if [ "$rc" -ne 0 ]; then
    for e in "${MC_AUTH_ERRORS[@]}"; do _pf_fail config "$e"; done
    _pf_hint_credentials
    return 1
  fi
  _pf_ok "$(mc_t pf.auth_ok "$MC_AUTH_DESC")"
}

# The credentials file is missing: create it from the template.
_pf_hint_credentials() {
  local cnf=${MC_CONF[auth_cnf]} example="${MYCUSTOS_MODULES%/bin/modules}/config/backup-credentials.conf.example"
  [ "${MC_CONF[auth_method]}" != login-path ] || return 0
  [ -n "$cnf" ] && [ ! -e "$cnf" ] && [ -r "$example" ] || return 0
  _pf_line '' "$(mc_t pf.hint_cnf_create)" \
    "(umask 077 && cp -- $(_pf_q "$example") $(_pf_q "$cnf"))"
}

_pf_check_dirs() {
  local key dir avail
  for key in data_dir logs_dir; do
    dir=${MC_CONF[$key]}
    if [ ! -d "$dir" ]; then
      _pf_fail env "$key: $(mc_t pf.dir_missing "$dir")" "$(mc_t pf.hint_mkdir "mkdir -p $dir")"
    elif [ ! -w "$dir" ] || [ ! -x "$dir" ]; then
      _pf_fail env "$key: $(mc_t pf.dir_not_writable "$(id -un)" "$dir")"
    else
      _pf_ok "$key: $dir"
    fi
  done
  # The INCR chain state and the lock live in config/.
  if [ -w "$MYCUSTOS_CONFIG" ] && [ -x "$MYCUSTOS_CONFIG" ]; then
    _pf_ok "$(mc_t pf.config_dir_ok "$MYCUSTOS_CONFIG")"
  else
    _pf_fail env "$(mc_t pf.config_dir_not_writable "$(id -un)" "$MYCUSTOS_CONFIG")" \
      "$(mc_t pf.config_dir_hint)"
  fi

  dir=${MC_CONF[data_dir]}
  if [ -d "$dir" ]; then
    avail=$(df -Pk -- "$dir" 2>/dev/null | awk 'NR == 2 { print $4 }')
    if [[ "$avail" =~ ^[0-9]+$ ]]; then
      _pf_ok "data_dir: $(mc_t pf.free_space "$((avail / 1048576))")"
    else
      _pf_warn "data_dir: $(mc_t pf.free_space_unknown "$dir")"
    fi
  fi
}

_pf_check_commands() {
  _pf_need tar "$(mc_t pf.need_tar)"
  _pf_need flock "$(mc_t pf.need_flock)"
  _pf_need_compressor
  _pf_need mysql "$(mc_t pf.need_mysql)"
  if [ "${MC_CONF[engine]}" != auto ]; then
    _pf_need "$(mc_engine_command "${MC_CONF[engine]}")" "engine=${MC_CONF[engine]}"
  fi
  if [ "${MC_CONF[archive_backend]}" = netbackup ]; then
    _pf_need bparchive "$(mc_t pf.need_bparchive)"
  fi
}

# The compressor must be installed; when it is not and the other one is,
# switching is one command away.
_pf_need_compressor() {
  local c=${MC_CONF[compress]} other=gzip hints=()
  if command -v "$c" >/dev/null 2>&1; then
    _pf_ok "$(mc_t pf.cmd_found "$c" "$(command -v "$c")")"
    return 0
  fi
  [ "$c" = gzip ] && other=zstd
  hints=("$(mc_t pf.needed_for "compress=$c")")
  if command -v "$other" >/dev/null 2>&1; then
    hints+=("$(mc_t pf.hint_switch_compress "$other")" "$(_pf_fix compress "$other")")
    if [ "$other" = gzip ] && [ "${MC_CONF[compress_level]}" -gt 9 ]; then
      hints+=("$(_pf_fix compress_level 6)")
    fi
  fi
  _pf_fail env "$(mc_t pf.cmd_missing "$c")" "${hints[@]}"
}

_pf_check_server() {
  local engine e
  mc_auth_prepare || { _pf_fail env "$(mc_t pf.tmp_login)"; return 1; }
  if ! mc_auth_test; then
    _pf_fail env "$(mc_t pf.cannot_connect "$MC_AUTH_DESC")" "$(mc_t pf.cannot_connect_hint)"
    return 1
  fi

  if ! mc_target_check; then
    for e in "${MC_TARGET_ERRORS[@]}"; do
      case "$MC_TARGET_STATUS" in
        config)      _pf_fail config "$e" ;;
        unreachable) _pf_fail env "$e" ;;
        *)           _pf_fail target "$e" ;;
      esac
    done
    [ "$MC_TARGET_STATUS" != unreachable ] || return 1
  fi
  _pf_ok "$(mc_t pf.connection_ok "${MC_TARGET_VERSION:-?}" "${MC_TARGET_VERSION_COMMENT:-$(mc_t pf.unknown_edition)}")"
  [ "$MC_TARGET_STATUS" = ok ] || return 1

  _pf_ok "$(mc_t pf.target_ok "$MC_TARGET_HOSTNAME" "$MC_TARGET_PORT" "$MC_TARGET_SOCKET" "$MC_TARGET_DATADIR")"
  _pf_check_expectations
  _pf_check_topology

  [ "${MC_CONF[engine]}" = auto ] || return 0
  engine=$(mc_engine_for_target)
  if [ -z "$engine" ]; then
    _pf_fail config "$(mc_t pf.edition_unknown "${MC_TARGET_VERSION_COMMENT:-$(mc_t pf.empty)}")" \
      "$(mc_t pf.set_engine_hint)" "$(_pf_fix engine mysqldump)"
    return 1
  fi
  _pf_ok "$(mc_t pf.engine_selected "$engine")"
  _pf_need "$(mc_engine_command "$engine")" "engine=auto ($engine)"
}

# On a host with more than one MySQL server, an unset expectation means a
# backup could reach the wrong instance: suggest the values just read.
_pf_check_expectations() {
  local n key value hints=()
  n=$(_pf_server_processes) || return 0
  [ "$n" -gt 1 ] || return 0
  for key in mysql_socket expect_hostname expect_port expect_datadir expect_server_uuid expect_server_id; do
    [ -z "${MC_CONF[$key]}" ] || continue
    case "$key" in
      mysql_socket)       value=$MC_TARGET_SOCKET ;;
      expect_hostname)    value=$MC_TARGET_HOSTNAME ;;
      expect_port)        value=$MC_TARGET_PORT ;;
      expect_datadir)     value=$MC_TARGET_DATADIR ;;
      expect_server_uuid) value=$MC_TARGET_SERVER_UUID ;;
      expect_server_id)   value=$MC_TARGET_SERVER_ID ;;
    esac
    [ -n "$value" ] || continue
    hints+=("$(_pf_fix "$key" "$value")")
  done
  [ ${#hints[@]} -gt 0 ] || return 0
  _pf_warn "$(mc_t pf.multi_instance "$n")" "$(mc_t pf.hint_expect)" "${hints[@]}"
}

# Number of mysqld / mariadbd processes on the host; returns 1 when unknown.
_pf_server_processes() {
  local list
  command -v ps >/dev/null 2>&1 || return 1
  list=$(ps -e -o comm= 2>/dev/null) || return 1
  printf '%s\n' "$list" | awk '{ sub(".*/", "") } $0 == "mysqld" || $0 == "mariadbd" { n++ } END { print n + 0 }'
}

_pf_check_topology() {
  local m
  if mc_topology_check; then
    case "$MC_TOPOLOGY_TYPE" in
      GROUP_REPLICATION) _pf_ok "$(mc_t pf.topology_primary)" ;;
      *)                 _pf_ok "$(mc_t pf.topology_single)" ;;
    esac
    return 0
  fi
  for m in "${MC_TOPOLOGY_MESSAGES[@]}"; do
    if [ "$MC_TOPOLOGY_STATUS" = skip ]; then _pf_warn "$m"; else _pf_fail target "$m"; fi
  done
}

# --- copy-ready commands -------------------------------------------------------

# _pf_q VALUE: the value quoted for the shell (unchanged when it needs no quotes).
_pf_q() {
  printf '%q' "$1"
}

# _pf_fix KEY VALUE: the command that sets KEY=VALUE in mycustos.conf. It
# replaces the active line, or else the first commented one ("#KEY=..."), or
# else appends the key. Only the configuration file is ever targeted.
_pf_fix() {
  local key=$1 value=$2 file=$MC_CONFIG_FILE v
  local active="^[[:space:]]*${key}[[:space:]]*="
  local commented="^[[:space:]]*#[[:space:]]*${key}[[:space:]]*="
  # In the sed replacement \, & and the | delimiter are special; in the
  # single-quoted script, a quote closes and reopens.
  # Quoted replacements are literal in every Bash (5.2 gives & a meaning).
  # shellcheck disable=SC1003  # the backslashes are the point
  local bs='\\' amp='\&' bar='\|' quote="'\\''"
  v=${value//\\/"$bs"}
  v=${v//&/"$amp"}
  v=${v//|/"$bar"}
  v=${v//\'/"$quote"}
  if grep -Eq "$active" "$file" 2>/dev/null; then
    printf "sed -i -E 's|%s.*|%s=%s|' %s" "$active" "$key" "$v" "$(_pf_q "$file")"
  elif grep -Eq "$commented" "$file" 2>/dev/null; then
    printf "sed -i -E '0,/%s/s|%s.*|%s=%s|' %s" "$commented" "$commented" "$key" "$v" "$(_pf_q "$file")"
  else
    printf '%s %s >> %s' "printf '%s\\n'" "$(_pf_q "$key=$value")" "$(_pf_q "$file")"
  fi
}

# --- result lines --------------------------------------------------------------

# _pf_need COMMAND PURPOSE: a required command must be in PATH.
_pf_need() {
  if command -v "$1" >/dev/null 2>&1; then
    _pf_ok "$(mc_t pf.cmd_found "$1" "$(command -v "$1")")"
  else
    _pf_fail env "$(mc_t pf.cmd_missing "$1")" "$(mc_t pf.needed_for "$2")"
  fi
}

# _pf_line TAG TEXT [HINT...]: one result line, then one "->" line per hint.
_pf_line() {
  local tag=$1 text=$2 hint
  shift 2
  if [ -n "$tag" ]; then printf '  %-5s %s\n' "$tag" "$text"; else printf '        %s\n' "$text"; fi
  for hint in "$@"; do
    [ -z "$hint" ] || printf '        -> %s\n' "$hint"
  done
}

_pf_ok()   { PF_OK=$((PF_OK + 1)); _pf_line OK "$@"; }
_pf_warn() { PF_WARN=$((PF_WARN + 1)); _pf_line WARN "$@"; }

# Texts and hints arrive already translated; the OK/WARN/FAIL tags stay in
# English, as they are meant to be searched for.
# _pf_fail config|env|target TEXT [HINT...]
_pf_fail() {
  case "$1" in
    config) PF_FAIL_CONFIG=$((PF_FAIL_CONFIG + 1)) ;;
    target) PF_FAIL_TARGET=$((PF_FAIL_TARGET + 1)) ;;
    *)      PF_FAIL_ENV=$((PF_FAIL_ENV + 1)) ;;
  esac
  shift
  _pf_line FAIL "$@"
}
