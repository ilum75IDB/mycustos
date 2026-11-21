# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Localisation of the messages shown to a person at the terminal.
# Sourced by bin/mycustos, right after core/errors.sh.
#
# Catalogs: bin/modules/locale/<code>.msg, one per language (en, it, pt_BR, ...).
#   # name: <language name, in that language>
#   # status: reviewed | needs native review
#   key.name=printf format      the value is everything after the first "=", verbatim
# The files are READ, never sourced. English (en.msg) is the reference: a key
# missing in another catalog falls back to English. Adding a language means
# adding a file: the available languages are the catalogs present.
#
# What is NOT localised: log files, the backup summary, flag names, statuses,
# "inspect" output, configuration keys, the OK/WARN/FAIL/ERROR tags, and the
# internal errors that can only come from a bug. Monitoring and scripts read them.
#
#   mc_t KEY [ARG...]          prints the message (no newline)
#   mc_tv VAR KEY [ARG...]     stores the message in VAR
#   mc_t_en KEY [ARG...]       prints the English message (for the log files)
#   say KEY [ARG...]           prints the message and a newline on stdout
#
# Language, first match wins: --lang > MYCUSTOS_LANGUAGE > "language=" in
# mycustos.conf > LC_ALL > LC_MESSAGES > LANG > en.

# shellcheck disable=SC2034  # MC_LANG is read by help and check-config

# Declared and assigned separately: Bash 4.2 mishandles "declare -gA x=()" when
# the file is sourced from a function (e.g. by the tests).
declare -gA MC_MSG MC_MSG_EN
MC_MSG=()
MC_MSG_EN=()
MC_LANG=en
MC_LOCALE_DIR=${MC_LOCALE_DIR:-$MYCUSTOS_MODULES/locale}

mc_t() {
  local out
  mc_tv out "$@"
  printf '%s' "$out"
}

mc_tv() {
  local _mc_var=$1 _mc_key=$2 _mc_fmt
  shift 2
  if [ -n "${MC_MSG[$_mc_key]+x}" ]; then
    _mc_fmt=${MC_MSG[$_mc_key]}
  elif [ -n "${MC_MSG_EN[$_mc_key]+x}" ]; then
    _mc_fmt=${MC_MSG_EN[$_mc_key]}
  else
    # A bug: the tests check that every key used in the code exists in en.msg.
    _mc_fmt="[$_mc_key]"
    [ $# -eq 0 ] || _mc_fmt+=$(printf ' %s' "$@")
    printf -v "$_mc_var" '%s' "$_mc_fmt"
    return 0
  fi
  # shellcheck disable=SC2059  # the format comes from the catalog
  printf -v "$_mc_var" -- "$_mc_fmt" "$@"
}

mc_t_en() {
  local -A MC_MSG
  MC_MSG=()
  mc_t "$@"
}

say() {
  local out
  mc_tv out "$@"
  printf '%s\n' "$out"
}

# Codes of the available languages, one per line, sorted.
mc_i18n_languages() {
  local f code
  local -a codes=()
  for f in "$MC_LOCALE_DIR"/*.msg; do
    [ -f "$f" ] || continue
    code=${f##*/}
    code=${code%.msg}
    _mc_i18n_valid_code "$code" && codes+=("$code")
  done
  [ ${#codes[@]} -gt 0 ] || return 0
  printf '%s\n' "${codes[@]}" | LC_ALL=C sort
}

# Name of a language, from the "# name:" header of its catalog.
mc_i18n_name() {
  local line
  [ -r "$MC_LOCALE_DIR/$1.msg" ] || return 1
  while IFS= read -r line; do
    case "$line" in
      '# name:'*) line=${line#'# name:'}; printf '%s\n' "${line# }"; return 0 ;;
      '#'*|'') ;;
      *) break ;;
    esac
  done < "$MC_LOCALE_DIR/$1.msg"
  return 1
}

# "en (English), it (Italiano), ..." for the help and the warnings.
mc_i18n_list() {
  local code name out=''
  while IFS= read -r code; do
    name=$(mc_i18n_name "$code") || name=$code
    out+="${out:+, }$code ($name)"
  done < <(mc_i18n_languages)
  printf '%s' "$out"
}

# mc_i18n_resolve VALUE: prints the code of the catalog for a language code or
# a locale (it, it_IT.UTF-8, pt-BR: region first, then the language alone).
# Prints "en" for C/POSIX/empty; returns 1 when no catalog matches.
mc_i18n_resolve() {
  local lang region code
  lang=${1%%[.@]*}
  lang=${lang//-/_}
  region=''
  if [[ "$lang" == *_* ]]; then
    region=${lang#*_}
    lang=${lang%%_*}
  fi
  lang=${lang,,}
  region=${region^^}
  case "$lang" in ''|c|posix) echo en; return 0 ;; esac
  for code in ${region:+"${lang}_$region"} "$lang"; do
    _mc_i18n_valid_code "$code" && [ -r "$MC_LOCALE_DIR/$code.msg" ] || continue
    echo "$code"
    return 0
  done
  return 1
}

# mc_i18n_select VALUE [explicit]: switches to the language of VALUE.
# Without "explicit" (the value comes from the system locale) an unavailable
# language silently means English; with it, a warning lists the available ones.
mc_i18n_select() {
  local code
  MC_MSG=()
  MC_LANG=en
  if ! code=$(mc_i18n_resolve "$1"); then
    if [ -n "${2:-}" ]; then
      printf 'mycustos: %s\n' "$(mc_t core.warning "$(mc_t i18n.unknown_language "$1" "$(mc_i18n_list)")")" >&2
    fi
    return 1
  fi
  MC_LANG=$code
  [ "$code" = en ] || _mc_i18n_load "$MC_LOCALE_DIR/$code.msg" cur
}

# mc_i18n_init [--lang VALUE]: chooses the language with the documented
# precedence. "--quiet-early" skips the configuration file and every warning
# (used before the global options are parsed).
mc_i18n_init() {
  local opt='' early='' mode=explicit v
  while [ $# -gt 0 ]; do
    case "$1" in
      --lang) opt=$2; shift ;;
      --quiet-early) early=1 ;;
    esac
    shift
  done
  [ -z "$early" ] || mode=''
  if [ -n "$opt" ]; then
    mc_i18n_select "$opt" "$mode"
  elif [ -n "${MYCUSTOS_LANGUAGE:-}" ]; then
    mc_i18n_select "$MYCUSTOS_LANGUAGE" "$mode"
  elif [ -z "$early" ] && declare -F mc_config_peek >/dev/null &&
       v=$(mc_config_peek language) && [ -n "$v" ]; then
    mc_i18n_select "$v" explicit
  else
    mc_i18n_select "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  fi
  return 0
}

# --- internals ---------------------------------------------------------------

_mc_i18n_valid_code() {
  [[ "$1" =~ ^[a-z]{2,3}(_[A-Z]{2})?$ ]]
}

# _mc_i18n_load FILE en|cur
_mc_i18n_load() {
  local file=$1 target=$2 line key
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%$'\r'}
    [[ -z "$line" || "$line" == '#'* || "$line" != *=* ]] && continue
    key=${line%%=*}
    key=${key//[[:space:]]/}
    [[ "$key" =~ ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$ ]] || continue
    if [ "$target" = en ]; then
      MC_MSG_EN[$key]=${line#*=}
    else
      MC_MSG[$key]=${line#*=}
    fi
  done < "$file"
}

# English is always loaded: it is the fallback of every other catalog.
if [ -r "$MC_LOCALE_DIR/en.msg" ]; then
  _mc_i18n_load "$MC_LOCALE_DIR/en.msg" en
fi
