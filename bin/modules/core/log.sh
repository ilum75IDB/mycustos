# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Run logging: timestamped lines on stderr and, once opened, in the run log.
# Sourced by bin/mycustos.
#
#   MC_VERBOSITY  0 = --quiet (warnings and errors only), 1 = normal, 2 = --verbose (debug)
#   MC_LOG_FILE   current run log, empty until mc_log_open
#   MC_RUN_ID     timestamp shared by every file of a run (logs, flags, summary)

MC_VERBOSITY=1
MC_LOG_FILE=''
MC_RUN_ID=''

# mc_log LEVEL MESSAGE...   LEVEL: DEBUG | INFO | WARN | ERROR
mc_log() {
  local level=$1 min line
  shift
  case "$level" in
    DEBUG) min=2 ;;
    INFO)  min=1 ;;
    WARN|ERROR) min=0 ;;
    *) printf 'mycustos: mc_log: invalid level: %s\n' "$level" >&2; return 1 ;;
  esac
  (( MC_VERBOSITY >= min )) || return 0
  printf -v line '%(%Y-%m-%d %H:%M:%S)T %-5s %s' -1 "$level" "$*"
  printf '%s\n' "$line" >&2
  [ -z "$MC_LOG_FILE" ] || printf '%s\n' "$line" >> "$MC_LOG_FILE"
}

log_debug() { mc_log DEBUG "$@"; }
log_info()  { mc_log INFO "$@"; }
log_warn()  { mc_log WARN "$@"; }
log_error() { mc_log ERROR "$@"; }

# Writes to the run log only (used by die, which has already printed on stderr).
mc_log_to_file() {
  [ -n "$MC_LOG_FILE" ] || return 0
  local level=$1 line
  shift
  printf -v line '%(%Y-%m-%d %H:%M:%S)T %-5s %s' -1 "$level" "$*"
  printf '%s\n' "$line" >> "$MC_LOG_FILE"
}

# Sets MC_RUN_ID once per run, in the main shell (not inside "$(...)", where the
# value would be lost); later calls keep the first value.
mc_run_init() {
  [ -n "$MC_RUN_ID" ] || printf -v MC_RUN_ID '%(%Y%m%d_%H%M%S)T' -1
}

# Path of the log of a phase: the only place where log file names are built.
#   mc_log_path PHASE  ->  $MYCUSTOS_LOGS/<run id>_<instance>_<phase>.log
# Requires mc_run_init and a loaded configuration (core/config.sh).
mc_log_path() {
  local phase=$1
  [[ "$phase" =~ ^[a-z][a-z0-9-]*$ ]] || {
    printf 'mycustos: mc_log_path: invalid phase: %s\n' "$phase" >&2
    return 1
  }
  [ -n "${MYCUSTOS_LOGS:-}" ] || {
    printf 'mycustos: mc_log_path: configuration not loaded\n' >&2
    return 1
  }
  [ -n "$MC_RUN_ID" ] || {
    printf 'mycustos: mc_log_path: mc_run_init not called\n' >&2
    return 1
  }
  printf '%s/%s_%s_%s.log\n' "$MYCUSTOS_LOGS" "$MC_RUN_ID" "${MC_CONF[instance]}" "$phase"
}

# Starts writing to FILE (appending). The directory must already exist.
mc_log_open() {
  local file=$1
  if ! { : >> "$file"; } 2>/dev/null; then
    printf 'mycustos: cannot write the log file: %s\n' "$file" >&2
    return 1
  fi
  MC_LOG_FILE=$file
}

mc_log_close() {
  MC_LOG_FILE=''
}
