# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Localised terminal messages: English, Italian, Spanish, German, French and
  Romanian, in catalogs `bin/modules/locale/<code>.msg` (read, never sourced).
  Language from `--lang`, `MYCUSTOS_LANGUAGE`, the new key `language=` or the
  system locale, falling back to English. Adding a language means adding a file.
  Logs, summary, flags, statuses and configuration keys stay in English (#13).
- `core/target.sh`: identity of the instance reached (MySQL or MariaDB first, then
  hostname, port, socket, datadir and server UUID or server id), compared with the
  new optional keys `expect_hostname`, `expect_port`, `expect_datadir`,
  `expect_server_uuid`, `expect_server_id` and with `mysql_socket` (#6).
- `core/topology.sh`: role of the node. Backup only on a single instance or on
  the Group Replication PRIMARY; a SECONDARY is skipped; Galera, an unreadable or
  inconsistent group and an unreadable `wsrep_on` are refused (#7).
- `mycustos inspect`: which instance is reached and what a backup would do there,
  as stable `KEY=value` lines for scripts; read-only (#8).
- `preflight`: with `--test-connection`, identity and topology checks (a SECONDARY
  is a warning, a rejected target exits with `9`); copy-ready fix commands for a
  missing configuration or credentials file, a key to change or to add, a missing
  compressor, and the `expect_*` lines on a host with several MySQL servers (#9).
- `core/engine.sh`: the engine detection, shared by `preflight` and `inspect`.
- Exit code `9`: wrong or unsupported target.
- `core/config.sh`: an unsafe `mycustos.conf` is refused with exit `3` (symbolic
  link, owner other than the running user or root, writable by group or others),
  with the `chmod`/`chown` that fixes it (#10).

## [0.2.0] - 2026-10-23

### Added

- `core/auth.sh`: choice of the MySQL authentication (`cnf`, `login-path`, `auto`),
  isolation of the option file from `~/.my.cnf` and `~/.mylogin.cnf`, connection test
  helper; credentials never on the command line or in logs.
- `mycustos preflight [--test-connection]`: read-only check of configuration,
  authentication, directories, free space and required commands; with
  `--test-connection` also the server connection and the engine chosen by `engine=auto`.
- `mycustos check-config`: full validation report of `mycustos.conf`, every error with
  its origin, plus warnings for settings that are valid but probably unintended.
- `mycustos config show`: effective configuration with the origin of each value
  (`config migrate` answers exit 69 until it is implemented).

### Changed

- Configuration: new rules between keys, `backup_type=incr` only with
  `engine=mysqlbackup` (or `auto`), `auth_method=login-path` requires `auth_login_path`.

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

[Unreleased]: https://github.com/ilum75IDB/mycustos/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/ilum75IDB/mycustos/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ilum75IDB/mycustos/releases/tag/v0.1.0
