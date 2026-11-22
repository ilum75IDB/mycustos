#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos inspect": runs bin/mycustos with the mysql mock answering each
# query from a responses file. No database, nothing written.

load test_helper

setup() {
  mc_test_load_core
  MYCUSTOS="$REPO/bin/mycustos"
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME" "$TMPDIR"
  export MC_MOCK_MYSQL_RESPONSES="$BATS_TEST_TMPDIR/responses"
  export MC_MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MC_MOCK_MYSQL_RESPONSES"
  unset MC_MOCK_MYSQL_OUTPUT MC_MOCK_MYSQL_RC MYSQL_TEST_LOGIN_FILE
  CNF="$BASE/config/backup-credentials.conf"
  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$CNF"
  chmod 600 "$CNF"
  conf
}

ME=3e11fa47-71ca-11e1-9e33-c80aa9429562
P2=4f22ab58-82db-22f2-af44-d91bb9530673
Q_VERSION='SELECT @@version, @@version_comment'
Q_MYSQL='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_uuid'
Q_MARIA='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_id'
Q_PLUGIN="SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME = 'group_replication'"
Q_MEMBERS='SELECT MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members'
Q_WSREP='SELECT @@wsrep_on'

KEYS='PRODUCT VERSION VERSION_COMMENT HOSTNAME PORT SOCKET DATADIR SERVER_UUID SERVER_ID AUTH TOPOLOGY ROLE PRIMARY_HOST PRIMARY_IP PRIMARY_PORT ENGINE BACKUP_ALLOWED'

conf() {
  mc_test_conf config_schema=1 auth_method=cnf "$@"
}

answer() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$MC_MOCK_MYSQL_RESPONSES"
}

mysql_server() {
  answer "$Q_VERSION" 0 '8.0.36\tMySQL Community Server - GPL'
  answer "$Q_MYSQL" 0 "db-a\\t3306\\t/run/mysqld/a.sock\\t/data/a/\\t$ME"
}

# inspect [ARGS...]: stdout only in $output, stderr in $BATS_TEST_TMPDIR/err.
inspect() {
  run inspect_raw "$@"
}

inspect_raw() {
  env PATH="$REPO/tests/mocks/bin:$PATH" "$MYCUSTOS" --home "$BASE" inspect "$@" \
    2> "$BATS_TEST_TMPDIR/err"
}

errout() {
  cat "$BATS_TEST_TMPDIR/err"
}

# value KEY: the value printed for KEY.
value() {
  printf '%s\n' "$output" | sed -n "s/^$1=//p"
}

@test "single MySQL instance: exit 0, every key, backup allowed" {
  mysql_server
  answer "$Q_PLUGIN" 0 ''
  inspect
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | cut -d= -f1 | tr '\n' ' ')" = "$KEYS " ]
  [ "$(value PRODUCT)" = MySQL ]
  [ "$(value VERSION_COMMENT)" = 'MySQL Community Server - GPL' ]
  [ "$(value DATADIR)" = /data/a/ ]
  [ "$(value SERVER_UUID)" = "$ME" ]
  [ -z "$(value SERVER_ID)" ]
  [ "$(value AUTH)" = "cnf:$CNF" ]
  [ "$(value TOPOLOGY)" = SINGLE_INSTANCE ]
  [ -z "$(value ROLE)" ]
  [ "$(value ENGINE)" = mysqldump ]
  [ "$(value BACKUP_ALLOWED)" = yes ]
  [ -z "$(errout)" ]
}

@test "SECONDARY: exit 0, backup not allowed, the PRIMARY reported" {
  mysql_server
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 0 "$P2\\t192.0.2.10\\t3306\\tONLINE\\tPRIMARY\\n$ME\\tdb-a\\t3306\\tONLINE\\tSECONDARY"
  inspect
  [ "$status" -eq 0 ]
  [ "$(value TOPOLOGY)" = GROUP_REPLICATION ]
  [ "$(value ROLE)" = SECONDARY ]
  [ "$(value PRIMARY_HOST)" = 192.0.2.10 ]
  [ "$(value PRIMARY_IP)" = 192.0.2.10 ]
  [ "$(value PRIMARY_PORT)" = 3306 ]
  [ "$(value BACKUP_ALLOWED)" = no ]
  [[ "$(errout)" == *'this node is a SECONDARY of the group'* ]]
}

@test "identity mismatch: exit 9, topology not read" {
  mysql_server
  conf expect_port=3310
  inspect
  [ "$status" -eq 9 ]
  [ "$(value PORT)" = 3306 ]
  [ -z "$(value TOPOLOGY)" ]
  [ "$(value BACKUP_ALLOWED)" = no ]
  [[ "$(errout)" == *'expect_port: expected 3310, the server reports 3306'* ]]
  ! grep -q 'group_replication' "$MC_MOCK_LOG"
}

@test "topology blocked (Galera): exit 9" {
  answer "$Q_VERSION" 0 '10.11.6-MariaDB\tmariadb.org binary distribution'
  answer "$Q_MARIA" 0 'db-m\t3307\t/run/m.sock\t/data/m/\t42'
  answer "$Q_WSREP" 0 1
  inspect
  [ "$status" -eq 9 ]
  [ "$(value PRODUCT)" = MariaDB ]
  [ "$(value SERVER_ID)" = 42 ]
  [ "$(value TOPOLOGY)" = GALERA ]
  [ "$(value ENGINE)" = mariadb-backup ]
  [ "$(value BACKUP_ALLOWED)" = no ]
  [[ "$(errout)" == *'Galera cluster, not supported'* ]]
}

@test "an expectation that cannot apply: exit 3" {
  answer "$Q_VERSION" 0 '10.11.6-MariaDB\tmariadb.org binary distribution'
  conf "expect_server_uuid=$ME"
  inspect
  [ "$status" -eq 3 ]
  [[ "$(errout)" == *'use expect_server_id'* ]]
}

@test "server not reachable: exit 4, keys still printed" {
  inspect
  [ "$status" -eq 4 ]
  [ "$(printf '%s\n' "$output" | wc -l | tr -d ' ')" -eq 17 ]
  [ "$(value BACKUP_ALLOWED)" = no ]
  [[ "$(errout)" == *'cannot read the server version and edition'* ]]
}

@test "mysql client missing: exit 4" {
  local tpath="$BATS_TEST_TMPDIR/path" u
  mkdir -p "$tpath"
  for u in bash readlink dirname basename id awk grep sed mktemp rm rmdir; do
    ln -s "$(command -v "$u")" "$tpath/$u"
  done
  run env PATH="$tpath" "$MYCUSTOS" --home "$BASE" inspect
  [ "$status" -eq 4 ]
  [[ "$output" == *'mysql client not found in PATH'* ]]
}

@test "configured engine is reported as is" {
  mysql_server
  answer "$Q_PLUGIN" 0 ''
  conf engine=mysqlbackup
  inspect
  [ "$(value ENGINE)" = mysqlbackup ]
}

@test "auth problem: exit 3, nothing queried" {
  rm -f "$CNF"
  inspect
  [ "$status" -eq 3 ]
  [ ! -s "$MC_MOCK_LOG" ]
}

@test "credentials never printed, nothing written, temporary file removed" {
  mysql_server
  answer "$Q_PLUGIN" 0 ''
  inspect
  [[ "$output" != *S3cr3t* ]]
  [[ "$(errout)" != *S3cr3t* ]]
  ! grep -q 'S3cr3t-value' "$MC_MOCK_LOG"
  [ -z "$(ls -A "$BASE/logs")" ]
  [ -z "$(ls -A "$BASE/data")" ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "keys and values stay in English, the reasons follow the language" {
  mysql_server
  conf expect_port=3310 language=it
  inspect
  [ "$status" -eq 9 ]
  [ "$(value BACKUP_ALLOWED)" = no ]
  [[ "$(errout)" == *'expect_port: atteso 3310, il server riporta 3306'* ]]
}

@test "inspect takes no argument" {
  run "$MYCUSTOS" --home "$BASE" inspect extra
  [ "$status" -eq 2 ]
}
