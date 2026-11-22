# name: Deutsch
# status: needs native review
#
# Meldungskatalog von mycustos — Deutsch.
# Gleiche Schlüssel und gleiche Platzhalter (%s, %d, in derselben Reihenfolge) wie en.msg.
# Namen von Schlüsseln, Optionen und Befehlen bleiben englisch. Siehe CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=Warnung: %s
core.cannot_load=%s kann nicht geladen werden
core.cannot_create=%s kann nicht angelegt werden
core.tmpdir=temporäres Verzeichnis kann nicht angelegt werden
log.cannot_write=Logdatei kann nicht geschrieben werden: %s
i18n.unknown_language=Sprache '%s' ist nicht verfügbar, Englisch wird verwendet (verfügbar: %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Hilfe zur Verwendung: 'mycustos help'.
cli.option_needs_value=Option %s erfordert einen Wert
cli.unknown_option=unbekannte Option: %s
cli.unknown_command=unbekannter Befehl: %s
cli.home_not_dir=--home: kein Verzeichnis: %s
cli.not_implemented=%s ist in mycustos %s noch nicht implementiert
cli.cmd_unknown_option=%s: unbekannte Option: %s
cli.cmd_unknown_argument=%s: unbekanntes Argument: %s
cli.missing_subcommand=%s: Unterbefehl fehlt (%s)
cli.unknown_subcommand=%s: unbekannter Unterbefehl: %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - standardisierte Ausführung von MySQL-Backups
help.usage=Verwendung: mycustos <Befehl> [Optionen]
help.commands=Befehle:
help.global_options=Globale Optionen:
help.flag_not_implemented=(noch nicht implementiert)
help.not_implemented=In mycustos %s noch nicht implementiert.
help.languages=Sprachen: %s (aktuell: %s)
help.installation=Installation: %s
help.cmd.backup=Führt ein FULL- oder INCR-Backup aus (--type full|incr, --dry-run)
help.cmd.preflight=Prüft die Voraussetzungen und schlägt Konfigurationsänderungen vor (nur lesend)
help.cmd.inspect=Zeigt, welche Instanz erreicht wird und was ein Backup dort tun würde (nur lesend)
help.cmd.check_config=Prüft mycustos.conf und meldet alle Probleme (nur lesend)
help.cmd.status=Zeigt das Ergebnis des letzten Laufs
help.cmd.config=Zeigt die wirksame Konfiguration oder importiert eine vorhandene Datei
help.cmd.version=Zeigt Version und Urheberschaft
help.cmd.help=Zeigt diese Hilfe oder die Hilfe eines Befehls
help.opt.config=Konfigurationsdatei (Standard: <home>/config/mycustos.conf)
help.opt.home=Basis von config/, data/ und logs/ (Standard: die Installation)
help.opt.lang=Sprache der Meldungen (Standard: language= oder das System-Locale)
help.opt.quiet=Nur Warnungen und Fehler anzeigen
help.opt.verbose=Auch Debug-Meldungen anzeigen
help.opt.help=Wie "mycustos help"
help.opt.version=Wie "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=Konfigurationsdatei nicht gefunden oder nicht lesbar
cfg.unsafe_symlink=muss eine reguläre Datei sein, kein symbolischer Link: gib mit --config die echte Datei an oder ersetze den Link durch eine Kopie
cfg.unsafe_owner=gehört der UID %s: muss dem Benutzer gehören, der mycustos ausführt, oder root (ausführen: %s)
cfg.unsafe_perms=für Gruppe oder andere beschreibbar (ausführen: %s)
cfg.expected_kv=Schlüssel=Wert erwartet
cfg.unknown_key=unbekannter Schlüssel: %s
cfg.duplicate_key=doppelter Schlüssel: %s (bereits in Zeile %s gesetzt)
cfg.expansion_not_allowed=%s ist hier nicht erlaubt
cfg.only_expansions=nur ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} und ${MYCUSTOS_LOGS} können expandiert werden
cfg.schema_missing=fehlt: config_schema=%s hinzufügen
cfg.schema_unsupported=nicht unterstützter Wert '%s' (diese Version liest config_schema=%s)
cfg.int_range=muss eine ganze Zahl zwischen %s und %s sein (gefunden '%s')
cfg.enum=muss einer der folgenden Werte sein: %s (gefunden '%s')
cfg.name=muss mit einem Buchstaben oder einer Ziffer beginnen und darf nur Buchstaben, Ziffern, '.', '_' und '-' enthalten (gefunden '%s')
cfg.dblist=muss ALL oder eine kommagetrennte Liste von Datenbanken ohne Leerzeichen sein (gefunden '%s')
cfg.path=muss ein absoluter Pfad außer / sein (gefunden '%s')
cfg.language=muss ein Sprachcode wie en, it oder pt_BR sein (gefunden '%s')
cfg.uuid=muss eine UUID wie 3e11fa47-71ca-11e1-9e33-c80aa9429562 sein (gefunden '%s')
cfg.gzip_level=muss mit compress=gzip zwischen 1 und 9 liegen (gefunden '%s')
cfg.incr_engine=incr wird nur mit engine=mysqlbackup unterstützt (gefunden engine=%s)
cfg.login_path_required=erforderlich mit auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=unterstütztes config_schema: %s (mycustos %s)
cc.result_valid=Ergebnis: gültig, %d Warnung(en)
cc.result_invalid=Ergebnis: ungültig, %d Fehler
cc.warn_incr_auto=backup_type=incr mit engine=auto funktioniert nur, wenn die Server-Edition mysqlbackup auswählt (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path wird mit auth_method=cnf ignoriert
cc.warn_cnf_ignored=auth_cnf wird mit auth_method=login-path ignoriert
cc.warn_same_dirs=logs_dir ist dasselbe Verzeichnis wie data_dir
cc.warn_language_missing=Sprache '%s' ist nicht verfügbar, Englisch wird verwendet (verfügbar: %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto: %s nicht gefunden und auth_login_path ist leer
auth.invalid_method=auth_method: ungültiger Wert: %s
auth.cnf_not_found=Datei nicht gefunden: %s
auth.cnf_not_readable=keine lesbare Datei: %s
auth.cnf_no_client=kein Abschnitt [client] in %s
auth.cnf_perms=Berechtigungen weiter als 0600 auf %s (ausführen: %s)
auth.desc_cnf=Optionsdatei %s
auth.desc_lp=Login-Path %s
auth.lp_file=Login-Datei nicht gefunden oder nicht lesbar: %s
auth.lp_undefined=Login-Path '%s' ist in %s nicht definiert
auth.lp_unverified=mysql_config_editor nicht gefunden, '%s' nicht geprüft

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - Instanz %s
pf.configuration=Konfiguration: %s
pf.result=Ergebnis: %d OK, %d Warnung(en), %d Fehler
pf.conn_skipped=Verbindungstest übersprungen: Authentifizierung oder mysql-Client nicht verfügbar
pf.engine_auto_later=Engine: auto, wird beim Backup anhand der Server-Edition gewählt
pf.engine_auto_hint=("mycustos preflight --test-connection" ausführen, um zu sehen, welche)
pf.auth_ok=Authentifizierung: %s
pf.dir_missing=Verzeichnis nicht gefunden: %s
pf.hint_mkdir=anlegen: %s
pf.dir_not_writable=für %s nicht beschreibbar: %s
pf.config_dir_ok=Konfigurationsverzeichnis beschreibbar: %s
pf.config_dir_not_writable=Konfigurationsverzeichnis für %s nicht beschreibbar: %s
pf.config_dir_hint=es enthält den Lock und den Zustand der INCR-Kette
pf.free_space=%d GiB verfügbar
pf.free_space_unknown=freier Speicherplatz von %s kann nicht gelesen werden
pf.need_tar=Paketierung
pf.need_flock=Lock gegen parallele Läufe (Paket util-linux)
pf.need_mysql=MySQL-Client, zum Erkennen des Servers und zum Testen der Verbindung
pf.need_bparchive=archive_backend=netbackup (NetBackup-Client)
pf.tmp_login=temporäre Login-Datei kann nicht angelegt werden
pf.cannot_connect=keine Verbindung zum MySQL-Server mit %s
pf.cannot_connect_hint=Zugangsdaten und mysql_socket prüfen
pf.connection_ok=Verbindung: MySQL-Server %s (%s)
pf.unknown_edition=unbekannte Edition
pf.edition_unknown=engine=auto: Server-Edition nicht erkannt: %s
pf.empty=leer
pf.set_engine_hint=engine= in mycustos.conf explizit setzen
pf.engine_selected=Engine: auto wählt %s für diesen Server
pf.cmd_found=Befehl %s: %s
pf.cmd_missing=Befehl %s: nicht im PATH gefunden
pf.needed_for=benötigt für %s
pf.config_missing=Konfigurationsdatei nicht gefunden: %s
pf.hint_copy_example=vom Beispiel ausgehen:
pf.hint_setup=oder sie durch Beantworten einiger Fragen erstellen:
pf.hint_cnf_create=aus der Vorlage erstellen, dann Benutzer und Passwort darin setzen:
pf.hint_switch_compress=oder zu %s wechseln, das installiert ist:
pf.target_ok=Instanz: %s, Port %s, Socket %s, datadir %s
pf.topology_single=Topologie: einzelne Instanz
pf.topology_primary=Topologie: Group Replication, dieser Knoten ist der PRIMARY
pf.multi_instance=%s MySQL-Serverprozesse auf diesem Host, und die erwartete Identität ist nicht vollständig gesetzt
pf.hint_expect=sie an die gerade erreichte Instanz binden:

# --- target identity ---------------------------------------------------------------
tgt.version_failed=Version und Edition des Servers können nicht gelesen werden
tgt.metadata_failed=Metadaten der Instanz können nicht gelesen werden (hostname, port, socket, datadir, %s)
tgt.metadata_missing=unvollständige Metadaten der Instanz: %s ist leer
tgt.metadata_invalid=ungültiger Wert von %s vom Server gemeldet: %s
tgt.mismatch=%s: erwartet %s, der Server meldet %s
tgt.uuid_on_mariadb=expect_server_uuid ist gesetzt, aber der Server ist MariaDB und hat keine server_uuid: expect_server_id verwenden
tgt.id_on_mysql=expect_server_id ist gesetzt, aber der Server ist MySQL: expect_server_uuid verwenden

# --- topology ------------------------------------------------------------------
topo.plugin_unreadable=der Status des Group-Replication-Plugins kann nicht gelesen werden (information_schema.PLUGINS): die Topologie ist unbekannt
topo.members_unreadable=Group Replication ist installiert, aber performance_schema.replication_group_members kann nicht gelesen werden
topo.no_members=Group Replication ist installiert, aber kein Mitglied der Gruppe ist sichtbar
topo.member_invalid=inkonsistentes Mitglied der Gruppe: %s
topo.member_duplicate=das Mitglied %s erscheint mehr als einmal in der Gruppe
topo.local_missing=dieser Knoten (%s) ist nicht unter den Mitgliedern der Gruppe
topo.local_not_online=dieser Knoten ist in der Gruppe %s, nicht ONLINE
topo.primary_count=%s PRIMARY online in der Gruppe, genau 1 erwartet
topo.secondary=dieser Knoten ist ein SECONDARY der Gruppe: hier kein Backup. Der PRIMARY ist %s (IP %s), Port %s
topo.wsrep_unreadable=@@wsrep_on kann nicht gelesen werden: der Galera-Status ist unbekannt
topo.wsrep_on=wsrep_on=ON: Galera-Cluster, nicht unterstützt (die Regel "nur PRIMARY" gilt nicht für einen Multi-Primary-Cluster)
topo.wsrep_ambiguous=unerwarteter Wert von @@wsrep_on: %s

# --- inspect ---------------------------------------------------------------------
insp.mysql_missing=mysql-Client nicht im PATH gefunden
