#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - Master Installer
# 🚀 Professional All-in-One Installation System
# Supports: Linux, Raspberry Pi, WSL, Termux, Android, Docker
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# KONFIGURACE A GLOBÁLNÍ PROMĚNNÉ
# ============================================================================

readonly SCRIPT_VERSION="4.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Adresářové struktury
readonly BASE_DIR="${UWP_BASE_DIR:-${HOME}/.universal-workspace}"
readonly CONFIG_DIR="${UWP_CONFIG_DIR:-${BASE_DIR}/config}"
readonly BIN_DIR="${UWP_BIN_DIR:-${BASE_DIR}/bin}"
readonly LIB_DIR="${UWP_LIB_DIR:-${BASE_DIR}/lib}"
readonly MODULES_DIR="${UWP_MODULES_DIR:-${BASE_DIR}/modules}"
readonly PLUGINS_DIR="${UWP_PLUGINS_DIR:-${BASE_DIR}/plugins}"
readonly CACHE_DIR="${UWP_CACHE_DIR:-${BASE_DIR}/.cache}"
readonly LOG_DIR="${UWP_LOG_DIR:-${BASE_DIR}/logs}"
readonly DATA_DIR="${UWP_DATA_DIR:-${BASE_DIR}/data}"
readonly TEMPLATES_DIR="${UWP_TEMPLATES_DIR:-${BASE_DIR}/templates}"
readonly REPORTS_DIR="${UWP_REPORTS_DIR:-${BASE_DIR}/reports}"

# Logy
readonly LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
readonly ERROR_LOG="${LOG_DIR}/errors.log"

# Barvy a formátování
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Detekované systémové informace
DETECTED_OS=""
DETECTED_ARCH=""
DETECTED_PKG_MANAGER=""
IS_ROOT=false
IS_TERMUX=false
IS_ANDROID=false
IS_WSL=false
IS_DOCKER=false
IS_RASPBERRY_PI=false

# Instalační statistiky
MODULES_INSTALLED=0
PACKAGES_INSTALLED=0
ERRORS_COUNT=0
WARNINGS_COUNT=0
INSTALL_START_TIME=""
INSTALL_END_TIME=""

# ============================================================================
# LOGGING SISTEM
# ============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    
    case "$level" in
        ERROR)
            echo -e "${RED}[✗]${NC} ${message}" >&2
            echo "[${timestamp}] [ERROR] ${message}" >> "${ERROR_LOG}"
            ((ERRORS_COUNT++))
            ;;
        WARN)
            echo -e "${YELLOW}[⚠]${NC} ${message}"
            ((WARNINGS_COUNT++))
            ;;
        INFO)
            echo -e "${GREEN}[i]${NC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[✓]${NC} ${message}"
            ;;
        DEBUG)
            [[ "${DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} ${message}"
            ;;
        STEP)
            echo -e "\n${CYAN}${BOLD}▶${NC} ${BOLD}${message}${NC}"
            ;;
    esac
}

log_info() { log INFO "$@"; }
log_warn() { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_success() { log SUCCESS "$@"; }
log_debug() { log DEBUG "$@"; }
log_step() { log STEP "$@"; }

die() {
    log_error "$@"
    exit 1
}

# ============================================================================
# DETEKCE SYSTÉMU
# ============================================================================

detect_system() {
    log_step "Detekce systému a prostředí"
    
    # Detekce OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DETECTED_OS="${ID}"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        DETECTED_OS="wsl"
        IS_WSL=true
    elif [[ -f /system/build.prop ]] || [[ -d /data/data ]]; then
        DETECTED_OS="android"
        IS_ANDROID=true
    fi
    
    # Detekce Termux
    [[ -f /etc/termux.properties ]] || [[ -d /data/data/com.termux ]] && IS_TERMUX=true
    
    # Detekce Raspberry Pi
    if [[ -f /proc/device-tree/model ]]; then
        if grep -qi "raspberry" /proc/device-tree/model; then
            IS_RASPBERRY_PI=true
        fi
    fi
    
    # Detekce Docker
    [[ -f /.dockerenv ]] && IS_DOCKER=true
    
    # Detekce architektury
    DETECTED_ARCH=$(uname -m)
    
    # Detekce správce balíčků
    for pm in pkg apt apt-get yum dnf pacman apk zypper brew nix-env; do
        if command -v "$pm" &>/dev/null; then
            DETECTED_PKG_MANAGER="$pm"
            break
        fi
    done
    
    # Detekce root oprávnění
    [[ $EUID -eq 0 ]] && IS_ROOT=true
    
    # Výstup informací
    log_success "OS: ${DETECTED_OS} | Arch: ${DETECTED_ARCH}"
    log_success "Package Manager: ${DETECTED_PKG_MANAGER}"
    log_success "Termux: ${IS_TERMUX} | WSL: ${IS_WSL} | Docker: ${IS_DOCKER} | RPi: ${IS_RASPBERRY_PI}"
}

# ============================================================================
# INICIALIZACE STRUKTURY
# ============================================================================

initialize_structure() {
    log_step "Inicializace adresářové struktury"
    
    local dirs=(
        "$BASE_DIR"
        "$CONFIG_DIR"
        "$BIN_DIR"
        "$LIB_DIR"
        "$MODULES_DIR"
        "$PLUGINS_DIR"
        "$CACHE_DIR"
        "$LOG_DIR"
        "$DATA_DIR"
        "$TEMPLATES_DIR"
        "$REPORTS_DIR"
        "$DATA_DIR/projects"
        "$DATA_DIR/backups"
        "$DATA_DIR/sessions"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" || die "Nelze vytvořit adresář: $dir"
    done
    
    log_success "Struktura vytvořena: $BASE_DIR"
}

# ============================================================================
# CORE LIBRARY
# ============================================================================

create_core_library() {
    log_step "Vytváření core knihovny"
    
    cat > "$LIB_DIR/uwp-core.sh" << 'CORE_LIB'
#!/usr/bin/env bash
# Universal Workspace Platform - Core Library

export UWP_LOADED=1

# ──── Utilities ────
uwp_command_exists() {
    command -v "$1" &>/dev/null
}

uwp_require_command() {
    local cmd=$1
    if ! uwp_command_exists "$cmd"; then
        echo "ERROR: Command not found: $cmd" >&2
        return 1
    fi
    return 0
}

uwp_file_exists() {
    [[ -f "$1" ]]
}

uwp_dir_exists() {
    [[ -d "$1" ]]
}

# ──── Path Management ────
uwp_get_module_path() {
    echo "${UWP_MODULES_DIR}/$1"
}

uwp_get_config_path() {
    echo "${UWP_CONFIG_DIR}/$1"
}

uwp_get_data_path() {
    echo "${UWP_DATA_DIR}/$1"
}

# ──── Package Management ────
uwp_install_package() {
    local package=$1
    local package_manager=${2:-${DETECTED_PKG_MANAGER}}
    
    if uwp_command_exists "$package"; then
        return 0
    fi
    
    case "$package_manager" in
        apt|apt-get)
            apt-get update &>/dev/null
            apt-get install -y "$package" &>/dev/null
            ;;
        pkg)
            pkg install -y "$package" &>/dev/null
            ;;
        yum|dnf)
            "$package_manager" install -y "$package" &>/dev/null
            ;;
        pacman)
            pacman -S --noconfirm "$package" &>/dev/null
            ;;
        apk)
            apk add "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# ──── String Utils ────
uwp_trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

uwp_to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

uwp_to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# ──── Validation ────
uwp_validate_json() {
    if ! command -v jq &>/dev/null; then
        return 1
    fi
    jq empty "$1" 2>/dev/null
}

uwp_validate_url() {
    [[ $1 =~ ^https?:// ]]
}

# ──── Module Management ────
uwp_module_exists() {
    [[ -d "$(uwp_get_module_path "$1")" ]]
}

uwp_module_is_installed() {
    [[ -f "$(uwp_get_module_path "$1")/.installed" ]]
}

uwp_module_mark_installed() {
    touch "$(uwp_get_module_path "$1")/.installed"
}

# ──── Configuration ────
uwp_config_get() {
    local key=$1
    local default=${2:-}
    local config_file="${UWP_CONFIG_DIR}/uwp.conf"
    
    if [[ -f "$config_file" ]]; then
        grep "^${key}=" "$config_file" | cut -d= -f2- | tr -d '"' || echo "$default"
    else
        echo "$default"
    fi
}

uwp_config_set() {
    local key=$1
    local value=$2
    local config_file="${UWP_CONFIG_DIR}/uwp.conf"
    
    mkdir -p "${UWP_CONFIG_DIR}"
    
    if grep -q "^${key}=" "$config_file" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$config_file"
    else
        echo "${key}=\"${value}\"" >> "$config_file"
    fi
}

# ──── Progress ────
uwp_progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' ' '
    printf "] %3d%%" $percent
    
    [[ $current -eq $total ]] && echo ""
}

export -f uwp_command_exists uwp_require_command uwp_file_exists uwp_dir_exists
export -f uwp_get_module_path uwp_get_config_path uwp_get_data_path
export -f uwp_install_package uwp_trim uwp_to_lower uwp_to_upper
export -f uwp_validate_json uwp_validate_url uwp_module_exists
export -f uwp_module_is_installed uwp_module_mark_installed uwp_config_get uwp_config_set
export -f uwp_progress_bar
CORE_LIB
    
    chmod +x "$LIB_DIR/uwp-core.sh"
    log_success "Core knihovna vytvořena"
}

# ============================================================================
# MODULÁRNÍ SYSTÉM
# ============================================================================

create_module_system() {
    log_step "Vytváření modulárního systému"
    
    # Module registry
    cat > "$CONFIG_DIR/modules.json" << 'MODULE_JSON'
{
  "modules": {
    "ai": {
      "name": "AI Workspace",
      "enabled": true,
      "priority": 10,
      "dependencies": [],
      "installer": "modules/ai/install.sh"
    },
    "android": {
      "name": "Android Toolkit",
      "enabled": true,
      "priority": 20,
      "dependencies": [],
      "installer": "modules/android/install.sh"
    },
    "docker": {
      "name": "Docker Environment",
      "enabled": true,
      "priority": 30,
      "dependencies": [],
      "installer": "modules/docker/install.sh"
    },
    "development": {
      "name": "Development Tools",
      "enabled": true,
      "priority": 5,
      "dependencies": [],
      "installer": "modules/development/install.sh"
    },
    "terminal": {
      "name": "Terminal Configuration",
      "enabled": true,
      "priority": 1,
      "dependencies": [],
      "installer": "modules/terminal/install.sh"
    }
  }
}
MODULE_JSON
    
    log_success "Modulární systém inicializován"
}

# ============================================================================
# VYTVÁŘENÍ MODULŮ
# ============================================================================

create_ai_module() {
    log_step "Vytváření AI modulu"
    
    local module_dir="$MODULES_DIR/ai"
    mkdir -p "$module_dir/scripts"
    
    # AI installer
    cat > "$module_dir/install.sh" << 'AI_INSTALL'
#!/usr/bin/env bash
source "${UWP_LIB_DIR}/uwp-core.sh"

MODULE_NAME="ai"
MODULE_DIR=$(uwp_get_module_path "$MODULE_NAME")

install_ai_module() {
    echo "[AI] Instaluji AI workspace..."
    
    # Ollama
    if ! command -v ollama &>/dev/null; then
        curl -fsSL https://ollama.ai/install.sh | sh 2>/dev/null || \
        uwp_install_package ollama
    fi
    
    # Python AI libraries
    if command -v pip3 &>/dev/null; then
        pip3 install --quiet \
            openai torch transformers langchain \
            chromadb sentence-transformers 2>/dev/null || true
    fi
    
    # Download models
    if command -v ollama &>/dev/null; then
        ollama pull phi3:mini &
        ollama pull llama3.2:3b &
        wait
    fi
    
    uwp_module_mark_installed "$MODULE_NAME"
    echo "[AI] Modul nainstalován ✓"
}

install_ai_module
AI_INSTALL
    
    # AI scripts
    cat > "$module_dir/scripts/analyze.sh" << 'AI_ANALYZE'
#!/usr/bin/env bash
PROJECT="${1:-.}"
echo "🔍 Analyzing: $PROJECT"

if ! command -v ollama &>/dev/null; then
    echo "Ollama not found"
    exit 1
fi

echo "Collecting project info..."
du -sh "$PROJECT"
find "$PROJECT" -type f | wc -l

echo "Running AI analysis..."
ollama run phi3:mini "Analyze this project structure: $(find "$PROJECT" -type f -name '*.js' -o -name '*.py' | head -5)"
AI_ANALYZE
    
    chmod +x "$module_dir/install.sh"
    chmod +x "$module_dir/scripts/analyze.sh"
    log_success "AI modul vytvořen"
}

create_android_module() {
    log_step "Vytváření Android modulu"
    
    local module_dir="$MODULES_DIR/android"
    mkdir -p "$module_dir/scripts"
    
    # Android installer
    cat > "$module_dir/install.sh" << 'ANDROID_INSTALL'
#!/usr/bin/env bash
source "${UWP_LIB_DIR}/uwp-core.sh"

MODULE_NAME="android"
MODULE_DIR=$(uwp_get_module_path "$MODULE_NAME")

install_android_module() {
    echo "[Android] Instaluji Android toolkit..."
    
    # ADB and Fastboot
    case "$DETECTED_PKG_MANAGER" in
        apt) apt-get update && apt-get install -y android-tools-adb android-tools-fastboot ;;
        pkg) pkg install -y android-tools ;;
        dnf) dnf install -y android-tools ;;
        pacman) pacman -S --noconfirm android-tools ;;
        *) echo "Manual installation required for ADB/Fastboot" ;;
    esac
    
    # Udev rules
    cat > /etc/udev/rules.d/51-android.rules << 'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
EOF
    
    udevadm control --reload-rules 2>/dev/null || true
    
    uwp_module_mark_installed "$MODULE_NAME"
    echo "[Android] Modul nainstalován ✓"
}

install_android_module
ANDROID_INSTALL
    
    chmod +x "$module_dir/install.sh"
    log_success "Android modul vytvořen"
}

create_docker_module() {
    log_step "Vytváření Docker modulu"
    
    local module_dir="$MODULES_DIR/docker"
    mkdir -p "$module_dir"
    
    # Docker installer
    cat > "$module_dir/install.sh" << 'DOCKER_INSTALL'
#!/usr/bin/env bash
source "${UWP_LIB_DIR}/uwp-core.sh"

MODULE_NAME="docker"
MODULE_DIR=$(uwp_get_module_path "$MODULE_NAME")

install_docker_module() {
    echo "[Docker] Instaluji Docker environment..."
    
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh 2>/dev/null || \
        uwp_install_package docker
    fi
    
    if ! command -v docker-compose &>/dev/null; then
        curl -fsSL https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose 2>/dev/null
        chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
    fi
    
    uwp_module_mark_installed "$MODULE_NAME"
    echo "[Docker] Modul nainstalován ✓"
}

install_docker_module
DOCKER_INSTALL
    
    chmod +x "$module_dir/install.sh"
    log_success "Docker modul vytvořen"
}

create_development_module() {
    log_step "Vytváření Development modulu"
    
    local module_dir="$MODULES_DIR/development"
    mkdir -p "$module_dir"
    
    cat > "$module_dir/install.sh" << 'DEV_INSTALL'
#!/usr/bin/env bash
source "${UWP_LIB_DIR}/uwp-core.sh"

MODULE_NAME="development"
MODULE_DIR=$(uwp_get_module_path "$MODULE_NAME")

install_dev_module() {
    echo "[Dev] Instaluji development tools..."
    
    # Core tools
    local tools="git curl wget nano vim python3 python3-pip nodejs npm"
    
    case "$DETECTED_PKG_MANAGER" in
        apt)
            apt-get update && apt-get install -y $tools build-essential
            ;;
        pkg)
            pkg install -y $tools
            ;;
        dnf)
            dnf install -y $tools gcc make
            ;;
        pacman)
            pacman -S --noconfirm $tools base-devel
            ;;
    esac
    
    # Python venv
    if command -v python3 &>/dev/null; then
        python3 -m venv "${UWP_DATA_DIR}/venv" 2>/dev/null || true
    fi
    
    # NPM packages
    if command -v npm &>/dev/null; then
        npm install -g typescript eslint prettier ts-node 2>/dev/null || true
    fi
    
    uwp_module_mark_installed "$MODULE_NAME"
    echo "[Dev] Modul nainstalován ✓"
}

install_dev_module
DEV_INSTALL
    
    chmod +x "$module_dir/install.sh"
    log_success "Development modul vytvořen"
}

create_terminal_module() {
    log_step "Vytváření Terminal modulu"
    
    local module_dir="$MODULES_DIR/terminal"
    mkdir -p "$module_dir"
    
    cat > "$module_dir/install.sh" << 'TERM_INSTALL'
#!/usr/bin/env bash
source "${UWP_LIB_DIR}/uwp-core.sh"

MODULE_NAME="terminal"
MODULE_DIR=$(uwp_get_module_path "$MODULE_NAME")

install_terminal_module() {
    echo "[Terminal] Konfiguruji terminal..."
    
    # Install zsh
    uwp_install_package zsh
    
    # Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
    fi
    
    # Zsh plugins
    local zsh_custom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
    mkdir -p "$zsh_custom/plugins"
    
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$zsh_custom/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        "$zsh_custom/plugins/zsh-autosuggestions" 2>/dev/null || true
    
    uwp_module_mark_installed "$MODULE_NAME"
    echo "[Terminal] Modul nainstalován ✓"
}

install_terminal_module
TERM_INSTALL
    
    chmod +x "$module_dir/install.sh"
    log_success "Terminal modul vytvořen"
}

# ============================================================================
# HLAVNÍ CLI NÁSTROJ
# ============================================================================

create_main_cli() {
    log_step "Vytváření hlavního CLI nástroje"
    
    cat > "$BIN_DIR/uwp" << 'UWP_CLI'
#!/usr/bin/env bash

UWP_HOME="${UWP_HOME:-${HOME}/.universal-workspace}"
UWP_LIB_DIR="${UWP_HOME}/lib"

source "${UWP_LIB_DIR}/uwp-core.sh" || exit 1

show_help() {
    cat << EOF
Universal Workspace Platform v4.0

Usage: uwp <command> [options]

Commands:
  status          Show system status
  modules list    List all modules
  modules install <module>  Install specific module
  config get <key>          Get configuration value
  config set <key> <value>  Set configuration value
  analyze <path>  Analyze project
  ai <prompt>     Chat with AI
  update          Update platform
  help            Show this help

Examples:
  uwp status
  uwp modules list
  uwp modules install ai
  uwp ai "Explain this code"
  uwp analyze .
EOF
}

case "${1:-help}" in
    status)
        echo "=== Universal Workspace Platform Status ==="
        echo "Version: 4.0.0"
        echo "Base Dir: $UWP_HOME"
        echo "Modules: $(ls -1 "${UWP_HOME}/modules" 2>/dev/null | wc -l)"
        ;;
    modules)
        case "${2:-help}" in
            list)
                ls -1 "${UWP_HOME}/modules" 2>/dev/null || echo "No modules found"
                ;;
            install)
                if [[ -z "$3" ]]; then
                    echo "Usage: uwp modules install <module>"
                    exit 1
                fi
                bash "${UWP_HOME}/modules/$3/install.sh"
                ;;
            *)
                echo "Usage: uwp modules [list|install <module>]"
                ;;
        esac
        ;;
    config)
        case "${2:-help}" in
            get)
                uwp_config_get "$3"
                ;;
            set)
                uwp_config_set "$3" "$4"
                ;;
            *)
                echo "Usage: uwp config [get|set] <key> [value]"
                ;;
        esac
        ;;
    analyze)
        bash "${UWP_HOME}/modules/ai/scripts/analyze.sh" "${2:-.}"
        ;;
    ai)
        if command -v ollama &>/dev/null; then
            ollama run phi3:mini "${@:2}"
        else
            echo "Ollama not installed"
            exit 1
        fi
        ;;
    update)
        echo "Updating platform..."
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
UWP_CLI
    
    chmod +x "$BIN_DIR/uwp"
    
    # Create symlink
    sudo ln -sf "$BIN_DIR/uwp" /usr/local/bin/uwp 2>/dev/null || \
    ln -sf "$BIN_DIR/uwp" "$HOME/.local/bin/uwp" 2>/dev/null || true
    
    log_success "CLI nástroj vytvořen"
}

# ============================================================================
# INSTALACE MODULŮ
# ============================================================================

install_modules() {
    log_step "Instalace modulů"
    
    create_ai_module
    create_android_module
    create_docker_module
    create_development_module
    create_terminal_module
    
    # Sp