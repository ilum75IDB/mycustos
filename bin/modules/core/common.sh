# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Core helpers shared by every command. Sourced by bin/mycustos: do not execute.

# Requires core/errors.sh (exit codes) and core/i18n.sh (messages).
# die, die_usage and warn take a message KEY of the catalogs, not a text:
#   die "$MC_EX_CONFIG" cfg.not_found "$file"

# Commands of the CLI, in the order shown by "mycustos help".
readonly MC_COMMANDS=(backup preflight check-config status config version help)

# Prints a text as it is (already translated, or not meant to be).
msg()  { printf '%s\n' "$*"; }

# warn KEY [ARG...]
warn() {
  local text
  mc_tv text "$@"
  printf 'mycustos: %s\n' "$(mc_t core.warning "$text")" >&2
}

# Fatal error: die CODE KEY [ARG...]. The run log, when open, gets the English
# text: logs are read by monitoring and must not depend on the language.
die() {
  local code=$1 text
  shift
  mc_tv text "$@"
  printf 'mycustos: %s\n' "$text" >&2
  if declare -F mc_log_to_file >/dev/null; then
    mc_log_to_file ERROR "$(mc_t_en "$@")"
  fi
  exit "$code"
}

# die_usage KEY [ARG...]
die_usage() {
  local text
  mc_tv text "$@"
  printf 'mycustos: %s\n' "$text" >&2
  say cli.run_help >&2
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
    die "$MC_EX_UNAVAILABLE" cli.not_implemented "$1" "$MYCUSTOS_VERSION"
  # shellcheck source=/dev/null
  source "$file" || die "$MC_EX_FAILURE" core.cannot_load "$file"
}
