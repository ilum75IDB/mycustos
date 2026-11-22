# name: Français
# status: needs native review
#
# Catalogue des messages de mycustos — français.
# Mêmes clés et mêmes espaces réservés (%s, %d, dans le même ordre) que en.msg.
# Les noms de clés, d'options et de commandes restent en anglais. Voir CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=avertissement : %s
core.cannot_load=impossible de charger %s
core.cannot_create=impossible de créer %s
core.tmpdir=impossible de créer un répertoire temporaire
log.cannot_write=impossible d'écrire le fichier de log : %s
i18n.unknown_language=la langue '%s' n'est pas disponible, utilisation de l'anglais (disponibles : %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Lancez 'mycustos help' pour l'utilisation.
cli.option_needs_value=l'option %s requiert une valeur
cli.unknown_option=option inconnue : %s
cli.unknown_command=commande inconnue : %s
cli.home_not_dir=--home : n'est pas un répertoire : %s
cli.not_implemented=%s n'est pas encore implémenté dans mycustos %s
cli.cmd_unknown_option=%s : option inconnue : %s
cli.cmd_unknown_argument=%s : argument inconnu : %s
cli.missing_subcommand=%s : sous-commande manquante (%s)
cli.unknown_subcommand=%s : sous-commande inconnue : %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - exécution standardisée des sauvegardes MySQL
help.usage=Utilisation : mycustos <commande> [options]
help.commands=Commandes :
help.global_options=Options globales :
help.flag_not_implemented=(pas encore implémenté)
help.not_implemented=Pas encore implémenté dans mycustos %s.
help.languages=Langues : %s (actuelle : %s)
help.installation=Installation : %s
help.cmd.backup=Lance une sauvegarde FULL ou INCR (--type full|incr, --dry-run)
help.cmd.preflight=Vérifie les prérequis et suggère des modifications de configuration (lecture seule)
help.cmd.check_config=Valide mycustos.conf et signale tous les problèmes (lecture seule)
help.cmd.status=Affiche le résultat de la dernière exécution
help.cmd.config=Affiche la configuration effective ou migre un ancien fichier
help.cmd.version=Affiche la version et l'attribution
help.cmd.help=Affiche cette aide, ou l'aide d'une commande
help.opt.config=Fichier de configuration (par défaut : <home>/config/mycustos.conf)
help.opt.home=Base de config/, data/ et logs/ (par défaut : l'installation)
help.opt.lang=Langue des messages (par défaut : language= ou la locale du système)
help.opt.quiet=N'affiche que les avertissements et les erreurs
help.opt.verbose=Affiche aussi les messages de débogage
help.opt.help=Identique à "mycustos help"
help.opt.version=Identique à "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=fichier de configuration introuvable ou illisible
cfg.expected_kv=clé=valeur attendu
cfg.unknown_key=clé inconnue : %s
cfg.duplicate_key=clé en double : %s (déjà définie à la ligne %s)
cfg.expansion_not_allowed=%s n'est pas autorisé ici
cfg.only_expansions=seuls ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} et ${MYCUSTOS_LOGS} peuvent être développés
cfg.schema_missing=absent : ajoutez config_schema=%s
cfg.schema_unsupported=valeur non prise en charge '%s' (cette version lit config_schema=%s)
cfg.int_range=doit être un entier entre %s et %s (trouvé '%s')
cfg.enum=doit être l'une des valeurs : %s (trouvé '%s')
cfg.name=doit commencer par une lettre ou un chiffre et ne contenir que des lettres, des chiffres, '.', '_' et '-' (trouvé '%s')
cfg.dblist=doit être ALL ou une liste de bases séparées par des virgules, sans espaces (trouvé '%s')
cfg.path=doit être un chemin absolu autre que / (trouvé '%s')
cfg.language=doit être un code de langue comme en, it ou pt_BR (trouvé '%s')
cfg.uuid=doit être un UUID comme 3e11fa47-71ca-11e1-9e33-c80aa9429562 (trouvé '%s')
cfg.gzip_level=doit être entre 1 et 9 avec compress=gzip (trouvé '%s')
cfg.incr_engine=incr n'est pris en charge qu'avec engine=mysqlbackup (trouvé engine=%s)
cfg.login_path_required=obligatoire avec auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=config_schema pris en charge : %s (mycustos %s)
cc.result_valid=Résultat : valide, %d avertissement(s)
cc.result_invalid=Résultat : invalide, %d erreur(s)
cc.warn_incr_auto=backup_type=incr avec engine=auto ne fonctionne que si l'édition du serveur sélectionne mysqlbackup (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path est ignoré avec auth_method=cnf
cc.warn_cnf_ignored=auth_cnf est ignoré avec auth_method=login-path
cc.warn_same_dirs=logs_dir est le même répertoire que data_dir
cc.warn_language_missing=la langue '%s' n'est pas disponible, l'anglais est utilisé (disponibles : %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto : %s introuvable et auth_login_path est vide
auth.invalid_method=auth_method : valeur invalide : %s
auth.cnf_not_found=fichier introuvable : %s
auth.cnf_not_readable=fichier illisible : %s
auth.cnf_no_client=aucune section [client] dans %s
auth.cnf_perms=permissions plus larges que 0600 sur %s (lancez : %s)
auth.desc_cnf=fichier d'options %s
auth.desc_lp=login path %s
auth.lp_file=fichier de login introuvable ou illisible : %s
auth.lp_undefined=login path '%s' non défini dans %s
auth.lp_unverified=mysql_config_editor introuvable, '%s' non vérifié

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - instance %s
pf.configuration=configuration : %s
pf.result=Résultat : %d OK, %d avertissement(s), %d échec(s)
pf.conn_skipped=test de connexion ignoré : authentification ou client mysql indisponible
pf.engine_auto_later=moteur : auto, choisi au moment de la sauvegarde selon l'édition du serveur
pf.engine_auto_hint=(lancez "mycustos preflight --test-connection" pour savoir lequel)
pf.auth_ok=authentification : %s
pf.dir_missing=répertoire introuvable : %s
pf.hint_mkdir=créez-le : %s
pf.dir_not_writable=non accessible en écriture pour %s : %s
pf.config_dir_ok=répertoire de configuration accessible en écriture : %s
pf.config_dir_not_writable=répertoire de configuration non accessible en écriture pour %s : %s
pf.config_dir_hint=il contient le verrou et l'état de la chaîne INCR
pf.free_space=%d Gio disponibles
pf.free_space_unknown=impossible de lire l'espace libre de %s
pf.need_tar=empaquetage
pf.need_flock=verrou d'exécution unique (paquet util-linux)
pf.need_mysql=client MySQL, utilisé pour reconnaître le serveur et tester la connexion
pf.need_bparchive=archive_backend=netbackup (client NetBackup)
pf.tmp_login=impossible de créer le fichier de login temporaire
pf.cannot_connect=impossible de se connecter au serveur MySQL avec %s
pf.cannot_connect_hint=vérifiez les identifiants et mysql_socket
pf.connection_ok=connexion : serveur MySQL %s (%s)
pf.unknown_edition=édition inconnue
pf.edition_unknown=engine=auto : édition du serveur non reconnue : %s
pf.empty=vide
pf.set_engine_hint=définissez engine= explicitement dans mycustos.conf
pf.engine_selected=moteur : auto sélectionne %s pour ce serveur
pf.cmd_found=commande %s : %s
pf.cmd_missing=commande %s : introuvable dans le PATH
pf.needed_for=nécessaire pour %s

# --- target identity ---------------------------------------------------------------
tgt.version_failed=impossible de lire la version et l'édition du serveur
tgt.metadata_failed=impossible de lire les métadonnées de l'instance (hostname, port, socket, datadir, %s)
tgt.metadata_missing=métadonnées de l'instance incomplètes : %s est vide
tgt.metadata_invalid=valeur de %s invalide renvoyée par le serveur : %s
tgt.mismatch=%s : attendu %s, le serveur indique %s
tgt.uuid_on_mariadb=expect_server_uuid est défini, mais le serveur est MariaDB, qui n'a pas de server_uuid : utilisez expect_server_id
tgt.id_on_mysql=expect_server_id est défini, mais le serveur est MySQL : utilisez expect_server_uuid

# --- topology ------------------------------------------------------------------
topo.plugin_unreadable=impossible de lire l'état du plugin Group Replication (information_schema.PLUGINS) : la topologie est inconnue
topo.members_unreadable=Group Replication est installé, mais performance_schema.replication_group_members est illisible
topo.no_members=Group Replication est installé, mais aucun membre du groupe n'est visible
topo.member_invalid=membre du groupe incohérent : %s
topo.member_duplicate=le membre %s apparaît plus d'une fois dans le groupe
topo.local_missing=ce nœud (%s) ne fait pas partie des membres du groupe
topo.local_not_online=ce nœud est %s dans le groupe, pas ONLINE
topo.primary_count=%s PRIMARY online dans le groupe, exactement 1 attendu
topo.secondary=ce nœud est un SECONDARY du groupe : pas de sauvegarde ici. Le PRIMARY est %s (IP %s), port %s
topo.wsrep_unreadable=impossible de lire @@wsrep_on : l'état de Galera est inconnu
topo.wsrep_on=wsrep_on=ON : cluster Galera, non pris en charge (la règle « PRIMARY uniquement » ne s'applique pas à un cluster multi-primary)
topo.wsrep_ambiguous=valeur inattendue de @@wsrep_on : %s
