# Contributing to mycustos

Thank you for your interest. mycustos is in **pre-release**: the architecture is
settled, and the code is being written phase by phase (see the
[Roadmap](README.md#roadmap)). Issues with bug reports, ideas and feedback are
welcome; for larger changes, please open an issue to discuss them before
writing code.

## Licensing of contributions

mycustos is released under the [Apache License 2.0](LICENSE). As stated in its
section 5, any contribution you intentionally submit is licensed under the same
terms, without additional conditions. Keep the `LICENSE` and `NOTICE` files and
the copyright headers unchanged.

## Never include real data

Issues, pull requests, tests and examples must not contain real credentials,
hostnames, IP addresses, paths or names of a company or customer. Use
placeholders such as `db01`, `backup_user`, `/backup`.

## Code guidelines

- **Bash 4.2+** (RHEL 7 is a supported target): no namerefs, no `${var@Q}`,
  no features newer than Bash 4.2.
- `set -uo pipefail` with explicit error checks; **no `set -e`**.
- Every `.sh` file starts with the SPDX header:
  ```bash
  # SPDX-License-Identifier: Apache-2.0
  # Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
  # Original project: https://github.com/ilum75IDB/mycustos
  ```
- Code, comments, CLI messages and logs are in **English**.
- The configuration is never executed: a new setting is a new key in the schema
  of `bin/modules/core/config.sh`, documented in `config/mycustos.conf.example`
  and covered by a test.
- Exit codes live in `bin/modules/core/errors.sh`: never renumber an existing
  code, only add new ones.
- New engines, archive backends and notifiers go in their own file under
  `bin/modules/engines/`, `archive/` or `notifiers/`, implementing the common
  functions described in the architecture.

## Tests

```bash
make check     # bash -n + ShellCheck + Bats
```

Tests must not contact a database, NetBackup or any network service: use the
fake executables in `tests/mocks/bin/`. The GitHub Actions workflow runs the
same checks, plus the test suite on Bash 4.2.

## Commits and pull requests

- One logical change per pull request, with tests.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat(config): …`, `fix(log): …`).
- Update [CHANGELOG.md](CHANGELOG.md) under `Unreleased`.
