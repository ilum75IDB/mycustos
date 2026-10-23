# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Shared setup: a temporary installation base with the server layout
# (config/, data/, logs/) and the core modules loaded in the test shell.

mc_test_load_core() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)"
  MYCUSTOS_MODULES="$REPO/bin/modules"
  MYCUSTOS_VERSION=test
  mkdir -p "$BATS_TEST_TMPDIR/base/config" "$BATS_TEST_TMPDIR/base/data" "$BATS_TEST_TMPDIR/base/logs"
  BASE="$(cd "$BATS_TEST_TMPDIR/base" && pwd -P)"   # physical path (macOS: /var -> /private/var)
  MYCUSTOS_HOME="$BASE"
  MC_OPT_CONFIG=''
  source "$MYCUSTOS_MODULES/core/errors.sh"
  source "$MYCUSTOS_MODULES/core/common.sh"
  source "$MYCUSTOS_MODULES/core/log.sh"
  source "$MYCUSTOS_MODULES/core/config.sh"
  source "$MYCUSTOS_MODULES/core/auth.sh"
}

# Writes the given lines to <base>/config/mycustos.conf.
mc_test_conf() {
  printf '%s\n' "$@" > "$BASE/config/mycustos.conf"
}

# Prints the collected configuration errors, one per line.
mc_test_errors() {
  printf '%s\n' "${MC_CONFIG_ERRORS[@]}"
}
