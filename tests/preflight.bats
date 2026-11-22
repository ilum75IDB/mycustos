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

@test "--test-connection: connection refused is exit 4" {
  conf
  export MC_MOCK_MYSQL_RC=1
  preflight --test-connection
  [ "$status" -eq 4 ]
  [[ "$output" == *"FAIL  cannot connect to the MySQL server with the option file $CNF"* ]]
}

@test "--test-connection: skipped when authentication fails" {
  rm "$CNF"
  conf
  preflight --test-connection
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  connection test skipped"* ]]
}

# --- server answers (mysql mock with a responses file) -------------------------

UUID=3e11fa47-71ca-11e1-9e33-c80aa9429562
Q_VERSION='SELECT @@version, @@version_comment'
Q_MYSQL='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_uuid'
Q_PLUGIN="SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME = 'group_replication'"
Q_MEMBERS='SELECT MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members'

answer() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$MC_MOCK_MYSQL_RESPONSES"
}

# server [EDITION]: a reachable single MySQL instance.
server() {
  export MC_MOCK_MYSQL_RESPONSES="$BATS_TEST_TMPDIR/responses"
  answer 'SELECT 1' 0 1
  answer "$Q_VERSION" 0 "8.0.36\\t${1:-MySQL Community Server - GPL}"
  answer "$Q_MYSQL" 0 "db-a\\t3306\\t/run/mysqld/a.sock\\t/data/a/\\t$UUID"
  answer "$Q_PLUGIN" 0 ''
}

# processes NAME...: a ps that lists these commands.
processes() {
  printf '#!/bin/sh\nprintf "%%s\\n" %s\n' "$*" > "$TPATH/ps"
  chmod +x "$TPATH/ps"
}

@test "--test-connection: server reached, auto selects the engine" {
  mc_test_conf 'config_schema=1'
  server 'MySQL Enterprise Server - Commercial'
  preflight --test-connection
  [ "$status" -eq 4 ]
  [[ "$output" == *"OK    connection: MySQL server 8.0.36 (MySQL Enterprise Server - Commercial)"* ]]
  [[ "$output" == *"OK    instance: db-a, port 3306, socket /run/mysqld/a.sock, datadir /data/a/"* ]]
  [[ "$output" == *"OK    topology: single instance"* ]]
  [[ "$output" == *"OK    engine: auto selects mysqlbackup for this server"* ]]
  [[ "$output" == *"FAIL  command mysqlbackup: not found in PATH"* ]]
  stub mysqlbackup
  preflight --test-connection
  [ "$status" -eq 0 ]
}

@test "--test-connection: unknown server edition with engine=auto is exit 3, with the fix" {
  mc_test_conf 'config_schema=1' 'engine=auto'
  server 'Something else'
  preflight --test-connection
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  engine=auto: server edition not recognised: Something else"* ]]
  [[ "$output" == *"-> set engine= explicitly in mycustos.conf"* ]]
  [[ "$output" == *"-> sed -i -E 's|^[[:space:]]*engine[[:space:]]*=.*|engine=mysqldump|' $BASE/config/mycustos.conf"* ]]
}

@test "--test-connection: identity mismatch is exit 9" {
  conf expect_port=3310
  server
  preflight --test-connection
  [ "$status" -eq 9 ]
  [[ "$output" == *"FAIL  expect_port: expected 3310, the server reports 3306"* ]]
  [[ "$output" != *"topology:"* ]]
}

@test "--test-connection: an expectation for the other product is exit 3" {
  conf expect_server_id=4
  server
  preflight --test-connection
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  expect_server_id is set, but the server is MySQL"* ]]
}

@test "--test-connection: a SECONDARY is a warning, exit 0" {
  conf
  server
  sed -i.bak '/PLUGIN_STATUS/d' "$MC_MOCK_MYSQL_RESPONSES"
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 0 "x-1\\t192.0.2.10\\t3306\\tONLINE\\tPRIMARY\\n$UUID\\tdb-a\\t3306\\tONLINE\\tSECONDARY"
  preflight --test-connection
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN  this node is a SECONDARY of the group: no backup here. The PRIMARY is 192.0.2.10 (IP 192.0.2.10), port 3306"* ]]
}

@test "--test-connection: Group Replication PRIMARY" {
  conf
  server
  sed -i.bak '/PLUGIN_STATUS/d' "$MC_MOCK_MYSQL_RESPONSES"
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 0 "$UUID\\tdb-a\\t3306\\tONLINE\\tPRIMARY"
  preflight --test-connection
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK    topology: Group Replication, this node is the PRIMARY"* ]]
}

@test "--test-connection: unreadable topology is exit 9" {
  conf
  server
  sed -i.bak '/PLUGIN_STATUS/d' "$MC_MOCK_MYSQL_RESPONSES"
  answer "$Q_PLUGIN" 1 ''
  preflight --test-connection
  [ "$status" -eq 9 ]
  [[ "$output" == *"FAIL  cannot read the Group Replication plugin status"* ]]
}

@test "--test-connection: several instances and no expectation, the expect_* lines with the values read" {
  conf
  server
  processes /usr/sbin/mysqld mysqld bash
  preflight --test-connection
  [ "$status" -eq 0 ]
  f="$BASE/config/mycustos.conf"
  [[ "$output" == *"WARN  2 MySQL server processes on this host, and the expected identity is not fully set"* ]]
  [[ "$output" == *"-> printf '%s\n' mysql_socket=/run/mysqld/a.sock >> $f"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_hostname=db-a >> $f"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_port=3306 >> $f"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_datadir=/data/a/ >> $f"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_server_uuid=$UUID >> $f"* ]]
  [[ "$output" != *"expect_server_id"* ]]
}

@test "--test-connection: one instance, no suggestion about the identity" {
  conf
  server
  processes mysqld bash
  preflight --test-connection
  [[ "$output" != *"expected identity"* ]]
}

@test "suggestions: active, commented and absent keys" {
  conf 'expect_hostname=' '# expect_port=3306'
  server
  processes mysqld mariadbd
  preflight --test-connection
  f="$BASE/config/mycustos.conf"
  [[ "$output" == *"-> sed -i -E 's|^[[:space:]]*expect_hostname[[:space:]]*=.*|expect_hostname=db-a|' $f"* ]]
  [[ "$output" == *"-> sed -i -E '0,/^[[:space:]]*#[[:space:]]*expect_port[[:space:]]*=/s|^[[:space:]]*#[[:space:]]*expect_port[[:space:]]*=.*|expect_port=3306|' $f"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_datadir=/data/a/ >> $f"* ]]
}

@test "suggestions target mycustos.local.conf when it exists" {
  conf 'expect_hostname='
  local="$BASE/config/mycustos.local.conf"
  printf '%s\n' '# expect_port=3306' > "$local"
  chmod 644 "$local"
  server
  processes mysqld mariadbd
  preflight --test-connection
  [[ "$output" == *"configuration: $BASE/config/mycustos.conf + $local"* ]]
  # expect_hostname is active only in mycustos.conf: the override goes to the local file.
  [[ "$output" == *"-> printf '%s\n' expect_hostname=db-a >> $local"* ]]
  [[ "$output" == *"-> printf '%s\n' expect_datadir=/data/a/ >> $local"* ]]
  [[ "$output" == *"expect_port=3306|' $local"* ]]
  [[ "$output" != *">> $BASE/config/mycustos.conf"* ]]
}

@test "suggestions work: applied with GNU sed, the configuration gets the values" {
  sed --version 2>/dev/null | head -n 1 | grep -q '^sed (GNU sed)' || skip 'GNU sed needed (sed -i, 0,/re/)'
  conf 'expect_hostname=' '# expect_port=1' '#expect_port=2'
  server
  processes mysqld mysqld
  preflight --test-connection
  local line
  while IFS= read -r line; do
    eval "${line#*-> }"
  done < <(printf '%s\n' "$output" | grep -E -- '-> (sed|printf) ')
  mc_config_load || { mc_test_errors; return 1; }
  [ "${MC_CONF[expect_hostname]}" = db-a ]
  [ "${MC_CONF[expect_port]}" = 3306 ]
  [ "${MC_CONF[expect_datadir]}" = /data/a/ ]
  [ "${MC_CONF[mysql_socket]}" = /run/mysqld/a.sock ]
  grep -q '^#expect_port=2' "$BASE/config/mycustos.conf"
}

@test "missing configuration: exit 3, with the copy command" {
  preflight
  [ "$status" -eq 3 ]
  [[ "$output" == *"FAIL  configuration file not found: $BASE/config/mycustos.conf"* ]]
  [[ "$output" == *"-> cp -p -- $REPO/config/mycustos.conf.example $BASE/config/mycustos.conf"* ]]
  [[ "$output" == *"Result: 0 OK, 0 warning(s), 1 failure(s)"* ]]
}

@test "missing credentials file: the command that creates it from the template" {
  rm "$CNF"
  conf
  preflight
  [ "$status" -eq 3 ]
  [[ "$output" == *"-> (umask 077 && cp -- $REPO/config/backup-credentials.conf.example $CNF)"* ]]
}

@test "missing compressor with the other one installed: the switch command" {
  unstub zstd
  stub gzip
  conf compress_level=12
  preflight
  [ "$status" -eq 4 ]
  [[ "$output" == *"FAIL  command zstd: not found in PATH"* ]]
  [[ "$output" == *"-> printf '%s\n' compress=gzip >> $BASE/config/mycustos.conf"* ]]
  [[ "$output" == *"compress_level=6"* ]]
}

@test "read-only: no file created or changed, temporary files removed" {
  mc_test_conf 'config_schema=1'
  server
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
