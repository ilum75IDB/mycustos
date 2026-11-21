# name: Română
# status: needs native review
#
# Catalogul de mesaje mycustos — română.
# Aceleași chei și aceiași substituenți (%s, %d, în aceeași ordine) ca en.msg.
# Numele cheilor, opțiunilor și comenzilor rămân în engleză. Vezi CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=avertisment: %s
core.cannot_load=nu se poate încărca %s
core.cannot_create=nu se poate crea %s
core.tmpdir=nu se poate crea un director temporar
log.cannot_write=nu se poate scrie fișierul de log: %s
i18n.unknown_language=limba '%s' nu este disponibilă, se folosește engleza (disponibile: %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Rulați 'mycustos help' pentru utilizare.
cli.option_needs_value=opțiunea %s necesită o valoare
cli.unknown_option=opțiune necunoscută: %s
cli.unknown_command=comandă necunoscută: %s
cli.home_not_dir=--home: nu este un director: %s
cli.not_implemented=%s nu este încă implementat în mycustos %s
cli.cmd_unknown_option=%s: opțiune necunoscută: %s
cli.cmd_unknown_argument=%s: argument necunoscut: %s
cli.missing_subcommand=%s: lipsește subcomanda (%s)
cli.unknown_subcommand=%s: subcomandă necunoscută: %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - execuție standardizată a backup-urilor MySQL
help.usage=Utilizare: mycustos <comandă> [opțiuni]
help.commands=Comenzi:
help.global_options=Opțiuni globale:
help.flag_not_implemented=(încă neimplementat)
help.not_implemented=Încă neimplementat în mycustos %s.
help.languages=Limbi: %s (curentă: %s)
help.installation=Instalare: %s
help.cmd.backup=Rulează un backup FULL sau INCR (--type full|incr, --dry-run)
help.cmd.preflight=Verifică cerințele și sugerează modificări ale configurației (doar citire)
help.cmd.check_config=Validează mycustos.conf și raportează toate problemele (doar citire)
help.cmd.status=Afișează rezultatul ultimei rulări
help.cmd.config=Afișează configurația efectivă sau migrează un fișier vechi
help.cmd.version=Afișează versiunea și atribuirea
help.cmd.help=Afișează acest ajutor sau ajutorul unei comenzi
help.opt.config=Fișier de configurare (implicit: <home>/config/mycustos.conf)
help.opt.home=Baza pentru config/, data/ și logs/ (implicit: instalarea)
help.opt.lang=Limba mesajelor (implicit: language= sau locale-ul sistemului)
help.opt.quiet=Afișează doar avertismentele și erorile
help.opt.verbose=Afișează și mesajele de depanare
help.opt.help=La fel ca "mycustos help"
help.opt.version=La fel ca "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=fișierul de configurare nu a fost găsit sau nu poate fi citit
cfg.expected_kv=se aștepta cheie=valoare
cfg.unknown_key=cheie necunoscută: %s
cfg.duplicate_key=cheie duplicată: %s (deja setată la linia %s)
cfg.expansion_not_allowed=%s nu este permis aici
cfg.only_expansions=se pot expanda doar ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} și ${MYCUSTOS_LOGS}
cfg.schema_missing=lipsește: adăugați config_schema=%s
cfg.schema_unsupported=valoare nesuportată '%s' (această versiune citește config_schema=%s)
cfg.int_range=trebuie să fie un număr întreg între %s și %s (găsit '%s')
cfg.enum=trebuie să fie una dintre: %s (găsit '%s')
cfg.name=trebuie să înceapă cu o literă sau o cifră și să conțină doar litere, cifre, '.', '_' și '-' (găsit '%s')
cfg.dblist=trebuie să fie ALL sau o listă de baze de date separate prin virgulă, fără spații (găsit '%s')
cfg.path=trebuie să fie o cale absolută diferită de / (găsit '%s')
cfg.language=trebuie să fie un cod de limbă precum en, it sau pt_BR (găsit '%s')
cfg.uuid=trebuie să fie un UUID precum 3e11fa47-71ca-11e1-9e33-c80aa9429562 (găsit '%s')
cfg.gzip_level=trebuie să fie între 1 și 9 cu compress=gzip (găsit '%s')
cfg.incr_engine=incr este suportat doar cu engine=mysqlbackup (găsit engine=%s)
cfg.login_path_required=obligatoriu cu auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=config_schema suportat: %s (mycustos %s)
cc.result_valid=Rezultat: validă, %d avertisment(e)
cc.result_invalid=Rezultat: invalidă, %d eroare(i)
cc.warn_incr_auto=backup_type=incr cu engine=auto funcționează doar dacă ediția serverului selectează mysqlbackup (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path este ignorat cu auth_method=cnf
cc.warn_cnf_ignored=auth_cnf este ignorat cu auth_method=login-path
cc.warn_same_dirs=logs_dir este același director ca data_dir
cc.warn_language_missing=limba '%s' nu este disponibilă, se folosește engleza (disponibile: %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto: %s nu a fost găsit și auth_login_path este gol
auth.invalid_method=auth_method: valoare invalidă: %s
auth.cnf_not_found=fișier negăsit: %s
auth.cnf_not_readable=nu este un fișier care poate fi citit: %s
auth.cnf_no_client=nicio secțiune [client] în %s
auth.cnf_perms=permisiuni mai largi decât 0600 pe %s (rulați: %s)
auth.desc_cnf=fișier de opțiuni %s
auth.desc_lp=login path %s
auth.lp_file=fișierul de login nu a fost găsit sau nu poate fi citit: %s
auth.lp_undefined=login path '%s' nu este definit în %s
auth.lp_unverified=mysql_config_editor nu a fost găsit, '%s' neverificat

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - instanța %s
pf.configuration=configurare: %s
pf.result=Rezultat: %d OK, %d avertisment(e), %d eșec(uri)
pf.conn_skipped=testul de conexiune a fost omis: autentificarea sau clientul mysql nu sunt disponibile
pf.engine_auto_later=motor: auto, ales la momentul backup-ului în funcție de ediția serverului
pf.engine_auto_hint=(rulați "mycustos preflight --test-connection" pentru a vedea care)
pf.auth_ok=autentificare: %s
pf.dir_missing=director negăsit: %s
pf.hint_mkdir=creați-l: %s
pf.dir_not_writable=%s nu poate scrie în: %s
pf.config_dir_ok=directorul de configurare poate fi scris: %s
pf.config_dir_not_writable=%s nu poate scrie în directorul de configurare: %s
pf.config_dir_hint=conține lock-ul și starea lanțului INCR
pf.free_space=%d GiB disponibili
pf.free_space_unknown=nu se poate citi spațiul liber din %s
pf.need_tar=împachetare
pf.need_flock=lock de rulare unică (pachetul util-linux)
pf.need_mysql=client MySQL, folosit pentru a recunoaște serverul și a testa conexiunea
pf.need_bparchive=archive_backend=netbackup (client NetBackup)
pf.tmp_login=nu se poate crea fișierul de login temporar
pf.cannot_connect=nu se poate conecta la serverul MySQL cu %s
pf.cannot_connect_hint=verificați datele de autentificare și mysql_socket
pf.connection_ok=conexiune: server MySQL %s (%s)
pf.unknown_edition=ediție necunoscută
pf.edition_unknown=engine=auto: ediția serverului nu a fost recunoscută: %s
pf.empty=goală
pf.set_engine_hint=setați explicit engine= în mycustos.conf
pf.engine_selected=motor: auto selectează %s pentru acest server
pf.cmd_found=comanda %s: %s
pf.cmd_missing=comanda %s: nu a fost găsită în PATH
pf.needed_for=necesară pentru %s

# --- target identity ---------------------------------------------------------------
tgt.version_failed=nu se pot citi versiunea și ediția serverului
tgt.metadata_failed=nu se pot citi metadatele instanței (hostname, port, socket, datadir, %s)
tgt.metadata_missing=metadate incomplete ale instanței: %s este gol
tgt.metadata_invalid=valoare invalidă pentru %s raportată de server: %s
tgt.mismatch=%s: se aștepta %s, serverul raportează %s
tgt.uuid_on_mariadb=expect_server_uuid este setat, dar serverul este MariaDB, care nu are server_uuid: folosiți expect_server_id
tgt.id_on_mysql=expect_server_id este setat, dar serverul este MySQL: folosiți expect_server_uuid
