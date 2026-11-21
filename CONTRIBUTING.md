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
- Code, comments and logs are in **English**. Messages for the terminal are
  never written in the code: they are keys of the catalogs (see below).
- The configuration is never executed: a new setting is a new key in the schema
  of `bin/modules/core/config.sh`, documented in `config/mycustos.conf.example`
  and covered by a test.
- Exit codes live in `bin/modules/core/errors.sh`: never renumber an existing
  code, only add new ones.
- New engines, archive backends and notifiers go in their own file under
  `bin/modules/engines/`, `archive/` or `notifiers/`, implementing the common
  functions described in the architecture.

## Messages and languages

Every message shown to a person goes through a catalog in `bin/modules/locale/`:

```bash
die "$MC_EX_CONFIG" cfg.unknown_key "$key"     # fatal error
die_usage cli.unknown_option "$1"              # usage error
warn auth.lp_unverified "$name"                # warning
say pf.header "$instance"                      # a line on stdout
text=$(mc_t pf.auth_ok "$desc")                # a message as a string
```

Add the key to `en.msg` first (the reference), then to every other catalog. Keys
are written literally in the code, so the tests can check that each one exists
and that none is unused. Log files keep English text (`die` already writes the
English version to the run log); errors that can only come from a bug stay
hard-coded in English.

### Adding a language

1. Copy `bin/modules/locale/en.msg` to `bin/modules/locale/<code>.msg`, where
   `<code>` is an ISO 639 language code, optionally with a region
   (`pt.msg`, `pt_BR.msg`). A region catalog wins over the language alone.
2. Set the header: `# name:` with the name of the language in that language,
   `# status: needs native review` (or `reviewed` once a native speaker has
   checked it).
3. Translate the values, never the keys. Keep the same placeholders (`%s`, `%d`)
   **in the same order**: Bash `printf` has no positional arguments, so rephrase
   instead of reordering them. Leave option names, configuration keys and
   commands as they are.
4. Run `make check`: the tests compare every catalog with `en.msg` (keys and
   placeholders).

No code change is needed: the available languages are the catalogs present.

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
