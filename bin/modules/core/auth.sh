# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# MySQL authentication: chooses between an option file (cnf) and a
# mysql_config_editor login path, and builds the client options for it.
# Sourced by bin/mycustos. Requires a loaded configuration (core/config.sh).
#
#   MC_AUTH_METHOD    selected method: cnf | login-path (empty until mc_auth_select)
#   MC_AUTH_OPTS      client options, to be placed first on the command line
#   MC_AUTH_DESC      human readable description; never contains a secret
#   MC_AUTH_ERRORS    problems found by mc_auth_select, one per element
#   MC_AUTH_WARNINGS  non fatal findings (e.g. permissions wider than 0600)
#
# Credentials never appear on a command line or in a log: only the path of
# the option file or the name of the login path does.
#
# With the cnf method the client must not merge credentials from elsewhere:
# --defaults-file skips /etc/my.cnf and ~/.my.cnf, and MYSQL_TEST_LOGIN_FILE
# points to an empty private file instead of ~/.mylogin.cnf (see mc_auth_run).

# shellcheck disable=SC2034  # read by preflight and the engines

MC_AUTH_METHOD=''
MC_AUTH_DESC=''
MC_AUTH_OPTS=()
MC_AUTH_ERRORS=()
MC_AUTH_WARNINGS=()
MC_AUTH_EMPTY_LOGIN=''   # empty login file used for the cnf isolation

# Selects the method from auth_method, auth_cnf and auth_login_path.
# Returns 0 and sets MC_AUTH_*, or 1 with the reasons in MC_AUTH_ERRORS.
# It only reads files: no connection to the server (see mc_auth_test).
mc_auth_select() {
  local method=${MC_CONF[auth_method]} cnf=${MC_CONF[auth_cnf]}
  MC_AUTH_METHOD=''
  MC_AUTH_DESC=''
  MC_AUTH_OPTS=()
  MC_AUTH_ERRORS=()
  MC_AUTH_WARNINGS=()

  case "$method" in
    cnf)
      _mc_auth_use_cnf "$cnf" ;;
    login-path)
      _mc_auth_use_login_path ;;
    auto)
      # A cnf file that exists but is unusable is a mistake to report,
      # not a reason to silently fall back to the login path.
      if [ -e "$cnf" ]; then
        _mc_auth_use_cnf "$cnf"
      elif [ -n "${MC_CONF[auth_login_path]}" ]; then
        _mc_auth_use_login_path
      else
        MC_AUTH_ERRORS+=("auth_method=auto: $cnf not found and auth_login_path is empty")
      fi ;;
    *)
      MC_AUTH_ERRORS+=("auth_method: invalid value: $method") ;;
  esac
  [ ${#MC_AUTH_ERRORS[@]} -eq 0 ]
}

# Runs a MySQL client command with the selected credentials:
#   mc_auth_run mysql -N -e 'SELECT 1'
# MC_AUTH_OPTS go right after the program name, as option files must come first.
# Inside "$(...)" call mc_auth_prepare first, in the main shell: the empty
# login file created in a subshell would not be known to mc_auth_cleanup.
mc_auth_run() {
  local prog=$1
  shift
  [ -n "$MC_AUTH_METHOD" ] || {
    printf 'mycustos: mc_auth_run: mc_auth_select not called\n' >&2
    return 1
  }
  if [ "$MC_AUTH_METHOD" = cnf ]; then
    mc_auth_prepare || return 1
    MYSQL_TEST_LOGIN_FILE=$MC_AUTH_EMPTY_LOGIN "$prog" "${MC_AUTH_OPTS[@]}" "$@"
  else
    "$prog" "${MC_AUTH_OPTS[@]}" "$@"
  fi
}

# Connection test (preflight --test-connection): SELECT 1 with the selected method.
mc_auth_test() {
  local opts=(--connect-timeout=10 -N -B)
  [ -z "${MC_CONF[mysql_socket]}" ] || opts+=("--socket=${MC_CONF[mysql_socket]}")
  mc_auth_run mysql "${opts[@]}" -e 'SELECT 1' >/dev/null 2>&1
}

# Removes the temporary files of the cnf isolation. Safe to call more than once.
mc_auth_cleanup() {
  [ -n "$MC_AUTH_EMPTY_LOGIN" ] || return 0
  rm -f -- "$MC_AUTH_EMPTY_LOGIN"
  rmdir -- "${MC_AUTH_EMPTY_LOGIN%/*}" 2>/dev/null
  MC_AUTH_EMPTY_LOGIN=''
  return 0
}

# Prints errors and warnings on stderr, prefixed like the config errors.
mc_auth_print_findings() {
  local e
  # Bash < 4.4 with "set -u" treats "${empty[@]}" as unbound.
  if [ ${#MC_AUTH_WARNINGS[@]} -gt 0 ]; then
    for e in "${MC_AUTH_WARNINGS[@]}"; do printf 'mycustos: auth: warning: %s\n' "$e" >&2; done
  fi
  if [ ${#MC_AUTH_ERRORS[@]} -gt 0 ]; then
    for e in "${MC_AUTH_ERRORS[@]}"; do printf 'mycustos: auth: %s\n' "$e" >&2; done
  fi
}

# Creates (once per run) the empty private login file used with the cnf method.
mc_auth_prepare() {
  [ "$MC_AUTH_METHOD" = cnf ] || return 0
  [ -z "$MC_AUTH_EMPTY_LOGIN" ] || return 0
  local dir
  dir=$(umask 077 && mktemp -d "${TMPDIR:-/tmp}/mycustos.XXXXXX") || {
    printf 'mycustos: cannot create a temporary directory\n' >&2
    return 1
  }
  (umask 077 && : > "$dir/empty-mylogin.cnf") || {
    rmdir -- "$dir" 2>/dev/null
    printf 'mycustos: cannot create %s\n' "$dir/empty-mylogin.cnf" >&2
    return 1
  }
  MC_AUTH_EMPTY_LOGIN=$dir/empty-mylogin.cnf
}

# --- internals ---------------------------------------------------------------

_mc_auth_use_cnf() {
  local cnf=$1 mode
  if [ ! -e "$cnf" ]; then
    MC_AUTH_ERRORS+=("auth_cnf: file not found: $cnf")
    return 1
  fi
  if [ ! -f "$cnf" ] || [ ! -r "$cnf" ]; then
    MC_AUTH_ERRORS+=("auth_cnf: not a readable file: $cnf")
    return 1
  fi
  if ! grep -Eq '^[[:space:]]*\[client\][[:space:]]*$' "$cnf"; then
    MC_AUTH_ERRORS+=("auth_cnf: no [client] section in $cnf")
    return 1
  fi
  # ls -l is the portable way to read the mode (GNU and BSD stat differ).
  mode=$(ls -ld -- "$cnf" 2>/dev/null) && mode=${mode:4:6}
  if [ "$mode" != '------' ]; then
    MC_AUTH_WARNINGS+=("auth_cnf: permissions wider than 0600 on $cnf (run: chmod 600)")
  fi
  MC_AUTH_METHOD=cnf
  MC_AUTH_OPTS=("--defaults-file=$cnf")
  MC_AUTH_DESC="option file $cnf"
}

_mc_auth_use_login_path() {
  local name=${MC_CONF[auth_login_path]}
  local file=${MYSQL_TEST_LOGIN_FILE:-${HOME:-}/.mylogin.cnf}
  if [ -z "$name" ]; then
    MC_AUTH_ERRORS+=("auth_login_path: required with auth_method=login-path")
    return 1
  fi
  if [ ! -r "$file" ]; then
    MC_AUTH_ERRORS+=("auth_login_path: login file not found or not readable: $file")
    return 1
  fi
  # mysql_config_editor prints nothing for an unknown login path.
  if command -v mysql_config_editor >/dev/null 2>&1; then
    if [ -z "$(mysql_config_editor print --login-path="$name" 2>/dev/null)" ]; then
      MC_AUTH_ERRORS+=("auth_login_path: login path '$name' not defined in $file")
      return 1
    fi
  else
    MC_AUTH_WARNINGS+=("auth_login_path: mysql_config_editor not found, '$name' not verified")
  fi
  MC_AUTH_METHOD=login-path
  MC_AUTH_OPTS=("--login-path=$name")
  MC_AUTH_DESC="login path $name"
}
