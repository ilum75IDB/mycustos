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
      *) die_usage "preflight: unknown option: $1" ;;
    esac
    shift
  done

  mc_config_load_or_die
  msg "mycustos preflight - instance ${MC_CONF[instance]}"
  _pf_ok "configuration: $MC_CONFIG_FILE"

  local auth_ok=0
  _pf_check_auth && auth_ok=1
  _pf_check_dirs
  _pf_check_commands

  if [ "$test_connection" -eq 1 ]; then
    if [ "$auth_ok" -eq 1 ] && command -v mysql >/dev/null 2>&1; then
      _pf_check_server
    else
      _pf_fail env 'connection test skipped: authentication or mysql client not available'
    fi
  elif [ "${MC_CONF[engine]}" = auto ]; then
    _pf_ok 'engine: auto, chosen at backup time from the server edition' \
      '(run "mycustos preflight --test-connection" to see which one)'
  fi
  mc_auth_cleanup

  msg ''
  msg "Result: $PF_OK OK, $PF_WARN warning(s), $((PF_FAIL_CONFIG + PF_FAIL_ENV)) failure(s)"
  if [ "$PF_FAIL_CONFIG" -gt 0 ]; then return "$MC_EX_CONFIG"; fi
  if [ "$PF_FAIL_ENV" -gt 0 ]; then return "$MC_EX_ENVIRONMENT"; fi
  return "$MC_EX_OK"
}

# Engine for a server, from SELECT @@version_comment (compared ignoring case:
# MariaDB reports e.g. "mariadb.org binary distribution"). Prints nothing when
# the edition is not recognised.
mc_engine_for_server() {
  case "${1,,}" in
    *mariadb*) echo mariadb-backup ;;
    *percona*) echo xtrabackup ;;
    *enterprise*|*commercial*) echo mysqlbackup ;;
    *community*|*'source distribution'*) echo mysqldump ;;
  esac
}

# Command of an engine, or of mariadb-backup's older name.
mc_engine_command() {
  case "$1" in
    mariadb-backup)
      if command -v mariadb-backup >/dev/null 2>&1 || ! command -v mariabackup >/dev/null 2>&1; then
        echo mariadb-backup
      else
        echo mariabackup
      fi ;;
    *) echo "$1" ;;
  esac
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
  _pf_ok "authentication: $MC_AUTH_DESC"
}

_pf_check_dirs() {
  local key dir avail
  for key in data_dir logs_dir; do
    dir=${MC_CONF[$key]}
    if [ ! -d "$dir" ]; then
      _pf_fail env "$key: directory not found: $dir" "create it: mkdir -p $dir"
    elif [ ! -w "$dir" ] || [ ! -x "$dir" ]; then
      _pf_fail env "$key: not writable by $(id -un): $dir"
    else
      _pf_ok "$key: $dir"
    fi
  done
  # The INCR chain state and the lock live in config/.
  if [ -w "$MYCUSTOS_CONFIG" ] && [ -x "$MYCUSTOS_CONFIG" ]; then
    _pf_ok "config directory writable: $MYCUSTOS_CONFIG"
  else
    _pf_fail env "config directory not writable by $(id -un): $MYCUSTOS_CONFIG" \
      'it holds the lock and the INCR chain state'
  fi

  dir=${MC_CONF[data_dir]}
  if [ -d "$dir" ]; then
    avail=$(df -Pk -- "$dir" 2>/dev/null | awk 'NR == 2 { print $4 }')
    if [[ "$avail" =~ ^[0-9]+$ ]]; then
      _pf_ok "data_dir: $((avail / 1048576)) GiB available"
    else
      _pf_warn "data_dir: cannot read the free space of $dir"
    fi
  fi
}

_pf_check_commands() {
  _pf_need tar 'packaging'
  _pf_need flock 'single-run lock (package util-linux)'
  _pf_need "${MC_CONF[compress]}" "compress=${MC_CONF[compress]}"
  _pf_need mysql 'MySQL client, used to detect the server and test the connection'
  if [ "${MC_CONF[engine]}" != auto ]; then
    _pf_need "$(mc_engine_command "${MC_CONF[engine]}")" "engine=${MC_CONF[engine]}"
  fi
  if [ "${MC_CONF[archive_backend]}" = netbackup ]; then
    _pf_need bparchive 'archive_backend=netbackup (NetBackup client)'
  fi
}

_pf_check_server() {
  local comment version engine
  mc_auth_prepare || { _pf_fail env 'cannot create the temporary login file'; return 1; }
  if ! mc_auth_test; then
    _pf_fail env "cannot connect to the MySQL server with the $MC_AUTH_DESC" \
      'check the credentials and mysql_socket'
    return 1
  fi
  version=$(mc_auth_query 'SELECT @@version' 2>/dev/null)
  comment=$(mc_auth_query 'SELECT @@version_comment' 2>/dev/null)
  _pf_ok "connection: MySQL server ${version:-?} (${comment:-unknown edition})"

  [ "${MC_CONF[engine]}" = auto ] || return 0
  engine=$(mc_engine_for_server "$comment")
  if [ -z "$engine" ]; then
    _pf_fail config "engine=auto: server edition not recognised: ${comment:-empty}" \
      'set engine= explicitly in mycustos.conf'
    return 1
  fi
  _pf_ok "engine: auto selects $engine for this server"
  _pf_need "$(mc_engine_command "$engine")" "engine=auto ($engine)"
}

# --- result lines --------------------------------------------------------------

# _pf_need COMMAND PURPOSE: a required command must be in PATH.
_pf_need() {
  if command -v "$1" >/dev/null 2>&1; then
    _pf_ok "command $1: $(command -v "$1")"
  else
    _pf_fail env "command $1: not found in PATH" "needed for $2"
  fi
}

_pf_line() {
  local tag=$1 text=$2 hint=${3:-}
  printf '  %-5s %s\n' "$tag" "$text"
  [ -z "$hint" ] || printf '        -> %s\n' "$hint"
}

_pf_ok()   { PF_OK=$((PF_OK + 1)); _pf_line OK "$@"; }
_pf_warn() { PF_WARN=$((PF_WARN + 1)); _pf_line WARN "$@"; }

# _pf_fail config|env TEXT [HINT]
_pf_fail() {
  if [ "$1" = config ]; then PF_FAIL_CONFIG=$((PF_FAIL_CONFIG + 1)); else PF_FAIL_ENV=$((PF_FAIL_ENV + 1)); fi
  shift
  _pf_line FAIL "$@"
}
