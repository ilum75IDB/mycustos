# mycustos

**Standardized MySQL backup runner** — one Bash command to run MySQL / MariaDB backups the same way on every server: same command, same configuration, same logs and status flags.

*custos* (Latin): guardian, keeper.

> [!WARNING]
> **Pre-release — not usable yet.** mycustos is a ground-up re-engineering of a Bash backup toolkit
> that has been running on enterprise MySQL servers. The new code base is being written in phases
> (see [Roadmap](#roadmap)). Today only `mycustos help` and `mycustos version` work.
> Do not use it to protect real data until a release says otherwise.

## Why

On many teams every database server ends up with its own backup script: different options, different log formats, different ways to tell whether last night's backup worked. mycustos aims to replace them with a single, self-contained tool that:

- installs in **one directory** (typically the backup mount point assigned to the DB server);
- runs the **same command** everywhere, from cron or a systemd timer;
- checks **prerequisites before** touching anything (`preflight`, `check-config`, `backup --dry-run`);
- writes **predictable logs, a final summary and status flags** that monitoring tools can read;
- never presents a backup as safe when it is not: a local backup and an archived backup are reported differently, and the incremental chain only advances after a confirmed archive.

## Planned features

| Area | Planned support |
|---|---|
| Backup engines | `mysqlbackup` (MySQL Enterprise Backup), `mysqldump`, `mydumper`, `xtrabackup`, `mariadb-backup`, or `auto` (chosen from the server edition) |
| Backup types | FULL with every engine; INCR with `mysqlbackup` only |
| Packaging | TAR compressed with `gzip` or `zstd`; `simple` (one archive) or `split` (numbered chunks) |
| Archiving | `none` (local only, with retention) or Veritas NetBackup (`bparchive`), as pluggable backends |
| Authentication | MySQL option file (CNF), `mysql_config_editor` login-path, or automatic fallback |
| Safety | single-run lock (`flock`), read-only checks, dry-run built from the same command as the real run |
| Monitoring | per-phase logs, final `BACKUP SUMMARY`, `.OK` / `.ERR` / `.TIMEOUT` flags, notification hook |

The status of each item is tracked in the [CHANGELOG](CHANGELOG.md).

## Installation layout

mycustos is **self-contained**: everything lives under one base directory, usually the backup mount point. The base is detected from the location of `bin/mycustos`, so it does not need to be written anywhere.

```text
<base>/                      # e.g. the backup mount point of the DB server
├── bin/
│   ├── mycustos             # the only command you run
│   └── modules/             # internal code (core, engines, packaging, archive, notifiers, commands)
├── config/
│   ├── mycustos.conf        # your configuration (KEY=value, never executed)
│   └── backup-credentials.conf
├── data/                    # backups
└── logs/                    # logs and status flags
```

## Quick start (current pre-release)

```bash
git clone https://github.com/ilum75IDB/mycustos.git
cd mycustos

bin/mycustos help
bin/mycustos version
```

## Commands

```text
mycustos backup [--type full|incr] [--dry-run]   # planned
mycustos preflight [--test-connection]           # available
mycustos check-config                            # available
mycustos status                                  # planned
mycustos config show | migrate FILE              # planned
mycustos version [--short]                       # available
mycustos help [command]                          # available

Global options (before the command):
  --config FILE   configuration file (default: <base>/config/mycustos.conf)
  --home DIR      base of config/, data/ and logs/ (default: the installation)
  -q, --quiet     warnings and errors only
  -v, --verbose   debug messages too
```

`mycustos help` always shows which commands are already implemented in the version you are running.

### preflight

`mycustos preflight` checks what a backup needs, without changing anything: the
configuration, the authentication, `data_dir`, `logs_dir` and the `config/`
directory, the free space, and the commands required by the configured engine,
compression and archive backend. Each check prints `OK`, `WARN` or `FAIL`, with a
hint when there is something to change. `--test-connection` also connects to the
MySQL server and, with `engine=auto`, shows which engine the server edition selects.

Exit code `0` when nothing failed (warnings allowed), `3` for a configuration
problem, `4` for an environment problem.

### check-config

`mycustos check-config` validates `mycustos.conf` and lists **every** problem in one
run, each with its origin (`file:line`, `env MYCUSTOS_<KEY>` or `default`): unknown
or duplicate keys, wrong types and ranges, forbidden expansions, an unsupported
`config_schema`, and rules between keys (e.g. `compress_level` at most 9 with `gzip`,
`backup_type=incr` only with `engine=mysqlbackup`). Valid settings that are probably
not what was meant are shown as warnings. It never touches the filesystem or the
server: that is the job of `preflight`.

Exit code `0` when valid (warnings allowed), `3` when invalid.

## Configuration

`config/mycustos.conf` is a plain `key=value` file, **read by a parser and never
executed**: no shell syntax, and an unknown key is reported as an error, so a
typo cannot go unnoticed. Start from [`config/mycustos.conf.example`](config/mycustos.conf.example),
which documents every key.

- Only four variables are expanded: `${MYCUSTOS_HOME}`, `${MYCUSTOS_CONFIG}`,
  `${MYCUSTOS_DATA}` and `${MYCUSTOS_LOGS}`.
- Precedence: command-line option > environment variable `MYCUSTOS_<KEY>`
  (e.g. `MYCUSTOS_RETENTION_DAYS=3`) > file > built-in default.
- `config_schema` versions the file format: it changes only when the format does.

### Authentication

Credentials never appear on a command line or in a log: mycustos passes only the
path of an option file or the name of a login path. `auth_method` selects how:

| `auth_method` | Credentials from | Client option |
|---|---|---|
| `cnf` | `auth_cnf`, a MySQL option file with a `[client]` section, permissions `600` (see [`config/backup-credentials.conf.example`](config/backup-credentials.conf.example)) | `--defaults-file=<auth_cnf>` |
| `login-path` | `auth_login_path`, created with `mysql_config_editor set --login-path=...` | `--login-path=<name>` |
| `auto` (default) | `cnf` when `auth_cnf` exists, otherwise `login-path` | |

With `cnf` the client reads that file only: `--defaults-file` skips `/etc/my.cnf`
and `~/.my.cnf`, and `~/.mylogin.cnf` is replaced by an empty private file for the
run, so no credential is mixed in from elsewhere. An `auth_cnf` that exists but is
unusable (unreadable, no `[client]` section) is an error, also with `auto`: mycustos
does not silently fall back to the login path. Permissions wider than `600` give a warning.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | unexpected internal error |
| 2 | invalid command line |
| 3 | configuration missing or invalid |
| 4 | prerequisite missing (command, directory, permission, MySQL server) |
| 5 | another run holds the lock |
| 6 | backup failed: nothing usable was produced |
| 7 | local backup OK, archiving failed |
| 8 | a phase exceeded its time limit |
| 69 | command not implemented in this version |

These values are stable: existing codes are never renumbered.

## Requirements

- Linux with **Bash 4.2+** and GNU core utilities (`tar`, `flock`, `split`, `stat`, …)
- the MySQL client and the backup engine you choose
- `gzip` or `zstd`
- optional: Veritas NetBackup client, only if you use that archive backend

## Roadmap

| Phase | Scope |
|---|---|
| F0 | Repository, layout, entry point, core modules, CI (ShellCheck + Bats) |
| F1 | Authentication, `preflight`, `check-config`, `config show` |
| F2 | Engines, `simple` packaging, local archive + retention, lock, flags, summary, `backup --dry-run`, `status` |
| F3 | `split` packaging, generic archive job queue, NetBackup backend |
| F4 | Incremental chain with `mysqlbackup` |
| F5 | `config migrate`, systemd / cron examples, release tarball, full documentation |

Version `1.0.0` will be tagged only after validation on a real server.

## Contributing and security

Issues with ideas and feedback are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md).
To report a vulnerability, follow [SECURITY.md](SECURITY.md) and do not open a public issue.

## License & attribution

mycustos is released under the [Apache License 2.0](LICENSE).
You are free to use, modify and redistribute it, provided that you keep the
[`LICENSE`](LICENSE) and [`NOTICE`](NOTICE) files and the copyright headers in the source files.

"mycustos" identifies the original project by Ivan Luminaria.
Forks and derivative works must not present themselves as the official project.

Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
