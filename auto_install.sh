
### **auto_install.sh**
```bash
#!/usr/bin/env bash

# ==============================================
# UNIVERSAL WORKSPACE PROJECT - AUTO INSTALLER
# ==============================================
# Version: 4.0.0
# Author: Fatalerorr69
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# UWP Configuration
UWP_HOME="$HOME/.universal-workspace"
UWP_CLI="$UWP_HOME/cli"
UWP_MODULES="$UWP_HOME/modules"
UWP_CONFIGS="$UWP_HOME/configs"
UWP_BIN="/usr/local/bin/uwp"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check requirements
check_requirements() {
    log_info "Kontrola systémových požadavků..."
    
    # Check for Python3
    if command -v python3 &> /dev/null; then
        log_success "Python3 je nainstalován"
    else
        log_error "Python3 není nainstalován!"
        log_info "Instalujte Python3: sudo apt install python3"
        exit 1
    fi
    
    # Check for pip
    if command -v pip3 &> /dev/null; then
        log_success "pip3 je nainstalován"
    else
        log_warning "pip3 není nainstalován, instaluji..."
        sudo apt install python3-pip -y
    fi
    
    # Check for Node.js
    if command -v node &> /dev/null; then
        log_success "Node.js je nainstalován"
    else
        log_warning "Node.js není nainstalován, přeskočím dev modul..."
    fi
    
    # Check for Docker
    if command -v docker &> /dev/null; then
        log_success "Docker je nainstalován"
    else
        log_warning "Docker není nainstalován, přeskočím docker modul..."
    fi
    
    log_success "Všechny požadavky splněny"
}

# Create UWP directory structure
create_structure() {
    log_info "Vytvářím strukturu UWP..."
    
    # Create main directories
    mkdir -p "$UWP_HOME"
    mkdir -p "$UWP_CLI"
    mkdir -p "$UWP_MODULES"
    mkdir -p "$UWP_CONFIGS"
    mkdir -p "$UWP_HOME/logs"
    mkdir -p "$UWP_HOME/cache"
    
    # Copy modules from current directory
    log_info "Kopíruji moduly..."
    cp -r modules/* "$UWP_MODULES/" 2>/dev/null || true
    
    # Copy configs
    log_info "Kopíruji konfigurace..."
    cp -r configs/* "$UWP_CONFIGS/" 2>/dev/null || true
    
    log_success "Struktura vytvořena"
}

# Install AI module
install_ai_module() {
    log_info "Instaluji AI modul..."
    
    AI_DIR="$UWP_MODULES/ai_module"
    
    if [ -d "$AI_DIR" ]; then
        # Create virtual environment
        python3 -m venv "$AI_DIR/venv" 2>/dev/null || true
        
        # Install requirements using wheels
        if [ -d "wheels" ] && [ "$(ls -A wheels/*.whl 2>/dev/null)" ]; then
            log_info "Instaluji Python balíčky z wheels..."
            "$AI_DIR/venv/bin/pip" install --no-index --find-links=wheels -r "$AI_DIR/requirements.txt"
        else
            log_info "Instaluji Python balíčky z internetu..."
            "$AI_DIR/venv/bin/pip" install -r "$AI_DIR/requirements.txt"
        fi
        
        log_success "AI modul nainstalován"
    else
        log_warning "AI modul nenalezen, přeskočeno"
    fi
}

# Install Dev module
install_dev_module() {
    log_info "Instaluji Dev modul..."
    
    DEV_DIR="$UWP_MODULES/dev_module"
    
    if [ -d "$DEV_DIR" ] && command -v npm &> /dev/null; then
        # Install npm packages offline if available
        if [ -d "node_modules" ] && [ "$(ls -A node_modules)" ]; then
            log_info "Kopíruji npm balíčky..."
            cp -r node_modules "$DEV_DIR/"
        else
            log_info "Instaluji npm balíčky..."
            cd "$DEV_DIR" && npm install --silent
        fi
        
        log_success "Dev modul nainstalován"
    else
        log_warning "Dev modul nenalezen nebo npm není dostupný, přeskočeno"
    fi
}

# Install Terminal module
install_terminal_module() {
    log_info "Instaluji Terminal modul..."
    
    TERM_DIR="$UWP_MODULES/terminal_module"
    
    if [ -d "$TERM_DIR" ]; then
        chmod +x "$TERM_DIR/terminal_config.sh"
        log_success "Terminal modul nainstalován"
    else
        log_warning "Terminal modul nenalezen, přeskočeno"
    fi
}

# Install Validator module
install_validator_module() {
    log_info "Instaluji Validator modul..."
    
    VALIDATOR_DIR="$UWP_MODULES/validator_module"
    
    if [ -d "$VALIDATOR_DIR" ]; then
        chmod +x "$VALIDATOR_DIR/validator.sh"
        log_success "Validator modul nainstalován"
    else
        log_warning "Validator modul nenalezen, přeskočeno"
    fi
}

# Create CLI
create_cli() {
    log_info "Vytvářím CLI..."
    
    # Create main CLI script
    cat > "$UWP_CLI/uwp" << 'EOF'
#!/usr/bin/env bash

UWP_HOME="$HOME/.universal-workspace"
UWP_CONFIGS="$UWP_HOME/configs"

# Source config
if [ -f "$UWP_CONFIGS/uwp_config.json" ]; then
    UWP_VERSION=$(grep '"version"' "$UWP_CONFIGS/uwp_config.json" | cut -d'"' -f4)
fi

# Main function
main() {
    case "$1" in
        --status|-s)
            echo "UWP Status:"
            echo "-----------"
            echo "Version: ${UWP_VERSION:-4.0.0}"
            echo "Home: $UWP_HOME"
            echo "Modules:"
            ls "$UWP_HOME/modules/" 2>/dev/null || echo "No modules"
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
            ;;
            
        --update)
            echo "Updating UWP..."
            curl -s https://raw.githubusercontent.com/Fatalerorr69/uwp/main/auto_install.sh | bash
            ;;
            
        --ai)
            if [ -f "$UWP_HOME/modules/ai_module/ai_main.py" ]; then
                python3 "$UWP_HOME/modules/ai_module/ai_main.py"
            else
                echo "AI module not found"
            fi
            ;;
            
        --dev)
            if [ -f "$UWP_HOME/modules/dev_module/dev_main.js" ]; then
                node "$UWP_HOME/modules/dev_module/dev_main.js"
            else
                echo "Dev module not found"
            fi
            ;;
            
        --docker)
            if [ -f "$UWP_HOME/modules/docker_module/docker_setup.sh" ]; then
                bash "$UWP_HOME/modules/docker_module/docker_setup.sh"
            else
                echo "Docker module not found"
            fi
            ;;
            
        --terminal)
            if [ -f "$UWP_HOME/modules/terminal_module/terminal_config.sh" ]; then
                bash "$UWP_HOME/modules/terminal_module/terminal_config.sh"
            else
                echo "Terminal module not found"
            fi
            ;;
            
        *)
            echo "Universal Workspace Project v${UWP_VERSION:-4.0.0}"
            echo "Use 'uwp --help' for usage information"
            ;;
    esac
}

main "$@"
EOF
    
    chmod +x "$UWP_CLI/uwp"
    
    # Create symlink in /usr/local/bin if possible
    if [ -w "/usr/local/bin" ]; then
        sudo ln -sf "$UWP_CLI/uwp" "$UWP_BIN"
        log_success "CLI nainstalován do $UWP_BIN"
    else
        log_warning "Nelze vytvořit symlink v /usr/local/bin, přidám alias"
        echo "alias uwp='$UWP_CLI/uwp'" >> "$HOME/.bashrc"
        echo "alias uwp='$UWP_CLI/uwp'" >> "$HOME/.zshrc" 2>/dev/null || true
    fi
}

# Update shell configuration
update_shell() {
    log_info "Aktualizuji shell konfiguraci..."
    
    # Add UWP to PATH
    if ! grep -q "UWP_HOME" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# Universal Workspace Project" >> "$HOME/.bashrc"
        echo "export UWP_HOME=\"$HOME/.universal-workspace\"" >> "$HOME/.bashrc"
        echo "export PATH=\"\$UWP_HOME/cli:\$PATH\"" >> "$HOME/.bashrc"
    fi
    
    # Also update zshrc if exists
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "UWP_HOME" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Universal Workspace Project" >> "$HOME/.zshrc"
            echo "export UWP_HOME=\"$HOME/.universal-workspace\"" >> "$HOME/.zshrc"
            echo "export PATH=\"\$UWP_HOME/cli:\$PATH\"" >> "$HOME/.zshrc"
        fi
    fi
    
    log_success "Shell konfigurace aktualizována"
}

# Main installation function
install() {
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   UNIVERSAL WORKSPACE PROJECT INSTALLER   ║${NC}"
    echo -e "${BLUE}║                 v4.0.0                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Nespouštějte tento skript jako root/sudo!"
        log_info "Spusťte jako běžný uživatel: ./auto_install.sh"
        exit 1
    fi
    
    # Check requirements
    check_requirements
    
    # Create structure
    create_structure
    
    # Install modules
    install_ai_module
    install_dev_module
    install_terminal_module
    install_validator_module
    
    # Create CLI
    create_cli
    
    # Update shell
    update_shell
    
    # Final message
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        INSTALACE ÚSPĚŠNĚ DOKONČENA       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Další kroky:${NC}"
    echo "1. Restartujte terminal nebo spusťte:"
    echo "   source ~/.bashrc"
    echo "2. Zkontrolujte instalaci:"
    echo "   uwp --status"
    echo "3. Zobrazte nápovědu:"
    echo "   uwp --help"
    echo ""
    echo -e "${YELLOW}UWP je nyní připraven k použití!${NC}"
    echo ""
}

# Handle command line arguments
case "$1" in
    --help|-h)
        echo "UWP Auto Installer"
        echo "Usage: ./auto_install.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help"
        echo "  --update      Update existing installation"
        echo "  --uninstall   Remove UWP"
        ;;
        
    --update)
        log_info "Aktualizuji UWP..."
        # Backup configs
        if [ -d "$UWP_HOME/configs" ]; then
            cp -r "$UWP_HOME/configs" /tmp/uwp_configs_backup
        fi
        # Remove old
        rm -rf "$UWP_HOME"
        # Install new
        install
        # Restore configs
        if [ -d "/tmp/uwp_configs_backup" ]; then
            cp -r /tmp/uwp_configs_backup/* "$UWP_HOME/configs/"
        fi
        ;;
        
    --uninstall)
        echo -e "${RED}Opravdu chcete odstranit UWP? [y/N]${NC}"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            rm -rf "$UWP_HOME"
            sudo rm -f "$UWP_BIN"
            # Remove from shell config
            sed -i '/# Universal Workspace Project/,+3d' "$HOME/.bashrc" 2>/dev/null
            sed -i '/# Universal Workspace Project/,+3d' "$HOME/.zshrc" 2>/dev/null
            echo "UWP byl odstraněn"
        else
            echo "Uninstall zrušen"
        fi
        ;;
        
    *)
        install
        ;;
esac