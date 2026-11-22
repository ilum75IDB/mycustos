#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# core/topology.sh: one test per row of the rules (issue #7), with the mysql
# mock answering each query from a responses file. No database.

load test_helper

setup() {
  mc_test_load_core
  export HOME="$BATS_TEST_TMPDIR/home" TMPDIR="$BATS_TEST_TMPDIR/tmp"
  mkdir -p "$HOME" "$TMPDIR"
  PATH="$REPO/tests/mocks/bin:$PATH"
  export MC_MOCK_MYSQL_RESPONSES="$BATS_TEST_TMPDIR/responses"
  export MC_MOCK_LOG="$BATS_TEST_TMPDIR/mock.log"
  : > "$MC_MOCK_MYSQL_RESPONSES"
  unset MC_MOCK_MYSQL_OUTPUT MC_MOCK_MYSQL_RC MYSQL_TEST_LOGIN_FILE
  CNF="$BASE/config/backup-credentials.conf"
  printf '[client]\nuser=backup_user\npassword=S3cr3t-value\n' > "$CNF"
  chmod 600 "$CNF"
}

ME=3e11fa47-71ca-11e1-9e33-c80aa9429562
P2=4f22ab58-82db-22f2-af44-d91bb9530673
P3=5a33bc69-93ec-33a3-b055-ea2cca641784
Q_VERSION='SELECT @@version, @@version_comment'
Q_MYSQL='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_uuid'
Q_MARIA='SELECT @@hostname, @@port, @@socket, @@datadir, @@server_id'
Q_PLUGIN="SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME = 'group_replication'"
Q_MEMBERS='SELECT MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members'
Q_WSREP='SELECT @@wsrep_on'

answer() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$MC_MOCK_MYSQL_RESPONSES"
}

mysql_server() {
  answer "$Q_VERSION" 0 '8.0.36\tMySQL Community Server - GPL'
  answer "$Q_MYSQL" 0 "db-a\\t3306\\t/run/mysqld/a.sock\\t/data/a/\\t$ME"
}

mariadb_server() {
  answer "$Q_VERSION" 0 '10.11.6-MariaDB\tmariadb.org binary distribution'
  answer "$Q_MARIA" 0 'db-m\t3307\t/run/mysqld/m.sock\t/data/m/\t42'
}

# member ID HOST STATE ROLE: one row of replication_group_members, as \t and \n escapes.
member() {
  printf '%s\\t%s\\t3306\\t%s\\t%s\\n' "$1" "$2" "$3" "$4"
}

# group ROWS...: the plugin is active and the members are the given rows.
group() {
  local rows
  rows=$(printf '%s' "$@")
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 0 "${rows%\\n}"
}

check() {
  mc_test_conf config_schema=1 auth_method=cnf
  mc_config_load || { mc_test_errors; return 99; }
  mc_auth_select || return 98
  mc_target_check || return 97
  mc_topology_check
}

messages() {
  printf '%s\n' "${MC_TOPOLOGY_MESSAGES[@]}"
}

@test "MySQL without Group Replication: allowed, SINGLE_INSTANCE" {
  mysql_server
  answer "$Q_PLUGIN" 0 ''
  check
  [ "$MC_TOPOLOGY_STATUS" = allowed ]
  [ "$MC_TOPOLOGY_TYPE" = SINGLE_INSTANCE ]
  [ -z "$MC_TOPOLOGY_ROLE" ]
  ! grep -q 'replication_group_members' "$MC_MOCK_LOG"
}

@test "GR, local node PRIMARY ONLINE: allowed" {
  mysql_server
  group "$(member "$ME" db-a ONLINE PRIMARY)" "$(member "$P2" db-b ONLINE SECONDARY)" \
        "$(member "$P3" db-c ONLINE SECONDARY)"
  check
  [ "$MC_TOPOLOGY_STATUS" = allowed ]
  [ "$MC_TOPOLOGY_TYPE" = GROUP_REPLICATION ]
  [ "$MC_TOPOLOGY_ROLE" = PRIMARY ]
  [ "$MC_TOPOLOGY_MEMBERS" -eq 3 ]
  [ "$MC_TOPOLOGY_PRIMARY_HOST" = db-a ]
}

@test "GR, local node SECONDARY ONLINE: skip, with host, IP and port of the PRIMARY" {
  mysql_server
  group "$(member "$P2" 192.0.2.10 ONLINE PRIMARY)" "$(member "$ME" db-a ONLINE SECONDARY)"
  run check
  [ "$status" -eq 1 ]
  check || true
  [ "$MC_TOPOLOGY_STATUS" = skip ]
  [ "$MC_TOPOLOGY_ROLE" = SECONDARY ]
  [ "$MC_TOPOLOGY_PRIMARY_HOST" = 192.0.2.10 ]
  [ "$MC_TOPOLOGY_PRIMARY_IP" = 192.0.2.10 ]
  [ "$MC_TOPOLOGY_PRIMARY_PORT" = 3306 ]
  [[ "$(messages)" == *'The PRIMARY is 192.0.2.10 (IP 192.0.2.10), port 3306' ]]
}

@test "GR, the member id is compared without case" {
  mysql_server
  group "$(member "${ME^^}" db-a ONLINE PRIMARY)"
  check
  [ "$MC_TOPOLOGY_STATUS" = allowed ]
}

@test "GR plugin present but no member visible: blocked" {
  mysql_server
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 0 ''
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'no member of the group is visible' ]]
}

@test "replication_group_members not readable: blocked, not SINGLE" {
  mysql_server
  answer "$Q_PLUGIN" 0 ACTIVE
  answer "$Q_MEMBERS" 1 ''
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [ "$MC_TOPOLOGY_TYPE" = GROUP_REPLICATION ]
  [[ "$(messages)" == *'replication_group_members cannot be read' ]]
}

@test "plugin status not readable: blocked, not SINGLE" {
  mysql_server
  answer "$Q_PLUGIN" 1 ''
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [ "$MC_TOPOLOGY_TYPE" = UNKNOWN ]
}

@test "inconsistent member (ONLINE without a role): blocked" {
  mysql_server
  group "$(member "$ME" db-a ONLINE PRIMARY)" "$(member "$P2" db-b ONLINE '')"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *"inconsistent member of the group: $P2 db-b 3306 ONLINE"* ]]
}

@test "member without id: blocked" {
  mysql_server
  group "$(member "$ME" db-a ONLINE PRIMARY)" "$(member NULL db-b ONLINE SECONDARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'inconsistent member'* ]]
}

@test "duplicate member: blocked" {
  mysql_server
  group "$(member "$ME" db-a ONLINE PRIMARY)" "$(member "$P2" db-b ONLINE SECONDARY)" \
        "$(member "$P2" db-b ONLINE SECONDARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *"member $P2 appears more than once"* ]]
}

@test "no online PRIMARY: blocked" {
  mysql_server
  group "$(member "$ME" db-a ONLINE SECONDARY)" "$(member "$P2" db-b UNREACHABLE PRIMARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'0 online PRIMARY in the group, exactly 1 expected' ]]
}

@test "two online PRIMARY (multi-primary): blocked" {
  mysql_server
  group "$(member "$ME" db-a ONLINE PRIMARY)" "$(member "$P2" db-b ONLINE PRIMARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'2 online PRIMARY'* ]]
}

@test "local node not ONLINE: blocked" {
  mysql_server
  group "$(member "$ME" db-a RECOVERING SECONDARY)" "$(member "$P2" db-b ONLINE PRIMARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'this node is RECOVERING in the group, not ONLINE' ]]
}

@test "local node OFFLINE with an empty role: blocked, every reason kept" {
  mysql_server
  group "$(member "$ME" db-a OFFLINE '')"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [ ${#MC_TOPOLOGY_MESSAGES[@]} -eq 2 ]
  [[ "$(messages)" == *'this node is OFFLINE'* ]]
  [[ "$(messages)" == *'0 online PRIMARY'* ]]
}

@test "local node not among the members: blocked" {
  mysql_server
  group "$(member "$P2" db-b ONLINE PRIMARY)" "$(member "$P3" db-c ONLINE SECONDARY)"
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *"this node ($ME) is not among the members"* ]]
}

@test "MariaDB wsrep_on=OFF: standalone, allowed" {
  mariadb_server
  answer "$Q_WSREP" 0 0
  check
  [ "$MC_TOPOLOGY_STATUS" = allowed ]
  [ "$MC_TOPOLOGY_TYPE" = SINGLE_INSTANCE ]
  ! grep -q 'group_replication' "$MC_MOCK_LOG"
}

@test "MariaDB wsrep_on=ON (Galera): blocked" {
  mariadb_server
  answer "$Q_WSREP" 0 1
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [ "$MC_TOPOLOGY_TYPE" = GALERA ]
  [[ "$(messages)" == *'Galera cluster, not supported'* ]]
}

@test "MariaDB wsrep_on missing: blocked" {
  mariadb_server
  answer "$Q_WSREP" 1 ''
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'cannot read @@wsrep_on'* ]]
}

@test "MariaDB wsrep_on ambiguous: blocked" {
  mariadb_server
  answer "$Q_WSREP" 0 NULL
  check || true
  [ "$MC_TOPOLOGY_STATUS" = blocked ]
  [[ "$(messages)" == *'unexpected value of @@wsrep_on: NULL' ]]
}

@test "without a successful target check: internal error, return 2" {
  run mc_topology_check
  [ "$status" -eq 2 ]
  [[ "$output" == *'needs a successful mc_target_check'* ]]
}

@test "messages follow the language, the English copy stays for the log" {
  mysql_server
  group "$(member "$P2" 192.0.2.10 ONLINE PRIMARY)" "$(member "$ME" db-a ONLINE SECONDARY)"
  mc_i18n_select it
  check || true
  [[ "$(messages)" == 'questo nodo è un SECONDARY del gruppo'* ]]
  [[ "${MC_TOPOLOGY_MESSAGES_EN[0]}" == 'this node is a SECONDARY of the group'* ]]
}

@test "the credentials never reach the command line" {
  mysql_server
  answer "$Q_PLUGIN" 0 ''
  check
  grep -q -- "--defaults-file=$CNF" "$MC_MOCK_LOG"
  ! grep -q 'S3cr3t-value' "$MC_MOCK_LOG"
}
