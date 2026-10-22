#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos config show|migrate", through bin/mycustos.

load test_helper

setup() {
  mc_test_load_core
  MYCUSTOS="$REPO/bin/mycustos"
  unset MYCUSTOS_CONFIG_FILE MYCUSTOS_RETENTION_DAYS MYCUSTOS_COMPRESS
  CONF="$BASE/config/mycustos.conf"
}

show() {
  run "$MYCUSTOS" --home "$BASE" config show "$@"
}

# line KEY: the output line of KEY, with the padding squeezed.
line() {
  printf '%s\n' "$output" | grep "^$1=" | tr -s ' '
}

@test "one line per key, in schema order, after a header" {
  mc_test_conf 'config_schema=1'
  show
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "# mycustos config show - $CONF" ]
  [ "${#lines[@]}" -eq $(( ${#MC_CONFIG_KEYS[@]} + 1 )) ]
  for i in "${!MC_CONFIG_KEYS[@]}"; do
    [[ "${lines[i + 1]}" == "${MC_CONFIG_KEYS[i]}="* ]]
  done
}

@test "each origin: file line, environment, default" {
  mc_test_conf 'config_schema=1' '' 'instance=db1'
  MYCUSTOS_RETENTION_DAYS=3 show
  [ "$status" -eq 0 ]
  [ "$(line config_schema)" = "config_schema=1 # $CONF:1" ]
  [ "$(line instance)" = "instance=db1 # $CONF:3" ]
  [ "$(line retention_days)" = 'retention_days=3 # env MYCUSTOS_RETENTION_DAYS' ]
  [ "$(line backup_type)" = 'backup_type=full # default' ]
}

@test "precedence: environment over file over default" {
  mc_test_conf 'config_schema=1' 'compress=gzip' 'retention_days=10'
  MYCUSTOS_COMPRESS=zstd show
  [ "$(line compress)" = 'compress=zstd # env MYCUSTOS_COMPRESS' ]
  [ "$(line retention_days)" = "retention_days=10 # $CONF:3" ]
  [ "$(line packaging)" = 'packaging=simple # default' ]
}

@test "expanded values are shown, not the raw ones" {
  mc_test_conf 'config_schema=1'
  show
  [ "$(line data_dir)" = "data_dir=$BASE/data # default" ]
  [ "$(line auth_cnf)" = "auth_cnf=$BASE/config/backup-credentials.conf # default" ]
}

@test "values and origins can be split back" {
  mc_test_conf 'config_schema=1' 'instance=db1'
  show
  l=$(printf '%s\n' "$output" | grep '^instance=')
  key=${l%%=*}
  origin=${l##*  # }
  value=${l#*=}
  value=${value%  # *}
  value=${value%"${value##*[! ]}"}
  [ "$key" = instance ]
  [ "$value" = db1 ]
  [ "$origin" = "$CONF:2" ]
}

@test "the credentials file content is never shown" {
  mc_test_conf 'config_schema=1'
  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$BASE/config/backup-credentials.conf"
  show
  [ "$status" -eq 0 ]
  [[ "$output" != *S3cr3t* ]]
}

@test "invalid configuration: errors and exit 3" {
  mc_test_conf 'config_schema=1' 'retention_days=forever'
  show
  [ "$status" -eq 3 ]
  [[ "$output" == *"retention_days: must be an integer"* ]]
}

@test "config migrate is not implemented yet: exit 69" {
  run "$MYCUSTOS" --home "$BASE" config migrate /tmp/backup.conf
  [ "$status" -eq 69 ]
  [[ "$output" == *"config migrate is not implemented yet"* ]]
}

@test "missing or unknown sub-command: exit 2" {
  run "$MYCUSTOS" --home "$BASE" config
  [ "$status" -eq 2 ]
  [[ "$output" == *"config: missing sub-command (show or migrate)"* ]]
  run "$MYCUSTOS" --home "$BASE" config list
  [ "$status" -eq 2 ]
  [[ "$output" == *"config: unknown sub-command: list"* ]]
  mc_test_conf 'config_schema=1'
  show extra
  [ "$status" -eq 2 ]
}
