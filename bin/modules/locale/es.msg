# name: Español
# status: needs native review
#
# Catálogo de mensajes de mycustos — español.
# Mismas claves y mismos marcadores (%s, %d, en el mismo orden) que en.msg.
# Los nombres de claves, opciones y comandos quedan en inglés. Ver CONTRIBUTING.md.

# --- core ---------------------------------------------------------------------
core.warning=aviso: %s
core.cannot_load=no se puede cargar %s
core.cannot_create=no se puede crear %s
core.tmpdir=no se puede crear un directorio temporal
log.cannot_write=no se puede escribir el archivo de log: %s
i18n.unknown_language=el idioma '%s' no está disponible, se usa el inglés (disponibles: %s)

# --- command line ---------------------------------------------------------------
cli.run_help=Ejecute 'mycustos help' para ver el uso.
cli.option_needs_value=la opción %s requiere un valor
cli.unknown_option=opción desconocida: %s
cli.unknown_command=comando desconocido: %s
cli.home_not_dir=--home: no es un directorio: %s
cli.not_implemented=%s aún no está implementado en mycustos %s
cli.cmd_unknown_option=%s: opción desconocida: %s
cli.cmd_unknown_argument=%s: argumento desconocido: %s
cli.missing_subcommand=%s: falta el subcomando (%s)
cli.unknown_subcommand=%s: subcomando desconocido: %s

# --- help -----------------------------------------------------------------------
help.title=mycustos %s - ejecución estandarizada de backups de MySQL
help.usage=Uso: mycustos <comando> [opciones]
help.commands=Comandos:
help.global_options=Opciones globales:
help.flag_not_implemented=(aún no implementado)
help.not_implemented=Aún no implementado en mycustos %s.
help.languages=Idiomas: %s (actual: %s)
help.installation=Instalación: %s
help.cmd.backup=Ejecuta un backup FULL o INCR (--type full|incr, --dry-run)
help.cmd.preflight=Comprueba los requisitos y sugiere cambios en la configuración (solo lectura)
help.cmd.inspect=Muestra qué instancia se alcanza y qué haría allí un backup (solo lectura)
help.cmd.check_config=Valida mycustos.conf e informa de todos los problemas (solo lectura)
help.cmd.status=Muestra el resultado de la última ejecución
help.cmd.config=Muestra la configuración efectiva o importa un archivo existente
help.cmd.version=Muestra la versión y la atribución
help.cmd.help=Muestra esta ayuda, o la ayuda de un comando
help.opt.config=Archivo de configuración (por defecto: <home>/config/mycustos.conf)
help.opt.home=Base de config/, data/ y logs/ (por defecto: la instalación)
help.opt.lang=Idioma de los mensajes (por defecto: language= o el locale del sistema)
help.opt.quiet=Muestra solo avisos y errores
help.opt.verbose=Muestra también los mensajes de depuración
help.opt.help=Igual que "mycustos help"
help.opt.version=Igual que "mycustos version"

# --- configuration ----------------------------------------------------------------
cfg.not_found=archivo de configuración no encontrado o no legible
cfg.expected_kv=se esperaba clave=valor
cfg.unknown_key=clave desconocida: %s
cfg.duplicate_key=clave duplicada: %s (ya definida en la línea %s)
cfg.expansion_not_allowed=%s no está permitido aquí
cfg.only_expansions=solo se pueden expandir ${MYCUSTOS_HOME}, ${MYCUSTOS_CONFIG}, ${MYCUSTOS_DATA} y ${MYCUSTOS_LOGS}
cfg.schema_missing=falta: añada config_schema=%s
cfg.schema_unsupported=valor no soportado '%s' (esta versión lee config_schema=%s)
cfg.int_range=debe ser un entero entre %s y %s (encontrado '%s')
cfg.enum=debe ser uno de: %s (encontrado '%s')
cfg.name=debe empezar por una letra o un dígito y contener solo letras, dígitos, '.', '_' y '-' (encontrado '%s')
cfg.dblist=debe ser ALL o una lista de bases de datos separadas por comas, sin espacios (encontrado '%s')
cfg.path=debe ser una ruta absoluta distinta de / (encontrado '%s')
cfg.language=debe ser un código de idioma como en, it o pt_BR (encontrado '%s')
cfg.uuid=debe ser un UUID como 3e11fa47-71ca-11e1-9e33-c80aa9429562 (encontrado '%s')
cfg.gzip_level=debe estar entre 1 y 9 con compress=gzip (encontrado '%s')
cfg.incr_engine=incr solo se admite con engine=mysqlbackup (encontrado engine=%s)
cfg.login_path_required=obligatorio con auth_method=login-path

# --- check-config -------------------------------------------------------------------
cc.schema_supported=config_schema soportado: %s (mycustos %s)
cc.result_valid=Resultado: válida, %d aviso(s)
cc.result_invalid=Resultado: no válida, %d error(es)
cc.warn_incr_auto=backup_type=incr con engine=auto solo funciona si la edición del servidor selecciona mysqlbackup (MySQL Enterprise)
cc.warn_login_path_ignored=auth_login_path se ignora con auth_method=cnf
cc.warn_cnf_ignored=auth_cnf se ignora con auth_method=login-path
cc.warn_same_dirs=logs_dir es el mismo directorio que data_dir
cc.warn_language_missing=el idioma '%s' no está disponible, se usa el inglés (disponibles: %s)

# --- authentication -------------------------------------------------------------------
auth.auto_nothing=auth_method=auto: %s no encontrado y auth_login_path está vacío
auth.invalid_method=auth_method: valor no válido: %s
auth.cnf_not_found=archivo no encontrado: %s
auth.cnf_not_readable=no es un archivo legible: %s
auth.cnf_no_client=no hay sección [client] en %s
auth.cnf_perms=permisos más amplios que 0600 en %s (ejecute: %s)
auth.desc_cnf=archivo de opciones %s
auth.desc_lp=login path %s
auth.lp_file=archivo de login no encontrado o no legible: %s
auth.lp_undefined=login path '%s' no definido en %s
auth.lp_unverified=mysql_config_editor no encontrado, '%s' no verificado

# --- preflight -----------------------------------------------------------------------
pf.header=mycustos preflight - instancia %s
pf.configuration=configuración: %s
pf.result=Resultado: %d OK, %d aviso(s), %d fallo(s)
pf.conn_skipped=prueba de conexión omitida: autenticación o cliente mysql no disponibles
pf.engine_auto_later=motor: auto, elegido en el momento del backup según la edición del servidor
pf.engine_auto_hint=(ejecute "mycustos preflight --test-connection" para ver cuál)
pf.auth_ok=autenticación: %s
pf.dir_missing=directorio no encontrado: %s
pf.hint_mkdir=créelo: %s
pf.dir_not_writable=%s no puede escribir en: %s
pf.config_dir_ok=directorio de configuración con permiso de escritura: %s
pf.config_dir_not_writable=%s no puede escribir en el directorio de configuración: %s
pf.config_dir_hint=contiene el lock y el estado de la cadena INCR
pf.free_space=%d GiB disponibles
pf.free_space_unknown=no se puede leer el espacio libre de %s
pf.need_tar=empaquetado
pf.need_flock=lock de ejecución única (paquete util-linux)
pf.need_mysql=cliente MySQL, usado para reconocer el servidor y probar la conexión
pf.need_bparchive=archive_backend=netbackup (cliente NetBackup)
pf.tmp_login=no se puede crear el archivo de login temporal
pf.cannot_connect=no se puede conectar al servidor MySQL con %s
pf.cannot_connect_hint=compruebe las credenciales y mysql_socket
pf.connection_ok=conexión: servidor MySQL %s (%s)
pf.unknown_edition=edición desconocida
pf.edition_unknown=engine=auto: edición del servidor no reconocida: %s
pf.empty=vacía
pf.set_engine_hint=defina engine= explícitamente en mycustos.conf
pf.engine_selected=motor: auto selecciona %s para este servidor
pf.cmd_found=comando %s: %s
pf.cmd_missing=comando %s: no encontrado en el PATH
pf.needed_for=necesario para %s
pf.config_missing=archivo de configuración no encontrado: %s
pf.hint_copy_example=partir del ejemplo:
pf.hint_setup=o crearlo respondiendo a unas preguntas:
pf.hint_cnf_create=crearlo desde la plantilla y luego poner en él usuario y contraseña:
pf.hint_switch_compress=o cambiar a %s, que está instalado:
pf.target_ok=instancia: %s, puerto %s, socket %s, datadir %s
pf.topology_single=topología: instancia única
pf.topology_primary=topología: Group Replication, este nodo es el PRIMARY
pf.multi_instance=%s procesos de servidor MySQL en este host, y la identidad esperada no está completa
pf.hint_expect=fijarla a la instancia que se acaba de alcanzar:

# --- target identity ---------------------------------------------------------------
tgt.version_failed=no se pueden leer la versión y la edición del servidor
tgt.metadata_failed=no se pueden leer los metadatos de la instancia (hostname, port, socket, datadir, %s)
tgt.metadata_missing=metadatos de la instancia incompletos: %s está vacío
tgt.metadata_invalid=valor no válido de %s devuelto por el servidor: %s
tgt.mismatch=%s: se esperaba %s, el servidor indica %s
tgt.uuid_on_mariadb=expect_server_uuid está definido, pero el servidor es MariaDB, que no tiene server_uuid: use expect_server_id
tgt.id_on_mysql=expect_server_id está definido, pero el servidor es MySQL: use expect_server_uuid

# --- topology ------------------------------------------------------------------
topo.plugin_unreadable=no se puede leer el estado del plugin Group Replication (information_schema.PLUGINS): la topología es desconocida
topo.members_unreadable=Group Replication está instalado, pero performance_schema.replication_group_members no se puede leer
topo.no_members=Group Replication está instalado, pero no se ve ningún miembro del grupo
topo.member_invalid=miembro del grupo incoherente: %s
topo.member_duplicate=el miembro %s aparece más de una vez en el grupo
topo.local_missing=este nodo (%s) no está entre los miembros del grupo
topo.local_not_online=este nodo está %s en el grupo, no ONLINE
topo.primary_count=%s PRIMARY online en el grupo, se espera exactamente 1
topo.secondary=este nodo es un SECONDARY del grupo: aquí no se hace backup. El PRIMARY es %s (IP %s), puerto %s
topo.wsrep_unreadable=no se puede leer @@wsrep_on: el estado de Galera es desconocido
topo.wsrep_on=wsrep_on=ON: clúster Galera, no soportado (la regla "solo PRIMARY" no se aplica a un clúster multi-primary)
topo.wsrep_ambiguous=valor inesperado de @@wsrep_on: %s

# --- inspect ---------------------------------------------------------------------
insp.mysql_missing=cliente mysql no encontrado en el PATH
