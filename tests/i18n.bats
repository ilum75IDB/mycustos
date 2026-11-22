#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 Ivan Luminaria — IDEA DB CONSULTING S.R.L.
# Original project: https://github.com/ilum75IDB/mycustos
#
# Localisation: consistency of the catalogs, keys used by the code, choice of
# the language, and what must stay in English.

load test_helper

setup() {
  mc_test_load_core
  MYCUSTOS="$REPO/bin/mycustos"
  LOCALE="$REPO/bin/modules/locale"
}

# Keys of a catalog, one per line, in file order.
cat_keys() {
  grep -vE '^[[:space:]]*(#|$)' "$1" | cut -d= -f1
}

# Placeholders of KEY in a catalog, on one line ("%s %d").
cat_placeholders() {
  grep -m1 "^$2=" "$1" | cut -d= -f2- | grep -oE '%[-+ 0#]*[0-9]*(\.[0-9]+)?[a-zA-Z%]' | tr '\n' ' '
}

# Keys referenced by the code (literal keys after the i18n functions).
code_keys() {
  grep -rhoE "(mc_t|mc_t_en|say|warn|die_usage|_mc_target_fail +[a-z]+|_mc_topology_(set|fail)( +[a-z]+)?|_mc_help_option +'[^']*' *|mc_tv +[A-Za-z_]+|die +\"?\\\$[A-Z_]+\"?) +[a-z][a-z0-9_]*(\.[a-z0-9_]+)+" \
    "$REPO/bin" | awk '{print $NF}' | sort -u
}

@test "catalogs: valid file names, header with name and status" {
  local f n=0
  for f in "$LOCALE"/*.msg; do
    n=$((n + 1))
    [[ "$(basename "$f" .msg)" =~ ^[a-z]{2,3}(_[A-Z]{2})?$ ]] || { echo "bad name: $f"; return 1; }
    grep -qE '^# name: .+' "$f" || { echo "no '# name:' in $f"; return 1; }
    grep -qE '^# status: (reviewed|needs native review)$' "$f" || { echo "no '# status:' in $f"; return 1; }
  done
  [ "$n" -ge 6 ]
}

@test "catalogs: every line is a comment, blank or key=value with a valid key" {
  local f bad
  for f in "$LOCALE"/*.msg; do
    bad=$(grep -vE '^[[:space:]]*(#|$)' "$f" | grep -vE '^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+=' || true)
    [ -z "$bad" ] || { echo "$f: $bad"; return 1; }
  done
}

@test "catalogs: no duplicated key, no empty value" {
  local f d
  for f in "$LOCALE"/*.msg; do
    d=$(cat_keys "$f" | sort | uniq -d)
    [ -z "$d" ] || { echo "$f: duplicated $d"; return 1; }
    d=$(grep -nE '^[a-z][a-z0-9_.]*=$' "$f" || true)
    [ -z "$d" ] || { echo "$f: $d"; return 1; }
  done
}

@test "catalogs: same keys as en.msg" {
  local f missing extra
  for f in "$LOCALE"/*.msg; do
    missing=$(comm -23 <(cat_keys "$LOCALE/en.msg" | sort) <(cat_keys "$f" | sort))
    extra=$(comm -13 <(cat_keys "$LOCALE/en.msg" | sort) <(cat_keys "$f" | sort))
    [ -z "$missing" ] || { echo "$f misses: $missing"; return 1; }
    [ -z "$extra" ] || { echo "$f has extra keys: $extra"; return 1; }
  done
}

@test "catalogs: same placeholders, in the same order, as en.msg" {
  local f key
  for f in "$LOCALE"/*.msg; do
    while IFS= read -r key; do
      if [ "$(cat_placeholders "$f" "$key")" != "$(cat_placeholders "$LOCALE/en.msg" "$key")" ]; then
        echo "$f: $key: '$(cat_placeholders "$f" "$key")' vs en '$(cat_placeholders "$LOCALE/en.msg" "$key")'"
        return 1
      fi
    done < <(cat_keys "$LOCALE/en.msg")
  done
}

@test "every key used by the code exists in en.msg" {
  local missing
  missing=$(comm -23 <(code_keys) <(cat_keys "$LOCALE/en.msg" | sort))
  [ -z "$missing" ] || { echo "missing in en.msg: $missing"; return 1; }
}

@test "every key of en.msg is used by the code" {
  local unused
  unused=$(comm -13 <(code_keys) <(cat_keys "$LOCALE/en.msg" | sort))
  [ -z "$unused" ] || { echo "unused: $unused"; return 1; }
}

@test "mc_t formats, falls back to English, flags an unknown key" {
  [ "$(mc_t cli.unknown_command nope)" = 'unknown command: nope' ]
  mc_i18n_select it
  [ "$MC_LANG" = it ]
  [ "$(mc_t cli.unknown_command nope)" = 'comando sconosciuto: nope' ]
  unset 'MC_MSG[cli.unknown_command]'
  [ "$(mc_t cli.unknown_command nope)" = 'unknown command: nope' ]
  [ "$(mc_t no.such_key a b)" = '[no.such_key] a b' ]
}

@test "mc_t keeps a message starting with dashes" {
  [ "$(mc_t cli.home_not_dir /x)" = '--home: not a directory: /x' ]
}

@test "mc_i18n_resolve: region, language alone, C and POSIX, unknown" {
  [ "$(mc_i18n_resolve it_IT.UTF-8)" = it ]
  [ "$(mc_i18n_resolve it_CH)" = it ]
  [ "$(mc_i18n_resolve de-AT)" = de ]
  [ "$(mc_i18n_resolve RO)" = ro ]
  [ "$(mc_i18n_resolve fr_FR@euro)" = fr ]
  [ "$(mc_i18n_resolve C)" = en ]
  [ "$(mc_i18n_resolve POSIX)" = en ]
  [ "$(mc_i18n_resolve '')" = en ]
  run mc_i18n_resolve ja_JP.UTF-8
  [ "$status" -eq 1 ]
}

@test "a region catalog is preferred to the language alone" {
  MC_LOCALE_DIR="$BATS_TEST_TMPDIR/locale"
  mkdir -p "$MC_LOCALE_DIR"
  cp "$LOCALE/en.msg" "$LOCALE/it.msg" "$MC_LOCALE_DIR/"
  sed 's/^cli.unknown_command=.*/cli.unknown_command=comando ignoto: %s/' "$LOCALE/it.msg" > "$MC_LOCALE_DIR/it_CH.msg"
  [ "$(mc_i18n_resolve it_CH.UTF-8)" = it_CH ]
  [ "$(mc_i18n_resolve it_IT.UTF-8)" = it ]
}

@test "adding a language is adding a file" {
  MC_LOCALE_DIR="$BATS_TEST_TMPDIR/locale"
  mkdir -p "$MC_LOCALE_DIR"
  cp "$LOCALE/en.msg" "$MC_LOCALE_DIR/"
  { echo '# name: Test'; echo '# status: needs native review'
    echo 'cli.unknown_command=xx: %s'; } > "$MC_LOCALE_DIR/xx.msg"
  [[ "$(mc_i18n_list)" == 'en (English), xx (Test)' ]]
  mc_i18n_select xx
  [ "$(mc_t cli.unknown_command a)" = 'xx: a' ]
  [ "$(mc_t cli.unknown_option a)" = 'unknown option: a' ]   # fallback to English
}

@test "help lists the languages, in their own names" {
  run "$MYCUSTOS" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Languages: de (Deutsch), en (English), es (Español), fr (Français), it (Italiano), ro (Română) (current: en)"* ]]
  [[ "$output" == *"--lang CODE"* ]]
}

@test "the system locale selects the language: LC_ALL > LC_MESSAGES > LANG" {
  run env LANG=it_IT.UTF-8 "$MYCUSTOS" help
  [[ "$output" == *"Uso: mycustos <comando> [opzioni]"* ]]
  run env LANG=it_IT.UTF-8 LC_MESSAGES=fr_FR.UTF-8 "$MYCUSTOS" help
  [[ "$output" == *"Utilisation : mycustos"* ]]
  run env LANG=it_IT.UTF-8 LC_MESSAGES=fr_FR.UTF-8 LC_ALL=de_DE.UTF-8 "$MYCUSTOS" help
  [[ "$output" == *"Verwendung: mycustos"* ]]
}

@test "precedence: --lang > MYCUSTOS_LANGUAGE > language= > locale" {
  mc_test_conf config_schema=1 language=es
  run env LANG=it_IT.UTF-8 "$MYCUSTOS" --home "$BASE" help
  [[ "$output" == *"Uso: mycustos <comando> [opciones]"* ]]
  run env LANG=it_IT.UTF-8 MYCUSTOS_LANGUAGE=ro "$MYCUSTOS" --home "$BASE" help
  [[ "$output" == *"Utilizare: mycustos"* ]]
  run env LANG=it_IT.UTF-8 MYCUSTOS_LANGUAGE=ro "$MYCUSTOS" --home "$BASE" --lang de help
  [[ "$output" == *"Verwendung: mycustos"* ]]
  run "$MYCUSTOS" --home "$BASE" --lang=fr help
  [[ "$output" == *"Utilisation : mycustos"* ]]
}

@test "an unknown language asked explicitly: one warning, then English" {
  run "$MYCUSTOS" --lang ja help
  [ "$status" -eq 0 ]
  [[ "$output" == *"warning: language 'ja' is not available, using English (available: de (Deutsch), en (English)"* ]]
  [[ "$output" == *"Usage: mycustos"* ]]
  [ "$(grep -c "is not available" <<< "$output")" -eq 1 ]
}

@test "an unknown language from the system locale: English, no warning" {
  run env LANG=ja_JP.UTF-8 "$MYCUSTOS" help
  [ "$status" -eq 0 ]
  [[ "$output" != *"not available"* ]]
  [[ "$output" == *"Usage: mycustos"* ]]
}

@test "errors on the global options follow the environment language" {
  run env MYCUSTOS_LANGUAGE=it "$MYCUSTOS" --nope
  [ "$status" -eq 2 ]
  [[ "$output" == *"opzione sconosciuta: --nope"* ]]
  [[ "$output" == *"Eseguire 'mycustos help' per l'uso."* ]]
}

@test "configuration errors are translated, origins and keys are not" {
  mc_test_conf config_schema=1 language=it compress_level=99
  run "$MYCUSTOS" --home "$BASE" check-config
  [ "$status" -eq 3 ]
  [[ "$output" == *"ERROR $BASE/config/mycustos.conf:3: compress_level: deve essere un intero tra 1 e 19 (trovato '99')"* ]]
  [[ "$output" == *"Esito: non valida, 1 errore/i"* ]]
}

@test "language= must look like a language code" {
  mc_test_conf config_schema=1 'language=it it'
  mc_config_load || true
  [[ "$(mc_test_errors)" == *"language: must be a language code"* ]]
}

@test "check-config warns about a language without a catalog" {
  mc_test_conf config_schema=1 language=ja
  run "$MYCUSTOS" --home "$BASE" check-config
  [ "$status" -eq 0 ]
  [[ "$output" == *"language 'ja' is not available, English is used"* ]]
}

@test "the run log stays in English whatever the language" {
  mc_i18n_select it
  mc_log_open "$BASE/logs/run.log"
  run die "$MC_EX_BACKUP" core.cannot_load /x/engine.sh
  [ "$status" -eq 6 ]
  [ "$output" = 'mycustos: impossibile caricare /x/engine.sh' ]
  grep -q 'ERROR cannot load /x/engine.sh$' "$BASE/logs/run.log"
}

@test "preflight in Italian keeps the OK/WARN/FAIL tags" {
  mc_test_conf config_schema=1 language=it auth_method=login-path auth_login_path=x
  run "$MYCUSTOS" --home "$BASE" preflight
  [[ "$output" == *"mycustos preflight - istanza main"* ]]
  [[ "$output" == *"  OK    configurazione: "* ]]
  [[ "$output" == *"  FAIL  "* ]]
  [[ "$output" == *"Esito: "* ]]
}
