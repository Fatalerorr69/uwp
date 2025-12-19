#!/bin/bash
# ====================================================
# UWP (Universal Workspace Project) - Samorozbalovací instalátor
# Verze: 4.0.0
# Autor: Fatalerorr69
# ====================================================

set -e

# Barvy pro výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# UWP konfigurace
UWP_HOME="$HOME/.universal-workspace"
UWP_TEMP="/tmp/uwp_install_$$"

# Funkce pro logování
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Zobrazení hlavičky
show_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Universal Workspace Project (UWP) - Instalátor v4.0.0    ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Kontrola závislostí
check_dependencies() {
    log_info "Kontrola systémových závislostí..."
    
    local missing=0
    
    # Python 3
    if command -v python3 &> /dev/null; then
        log_success "Python 3: $(python3 --version | cut -d' ' -f2)"
    else
        log_error "Python 3 není nainstalován!"
        missing=1
    fi
    
    # pip3
    if command -v pip3 &> /dev/null; then
        log_success "pip3: $(pip3 --version | cut -d' ' -f2)"
    else
        log_warning "pip3 není nainstalován, bude nainstalován automaticky"
    fi
    
    # curl
    if command -v curl &> /dev/null; then
        log_success "curl: $(curl --version | head -1 | cut -d' ' -f2)"
    else
        log_warning "curl není nainstalován, bude nainstalován automaticky"
    fi
    
    # wget
    if command -v wget &> /dev/null; then
        log_success "wget: $(wget --version | head -1 | cut -d' ' -f3)"
    else
        log_warning "wget není nainstalován, bude nainstalován automaticky"
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Některé závislosti chybí. Chcete je nainstalovat? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            install_missing_deps
        else
            log_error "Instalace nemůže pokračovat bez Pythonu 3"
            exit 1
        fi
    fi
}

# Instalace chybějících závislostí
install_missing_deps() {
    log_info "Instalace chybějících závislostí..."
    
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu
        sudo apt update
        sudo apt install -y python3 python3-pip curl wget git
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        sudo yum install -y python3 python3-pip curl wget git
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y python3 python3-pip curl wget git
    elif command -v pacman &> /dev/null; then
        # Arch
        sudo pacman -Syu --noconfirm python python-pip curl wget git
    elif command -v brew &> /dev/null; then
        # macOS
        brew install python curl wget git
    else
        log_error "Nepodporovaný systém. Nainstalujte závislosti manuálně."
        exit 1
    fi
}

# Vytvoření UWP struktury
create_uwp_structure() {
    log_info "Vytvářím strukturu UWP..."
    
    # Hlavní adresáře
    mkdir -p "$UWP_HOME"
    mkdir -p "$UWP_HOME/modules"
    mkdir -p "$UWP_HOME/configs"
    mkdir -p "$UWP_HOME/logs"
    mkdir -p "$UWP_HOME/cache"
    mkdir -p "$UWP_HOME/cli"
    mkdir -p "$UWP_HOME/wheels"
    mkdir -p "$UWP_HOME/extensions"
    mkdir -p "$UWP_HOME/plugins"
    
    log_success "Struktura vytvořena v $UWP_HOME"
}

# Extrakce zabudovaných souborů
extract_files() {
    log_info "Extrahuji UWP soubory..."
    
    # Vytvoření temporárního adresáře
    mkdir -p "$UWP_TEMP"
    
    # Extrakce souborů z tohoto skriptu
    local start_line=$(awk '/^__UWP_FILES_START__$/ { print NR + 1; exit 0; }' "$0")
    tail -n +$start_line "$0" | base64 -d | tar -xz -C "$UWP_TEMP"
    
    # Kopírování do cílového umístění
    cp -r "$UWP_TEMP"/* "$UWP_HOME/"
    
    # Nastavení práv
    find "$UWP_HOME" -name "*.sh" -exec chmod +x {} \;
    find "$UWP_HOME" -name "*.py" -exec chmod +x {} \;
    
    log_success "Soubory úspěšně extrahovány"
}

# Instalace AI modulu
install_ai_module() {
    log_info "Instaluji AI modul..."
    
    AI_DIR="$UWP_HOME/modules/ai_module"
    
    if [ -d "$AI_DIR" ]; then
        # Vytvoření virtuálního prostředí
        python3 -m venv "$AI_DIR/venv" 2>/dev/null || python3 -m venv --without-pip "$AI_DIR/venv"
        
        # Instalace závislostí
        if [ -d "$UWP_HOME/wheels" ] && [ "$(ls -A $UWP_HOME/wheels/*.whl 2>/dev/null)" ]; then
            log_info "Instaluji Python balíčky z wheels..."
            "$AI_DIR/venv/bin/pip" install --no-index --find-links="$UWP_HOME/wheels" -r "$AI_DIR/requirements.txt"
        else
            log_info "Instaluji Python balíčky z PyPI..."
            "$AI_DIR/venv/bin/pip" install -r "$AI_DIR/requirements.txt"
        fi
        
        log_success "AI modul nainstalován"
    else
        log_warning "AI modul nenalezen"
    fi
}

# Instalace Dev modulu
install_dev_module() {
    log_info "Instaluji Dev modul..."
    
    DEV_DIR="$UWP_HOME/modules/dev_module"
    
    if [ -d "$DEV_DIR" ] && command -v npm &> /dev/null; then
        cd "$DEV_DIR"
        npm install --silent
        log_success "Dev modul nainstalován"
    else
        log_warning "Dev modul nebo npm není dostupný"
    fi
}

# Vytvoření CLI
create_cli() {
    log_info "Vytvářím CLI..."
    
    # Hlavní CLI skript
    cat > "$UWP_HOME/cli/uwp" << 'EOF'
#!/usr/bin/env bash

UWP_HOME="$HOME/.universal-workspace"
UWP_CONFIGS="$UWP_HOME/configs"

# Načtení konfigurace
if [ -f "$UWP_CONFIGS/uwp_config.json" ]; then
    UWP_VERSION=$(grep '"version"' "$UWP_CONFIGS/uwp_config.json" | cut -d'"' -f4 2>/dev/null || echo "4.0.0")
else
    UWP_VERSION="4.0.0"
fi

# Hlavní funkce
main() {
    case "$1" in
        --status|-s)
            echo "UWP Status:"
            echo "-----------"
            echo "Version: $UWP_VERSION"
            echo "Home: $UWP_HOME"
            echo "Modules:"
            ls "$UWP_HOME/modules/" 2>/dev/null | while read mod; do
                echo "  - $mod"
            done
            ;;
            
        --help|-h)
            echo "Universal Workspace Project (UWP) CLI"
            echo "Usage: uwp [OPTION]"
            echo ""
            echo "Options:"
            echo "  --status, -s     Show UWP status"
            echo "  --help, -h       Show this help"
            echo "  --update         Update UWP"
            echo "  --ai             Launch AI module"
            echo "  --dev            Launch Dev module"
            echo "  --docker         Launch Docker module"
            echo "  --terminal       Configure terminal"
            echo "  --validate       Run system validation"
            ;;
            
        --update)
            echo "Updating UWP..."
            curl -s https://raw.githubusercontent.com/Fatalerorr69/uwp/main/auto_install.sh | bash
            ;;
            
        --ai)
            if [ -f "$UWP_HOME/modules/ai_module/ai_main.py" ]; then
                python3 "$UWP_HOME/modules/ai_module/ai_main.py" "${@:2}"
            else
                echo "AI module not found"
            fi
            ;;
            
        --dev)
            if [ -f "$UWP_HOME/modules/dev_module/dev_main.js" ]; then
                node "$UWP_HOME/modules/dev_module/dev_main.js" "${@:2}"
            else
                echo "Dev module not found"
            fi
            ;;
            
        --docker)
            if [ -f "$UWP_HOME/modules/docker_module/docker_setup.sh" ]; then
                bash "$UWP_HOME/modules/docker_module/docker_setup.sh" "${@:2}"
            else
                echo "Docker module not found"
            fi
            ;;
            
        --terminal)
            if [ -f "$UWP_HOME/modules/terminal_module/terminal_config.sh" ]; then
                bash "$UWP_HOME/modules/terminal_module/terminal_config.sh" "${@:2}"
            else
                echo "Terminal module not found"
            fi
            ;;
            
        --validate)
            if [ -f "$UWP_HOME/modules/validator_module/validator.sh" ]; then
                bash "$UWP_HOME/modules/validator_module/validator.sh" "${@:2}"
            else
                echo "Validator module not found"
            fi
            ;;
            
        *)
            echo "Universal Workspace Project v$UWP_VERSION"
            echo "Use 'uwp --help' for usage information"
            ;;
    esac
}

main "$@"
EOF
    
    chmod +x "$UWP_HOME/cli/uwp"
    
    # Vytvoření symlinku
    if [ -w "/usr/local/bin" ]; then
        sudo ln -sf "$UWP_HOME/cli/uwp" /usr/local/bin/uwp 2>/dev/null || true
        log_success "CLI nainstalován do /usr/local/bin/uwp"
    else
        # Přidání aliasu do shellu
        echo "alias uwp='$UWP_HOME/cli/uwp'" >> "$HOME/.bashrc"
        if [ -f "$HOME/.zshrc" ]; then
            echo "alias uwp='$UWP_HOME/cli/uwp'" >> "$HOME/.zshrc"
        fi
        log_success "CLI alias přidán do shellu"
    fi
}

# Aktualizace shell konfigurace
update_shell_config() {
    log_info "Aktualizuji shell konfiguraci..."
    
    # Přidání UWP do PATH
    if ! grep -q "UWP_HOME" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Universal Workspace Project" >> "$HOME/.bashrc"
        echo "export UWP_HOME=\"$HOME/.universal-workspace\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$UWP_HOME/cli:\$PATH\"" >> "$HOME/.bashrc"
    fi
    
    # Pro zsh
    if [ -f "$HOME/.zshrc" ] && ! grep -q "UWP_HOME" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Universal Workspace Project" >> "$HOME/.zshrc"
        echo "export UWP_HOME=\"$HOME/.universal-workspace\"" >> "$HOME/.zshrc"
        echo "export PATH=\"\$UWP_HOME/cli:\$PATH\"" >> "$HOME/.zshrc"
    fi
    
    log_success "Shell konfigurace aktualizována"
}

# Hlavní instalační funkce
install_uwp() {
    show_header
    
    echo "Tento instalátor nainstaluje Universal Workspace Project (UWP) do:"
    echo -e "${CYAN}$UWP_HOME${NC}"
    echo ""
    echo "UWP obsahuje:"
    echo "  • AI modul s Python a offline modelem"
    echo "  • Development modul s Node.js nástroji"
    echo "  • Docker management modul"
    echo "  • Terminal enhancement modul"
    echo "  • System validator modul"
    echo "  • Auto-deployment modul"
    echo ""
    
    # Potvrzení instalace
    read -p "Chcete pokračovat v instalaci? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Instalace zrušena"
        exit 0
    fi
    
    # Kontrola závislostí
    check_dependencies
    
    # Kontrola existující instalace
    if [ -d "$UWP_HOME" ]; then
        log_warning "UWP již je nainstalován v $UWP_HOME"
        read -p "Chcete přeinstalovat? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Instalace zrušena"
            exit 0
        fi
        # Záloha konfigurace
        if [ -d "$UWP_HOME/configs" ]; then
            cp -r "$UWP_HOME/configs" "/tmp/uwp_configs_backup_$(date +%Y%m%d_%H%M%S)"
        fi
        # Odstranění staré instalace
        rm -rf "$UWP_HOME"
    fi
    
    # Vytvoření struktury
    create_uwp_structure
    
    # Extrakce souborů
    extract_files
    
    # Instalace modulů
    install_ai_module
    install_dev_module
    
    # Vytvoření CLI
    create_cli
    
    # Aktualizace shellu
    update_shell_config
    
    # Zobrazení dokončovací zprávy
    show_completion_message
}

# Zobrazení dokončovací zprávy
show_completion_message() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         INSTALACE ÚSPĚŠNĚ DOKONČENA!                        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}🎉 Universal Workspace Project (UWP) je nainstalován!${NC}"
    echo ""
    echo -e "${YELLOW}📋 Další kroky:${NC}"
    echo "1. Restartujte terminal nebo spusťte:"
    echo "   ${CYAN}source ~/.bashrc${NC}"
    echo "2. Zkontrolujte instalaci:"
    echo "   ${CYAN}uwp --status${NC}"
    echo "3. Zobrazte nápovědu:"
    echo "   ${CYAN}uwp --help${NC}"
    echo ""
    echo -e "${BLUE}🚀 Dostupné příkazy:${NC}"
    echo "   • ${CYAN}uwp --ai${NC}          - Spustí AI modul"
    echo "   • ${CYAN}uwp --dev${NC}         - Spustí Dev modul"
    echo "   • ${CYAN}uwp --docker${NC}      - Spustí Docker modul"
    echo "   • ${CYAN}uwp --terminal${NC}    - Konfigurace terminálu"
    echo "   • ${CYAN}uwp --validate${NC}    - Ověření systému"
    echo ""
    echo -e "${PURPLE}📂 UWP je nainstalován v: ${UWP_HOME}${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Poznámka: Pro plnou funkčnost Docker modulu potřebujete mít nainstalovaný Docker${NC}"
    echo ""
}

# Úklid
cleanup() {
    if [ -d "$UWP_TEMP" ]; then
        rm -rf "$UWP_TEMP"
    fi
}

# Hlavní funkce
main() {
    trap cleanup EXIT
    
    # Zpracování argumentů
    case "$1" in
        --help|-h)
            echo "UWP Samorozbalovací Instalátor"
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --help, -h    Show this help"
            echo "  --update      Update existing installation"
            echo "  --uninstall   Remove UWP"
            ;;
            
        --update)
            echo "Aktualizace UWP..."
            # Stažení nejnovějšího instalátoru
            curl -s https://raw.githubusercontent.com/Fatalerorr69/uwp/main/uwp_installer.sh | bash -s -- --update
            ;;
            
        --uninstall)
            echo -e "${RED}Opravdu chcete odstranit UWP? [y/N]${NC}"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                rm -rf "$UWP_HOME"
                sudo rm -f /usr/local/bin/uwp 2>/dev/null
                # Odstranění z shell konfigurace
                sed -i '/# Universal Workspace Project/,+3d' "$HOME/.bashrc" 2>/dev/null
                sed -i '/# Universal Workspace Project/,+3d' "$HOME/.zshrc" 2>/dev/null
                echo "UWP byl odstraněn"
            else
                echo "Odstranění zrušeno"
            fi
            ;;
            
        *)
            install_uwp
            ;;
    esac
}

# Spuštění hlavní funkce
main "$@"

exit 0

# ====================================================
# ZDE ZAČÍNAJÍ ZAKÓDOVANÉ SOUBORY UWP
# ====================================================
__UWP_FILES_START__
