# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Core helpers shared by every command. Sourced by bin/mycustos: do not execute.

# Exit codes (the complete table will live in core/errors.sh).
# shellcheck disable=SC2034  # used by the command modules
readonly MC_EX_OK=0
readonly MC_EX_USAGE=2
readonly MC_EX_UNAVAILABLE=69

# Commands of the CLI, in the order shown by "mycustos help".
readonly MC_COMMANDS=(backup preflight check-config status config version help)

msg()  { printf '%s\n' "$*"; }
warn() { printf 'mycustos: warning: %s\n' "$*" >&2; }

die() {
  local code=$1
  shift
  printf 'mycustos: %s\n' "$*" >&2
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
  source "$file" || die 1 "cannot load $file"
}
