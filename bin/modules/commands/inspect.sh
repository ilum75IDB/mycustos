# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos inspect": which instance mycustos reaches and what it would do
# there. Read-only: no log file, no flag, no lock, no file written (the cnf
# isolation uses a temporary file, removed at the end).
# Sourced by bin/mycustos.
#
# Output on stdout, one KEY=value per line, always the same keys in the same
# order, meant for scripts (keys and values are never translated; a value not
# known is empty):
#   PRODUCT VERSION VERSION_COMMENT HOSTNAME PORT SOCKET DATADIR SERVER_UUID
#   SERVER_ID AUTH TOPOLOGY ROLE PRIMARY_HOST PRIMARY_IP PRIMARY_PORT ENGINE
#   BACKUP_ALLOWED
# The reasons of a refusal, and the notice of a SECONDARY, go to stderr.
#
# Exit codes: 0 acceptable target (a SECONDARY too, with BACKUP_ALLOWED=no),
# 3 configuration problem, 4 mysql client missing or server not reachable,
# 9 identity or topology rejected.

cmd_inspect() {
  [ $# -eq 0 ] || die_usage cli.cmd_unknown_argument inspect "$1"

  mc_config_load_or_die
  if ! mc_auth_select; then
    mc_auth_print_findings
    return "$MC_EX_CONFIG"
  fi
  mc_auth_print_findings

  local rc=$MC_EX_OK allowed=no
  mc_target_reset
  mc_topology_reset
  if ! command -v mysql >/dev/null 2>&1; then
    _insp_error "$(mc_t insp.mysql_missing)"
    rc=$MC_EX_ENVIRONMENT
  elif ! mc_target_check; then
    _insp_errors "${MC_TARGET_ERRORS[@]}"
    case "$MC_TARGET_STATUS" in
      config)      rc=$MC_EX_CONFIG ;;
      unreachable) rc=$MC_EX_ENVIRONMENT ;;
      *)           rc=$MC_EX_TARGET ;;
    esac
  elif mc_topology_check; then
    allowed=yes
  else
    _insp_errors "${MC_TOPOLOGY_MESSAGES[@]}"
    [ "$MC_TOPOLOGY_STATUS" = skip ] || rc=$MC_EX_TARGET
  fi
  mc_auth_cleanup

  _insp_kv PRODUCT         "$MC_TARGET_PRODUCT"
  _insp_kv VERSION         "$MC_TARGET_VERSION"
  _insp_kv VERSION_COMMENT "$MC_TARGET_VERSION_COMMENT"
  _insp_kv HOSTNAME        "$MC_TARGET_HOSTNAME"
  _insp_kv PORT            "$MC_TARGET_PORT"
  _insp_kv SOCKET          "$MC_TARGET_SOCKET"
  _insp_kv DATADIR         "$MC_TARGET_DATADIR"
  _insp_kv SERVER_UUID     "$MC_TARGET_SERVER_UUID"
  _insp_kv SERVER_ID       "$MC_TARGET_SERVER_ID"
  _insp_kv AUTH            "$(_insp_auth)"
  _insp_kv TOPOLOGY        "$([ -z "$MC_TOPOLOGY_STATUS" ] || printf '%s' "$MC_TOPOLOGY_TYPE")"
  _insp_kv ROLE            "$MC_TOPOLOGY_ROLE"
  _insp_kv PRIMARY_HOST    "$MC_TOPOLOGY_PRIMARY_HOST"
  _insp_kv PRIMARY_IP      "$MC_TOPOLOGY_PRIMARY_IP"
  _insp_kv PRIMARY_PORT    "$MC_TOPOLOGY_PRIMARY_PORT"
  _insp_kv ENGINE          "$(mc_engine_for_target)"
  _insp_kv BACKUP_ALLOWED  "$allowed"
  return "$rc"
}

# --- internals ---------------------------------------------------------------

_insp_kv() {
  printf '%s=%s\n' "$1" "$2"
}

_insp_error() {
  printf 'mycustos: inspect: %s\n' "$1" >&2
}

_insp_errors() {
  local e
  for e in "$@"; do _insp_error "$e"; done
}

# Method and source of the credentials, never the credentials themselves:
# "cnf:<option file>" or "login-path:<name>".
_insp_auth() {
  local opt=${MC_AUTH_OPTS[0]:-}
  case "$opt" in
    --defaults-file=*) printf 'cnf:%s' "${opt#--defaults-file=}" ;;
    --login-path=*)    printf 'login-path:%s' "${opt#--login-path=}" ;;
  esac
}
