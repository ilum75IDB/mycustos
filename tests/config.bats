#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/config.sh: the KEY=value parser, its whitelist, expansions and precedence.
# mc_config_load runs in the test shell (not with "run") to inspect MC_CONF.

load test_helper

setup() {
  mc_test_load_core
  unset MYCUSTOS_CONFIG_FILE MYCUSTOS_RETENTION_DAYS MYCUSTOS_INSTANCE MYCUSTOS_CONFIG_SCHEMA
}

load_rc() {
  rc=0
  mc_config_load || rc=$?
}

@test "the shipped example loads without errors" {
  cp "$REPO/config/mycustos.conf.example" "$BASE/config/mycustos.conf"
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[instance]}" = main ]
  [ "${MC_CONF[data_dir]}" = "$BASE/data" ]
  [ "${MC_CONF[auth_cnf]}" = "$BASE/config/backup-credentials.conf" ]
  [[ "${MC_CONF_ORIGIN[data_dir]}" == "$BASE/config/mycustos.conf:"* ]]
}

@test "the example sets every key of the schema" {
  for key in "${MC_CONFIG_KEYS[@]}"; do
    grep -q "^$key=" "$REPO/config/mycustos.conf.example"
  done
}

@test "config_schema alone gives the defaults" {
  mc_test_conf 'config_schema=1'
  load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[backup_type]}" = full ]
  [ "${MC_CONF[logs_dir]}" = "$BASE/logs" ]
  [ "${MC_CONF_ORIGIN[backup_type]}" = default ]
  [ "$MYCUSTOS_CONFIG" = "$BASE/config" ]
  [ "$MYCUSTOS_DATA" = "$BASE/data" ]
  [ "$MYCUSTOS_LOGS" = "$BASE/logs" ]
}

@test "a missing file is an error" {
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"mycustos.conf: configuration file not found or not readable" ]]
}

@test "config_schema is required" {
  mc_test_conf 'instance=db1'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"config_schema: missing: add config_schema=1" ]]
}

@test "an unsupported config_schema is an error" {
  mc_test_conf 'config_schema=2'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"unsupported value '2'"* ]]
}

@test "an unknown key is an error with file and line" {
  mc_test_conf 'config_schema=1' '' 'retention_dayz=3'
  load_rc
  [ "$rc" -eq 1 ]
  [ "$(mc_test_errors)" = "$BASE/config/mycustos.conf:3: unknown key: retention_dayz" ]
}

@test "a duplicate key is an error" {
  mc_test_conf 'config_schema=1' 'instance=a' 'instance=b'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *":3: duplicate key: instance (already set at line 2)" ]]
}

@test "a line without = is an error" {
  mc_test_conf 'config_schema=1' 'instance'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *":2: expected key=value" ]]
}

@test "comments, blank lines, CRLF, spaces and quotes are handled" {
  printf '%s\r\n' '# comment' '' '  config_schema = 1  ' '   # indented comment' \
    'instance = "db-01"' "databases='app,crm'" > "$BASE/config/mycustos.conf"
  printf 'retention_days=3' >> "$BASE/config/mycustos.conf"   # no final newline
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[instance]}" = db-01 ]
  [ "${MC_CONF[databases]}" = app,crm ]
  [ "${MC_CONF[retention_days]}" = 3 ]
}

@test "inline comments are not stripped" {
  mc_test_conf 'config_schema=1' 'retention_days=7 # days'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"retention_days: must be an integer between 0 and 3650 (found '7 # days')" ]]
}

@test "an invalid enum value lists the accepted ones" {
  mc_test_conf 'config_schema=1' 'compress=xz'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"compress: must be one of: gzip, zstd (found 'xz')" ]]
}

@test "integers are decimal and range-checked" {
  mc_test_conf 'config_schema=1' 'retention_days=08'
  load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[retention_days]}" = 8 ]
  mc_test_conf 'config_schema=1' 'compress_level=0'
  load_rc
  [ "$rc" -eq 1 ]
}

@test "compress_level above 9 is rejected only with gzip" {
  mc_test_conf 'config_schema=1' 'compress=zstd' 'compress_level=12'
  load_rc
  [ "$rc" -eq 0 ]
  mc_test_conf 'config_schema=1' 'compress=gzip' 'compress_level=12'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *"compress_level: must be between 1 and 9 with compress=gzip"* ]]
}

@test "names, database lists and paths are validated" {
  mc_test_conf 'config_schema=1' 'instance=db 1' 'databases=app, crm' 'data_dir=data' \
    'logs_dir=/' 'mysql_socket=run/mysql.sock'
  load_rc
  [ "$rc" -eq 1 ]
  [ "${#MC_CONFIG_ERRORS[@]}" -eq 5 ]
  [[ "$(mc_test_errors)" == *"instance: must start with a letter or digit"* ]]
  [[ "$(mc_test_errors)" == *"databases: must be ALL or a comma-separated list"* ]]
  [[ "$(mc_test_errors)" == *"data_dir: must be an absolute path other than / (found 'data')"* ]]
  [[ "$(mc_test_errors)" == *"logs_dir: must be an absolute path other than / (found '/')"* ]]
  [[ "$(mc_test_errors)" == *"mysql_socket: must be an absolute path"* ]]
}

@test "only the MYCUSTOS directories are expanded" {
  mc_test_conf 'config_schema=1' 'data_dir=/backup/data' 'logs_dir=${MYCUSTOS_HOME}/log' \
    'auth_cnf=${MYCUSTOS_LOGS}/../x.cnf'
  load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[auth_cnf]}" = "$BASE/log/../x.cnf" ]
  [ "$MYCUSTOS_DATA" = /backup/data ]
}

@test "other variables are rejected" {
  mc_test_conf 'config_schema=1' 'auth_cnf=${HOME}/x.cnf' 'mysql_socket=$HOME/s.sock' \
    'data_dir=${MYCUSTOS_DATA}/x'
  load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == *'auth_cnf: ${HOME} is not allowed here'* ]]
  [[ "$(mc_test_errors)" == *'mysql_socket: only ${MYCUSTOS_HOME}'*'can be expanded'* ]]
  [[ "$(mc_test_errors)" == *'data_dir: ${MYCUSTOS_DATA} is not allowed here'* ]]
}

@test "the file is never executed" {
  mc_test_conf 'config_schema=1' "touch $BASE/pwned1" "instance=\$(touch $BASE/pwned2)" \
    "auth_cnf=/x\`touch $BASE/pwned3\`"
  load_rc
  [ "$rc" -eq 1 ]
  [ ! -e "$BASE/pwned1" ]
  [ ! -e "$BASE/pwned2" ]
  [ ! -e "$BASE/pwned3" ]
}

@test "the environment overrides the file, except config_schema" {
  mc_test_conf 'config_schema=1' 'retention_days=7'
  MYCUSTOS_RETENTION_DAYS=3 MYCUSTOS_CONFIG_SCHEMA=2 load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[retention_days]}" = 3 ]
  [ "${MC_CONF_ORIGIN[retention_days]}" = "env MYCUSTOS_RETENTION_DAYS" ]
  [ "${MC_CONF[config_schema]}" = 1 ]
}

@test "an invalid environment value names its origin" {
  mc_test_conf 'config_schema=1'
  MYCUSTOS_INSTANCE='a b' load_rc
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == "env MYCUSTOS_INSTANCE: instance: "* ]]
}

@test "a command-line option overrides the environment" {
  mc_test_conf 'config_schema=1'
  MYCUSTOS_BACKUP_TYPE=full load_rc
  [ "$rc" -eq 0 ]
  mc_config_set_cli backup_type incr --type
  [ "${MC_CONF[backup_type]}" = incr ]
  [ "${MC_CONF_ORIGIN[backup_type]}" = "option --type" ]
  rc=0
  mc_config_set_cli backup_type weekly --type || rc=$?
  [ "$rc" -eq 1 ]
  [[ "$(mc_test_errors)" == "option --type: backup_type: must be one of: full, incr (found 'weekly')" ]]
}

@test "--config and MYCUSTOS_CONFIG_FILE select the file and the config directory" {
  mkdir -p "$BATS_TEST_TMPDIR/elsewhere"
  printf 'config_schema=1\ninstance=from-env\n' > "$BATS_TEST_TMPDIR/elsewhere/env.conf"
  printf 'config_schema=1\ninstance=from-option\n' > "$BATS_TEST_TMPDIR/elsewhere/opt.conf"
  MYCUSTOS_CONFIG_FILE="$BATS_TEST_TMPDIR/elsewhere/env.conf" load_rc
  [ "${MC_CONF[instance]}" = from-env ]
  [ "$MYCUSTOS_CONFIG" = "$(cd "$BATS_TEST_TMPDIR/elsewhere" && pwd -P)" ]
  cd "$BATS_TEST_TMPDIR"
  MC_OPT_CONFIG=elsewhere/opt.conf
  MYCUSTOS_CONFIG_FILE="$BATS_TEST_TMPDIR/elsewhere/env.conf" load_rc
  [ "${MC_CONF[instance]}" = from-option ]
  [ "$MC_CONFIG_FILE" = "$MYCUSTOS_CONFIG/opt.conf" ]
}

@test "mc_config_get prints a value and rejects unknown keys" {
  mc_test_conf 'config_schema=1'
  load_rc
  [ "$(mc_config_get packaging)" = simple ]
  run mc_config_get nope
  [ "$status" -eq 1 ]
}

@test "mc_config_load_or_die exits with the config exit code and lists every problem" {
  mc_test_conf 'config_schema=1' 'engine=bogus' 'nope=1'
  run mc_config_load_or_die
  [ "$status" -eq 3 ]
  [[ "$output" == *"mycustos: config: "*"unknown key: nope"* ]]
  [[ "$output" == *"mycustos: config: "*"engine: must be one of"* ]]
}

@test "loading works under set -u, as in bin/mycustos" {
  mc_test_conf 'config_schema=1'
  run bash -uo pipefail -c '
    MYCUSTOS_HOME=$1 MYCUSTOS_MODULES=$2 MC_OPT_CONFIG=""
    for m in errors common log config; do source "$MYCUSTOS_MODULES/core/$m.sh"; done
    mc_config_load_or_die
    mc_config_print_errors
    mc_config_get instance' _ "$BASE" "$MYCUSTOS_MODULES"
  [ "$status" -eq 0 ]
  [ "$output" = main ]
}
