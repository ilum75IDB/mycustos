# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Topology and role of the node: back up only on the PRIMARY, and any doubt
# blocks. An error reading the topology is never taken for a single instance.
# Sourced by bin/mycustos. Requires core/auth.sh with a selected method and a
# successful mc_target_check (product and server_uuid).
#
# MySQL:
#   no group_replication plugin              -> allowed (SINGLE_INSTANCE)
#   plugin, local node PRIMARY and ONLINE    -> allowed
#   plugin, local node SECONDARY and ONLINE  -> skip: no backup, exit 0, no flag
#   plugin unreadable, members unreadable, no member, inconsistent members,
#   local node missing or not ONLINE, online PRIMARY count != 1  -> blocked
# MariaDB:
#   @@wsrep_on OFF -> allowed (SINGLE_INSTANCE); ON (Galera) -> blocked;
#   unreadable or any other value -> blocked
# Classic asynchronous replication is not evaluated. Nothing is ever run on
# the PRIMARY: the module only says where it is.
#
# Results:
#   MC_TOPOLOGY_STATUS        allowed | skip | blocked
#   MC_TOPOLOGY_TYPE          SINGLE_INSTANCE | GROUP_REPLICATION | GALERA | UNKNOWN
#   MC_TOPOLOGY_ROLE          PRIMARY | SECONDARY | '' (not in a group)
#   MC_TOPOLOGY_MESSAGES      the reasons (or the skip notice), translated
#   MC_TOPOLOGY_MESSAGES_EN   the same in English, for the log
#   MC_TOPOLOGY_PRIMARY_HOST, MC_TOPOLOGY_PRIMARY_PORT, MC_TOPOLOGY_PRIMARY_IP
#                             the PRIMARY of the group, when there is exactly one
#   MC_TOPOLOGY_MEMBERS       number of members read

# shellcheck disable=SC2034  # MC_TOPOLOGY_* are read by backup, inspect and preflight

MC_TOPOLOGY_Q_PLUGIN="SELECT PLUGIN_STATUS FROM information_schema.PLUGINS WHERE PLUGIN_NAME = 'group_replication'"
MC_TOPOLOGY_Q_MEMBERS='SELECT MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members'
MC_TOPOLOGY_Q_WSREP='SELECT @@wsrep_on'

mc_topology_reset() {
  MC_TOPOLOGY_STATUS=''
  MC_TOPOLOGY_TYPE=UNKNOWN
  MC_TOPOLOGY_ROLE=''
  MC_TOPOLOGY_MESSAGES=()
  MC_TOPOLOGY_MESSAGES_EN=()
  MC_TOPOLOGY_PRIMARY_HOST=''
  MC_TOPOLOGY_PRIMARY_PORT=''
  MC_TOPOLOGY_PRIMARY_IP=''
  MC_TOPOLOGY_MEMBERS=0
}
mc_topology_reset

# Returns 0 when the backup may run here, 1 otherwise (skip or blocked: see
# MC_TOPOLOGY_STATUS), 2 when called without a successful mc_target_check.
mc_topology_check() {
  mc_topology_reset
  if [ "${MC_TARGET_STATUS:-}" != ok ]; then
    printf 'mycustos: internal error: mc_topology_check needs a successful mc_target_check\n' >&2
    return 2
  fi
  case "$MC_TARGET_PRODUCT" in
    MariaDB) _mc_topology_mariadb ;;
    *)       _mc_topology_mysql ;;
  esac
  [ "$MC_TOPOLOGY_STATUS" = allowed ]
}

# --- internals ---------------------------------------------------------------

_mc_topology_mariadb() {
  local value
  if ! value=$(mc_auth_query "$MC_TOPOLOGY_Q_WSREP" 2>/dev/null) || [ -z "$value" ]; then
    _mc_topology_set blocked topo.wsrep_unreadable
    return
  fi
  case "${value^^}" in
    0|OFF) MC_TOPOLOGY_TYPE=SINGLE_INSTANCE; MC_TOPOLOGY_STATUS=allowed ;;
    1|ON)  MC_TOPOLOGY_TYPE=GALERA; _mc_topology_set blocked topo.wsrep_on ;;
    *)     _mc_topology_set blocked topo.wsrep_ambiguous "$value" ;;
  esac
}

_mc_topology_mysql() {
  local plugin rows line id host port state role local_uuid
  local local_state='' local_role='' primaries=0 p_host='' p_port=''
  local -A seen

  if ! plugin=$(mc_auth_query "$MC_TOPOLOGY_Q_PLUGIN" 2>/dev/null); then
    _mc_topology_set blocked topo.plugin_unreadable
    return
  fi
  if [ -z "$plugin" ]; then
    MC_TOPOLOGY_TYPE=SINGLE_INSTANCE
    MC_TOPOLOGY_STATUS=allowed
    return
  fi

  MC_TOPOLOGY_TYPE=GROUP_REPLICATION
  if ! rows=$(mc_auth_query "$MC_TOPOLOGY_Q_MEMBERS" 2>/dev/null); then
    _mc_topology_set blocked topo.members_unreadable
    return
  fi
  if [ -z "$rows" ]; then
    _mc_topology_set blocked topo.no_members
    return
  fi

  local_uuid=${MC_TARGET_SERVER_UUID,,}
  seen=()
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    MC_TOPOLOGY_MEMBERS=$((MC_TOPOLOGY_MEMBERS + 1))
    # Tabs are IFS whitespace: a non-whitespace separator keeps an empty
    # column empty (an OFFLINE member has an empty role).
    line=${line//$'\t'/$'\x1f'}
    id='' host='' port='' state='' role=''
    IFS=$'\x1f' read -r id host port state role <<< "$line"
    [ "$role" != NULL ] || role=''
    if [ -z "$id" ] || [ "$id" = NULL ] || [ -z "$state" ] || [ "$state" = NULL ]; then
      _mc_topology_fail topo.member_invalid "${line//$'\x1f'/ }"
      continue
    fi
    id=${id,,}
    if [ -n "${seen[$id]:-}" ]; then
      _mc_topology_fail topo.member_duplicate "$id"
      continue
    fi
    seen[$id]=1
    if [ "$state" = ONLINE ]; then
      case "$role" in
        PRIMARY)   primaries=$((primaries + 1)); p_host=$host; p_port=$port ;;
        SECONDARY) ;;
        *)         _mc_topology_fail topo.member_invalid "${line//$'\x1f'/ }"; continue ;;
      esac
    fi
    if [ "$id" = "$local_uuid" ]; then
      local_state=$state
      local_role=$role
    fi
  done <<< "$rows"

  if [ -z "$local_state" ]; then
    _mc_topology_fail topo.local_missing "$MC_TARGET_SERVER_UUID"
  elif [ "$local_state" != ONLINE ]; then
    _mc_topology_fail topo.local_not_online "$local_state"
  fi
  if [ "$primaries" -ne 1 ]; then
    _mc_topology_fail topo.primary_count "$primaries"
  fi
  [ -z "$MC_TOPOLOGY_STATUS" ] || return

  MC_TOPOLOGY_ROLE=$local_role
  MC_TOPOLOGY_PRIMARY_HOST=$p_host
  MC_TOPOLOGY_PRIMARY_PORT=$p_port
  MC_TOPOLOGY_PRIMARY_IP=$(_mc_topology_resolve "$p_host")
  if [ "$local_role" = PRIMARY ]; then
    MC_TOPOLOGY_STATUS=allowed
  else
    _mc_topology_set skip topo.secondary "$p_host" "${MC_TOPOLOGY_PRIMARY_IP:--}" "$p_port"
  fi
}

# _mc_topology_set STATUS KEY [ARGS...]: sets the status, keeps the message.
_mc_topology_set() {
  MC_TOPOLOGY_STATUS=$1
  shift
  MC_TOPOLOGY_MESSAGES+=("$(mc_t "$@")")
  MC_TOPOLOGY_MESSAGES_EN+=("$(mc_t_en "$@")")
}

# _mc_topology_fail KEY [ARGS...]: blocks, every reason is kept.
_mc_topology_fail() {
  _mc_topology_set blocked "$@"
}

# _mc_topology_resolve HOST: prints its IPv4/IPv6 address, the host itself
# when it already is one, nothing when it cannot be resolved.
_mc_topology_resolve() {
  local host=$1 ip=''
  [ -n "$host" ] || return 0
  if [[ "$host" =~ ^[0-9]+(\.[0-9]+){3}$ || "$host" == *:* ]]; then
    printf '%s' "$host"
    return 0
  fi
  if command -v getent >/dev/null 2>&1; then
    ip=$(getent hosts "$host" 2>/dev/null | awk 'NR == 1 { print $1 }')
  fi
  printf '%s' "$ip"
}
