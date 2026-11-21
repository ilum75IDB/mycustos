# Delta v2.00.14 → v2.06.00 — cosa entra in mycustos

**Data**: 2026-11-21
**Stato**: proposta (in attesa di approvazione)
**Riferimento**: [`01-proposta-reingegnerizzazione.md`](01-proposta-reingegnerizzazione.md) (approvata il 2026-10-21, basata sulla v2.00.14)

La procedura monolitica originale è passata dalla v2.00.14 (main da 1.950 righe + libreria v1.6) alla v2.06.00 (un unico script da circa 3.100 righe + preflight). La libreria v1.6 è stata assorbita nello script. Questo documento elenca le novità **funzionali** che mycustos deve recepire, quelle da **non** portare e l'impatto sulla roadmap.

Le sorgenti restano fuori da git (`docs/originali-da-non-postare-su-github/`). Qui si descrive solo il comportamento, in forma generica: nessun nome, valore o messaggio viene copiato.

---

## 1. Novità da recepire

### 1.1 Identità dell'istanza (v2.04) — sicurezza, priorità alta

Prima di qualsiasi backup, la procedura verifica di essere collegata **all'istanza giusta**. Sui server con più istanze, un `SELECT 1` riuscito non basta.

- Interroga `@@version` e `@@version_comment` e distingue MySQL da MariaDB **prima** di leggere variabili specifiche: MariaDB non ha `@@server_uuid`.
- Legge `@@hostname`, `@@port`, `@@socket`, `@@datadir` e poi `@@server_uuid` (MySQL) o `@@server_id` (MariaDB). Se manca anche un solo valore, si blocca.
- Se il socket è configurato, deve coincidere con `@@socket`.
- Valori attesi facoltativi: se impostati e diversi da quelli letti, il backup si blocca. Se si imposta un UUID atteso su MariaDB, è un errore di configurazione.

**In mycustos**: nuovo modulo `core/target.sh`, con queste nuove chiavi di configurazione (vuote per default):

| Chiave | Confronto con |
|---|---|
| `expect_hostname` | `@@hostname` |
| `expect_port` | `@@port` |
| `expect_datadir` | `@@datadir` |
| `expect_server_uuid` | `@@server_uuid` (solo MySQL; su MariaDB è un errore di configurazione) |
| `expect_server_id` | `@@server_id` (solo MariaDB) |
| `mysql_socket` (esiste già) | `@@socket`, se impostato |

### 1.2 Topologia e ruolo del nodo (v2.04) — sicurezza, priorità alta

Regola: **si fa il backup solo sul PRIMARY**, e qualsiasi dubbio blocca.

| Situazione | Esito |
|---|---|
| MySQL senza Group Replication | backup consentito (`SINGLE_INSTANCE`) |
| Group Replication, nodo `PRIMARY` `ONLINE` | backup consentito |
| Group Replication, nodo `SECONDARY` `ONLINE` | **nessun backup**, exit 0, stato `SKIPPED_SECONDARY`, nessun flag; nel log vanno host, IP e porta del PRIMARY |
| plugin GR presente ma nessun membro visibile, membri incoerenti, numero di PRIMARY online diverso da 1, nodo locale non `ONLINE` | blocco |
| `performance_schema.replication_group_members` non leggibile | blocco: un errore **non** va interpretato come SINGLE |
| MariaDB `wsrep_on=OFF` | standalone, backup consentito |
| MariaDB `wsrep_on=ON` (Galera) | blocco: la regola "solo PRIMARY" non si applica a un multi-primary |
| MariaDB `wsrep_on` assente o ambiguo | blocco |

La replica asincrona tradizionale non viene valutata, come nell'originale. La procedura non si sposta sul PRIMARY: si limita a dire dov'è.

**In mycustos**: `core/topology.sh`, chiamato da `backup` e da `preflight --test-connection`. Ci vuole un nuovo codice di uscita: **`MC_EX_TARGET=9`**, "istanza sbagliata o topologia non supportata". Va **aggiunto** alla tabella di `core/errors.sh`, perché i codici esistenti non si rinumerano.

### 1.3 Comando di ispezione (v2.04)

`--inspect-target` stampa in sola lettura, nel formato `CHIAVE=valore`: identità, autenticazione usata, topologia, ruolo, PRIMARY e motore che verrebbe scelto.

**In mycustos**: nuovo sottocomando **`mycustos inspect`**, che si appoggia a `core/target.sh`, `core/topology.sh` e al rilevamento del motore. L'output `KEY=value` è stabile, così si può usare negli script. Il comando va aggiunto alla lista di `bin/mycustos` e a `help`.

### 1.4 mysqldump e viste non valide (v2.06) — da attivare esplicitamente

Per default, un errore di mysqldump fa fallire il backup (fail-closed). Con l'opzione attiva:

- a `mysqldump` si aggiunge `--force`;
- lo stderr viene letto riga per riga e si accetta **solo** l'errore 1356 (vista che fa riferimento a tabelle, colonne o funzioni non valide) nel formato atteso, da cui si ricava `schema.vista`. Le righe `[Warning]` del client vengono registrate. **Qualsiasi altra riga fa fallire l'export**;
- il dump deve essere non vuoto e terminare con il footer `-- Dump completed`;
- un rc diverso da zero senza alcuna vista riconosciuta è un fallimento;
- l'esito diventa `COMPLETED_WITH_WARNINGS`, con flag **`.WARN`** al posto di `.OK`. Il riepilogo riporta l'rc originale, il numero e l'elenco delle viste escluse, e avverte che quelle viste non si ripristinano.

**In mycustos**:
- chiave `mysqldump_allow_invalid_views=false`;
- parser in `engines/mysqldump.sh`, con test Bats su stderr sintetici (solo 1356; 1356 più un errore di connessione; dump senza footer; rc≠0 senza viste);
- **miglioramento**: il controllo "non vuoto + footer" vale **sempre** per mysqldump, non solo con `--force`. Un dump troncato con rc 0 è comunque un dump inutilizzabile.

### 1.5 Esiti, flag e riepilogo (v2.04–v2.06)

Stati finali, con gli stessi nomi dell'originale per non rompere il monitoraggio:

| `EXECUTION STATUS` | Exit | Flag |
|---|---|---|
| `LOCAL_BACKUP_OK` | 0 | `.OK` |
| `BACKUP_ARCHIVED_OK` | 0 | `.OK` |
| `COMPLETED_WITH_WARNINGS` | 0 | **`.WARN`** (nuovo) |
| `SKIPPED_SECONDARY` | 0 | nessuno |
| `FAILED` | ≠0 | `.ERR` o `.TIMEOUT` |

Il `BACKUP SUMMARY` viene scritto **sempre** dal trap `EXIT` e contiene, per ogni fase (backup, compressione, archiviazione, rimozione), inizio, fine, durata ed esito. Riporta anche dimensione della directory e dell'archivio con il rapporto di compressione, topologia e ruolo, e in caso di errore la sezione `ERROR DETAILS`: fase, comando fallito, messaggio, file di log e riga. In fondo ci sono i comandi `tail` pronti per ogni log.

**In mycustos**: `core/status.sh` e `core/summary.sh`, già previsti, si allineano a questa tabella. Il flag `.WARN` va aggiunto alle decisioni sui "flag compatibili".

### 1.6 Conservazione della directory di backup e verifica dell'archivio (v2.04–v2.05)

| Archiviazione | Directory conservata | Comportamento |
|---|---|---|
| nessuna | sì (default) | si conservano directory e archivio |
| nessuna | no | **verifica completa dell'archivio** (`gzip -dc`/`zstd -dc` \| `tar -tf -`, su tutti i chunk in sequenza in modalità split), poi rimozione della directory; l'archivio resta |
| NetBackup | sì | si conserva la directory |
| NetBackup | no | rimozione solo dopo l'**archiviazione riuscita** |

Le directory dei backup precedenti non vengono mai rimosse da questa logica.

**In mycustos**: chiave `keep_backup_dir=true`. La verifica dell'archivio anticipa una parte di `mycustos verify`: la funzione va in `packaging/verify.sh` e il comando `verify` la riuserà in seguito.

### 1.7 NetBackup (v2.05)

- `bparchive` **senza `-L`**: stdout, stderr e rc di ogni job vengono catturati dalla procedura.
- **Inventario dei job** nel riepilogo: per ogni file inviato stato (`OK`/`FAILED`/`NOT_COMPLETED`/`SKIPPED_NOT_SENT`), rc, tipo (`CURRENT_FULL` / `CURRENT_CHUNK` / `PREEXISTING`), byte e percorso, più i totali. L'inventario si basa sui job registrati, non sui file su disco, perché `bparchive` può averli già cancellati.
- **Invio degli archivi preesistenti** (`netbackup_archive_all_files`): l'elenco viene fotografato **prima** dell'export e ogni archivio viene inviato come **job indipendente**, non come chunk del backup nuovo.
- **Bug corretto nella v2.05**: lo scope dinamico di Bash tra la funzione che avvia un job e quella che ne raccoglie l'esito faceva perdere il percorso del job mentre aspettava uno slot libero. Per mycustos: `local` ovunque, ShellCheck, e un test con `parallel=1` e archivi preesistenti.
- **Invio di un solo archivio** (`--netbackup-only --file=PATH [--dry-run]`), senza fare un nuovo backup.

**In mycustos** (fase NetBackup):
- chiave `archive_include_existing=false`;
- inventario dei job generato da `archive/archive.sh`, quindi uguale per tutte le destinazioni;
- nuovo sottocomando **`mycustos archive FILE… [--dry-run]`**, che usa la stessa coda e la stessa destinazione del backup.

### 1.8 Preflight con comandi pronti da copiare (v2.06)

Per ogni problema trovato, il preflight **suggerisce** il comando che lo corregge, senza mai eseguirlo:

- config mancante: `cp -p -- config/mycustos.conf.example config/mycustos.conf`;
- chiave da cambiare, anche se è commentata: `sed -i -E 's|^#?[[:space:]]*KEY=.*|KEY=valore|' config/mycustos.conf`;
- chiave assente: `printf 'KEY=valore\n' >> config/mycustos.conf`;
- suggerimenti legati a quello che è successo davvero: login-path assente, compressore mancante, NetBackup senza policy o schedule, errori 1356 già presenti nei log precedenti (in quel caso si propone di attivare l'opzione 1.4).

**In mycustos**: i `_pf_fail … 'hint'` di F1 diventano comandi copiabili quando la correzione si può esprimere come comando. Il controllo dei log precedenti arriva quando esistono i log (fase del primo FULL).

### 1.9 Sicurezza del file di configurazione (v2.04)

L'override locale viene rifiutato se non è un file regolare, se è un symlink, se il proprietario non è l'utente che esegue né root, o se è scrivibile dal gruppo o da altri.

**In mycustos**: lo stesso controllo su `mycustos.conf`, in `core/config.sh`. Da noi il rischio è minore, perché il file viene letto e non eseguito, ma chi lo modifica decide comunque *dove* finiscono i dati e *quali* credenziali si usano.

### 1.10 Altri dettagli da conservare

- Socket assente: errore bloccante, non skip con exit 0 (era già la scelta di mycustos).
- `mydumper` richiede l'autenticazione `cnf`. `xtrabackup`/`mariadb-backup` vogliono `--defaults-file`/`--defaults-extra-file` come **prima** opzione. Questi vincoli vanno in `engine_<x>_check` e il preflight li mostra.
- INCR: si rifiuta **prima del lock** se manca lo stato della catena, e si controlla che `lsn.txt` coincida con `last_end_lsn` nello stato. Con archiviazione `none` la catena **non** avanza e l'LSN in attesa viene scartato (da confermare in F-INCR).
- `--dry-run` con `engine=auto` non può scegliere il motore senza connessione: in quel caso lo dice chiaramente.

## 2. Da non portare

| Nella v2.06.00 | Perché no |
|---|---|
| due file di config eseguiti con `source` (`backup.conf` + `backup.local.conf`) | in mycustos i default sono nello schema del codice e `mycustos.conf` **è** già l'override locale, letto e mai eseguito |
| `config_version` / `error_messages_version` allineati a ogni release | sostituiti da `config_schema` |
| socket ricavato con `awk` da `/etc/my.cnf` | default del client o `mysql_socket` esplicito, poi confronto con `@@socket` |
| il trap che rilegge il log e forza rc=101 se trova un messaggio di errore | in mycustos l'esito è una variabile esplicita, mai ricostruita dai log |
| l'esito "socket non trovato" ricavato cercando una frase nel log | come sopra |
| SCR/`opcmsg` e mail nel codice | notifier `command` + esempio in `contrib/` (già deciso) |
| messaggi in italiano | CLI e log in inglese (già deciso) |

## 3. Impatto sulla roadmap

Identità e topologia vanno fatte **prima** del primo backup reale: sono controlli in sola lettura (come F1) e proteggono dal rischio peggiore, cioè fare il backup dell'istanza sbagliata o di un nodo SECONDARY. Propongo quindi di inserire una fase e di far scalare le successive:

| Fase | Versione | Contenuto | Rispetto alla roadmap attuale |
|---|---|---|---|
| **F2 — Bersaglio sicuro** | v0.3.0 | `core/target.sh` (1.1), `core/topology.sh` (1.2), `MC_EX_TARGET=9`, `mycustos inspect` (1.3), preflight con comandi copiabili (1.8), controllo dei permessi di `mycustos.conf` (1.9) | **nuova**; tutto in sola lettura, testabile con il mock `mysql` |
| **F3 — Primo FULL locale** | v0.4.0 | motore mysqldump con footer + viste non valide (1.4), packaging simple gzip/zstd, archiviazione `none` + retention, verifica dell'archivio + `keep_backup_dir` (1.6), lock, flag `.OK/.WARN/.ERR`, summary dal trap (1.5), `backup --dry-run`, `status` | era F2 |
| **F4 — Split e NetBackup** | v0.5.0 | split, coda generica dei job, `netbackup` senza `-L`, inventario dei job, `archive_include_existing`, `mycustos archive` (1.7), monitor | era F3 |
| **F5 — Catena INCR** | v0.6.0 | `core/chain.sh` con mysqlbackup, controlli 1.10 | era F4 |
| **F6 — Altri motori e release** | v0.7.0 → v1.0.0 | mydumper, xtrabackup, mariadb-backup, `config migrate` (anche dal formato a due file v2.04+), `contrib/`, tarball, README | era F5 |

Le sotto-issue di F2 sarebbero:

1. `core/target.sh` + chiavi `expect_*` + confronto socket
2. `core/topology.sh` (GR + wsrep) + `MC_EX_TARGET`
3. `mycustos inspect`
4. preflight: identità, topologia e comandi copiabili
5. `core/config.sh`: controllo proprietario e permessi di `mycustos.conf`

## 4. Decisioni da prendere

1. Approvazione del delta e dello spostamento della roadmap (§3).
2. Nomi delle nuove chiavi: `expect_*`, `mysqldump_allow_invalid_views`, `keep_backup_dir`, `archive_include_existing`.
3. Nuovo codice di uscita `9` per istanza sbagliata o topologia non supportata (in alternativa si riusa `4`, ambiente).
