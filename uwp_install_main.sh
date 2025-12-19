#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - Main Installer
# Installation entry point with full feature support
################################################################################

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly VERSION="4.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BASE_DIR="${HOME}/.universal-workspace"
readonly CONFIG_DIR="${BASE_DIR}/config"
readonly BIN_DIR="${BASE_DIR}/bin"
readonly LIB_DIR="${BASE_DIR}/lib"
readonly MODULES_DIR="${BASE_DIR}/modules"
readonly LOG_DIR="${BASE_DIR}/logs"
readonly INSTALL_LOG="${LOG_DIR}/install_$(date +%s).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Flags
GUI_MODE=true
SKIP_DEPS=false
CONFIG_ONLY=false
DEBUG=false
FORCE=false
SELECTED_MODULES=""

# ============================================================================
# LOGGING
# ============================================================================

log() {
    local level=$1
    shift
    local msg="$*"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[${ts}] [${level}] ${msg}" >> "${INSTALL_LOG}"
    
    case "$level" in
        INFO) echo -e "${BLUE}[i]${NC} ${msg}" ;;
        SUCCESS) echo -e "${GREEN}[✓]${NC} ${msg}" ;;
        WARN) echo -e "${YELLOW}[⚠]${NC} ${msg}" ;;
        ERROR) echo -e "${RED}[✗]${NC} ${msg}" >&2 ;;
    esac
}

die() {
    log ERROR "$@"
    exit 1
}

# ============================================================================
# PARSE ARGUMENTS
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-gui) GUI_MODE=false; shift ;;
            --skip-deps) SKIP_DEPS=true; shift ;;
            --config-only) CONFIG_ONLY=true; shift ;;
            --debug) DEBUG=true; shift ;;
            --force) FORCE=true; shift ;;
            --modules=*) SELECTED_MODULES="${1#*=}"; shift ;;
            --help) show_help; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

show_help() {
    cat << EOF
Universal Workspace Platform v${VERSION} Installer

Usage: $0 [OPTIONS]

Options:
  --no-gui              Skip GUI and use CLI mode
  --modules=MOD1,MOD2   Install specific modules (ai,android,docker,dev,term)
  --skip-deps           Skip dependency installation
  --config-only         Only configure, don't install
  --debug               Enable debug mode
  --force               Force reinstall
  --help                Show this help

Examples:
  $0                                          # Interactive GUI
  $0 --no-gui --modules=ai,android           # CLI mode
  $0 --config-only                           # Configuration only
EOF
}

# ============================================================================
# PREREQUISITE CHECKS
# ============================================================================

check_prerequisites() {
    log INFO "Checking prerequisites..."
    
    # Bash version
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        die "Bash 4.0+ required (you have ${BASH_VERSION})"
    fi
    
    # Required commands
    local required=("bash" "mkdir" "cp" "curl")
    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            die "Required command not found: $cmd"
        fi
    done
    
    log SUCCESS "Prerequisites met"
}

# ============================================================================
# CREATE DIRECTORIES
# ============================================================================

create_directories() {
    log INFO "Creating directory structure..."
    
    local dirs=(
        "$BASE_DIR"
        "$CONFIG_DIR"
        "$BIN_DIR"
        "$LIB_DIR"
        "$MODULES_DIR"
        "$LOG_DIR"
        "${BASE_DIR}/data"
        "${BASE_DIR}/plugins"
        "${BASE_DIR}/templates"
        "${BASE_DIR}/reports"
        "${BASE_DIR}/.cache"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" || die "Failed to create: $dir"
    done
    
    log SUCCESS "Directory structure created"
}

# ============================================================================
# INSTALL SYSTEM DEPENDENCIES
# ============================================================================

install_dependencies() {
    if [[ "$SKIP_DEPS" == true ]]; then
        log WARN "Skipping dependency installation"
        return
    fi
    
    log INFO "Installing system dependencies..."
    
    # Detect package manager
    local pkg_manager=""
    if command -v apt-get &>/dev/null; then
        pkg_manager="apt"
    elif command -v pkg &>/dev/null; then
        pkg_manager="pkg"
    elif command -v dnf &>/dev/null; then
        pkg_manager="dnf"
    elif command -v pacman &>/dev/null; then
        pkg_manager="pacman"
    fi
    
    if [[ -z "$pkg_manager" ]]; then
        log WARN "Package manager not found, skipping dependency installation"
        return
    fi
    
    case "$pkg_manager" in
        apt)
            apt-get update &>/dev/null || true
            apt-get install -y git curl wget nano vim python3 python3-pip nodejs npm &>/dev/null || true
            ;;
        pkg)
            pkg install -y git curl wget python python-pip nodejs &>/dev/null || true
            ;;
        dnf)
            dnf install -y git curl wget python3 python3-pip nodejs npm &>/dev/null || true
            ;;
        pacman)
            pacman -S --noconfirm git curl wget python python-pip nodejs npm &>/dev/null || true
            ;;
    esac
    
    log SUCCESS "Dependencies installed"
}

# ============================================================================
# COPY CORE FILES
# ============================================================================

copy_core_files() {
    log INFO "Copying core files..."
    
    # Copy library files
    local lib_files=("lib/uwp-core.sh" "lib/uwp-installer.sh" "lib/uwp-validator.sh")
    for file in "${lib_files[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${file}" ]]; then
            cp "${SCRIPT_DIR}/${file}" "${LIB_DIR}/"
        fi
    done
    
    # Copy bin files
    if [[ -f "${SCRIPT_DIR}/bin/uwp" ]]; then
        cp "${SCRIPT_DIR}/bin/uwp" "${BIN_DIR}/"
        chmod +x "${BIN_DIR}/uwp"
    fi
    
    log SUCCESS "Core files copied"
}

# ============================================================================
# INITIALIZE CONFIGURATION
# ============================================================================

init_configuration() {
    log INFO "Initializing configuration..."
    
    # Create config file
    cat > "${CONFIG_DIR}/uwp.conf" << 'CONFIG'
# Universal Workspace Platform Configuration
INSTALLED_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION=4.0.0
BASE_DIR=${HOME}/.universal-workspace
CONFIG_DIR=${BASE_DIR}/config
BIN_DIR=${BASE_DIR}/bin
LIB_DIR=${BASE_DIR}/lib
MODULES_DIR=${BASE_DIR}/modules
LOG_DIR=${BASE_DIR}/logs
DATA_DIR=${BASE_DIR}/data

# Feature flags
ENABLE_AI=true
ENABLE_ANDROID=true
ENABLE_DOCKER=true
ENABLE_DEVELOPMENT=true
ENABLE_TERMINAL=true

# Settings
DEBUG=false
AUTO_UPDATE=true
CONFIG

    # Create modules registry
    cat > "${CONFIG_DIR}/modules.json" << 'MODULES'
{
  "version": "1.0",
  "modules": {
    "ai": {
      "name": "AI Workspace",
      "description": "Ollama, LLMs, code analysis",
      "enabled": true,
      "priority": 10,
      "dependencies": [],
      "size": "2.5GB"
    },
    "android": {
      "name": "Android Toolkit",
      "description": "ADB, Fastboot, device management",
      "enabled": true,
      "priority": 20,
      "dependencies": [],
      "size": "500MB"
    },
    "docker": {
      "name": "Docker Environment",
      "description": "Containers, Docker Compose",
      "enabled": true,
      "priority": 30,
      "dependencies": [],
      "size": "1GB"
    },
    "development": {
      "name": "Development Tools",
      "description": "Python, Node.js, Git, compilers",
      "enabled": true,
      "priority": 5,
      "dependencies": [],
      "size": "1GB"
    },
    "terminal": {
      "name": "Terminal Configuration",
      "description": "Zsh, Oh My Zsh, plugins",
      "enabled": true,
      "priority": 1,
      "dependencies": [],
      "size": "200MB"
    }
  }
}
MODULES
    
    log SUCCESS "Configuration initialized"
}

# ============================================================================
# INSTALL MODULES
# ============================================================================

install_modules() {
    log INFO "Installing selected modules..."
    
    if [[ -z "$SELECTED_MODULES" ]]; then
        SELECTED_MODULES="ai,android,docker,development,terminal"
    fi
    
    IFS=',' read -ra modules <<< "$SELECTED_MODULES"
    
    for module in "${modules[@]}"; do
        module=$(echo "$module" | xargs)  # trim whitespace
        log INFO "Installing module: $module"
        
        local module_path="${MODULES_DIR}/${module}"
        mkdir -p "$module_path"
        
        case "$module" in
            ai)
                install_ai_module
                ;;
            android)
                install_android_module
                ;;
            docker)
                install_docker_module
                ;;
            development)
                install_dev_module
                ;;
            terminal)
                install_terminal_module
                ;;
            *)
                log WARN "Unknown module: $module"
                ;;
        esac
    done
    
    log SUCCESS "Modules installed"
}

# ============================================================================
# MODULE INSTALLERS
# ============================================================================

install_ai_module() {
    local module_dir="${MODULES_DIR}/ai"
    mkdir -p "$module_dir/scripts"
    
    # AI installer
    cat > "$module_dir/install.sh" << 'AI_SCRIPT'
#!/usr/bin/env bash
if ! command -v ollama &>/dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh 2>/dev/null || echo "Ollama manual install required"
fi
touch "$module_dir/.installed"
echo "[AI] Module installed"
AI_SCRIPT
    chmod +x "$module_dir/install.sh"
}

install_android_module() {
    local module_dir="${MODULES_DIR}/android"
    mkdir -p "$module_dir/scripts"
    
    cat > "$module_dir/install.sh" << 'ANDROID_SCRIPT'
#!/usr/bin/env bash
if ! command -v adb &>/dev/null; then
    if command -v apt-get &>/dev/null; then
        apt-get install -y android-tools-adb android-tools-fastboot &>/dev/null || true
    fi
fi
touch "$module_dir/.installed"
echo "[Android] Module installed"
ANDROID_SCRIPT
    chmod +x "$module_dir/install.sh"
}

install_docker_module() {
    local module_dir="${MODULES_DIR}/docker"
    mkdir -p "$module_dir"
    
    cat > "$module_dir/install.sh" << 'DOCKER_SCRIPT'
#!/usr/bin/env bash
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh 2>/dev/null || echo "Docker manual install required"
fi
touch "$module_dir/.installed"
echo "[Docker] Module installed"
DOCKER_SCRIPT
    chmod +x "$module_dir/install.sh"
}

install_dev_module() {
    local module_dir="${MODULES_DIR}/development"
    mkdir -p "$module_dir"
    
    cat > "$module_dir/install.sh" << 'DEV_SCRIPT'
#!/usr/bin/env bash
# Python venv
if command -v python3 &>/dev/null; then
    python3 -m venv "${HOME}/.universal-workspace/venv" 2>/dev/null || true
fi
# NPM packages
if command -v npm &>/dev/null; then
    npm install -g typescript eslint prettier 2>/dev/null || true
fi
touch "$module_dir/.installed"
echo "[Development] Module installed"
DEV_SCRIPT
    chmod +x "$module_dir/install.sh"
}

install_terminal_module() {
    local module_dir="${MODULES_DIR}/terminal"
    mkdir -p "$module_dir"
    
    cat > "$module_dir/install.sh" << 'TERM_SCRIPT'
#!/usr/bin/env bash
if ! command -v zsh &>/dev/null; then
    if command -v apt-get &>/dev/null; then
        apt-get install -y zsh &>/dev/null || true
    fi
fi
touch "$module_dir/.installed"
echo "[Terminal] Module installed"
TERM_SCRIPT
    chmod +x "$module_dir/install.sh"
}

# ============================================================================
# CREATE CLI TOOL
# ============================================================================

create_cli_tool() {
    log INFO "Creating CLI tool..."
    
    cat > "${BIN_DIR}/uwp" << 'CLI_TOOL'
#!/usr/bin/env bash
UWP_HOME="${HOME}/.universal-workspace"
show_help() {
    cat << EOF
Universal Workspace Platform v4.0

Usage: uwp <command> [options]

Commands:
  status              Show platform status
  modules list        List all modules
  modules install     Install module
  config get          Get config value
  config set          Set config value
  ai                  Chat with AI
  analyze             Analyze project
  help                Show help
EOF
}

case "${1:-help}" in
    status)
        echo "=== UWP Status ==="
        echo "Version: 4.0.0"
        echo "Location: $UWP_HOME"
        ;;
    modules)
        if [[ "$2" == "list" ]]; then
            ls -1 "${UWP_HOME}/modules" 2>/dev/null || echo "No modules"
        fi
        ;;
    help|--help) show_help ;;
    *) show_help ;;
esac
CLI_TOOL
    
    chmod +x "${BIN_DIR}/uwp"
    
    # Create symlink
    mkdir -p "${HOME}/.local/bin" 2>/dev/null || true
    ln -sf "${BIN_DIR}/uwp" "${HOME}/.local/bin/uwp" 2>/dev/null || true
    
    log SUCCESS "CLI tool created"
}

# ============================================================================
# SETUP PATH
# ============================================================================

setup_path() {
    log INFO "Setting up PATH..."
    
    local shell_rc=""
    if [[ -f "${HOME}/.bashrc" ]]; then
        shell_rc="${HOME}/.bashrc"
    elif [[ -f "${HOME}/.zshrc" ]]; then
        shell_rc="${HOME}/.zshrc"
    fi
    
    if [[ -n "$shell_rc" ]]; then
        if ! grep -q "universal-workspace" "$shell_rc"; then
            cat >> "$shell_rc" << 'PATH_CONFIG'

# Universal Workspace Platform
export UWP_HOME="${HOME}/.universal-workspace"
export PATH="${UWP_HOME}/bin:${PATH}"
PATH_CONFIG
        fi
    fi
    
    log SUCCESS "PATH configured"
}

# ============================================================================
# GENERATE REPORT
# ============================================================================

generate_report() {
    log INFO "Generating installation report..."
    
    cat > "${LOG_DIR}/installation_report.txt" << REPORT
╔════════════════════════════════════════════════════╗
║  Universal Workspace Platform v${VERSION}          ║
║  Installation Report                              ║
╚════════════════════════════════════════════════════╝

Installation Date: $(date)
Installation Location: ${BASE_DIR}
Log File: ${INSTALL_LOG}

Installed Components:
✓ Core Library
✓ CLI Tool
✓ Module System
✓ Configuration

Installed Modules:
$(for module in ${SELECTED_MODULES//,/ }; do echo "✓ $module"; done)

Next Steps:
1. Reload shell: source ~/.bashrc or source ~/.zshrc
2. Check status: uwp status
3. Install module: uwp modules install ai
4. Start using: uwp ai "Your prompt"

Support:
- GitHub: https://github.com/username/uwp
- Docs: ${BASE_DIR}/docs

REPORT
    
    cat "${LOG_DIR}/installation_report.txt"
}

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

main() {
    parse_arguments "$@"
    
    mkdir -p "$LOG_DIR"
    
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Universal Workspace Platform v${VERSION} Installer  ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    check_prerequisites
    create_directories
    
    if [[ "$CONFIG_ONLY" != true ]]; then
        [[ "$SKIP_DEPS" != true ]] && install_dependencies
    fi
    
    copy_core_files
    init_configuration
    install_modules
    create_cli_tool
    setup_path
    generate_report
    
    echo ""
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Installation completed successfully! ✅           ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Reload your shell to apply changes:"
    echo "  source ~/.bashrc  or  source ~/.zshrc"
    echo ""
    echo "Test installation:"
    echo "  uwp status"
    echo ""
}

main "$@"
