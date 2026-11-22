# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
# shellcheck disable=SC2034  # MYCUSTOS_* directories: read by the other modules and via ${!name}
#
# Configuration: mycustos.conf is READ, never executed (no "source").
# Sourced by bin/mycustos.
#
# File format, one setting per line:
#   key=value          spaces around "=" are ignored
#   key="value"        optional single or double quotes, no escapes
#   # comment          whole-line comments only: "key=value # note" keeps "# note" in the value
# Only the keys of the schema below are accepted: an unknown key is an error.
# The only expansions are ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA}
# and ${MYCUSTOS_LOGS} (data_dir and logs_dir may use only the first two).
#
# Local overrides: mycustos.local.conf, next to the main file (same name with
# ".conf" replaced by ".local.conf"), is optional and read after it. The main
# file holds the values shared by every server, the local file only what this
# server customises: a key in both takes the local value. A key twice in the
# same file is still an error.
#
# Each file decides where the data goes and which credentials are used, so it
# must be safe even though it is never executed: a regular file (not a
# symbolic link), owned by the running user or root, not writable by group or
# others. Any violation is a configuration error.
#
# Precedence: command-line option > environment (MYCUSTOS_<KEY>) >
# mycustos.local.conf > mycustos.conf > default.
#
# After mc_config_load:
#   MC_CONF[key]         effective value
#   MC_CONF_ORIGIN[key]  "default", "<file>:<line>", "env MYCUSTOS_<KEY>" or "option <name>"
#   MC_CONFIG_FILE, MYCUSTOS_CONFIG (its directory), MYCUSTOS_DATA, MYCUSTOS_LOGS
#   MC_CONFIG_LOCAL_FILE  the local file path; MC_CONFIG_LOCAL_LOADED 1 when it was read
#   MC_CONFIG_ERRORS     every problem found, as "<origin>: <message>"

readonly MC_CONFIG_SCHEMA_VERSION=1

# Declared and assigned separately: Bash 4.2 mishandles "declare -gA x=()" when
# the file is sourced from a function (e.g. by the tests).
declare -gA MC_SCHEMA_TYPE MC_SCHEMA_DEFAULT MC_CONF MC_CONF_RAW MC_CONF_ORIGIN
MC_SCHEMA_TYPE=()
MC_SCHEMA_DEFAULT=()
MC_CONF=()
MC_CONF_RAW=()
MC_CONF_ORIGIN=()
MC_CONFIG_KEYS=()
MC_CONFIG_ERRORS=()
MC_CONFIG_UNSAFE=()
MC_CONFIG_FILE=''
MC_CONFIG_LOCAL_FILE=''
MC_CONFIG_LOCAL_LOADED=0
MYCUSTOS_CONFIG=''
MYCUSTOS_DATA=''
MYCUSTOS_LOGS=''

# _mc_schema KEY TYPE DEFAULT
# Types: int:MIN:MAX, optint:MIN:MAX, enum:A,B,..., name, optname, dblist, path,
# optpath, optlang, optuuid, schema. The "opt" types also accept an empty value.
_mc_schema() {
  MC_CONFIG_KEYS+=("$1")
  MC_SCHEMA_TYPE[$1]=$2
  MC_SCHEMA_DEFAULT[$1]=$3
}

# shellcheck disable=SC2016  # ${MYCUSTOS_*} are expanded by the parser, not by Bash
{
  _mc_schema config_schema   schema                        ''
  _mc_schema instance        name                          main
  _mc_schema databases       dblist                        ALL
  _mc_schema backup_type     enum:full,incr                full
  _mc_schema engine          enum:auto,mysqlbackup,mysqldump,mydumper,xtrabackup,mariadb-backup auto
  _mc_schema auth_method     enum:auto,cnf,login-path      auto
  _mc_schema auth_cnf        path                          '${MYCUSTOS_CONFIG}/backup-credentials.conf'
  _mc_schema auth_login_path optname                       ''
  _mc_schema mysql_socket    optpath                       ''
  _mc_schema compress        enum:gzip,zstd                zstd
  _mc_schema compress_level  int:1:19                      7
  _mc_schema packaging       enum:simple,split             simple
  _mc_schema archive_backend enum:none,netbackup           none
  _mc_schema retention_days  int:0:3650                    7
  _mc_schema data_dir        path                          '${MYCUSTOS_HOME}/data'
  _mc_schema logs_dir        path                          '${MYCUSTOS_HOME}/logs'
  _mc_schema language        optlang                       ''
  # Expected identity of the instance (core/target.sh): empty = not checked.
  _mc_schema expect_hostname    optname                    ''
  _mc_schema expect_port        optint:1:65535             ''
  _mc_schema expect_datadir     optpath                    ''
  _mc_schema expect_server_uuid optuuid                    ''
  _mc_schema expect_server_id   optint:0:4294967295        ''
}

mc_config_is_key() {
  [[ "$1" =~ ^[a-z][a-z0-9_]*$ ]] && [ -n "${MC_SCHEMA_TYPE[$1]+x}" ]
}

# Prints the effective value of KEY.
mc_config_get() {
  mc_config_is_key "$1" || {
    printf 'mycustos: mc_config_get: unknown key: %s\n' "$1" >&2
    return 1
  }
  printf '%s\n' "${MC_CONF[$1]-}"
}

# Configuration file to read: --config FILE, else $MYCUSTOS_CONFIG_FILE,
# else <home>/config/mycustos.conf. Printed as an absolute path when its directory exists.
mc_config_file() {
  local file=${MC_OPT_CONFIG:-${MYCUSTOS_CONFIG_FILE:-$MYCUSTOS_HOME/config/mycustos.conf}}
  local dir
  if dir=$(cd -- "$(dirname -- "$file")" 2>/dev/null && pwd -P); then
    file="$dir/$(basename -- "$file")"
  fi
  printf '%s\n' "$file"
}

# mc_config_local_file [MAIN]: path of the local override file of MAIN
# (default: the main file in use).
mc_config_local_file() {
  local main=${1:-$(mc_config_file)}
  printf '%s.local.conf\n' "${main%.conf}"
}

# The files read, for headers: "<main>" or "<main> + <local>".
mc_config_files_desc() {
  if [ "$MC_CONFIG_LOCAL_LOADED" -eq 1 ]; then
    printf '%s + %s\n' "$MC_CONFIG_FILE" "$MC_CONFIG_LOCAL_FILE"
  else
    printf '%s\n' "$MC_CONFIG_FILE"
  fi
}

mc_config_load() {
  local key
  MC_CONFIG_ERRORS=()
  MC_CONF_RAW=()
  MC_CONF_ORIGIN=()
  for key in "${MC_CONFIG_KEYS[@]}"; do
    MC_CONF_RAW[$key]=${MC_SCHEMA_DEFAULT[$key]}
    MC_CONF_ORIGIN[$key]=default
  done

  MC_CONFIG_FILE=$(mc_config_file)
  MC_CONFIG_LOCAL_FILE=$(mc_config_local_file "$MC_CONFIG_FILE")
  MC_CONFIG_LOCAL_LOADED=0
  MYCUSTOS_CONFIG=$(dirname -- "$MC_CONFIG_FILE")
  if [ ! -L "$MC_CONFIG_FILE" ] && { [ ! -f "$MC_CONFIG_FILE" ] || [ ! -r "$MC_CONFIG_FILE" ]; }; then
    MC_CONFIG_ERRORS+=("$MC_CONFIG_FILE: $(mc_t cfg.not_found)")
    return 1
  fi
  _mc_config_safe_or_errors "$MC_CONFIG_FILE" || return 1
  # The local file is optional, but once it exists it must be safe too.
  if [ -e "$MC_CONFIG_LOCAL_FILE" ] || [ -L "$MC_CONFIG_LOCAL_FILE" ]; then
    _mc_config_safe_or_errors "$MC_CONFIG_LOCAL_FILE" || return 1
    if [ ! -r "$MC_CONFIG_LOCAL_FILE" ]; then
      MC_CONFIG_ERRORS+=("$MC_CONFIG_LOCAL_FILE: $(mc_t cfg.not_found)")
      return 1
    fi
    MC_CONFIG_LOCAL_LOADED=1
  fi

  _mc_config_parse_file "$MC_CONFIG_FILE"
  [ "$MC_CONFIG_LOCAL_LOADED" -eq 0 ] || _mc_config_parse_file "$MC_CONFIG_LOCAL_FILE"
  _mc_config_apply_env
  _mc_config_resolve
  [ ${#MC_CONFIG_ERRORS[@]} -eq 0 ]
}

# Raw value of KEY in the configuration files (the local one first), without
# validation or expansion; returns 1 when no safe file holds the key. Used to
# pick the language before the configuration is loaded (and its errors are
# translated).
mc_config_peek() {
  local main
  main=$(mc_config_file)
  _mc_config_peek_file "$(mc_config_local_file "$main")" "$1" ||
    _mc_config_peek_file "$main" "$1"
}

# _mc_config_peek_file FILE KEY
_mc_config_peek_file() {
  local file=$1 want=$2 line key value
  [ -f "$file" ] && [ -r "$file" ] || return 1
  _mc_config_safety "$file" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    _mc_trim line "${line%$'\r'}"
    [[ "$line" == *=* && "$line" != '#'* ]] || continue
    _mc_trim key "${line%%=*}"
    [ "$key" = "$want" ] || continue
    _mc_trim value "${line#*=}"
    _mc_unquote value
    printf '%s\n' "$value"
    return 0
  done < "$file"
  return 1
}

# Command-line override, applied after mc_config_load (e.g. "backup --type incr").
#   mc_config_set_cli KEY VALUE OPTION
mc_config_set_cli() {
  mc_config_is_key "$1" || {
    printf 'mycustos: mc_config_set_cli: unknown key: %s\n' "$1" >&2
    return 1
  }
  MC_CONF_RAW[$1]=$2
  MC_CONF_ORIGIN[$1]="option $3"
  MC_CONFIG_ERRORS=()
  _mc_config_resolve
  [ ${#MC_CONFIG_ERRORS[@]} -eq 0 ]
}

mc_config_print_errors() {
  local e
  # Bash < 4.4 with "set -u" treats "${empty[@]}" as unbound.
  [ ${#MC_CONFIG_ERRORS[@]} -gt 0 ] || return 0
  for e in "${MC_CONFIG_ERRORS[@]}"; do
    printf 'mycustos: config: %s\n' "$e" >&2
  done
}

# Loads the configuration or exits with MC_EX_CONFIG, listing every problem.
mc_config_load_or_die() {
  mc_config_load && return 0
  mc_config_print_errors
  exit "$MC_EX_CONFIG"
}

# --- internals ---------------------------------------------------------------

# _mc_config_safe_or_errors FILE: adds the safety problems of FILE to
# MC_CONFIG_ERRORS, returns 1 when there is at least one.
_mc_config_safe_or_errors() {
  local e
  _mc_config_safety "$1" && return 0
  for e in "${MC_CONFIG_UNSAFE[@]}"; do
    MC_CONFIG_ERRORS+=("$1: $e")
  done
  return 1
}

# _mc_config_safety FILE: fills MC_CONFIG_UNSAFE with every reason why FILE
# must not be read (translated, with the command that fixes it) and returns 1
# when there is at least one. Portable: "[ -O ]" and "ls -ln", never stat. The path is absolute,
# so the commands need no "--" (BSD chmod would take it for a file).
_mc_config_safety() {
  local file=$1 q ls uid
  MC_CONFIG_UNSAFE=()
  q=$(printf '%q' "$file")
  if [ -L "$file" ]; then
    MC_CONFIG_UNSAFE+=("$(mc_t cfg.unsafe_symlink)")
    return 1
  fi
  if [ ! -f "$file" ]; then
    MC_CONFIG_UNSAFE+=("$(mc_t cfg.not_found)")
    return 1
  fi
  ls=$(LC_ALL=C ls -ldn -- "$file" 2>/dev/null) || ls=''
  if [ ! -O "$file" ]; then
    uid=$(printf '%s\n' "$ls" | awk '{ print $3 }')
    if [ "$uid" != 0 ]; then
      MC_CONFIG_UNSAFE+=("$(mc_t cfg.unsafe_owner "${uid:-?}" "chown $(id -un) $q")")
    fi
  fi
  if [ "${ls:5:1}" = w ] || [ "${ls:8:1}" = w ]; then
    MC_CONFIG_UNSAFE+=("$(mc_t cfg.unsafe_perms "chmod go-w $q")")
  fi
  [ ${#MC_CONFIG_UNSAFE[@]} -eq 0 ]
}

# _mc_unquote VAR: removes one pair of matching single or double quotes.
_mc_unquote() {
  local v=${!1}
  if [[ ${#v} -ge 2 && ( "$v" == \"*\" || "$v" == \'*\' ) && "${v:0:1}" == "${v: -1}" ]]; then
    printf -v "$1" '%s' "${v:1:${#v}-2}"
  fi
}

# _mc_trim OUTVAR STRING
_mc_trim() {
  local v=$2
  v=${v#"${v%%[![:space:]]*}"}
  v=${v%"${v##*[![:space:]]}"}
  printf -v "$1" '%s' "$v"
}

_mc_config_parse_file() {
  local file=$1 n=0 line key value
  local -A seen=()
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    _mc_trim line "${line%$'\r'}"
    [[ -z "$line" || "$line" == '#'* ]] && continue
    if [[ "$line" != *=* ]]; then
      MC_CONFIG_ERRORS+=("$file:$n: $(mc_t cfg.expected_kv)")
      continue
    fi
    _mc_trim key "${line%%=*}"
    _mc_trim value "${line#*=}"
    if ! mc_config_is_key "$key"; then
      MC_CONFIG_ERRORS+=("$file:$n: $(mc_t cfg.unknown_key "$key")")
      continue
    fi
    if [ -n "${seen[$key]+x}" ]; then
      MC_CONFIG_ERRORS+=("$file:$n: $(mc_t cfg.duplicate_key "$key" "${seen[$key]}")")
      continue
    fi
    seen[$key]=$n
    _mc_unquote value
    MC_CONF_RAW[$key]=$value
    MC_CONF_ORIGIN[$key]="$file:$n"
  done < "$file"
}

_mc_config_apply_env() {
  local key var
  for key in "${MC_CONFIG_KEYS[@]}"; do
    [ "$key" = config_schema ] && continue
    var="MYCUSTOS_${key^^}"
    [ -n "${!var+x}" ] || continue
    MC_CONF_RAW[$key]=${!var}
    MC_CONF_ORIGIN[$key]="env $var"
  done
}

# Expands and validates every raw value into MC_CONF. data_dir and logs_dir
# first, because ${MYCUSTOS_DATA} and ${MYCUSTOS_LOGS} come from them.
_mc_config_resolve() {
  local key
  MC_CONF=()
  for key in data_dir logs_dir; do
    _mc_config_resolve_key "$key" HOME CONFIG
  done
  MYCUSTOS_DATA=${MC_CONF[data_dir]-}
  MYCUSTOS_LOGS=${MC_CONF[logs_dir]-}
  for key in "${MC_CONFIG_KEYS[@]}"; do
    case "$key" in data_dir|logs_dir) continue ;; esac
    _mc_config_resolve_key "$key" HOME CONFIG DATA LOGS
  done
  _mc_config_cross_check
}

# _mc_config_resolve_key KEY ALLOWED_EXPANSION...
_mc_config_resolve_key() {
  local key=$1 value problem
  shift
  if ! problem=$(_mc_config_expand "${MC_CONF_RAW[$key]}" "$@"); then
    MC_CONFIG_ERRORS+=("${MC_CONF_ORIGIN[$key]}: $key: $problem")
    return 1
  fi
  value=$problem
  if ! problem=$(_mc_config_check "$key" "$value"); then
    MC_CONFIG_ERRORS+=("${MC_CONF_ORIGIN[$key]}: $key: $problem")
    return 1
  fi
  # Integers are stored in decimal form: "07" becomes 7, never an octal number.
  [[ "${MC_SCHEMA_TYPE[$key]}" == int:* || ( "${MC_SCHEMA_TYPE[$key]}" == optint:* && -n "$value" ) ]] &&
    value=$((10#$value))
  MC_CONF[$key]=$value
}

# _mc_config_expand VALUE ALLOWED...  (ALLOWED: HOME CONFIG DATA LOGS)
# Prints the expanded value, or the problem and returns 1.
_mc_config_expand() {
  local value=$1 re='\$\{([A-Za-z_][A-Za-z0-9_]*)\}' name token allowed rounds=0
  shift
  allowed=" $* "
  while [[ "$value" =~ $re ]] && (( rounds++ < 10 )); do
    token=${BASH_REMATCH[0]}
    name=${BASH_REMATCH[1]}
    if [[ "$name" != MYCUSTOS_* || "$allowed" != *" ${name#MYCUSTOS_} "* ]]; then
      say cfg.expansion_not_allowed "$token"
      return 1
    fi
    value=${value//"$token"/"${!name}"}
  done
  if [[ "$value" == *'$'* ]]; then
    say cfg.only_expansions
    return 1
  fi
  printf '%s\n' "$value"
}

# _mc_config_check KEY VALUE: prints the problem and returns 1 when VALUE is invalid.
_mc_config_check() {
  local key=$1 v=$2 type=${MC_SCHEMA_TYPE[$1]} spec min max
  case "$type" in
    schema)
      [ "$v" = "$MC_CONFIG_SCHEMA_VERSION" ] && return 0
      if [ -z "$v" ]; then
        say cfg.schema_missing "$MC_CONFIG_SCHEMA_VERSION"
      else
        say cfg.schema_unsupported "$v" "$MC_CONFIG_SCHEMA_VERSION"
      fi
      return 1 ;;
    optint:*)
      [ -z "$v" ] && return 0
      type=${type#opt}
      ;&
    int:*)
      spec=${type#int:}
      min=${spec%%:*}
      max=${spec#*:}
      [[ "$v" =~ ^[0-9]{1,10}$ ]] && (( 10#$v >= min && 10#$v <= max )) && return 0
      say cfg.int_range "$min" "$max" "$v"
      return 1 ;;
    enum:*)
      spec=${type#enum:}
      [[ -n "$v" && "$v" != *,* && ",$spec," == *",$v,"* ]] && return 0
      say cfg.enum "${spec//,/, }" "$v"
      return 1 ;;
    optname)
      [ -z "$v" ] && return 0
      ;&
    name)
      [[ "$v" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] && return 0
      say cfg.name "$v"
      return 1 ;;
    dblist)
      [[ "$v" == ALL || "$v" =~ ^[A-Za-z0-9_-]+(,[A-Za-z0-9_-]+)*$ ]] && return 0
      say cfg.dblist "$v"
      return 1 ;;
    optpath)
      [ -z "$v" ] && return 0
      ;&
    path)
      [[ "$v" == /* && ! "$v" =~ ^/+$ && "$v" != *$'\n'* ]] && return 0
      say cfg.path "$v"
      return 1 ;;
    optuuid)
      [[ -z "$v" || "$v" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$ ]] && return 0
      say cfg.uuid "$v"
      return 1 ;;
    optlang)
      [[ -z "$v" || "$v" =~ ^[A-Za-z]{2,3}([_-][A-Za-z]{2})?$ ]] && return 0
      say cfg.language "$v"
      return 1 ;;
    *)
      echo "internal error: unknown type '$type' for key $key"
      return 1 ;;
  esac
}

# Checks that involve more than one key.
_mc_config_cross_check() {
  if [ "${MC_CONF[compress]-}" = gzip ] && [ -n "${MC_CONF[compress_level]-}" ] &&
     (( MC_CONF[compress_level] > 9 )); then
    MC_CONFIG_ERRORS+=("${MC_CONF_ORIGIN[compress_level]}: compress_level: $(mc_t cfg.gzip_level "${MC_CONF[compress_level]}")")
  fi
  # INCR backups rely on the mysqlbackup LSN chain; with engine=auto the
  # server edition decides (check-config warns about it).
  if [ "${MC_CONF[backup_type]-}" = incr ]; then
    case "${MC_CONF[engine]-}" in
      mysqlbackup|auto|'') ;;
      *) MC_CONFIG_ERRORS+=("${MC_CONF_ORIGIN[backup_type]}: backup_type: $(mc_t cfg.incr_engine "${MC_CONF[engine]}")") ;;
    esac
  fi
  if [ "${MC_CONF[auth_method]-}" = login-path ] && [ -n "${MC_CONF[auth_login_path]+set}" ] &&
     [ -z "${MC_CONF[auth_login_path]}" ]; then
    MC_CONFIG_ERRORS+=("${MC_CONF_ORIGIN[auth_method]}: auth_login_path: $(mc_t cfg.login_path_required)")
  fi
}
