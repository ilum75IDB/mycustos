# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Engine detection shared by preflight, inspect and backup: which backup
# engine fits a server edition, and the command that runs it.
# Sourced by bin/mycustos.

# Engine for a server, from SELECT @@version_comment (compared ignoring case:
# MariaDB reports e.g. "mariadb.org binary distribution"). Prints nothing when
# the edition is not recognised.
mc_engine_for_server() {
  case "${1,,}" in
    *mariadb*) echo mariadb-backup ;;
    *percona*) echo xtrabackup ;;
    *enterprise*|*commercial*) echo mysqlbackup ;;
    *community*|*'source distribution'*) echo mysqldump ;;
  esac
}

# Command of an engine, or of mariadb-backup's older name.
mc_engine_command() {
  case "$1" in
    mariadb-backup)
      if command -v mariadb-backup >/dev/null 2>&1 || ! command -v mariabackup >/dev/null 2>&1; then
        echo mariadb-backup
      else
        echo mariabackup
      fi ;;
    *) echo "$1" ;;
  esac
}
