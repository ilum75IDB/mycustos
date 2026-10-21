#!/usr/bin/env zsh

###############################################################################
# MYCUSTOS - HELP SYSTEM
# Sistema help parametrico per accesso rapido a tutti i comandi MYCUS
# Versione: 1.0 (standard RCCS2025)
# Data Creazione: Mercoledì 21 Ottobre 2026
# Autore: Ivan Luminaria
# Progetto: mycustos (runner Bash per standardizzare i backup MySQL sui server)
# Repository: ilum75IDB/mycustos (da creare)
###############################################################################

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Header e Footer comuni
show_header() {
    echo "================================================================"
    echo "🛡️  MYCUSTOS - HELP"
    echo "================================================================"
}

show_footer() {
    echo "================================================================"
}

# Menu principale
show_main_menu() {
    show_header
    echo ""
    echo -e "${YELLOW}SEZIONI HELP DISPONIBILI:${NC}"
    echo ""
    echo -e "  ${WHITE}1${NC}  mycushelp -B    Backup runner (script Bash)"
    echo -e "  ${WHITE}2${NC}  mycushelp -L    Licenza e paternità (Apache-2.0)"
    echo -e "  ${WHITE}3${NC}  mycushelp -N    Navigazione directory"
    echo -e "  ${WHITE}4${NC}  mycushelp -G    Git & Safety"
    echo -e "  ${WHITE}5${NC}  mycushelp -V    Variabili ambiente"
    echo -e "  ${WHITE}6${NC}  mycushelp -H    Help e Setup"
    echo ""
    echo -e "${CYAN}Esempio:${NC} mycushelp -L  ${CYAN}(mostra help licenza)${NC}"
    echo ""
    show_footer
}

# Sezione: BACKUP RUNNER
show_backup() {
    show_header
    echo ""
    echo -e "${YELLOW}🐚 BACKUP RUNNER (script Bash):${NC}"
    echo ""
    echo -e "${CYAN}Stato:${NC} in attesa della base di codice già sviluppata."
    echo -e "  Questa sezione verrà popolata con i comandi reali di mycustos"
    echo -e "  (es. ${WHITE}mycustos run${NC}, ${WHITE}mycustos verify${NC}, ${WHITE}mycustos --version${NC})."
    echo ""
    echo -e "${CYAN}Qualità Bash:${NC}"
    echo -e "  ${WHITE}mycuslint${NC}       # shellcheck su tutti gli script .sh del progetto"
    echo ""
    echo -e "${CYAN}Note:${NC}"
    echo -e "  • Target: DB server Linux (cron / systemd timer), nessuna porta TCP"
    echo -e "  • Progetto ${WHITE}pubblico${NC}: mai riferimenti a clienti, host o path reali"
    echo ""
    show_footer
}

# Sezione: LICENZA
show_license() {
    show_header
    echo ""
    echo -e "${YELLOW}⚖️  LICENZA E PATERNITÀ:${NC}"
    echo ""
    echo -e "  ${WHITE}Licenza:${NC}  Apache-2.0 + file NOTICE (attribuzione obbligatoria)"
    echo -e "  ${WHITE}Autore:${NC}   Ivan Luminaria — IDEA DB CONSULTING S.R.L."
    echo ""
    echo -e "${CYAN}File da mantenere nel repo:${NC}"
    echo -e "  ${WHITE}LICENSE${NC}         # testo integrale Apache-2.0 (non modificato)"
    echo -e "  ${WHITE}NOTICE${NC}          # attribuzione autore (da preservare nelle redistribuzioni)"
    echo -e "  ${WHITE}header SPDX${NC}     # in testa a ogni script .sh"
    echo ""
    echo -e "${CYAN}Appunti completi:${NC}"
    echo -e "  ${WHITE}docs/licensing/01-appunti-licensing.md${NC}  (mycusgo lic)"
    echo ""
    show_footer
}

# Sezione: NAVIGAZIONE
show_navigation() {
    show_header
    echo ""
    echo -e "${YELLOW}🧭 NAVIGAZIONE (Unified Manager v1.0):${NC}"
    echo ""
    echo -e "  ${WHITE}mycusgo project${NC}     # Va a project root directory"
    echo -e "  ${WHITE}mycusgo bin${NC}         # Va a bin/ (anticipata)"
    echo -e "  ${WHITE}mycusgo lib${NC}         # Va a lib/ (anticipata)"
    echo -e "  ${WHITE}mycusgo conf${NC}        # Va a conf/ (anticipata)"
    echo -e "  ${WHITE}mycusgo tests${NC}       # Va a tests/ (anticipata)"
    echo -e "  ${WHITE}mycusgo docs${NC}        # Va a docs/"
    echo -e "  ${WHITE}mycusgo handoff${NC}     # Va a docs/handoff/"
    echo -e "  ${WHITE}mycusgo licensing${NC}   # Va a docs/licensing/"
    echo -e "  ${WHITE}mycusgo scripts${NC}     # Va a scripts/"
    echo -e "  ${WHITE}mycusgo shell${NC}       # Va a scripts/shell/ (env, help, go manager)"
    echo -e "  ${WHITE}mycusgo config${NC}      # Va a scripts/shell/config/ (copia ~/.zshrc)"
    echo ""
    echo -e "  ${WHITE}mycusgo${NC}             # Mostra lista directory disponibili"
    echo -e "  ${WHITE}mycusgo help${NC}        # Help completo navigation manager"
    echo ""
    echo -e "${CYAN}Alias:${NC}"
    echo -e "  mycusgo root = project, mycusgo test = tests, mycusgo lic = licensing"
    echo ""
    echo -e "${CYAN}Note:${NC}"
    echo -e "  • Le path target sono ricavate dalle variabili \$MYCUS_* (vedi ${WHITE}mycushelp -V${NC})"
    echo -e "  • Funzione wrapper in: ${WHITE}\$MYCUS_SHELL_DIR/mycus_env.zsh${NC}"
    echo -e "  • Script list/help in:  ${WHITE}\$MYCUS_SHELL_DIR/mycus_go_manager.zsh${NC}"
    echo -e "  • Le directory anticipate danno errore 'non trovata' finché non vengono create"
    echo ""
    show_footer
}

# Sezione: GIT & SAFETY
show_git() {
    show_header
    echo ""
    echo -e "${YELLOW}🔀 GIT & SAFETY:${NC}"
    echo ""
    echo -e "${CYAN}Stato:${NC} repo git ${WHITE}non ancora inizializzato${NC} (avvio GitHub in una fase successiva)."
    echo ""
    echo -e "${CYAN}Shortcut Git:${NC}"
    echo -e "  ${WHITE}gstatus${NC}         # git status"
    echo -e "  ${WHITE}gdiff${NC}           # git diff"
    echo -e "  ${WHITE}glog${NC}            # git log --oneline -20"
    echo ""
    echo -e "${RED}⚠️  Safety rules (~/.claude/CLAUDE.md globale):${NC}"
    echo -e "  • ${WHITE}Push su main consentito con valutazione esplicita${NC} (check-list di rischio)"
    echo -e "  • ${WHITE}Mai --force / --no-verify / --no-gpg-sign${NC} senza ok esplicito"
    echo -e "  • ${WHITE}Pre-commit fallito → MAI --amend, MAI --no-verify${NC} — fixa la causa + nuovo commit"
    echo -e "  • ${WHITE}Repo pubblico${NC}: verificare sempre l'assenza di dati cliente prima del push"
    echo ""
    show_footer
}

# Sezione: VARIABILI AMBIENTE
show_vars() {
    show_header
    echo ""
    echo -e "${YELLOW}📋 VARIABILI AMBIENTE:${NC}"
    echo ""
    echo -e "${CYAN}Path progetto:${NC}"
    echo -e "  ${WHITE}\$MYCUS_PROJECT_DIR${NC}    # $MYCUS_PROJECT_DIR"
    echo -e "  ${WHITE}\$MYCUS_SCRIPTS_DIR${NC}    # $MYCUS_SCRIPTS_DIR"
    echo -e "  ${WHITE}\$MYCUS_SHELL_DIR${NC}      # $MYCUS_SHELL_DIR"
    echo -e "  ${WHITE}\$MYCUS_DOCS_DIR${NC}       # $MYCUS_DOCS_DIR"
    echo -e "  ${WHITE}\$MYCUS_HANDOFF_DIR${NC}    # $MYCUS_HANDOFF_DIR"
    echo -e "  ${WHITE}\$MYCUS_LICENSING_DIR${NC}  # $MYCUS_LICENSING_DIR"
    echo -e "  ${WHITE}\$MYCUS_BIN_DIR${NC}        # $MYCUS_BIN_DIR (anticipata)"
    echo -e "  ${WHITE}\$MYCUS_LIB_DIR${NC}        # $MYCUS_LIB_DIR (anticipata)"
    echo -e "  ${WHITE}\$MYCUS_CONF_DIR${NC}       # $MYCUS_CONF_DIR (anticipata)"
    echo -e "  ${WHITE}\$MYCUS_TESTS_DIR${NC}      # $MYCUS_TESTS_DIR (anticipata)"
    echo ""
    echo -e "${CYAN}Repository:${NC}"
    echo -e "  ${WHITE}\$MYCUS_REPO${NC}           # $MYCUS_REPO"
    echo ""
    echo -e "${CYAN}Note:${NC}"
    echo -e "  • Caricate da: ${WHITE}\$MYCUS_SHELL_DIR/mycus_env.zsh${NC}"
    echo -e "  • Nessuna porta TCP locale (script CLI)"
    echo ""
    show_footer
}

# Sezione: HELP E SETUP
show_help_section() {
    show_header
    echo ""
    echo -e "${YELLOW}❓ HELP E SETUP:${NC}"
    echo ""
    echo -e "  ${WHITE}mycushelp${NC}        # Mostra elenco sezioni"
    echo -e "  ${WHITE}mycushelp -X${NC}     # Mostra sezione specifica (X = parametro)"
    echo ""
    echo -e "${CYAN}Setup ambiente:${NC}"
    echo -e "  ${WHITE}workmycus${NC}        # Carica ambiente MYCUS (alias da ~/.zshrc)"
    echo -e "  ${WHITE}prjmenu${NC}          # Ricarica ~/.zshrc (menu progetti)"
    echo ""
    echo -e "${CYAN}File di configurazione:${NC}"
    echo -e "  • Env progetto:  ${WHITE}\$MYCUS_SHELL_DIR/mycus_env.zsh${NC}"
    echo -e "  • Help progetto: ${WHITE}\$MYCUS_SHELL_DIR/mycus_help.zsh${NC}"
    echo -e "  • Go manager:    ${WHITE}\$MYCUS_SHELL_DIR/mycus_go_manager.zsh${NC}"
    echo -e "  • Menu globale:  ${WHITE}~/.zshrc${NC} (case 18|mycus → carica env)"
    echo -e "  • Backup zshrc:  ${WHITE}\$MYCUS_SHELL_DIR/config/zshrc.txt${NC} (copia statica)"
    echo ""
    echo -e "${CYAN}Documentazione progetto:${NC}"
    echo -e "  • ${WHITE}CLAUDE.md${NC}                          → istruzioni AI + convenzioni progetto"
    echo -e "  • ${WHITE}docs/licensing/${NC}                    → appunti licenza e paternità"
    echo ""
    show_footer
}

# MAIN - Gestione parametri (CASE-INSENSITIVE)
main() {
    # Converte il parametro in minuscolo per gestione case-insensitive
    local param="${1}"
    local param_lower="${param:l}"  # ZSH parameter expansion per lowercase

    case "${param_lower}" in
        -b|--backup)
            show_backup
            ;;
        -l|--license)
            show_license
            ;;
        -n|--navigation)
            show_navigation
            ;;
        -g|--git)
            show_git
            ;;
        -v|--vars)
            show_vars
            ;;
        -h|--help)
            show_help_section
            ;;
        "")
            show_main_menu
            ;;
        *)
            echo -e "${RED}Errore: Parametro non riconosciuto: $1${NC}"
            echo ""
            show_main_menu
            ;;
    esac
}

# Esegui main
main "$@"
