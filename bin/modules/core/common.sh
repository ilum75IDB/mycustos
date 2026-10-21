# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Core helpers shared by every command. Sourced by bin/mycustos: do not execute.

# Requires core/errors.sh (exit codes).

# Commands of the CLI, in the order shown by "mycustos help".
readonly MC_COMMANDS=(backup preflight check-config status config version help)

msg()  { printf '%s\n' "$*"; }
warn() { printf 'mycustos: warning: %s\n' "$*" >&2; }

# Fatal error: also recorded in the run log when core/log.sh has one open.
die() {
  local code=$1
  shift
  printf 'mycustos: %s\n' "$*" >&2
  if declare -F mc_log_to_file >/dev/null; then
    mc_log_to_file ERROR "$*"
  fi
  exit "$code"
}

die_usage() {
  printf 'mycustos: %s\n' "$*" >&2
  printf "Run 'mycustos help' for usage.\n" >&2
  exit "$MC_EX_USAGE"
}

mc_is_known_command() {
  local c
  for c in "${MC_COMMANDS[@]}"; do
    [ "$c" = "$1" ] && return 0
  done
  return 1
}

mc_command_file() {
  printf '%s/commands/%s.sh' "$MYCUSTOS_MODULES" "$1"
}

mc_is_implemented() {
  [ -r "$(mc_command_file "$1")" ]
}

mc_load_command() {
  local file
  file=$(mc_command_file "$1")
  mc_is_implemented "$1" ||
    die "$MC_EX_UNAVAILABLE" "command '$1' is not implemented yet in mycustos $MYCUSTOS_VERSION"
  # shellcheck source=/dev/null
  source "$file" || die "$MC_EX_FAILURE" "cannot load $file"
}
