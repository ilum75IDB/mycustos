#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos preflight": runs bin/mycustos with a PATH that holds only the
# basic utilities, the mocks and the stubs each test asks for, so that the
# outcome does not depend on what is installed on the test machine.

load test_helper

setup() {
  mc_test_load_core
  MYCUSTOS="$REPO/bin/mycustos"
  CNF="$BASE/config/backup-credentials.conf"
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME" "$TMPDIR"
  unset MYSQL_TEST_LOGIN_FILE MC_MOCK_LOGIN_PATHS MC_MOCK_MYSQL_RC MC_MOCK_MYSQL_OUTPUT

  TPATH="$BATS_TEST_TMPDIR/path"
  mkdir -p "$TPATH"
  local u
  for u in bash readlink dirname basename id df awk grep sed ls mktemp rm rmdir; do
    ln -s "$(command -v "$u")" "$TPATH/$u"
  done
  ln -s "$REPO/tests/mocks/bin/mysql" "$TPATH/mysql"
  ln -s "$REPO/tests/mocks/bin/mysql_config_editor" "$TPATH/mysql_config_editor"
  stub tar flock zstd mysqldump

  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$CNF"
  chmod 600 "$CNF"
}

# stub NAME...: commands that exist and do nothing.
stub() {
  local c
  for c in "$@"; do
    printf '#!/bin/sh\nexit 0\n' > "$TPATH/$c"
    chmod +x "$TPATH/$c"
  done
}

unstub() {
  local c
  for c in "$@"; do rm -f "$TPATH/$c"; done
}

# conf KEY=VALUE...: configuration with config_schema=1, engine=mysqldump, plus the given lines.
conf() {
  mc_test_conf 'config_schema=1' 'engine=mysqldump' "$@"
}

preflight() {
  run env PATH="$TPATH" "$MYCUSTOS" --home "$BASE" preflight "$@"
}

@test "everything in place: exit 0, no warnings" {
  conf
  preflight
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos preflight - instance main"* ]]
  [[ "$output" == *"  OK    authentication: option file $CNF"* ]]
  [[ "$output" == *"  OK    command mysqldump: $TPATH/mysqldump"* ]]
  [[ "$output" == *"Result: "*" OK, 0 warning(s), 0 failure(s)" ]]
}

@test "invalid configuration: exit 3 before any check" {
  mc_test_conf 'config_schema=1' 'retention_days=forever'
  preflight
  [ "$status" -eq 3 ]
  [[ "$output" == *"retention_days"* ]]
  [[ "$output" != *"Result:"* ]]
}

@test "authentication problem: exit 3" {
  rm "$CNF"
  conf
  preflight
  [ "$status" -eq 3 ]
  [[ "$output" == *"  FAIL  auth_method=auto: $CNF not found and auth_login_path is empty"* ]]
}

@test "cnf permissions wider than 0600: warning, exit 0" {
  chmod 644 "$CNF"
  conf
  preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"  WARN  auth_cnf: permissions wider than 0600"* ]]
  [[ "$output" == *", 1 warning(s), 0 failure(s)" ]]
}

@test "missing data directory: exit 4 with a hint" {
  rmdir "$BASE/data"
  conf
  preflight
  [ "$status" -eq 4 ]
  [[ "$output" == *"  FAIL  data_dir: directory not found: $BASE/data"* ]]
  [[ "$output" == *"-> create it: mkdir -p $BASE/data"* ]]
}

@test "read-only config directory: exit 4" {
  [ "$(id -u)" -ne 0 ] || skip 'root can write anywhere'
  conf
  chmod 555 "$BASE/config"
  preflight
  chmod 755 "$BASE/config"
  [ "$status" -eq 4 ]
  [[ "$output" == *"FAIL  config directory not writable"* ]]
}

@test "missing commands: exit 4, one failure each" {
  unstub zstd flock
  conf
  preflight
  [ "$status" -eq 4 ]
  [[ "$output" == *"  FAIL  command zstd: not found in PATH"* ]]
  [[ "$output" == *"-> needed for compress=zstd"* ]]
  [[ "$output" == *"  FAIL  command flock: not found in PATH"* ]]
  [[ "$output" == *", 2 failure(s)" ]]
}

@test "the compression command follows compress" {
  unstub zstd
  stub gzip
  conf compress=gzip
  preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK    command gzip:"* ]]
}

@test "netbackup needs bparchive" {
  conf archive_backend=netbackup
  preflight
  [ "$status" -eq 4 ]
  [[ "$output" == *"FAIL  command bparchive: not found in PATH"* ]]
  stub bparchive
  preflight
  [ "$status" -eq 0 ]
}

@test "engine=auto without --test-connection explains when it is chosen" {
  mc_test_conf 'config_schema=1'
  preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK    engine: auto, chosen at backup time from the server edition"* ]]
}

@test "--test-connection: server reached, auto selects the engine" {
  mc_test_conf 'config_schema=1'
  export MC_MOCK_MYSQL_OUTPUT='MySQL Enterprise Server - Commercial'
  preflight --test-connection
  [ "$status" -eq 4 ]
  [[ "$output" == *"OK    connection: MySQL server"*"Commercial"* ]]
  [[ "$output" == *"OK    engine: auto selects mysqlbackup for this server"* ]]
  [[ "$output" == *"FAIL  command mysqlbackup: not found in PATH"* ]]
  stub mysqlbackup
  preflight --test-connection
  [ "$status" -eq 0 ]
}

@test "--test-connection: connection refused is exit 4" {
  conf
  export MC_MOCK_MYSQL_RC=1
  preflight --test-connection
  [ "$status" -eq 4 ]
  [[ "$output" == *"FAIL  cannot connect to the MySQL server with the option file $CNF"* ]]
}

@test "--test-connection: unknown server edition with engine=auto is exit 3" {
  mc_test_conf 'config_schema=1'
  export MC_MOCK_MYSQL_OUTPUT='Something else'
  preflight --test-connection
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  engine=auto: server edition not recognised: Something else"* ]]
  [[ "$output" == *"-> set engine= explicitly in mycustos.conf"* ]]
}

@test "--test-connection: skipped when authentication fails" {
  rm "$CNF"
  conf
  preflight --test-connection
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  connection test skipped"* ]]
}

@test "read-only: no file created or changed, temporary files removed" {
  mc_test_conf 'config_schema=1'
  export MC_MOCK_MYSQL_OUTPUT='MySQL Community Server - GPL'
  before=$(find "$BASE" -exec ls -ld {} + | sort)
  preflight --test-connection
  [ "$status" -eq 0 ]
  [ "$(find "$BASE" -exec ls -ld {} + | sort)" = "$before" ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "the password never appears in the output" {
  conf
  export MC_MOCK_MYSQL_OUTPUT='MySQL Community Server - GPL'
  preflight --test-connection
  [[ "$output" != *S3cr3t* ]]
}

@test "unknown option is a usage error" {
  conf
  preflight --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"preflight: unknown option: --nope"* ]]
}

@test "help preflight no longer says not implemented" {
  run "$MYCUSTOS" help preflight
  [ "$status" -eq 0 ]
  [[ "$output" != *"Not implemented"* ]]
}

@test "mc_engine_for_server maps the server editions" {
  source "$REPO/bin/modules/commands/preflight.sh"
  [ "$(mc_engine_for_server 'MySQL Enterprise Server - Commercial')" = mysqlbackup ]
  [ "$(mc_engine_for_server 'MySQL Community Server - GPL')" = mysqldump ]
  [ "$(mc_engine_for_server 'Source distribution')" = mysqldump ]
  [ "$(mc_engine_for_server 'mariadb.org binary distribution')" = mariadb-backup ]
  [ "$(mc_engine_for_server 'MariaDB Server')" = mariadb-backup ]
  [ "$(mc_engine_for_server 'Percona Server (GPL), Release 26')" = xtrabackup ]
  [ -z "$(mc_engine_for_server 'Something else')" ]
}

@test "mariadb-backup falls back to the older mariabackup name" {
  source "$REPO/bin/modules/commands/preflight.sh"
  PATH="$TPATH" run mc_engine_command mariadb-backup
  [ "$output" = mariadb-backup ]
  stub mariabackup
  PATH="$TPATH" run mc_engine_command mariadb-backup
  [ "$output" = mariabackup ]
}
