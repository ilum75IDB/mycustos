# Proposta di ri-ingegnerizzazione — mycustos

**Data**: 2026-10-21 (rev. 3: tutte le decisioni chiuse)
**Stato**: approvata (2026-10-21)
**Base di partenza**: `MYSQL-Backup v2.00.14` (sorgenti in `docs/originali-da-non-postare-su-github/`, esclusi da git)

---

## 1. Un file unico o più file? Più moduli, con un solo punto d'ingresso

Opzioni valutate:

| Opzione | Pro | Contro |
|---|---|---|
| **A. Tutto in un file** (v1.6 dentro la main) | un solo file da copiare sul server | 2.500+ righe; test, revisione ed estensioni difficili. È già il problema di oggi, la main ha 1.950 righe |
| **B. Moduli caricati a runtime** ✅ | ogni parte si testa da sola; motori e destinazioni di archiviazione diventano moduli aggiungibili; revisione semplice | servono più file sul server (un tarball o un `git clone` risolvono) |
| **C. Moduli + build in un file unico** | i vantaggi di B più la distribuzione di un solo file | serve uno step di build |

**Scelta raccomandata: B**, con C come opzione futura (`make dist`) se servirà distribuire un solo file sui server. Unire la v1.6 nella main peggiorerebbe proprio il problema che vogliamo risolvere.

La libreria v1.6 viene **riscritta da zero** (decisione presa il 2026-10-21): risolve il dubbio sulla titolarità e permette di correggere i difetti storici.

## 2. Struttura

Bisogna distinguere **cosa c'è nel repo** da **cosa finisce sul server**. Sul server la struttura resta quella di oggi.

### 2.1 Sul server: layout autocontenuto sul mount point di backup

Il caso d'uso tipico è *"mi assegnano un mount point per il backup e installo tutto lì"*. La struttura resta quella della v2.00.14 (`bin/`, `config/`, `data/`, `logs/`): autocontenuta, da copiare, spostare o cancellare in blocco, senza directory che ricordino quelle di sistema (`etc/`, `var/`, `lib/`).

```text
/<mount-point-backup>/
├── bin/
│   ├── mycustos                    # l'unico comando che il DBA lancia
│   └── modules/                    # il codice: nessuno deve toccarlo
│       ├── core/
│       │   ├── common.sh           # die, require_cmd, gestione dei temporanei (mktemp), helper
│       │   ├── log.sh              # logger, log per fase, comando tail di riepilogo
│       │   ├── config.sh           # ricerca, lettura e validazione della config, valori di default, precedenze
│       │   ├── errors.sh           # codici errore e di uscita stabili, severità
│       │   ├── lock.sh             # flock
│       │   ├── status.sh           # flag OK/ERR/TIMEOUT, storico, file di stato
│       │   ├── summary.sh          # BACKUP SUMMARY (scritto sempre, dal trap)
│       │   ├── hooks.sh            # script pre/post backup e pre/post archiviazione
│       │   ├── notify.sh           # invio delle notifiche
│       │   ├── retention.sh        # pulizia di log e archivi locali
│       │   ├── auth.sh             # CNF / LOGIN_PATH / AUTO, isolamento da ~/.mylogin.cnf
│       │   └── chain.sh            # catena LSN: pending → commit
│       ├── engines/                # un file per motore
│       │   ├── engine.sh           # rilevamento automatico + contratto comune
│       │   ├── mysqlbackup.sh
│       │   ├── mysqldump.sh
│       │   ├── mydumper.sh
│       │   └── xtrabackup.sh       # usato anche da mariadb-backup
│       ├── packaging/
│       │   ├── compress.sh         # gzip / zstd
│       │   ├── simple.sh
│       │   └── split.sh            # stream diviso in chunk, ognuno passato all'archiviazione appena chiuso
│       ├── archive/                # un file per destinazione
│       │   ├── archive.sh          # coda dei job, parallelismo, raccolta degli esiti (generico)
│       │   ├── none.sh             # solo locale (con retention)
│       │   └── netbackup.sh        # bparchive + monitor sar/iostat/ss opzionale
│       ├── notifiers/
│       │   ├── none.sh
│       │   └── command.sh          # comando esterno generico (mail, opcmsg, webhook…)
│       └── commands/               # un file per sottocomando
│           ├── backup.sh
│           ├── preflight.sh
│           ├── check-config.sh
│           ├── status.sh
│           ├── config.sh           # config show / config migrate
│           ├── version.sh
│           └── help.sh
├── config/
│   ├── mycustos.conf               # configurazione (nella v2.00.14: backup.conf)
│   ├── backup-credentials.conf     # credenziali MySQL, permessi 600
│   ├── lsn.txt                     # stato della catena INCR (runtime)
│   ├── backup_chain.state          # stato della catena INCR (runtime)
│   └── mycustos.lock               # lock flock (runtime)
├── data/                           # i backup
└── logs/                           # log e flag
```

Le scelte:

- **Restano le quattro directory di oggi.** Il codice va in `bin/modules/`: `bin/` significa già "programmi", quindi non si aggiungono directory al primo livello.
- **Moduli raggruppati in sottocartelle per tipo** (`core/`, `engines/`, `packaging/`, `archive/`, `notifiers/`, `commands/`): chi deve aggiungere un motore o una destinazione sa subito dove guardare.
- **Lo stato (LSN, catena, lock) resta in `config/`, come oggi.** La procedura di aggiornamento dice già di salvare `config/`, quindi la catena si salva insieme. E se qualcuno svuota `data/` per liberare spazio, la catena INCR non si perde.
- **Il file di config si chiama `mycustos.conf`**: accanto a un `my.cnf` o al `backup.conf` di altri strumenti si capisce subito di chi è. `mycustos config migrate` legge il vecchio `backup.conf`.

### 2.2 Nel repo GitHub

```text
mycustos/                           # repo
├── bin/                            # ← va sul server
│   ├── mycustos
│   └── modules/...
├── config/                         # ← va sul server (solo i template)
│   ├── mycustos.conf.example
│   └── backup-credentials.conf.example
├── contrib/                        # esempi opzionali, non installati
│   ├── systemd/                    # mycustos-backup@.service + .timer
│   ├── cron/mycustos.cron.example
│   └── notifiers/opcmsg.sh.example # l'integrazione SCR diventa un esempio, non codice core
├── tests/
│   ├── mocks/bin/                  # finti mysql, mysqlbackup, mysqldump, bparchive, zstd
│   └── *.bats
├── docs/
├── Makefile                        # lint, test, release (tarball)
├── LICENSE · NOTICE · README.md · CHANGELOG.md · SECURITY.md · CONTRIBUTING.md
└── .gitignore                      # esclude config reali, data/, logs/, stato e docs/originali-da-non-postare-su-github/
```

**La release** è un tarball che contiene solo `bin/`, `config/*.example`, `README.md`, `LICENSE` e `NOTICE`. Installazione: si estrae sul mount point, si creano `data/` e `logs/`, si copiano i template `.example` e si personalizzano.

### 2.3 Punto d'ingresso

`bin/mycustos` risolve la propria posizione con `readlink -f`. Così funziona anche come symlink in `/usr/local/bin/mycustos`, ricava la base (`bin/..`) e carica solo i moduli del sottocomando richiesto:

```bash
MYCUSTOS_HOME=$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd -P)
MYCUSTOS_MODULES="$MYCUSTOS_HOME/bin/modules"
source "$MYCUSTOS_MODULES/core/common.sh"
cmd=${1:-help}; shift || true
case $cmd in
  backup|preflight|check-config|status|config|version|help) ;;
  *) die_usage "unknown command: $cmd" ;;
esac
source "$MYCUSTOS_MODULES/commands/$cmd.sh"
"cmd_${cmd//-/_}" "$@"
```

## 3. I comandi

```text
mycustos backup [--type full|incr] [--dry-run]
mycustos preflight [--test-connection]
mycustos check-config
mycustos status                     # esito dell'ultima esecuzione (dal file di stato)
mycustos config show                # config effettiva, con l'origine di ogni valore
mycustos config migrate FILE        # converte un vecchio backup.conf in mycustos.conf
mycustos version
mycustos help [command]

Opzioni globali: --config FILE · --home DIR · --quiet · --verbose
```

Corrispondenza con la v2.00.14: `--dry-run` diventa un'opzione di `backup`, `--preflight` diventa il sottocomando `preflight`, `--config-version` confluisce in `check-config` e in `version`, `--backup_base_dir` diventa `--home`. `mycustos verify` è previsto in una fase successiva (vedi §5).

## 4. Le scelte di progetto importanti

### 4.1 Contratto comune per i motori, e il dry-run usa lo stesso codice

Ogni motore (`bin/modules/engines/<nome>.sh`) espone funzioni con nomi fissi:

```bash
engine_mysqldump_capabilities()  { echo "full"; }   # mysqlbackup: "full incr"
engine_mysqldump_build_cmd()     { ...; }           # riempie l'array MC_CMD
engine_mysqldump_run()           { ...; }           # esegue MC_CMD
engine_mysqldump_end_lsn()       { return 1; }      # solo mysqlbackup lo implementa
```

**Il dry-run e il backup reale chiamano lo stesso `build_cmd`.** Nella v2.00.14 il dry-run ricostruisce i comandi per conto suo (`HotBackupArchiviazione-mysql_ALL.sh:371-392`), e i due percorsi già divergono. Per esempio, il dry-run di mysqldump mostra sempre `--login-path` anche quando l'autenticazione reale userebbe il CNF. Con un unico `build_cmd` il dry-run mostra esattamente il comando reale.

### 4.2 Archiviazione separata dal packaging

Nella v2.00.14 la logica degli slot paralleli è legata a NetBackup. Va portata in `archive/archive.sh` come coda generica di job. Ogni destinazione implementa solo quattro funzioni:

```bash
archive_<b>_check              # usata da preflight
archive_<b>_submit FILE        # avvia il trasferimento in background
archive_<b>_poll JOB           # running | ok | failed
archive_<b>_consumes_source    # true per bparchive (semantica ARCHIVE)
```

`packaging/split.sh` passa ogni chunk alla coda appena è chiuso e non sa quale destinazione c'è dietro. Domani `rsync` o `s3` sono un file nuovo in `archive/`, senza toccare il resto. È lo stesso schema a moduli di **dba-cockpit**, applicato in Bash.

### 4.3 La config viene letta, non eseguita

Nella v2.00.14 `backup.conf` viene eseguito con `source`: è codice Bash a tutti gli effetti, e il preflight per questo deve leggerlo con un parser a parte. Proposta: **unico parser `KEY=value`** con chiavi ammesse in una whitelist, usato da tutti i comandi. Esempio di `config/mycustos.conf`:

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
```

- Le uniche espansioni ammesse sono `${MYCUSTOS_HOME}`, `${MYCUSTOS_CONFIG}`, `${MYCUSTOS_DATA}` e `${MYCUSTOS_LOGS}`. Una chiave sconosciuta è un errore, così i refusi vengono segnalati subito.
- Ordine di precedenza: **CLI > variabili d'ambiente `MYCUSTOS_*` > `mycustos.conf` > default**.
- **`config_schema` al posto della versione allineata.** Oggi ogni release obbliga a cambiare `config_version` ed `error_messages_version` anche se la config non è cambiata. Con uno schema versionato si aggiorna solo quando cambia davvero il formato.
- `error_messages.conf` sparisce: codici e messaggi (in inglese) stanno in `core/errors.sh`.

### 4.4 Directory: autocontenute per default, spostabili se serve

| Cosa | Default | Variabile | Override opzionale |
|---|---|---|---|
| codice | `<base>/bin` | `MYCUSTOS_HOME` = `<base>` | `--home DIR` |
| config + stato (LSN, catena, lock) | `<base>/config` | `MYCUSTOS_CONFIG` | `--config FILE` |
| backup | `<base>/data` | `MYCUSTOS_DATA` | `data_dir=` in `mycustos.conf` |
| log e flag | `<base>/logs` | `MYCUSTOS_LOGS` | `logs_dir=` in `mycustos.conf` |

`<base>` è il mount point di backup su cui è installato mycustos, ricavato automaticamente dalla posizione di `bin/mycustos`: non serve scriverlo da nessuna parte.

Il controllo della v2.00.14 che obbliga le directory derivate a stare sotto la base (`HotBackupArchiviazione-mysql_ALL.sh:268`) resta per i valori di default, che protegge da errori nella config. Quando invece `data_dir` o `logs_dir` sono impostati esplicitamente, si verifica solo che siano percorsi assoluti, diversi da `/` e scrivibili.

## 5. Cosa migliora riscrivendo la v1.6

| v2.00.14 | mycustos |
|---|---|
| `logger … >> $flag_file_err` scrive file vuoti | i flag vengono scritti esplicitamente da `core/status.sh` |
| socket assente → exit 0, ma il riepilogo dice 101 | tabella dei codici di uscita, unica e documentata |
| `log_postArchive` uguale a `log_postExport` | log di fase con nomi generati in un unico punto |
| svecchiamento con `for f in $(find … -ctime)` su tutti i file | `find … -name pattern -mtime +N -delete` limitato ai file di mycustos |
| `/tmp/full_chunk500_<data>_<pid>` | `mktemp -d` |
| `opcmsg` e mail-sender scritti nel codice | notifier `command` generico; SCR va in `contrib/` |
| nessuna retention con NetBackup disabilitato | `retention_days` / `retention_count` per l'archiviazione `none` |
| valori aziendali come default (media server, LV, `/mysql`) | nessun default specifico di un ambiente |
| CLI e log in italiano | tutto in inglese |
| restore mai verificato | in seguito: `mycustos verify` (`zstd -t`/`gzip -t`, controllo completezza del manifest dei chunk) |

Requisito minimo: **Bash 4.2**, quindi anche RHEL 7. Si usa `set -uo pipefail` con controlli espliciti, senza `set -e`, che in Bash ha troppi casi limite per uno script del genere.

## 6. Test

I finti eseguibili in `tests/mocks/bin/` permettono di provare **in CI il flusso completo senza un database**:

- un finto `mysql` restituisce un `version_comment` a scelta (Enterprise, Community, MariaDB);
- un finto `mysqlbackup` crea la directory con `meta/backup_variables.txt` ed `end_lsn`;
- un finto `bparchive` cancella il file e restituisce il codice d'uscita che serve al test;
- `CHUNK_SIZE=4K` fa produrre al modo split molti chunk anche con pochi KB di dati.

Ogni test crea una base temporanea con `bin/`, `config/`, `data/` e `logs/`, cioè lo stesso layout del server. Così diventano test automatici proprio i percorsi più delicati: split con invio in parallelo, catena LSN che avanza solo dopo l'archiviazione riuscita, chunk fallito, lock già occupato. Strumenti: `bats-core` + `shellcheck` in GitHub Actions. La CI non contatta mai database, NetBackup o credenziali reali.

## 7. Da dove viene ogni parte e dove va

Percorsi relativi a `bin/modules/`.

| Origine (v2.00.14) | Destinazione |
|---|---|
| v1.6: logger, init, flag, hook, svecchiamento | `core/log.sh`, `core/status.sh`, `core/hooks.sh`, `core/retention.sh` (riscritti) |
| v1.6: `segnalazione_scr`, `invio_email` | `core/notify.sh` + `notifiers/` |
| main: parsing CLI, ricerca della config | `bin/mycustos` + `core/config.sh` |
| main: `select_backup_auth`, `prepare_cnf_isolation` | `core/auth.sh` |
| main: `resolve_backup_engine`, `run_hotbackup`, `run_other_engine` | `engines/*` |
| main: `read_backup_end_lsn`, `commit_backup_lsn` | `core/chain.sh` + `engines/mysqlbackup.sh` |
| main: `create_single_archive`, `create_chunks_and_dispatch` | `packaging/*` |
| main: `launch_nb_chunk`, `reap…`, `wait…`, monitor NetBackup | `archive/archive.sh` (coda) + `archive/netbackup.sh` |
| main: `summary_*`, `append_summary_tail_command` | `core/summary.sh`, `core/log.sh` |
| main: blocco dry-run | sparisce; diventa un'opzione di `commands/backup.sh` che riusa `build_cmd` |
| preflight | `commands/preflight.sh`, con i controlli chiesti a ogni motore e destinazione (`*_check`) |
| `config/backup.conf` + `error_messages.conf` | `config/mycustos.conf` (+ `commands/config.sh migrate`) e `core/errors.sh` |

## 8. Roadmap

| Fase | Contenuto | Risultato verificabile |
|---|---|---|
| **F0** | `git init` con il `.gitignore` giusto, LICENSE/NOTICE/SPDX, struttura, `bin/mycustos`, `core/` (common, log, config, errors), `version`/`help`, CI con shellcheck + bats | `mycustos help` e i test girano in CI |
| **F1** | `core/auth.sh`, `preflight`, `check-config`, `config show` | comandi senza effetti collaterali, testati con i mock |
| **F2** | motori, packaging simple, archiviazione `none` + retention, lock, flag, summary, `backup --dry-run`, `status` | primo FULL locale end-to-end (mock + VM di test) |
| **F3** | split, coda generica dei job, archiviazione `netbackup`, monitor | split e invio in parallelo testati con i mock |
| **F4** | catena INCR con mysqlbackup (`core/chain.sh`) | test sulla catena LSN, incluso il caso di errore |
| **F5** | `config migrate`, `contrib/` (systemd/cron/notifier), tarball di release, README e docs in inglese | release pubblicabile dopo una prova su un server reale |

## 9. Decisioni

### Prese (2026-10-21)

- Libreria v1.6 **riscritta** (ed eventualmente migliorata), non portata così com'è.
- Unico punto d'ingresso **`mycustos`** con sottocomandi in inglese (`backup`, `preflight`, `check-config`, …).
- **Layout autocontenuto sul mount point di backup**, con le stesse directory di oggi: `bin/`, `config/`, `data/`, `logs/`. Niente `etc/`, `var/`, `lib/`.
- Codice in **`bin/modules/`**, raggruppato in sottocartelle per tipo.
- File di configurazione: **`config/mycustos.conf`**.
- Stato della catena INCR e lock **in `config/`**, come oggi.
- **Versionamento SemVer**: `v0.1.0` alla fine di F0, `v1.0.0` solo dopo la validazione su un server reale.
- **Flag compatibili** con il monitoraggio attuale: il formato dei nomi (`<data>_<instance>_<type>.OK`, `<data>_<instance>_<database>_<type>.ERR` / `.TIMEOUT`) e lo storico `flag_file_esito_backup.log` restano quelli della v2.00.14.
- **Config `KEY=value`**, letta dal parser con whitelist delle chiavi, mai eseguita con `source`.

### Aperte

Nessuna.
