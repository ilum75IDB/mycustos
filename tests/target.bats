#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/target.sh: identity of the instance, with the mysql mock answering
# each query from a responses file. No database, nothing written.

load test_helper

setup() {
  mc_test_load_core
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME" "$TMPDIR"
  PATH="$REPO/tests/mocks/bin:$PATH"
  export MC_MOCK_MYSQL_RESPONSES="$BATS_TEST_TMPDIR/responses"
  export MC_MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  unset MC_MOCK_MYSQL_OUTPUT MC_MOCK_MYSQL_RC MYSQL_TEST_LOGIN_FILE
  CNF="$BASE/config/backup-credentials.conf"
  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$CNF"
  chmod 600 "$CNF"
}

UUID=3e11fa47-71ca-11e1-9e33-c80aa9429562
Q_VERSION='SELECT @@version, @@version_comment'
Q_MYSQL='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_uuid'
Q_MARIA='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_id'

# answer SQL RC OUTPUT: appends one line to the responses file.
answer() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$MC_MOCK_MYSQL_RESPONSES"
}

mysql_server() {
  answer "$Q_VERSION" 0 '8.0.36-commercial\tMySQL Enterprise Server - Commercial'
  answer "$Q_MYSQL" 0 "db-a\\t3306\\t/run/mysqld/a.sock\\t/data/a/\\t$UUID"
}

mariadb_server() {
  answer "$Q_VERSION" 0 '10.11.6-MariaDB\tmariadb.org binary distribution'
  answer "$Q_MARIA" 0 'db-m\t3307\t/run/mysqld/m.sock\t/data/m/\t42'
}

# check KEY=VALUE...: load the configuration with the given lines and run the check.
check() {
  mc_test_conf config_schema=1 auth_method=cnf "$@"
  mc_config_load || { mc_test_errors; return 99; }
  mc_auth_select || return 98
  mc_target_check
}

errors() {
  printf '%s\n' "${MC_TARGET_ERRORS[@]}"
}

@test "MySQL without expectations: ok, every value read" {
  mysql_server
  check
  [ "$MC_TARGET_STATUS" = ok ]
  [ "$MC_TARGET_PRODUCT" = MySQL ]
  [ "$MC_TARGET_VERSION" = 8.0.36-commercial ]
  [ "$MC_TARGET_VERSION_COMMENT" = 'MySQL Enterprise Server - Commercial' ]
  [ "$MC_TARGET_HOSTNAME" = db-a ]
  [ "$MC_TARGET_PORT" = 3306 ]
  [ "$MC_TARGET_SOCKET" = /run/mysqld/a.sock ]
  [ "$MC_TARGET_DATADIR" = /data/a/ ]
  [ "$MC_TARGET_SERVER_UUID" = "$UUID" ]
  [ -z "$MC_TARGET_SERVER_ID" ]
  [ ${#MC_TARGET_ERRORS[@]} -eq 0 ]
}

@test "MariaDB: server_id read, server_uuid never asked" {
  mariadb_server
  check
  [ "$MC_TARGET_STATUS" = ok ]
  [ "$MC_TARGET_PRODUCT" = MariaDB ]
  [ "$MC_TARGET_SERVER_ID" = 42 ]
  [ -z "$MC_TARGET_SERVER_UUID" ]
  ! grep -q 'server_uuid' "$MC_MOCK_LOG"
}

@test "MariaDB recognised from @@version alone" {
  answer "$Q_VERSION" 0 '10.6.16-MariaDB-log\tSource distribution'
  answer "$Q_MARIA" 0 'db-m\t3307\t/run/m.sock\t/data/m/\t7'
  check
  [ "$MC_TARGET_PRODUCT" = MariaDB ]
}

@test "every expectation that matches: ok" {
  mysql_server
  check mysql_socket=/run/mysqld/a.sock expect_hostname=DB-A expect_port=3306 \
    expect_datadir=/data/a expect_server_uuid=3E11FA47-71CA-11E1-9E33-C80AA9429562
  [ "$MC_TARGET_STATUS" = ok ]
}

@test "each mismatch is rejected, with expected and actual values" {
  local line
  for line in mysql_socket=/run/mysqld/b.sock expect_hostname=db-b expect_port=3310 \
              expect_datadir=/data/b expect_server_uuid=00000000-0000-0000-0000-000000000000; do
    : > "$MC_MOCK_MYSQL_RESPONSES"
    mysql_server
    run check "$line"
    [ "$status" -eq 1 ]
    check "$line" || true
    [ "$MC_TARGET_STATUS" = rejected ]
    [[ "$(errors)" == "${line%%=*}: expected ${line#*=}, the server reports "* ]]
  done
}

@test "all the mismatches are reported together" {
  mysql_server
  check expect_hostname=db-b expect_port=3310 || true
  [ "$MC_TARGET_STATUS" = rejected ]
  [ ${#MC_TARGET_ERRORS[@]} -eq 2 ]
}

@test "MariaDB: expect_server_id mismatch is rejected" {
  mariadb_server
  check expect_server_id=43 || true
  [ "$MC_TARGET_STATUS" = rejected ]
  [[ "$(errors)" == 'expect_server_id: expected 43, the server reports 42' ]]
}

@test "expect_server_uuid on MariaDB is a configuration error, before the metadata query" {
  mariadb_server
  check expect_server_uuid="$UUID" || true
  [ "$MC_TARGET_STATUS" = config ]
  [[ "$(errors)" == *"use expect_server_id"* ]]
  ! grep -q '@@hostname' "$MC_MOCK_LOG"
}

@test "expect_server_id on MySQL is a configuration error" {
  mysql_server
  check expect_server_id=1 || true
  [ "$MC_TARGET_STATUS" = config ]
  [[ "$(errors)" == *"use expect_server_uuid"* ]]
}

@test "server not reachable: unreachable" {
  check || true
  [ "$MC_TARGET_STATUS" = unreachable ]
  [[ "$(errors)" == 'cannot read the server version and edition' ]]
}

@test "metadata query failing: unreachable" {
  answer "$Q_VERSION" 0 '8.0.36\tMySQL Community Server - GPL'
  answer "$Q_MYSQL" 1 ''
  check || true
  [ "$MC_TARGET_STATUS" = unreachable ]
  [[ "$(errors)" == *"server_uuid"* ]]
}

@test "a NULL or empty value rejects the target, without shifting the others" {
  answer "$Q_VERSION" 0 '8.0.36\tMySQL Community Server - GPL'
  answer "$Q_MYSQL" 0 "db-a\\t3306\\t\\t/data/a/\\tNULL"
  check || true
  [ "$MC_TARGET_STATUS" = rejected ]
  [ "$MC_TARGET_DATADIR" = /data/a/ ]
  [[ "$(errors)" == *"@@socket is empty"* ]]
  [[ "$(errors)" == *"@@server_uuid is empty"* ]]
}

@test "a non numeric port or server_id is rejected" {
  answer "$Q_VERSION" 0 '10.11.6-MariaDB\tmariadb.org binary distribution'
  answer "$Q_MARIA" 0 'db-m\tabc\t/run/m.sock\t/data/m/\tx1'
  check || true
  [ "$MC_TARGET_STATUS" = rejected ]
  [[ "$(errors)" == *"@@port"*"abc"* ]]
  [[ "$(errors)" == *"@@server_id"*"x1"* ]]
}

@test "the credentials never reach the command line" {
  mysql_server
  check
  grep -q -- "--defaults-file=$CNF" "$MC_MOCK_LOG"
  ! grep -q 'S3cr3t-value' "$MC_MOCK_LOG"
}

@test "messages follow the language" {
  mysql_server
  mc_i18n_select it
  check expect_port=3310 || true
  [[ "$(errors)" == 'expect_port: atteso 3310, il server riporta 3306' ]]
}

@test "config: expect_* keys are validated" {
  mc_test_conf config_schema=1 expect_port=70000 expect_server_uuid=not-a-uuid \
    expect_server_id=-1 expect_datadir=relative 'expect_hostname=bad name'
  mc_config_load || true
  [[ "$(mc_test_errors)" == *"expect_port: must be an integer between 1 and 65535"* ]]
  [[ "$(mc_test_errors)" == *"expect_server_uuid: must be a UUID"* ]]
  [[ "$(mc_test_errors)" == *"expect_server_id: must be an integer between 0 and 4294967295"* ]]
  [[ "$(mc_test_errors)" == *"expect_datadir: must be an absolute path"* ]]
  [[ "$(mc_test_errors)" == *"expect_hostname: must start with"* ]]
}

@test "config: expect_* keys accept empty values and the largest server_id" {
  mc_test_conf config_schema=1 expect_port= expect_server_id=4294967295
  mc_config_load
  [ -z "${MC_CONF[expect_port]}" ]
  [ "${MC_CONF[expect_server_id]}" = 4294967295 ]
}

@test "exit code 9 is the wrong-target code" {
  [ "$MC_EX_TARGET" -eq 9 ]
  [ "$(mc_exit_describe 9)" = 'wrong or unsupported target' ]
}
