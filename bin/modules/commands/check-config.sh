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
  [ $# -eq 0 ] || die_usage "check-config: unknown argument: $1"

  local rc=0 e w
  local -a warnings=()
  mc_config_load || rc=$?
  msg "mycustos check-config - $MC_CONFIG_FILE"
  msg "config_schema supported: $MC_CONFIG_SCHEMA_VERSION (mycustos $MYCUSTOS_VERSION)"

  if [ "$rc" -eq 0 ]; then
    _cc_warnings
    if [ ${#warnings[@]} -gt 0 ]; then
      for w in "${warnings[@]}"; do msg "  WARN  $w"; done
    fi
    msg "Result: valid, ${#warnings[@]} warning(s)"
    return "$MC_EX_OK"
  fi

  for e in "${MC_CONFIG_ERRORS[@]}"; do msg "  ERROR $e"; done
  msg "Result: invalid, ${#MC_CONFIG_ERRORS[@]} error(s)"
  return "$MC_EX_CONFIG"
}

# Settings that are valid but probably not what was meant. Fills "warnings"
# (local to cmd_check_config).
_cc_warnings() {
  if [ "${MC_CONF[backup_type]}" = incr ] && [ "${MC_CONF[engine]}" = auto ]; then
    warnings+=("${MC_CONF_ORIGIN[backup_type]}: backup_type=incr with engine=auto works only when the server edition selects mysqlbackup (MySQL Enterprise)")
  fi
  if [ "${MC_CONF[auth_method]}" = cnf ] && [ -n "${MC_CONF[auth_login_path]}" ]; then
    warnings+=("${MC_CONF_ORIGIN[auth_login_path]}: auth_login_path is ignored with auth_method=cnf")
  fi
  if [ "${MC_CONF[auth_method]}" = login-path ] && [ "${MC_CONF_ORIGIN[auth_cnf]}" != default ]; then
    warnings+=("${MC_CONF_ORIGIN[auth_cnf]}: auth_cnf is ignored with auth_method=login-path")
  fi
  if [ "${MC_CONF[data_dir]}" = "${MC_CONF[logs_dir]}" ]; then
    warnings+=("${MC_CONF_ORIGIN[logs_dir]}: logs_dir is the same directory as data_dir")
  fi
}
