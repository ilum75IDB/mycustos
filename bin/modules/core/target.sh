# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Identity of the MySQL instance: before a backup, make sure mycustos reaches
# the instance it is configured for. On a host with several instances a
# successful "SELECT 1" proves nothing.
# Sourced by bin/mycustos. Requires core/auth.sh with a selected method.
#
# mc_target_check reads, in two queries:
#   1. @@version, @@version_comment  -> MySQL or MariaDB (checked first:
#      MariaDB has no @@server_uuid, so it is never asked for it);
#   2. @@hostname, @@port, @@socket, @@datadir, then @@server_uuid (MySQL)
#      or @@server_id (MariaDB). A missing value rejects the target.
# Then compares them with the optional expectations of mycustos.conf:
#   mysql_socket, expect_hostname, expect_port, expect_datadir,
#   expect_server_uuid (MySQL only), expect_server_id (MariaDB only).
#
# Results:
#   MC_TARGET_STATUS   ok | rejected | config | unreachable
#                      (config: an expectation that cannot apply to this product)
#   MC_TARGET_ERRORS   the reasons, translated, one per element
#   MC_TARGET_ERRORS_EN  the same reasons in English, for the log
#   MC_TARGET_PRODUCT  MySQL | MariaDB
#   MC_TARGET_VERSION, MC_TARGET_VERSION_COMMENT, MC_TARGET_HOSTNAME,
#   MC_TARGET_PORT, MC_TARGET_SOCKET, MC_TARGET_DATADIR,
#   MC_TARGET_SERVER_UUID (MySQL), MC_TARGET_SERVER_ID (MariaDB)
#
# Comparisons: hostname and UUID ignore case, datadir ignores trailing
# slashes, the rest is exact. Nothing is ever written.

# shellcheck disable=SC2034  # MC_TARGET_* are read by inspect, preflight and the summary

mc_target_reset() {
  MC_TARGET_STATUS=''
  MC_TARGET_ERRORS=()
  MC_TARGET_ERRORS_EN=()
  MC_TARGET_PRODUCT=''
  MC_TARGET_VERSION=''
  MC_TARGET_VERSION_COMMENT=''
  MC_TARGET_HOSTNAME=''
  MC_TARGET_PORT=''
  MC_TARGET_SOCKET=''
  MC_TARGET_DATADIR=''
  MC_TARGET_SERVER_UUID=''
  MC_TARGET_SERVER_ID=''
}
mc_target_reset

# Returns 0 when the target is the expected one, 1 otherwise (see MC_TARGET_STATUS).
mc_target_check() {
  local row id_column id_value field value
  mc_target_reset

  if ! row=$(mc_auth_query 'SELECT @@version, @@version_comment' 2>/dev/null) || [ -z "$row" ]; then
    _mc_target_fail unreachable tgt.version_failed
    return 1
  fi
  # Tabs are IFS whitespace: two in a row would merge and shift the fields.
  # A non-whitespace separator keeps an empty column empty.
  row=${row//$'\t'/$'\x1f'}
  IFS=$'\x1f' read -r MC_TARGET_VERSION MC_TARGET_VERSION_COMMENT <<< "$row"
  if [[ "${MC_TARGET_VERSION,,}" == *mariadb* || "${MC_TARGET_VERSION_COMMENT,,}" == *mariadb* ]]; then
    MC_TARGET_PRODUCT=MariaDB
    id_column=server_id
  else
    MC_TARGET_PRODUCT=MySQL
    id_column=server_uuid
  fi

  # An expectation that cannot apply to this product is a configuration error.
  if [ "$MC_TARGET_PRODUCT" = MariaDB ] && [ -n "${MC_CONF[expect_server_uuid]}" ]; then
    _mc_target_fail config tgt.uuid_on_mariadb
  fi
  if [ "$MC_TARGET_PRODUCT" = MySQL ] && [ -n "${MC_CONF[expect_server_id]}" ]; then
    _mc_target_fail config tgt.id_on_mysql
  fi
  [ -z "$MC_TARGET_STATUS" ] || return 1

  if ! row=$(mc_auth_query "SELECT @@hostname, @@port, @@socket, @@datadir, @@$id_column" 2>/dev/null) ||
     [ -z "$row" ]; then
    _mc_target_fail unreachable tgt.metadata_failed "$id_column"
    return 1
  fi
  row=${row//$'\t'/$'\x1f'}
  IFS=$'\x1f' read -r MC_TARGET_HOSTNAME MC_TARGET_PORT MC_TARGET_SOCKET MC_TARGET_DATADIR id_value <<< "$row"
  if [ "$MC_TARGET_PRODUCT" = MariaDB ]; then
    MC_TARGET_SERVER_ID=$id_value
  else
    MC_TARGET_SERVER_UUID=$id_value
  fi

  # Every value must be there: the client prints NULL for a missing one.
  for field in hostname port socket datadir "$id_column"; do
    case "$field" in
      hostname)    value=$MC_TARGET_HOSTNAME ;;
      port)        value=$MC_TARGET_PORT ;;
      socket)      value=$MC_TARGET_SOCKET ;;
      datadir)     value=$MC_TARGET_DATADIR ;;
      server_uuid) value=$MC_TARGET_SERVER_UUID ;;
      server_id)   value=$MC_TARGET_SERVER_ID ;;
    esac
    if [ -z "$value" ] || [ "$value" = NULL ]; then
      _mc_target_fail rejected tgt.metadata_missing "@@$field"
    fi
  done
  if [ -n "$MC_TARGET_PORT" ] && ! [[ "$MC_TARGET_PORT" =~ ^[0-9]+$ ]]; then
    _mc_target_fail rejected tgt.metadata_invalid "@@port" "$MC_TARGET_PORT"
  fi
  if [ -n "$MC_TARGET_SERVER_ID" ] && [ "$MC_TARGET_SERVER_ID" != NULL ] &&
     ! [[ "$MC_TARGET_SERVER_ID" =~ ^[0-9]+$ ]]; then
    _mc_target_fail rejected tgt.metadata_invalid "@@server_id" "$MC_TARGET_SERVER_ID"
  fi
  [ -z "$MC_TARGET_STATUS" ] || return 1

  _mc_target_expect mysql_socket       "$MC_TARGET_SOCKET"
  _mc_target_expect expect_hostname    "$MC_TARGET_HOSTNAME" nocase
  _mc_target_expect expect_port        "$MC_TARGET_PORT"
  _mc_target_expect expect_datadir     "$MC_TARGET_DATADIR" dir
  _mc_target_expect expect_server_uuid "$MC_TARGET_SERVER_UUID" nocase
  _mc_target_expect expect_server_id   "$MC_TARGET_SERVER_ID"
  [ -z "$MC_TARGET_STATUS" ] || return 1

  MC_TARGET_STATUS=ok
}

# --- internals ---------------------------------------------------------------

# _mc_target_fail STATUS KEY [ARGS...]: the first status wins, every message
# is kept, translated and in English.
_mc_target_fail() {
  [ -n "$MC_TARGET_STATUS" ] || MC_TARGET_STATUS=$1
  shift
  MC_TARGET_ERRORS+=("$(mc_t "$@")")
  MC_TARGET_ERRORS_EN+=("$(mc_t_en "$@")")
}

# _mc_target_expect KEY ACTUAL [nocase|dir]: compares when KEY is set.
_mc_target_expect() {
  local key=$1 actual=$2 mode=${3:-} expected=${MC_CONF[$1]} a e
  [ -n "$expected" ] || return 0
  a=$actual
  e=$expected
  case "$mode" in
    nocase) a=${a,,}; e=${e,,} ;;
    dir)    while [[ "$a" == */ && "$a" != / ]]; do a=${a%/}; done
            while [[ "$e" == */ && "$e" != / ]]; do e=${e%/}; done ;;
  esac
  [ "$a" = "$e" ] && return 0
  _mc_target_fail rejected tgt.mismatch "$key" "$expected" "$actual"
  return 1
}
