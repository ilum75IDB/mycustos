# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos help [command]": usage of the CLI. Sourced by bin/mycustos.

mc_command_summary() {
  case "$1" in
    backup)       echo 'Run a FULL or INCR backup (--type full|incr, --dry-run)' ;;
    preflight)    echo 'Check prerequisites and suggest config changes (read-only)' ;;
    check-config) echo 'Validate mycustos.conf, reporting every problem (read-only)' ;;
    status)       echo 'Show the outcome of the last run' ;;
    config)       echo 'Show the effective configuration or migrate a legacy file' ;;
    version)      echo 'Show version and attribution' ;;
    help)         echo 'Show this help, or the help of a command' ;;
  esac
}

cmd_help() {
  if [ $# -gt 0 ]; then
    mc_is_known_command "$1" || die_usage "unknown command: $1"
    msg "mycustos $1 - $(mc_command_summary "$1")"
    mc_is_implemented "$1" || msg "Not implemented yet in mycustos $MYCUSTOS_VERSION."
    return "$MC_EX_OK"
  fi

  local c note
  msg "mycustos $MYCUSTOS_VERSION - standardized MySQL backup runner"
  msg ''
  msg 'Usage: mycustos <command> [options]'
  msg ''
  msg 'Commands:'
  for c in "${MC_COMMANDS[@]}"; do
    note=''
    mc_is_implemented "$c" || note=' (not implemented yet)'
    printf '  %-13s %s%s\n' "$c" "$(mc_command_summary "$c")" "$note"
  done
  msg ''
  msg 'Global options:'
  msg '  --config FILE  Configuration file (default: <home>/config/mycustos.conf)'
  msg '  --home DIR     Base of config/, data/ and logs/ (default: the installation)'
  msg '  -q, --quiet    Show only warnings and errors'
  msg '  -v, --verbose  Show debug messages too'
  msg '  -h, --help     Same as "mycustos help"'
  msg '  -V, --version  Same as "mycustos version"'
  msg ''
  msg "Installation: $MYCUSTOS_HOME"
  return "$MC_EX_OK"
}
