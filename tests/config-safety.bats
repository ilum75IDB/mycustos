#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/config.sh: an unsafe mycustos.conf (symbolic link, foreign owner,
# writable by group or others) is refused as a configuration error.

load test_helper

setup() {
  mc_test_load_core
  unset MYCUSTOS_CONFIG_FILE MYCUSTOS_LANGUAGE
  CONF=$BASE/config/mycustos.conf
  mc_test_conf config_schema=1 language=it
  MYCUSTOS="$REPO/bin/mycustos"
}

load_rc() {
  rc=0
  mc_config_load || rc=$?
}

@test "a private file owned by the running user is accepted" {
  chmod 600 "$CONF"
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
}

@test "a file readable by everyone but writable only by the owner is accepted" {
  chmod 644 "$CONF"
  load_rc
  [ "$rc" -eq 0 ]
}

@test "a symbolic link is refused, even to a safe file" {
  mv "$CONF" "$BASE/real.conf"
  ln -s "$BASE/real.conf" "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [ "${#lines[@]}" -eq 1 ]
  [[ "$output" == "$CONF: must be a regular file, not a symbolic link"* ]]
}

@test "a dangling symbolic link is refused as a link, not as a missing file" {
  rm -f "$CONF"
  ln -s "$BASE/nowhere.conf" "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [[ "$output" == *"not a symbolic link"* ]]
}

@test "a group-writable file is refused with the chmod that fixes it" {
  chmod 664 "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [ "$output" = "$CONF: writable by group or others (run: chmod go-w $CONF)" ]
}

@test "an other-writable file is refused" {
  chmod 602 "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [[ "$output" == *"writable by group or others"* ]]
}

@test "the suggested command quotes the path and really fixes the file" {
  mkdir -p "$BASE/my conf"
  cp -p "$CONF" "$BASE/my conf/mycustos.conf"
  chmod 666 "$BASE/my conf/mycustos.conf"
  MC_OPT_CONFIG="$BASE/my conf/mycustos.conf"
  load_rc
  [ "$rc" -eq 1 ]
  fix=$(mc_test_errors | sed -n 's/.*(run: \(.*\))$/\1/p')
  [ "$fix" = 'chmod go-w '"$(printf '%q' "$BASE/my conf/mycustos.conf")" ]
  eval "$fix"
  load_rc
  mc_test_errors
  [ "$rc" -eq 0 ]
}

@test "a file owned by another user is refused with the chown that fixes it (root only)" {
  [ "$(id -u)" -eq 0 ] || skip "needs root to give the file away"
  chown 65534 "$CONF"
  load_rc
  [ "$rc" -eq 1 ]
  run mc_test_errors
  [[ "$output" == "$CONF: owned by uid 65534: must be owned by the user running mycustos or by root (run: chown root $CONF)" ]]
}

@test "an unsafe file is not even peeked for the language" {
  chmod 666 "$CONF"
  run mc_config_peek language
  [ "$status" -eq 1 ]
  chmod 644 "$CONF"
  run mc_config_peek language
  [ "$output" = it ]
}

@test "the commands exit with the configuration error code (3)" {
  chmod 666 "$CONF"
  for cmd in check-config preflight inspect "config show"; do
    # shellcheck disable=SC2086  # "config show" is two words
    run "$MYCUSTOS" --home "$BASE" --lang en $cmd
    [ "$status" -eq 3 ] || { echo "$cmd: $status: $output"; false; }
    [[ "$output" == *"writable by group or others"* ]] || { echo "$cmd: $output"; false; }
  done
}

@test "the message is translated" {
  chmod 666 "$CONF"
  run "$MYCUSTOS" --home "$BASE" --lang it check-config
  [ "$status" -eq 3 ]
  [[ "$output" == *"scrivibile dal gruppo o da altri (esegui: chmod go-w "* ]]
}
