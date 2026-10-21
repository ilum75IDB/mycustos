#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/log.sh and core/errors.sh.

bats_require_minimum_version 1.5.0
load test_helper

setup() {
  mc_test_load_core
}

@test "log lines are timestamped and go to stderr" {
  run --separate-stderr log_info 'hello'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [[ "$stderr" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ INFO\ \ hello$ ]]
}

@test "normal verbosity hides debug messages" {
  run log_debug 'details'
  [ -z "$output" ]
  MC_VERBOSITY=2
  run log_debug 'details'
  [[ "$output" == *"DEBUG details" ]]
}

@test "--quiet keeps warnings and errors only" {
  MC_VERBOSITY=0
  run log_info 'progress'
  [ -z "$output" ]
  run log_warn 'careful'
  [[ "$output" == *"WARN  careful" ]]
  run log_error 'broken'
  [[ "$output" == *"ERROR broken" ]]
}

@test "an invalid level is refused" {
  run mc_log LOUD 'x'
  [ "$status" -eq 1 ]
}

@test "the run log receives the same lines" {
  mc_log_open "$BASE/logs/run.log"
  log_info 'one' 2>/dev/null
  log_warn 'two' 2>/dev/null
  mc_log_close
  log_info 'three' 2>/dev/null
  [ "$(wc -l < "$BASE/logs/run.log")" -eq 2 ]
  grep -q 'INFO  one$' "$BASE/logs/run.log"
  grep -q 'WARN  two$' "$BASE/logs/run.log"
}

@test "die records the error in the run log" {
  mc_log_open "$BASE/logs/run.log"
  run die "$MC_EX_BACKUP" 'engine failed'
  [ "$status" -eq 6 ]
  [ "$output" = 'mycustos: engine failed' ]
  grep -q 'ERROR engine failed$' "$BASE/logs/run.log"
}

@test "mc_log_open fails on an unwritable path" {
  run mc_log_open "$BASE/missing-dir/run.log"
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot write the log file"* ]]
}

@test "mc_log_path builds the phase log name" {
  mc_test_conf 'config_schema=1' 'instance=db01'
  mc_config_load
  run mc_log_path backup
  [ "$status" -eq 1 ]
  [[ "$output" == *"mc_run_init not called"* ]]
  mc_run_init
  first=$MC_RUN_ID
  mc_run_init
  [ "$MC_RUN_ID" = "$first" ]
  [[ "$MC_RUN_ID" =~ ^[0-9]{8}_[0-9]{6}$ ]]
  [ "$(mc_log_path post-archive)" = "$BASE/logs/${MC_RUN_ID}_db01_post-archive.log" ]
  run mc_log_path 'Bad/Phase'
  [ "$status" -eq 1 ]
}

@test "mc_log_path needs a loaded configuration" {
  mc_run_init
  run mc_log_path backup
  [ "$status" -eq 1 ]
  [[ "$output" == *"configuration not loaded"* ]]
}

@test "every exit code has a description" {
  for code in "$MC_EX_OK" "$MC_EX_FAILURE" "$MC_EX_USAGE" "$MC_EX_CONFIG" "$MC_EX_ENVIRONMENT" \
              "$MC_EX_LOCKED" "$MC_EX_BACKUP" "$MC_EX_ARCHIVE" "$MC_EX_TIMEOUT" "$MC_EX_UNAVAILABLE"; do
    [ "$(mc_exit_describe "$code")" != 'unknown exit code' ]
  done
  [ "$(mc_exit_describe 42)" = 'unknown exit code' ]
}
