# name: English
# status: reviewed
#
# mycustos message catalog — reference language.
# Format: key=printf format. The value is everything after the first "=",
# verbatim (leading spaces included). Placeholders: %s (text), %d (number).
# Another catalog must have the same keys and the same placeholders, in the
# same order (Bash printf has no positional arguments). See CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=warning: %s
core.cannot_load=cannot load %s
core.cannot_create=cannot create %s
core.tmpdir=cannot create a temporary directory
log.cannot_write=cannot write the log file: %s
i18n.unknown_language=language '%s' is not available, using English (available: %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Run 'mycustos help' for usage.
cli.option_needs_value=option %s requires a value
cli.unknown_option=unknown option: %s
cli.unknown_command=unknown command: %s
cli.home_not_dir=--home: not a directory: %s
cli.not_implemented=%s is not implemented yet in mycustos %s
cli.cmd_unknown_option=%s: unknown option: %s
cli.cmd_unknown_argument=%s: unknown argument: %s
cli.missing_subcommand=%s: missing sub-command (%s)
cli.unknown_subcommand=%s: unknown sub-command: %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - standardized MySQL backup runner
help.usage=Usage: mycustos <command> [options]
help.commands=Commands:
help.global_options=Global options:
help.flag_not_implemented=(not implemented yet)
help.not_implemented=Not implemented yet in mycustos %s.
help.languages=Languages: %s (current: %s)
help.installation=Installation: %s
help.cmd.backup=Run a FULL or INCR backup (--type full|incr, --dry-run)
help.cmd.preflight=Check prerequisites and suggest config changes (read-only)
help.cmd.check_config=Validate mycustos.conf, reporting every problem (read-only)
help.cmd.status=Show the outcome of the last run
help.cmd.config=Show the effective configuration or migrate a legacy file
help.cmd.version=Show version and attribution
help.cmd.help=Show this help, or the help of a command
help.opt.config=Configuration file (default: <home>/config/mycustos.conf)
help.opt.home=Base of config/, data/ and logs/ (default: the installation)
help.opt.lang=Language of the messages (default: language= or the system locale)
help.opt.quiet=Show only warnings and errors
help.opt.verbose=Show debug messages too
help.opt.help=Same as "mycustos help"
help.opt.version=Same as "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=configuration file not found or not readable
cfg.expected_kv=expected key=value
cfg.unknown_key=unknown key: %s
cfg.duplicate_key=duplicate key: %s (already set at line %s)
cfg.expansion_not_allowed=%s is not allowed here
cfg.only_expansions=only ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} and ${MYCUSTOS_LOGS} can be expanded
cfg.schema_missing=missing: add config_schema=%s
cfg.schema_unsupported=unsupported value '%s' (this version reads config_schema=%s)
cfg.int_range=must be an integer between %s and %s (found '%s')
cfg.enum=must be one of: %s (found '%s')
cfg.name=must start with a letter or digit and contain only letters, digits, '.', '_' and '-' (found '%s')
cfg.dblist=must be ALL or a comma-separated list of database names, without spaces (found '%s')
cfg.path=must be an absolute path other than / (found '%s')
cfg.language=must be a language code such as en, it or pt_BR (found '%s')
cfg.uuid=must be a UUID such as 3e11fa47-71ca-11e1-9e33-c80aa9429562 (found '%s')
cfg.gzip_level=must be between 1 and 9 with compress=gzip (found '%s')
cfg.incr_engine=incr is supported only with engine=mysqlbackup (found engine=%s)
cfg.login_path_required=required with auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=config_schema supported: %s (mycustos %s)
cc.result_valid=Result: valid, %d warning(s)
cc.result_invalid=Result: invalid, %d error(s)
cc.warn_incr_auto=backup_type=incr with engine=auto works only when the server edition selects mysqlbackup (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path is ignored with auth_method=cnf
cc.warn_cnf_ignored=auth_cnf is ignored with auth_method=login-path
cc.warn_same_dirs=logs_dir is the same directory as data_dir
cc.warn_language_missing=language '%s' is not available, English is used (available: %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto: %s not found and auth_login_path is empty
auth.invalid_method=auth_method: invalid value: %s
auth.cnf_not_found=file not found: %s
auth.cnf_not_readable=not a readable file: %s
auth.cnf_no_client=no [client] section in %s
auth.cnf_perms=permissions wider than 0600 on %s (run: %s)
auth.desc_cnf=option file %s
auth.desc_lp=login path %s
auth.lp_file=login file not found or not readable: %s
auth.lp_undefined=login path '%s' not defined in %s
auth.lp_unverified=mysql_config_editor not found, '%s' not verified

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - instance %s
pf.configuration=configuration: %s
pf.result=Result: %d OK, %d warning(s), %d failure(s)
pf.conn_skipped=connection test skipped: authentication or mysql client not available
pf.engine_auto_later=engine: auto, chosen at backup time from the server edition
pf.engine_auto_hint=(run "mycustos preflight --test-connection" to see which one)
pf.auth_ok=authentication: %s
pf.dir_missing=directory not found: %s
pf.hint_mkdir=create it: %s
pf.dir_not_writable=not writable by %s: %s
pf.config_dir_ok=config directory writable: %s
pf.config_dir_not_writable=config directory not writable by %s: %s
pf.config_dir_hint=it holds the lock and the INCR chain state
pf.free_space=%d GiB available
pf.free_space_unknown=cannot read the free space of %s
pf.need_tar=packaging
pf.need_flock=single-run lock (package util-linux)
pf.need_mysql=MySQL client, used to detect the server and test the connection
pf.need_bparchive=archive_backend=netbackup (NetBackup client)
pf.tmp_login=cannot create the temporary login file
pf.cannot_connect=cannot connect to the MySQL server with the %s
pf.cannot_connect_hint=check the credentials and mysql_socket
pf.connection_ok=connection: MySQL server %s (%s)
pf.unknown_edition=unknown edition
pf.edition_unknown=engine=auto: server edition not recognised: %s
pf.empty=empty
pf.set_engine_hint=set engine= explicitly in mycustos.conf
pf.engine_selected=engine: auto selects %s for this server
pf.cmd_found=command %s: %s
pf.cmd_missing=command %s: not found in PATH
pf.needed_for=needed for %s

# --- target identity ---------------------------------------------------------------
tgt.version_failed=cannot read the server version and edition
tgt.metadata_failed=cannot read the instance metadata (hostname, port, socket, datadir, %s)
tgt.metadata_missing=incomplete instance metadata: %s is empty
tgt.metadata_invalid=invalid value of %s reported by the server: %s
tgt.mismatch=%s: expected %s, the server reports %s
tgt.uuid_on_mariadb=expect_server_uuid is set, but the server is MariaDB, which has no server_uuid: use expect_server_id
tgt.id_on_mysql=expect_server_id is set, but the server is MySQL: use expect_server_uuid

# --- topology ------------------------------------------------------------------
topo.plugin_unreadable=cannot read the Group Replication plugin status (information_schema.PLUGINS): the topology is unknown
topo.members_unreadable=Group Replication is installed, but performance_schema.replication_group_members cannot be read
topo.no_members=Group Replication is installed, but no member of the group is visible
topo.member_invalid=inconsistent member of the group: %s
topo.member_duplicate=member %s appears more than once in the group
topo.local_missing=this node (%s) is not among the members of the group
topo.local_not_online=this node is %s in the group, not ONLINE
topo.primary_count=%s online PRIMARY in the group, exactly 1 expected
topo.secondary=this node is a SECONDARY of the group: no backup here. The PRIMARY is %s (IP %s), port %s
topo.wsrep_unreadable=cannot read @@wsrep_on: the Galera state is unknown
topo.wsrep_on=wsrep_on=ON: Galera cluster, not supported (the PRIMARY-only rule does not apply to a multi-primary cluster)
topo.wsrep_ambiguous=unexpected value of @@wsrep_on: %s
