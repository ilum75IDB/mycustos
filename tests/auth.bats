#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/auth.sh: choice of the authentication method and isolation of the cnf
# credentials. The mysql client and mysql_config_editor are mocks.

load test_helper

setup() {
  mc_test_load_core
  PATH="$REPO/tests/mocks/bin:$PATH"
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$TMPDIR"
  export MC_MOCK_LOG="$BATS_TEST_TMPDIR/mysql.log"
  unset MYSQL_TEST_LOGIN_FILE MC_MOCK_LOGIN_PATHS MC_MOCK_MYSQL_RC
  CNF="$BASE/config/backup-credentials.conf"
}

teardown() {
  mc_auth_cleanup
}

# load_conf KEY=VALUE...: configuration with config_schema=1 plus the given lines.
load_conf() {
  mc_test_conf 'config_schema=1' "$@"
  mc_config_load
}

write_cnf() {
  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$CNF"
  chmod 600 "$CNF"
}

write_login_file() {
  : > "$HOME/.mylogin.cnf"
  chmod 600 "$HOME/.mylogin.cnf"
}

select_rc() {
  rc=0
  mc_auth_select || rc=$?
}

@test "cnf: valid file selected with --defaults-file" {
  write_cnf
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = cnf ]
  [ "${MC_AUTH_OPTS[*]}" = "--defaults-file=$CNF" ]
  [ "$MC_AUTH_DESC" = "option file $CNF" ]
  [ ${#MC_AUTH_WARNINGS[@]} -eq 0 ]
}

@test "cnf: missing file is an error" {
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 1 ]
  [ -z "$MC_AUTH_METHOD" ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_cnf: file not found: $CNF" ]
}

@test "cnf: unreadable file is an error" {
  [ "$(id -u)" -ne 0 ] || skip 'root can read any file'
  write_cnf
  chmod 000 "$CNF"
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_cnf: not a readable file: $CNF" ]
}

@test "cnf: a directory is not accepted" {
  mkdir "$CNF"
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 1 ]
  [[ "${MC_AUTH_ERRORS[0]}" == "auth_cnf: not a readable file:"* ]]
}

@test "cnf: a file without [client] is an error" {
  printf '[mysqldump]\nuser=backup_user\n' > "$CNF"
  chmod 600 "$CNF"
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_cnf: no [client] section in $CNF" ]
}

@test "cnf: permissions wider than 0600 give a warning only" {
  write_cnf
  chmod 640 "$CNF"
  load_conf auth_method=cnf
  select_rc
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = cnf ]
  [[ "${MC_AUTH_WARNINGS[0]}" == "auth_cnf: permissions wider than 0600 on $CNF"* ]]
}

@test "login-path: defined name selected with --login-path" {
  write_login_file
  export MC_MOCK_LOGIN_PATHS='other backup_lp'
  load_conf auth_method=login-path auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = login-path ]
  [ "${MC_AUTH_OPTS[*]}" = '--login-path=backup_lp' ]
  [ "$MC_AUTH_DESC" = 'login path backup_lp' ]
}

@test "login-path: empty name is an error" {
  write_login_file
  load_conf auth_method=login-path || true   # also a configuration error
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = 'auth_login_path: required with auth_method=login-path' ]
}

@test "login-path: missing login file is an error" {
  load_conf auth_method=login-path auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_login_path: login file not found or not readable: $HOME/.mylogin.cnf" ]
}

@test "login-path: MYSQL_TEST_LOGIN_FILE overrides the login file" {
  : > "$BATS_TEST_TMPDIR/alt.cnf"
  export MYSQL_TEST_LOGIN_FILE="$BATS_TEST_TMPDIR/alt.cnf"
  export MC_MOCK_LOGIN_PATHS=backup_lp
  load_conf auth_method=login-path auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 0 ]
}

@test "login-path: undefined name is an error" {
  write_login_file
  export MC_MOCK_LOGIN_PATHS=other
  load_conf auth_method=login-path auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_login_path: login path 'backup_lp' not defined in $HOME/.mylogin.cnf" ]
}

@test "login-path: without mysql_config_editor the name is not verified" {
  write_login_file
  load_conf auth_method=login-path auth_login_path=backup_lp
  mkdir "$BATS_TEST_TMPDIR/bin"
  ln -s "$(command -v grep)" "$BATS_TEST_TMPDIR/bin/grep"
  PATH="$BATS_TEST_TMPDIR/bin" select_rc   # PATH changed for this call only
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = login-path ]
  [ "${MC_AUTH_WARNINGS[0]}" = "auth_login_path: mysql_config_editor not found, 'backup_lp' not verified" ]
}

@test "auto: cnf preferred when the file exists" {
  write_cnf
  write_login_file
  export MC_MOCK_LOGIN_PATHS=backup_lp
  load_conf auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = cnf ]
}

@test "auto: login-path when the cnf file does not exist" {
  write_login_file
  export MC_MOCK_LOGIN_PATHS=backup_lp
  load_conf auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 0 ]
  [ "$MC_AUTH_METHOD" = login-path ]
}

@test "auto: an unusable cnf file is reported, no fallback" {
  printf 'user=backup_user\n' > "$CNF"
  write_login_file
  export MC_MOCK_LOGIN_PATHS=backup_lp
  load_conf auth_login_path=backup_lp
  select_rc
  [ "$rc" -eq 1 ]
  [ -z "$MC_AUTH_METHOD" ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_cnf: no [client] section in $CNF" ]
}

@test "auto: neither cnf nor login path is an error" {
  load_conf
  select_rc
  [ "$rc" -eq 1 ]
  [ "${MC_AUTH_ERRORS[0]}" = "auth_method=auto: $CNF not found and auth_login_path is empty" ]
}

@test "a new selection resets the previous one" {
  write_cnf
  load_conf auth_method=cnf
  mc_auth_select
  rm "$CNF"
  select_rc
  [ "$rc" -eq 1 ]
  [ -z "$MC_AUTH_METHOD" ]
  [ ${#MC_AUTH_OPTS[@]} -eq 0 ]
  [ ${#MC_AUTH_ERRORS[@]} -eq 1 ]
}

@test "mc_auth_run: cnf uses an empty private login file" {
  write_cnf
  load_conf auth_method=cnf
  mc_auth_select
  mc_auth_run mysql -N -e 'SELECT 1'
  grep -qx 'login_file_empty=yes' "$MC_MOCK_LOG"
  grep -qx "arg=--defaults-file=$CNF" "$MC_MOCK_LOG"
  [ "$(grep -m1 "^arg=" "$MC_MOCK_LOG")" = "arg=--defaults-file=$CNF" ]   # first option
  [[ "$MC_AUTH_EMPTY_LOGIN" == "$TMPDIR"/mycustos.* ]]
  [ "$(ls -ld -- "$MC_AUTH_EMPTY_LOGIN" | cut -c1-10)" = '-rw-------' ]
}

@test "mc_auth_run: login-path leaves the login file alone" {
  write_login_file
  export MC_MOCK_LOGIN_PATHS=backup_lp
  load_conf auth_method=login-path auth_login_path=backup_lp
  mc_auth_select
  mc_auth_run mysql -N -e 'SELECT 1'
  grep -qx 'login_file=<unset>' "$MC_MOCK_LOG"
  grep -qx 'arg=--login-path=backup_lp' "$MC_MOCK_LOG"
  [ -z "$MC_AUTH_EMPTY_LOGIN" ]
}

@test "mc_auth_run: requires mc_auth_select" {
  run mc_auth_run mysql -e 'SELECT 1'
  [ "$status" -eq 1 ]
  [[ "$output" == *"mc_auth_select not called"* ]]
}

@test "mc_auth_test: success, failure and socket option" {
  write_cnf
  load_conf auth_method=cnf mysql_socket=/run/mysqld/mysqld.sock
  mc_auth_select
  mc_auth_test
  grep -qx 'arg=--socket=/run/mysqld/mysqld.sock' "$MC_MOCK_LOG"
  grep -qx 'arg=SELECT 1' "$MC_MOCK_LOG"
  export MC_MOCK_MYSQL_RC=1
  rc=0
  mc_auth_test || rc=$?
  [ "$rc" -ne 0 ]
}

@test "mc_auth_cleanup removes the isolation files" {
  write_cnf
  load_conf auth_method=cnf
  mc_auth_select
  mc_auth_prepare
  dir=${MC_AUTH_EMPTY_LOGIN%/*}
  [ -d "$dir" ]
  mc_auth_cleanup
  [ ! -e "$dir" ]
  [ -z "$MC_AUTH_EMPTY_LOGIN" ]
  mc_auth_cleanup
}

@test "the password never appears in descriptions, options or findings" {
  write_cnf
  chmod 644 "$CNF"
  load_conf auth_method=cnf
  mc_auth_select
  mc_auth_run mysql -e 'SELECT 1'
  run mc_auth_print_findings
  [[ "$output" == *"permissions wider than 0600"* ]]
  [[ "$output$MC_AUTH_DESC${MC_AUTH_OPTS[*]}" != *S3cr3t* ]]
  ! grep -q S3cr3t "$MC_MOCK_LOG"
}

@test "the shipped credentials example is a valid cnf file" {
  cp "$REPO/config/backup-credentials.conf.example" "$CNF"
  chmod 600 "$CNF"
  load_conf auth_method=cnf
  mc_auth_select
  [ "$MC_AUTH_METHOD" = cnf ]
}
