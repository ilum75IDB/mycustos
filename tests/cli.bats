#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# CLI contract of bin/mycustos. No database, no network, no side effects.

setup() {
  MYCUSTOS="$BATS_TEST_DIRNAME/../bin/mycustos"
}

@test "no arguments prints the help" {
  run "$MYCUSTOS"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mycustos <command> [options]"* ]]
}

@test "help lists every command and flags the unimplemented ones" {
  run "$MYCUSTOS" help
  [ "$status" -eq 0 ]
  for c in backup preflight check-config status config version help; do
    [[ "$output" == *"  $c "* ]]
  done
  [[ "$output" == *"backup"*"(not implemented yet)"* ]]
  [[ "$output" != *"version"*"Show version and attribution (not implemented yet)"* ]]
}

@test "--help and -h are aliases of help" {
  run "$MYCUSTOS" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
  run "$MYCUSTOS" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "help <command> describes a single command" {
  run "$MYCUSTOS" help version
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos version - Show version and attribution" ]]
  run "$MYCUSTOS" help backup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Not implemented yet"* ]]
}

@test "help with an unknown command is a usage error" {
  run "$MYCUSTOS" help nope
  [ "$status" -eq 2 ]
}

@test "version prints version and attribution" {
  run "$MYCUSTOS" version
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos v"*"Ivan Luminaria"*"Apache-2.0"*"github.com/ilum75IDB/mycustos" ]]
}

@test "--version and -V are aliases of version" {
  run "$MYCUSTOS" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos v"* ]]
  run "$MYCUSTOS" -V
  [ "$status" -eq 0 ]
  [[ "$output" == "mycustos v"* ]]
}

@test "version --short prints only the version number" {
  run "$MYCUSTOS" version --short
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]]
}

@test "version with an unknown option is a usage error" {
  run "$MYCUSTOS" version --nope
  [ "$status" -eq 2 ]
}

@test "unknown command is a usage error" {
  run "$MYCUSTOS" nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown command: nope"* ]]
}

@test "unknown global option is a usage error" {
  run "$MYCUSTOS" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option: --nope"* ]]
}

@test "a planned command exits 69 without side effects" {
  run "$MYCUSTOS" backup
  [ "$status" -eq 69 ]
  [[ "$output" == *"not implemented yet"* ]]
}

@test "works when invoked through a symlink" {
  ln -s "$MYCUSTOS" "$BATS_TEST_TMPDIR/mycustos"
  run "$BATS_TEST_TMPDIR/mycustos" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation: $(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"* ]]
}
