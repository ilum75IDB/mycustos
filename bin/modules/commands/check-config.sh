# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos check-config": validates mycustos.conf and reports every problem
# at once, with its origin (file and line, environment variable or default).
# Read-only, no connection to MySQL: the environment is checked by "preflight".
# Sourced by bin/mycustos.
#
# Exit codes: 0 valid (warnings allowed), 3 invalid.

cmd_check_config() {
  [ $# -eq 0 ] || die_usage cli.cmd_unknown_argument check-config "$1"

  local rc=0 e w
  local -a warnings=()
  mc_config_load || rc=$?
  msg "mycustos check-config - $(mc_config_files_desc)"
  say cc.schema_supported "$MC_CONFIG_SCHEMA_VERSION" "$MYCUSTOS_VERSION"

  if [ "$rc" -eq 0 ]; then
    _cc_warnings
    if [ ${#warnings[@]} -gt 0 ]; then
      for w in "${warnings[@]}"; do msg "  WARN  $w"; done
    fi
    say cc.result_valid "${#warnings[@]}"
    return "$MC_EX_OK"
  fi

  for e in "${MC_CONFIG_ERRORS[@]}"; do msg "  ERROR $e"; done
  say cc.result_invalid "${#MC_CONFIG_ERRORS[@]}"
  return "$MC_EX_CONFIG"
}

# Settings that are valid but probably not what was meant. Fills "warnings"
# (local to cmd_check_config).
_cc_warnings() {
  if [ "${MC_CONF[backup_type]}" = incr ] && [ "${MC_CONF[engine]}" = auto ]; then
    warnings+=("${MC_CONF_ORIGIN[backup_type]}: $(mc_t cc.warn_incr_auto)")
  fi
  if [ "${MC_CONF[auth_method]}" = cnf ] && [ -n "${MC_CONF[auth_login_path]}" ]; then
    warnings+=("${MC_CONF_ORIGIN[auth_login_path]}: $(mc_t cc.warn_login_path_ignored)")
  fi
  if [ "${MC_CONF[auth_method]}" = login-path ] && [ "${MC_CONF_ORIGIN[auth_cnf]}" != default ]; then
    warnings+=("${MC_CONF_ORIGIN[auth_cnf]}: $(mc_t cc.warn_cnf_ignored)")
  fi
  if [ "${MC_CONF[data_dir]}" = "${MC_CONF[logs_dir]}" ]; then
    warnings+=("${MC_CONF_ORIGIN[logs_dir]}: $(mc_t cc.warn_same_dirs)")
  fi
  # The language exists only if its catalog does: otherwise English is used.
  if [ -n "${MC_CONF[language]}" ] &&
     ! mc_i18n_resolve "${MC_CONF[language]}" >/dev/null; then
    warnings+=("${MC_CONF_ORIGIN[language]}: $(mc_t cc.warn_language_missing "${MC_CONF[language]}" "$(mc_i18n_list)")")
  fi
}
