# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Runs once before every test file: the tests check English messages, so the
# language must not depend on the locale of the machine running them.
# tests/i18n.bats sets the language explicitly where it needs another one.

setup_suite() {
  unset LC_ALL LC_MESSAGES MYCUSTOS_LANGUAGE
  export LANG=C
}
