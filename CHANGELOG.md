# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-10-21

### Added

- Project layout: `bin/`, `bin/modules/`, `config/`, `tests/`, `contrib/`, `docs/`.
- `bin/mycustos` entry point with the `help` and `version` commands.
- Apache License 2.0, `NOTICE` file and SPDX headers.
- `make check` (bash -n, ShellCheck, Bats) and the GitHub Actions `checks` workflow,
  with an additional test job on Bash 4.2.
- Global options `--config FILE`, `--home DIR`, `-q/--quiet`, `-v/--verbose`.
- `core/errors.sh`: stable table of exit codes.
- `core/log.sh`: timestamped logging with verbosity levels, run log, phase log names.
- `core/config.sh`: `key=value` parser that never executes the file, with a key whitelist,
  typed validation, limited `${MYCUSTOS_*}` expansions and the precedence
  option > environment > file > default.
- `config/mycustos.conf.example` and `config/backup-credentials.conf.example`.
- `SECURITY.md` and `CONTRIBUTING.md`.

[Unreleased]: https://github.com/ilum75IDB/mycustos/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ilum75IDB/mycustos/releases/tag/v0.1.0
