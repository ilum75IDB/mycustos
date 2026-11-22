# name: Italiano
# status: needs native review
#
# Catalogo dei messaggi di mycustos — italiano.
# Stesse chiavi e stessi segnaposto (%s, %d, nello stesso ordine) di en.msg.
# Nomi di chiavi, opzioni e comandi restano in inglese. Vedi CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=attenzione: %s
core.cannot_load=impossibile caricare %s
core.cannot_create=impossibile creare %s
core.tmpdir=impossibile creare una directory temporanea
log.cannot_write=impossibile scrivere il file di log: %s
i18n.unknown_language=la lingua '%s' non è disponibile, uso l'inglese (disponibili: %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Eseguire 'mycustos help' per l'uso.
cli.option_needs_value=l'opzione %s richiede un valore
cli.unknown_option=opzione sconosciuta: %s
cli.unknown_command=comando sconosciuto: %s
cli.home_not_dir=--home: non è una directory: %s
cli.not_implemented=%s non è ancora implementato in mycustos %s
cli.cmd_unknown_option=%s: opzione sconosciuta: %s
cli.cmd_unknown_argument=%s: argomento sconosciuto: %s
cli.missing_subcommand=%s: sottocomando mancante (%s)
cli.unknown_subcommand=%s: sottocomando sconosciuto: %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - esecuzione standardizzata dei backup MySQL
help.usage=Uso: mycustos <comando> [opzioni]
help.commands=Comandi:
help.global_options=Opzioni globali:
help.flag_not_implemented=(non ancora implementato)
help.not_implemented=Non ancora implementato in mycustos %s.
help.languages=Lingue: %s (attuale: %s)
help.installation=Installazione: %s
help.cmd.backup=Esegue un backup FULL o INCR (--type full|incr, --dry-run)
help.cmd.preflight=Controlla i prerequisiti e suggerisce le modifiche alla config (sola lettura)
help.cmd.inspect=Mostra quale istanza viene raggiunta e cosa farebbe lì un backup (sola lettura)
help.cmd.check_config=Valida mycustos.conf e segnala tutti i problemi (sola lettura)
help.cmd.status=Mostra l'esito dell'ultima esecuzione
help.cmd.config=Mostra la configurazione effettiva o importa un file esistente
help.cmd.version=Mostra versione e attribuzione
help.cmd.help=Mostra questo help, o l'help di un comando
help.opt.config=File di configurazione (default: <home>/config/mycustos.conf; FILE.local.conf, se presente, la sovrascrive)
help.opt.home=Base di config/, data/ e logs/ (default: l'installazione)
help.opt.lang=Lingua dei messaggi (default: language= o il locale del sistema)
help.opt.quiet=Mostra solo avvisi ed errori
help.opt.verbose=Mostra anche i messaggi di debug
help.opt.help=Come "mycustos help"
help.opt.version=Come "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=file di configurazione non trovato o non leggibile
cfg.unsafe_symlink=deve essere un file regolare, non un link simbolico: indica il file reale con --config o sostituisci il link con una copia
cfg.unsafe_owner=appartiene all'uid %s: deve appartenere all'utente che esegue mycustos o a root (esegui: %s)
cfg.unsafe_perms=scrivibile dal gruppo o da altri (esegui: %s)
cfg.expected_kv=atteso chiave=valore
cfg.unknown_key=chiave sconosciuta: %s
cfg.duplicate_key=chiave duplicata: %s (già impostata alla riga %s)
cfg.expansion_not_allowed=%s non è ammesso qui
cfg.only_expansions=si possono espandere solo ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} e ${MYCUSTOS_LOGS}
cfg.schema_missing=mancante: aggiungere config_schema=%s
cfg.schema_unsupported=valore non supportato '%s' (questa versione legge config_schema=%s)
cfg.int_range=deve essere un intero tra %s e %s (trovato '%s')
cfg.enum=deve essere uno tra: %s (trovato '%s')
cfg.name=deve iniziare con una lettera o una cifra e contenere solo lettere, cifre, '.', '_' e '-' (trovato '%s')
cfg.dblist=deve essere ALL o un elenco di database separati da virgole, senza spazi (trovato '%s')
cfg.path=deve essere un percorso assoluto diverso da / (trovato '%s')
cfg.language=deve essere un codice di lingua come en, it o pt_BR (trovato '%s')
cfg.uuid=deve essere un UUID come 3e11fa47-71ca-11e1-9e33-c80aa9429562 (trovato '%s')
cfg.gzip_level=deve essere tra 1 e 9 con compress=gzip (trovato '%s')
cfg.incr_engine=incr è supportato solo con engine=mysqlbackup (trovato engine=%s)
cfg.login_path_required=obbligatorio con auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=config_schema supportato: %s (mycustos %s)
cc.result_valid=Esito: valida, %d avviso/i
cc.result_invalid=Esito: non valida, %d errore/i
cc.warn_incr_auto=backup_type=incr con engine=auto funziona solo se l'edizione del server seleziona mysqlbackup (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path viene ignorato con auth_method=cnf
cc.warn_cnf_ignored=auth_cnf viene ignorato con auth_method=login-path
cc.warn_same_dirs=logs_dir è la stessa directory di data_dir
cc.warn_language_missing=la lingua '%s' non è disponibile, si usa l'inglese (disponibili: %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto: %s non trovato e auth_login_path è vuoto
auth.invalid_method=auth_method: valore non valido: %s
auth.cnf_not_found=file non trovato: %s
auth.cnf_not_readable=non è un file leggibile: %s
auth.cnf_no_client=nessuna sezione [client] in %s
auth.cnf_perms=permessi più ampi di 0600 su %s (eseguire: %s)
auth.desc_cnf=file di opzioni %s
auth.desc_lp=login path %s
auth.lp_file=file di login non trovato o non leggibile: %s
auth.lp_undefined=login path '%s' non definito in %s
auth.lp_unverified=mysql_config_editor non trovato, '%s' non verificato

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - istanza %s
pf.configuration=configurazione: %s
pf.result=Esito: %d OK, %d avviso/i, %d errore/i
pf.conn_skipped=test di connessione saltato: autenticazione o client mysql non disponibili
pf.engine_auto_later=motore: auto, scelto al momento del backup in base all'edizione del server
pf.engine_auto_hint=(eseguire "mycustos preflight --test-connection" per vedere quale)
pf.auth_ok=autenticazione: %s
pf.dir_missing=directory non trovata: %s
pf.hint_mkdir=crearla: %s
pf.dir_not_writable=non scrivibile da %s: %s
pf.config_dir_ok=directory di config scrivibile: %s
pf.config_dir_not_writable=directory di config non scrivibile da %s: %s
pf.config_dir_hint=contiene il lock e lo stato della catena INCR
pf.free_space=%d GiB disponibili
pf.free_space_unknown=impossibile leggere lo spazio libero di %s
pf.need_tar=packaging
pf.need_flock=lock di esecuzione singola (pacchetto util-linux)
pf.need_mysql=client MySQL, usato per riconoscere il server e testare la connessione
pf.need_bparchive=archive_backend=netbackup (client NetBackup)
pf.tmp_login=impossibile creare il file di login temporaneo
pf.cannot_connect=impossibile connettersi al server MySQL con %s
pf.cannot_connect_hint=controllare le credenziali e mysql_socket
pf.connection_ok=connessione: server MySQL %s (%s)
pf.unknown_edition=edizione sconosciuta
pf.edition_unknown=engine=auto: edizione del server non riconosciuta: %s
pf.empty=vuota
pf.set_engine_hint=impostare engine= esplicitamente in mycustos.conf
pf.engine_selected=motore: auto seleziona %s per questo server
pf.cmd_found=comando %s: %s
pf.cmd_missing=comando %s: non trovato nel PATH
pf.needed_for=serve per %s
pf.config_missing=file di configurazione non trovato: %s
pf.hint_copy_example=partire dall'esempio:
pf.hint_setup=oppure crearlo rispondendo a qualche domanda:
pf.hint_cnf_create=crearlo dal modello, poi impostarvi utente e password:
pf.hint_switch_compress=oppure passare a %s, che è installato:
pf.target_ok=istanza: %s, porta %s, socket %s, datadir %s
pf.topology_single=topologia: istanza singola
pf.topology_primary=topologia: Group Replication, questo nodo è il PRIMARY
pf.multi_instance=%s processi server MySQL su questo host, e l'identità attesa non è impostata del tutto
pf.hint_expect=legarla all'istanza appena raggiunta:

# --- target identity ---------------------------------------------------------------
tgt.version_failed=impossibile leggere versione ed edizione del server
tgt.metadata_failed=impossibile leggere i metadati dell'istanza (hostname, port, socket, datadir, %s)
tgt.metadata_missing=metadati dell'istanza incompleti: %s è vuoto
tgt.metadata_invalid=valore di %s non valido restituito dal server: %s
tgt.mismatch=%s: atteso %s, il server riporta %s
tgt.uuid_on_mariadb=expect_server_uuid è impostato, ma il server è MariaDB, che non ha server_uuid: usare expect_server_id
tgt.id_on_mysql=expect_server_id è impostato, ma il server è MySQL: usare expect_server_uuid

# --- topology ------------------------------------------------------------------
topo.plugin_unreadable=impossibile leggere lo stato del plugin Group Replication (information_schema.PLUGINS): la topologia è sconosciuta
topo.members_unreadable=Group Replication è installato, ma performance_schema.replication_group_members non è leggibile
topo.no_members=Group Replication è installato, ma nessun membro del gruppo è visibile
topo.member_invalid=membro del gruppo incoerente: %s
topo.member_duplicate=il membro %s compare più di una volta nel gruppo
topo.local_missing=questo nodo (%s) non è tra i membri del gruppo
topo.local_not_online=questo nodo è %s nel gruppo, non ONLINE
topo.primary_count=%s PRIMARY online nel gruppo, ne è atteso esattamente 1
topo.secondary=questo nodo è un SECONDARY del gruppo: nessun backup qui. Il PRIMARY è %s (IP %s), porta %s
topo.wsrep_unreadable=impossibile leggere @@wsrep_on: lo stato Galera è sconosciuto
topo.wsrep_on=wsrep_on=ON: cluster Galera, non supportato (la regola "solo PRIMARY" non si applica a un cluster multi-primary)
topo.wsrep_ambiguous=valore inatteso di @@wsrep_on: %s

# --- inspect ---------------------------------------------------------------------
insp.mysql_missing=client mysql non trovato nel PATH
