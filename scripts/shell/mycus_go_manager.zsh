#!/usr/bin/env zsh

###############################################################################
# MYCUSTOS - GO MANAGER
# Gestione unificata navigazione directory progetto
# Versione: 1.0 (standard RCCS2025 rcc_go_manager.zsh)
# Data Creazione: Mercoledì 21 Ottobre 2026
# Autore: Ivan Luminaria
# Progetto: mycustos (runner Bash per standardizzare i backup MySQL sui server)
# Repository: ilum75IDB/mycustos (da creare)
###############################################################################

# Exit on error
set -e

# Verifica che l'environment MYCUS sia caricato
if [[ -z "$MYCUS_SHELL_DIR" ]]; then
    echo "❌ ERROR: Environment MYCUS non caricato!"
    echo "   Assicurati di aver caricato mycus_env.zsh nella tua shell"
    exit 1
fi

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

###############################################################################
# FUNZIONI UTILITÀ
###############################################################################

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

###############################################################################
# COMANDO: HELP
###############################################################################

show_help() {
    cat << EOF
================================================================
🧭 MYCUSTOS - GO MANAGER
================================================================

Gestione unificata navigazione directory progetto

COMANDI DISPONIBILI:

  project             Va a project root directory
  bin                 Va a bin/ (entry point mycustos)
  lib                 Va a bin/modules/ (moduli Bash)
  conf                Va a config/ (template *.example)
  tests               Va a tests/ (test Bats)
  docs                Va a docs/ (documentazione progetto)
  handoff             Va a docs/handoff/ (recap sessioni)
  licensing           Va a docs/licensing/ (appunti licenza e paternità)
  scripts             Va a scripts/ (root scripts del progetto)
  shell               Va a scripts/shell/ (env, help, go manager)
  config              Va a scripts/shell/config/ (copia ~/.zshrc)

  help                Mostra questo messaggio

ALIAS:

  root                Alias per 'project'
  test                Alias per 'tests'
  lic                 Alias per 'licensing'

ESEMPI:

  mycusgo project
  mycusgo licensing
  mycusgo docs
  mycusgo                 # Mostra lista directory

DIRECTORY MAPPATE:

  project    → $MYCUS_PROJECT_DIR
  bin        → $MYCUS_BIN_DIR
  lib        → $MYCUS_LIB_DIR
  conf       → $MYCUS_CONF_DIR
  tests      → $MYCUS_TESTS_DIR
  docs       → $MYCUS_DOCS_DIR
  handoff    → $MYCUS_HANDOFF_DIR
  licensing  → $MYCUS_LICENSING_DIR
  scripts    → $MYCUS_SCRIPTS_DIR
  shell      → $MYCUS_SHELL_DIR
  config     → $MYCUS_SHELL_DIR/config

NOTE:

  • Le path sono ricavate dalle variabili \$MYCUS_* (vedi 'mycushelp -V')
  • lib = bin/modules/, conf = config/ del progetto;
    config = scripts/shell/config/ (copia ~/.zshrc)

================================================================
EOF
}

###############################################################################
# COMANDO: LIST (senza parametri)
###############################################################################

show_list() {
    cat << EOF
================================================================
🧭 MYCUS - DIRECTORY DISPONIBILI
================================================================

$(echo -e "${YELLOW}Directory Progetto:${NC}")
  project    → $MYCUS_PROJECT_DIR

$(echo -e "${YELLOW}Directory Codice:${NC}")
  bin        → $MYCUS_BIN_DIR
  lib        → $MYCUS_LIB_DIR
  conf       → $MYCUS_CONF_DIR
  tests      → $MYCUS_TESTS_DIR

$(echo -e "${YELLOW}Directory Docs:${NC}")
  docs       → $MYCUS_DOCS_DIR
  handoff    → $MYCUS_HANDOFF_DIR
  licensing  → $MYCUS_LICENSING_DIR

$(echo -e "${YELLOW}Directory Shell & Config:${NC}")
  scripts    → $MYCUS_SCRIPTS_DIR
  shell      → $MYCUS_SHELL_DIR
  config     → $MYCUS_SHELL_DIR/config

$(echo -e "${CYAN}Alias:${NC}")
  root = project, test = tests, lic = licensing

$(echo -e "${CYAN}Uso:${NC}")
  mycusgo <directory>
  mycusgo help

================================================================
EOF
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    # Se nessun argomento, mostra lista
    if [[ $# -eq 0 ]]; then
        show_list
        return 0
    fi

    local command="$1"

    case "$command" in
        help|-h|--help)
            show_help
            ;;
        list|ls)
            show_list
            ;;
        *)
            # Per directory target, la funzione wrapper mycusgo() in mycus_env.zsh
            # gestisce il cd effettivo nella shell chiamante.
            log_error "Comando non riconosciuto in esecuzione standalone: $command"
            echo ""
            echo "Usa 'mycusgo' (senza script) per navigare. Vedi 'mycusgo help'."
            return 1
            ;;
    esac
}

# NOTA IMPORTANTE: Per cambiare directory nella shell chiamante,
# questo script viene chiamato solo per i comandi list/help.
# Il cambio di directory effettivo è gestito dalla funzione wrapper
# mycusgo() definita in mycus_env.zsh (case + cd diretto in shell corrente).

# Gestione interruzioni
trap 'echo -e "\n${RED}[INTERROTTO]${NC} Go manager interrotto"; exit 130' INT TERM

# Esegui main con tutti gli argomenti
main "$@"
