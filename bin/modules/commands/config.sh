# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos config show":           effective configuration, with the origin of each value
# "mycustos config migrate FILE":   convert a legacy backup.conf (planned)
# Sourced by bin/mycustos.
#
# Output of "config show", one line per key in schema order:
#   key=value  # origin
# The origin is "default", "<file>:<line>", "env MYCUSTOS_<KEY>" or "option <name>".
# Split each line on the first "=" and on the last "  # ". Not meant to be read
# back as mycustos.conf: the parser takes "# ..." after a value as part of it.

cmd_config() {
  local sub=${1:-}
  [ $# -eq 0 ] || shift
  case "$sub" in
    show)
      [ $# -eq 0 ] || die_usage "config show: unknown argument: $1"
      _mc_config_show ;;
    migrate)
      die "$MC_EX_UNAVAILABLE" "config migrate is not implemented yet in mycustos $MYCUSTOS_VERSION" ;;
    '')
      die_usage 'config: missing sub-command (show or migrate)' ;;
    *)
      die_usage "config: unknown sub-command: $sub" ;;
  esac
}

_mc_config_show() {
  local key value width=0 line
  local -a lines=()
  mc_config_load_or_die
  for key in "${MC_CONFIG_KEYS[@]}"; do
    value=${MC_CONF[$key]}
    # No key of the schema holds a secret today; keep it that way if one is added.
    case "$key" in *password*|*secret*|*token*) value='********' ;; esac
    line="$key=$value"
    lines+=("$line")
    (( ${#line} > width )) && width=${#line}
  done
  (( width <= 40 )) || width=40   # long paths would push every origin far right
  msg "# mycustos config show - $MC_CONFIG_FILE"
  local i
  for i in "${!MC_CONFIG_KEYS[@]}"; do
    printf '%-*s  # %s\n' "$width" "${lines[i]}" "${MC_CONF_ORIGIN[${MC_CONFIG_KEYS[i]}]}"
  done
  return "$MC_EX_OK"
}
