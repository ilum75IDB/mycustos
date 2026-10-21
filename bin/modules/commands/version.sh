# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# "mycustos version [--short]": version and attribution. Sourced by bin/mycustos.

cmd_version() {
  case "${1:-}" in
    '') msg "mycustos v$MYCUSTOS_VERSION — © 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L. — Apache-2.0 — https://github.com/ilum75IDB/mycustos" ;;
    --short) msg "$MYCUSTOS_VERSION" ;;
    *) die_usage "version: unknown option: $1" ;;
  esac
  return "$MC_EX_OK"
}
