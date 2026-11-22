# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos preflight [--test-connection]": checks the prerequisites of a
# backup and suggests what to change. Read-only: it creates no file and no
# directory (the cnf isolation uses a temporary file, removed at the end).
# Sourced by bin/mycustos.
#
# Exit codes: 0 no failure (warnings allowed), 3 a configuration problem,
# 4 an environment problem (command, directory, permission, MySQL server).

PF_OK=0
PF_WARN=0
PF_FAIL_CONFIG=0
PF_FAIL_ENV=0

cmd_preflight() {
  local test_connection=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --test-connection) test_connection=1 ;;
      *) die_usage cli.cmd_unknown_option preflight "$1" ;;
    esac
    shift
  done

  mc_config_load_or_die
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

  msg ''
  say pf.result "$PF_OK" "$PF_WARN" "$((PF_FAIL_CONFIG + PF_FAIL_ENV))"
  if [ "$PF_FAIL_CONFIG" -gt 0 ]; then return "$MC_EX_CONFIG"; fi
  if [ "$PF_FAIL_ENV" -gt 0 ]; then return "$MC_EX_ENVIRONMENT"; fi
  return "$MC_EX_OK"
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
    return 1
  fi
  _pf_ok "$(mc_t pf.auth_ok "$MC_AUTH_DESC")"
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
  _pf_need "${MC_CONF[compress]}" "compress=${MC_CONF[compress]}"
  _pf_need mysql "$(mc_t pf.need_mysql)"
  if [ "${MC_CONF[engine]}" != auto ]; then
    _pf_need "$(mc_engine_command "${MC_CONF[engine]}")" "engine=${MC_CONF[engine]}"
  fi
  if [ "${MC_CONF[archive_backend]}" = netbackup ]; then
    _pf_need bparchive "$(mc_t pf.need_bparchive)"
  fi
}

_pf_check_server() {
  local comment version engine
  mc_auth_prepare || { _pf_fail env "$(mc_t pf.tmp_login)"; return 1; }
  if ! mc_auth_test; then
    _pf_fail env "$(mc_t pf.cannot_connect "$MC_AUTH_DESC")" "$(mc_t pf.cannot_connect_hint)"
    return 1
  fi
  version=$(mc_auth_query 'SELECT @@version' 2>/dev/null)
  comment=$(mc_auth_query 'SELECT @@version_comment' 2>/dev/null)
  _pf_ok "$(mc_t pf.connection_ok "${version:-?}" "${comment:-$(mc_t pf.unknown_edition)}")"

  [ "${MC_CONF[engine]}" = auto ] || return 0
  engine=$(mc_engine_for_server "$comment")
  if [ -z "$engine" ]; then
    _pf_fail config "$(mc_t pf.edition_unknown "${comment:-$(mc_t pf.empty)}")" \
      "$(mc_t pf.set_engine_hint)"
    return 1
  fi
  _pf_ok "$(mc_t pf.engine_selected "$engine")"
  _pf_need "$(mc_engine_command "$engine")" "engine=auto ($engine)"
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

_pf_line() {
  local tag=$1 text=$2 hint=${3:-}
  printf '  %-5s %s\n' "$tag" "$text"
  [ -z "$hint" ] || printf '        -> %s\n' "$hint"
}

_pf_ok()   { PF_OK=$((PF_OK + 1)); _pf_line OK "$@"; }
_pf_warn() { PF_WARN=$((PF_WARN + 1)); _pf_line WARN "$@"; }

# Texts and hints arrive already translated; the OK/WARN/FAIL tags stay in
# English, as they are meant to be searched for.
# _pf_fail config|env TEXT [HINT]
_pf_fail() {
  if [ "$1" = config ]; then PF_FAIL_CONFIG=$((PF_FAIL_CONFIG + 1)); else PF_FAIL_ENV=$((PF_FAIL_ENV + 1)); fi
  shift
  _pf_line FAIL "$@"
}
