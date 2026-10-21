# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Exit codes of mycustos: the single, stable table. Sourced by bin/mycustos.
# Monitoring may rely on these values: never renumber an existing code,
# only add new ones (and document them in README.md, "Exit codes").

# shellcheck disable=SC2034  # used by the other modules
readonly MC_EX_OK=0            # success
readonly MC_EX_FAILURE=1       # unexpected internal error
readonly MC_EX_USAGE=2         # invalid command line
readonly MC_EX_CONFIG=3        # configuration missing or invalid
readonly MC_EX_ENVIRONMENT=4   # prerequisite missing: command, directory, permission, MySQL server
readonly MC_EX_LOCKED=5        # another run holds the lock
readonly MC_EX_BACKUP=6        # backup or packaging failed: nothing usable was produced
readonly MC_EX_ARCHIVE=7       # local backup OK, archiving failed
readonly MC_EX_TIMEOUT=8       # a phase exceeded its time limit
readonly MC_EX_UNAVAILABLE=69  # command not implemented in this version

# Prints the meaning of an exit code (used by the summary and by "status").
mc_exit_describe() {
  case "$1" in
    0)  echo 'success' ;;
    1)  echo 'unexpected internal error' ;;
    2)  echo 'invalid command line' ;;
    3)  echo 'configuration missing or invalid' ;;
    4)  echo 'prerequisite missing' ;;
    5)  echo 'another run is in progress' ;;
    6)  echo 'backup failed' ;;
    7)  echo 'archiving failed (local backup available)' ;;
    8)  echo 'timeout' ;;
    69) echo 'not implemented in this version' ;;
    *)  echo 'unknown exit code' ;;
  esac
}
