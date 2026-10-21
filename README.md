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
mycustos preflight [--test-connection]           # planned
mycustos check-config                            # planned
mycustos status                                  # planned
mycustos config show | migrate FILE              # planned
mycustos version [--short]                       # available
mycustos help [command]                          # available
```

`mycustos help` always shows which commands are already implemented in the version you are running.

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

## Contributing

The project is in its initial design phase. Issues with ideas and feedback are welcome; contribution guidelines will be published before the first release.

## License & attribution

mycustos is released under the [Apache License 2.0](LICENSE).
You are free to use, modify and redistribute it, provided that you keep the
[`LICENSE`](LICENSE) and [`NOTICE`](NOTICE) files and the copyright headers in the source files.

"mycustos" identifies the original project by Ivan Luminaria.
Forks and derivative works must not present themselves as the official project.

Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
