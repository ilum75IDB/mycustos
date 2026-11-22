# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos help [command]": usage of the CLI. Sourced by bin/mycustos.

mc_command_summary() {
  case "$1" in
    backup)       mc_t help.cmd.backup ;;
    preflight)    mc_t help.cmd.preflight ;;
    inspect)      mc_t help.cmd.inspect ;;
    check-config) mc_t help.cmd.check_config ;;
    status)       mc_t help.cmd.status ;;
    config)       mc_t help.cmd.config ;;
    version)      mc_t help.cmd.version ;;
    help)         mc_t help.cmd.help ;;
  esac
}

cmd_help() {
  if [ $# -gt 0 ]; then
    mc_is_known_command "$1" || die_usage cli.unknown_command "$1"
    msg "mycustos $1 - $(mc_command_summary "$1")"
    mc_is_implemented "$1" || say help.not_implemented "$MYCUSTOS_VERSION"
    return "$MC_EX_OK"
  fi

  local c note
  say help.title "$MYCUSTOS_VERSION"
  msg ''
  say help.usage
  msg ''
  say help.commands
  for c in "${MC_COMMANDS[@]}"; do
    note=''
    mc_is_implemented "$c" || note=" $(mc_t help.flag_not_implemented)"
    printf '  %-13s %s%s\n' "$c" "$(mc_command_summary "$c")" "$note"
  done
  msg ''
  say help.global_options
  _mc_help_option '--config FILE' help.opt.config
  _mc_help_option '--home DIR'    help.opt.home
  _mc_help_option '--lang CODE'   help.opt.lang
  _mc_help_option '-q, --quiet'   help.opt.quiet
  _mc_help_option '-v, --verbose' help.opt.verbose
  _mc_help_option '-h, --help'    help.opt.help
  _mc_help_option '-V, --version' help.opt.version
  msg ''
  say help.languages "$(mc_i18n_list)" "$MC_LANG"
  say help.installation "$MYCUSTOS_HOME"
  return "$MC_EX_OK"
}

_mc_help_option() {
  printf '  %-14s %s\n' "$1" "$(mc_t "$2")"
}
