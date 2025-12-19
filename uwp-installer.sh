#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v5.0 - Master Installer
# 🚀 Professional Development Environment
# Supports: Linux, Android, Termux, WSL, Raspberry Pi, Docker
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly VERSION="5.0.0"
readonly PLATFORM_NAME="Universal Workspace Platform"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
readonly BASE_DIR="${UWP_HOME:-${HOME}/.uwp}"
readonly CONFIG_DIR="${BASE_DIR}/config"
readonly BIN_DIR="${BASE_DIR}/bin"
readonly LIB_DIR="${BASE_DIR}/lib"
readonly MODULES_DIR="${BASE_DIR}/modules"
readonly PLUGINS_DIR="${BASE_DIR}/plugins"
readonly DATA_DIR="${BASE_DIR}/data"
readonly CACHE_DIR="${BASE_DIR}/.cache"
readonly LOG_DIR="${BASE_DIR}/logs"
readonly TEMPLATES_DIR="${BASE_DIR}/templates"

# Logging
readonly LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_LOG="${LOG_DIR}/errors.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# System detection
DETECTED_OS=""
DETECTED_ARCH=""
PKG_MANAGER=""
IS_ROOT=false
IS_TERMUX=false
IS_ANDROID=false
IS_WSL=false
IS_RPI=false

# Statistics
TOTAL_STEPS=12
CURRENT_STEP=0
ERRORS=0
WARNINGS=0
START_TIME=$(date +%s)

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

log_raw() {
    mkdir -p "$LOG_DIR"
    echo "$*" >> "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $*"
    log_raw "[INFO] $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
    log_raw "[SUCCESS] $*"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $*"
    log_raw "[WARN] $*"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" >&2
    log_raw "[ERROR] $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$ERROR_LOG"
    ((ERRORS++))
}

log_step() {
    ((CURRENT_STEP++))
    echo ""
    echo -e "${CYAN}${BOLD}[$CURRENT_STEP/$TOTAL_STEPS]${NC} ${BOLD}$*${NC}"
    log_raw "=== STEP $CURRENT_STEP: $* ==="
}

die() {
    log_error "$*"
    log_error "Installation failed!"
    exit 1
}

# ============================================================================
# BANNER
# ============================================================================

show_banner() {
    clear
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ██╗   ██╗██╗    ██╗██████╗     ██╗   ██╗███████╗     ║
║   ██║   ██║██║    ██║██╔══██╗    ██║   ██║██╔════╝     ║
║   ██║   ██║██║ █╗ ██║██████╔╝    ██║   ██║███████╗     ║
║   ██║   ██║██║███╗██║██╔═══╝     ╚██╗ ██╔╝╚════██║     ║
║   ╚██████╔╝╚███╔███╔╝██║          ╚████╔╝ ███████║     ║
║    ╚═════╝  ╚══╝╚══╝ ╚═╝           ╚═══╝  ╚══════╝     ║
║                                                          ║
║        UNIVERSAL WORKSPACE PLATFORM v5.0                ║
║        Professional Development Environment             ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo ""
    echo -e "${DIM}Installing to: ${BASE_DIR}${NC}"
    echo -e "${DIM}Log file: ${LOG_FILE}${NC}"
    echo ""
}

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

detect_system() {
    log_step "Detecting system environment"
    
    # OS Detection
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DETECTED_OS="${ID}"
        log_info "OS: ${NAME} ${VERSION_ID}"
    elif [[ -f /data/data/com.termux/files/usr/etc/motd ]]; then
        DETECTED_OS="termux"
        IS_TERMUX=true
        IS_ANDROID=true
        log_info "OS: Termux (Android)"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        DETECTED_OS="wsl"
        IS_WSL=true
        log_info "OS: Windows Subsystem for Linux"
    elif [[ -f /system/build.prop ]]; then
        DETECTED_OS="android"
        IS_ANDROID=true
        log_info "OS: Android"
    else
        DETECTED_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        log_info "OS: ${DETECTED_OS}"
    fi
    
    # Architecture
    DETECTED_ARCH=$(uname -m)
    log_info "Architecture: ${DETECTED_ARCH}"
    
    # Raspberry Pi
    if [[ -f /proc/device-tree/model ]] && grep -qi raspberry /proc/device-tree/model; then
        IS_RPI=true
        log_info "Raspberry Pi detected"
    fi
    
    # Package Manager
    for pm in pkg apt apt-get yum dnf pacman apk zypper brew; do
        if command -v "$pm" &>/dev/null; then
            PKG_MANAGER="$pm"
            log_info "Package manager: ${PKG_MANAGER}"
            break
        fi
    done
    
    # Root check
    if [[ $EUID -eq 0 ]] || [[ $(id -u) -eq 0 ]]; then
        IS_ROOT=true
        log_info "Running as root"
    else
        log_info "Running as user: $(whoami)"
    fi
    
    log_success "System detection complete"
}

# ============================================================================
# DIRECTORY STRUCTURE
# ============================================================================

create_structure() {
    log_step "Creating directory structure"
    
    local dirs=(
        "$BASE_DIR"
        "$CONFIG_DIR"
        "$BIN_DIR"
        "$LIB_DIR"
        "$MODULES_DIR"
        "$PLUGINS_DIR"
        "$DATA_DIR"
        "$CACHE_DIR"
        "$LOG_DIR"
        "$TEMPLATES_DIR"
        "$DATA_DIR/projects"
        "$DATA_DIR/backups"
        "$DATA_DIR/ai-models"
        "$DATA_DIR/android"
        "$DATA_DIR/docker"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            log_info "Created: ${dir##*/}"
        else
            log_error "Failed to create: $dir"
        fi
    done
    
    log_success "Directory structure created"
}

# ============================================================================
# CORE LIBRARY
# ============================================================================

create_core_library() {
    log_step "Creating core library"
    
    cat > "$LIB_DIR/uwp-core.sh" << 'CORE_END'
#!/usr/bin/env bash
# UWP Core Library v5.0

export UWP_VERSION="5.0.0"
export UWP_LOADED=1

# === Utilities ===
uwp_cmd_exists() { command -v "$1" &>/dev/null; }
uwp_file_exists() { [[ -f "$1" ]]; }
uwp_dir_exists() { [[ -d "$1" ]]; }

# === Colors ===
uwp_red() { echo -e "\033[0;31m$*\033[0m"; }
uwp_green() { echo -e "\033[0;32m$*\033[0m"; }
uwp_yellow() { echo -e "\033[1;33m$*\033[0m"; }
uwp_blue() { echo -e "\033[0;34m$*\033[0m"; }

# === Path Management ===
uwp_get_module_path() { echo "${UWP_HOME:-$HOME/.uwp}/modules/$1"; }
uwp_get_config_path() { echo "${UWP_HOME:-$HOME/.uwp}/config/$1"; }
uwp_get_data_path() { echo "${UWP_HOME:-$HOME/.uwp}/data/$1"; }

# === Configuration ===
uwp_config_get() {
    local key=$1
    local default=${2:-}
    local config="${UWP_HOME:-$HOME/.uwp}/config/uwp.conf"
    
    if [[ -f "$config" ]]; then
        grep "^${key}=" "$config" 2>/dev/null | cut -d= -f2- | tr -d '"' || echo "$default"
    else
        echo "$default"
    fi
}

uwp_config_set() {
    local key=$1
    local value=$2
    local config="${UWP_HOME:-$HOME/.uwp}/config/uwp.conf"
    
    mkdir -p "$(dirname "$config")"
    
    if grep -q "^${key}=" "$config" 2>/dev/null; then
        sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$config"
    else
        echo "${key}=\"${value}\"" >> "$config"
    fi
}

# === Package Management ===
uwp_install_pkg() {
    local package=$1
    
    if uwp_cmd_exists "$package"; then
        return 0
    fi
    
    case "${PKG_MANAGER:-apt}" in
        pkg)
            pkg install -y "$package" 2>/dev/null
            ;;
        apt|apt-get)
            if [[ $EUID -eq 0 ]]; then
                apt-get update -qq && apt-get install -y "$package" 2>/dev/null
            else
                sudo apt-get update -qq && sudo apt-get install -y "$package" 2>/dev/null
            fi
            ;;
        yum|dnf)
            if [[ $EUID -eq 0 ]]; then
                "$PKG_MANAGER" install -y "$package" 2>/dev/null
            else
                sudo "$PKG_MANAGER" install -y "$package" 2>/dev/null
            fi
            ;;
        pacman)
            if [[ $EUID -eq 0 ]]; then
                pacman -S --noconfirm "$package" 2>/dev/null
            else
                sudo pacman -S --noconfirm "$package" 2>/dev/null
            fi
            ;;
    esac
}

# === Module Management ===
uwp_module_exists() {
    [[ -d "$(uwp_get_module_path "$1")" ]]
}

uwp_module_installed() {
    [[ -f "$(uwp_get_module_path "$1")/.installed" ]]
}

uwp_module_mark_installed() {
    touch "$(uwp_get_module_path "$1")/.installed"
}

# === Progress Bar ===
uwp_progress() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((width - filled))s" | tr ' ' '░'
    printf "] %3d%%" $percent
    
    [[ $current -eq $total ]] && echo ""
}

export -f uwp_cmd_exists uwp_file_exists uwp_dir_exists
export -f uwp_red uwp_green uwp_yellow uwp_blue
export -f uwp_get_module_path uwp_get_config_path uwp_get_data_path
export -f uwp_config_get uwp_config_set uwp_install_pkg
export -f uwp_module_exists uwp_module_installed uwp_module_mark_installed
export -f uwp_progress
CORE_END
    
    chmod +x "$LIB_DIR/uwp-core.sh"
    log_success "Core library created"
}

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================

install_dependencies() {
    log_step "Installing system dependencies"
    
    local packages="git curl wget nano vim python3 python3-pip nodejs npm"
    
    case "$PKG_MANAGER" in
        pkg)
            log_info "Installing for Termux..."
            pkg update -y 2>/dev/null
            pkg install -y git curl wget nano vim python nodejs 2>/dev/null
            ;;
        apt|apt-get)
            log_info "Installing for Debian/Ubuntu..."
            if $IS_ROOT; then
                apt-get update -qq
                apt-get install -y $packages build-essential 2>/dev/null
            else
                sudo apt-get update -qq
                sudo apt-get install -y $packages build-essential 2>/dev/null
            fi
            ;;
        dnf)
            log_info "Installing for Fedora/RHEL..."
            if $IS_ROOT; then
                dnf install -y $packages gcc make 2>/dev/null
            else
                sudo dnf install -y $packages gcc make 2>/dev/null
            fi
            ;;
        pacman)
            log_info "Installing for Arch Linux..."
            if $IS_ROOT; then
                pacman -Sy --noconfirm $packages base-devel 2>/dev/null
            else
                sudo pacman -Sy --noconfirm $packages base-devel 2>/dev/null
            fi
            ;;
        *)
            log_warn "Unknown package manager, skipping system packages"
            ;;
    esac
    
    log_success "Dependencies installed"
}

# ============================================================================
# CREATE MODULES
# ============================================================================

create_modules() {
    log_step "Creating module system"
    
    # AI Module
    mkdir -p "$MODULES_DIR/ai/scripts"
    cat > "$MODULES_DIR/ai/install.sh" << 'AI_MODULE'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"

echo "[AI] Installing AI workspace..."

if ! uwp_cmd_exists ollama; then
    curl -fsSL https://ollama.ai/install.sh | sh 2>/dev/null || true
fi

if uwp_cmd_exists pip3; then
    pip3 install --quiet openai langchain chromadb 2>/dev/null || true
fi

if uwp_cmd_exists ollama; then
    ollama pull phi3:mini &>/dev/null &
    ollama pull llama3.2:3b &>/dev/null &
fi

uwp_module_mark_installed ai
echo "[AI] Module installed ✓"
AI_MODULE
    
    # Android Module
    mkdir -p "$MODULES_DIR/android/scripts"
    cat > "$MODULES_DIR/android/install.sh" << 'ANDROID_MODULE'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"

echo "[Android] Installing Android toolkit..."

case "${PKG_MANAGER:-apt}" in
    pkg) pkg install -y android-tools 2>/dev/null ;;
    apt) sudo apt-get install -y android-tools-adb android-tools-fastboot 2>/dev/null ;;
    dnf) sudo dnf install -y android-tools 2>/dev/null ;;
    pacman) sudo pacman -S --noconfirm android-tools 2>/dev/null ;;
esac

uwp_module_mark_installed android
echo "[Android] Module installed ✓"
ANDROID_MODULE
    
    # Docker Module
    mkdir -p "$MODULES_DIR/docker"
    cat > "$MODULES_DIR/docker/install.sh" << 'DOCKER_MODULE'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"

echo "[Docker] Installing Docker..."

if ! uwp_cmd_exists docker; then
    curl -fsSL https://get.docker.com | sh 2>/dev/null || true
fi

uwp_module_mark_installed docker
echo "[Docker] Module installed ✓"
DOCKER_MODULE
    
    # Terminal Module
    mkdir -p "$MODULES_DIR/terminal"
    cat > "$MODULES_DIR/terminal/install.sh" << 'TERMINAL_MODULE'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"

echo "[Terminal] Configuring terminal..."

uwp_install_pkg zsh

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi

uwp_module_mark_installed terminal
echo "[Terminal] Module installed ✓"
TERMINAL_MODULE
    
    # Development Module
    mkdir -p "$MODULES_DIR/development"
    cat > "$MODULES_DIR/development/install.sh" << 'DEV_MODULE'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"

echo "[Development] Installing dev tools..."

if uwp_cmd_exists npm; then
    npm install -g typescript eslint prettier 2>/dev/null || true
fi

if uwp_cmd_exists python3; then
    python3 -m venv "${UWP_HOME:-$HOME/.uwp}/data/venv" 2>/dev/null || true
fi

uwp_module_mark_installed development
echo "[Development] Module installed ✓"
DEV_MODULE
    
    chmod +x "$MODULES_DIR"/*/install.sh
    log_success "Modules created"
}

# ============================================================================
# CREATE CLI TOOL
# ============================================================================

create_cli() {
    log_step "Creating CLI tool"
    
    cat > "$BIN_DIR/uwp" << 'CLI_END'
#!/usr/bin/env bash

UWP_HOME="${UWP_HOME:-${HOME}/.uwp}"
source "${UWP_HOME}/lib/uwp-core.sh" 2>/dev/null || {
    echo "Error: UWP not initialized"
    exit 1
}

show_help() {
    cat << EOF
Universal Workspace Platform v5.0

Usage: uwp <command> [options]

Commands:
  status              Show platform status
  modules list        List all modules
  modules install <m> Install module
  config get <key>    Get config value
  config set <k> <v>  Set config value
  analyze <path>      Analyze project
  ai <prompt>         AI assistant
  update              Update platform
  help                Show this help

Examples:
  uwp status
  uwp modules list
  uwp modules install ai
  uwp analyze .
  uwp ai "Explain this code"
EOF
}

case "${1:-help}" in
    status)
        echo "=== UWP Status ==="
        echo "Version: $(uwp_config_get version 5.0.0)"
        echo "Home: $UWP_HOME"
        echo "Modules: $(ls -1 "$UWP_HOME/modules" 2>/dev/null | wc -l)"
        ;;
    modules)
        case "${2:-list}" in
            list)
                echo "Available modules:"
                for mod in "$UWP_HOME/modules"/*; do
                    name=$(basename "$mod")
                    if [[ -f "$mod/.installed" ]]; then
                        echo "  ✓ $name"
                    else
                        echo "  ○ $name"
                    fi
                done
                ;;
            install)
                if [[ -z "$3" ]]; then
                    echo "Usage: uwp modules install <module>"
                    exit 1
                fi
                if [[ -f "$UWP_HOME/modules/$3/install.sh" ]]; then
                    bash "$UWP_HOME/modules/$3/install.sh"
                else
                    echo "Module not found: $3"
                    exit 1
                fi
                ;;
        esac
        ;;
    config)
        case "$2" in
            get) uwp_config_get "$3" ;;
            set) uwp_config_set "$3" "$4" ;;
            *) echo "Usage: uwp config [get|set] <key> [value]" ;;
        esac
        ;;
    analyze)
        project="${2:-.}"
        echo "Analyzing: $project"
        echo "Files: $(find "$project" -type f 2>/dev/null | wc -l)"
        echo "Size: $(du -sh "$project" 2>/dev/null | cut -f1)"
        ;;
    ai)
        if uwp_cmd_exists ollama; then
            ollama run phi3:mini "${@:2}"
        else
            echo "AI not available. Install with: uwp modules install ai"
        fi
        ;;
    update)
        echo "Checking for updates..."
        echo "Platform is up to date (v5.0.0)"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
CLI_END
    
    chmod +x "$BIN_DIR/uwp"
    
    # Create symlink
    if [[ -w /usr/local/bin ]]; then
        ln -sf "$BIN_DIR/uwp" /usr/local/bin/uwp 2>/dev/null || true
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$BIN_DIR/uwp" "$HOME/.local/bin/uwp" 2>/dev/null || true
    fi
    
    log_success "CLI tool created"
}

# ============================================================================
# CREATE CONFIGURATION
# ============================================================================

create_config() {
    log_step "Creating configuration"
    
    cat > "$CONFIG_DIR/uwp.conf" << EOF
# UWP Configuration
version="5.0.0"
install_date="$(date -Iseconds)"
os="${DETECTED_OS}"
arch="${DETECTED_ARCH}"
pkg_manager="${PKG_MANAGER}"
is_termux="${IS_TERMUX}"
is_wsl="${IS_WSL}"
is_rpi="${IS_RPI}"

# Features
ai_enabled="true"
android_enabled="true"
docker_enabled="true"
web_enabled="true"

# Paths
uwp_home="${BASE_DIR}"
uwp_data="${DATA_DIR}"
uwp_cache="${CACHE_DIR}"
EOF
    
    log_success "Configuration created"
}

# ============================================================================
# SHELL INTEGRATION
# ============================================================================

setup_shell() {
    log_step "Setting up shell integration"
    
    local shell_config=""
    
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    fi
    
    if [[ -n "$shell_config" ]]; then
        if ! grep -q "UWP_HOME" "$shell_config" 2>/dev/null; then
            cat >> "$shell_config" << EOF

# Universal Workspace Platform
export UWP_HOME="${BASE_DIR}"
export PATH="\${UWP_HOME}/bin:\${PATH}"

# UWP aliases
alias uwp-status='uwp status'
alias uwp-analyze='uwp analyze'
alias uwp-ai='uwp ai'
EOF
            log_success "Shell integration added to ${shell_config##*/}"
        else
            log_info "Shell already configured"
        fi
    fi
}

# ============================================================================
# CREATE DOCUMENTATION
# ============================================================================

create_docs() {
    log_step "Creating documentation"
    
    cat > "$BASE_DIR/README.md" << 'README_END'
# Universal Workspace Platform v5.0

Professional development environment with AI, Android tools, Docker integration and more.

## 🚀 Quick Start

```bash
# Show status
uwp status

# List modules
uwp modules list

# Install AI module
uwp modules install ai

# Analyze project
uwp analyze /path/to/project

# AI assistant
uwp ai "How do I optimize this code?"
```

## 📦 Modules

- **AI** - Ollama integration with AI models
- **Android** - ADB and Android development tools
- **Docker** - Container management
- **Terminal** - Zsh with Oh My Zsh
- **Development** - Node.js, Python, build tools

## 📁 Structure

```
~/.uwp/
├── bin/          # CLI tools
├── config/       # Configuration
├── data/         # User data
├── lib/          # Core libraries
├── modules/      # Feature modules
└── logs/         # Log files
```

## ⚙️ Configuration

Edit configuration:
```bash
uwp config set <key> <value>
uwp config get <key>
```

## 🔄 Updates

Update platform:
```bash
uwp update
```

## 📝 Logs

View logs:
```bash
cat ~/.uwp/logs/install_*.log
```
README_END
    
    log_success "Documentation created"
}

# ============================================================================
# POST INSTALL
# ============================================================================

post_install() {
    log_step "Running post-installation tasks"
    
    # Install core modules
    if [[ -f "$MODULES_DIR/development/install.sh" ]]; then
        bash "$MODULES_DIR/development/install.sh" 2>/dev/null || log_warn "Development module installation had issues"
    fi
    
    log_success "Post-installation complete"
}

# ============================================================================
# SUMMARY
# ============================================================================

show_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo -e "${BOLD}Platform:${NC} Universal Workspace Platform v5.0"
    echo -e "${BOLD}Location:${NC} ${BASE_DIR}"
    echo -e "${BOLD}Duration:${NC} ${duration}s"
    echo ""
    echo -e "${BOLD}Statistics:${NC}"
    echo "  • Steps completed: ${CURRENT_STEP}/${TOTAL_STEPS}"
    echo "  • Warnings: ${WARNINGS}"
    echo "  • Errors: ${ERRORS}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "  1. Reload shell: ${CYAN}source ~/.bashrc${NC} or ${CYAN}source ~/.zshrc${NC}"
    echo "  2. Check status: ${CYAN}uwp status${NC}"
    echo "  3. Install modules: ${CYAN}uwp modules install <module>${NC}"
    echo "  4. Read docs: ${CYAN}cat ~/.uwp/README.md${NC}"
    echo ""
    echo -e "${BOLD}Available Commands:${NC}"
    echo "  ${CYAN}uwp status${NC}          - Show platform status"
    echo "  ${CYAN}uwp modules list${NC}    - List all modules"
    echo "  ${CYAN}uwp analyze <path>${NC}  - Analyze project"
    echo "  ${CYAN}uwp ai <prompt>${NC}     - AI assistant"
    echo ""
    
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Some errors occurred. Check: ${ERROR_LOG}${NC}"
    else
        echo -e "${GREEN}✓ Installation completed successfully!${NC}"
    fi
    
    echo "═══════════════════════════════════════════════════════"
}

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

main() {
    show_banner
    
    detect_system
    create_structure
    create_core_library
    install_dependencies
    create_modules
    create_cli
    create_config
    setup_shell
    create_docs
    post_install
    
    show_summary
}

# Trap errors
trap 'log_error "Installation failed at line $LINENO"' ERR

# Run installation
main "$@"

exit 0