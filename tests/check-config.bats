#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos check-config": validation report of mycustos.conf, through bin/mycustos.

load test_helper

setup() {
  mc_test_load_core
  MYCUSTOS="$REPO/bin/mycustos"
  unset MYCUSTOS_CONFIG_FILE MYCUSTOS_RETENTION_DAYS MYCUSTOS_ENGINE
  CONF="$BASE/config/mycustos.conf"
}

check() {
  run "$MYCUSTOS" --home "$BASE" check-config "$@"
}

@test "the shipped example is valid" {
  cp "$REPO/config/mycustos.conf.example" "$CONF"
  check
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos check-config - $CONF"* ]]
  [[ "$output" == *"config_schema supported: 1 (mycustos "* ]]
  [[ "$output" == *"Result: valid, 0 warning(s)" ]]
}

@test "missing file: exit 3" {
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $CONF: configuration file not found or not readable"* ]]
}

@test "every error is reported in one run, with its line" {
  mc_test_conf 'config_schema=1' 'retention_days=forever' 'engine=rsync' 'colour=blue' 'retention_days=3'
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $CONF:4: unknown key: colour"* ]]
  [[ "$output" == *"ERROR $CONF:5: duplicate key: retention_days (already set at line 2)"* ]]
  [[ "$output" == *"ERROR $CONF:2: retention_days: must be an integer between 0 and 3650"* ]]
  [[ "$output" == *"ERROR $CONF:3: engine: must be one of:"* ]]
  [[ "$output" == *"Result: invalid, 4 error(s)" ]]
}

@test "errors from the environment name the variable" {
  mc_test_conf 'config_schema=1'
  MYCUSTOS_RETENTION_DAYS=-1 check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR env MYCUSTOS_RETENTION_DAYS: retention_days:"* ]]
}

@test "unsupported config_schema" {
  mc_test_conf 'config_schema=2'
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"config_schema: unsupported value '2' (this version reads config_schema=1)"* ]]
}

@test "cross-key: compress_level above 9 with gzip" {
  mc_test_conf 'config_schema=1' 'compress=gzip' 'compress_level=12'
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $CONF:3: compress_level: must be between 1 and 9 with compress=gzip"* ]]
}

@test "cross-key: incr only with mysqlbackup" {
  mc_test_conf 'config_schema=1' 'backup_type=incr' 'engine=mysqldump'
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $CONF:2: backup_type: incr is supported only with engine=mysqlbackup (found engine=mysqldump)"* ]]
  mc_test_conf 'config_schema=1' 'backup_type=incr' 'engine=mysqlbackup'
  check
  [ "$status" -eq 0 ]
}

@test "cross-key: login-path needs auth_login_path" {
  mc_test_conf 'config_schema=1' 'auth_method=login-path'
  check
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $CONF:2: auth_login_path: required with auth_method=login-path"* ]]
  mc_test_conf 'config_schema=1' 'auth_method=login-path' 'auth_login_path=backup_lp'
  check
  [ "$status" -eq 0 ]
}

@test "warning: incr with engine=auto" {
  mc_test_conf 'config_schema=1' 'backup_type=incr'
  check
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN  $CONF:2: backup_type=incr with engine=auto works only when the server edition selects mysqlbackup"* ]]
  [[ "$output" == *"Result: valid, 1 warning(s)" ]]
}

@test "warnings: settings ignored by the chosen auth_method" {
  mc_test_conf 'config_schema=1' 'auth_method=cnf' 'auth_login_path=backup_lp'
  check
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN  $CONF:3: auth_login_path is ignored with auth_method=cnf"* ]]
  mc_test_conf 'config_schema=1' 'auth_method=login-path' 'auth_login_path=backup_lp' 'auth_cnf=/etc/x.cnf'
  check
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN  $CONF:4: auth_cnf is ignored with auth_method=login-path"* ]]
}

@test "warning: logs_dir equal to data_dir" {
  mc_test_conf 'config_schema=1' 'data_dir=/srv/backup' 'logs_dir=/srv/backup'
  check
  [ "$status" -eq 0 ]
  [[ "$output" == *"WARN  $CONF:3: logs_dir is the same directory as data_dir"* ]]
}

@test "--config selects another file" {
  printf 'config_schema=1\n' > "$BASE/other.conf"
  run "$MYCUSTOS" --home "$BASE" --config "$BASE/other.conf" check-config
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos check-config - $BASE/other.conf"* ]]
}

@test "read-only: nothing created or changed" {
  cp "$REPO/config/mycustos.conf.example" "$CONF"
  before=$(find "$BASE" -exec ls -ld {} + | sort)
  check
  [ "$status" -eq 0 ]
  [ "$(find "$BASE" -exec ls -ld {} + | sort)" = "$before" ]
}

@test "unexpected argument is a usage error" {
  mc_test_conf 'config_schema=1'
  check extra
  [ "$status" -eq 2 ]
  [[ "$output" == *"check-config: unknown argument: extra"* ]]
}
