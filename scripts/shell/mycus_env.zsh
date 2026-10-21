#!/bin/zsh
# ===================================================================
# MYCUSTOS - ENVIRONMENT CONFIGURATION FOR ZSH
# File: mycus_env.zsh
# Versione: 1.0 (standard RCCS2025: env separato + help parametrico + go manager)
# Data Creazione: Mercoledì 21 Ottobre 2026
# Autore: Ivan Luminaria
# Progetto: mycustos (runner Bash per standardizzare i backup MySQL sui server)
# Repository: ilum75IDB/mycustos (da creare — progetto pubblico, Apache-2.0)
# ===================================================================

# ===================================================================
# DIRECTORY BASE E PROGETTO
# ===================================================================
export MYCUS_PROJECT_DIR="${HOME}/Development/APPLICAZIONI/mycustos"
export MYCUS_SCRIPTS_DIR="$MYCUS_PROJECT_DIR/scripts"
export MYCUS_SHELL_DIR="$MYCUS_SCRIPTS_DIR/shell"
export MYCUS_DOCS_DIR="$MYCUS_PROJECT_DIR/docs"
export MYCUS_HANDOFF_DIR="$MYCUS_DOCS_DIR/handoff"
export MYCUS_LICENSING_DIR="$MYCUS_DOCS_DIR/licensing"
# Nota: bin/, lib/, conf/, tests/ sono anticipate — la struttura reale del
# codice verrà definita quando arriverà la base di partenza già sviluppata.
export MYCUS_BIN_DIR="$MYCUS_PROJECT_DIR/bin"
export MYCUS_LIB_DIR="$MYCUS_PROJECT_DIR/lib"
export MYCUS_CONF_DIR="$MYCUS_PROJECT_DIR/conf"
export MYCUS_TESTS_DIR="$MYCUS_PROJECT_DIR/tests"

# ===================================================================
# REPOSITORY
# ===================================================================
export MYCUS_REPO="ilum75IDB/mycustos (non ancora creato)"

# Nota: questo progetto NON usa porte TCP locali (no web, no server).
# Lo scope è uno script Bash eseguito sui DB server (cron / systemd timer).

# ===================================================================
# ALIAS - GIT (shortcut comuni)
# ===================================================================
alias gstatus='git status'
alias gdiff='git diff'
alias glog='git log --oneline -20'

# ===================================================================
# ALIAS - QUALITÀ BASH
# ===================================================================
# shellcheck: lint di tutti gli script .sh del progetto (se installato)
alias mycuslint='find "$MYCUS_PROJECT_DIR" -name "*.sh" -not -path "*/.git/*" -print0 | xargs -0 shellcheck'

# ===================================================================
# FUNZIONI GO MANAGER (UNIFIED v1.0 — pattern RCCS2025 rccgo)
# ===================================================================
# Funzione wrapper per go manager
# - Senza argomenti       → mostra lista directory (delega allo script)
# - 'help'/-h/--help      → mostra help completo (delega allo script)
# - <target>              → cambia directory in shell corrente (case locale)
mycusgo() {
    local target="${1:-}"

    if [[ -z "$target" ]]; then
        # Mostra lista
        "$MYCUS_SHELL_DIR/mycus_go_manager.zsh"
        return 0
    fi

    if [[ "$target" == "help" ]] || [[ "$target" == "-h" ]] || [[ "$target" == "--help" ]]; then
        # Mostra help
        "$MYCUS_SHELL_DIR/mycus_go_manager.zsh" help
        return 0
    fi

    # Determina la directory target
    local target_dir=""

    case "$target" in
        project|root)
            target_dir="$MYCUS_PROJECT_DIR"
            ;;
        bin)
            target_dir="$MYCUS_BIN_DIR"
            ;;
        lib)
            target_dir="$MYCUS_LIB_DIR"
            ;;
        conf)
            target_dir="$MYCUS_CONF_DIR"
            ;;
        tests|test)
            target_dir="$MYCUS_TESTS_DIR"
            ;;
        docs)
            target_dir="$MYCUS_DOCS_DIR"
            ;;
        handoff)
            target_dir="$MYCUS_HANDOFF_DIR"
            ;;
        licensing|lic)
            target_dir="$MYCUS_LICENSING_DIR"
            ;;
        scripts)
            target_dir="$MYCUS_SCRIPTS_DIR"
            ;;
        shell)
            target_dir="$MYCUS_SHELL_DIR"
            ;;
        config)
            target_dir="$MYCUS_SHELL_DIR/config"
            ;;
        *)
            echo "❌ Directory non riconosciuta: $target"
            echo ""
            echo "Directory disponibili:"
            echo "  project/root, bin, lib, conf, tests/test, docs, handoff,"
            echo "  licensing/lic, scripts, shell, config"
            echo ""
            echo "Usa 'mycusgo help' per maggiori informazioni"
            return 1
            ;;
    esac

    # Verifica esistenza directory
    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Directory non trovata: $target_dir"
        echo "   (potrebbe essere una dir anticipata, non ancora creata)"
        return 1
    fi

    # Cambia directory
    cd "$target_dir"

    # Feedback visivo
    echo "✅ 📁 $(pwd)"
}

# ===================================================================
# HELP FUNCTION CON SISTEMA PARAMETRICO
# ===================================================================
mycushelp() {
    # Delega SEMPRE a mycus_help.zsh per help parametrico
    "$MYCUS_SHELL_DIR/mycus_help.zsh" "$@"
}

# ===================================================================
# MESSAGGI DI BENVENUTO
# ===================================================================
echo "🛡️  mycustos - Environment Loaded"
echo "   Versione: 1.0 (env separato + help parametrico, standard RCCS2025)"
echo "   Repository: $MYCUS_REPO"
echo ""
echo "   💡 Comandi rapidi:"
echo "      mycushelp      - Help completo (menu sezioni)"
echo "      mycusgo        - Navigazione directory (target: project/bin/lib/conf/docs/...)"
echo "      mycuslint      - shellcheck su tutti gli script .sh"
echo "      gstatus        - git status"
echo ""
