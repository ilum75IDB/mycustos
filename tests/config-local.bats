#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/config.sh: the optional mycustos.local.conf, read after mycustos.conf,
# overrides it key by key.

load test_helper

setup() {
  mc_test_load_core
  unset MYCUSTOS_CONFIG_FILE MYCUSTOS_LANGUAGE MYCUSTOS_RETENTION_DAYS MYCUSTOS_INSTANCE
  CONF=$BASE/config/mycustos.conf
  LOCAL=$BASE/config/mycustos.local.conf
  mc_test_conf config_schema=1 instance=shared retention_days=7 compress=zstd
  MYCUSTOS="$REPO/bin/mycustos"
}

# local LINE...: writes mycustos.local.conf (not writable by group or others).
local_conf() {
  printf '%s\n' "$@" > "$LOCAL"
  chmod 644 "$LOCAL"
}

load_rc() {
  rc=0
  mc_config_load || rc=$?
}

@test "without a local file: the main file only" {
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
  [ "$MC_CONFIG_LOCAL_LOADED" -eq 0 ]
  [ "$MC_CONFIG_LOCAL_FILE" = "$LOCAL" ]
  [ "${MC_CONF[instance]}" = shared ]
  [ "$(mc_config_files_desc)" = "$CONF" ]
}

@test "the local file overrides only the keys it sets" {
  local_conf 'instance=db-a' 'retention_days = 14'
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
  [ "$MC_CONFIG_LOCAL_LOADED" -eq 1 ]
  [ "${MC_CONF[instance]}" = db-a ]
  [ "${MC_CONF[retention_days]}" = 14 ]
  [ "${MC_CONF[compress]}" = zstd ]
  [ "${MC_CONF_ORIGIN[instance]}" = "$LOCAL:1" ]
  [ "${MC_CONF_ORIGIN[retention_days]}" = "$LOCAL:2" ]
  [ "${MC_CONF_ORIGIN[compress]}" = "$CONF:4" ]
  [ "${MC_CONF_ORIGIN[packaging]}" = default ]
  [ "$(mc_config_files_desc)" = "$CONF + $LOCAL" ]
}

@test "a key only in the local file overrides the default" {
  local_conf 'packaging=split'
  load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[packaging]}" = split ]
  [ "${MC_CONF_ORIGIN[packaging]}" = "$LOCAL:1" ]
}

@test "the environment and the command line still win over the local file" {
  local_conf 'retention_days=14' 'backup_type=full'
  MYCUSTOS_RETENTION_DAYS=3 load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[retention_days]}" = 3 ]
  [ "${MC_CONF_ORIGIN[retention_days]}" = "env MYCUSTOS_RETENTION_DAYS" ]
  mc_config_set_cli backup_type incr --type
  [ "${MC_CONF[backup_type]}" = incr ]
}

@test "the same key twice in the local file is an error" {
  local_conf 'instance=a' 'instance=b'
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [ "$output" = "$LOCAL:2: duplicate key: instance (already set at line 1)" ]
}

@test "the local file uses the same whitelist and validation" {
  local_conf 'retension_days=3' 'compress_level=99'
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [[ "$output" == *"$LOCAL:1: unknown key: retension_days"* ]]
  [[ "$output" == *"$LOCAL:2: compress_level: must be an integer between 1 and 19"* ]]
}

@test "the local file may use the expansions, \${MYCUSTOS_CONFIG} is the shared directory" {
  local_conf 'auth_cnf=${MYCUSTOS_CONFIG}/other.cnf'
  load_rc
  [ "$rc" -eq 0 ]
  [ "${MC_CONF[auth_cnf]}" = "$BASE/config/other.cnf" ]
}

@test "an unsafe local file is refused like the main one" {
  local_conf 'instance=db-a'
  chmod 666 "$LOCAL"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [ "$output" = "$LOCAL: writable by group or others (run: chmod go-w $LOCAL)" ]
}

@test "a symbolic link as local file is refused, even a dangling one" {
  ln -s "$BASE/nowhere.conf" "$LOCAL"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [[ "$output" == "$LOCAL: must be a regular file, not a symbolic link"* ]]
}

@test "the main file stays required, even with a local file" {
  local_conf 'instance=db-a'
  rm -f "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [ "$output" = "$CONF: configuration file not found or not readable" ]
}

@test "--config FILE.conf uses FILE.local.conf next to it" {
  mkdir -p "$BASE/etc"
  cp -p "$CONF" "$BASE/etc/db-b.conf"
  printf '%s\n' 'instance=db-b' > "$BASE/etc/db-b.local.conf"
  chmod 644 "$BASE/etc/db-b.local.conf"
  MC_OPT_CONFIG="$BASE/etc/db-b.conf"
  load_rc
  [ "$rc" -eq 0 ]
  [ "$MC_CONFIG_LOCAL_FILE" = "$BASE/etc/db-b.local.conf" ]
  [ "${MC_CONF[instance]}" = db-b ]
}

@test "a name without .conf gets .local.conf appended" {
  [ "$(mc_config_local_file /x/settings)" = /x/settings.local.conf ]
  [ "$(mc_config_local_file /x/mycustos.conf)" = /x/mycustos.local.conf ]
}

@test "the language is peeked from the local file first" {
  mc_test_conf config_schema=1 language=de
  run mc_config_peek language
  [ "$output" = de ]
  local_conf 'language=it'
  run mc_config_peek language
  [ "$output" = it ]
  run "$MYCUSTOS" --home "$BASE" check-config
  [[ "$output" == *"config_schema supportato:"* ]]
}

@test "config show and check-config name both files and every origin" {
  local_conf 'instance=db-a'
  run "$MYCUSTOS" --home "$BASE" --lang en config show
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "# mycustos config show - $CONF + $LOCAL" ]
  [[ "$output" == *"instance=db-a"*"# $LOCAL:1"* ]]
  [[ "$output" == *"# $CONF:4"* ]]
  run "$MYCUSTOS" --home "$BASE" --lang en check-config
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "mycustos check-config - $CONF + $LOCAL" ]
}

@test "the shipped local example loads on top of the shipped main example" {
  cp "$REPO/config/mycustos.conf.example" "$CONF"
  cp "$REPO/config/mycustos.local.conf.example" "$LOCAL"
  chmod go-w "$CONF" "$LOCAL"
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
  [ "$MC_CONFIG_LOCAL_LOADED" -eq 1 ]
}
