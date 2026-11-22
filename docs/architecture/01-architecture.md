# mycustos architecture

**Status**: approved. Phases F0 and F1 are done (v0.2.0); F2 is in progress.
**Scope**: how mycustos is organised, the main design choices and the roadmap.
The user-facing behaviour is documented in the [README](../../README.md).

---

## 1. One entry point, many modules

Three layouts were considered:

| Option | Pros | Cons |
|---|---|---|
| **A. Everything in one file** | a single file to copy to the server | thousands of lines; hard to test, review and extend |
| **B. Modules loaded at runtime** ✅ | each part is tested on its own; engines and archive targets are modules you add; easy reviews | more files on the server (a tarball or a `git clone` takes care of that) |
| **C. Modules + build into one file** | B's advantages and a single file to ship | needs a build step |

**Choice: B.** C remains an option for later (`make dist`) if shipping a single file
to the servers turns out to matter.

## 2. Layout

What is **in the repository** is not the same as what **ends up on the server**.

### 2.1 On the server: self-contained on the backup mount point

The typical case is *"I was given a mount point for backups, and I install everything
there"*. mycustos lives in four directories (`bin/`, `config/`, `data/`, `logs/`)
that can be copied, moved or removed as a whole. There are no directories that look
like system ones (`etc/`, `var/`, `lib/`).

```text
/<backup-mount-point>/
├── bin/
│   ├── mycustos                    # the only command the DBA runs
│   └── modules/                    # the code: nobody needs to touch it
│       ├── core/
│       │   ├── common.sh           # die, warn, say, command loading, helpers
│       │   ├── errors.sh           # stable exit codes
│       │   ├── i18n.sh             # message catalogs and language selection
│       │   ├── log.sh              # logger (always in English)
│       │   ├── config.sh           # lookup, parsing and validation of the configuration, defaults, precedence
│       │   ├── auth.sh             # cnf / login-path / auto, isolation from ~/.mylogin.cnf
│       │   ├── target.sh           # identity of the instance reached
│       │   ├── topology.sh         # topology and role of the node
│       │   ├── engine.sh           # engine detection from the server edition
│       │   ├── lock.sh             # flock (planned)
│       │   ├── status.sh           # flags, history, status file (planned)
│       │   ├── summary.sh          # BACKUP SUMMARY, always written by the trap (planned)
│       │   ├── hooks.sh            # pre/post backup and pre/post archive scripts (planned)
│       │   ├── notify.sh           # notifications (planned)
│       │   ├── retention.sh        # clean-up of logs and local archives (planned)
│       │   └── chain.sh            # INCR chain: pending → commit (planned)
│       ├── locale/                 # one catalog per language: en.msg, it.msg, ...
│       ├── engines/                # one file per engine
│       │   ├── mysqlbackup.sh
│       │   ├── mysqldump.sh
│       │   ├── mydumper.sh
│       │   └── xtrabackup.sh       # also used for mariadb-backup
│       ├── packaging/
│       │   ├── compress.sh         # gzip / zstd
│       │   ├── simple.sh
│       │   ├── split.sh            # stream cut into chunks, each handed to the archive queue once closed
│       │   └── verify.sh           # archive check, reused later by "mycustos verify"
│       ├── archive/                # one file per target
│       │   ├── archive.sh          # job queue, parallelism, outcome collection (generic)
│       │   ├── none.sh             # local only (with retention)
│       │   └── netbackup.sh        # bparchive, optional monitor
│       ├── notifiers/
│       │   ├── none.sh
│       │   └── command.sh          # generic external command (mail, monitoring agent, webhook…)
│       └── commands/               # one file per sub-command
│           ├── backup.sh
│           ├── preflight.sh
│           ├── inspect.sh
│           ├── check-config.sh
│           ├── setup.sh
│           ├── status.sh
│           ├── archive.sh
│           ├── config.sh           # config show / config migrate
│           ├── version.sh
│           └── help.sh
├── config/
│   ├── mycustos.conf               # configuration
│   ├── backup-credentials.conf     # MySQL credentials, mode 600
│   ├── lsn.txt                     # INCR chain state (runtime)
│   ├── backup_chain.state          # INCR chain state (runtime)
│   └── mycustos.lock               # flock lock (runtime)
├── data/                           # the backups
└── logs/                           # logs and flags
```

The choices:

- **Four top-level directories only.** The code goes in `bin/modules/`: `bin/` already
  means "programs", so no top-level directory is added.
- **Modules grouped by kind** (`core/`, `engines/`, `packaging/`, `archive/`,
  `notifiers/`, `commands/`): whoever adds an engine or an archive target knows where
  to look.
- **State (LSN, chain, lock) lives in `config/`.** The upgrade procedure already says
  to save `config/`, so the chain is saved with it; and emptying `data/` to free space
  does not break the INCR chain.
- **The configuration file is `mycustos.conf`**: next to a `my.cnf` or the files of
  other tools, it is obvious whose it is.

### 2.2 In the repository

```text
mycustos/
├── bin/                            # ← goes to the server
│   ├── mycustos
│   └── modules/...
├── config/                         # ← goes to the server (templates only)
│   ├── mycustos.conf.example
│   └── backup-credentials.conf.example
├── contrib/                        # optional examples, not installed
│   ├── systemd/                    # mycustos-backup@.service + .timer
│   ├── cron/mycustos.cron.example
│   └── notifiers/                  # examples for the command notifier
├── tests/
│   ├── mocks/bin/                  # fake mysql, mysqlbackup, mysqldump, bparchive, zstd
│   └── *.bats
├── docs/
├── Makefile                        # lint, test, release (tarball)
├── LICENSE · NOTICE · README.md · CHANGELOG.md · SECURITY.md · CONTRIBUTING.md
└── .gitignore                      # real configurations, data/, logs/, state
```

**A release** is a tarball with only `bin/`, `config/*.example`, `README.md`, `LICENSE`
and `NOTICE`. Installation: extract it on the mount point, create `data/` and `logs/`,
copy the `.example` templates and edit them (or run `mycustos setup`).

### 2.3 Entry point

`bin/mycustos` resolves its own location with `readlink -f`, so it also works through
a symlink such as `/usr/local/bin/mycustos`. It derives the base (`bin/..`), loads the
core modules and then only the module of the requested sub-command:

```bash
MYCUSTOS_HOME=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)
MYCUSTOS_MODULES="$MYCUSTOS_HOME/bin/modules"
source "$MYCUSTOS_MODULES/core/common.sh"
cmd=${1:-help}; shift || true
mc_is_known_command "$cmd" || die_usage cli.unknown_command "$cmd"
source "$MYCUSTOS_MODULES/commands/$cmd.sh"
"cmd_${cmd//-/_}" "$@"
```

## 3. Commands

```text
mycustos backup [--type full|incr] [--dry-run]
mycustos preflight [--test-connection]
mycustos inspect
mycustos check-config
mycustos setup [--output FILE] [--defaults] [--force]
mycustos status                     # outcome of the last run (from the status file)
mycustos archive FILE... [--dry-run]
mycustos config show                # effective configuration, with the origin of each value
mycustos config migrate FILE        # imports an existing configuration file (planned)
mycustos version
mycustos help [command]

Global options: --config FILE · --home DIR · --lang CODE · --quiet · --verbose
```

`mycustos verify` comes in a later phase (see §6).

## 4. Main design choices

### 4.1 A common contract for the engines; the dry-run uses the same code

Each engine (`bin/modules/engines/<name>.sh`) exposes functions with fixed names:

```bash
engine_mysqldump_capabilities()  { echo "full"; }   # mysqlbackup: "full incr"
engine_mysqldump_check()         { ...; }           # used by preflight
engine_mysqldump_build_cmd()     { ...; }           # fills the MC_CMD array
engine_mysqldump_run()           { ...; }           # runs MC_CMD
engine_mysqldump_end_lsn()       { return 1; }      # only mysqlbackup implements it
```

**The dry-run and the real backup call the same `build_cmd`.** Two separate code paths
would drift apart (for example, a dry-run showing an authentication option the real run
does not use). With a single `build_cmd`, the dry-run shows exactly the real command.

Engine constraints are checked in `engine_<x>_check` and shown by preflight:
`mydumper` needs the `cnf` authentication; `xtrabackup` and `mariadb-backup` need
`--defaults-file` / `--defaults-extra-file` as their **first** option. With
`engine=auto`, a `--dry-run` cannot pick the engine without a connection, and says so.

### 4.2 Archiving is separate from packaging

The parallel slots are a generic job queue in `archive/archive.sh`. Each target
implements four functions:

```bash
archive_<b>_check              # used by preflight
archive_<b>_submit FILE        # starts the transfer in the background
archive_<b>_poll JOB           # running | ok | failed
archive_<b>_consumes_source    # true for bparchive (ARCHIVE semantics)
```

`packaging/split.sh` hands each chunk to the queue as soon as it is closed and does not
know which target is behind it. Adding `rsync` or `s3` later means one new file in
`archive/`, without touching the rest.

The queue also produces the **job inventory** of the summary, the same for every target.
For each file sent it records the status (`OK` / `FAILED` / `NOT_COMPLETED` /
`SKIPPED_NOT_SENT`), the exit code, the kind (`CURRENT_FULL` / `CURRENT_CHUNK` /
`PREEXISTING`), bytes and path, plus the totals. The inventory comes from the jobs that
were registered, not from the files on disk, because `bparchive` may already have
removed them. Every variable of the queue is `local`, so a job keeps its path while it
waits for a free slot (a test covers `parallel=1` with pre-existing archives).

NetBackup specifics:

- `bparchive` runs **without `-L`**: stdout, stderr and exit code of each job are
  captured by mycustos;
- `archive_include_existing=false`: when enabled, the list of archives already present
  is taken **before** the export, and each of them is sent as an **independent job**,
  not as a chunk of the new backup;
- `mycustos archive FILE... [--dry-run]` sends existing archives without a new backup,
  with the same queue and the same target.

### 4.3 The configuration is read, never executed

`mycustos.conf` is parsed as `KEY=value` lines, against a whitelist of known keys, by
one parser used by every command. It is never `source`d. Example:

```ini
config_schema=1
instance=main
databases=ALL
backup_type=full
engine=auto
auth_method=auto
auth_cnf=${MYCUSTOS_CONFIG}/backup-credentials.conf
compress=zstd
compress_level=7
packaging=simple
archive_backend=none
retention_days=7
language=
```

- The only expansions allowed are `${MYCUSTOS_HOME}`, `${MYCUSTOS_CONFIG}`,
  `${MYCUSTOS_DATA}` and `${MYCUSTOS_LOGS}`. An unknown key is an error, so typos are
  reported at once.
- Precedence: **CLI > environment `MYCUSTOS_<KEY>` > `mycustos.conf` > default**. The
  defaults live in the schema in the code, so `mycustos.conf` holds only the local
  values.
- **`config_schema`** versions the format: it changes only when the format does, not at
  every release.
- Exit codes and their meaning live in `core/errors.sh`.
- **The file must be safe** (#10): it is refused when it is not a regular file, when it
  is a symlink, when its owner is neither the user running mycustos nor root, or when it
  is writable by the group or by others. Even though it is never executed, whoever
  edits it decides *where* the data goes and *which* credentials are used.

### 4.4 Directories: self-contained by default, movable when needed

| What | Default | Variable | Optional override |
|---|---|---|---|
| code | `<base>/bin` | `MYCUSTOS_HOME` = `<base>` | `--home DIR` |
| configuration + state (LSN, chain, lock) | `<base>/config` | `MYCUSTOS_CONFIG` | `--config FILE` |
| backups | `<base>/data` | `MYCUSTOS_DATA` | `data_dir=` in `mycustos.conf` |
| logs and flags | `<base>/logs` | `MYCUSTOS_LOGS` | `logs_dir=` in `mycustos.conf` |

`<base>` is the backup mount point where mycustos is installed, derived from the
location of `bin/mycustos`: it is not written anywhere.

With the default values, the derived directories must stay under the base, which
protects from mistakes in the configuration. When `data_dir` or `logs_dir` are set
explicitly, they only need to be absolute paths, other than `/`, and writable.

### 4.5 A safe target: identity and topology before anything is written

Before a backup, mycustos checks that it reached **the right instance** and that the
instance is a node where a backup is allowed. Both checks are read-only.

**Identity** (`core/target.sh`). On a host with several instances, a successful
`SELECT 1` proves nothing.

- `@@version` and `@@version_comment` are read first, to tell MySQL from MariaDB
  before asking product-specific variables (MariaDB has no `@@server_uuid`).
- Then `@@hostname`, `@@port`, `@@socket`, `@@datadir` and `@@server_uuid` (MySQL) or
  `@@server_id` (MariaDB). A missing value refuses the target.
- Optional expectations, empty by default; when one is set and differs, the backup is
  refused:

| Key | Compared with |
|---|---|
| `mysql_socket` | `@@socket` |
| `expect_hostname` | `@@hostname` (case ignored) |
| `expect_port` | `@@port` |
| `expect_datadir` | `@@datadir` (trailing `/` ignored) |
| `expect_server_uuid` | `@@server_uuid`, MySQL only (on MariaDB it is a configuration error) |
| `expect_server_id` | `@@server_id`, MariaDB only |

A missing socket is a blocking error, never a skip.

**Topology** (`core/topology.sh`). The rule is **back up only on the PRIMARY**, and any
doubt refuses:

| Situation | Result |
|---|---|
| MySQL without Group Replication | allowed (`SINGLE_INSTANCE`) |
| Group Replication, local node `PRIMARY` `ONLINE` | allowed |
| Group Replication, local node `SECONDARY` `ONLINE` | **no backup**, exit 0, status `SKIPPED_SECONDARY`, no flag; the log names host, IP and port of the PRIMARY |
| GR plugin present but no member visible, inconsistent members, number of online PRIMARY other than 1, local node not `ONLINE` | refused |
| `performance_schema.replication_group_members` not readable | refused: an error is **never** taken for a single instance |
| MariaDB `wsrep_on=OFF` | standalone, allowed |
| MariaDB `wsrep_on=ON` (Galera) | refused: the PRIMARY-only rule does not apply to a multi-primary cluster |
| MariaDB `wsrep_on` missing or unexpected | refused |

Classic asynchronous replication is not evaluated. mycustos never moves to the
PRIMARY: it only says where it is. A refused identity or topology exits with
**`MC_EX_TARGET=9`**.

**`mycustos inspect`** prints, read-only and as stable `KEY=value` lines for scripts,
the identity, the authentication used, the topology, the role, the PRIMARY and the
engine that would be chosen.

### 4.6 mysqldump: complete dumps only, invalid views on request

Every mysqldump export must be non-empty and end with the `-- Dump completed` footer,
whatever its exit code: a truncated dump with exit code 0 is still unusable.

By default any mysqldump error fails the backup (fail-closed). With
`mysqldump_allow_invalid_views=true`:

- `--force` is added to `mysqldump`;
- stderr is read line by line and **only** error 1356 (a view referencing invalid
  tables, columns or functions) in the expected format is accepted, and the
  `schema.view` is extracted from it. The client `[Warning]` lines are logged. **Any
  other line fails the export**;
- a non-zero exit code without any recognised view is a failure;
- the outcome becomes `COMPLETED_WITH_WARNINGS`, with a **`.WARN`** flag instead of
  `.OK`. The summary reports the exit code, the number and the list of the skipped
  views, and warns that those views will not be restored.

The parser lives in `engines/mysqldump.sh`, tested with synthetic stderr (1356 only;
1356 plus a connection error; dump without footer; non-zero exit code without views).

### 4.7 Outcomes, flags and summary

| `EXECUTION STATUS` | Exit | Flag |
|---|---|---|
| `LOCAL_BACKUP_OK` | 0 | `.OK` |
| `BACKUP_ARCHIVED_OK` | 0 | `.OK` |
| `COMPLETED_WITH_WARNINGS` | 0 | `.WARN` |
| `SKIPPED_SECONDARY` | 0 | none |
| `FAILED` | ≠0 | `.ERR` or `.TIMEOUT` |

Flag names: `<date>_<instance>_<type>.OK` / `.WARN`, `<date>_<instance>_<database>_<type>.ERR`
/ `.TIMEOUT`, plus a history file of the outcomes. Flags are written explicitly by
`core/status.sh`; the outcome is always an explicit variable, never rebuilt by reading
the logs.

The `BACKUP SUMMARY` is **always** written by the `EXIT` trap. For each phase (backup,
compression, archiving, removal) it reports start, end, duration and outcome; then the
size of the backup directory and of the archive with the compression ratio, the
topology and the role, the job inventory, and on failure an `ERROR DETAILS` section
(phase, failed command, message, log file and line). It ends with ready-to-run `tail`
commands for each log.

### 4.8 Keeping the backup directory, verifying the archive

| Archiving | `keep_backup_dir` | Behaviour |
|---|---|---|
| none | `true` (default) | the directory and the archive are kept |
| none | `false` | **full archive check** (`gzip -dc` / `zstd -dc` \| `tar -tf -`, over all the chunks in order in split mode), then the directory is removed; the archive stays |
| NetBackup | `true` | the directory is kept |
| NetBackup | `false` | removed only after a **successful archiving** |

The directories of earlier backups are never removed by this logic. The check lives in
`packaging/verify.sh`, and `mycustos verify` will reuse it.

### 4.9 INCR chain

- An INCR run is refused **before the lock** when the chain state is missing, and
  `lsn.txt` must match `last_end_lsn` in the state file.
- The chain moves forward only after a successful archiving. With archive target
  `none` the chain does **not** advance and the pending LSN is discarded (to be
  confirmed in the INCR phase).

### 4.10 Preflight suggests the fix

For each problem, `preflight` **suggests** the command that fixes it, and never runs it:

- missing configuration: `cp -p -- config/mycustos.conf.example config/mycustos.conf`;
- a key to change, even when commented out: `sed -i -E 's|^#?[[:space:]]*KEY=.*|KEY=value|' config/mycustos.conf`;
- a missing key: `printf 'KEY=value\n' >> config/mycustos.conf`;
- hints tied to what actually happened: missing login path, missing compressor,
  NetBackup without policy or schedule, 1356 errors already in earlier logs (then it
  suggests `mysqldump_allow_invalid_views`, see 4.6).

### 4.11 Languages

Terminal messages are keys of the catalogs `bin/modules/locale/<code>.msg` (English
as the reference, plus Italian, Spanish, German, French and Romanian), read and never
executed. Adding a language means adding a file. The language comes from `--lang`,
`MYCUSTOS_LANGUAGE`, `language=` or the system locale, falling back to English. Logs,
summary, flags, statuses, the `OK`/`WARN`/`FAIL` tags, output meant for scripts and
configuration keys always stay in English.

### 4.12 Other rules

- **Bash 4.2** at least, so RHEL 7 too. `set -uo pipefail` with explicit checks, no
  `set -e`, which has too many corner cases for a tool like this.
- No environment-specific defaults (media servers, volumes, paths).
- Temporary files with `mktemp`, removed on exit.
- Retention with `find … -name <mycustos pattern> -mtime +N -delete`, limited to the
  files of mycustos; `retention_days` / `retention_count` for the `none` target.
- Notifications through a generic `command` notifier; integrations are examples in
  `contrib/`, not core code.
- Later: `mycustos verify` (`zstd -t` / `gzip -t`, completeness of the chunk manifest).

## 5. Tests

The fake executables in `tests/mocks/bin/` let the CI test **the whole flow without a
database**:

- a fake `mysql` answers each query from a responses file (version, edition, identity,
  Group Replication members, `wsrep_on`);
- a fake `mysqlbackup` creates the directory with `meta/backup_variables.txt` and
  `end_lsn`;
- a fake `bparchive` removes the file and returns the exit code the test needs;
- `CHUNK_SIZE=4K` makes the split mode produce many chunks from a few KB.

Each test builds a temporary base with `bin/`, `config/`, `data/` and `logs/`, the same
layout as on the server. The most delicate paths become automated tests: split with
parallel sending, an LSN chain that advances only after a successful archiving, a
failed chunk, a lock already held. Tools: `bats-core` and `shellcheck` in GitHub
Actions, plus a job on Bash 4.2. The CI never contacts real databases, NetBackup or
credentials.

## 6. Roadmap

| Phase | Version | Content | Verifiable result |
|---|---|---|---|
| **F0** ✅ | v0.1.0 | repository, LICENSE/NOTICE/SPDX, layout, `bin/mycustos`, `core/` (common, log, config, errors), `version` / `help`, CI | `mycustos help` and the tests run in CI |
| **F1** ✅ | v0.2.0 | `core/auth.sh`, `preflight`, `check-config`, `config show` | commands without side effects, tested with the mocks |
| **F2 — Safe target** | v0.3.0 | languages (#13), `core/target.sh` (#6), `core/topology.sh` and exit code 9 (#7), `inspect` (#8), preflight with identity, topology and copy-ready fixes (#9), safe `mycustos.conf` (#10), `setup` wizard (#11) | all read-only, tested with the `mysql` mock |
| **F3 — First local FULL** | v0.4.0 | mysqldump engine with footer and invalid views, simple packaging gzip/zstd, archive target `none` + retention, archive check + `keep_backup_dir`, lock, `.OK` / `.WARN` / `.ERR` flags, summary from the trap, `backup --dry-run`, `status` | first end-to-end FULL (mocks + test VM) |
| **F4 — Split and NetBackup** | v0.5.0 | split, generic job queue, `netbackup` without `-L`, job inventory, `archive_include_existing`, `mycustos archive`, monitor | split and parallel sending tested with the mocks |
| **F5 — INCR chain** | v0.6.0 | `core/chain.sh` with mysqlbackup, checks of 4.9 | tests on the LSN chain, error case included |
| **F6 — Other engines and release** | v0.7.0 → v1.0.0 | mydumper, xtrabackup, mariadb-backup, `config migrate`, `contrib/` (systemd, cron, notifier), release tarball | release published after a test on a real server |

## 7. Decisions

- Single entry point **`mycustos`** with English sub-commands.
- **Self-contained layout on the backup mount point**: `bin/`, `config/`, `data/`,
  `logs/`. No `etc/`, `var/`, `lib/`.
- Code in **`bin/modules/`**, grouped by kind.
- Configuration file: **`config/mycustos.conf`**, `KEY=value`, parsed against a
  whitelist, never `source`d.
- INCR chain state and lock **in `config/`**.
- Flags `.OK`, `.WARN`, `.ERR`, `.TIMEOUT` and statuses as in 4.7.
- Exit code **9** for a wrong or unsupported target.
- New keys: `expect_*`, `mysqldump_allow_invalid_views`, `keep_backup_dir`,
  `archive_include_existing`, `language`.
- **SemVer**: `v0.1.0` at the end of F0, `v1.0.0` only after validation on a real
  server.
