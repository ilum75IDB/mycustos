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
help.cmd.check_config=Valida mycustos.conf e segnala tutti i problemi (sola lettura)
help.cmd.status=Mostra l'esito dell'ultima esecuzione
help.cmd.config=Mostra la configurazione effettiva o migra un file legacy
help.cmd.version=Mostra versione e attribuzione
help.cmd.help=Mostra questo help, o l'help di un comando
help.opt.config=File di configurazione (default: <home>/config/mycustos.conf)
help.opt.home=Base di config/, data/ e logs/ (default: l'installazione)
help.opt.lang=Lingua dei messaggi (default: language= o il locale del sistema)
help.opt.quiet=Mostra solo avvisi ed errori
help.opt.verbose=Mostra anche i messaggi di debug
help.opt.help=Come "mycustos help"
help.opt.version=Come "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=file di configurazione non trovato o non leggibile
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
