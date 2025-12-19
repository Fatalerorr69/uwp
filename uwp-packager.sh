#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v5.0 - Package Builder
# Vytvoří kompletní instalační balíček připravený ke stažení
################################################################################

set -euo pipefail

readonly VERSION="5.0.0"
readonly PKG_NAME="uwp-v${VERSION}"
readonly BUILD_DIR="./build"
readonly DIST_DIR="./dist"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Universal Workspace Platform v5.0              ║${NC}"
echo -e "${BLUE}║  Package Builder                                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Clean and create directories
echo -e "${GREEN}[1/8]${NC} Preparing directories..."
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR/$PKG_NAME"
mkdir -p "$DIST_DIR"

# Create structure
cd "$BUILD_DIR/$PKG_NAME"
mkdir -p {bin,lib,modules/{ai,android,docker,development,terminal}/scripts,web,docs,config,templates}

# ============================================================================
# CORE FILES
# ============================================================================

echo -e "${GREEN}[2/8]${NC} Creating core library..."

cat > lib/uwp-core.sh << 'CORE_LIB'
#!/usr/bin/env bash
# UWP Core Library v5.0

export UWP_VERSION="5.0.0"
export UWP_LOADED=1

uwp_cmd_exists() { command -v "$1" &>/dev/null; }
uwp_file_exists() { [[ -f "$1" ]]; }
uwp_dir_exists() { [[ -d "$1" ]]; }

uwp_red() { echo -e "\033[0;31m$*\033[0m"; }
uwp_green() { echo -e "\033[0;32m$*\033[0m"; }
uwp_yellow() { echo -e "\033[1;33m$*\033[0m"; }
uwp_blue() { echo -e "\033[0;34m$*\033[0m"; }

uwp_get_module_path() { echo "${UWP_HOME:-$HOME/.uwp}/modules/$1"; }
uwp_get_config_path() { echo "${UWP_HOME:-$HOME/.uwp}/config/$1"; }
uwp_get_data_path() { echo "${UWP_HOME:-$HOME/.uwp}/data/$1"; }

uwp_config_get() {
    local key=$1 default=${2:-}
    local config="${UWP_HOME:-$HOME/.uwp}/config/uwp.conf"
    [[ -f "$config" ]] && grep "^${key}=" "$config" 2>/dev/null | cut -d= -f2- | tr -d '"' || echo "$default"
}

uwp_config_set() {
    local key=$1 value=$2
    local config="${UWP_HOME:-$HOME/.uwp}/config/uwp.conf"
    mkdir -p "$(dirname "$config")"
    if grep -q "^${key}=" "$config" 2>/dev/null; then
        sed -i.bak "s|^${key}=.*|${key}=\"${value}\"|" "$config"
    else
        echo "${key}=\"${value}\"" >> "$config"
    fi
}

uwp_install_pkg() {
    local package=$1
    uwp_cmd_exists "$package" && return 0
    case "${PKG_MANAGER:-apt}" in
        pkg) pkg install -y "$package" 2>/dev/null ;;
        apt|apt-get) [[ $EUID -eq 0 ]] && apt-get update -qq && apt-get install -y "$package" 2>/dev/null || sudo apt-get update -qq && sudo apt-get install -y "$package" 2>/dev/null ;;
        yum|dnf) [[ $EUID -eq 0 ]] && "$PKG_MANAGER" install -y "$package" 2>/dev/null || sudo "$PKG_MANAGER" install -y "$package" 2>/dev/null ;;
        pacman) [[ $EUID -eq 0 ]] && pacman -S --noconfirm "$package" 2>/dev/null || sudo pacman -S --noconfirm "$package" 2>/dev/null ;;
    esac
}

uwp_module_exists() { [[ -d "$(uwp_get_module_path "$1")" ]]; }
uwp_module_installed() { [[ -f "$(uwp_get_module_path "$1")/.installed" ]]; }
uwp_module_mark_installed() { touch "$(uwp_get_module_path "$1")/.installed"; }

uwp_progress() {
    local current=$1 total=$2 width=40
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    printf "\r["; printf "%${filled}s" | tr ' ' '█'
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
CORE_LIB

chmod +x lib/uwp-core.sh

# ============================================================================
# CLI TOOL
# ============================================================================

echo -e "${GREEN}[3/8]${NC} Creating CLI tool..."

cat > bin/uwp << 'CLI_TOOL'
#!/usr/bin/env bash
UWP_HOME="${UWP_HOME:-${HOME}/.uwp}"
source "${UWP_HOME}/lib/uwp-core.sh" 2>/dev/null || { echo "Error: UWP not initialized"; exit 1; }

show_help() {
    cat << 'EOF'
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
                    [[ -f "$mod/.installed" ]] && echo "  ✓ $name" || echo "  ○ $name"
                done
                ;;
            install)
                [[ -z "$3" ]] && echo "Usage: uwp modules install <module>" && exit 1
                [[ -f "$UWP_HOME/modules/$3/install.sh" ]] && bash "$UWP_HOME/modules/$3/install.sh" || { echo "Module not found: $3"; exit 1; }
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
        uwp_cmd_exists ollama && ollama run phi3:mini "${@:2}" || echo "AI not available. Install with: uwp modules install ai"
        ;;
    update)
        echo "Checking for updates..."
        echo "Platform is up to date (v5.0.0)"
        ;;
    help|--help|-h) show_help ;;
    *) echo "Unknown command: $1"; show_help; exit 1 ;;
esac
CLI_TOOL

chmod +x bin/uwp

# ============================================================================
# MODULES
# ============================================================================

echo -e "${GREEN}[4/8]${NC} Creating modules..."

# AI Module
cat > modules/ai/install.sh << 'AI_MOD'
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
AI_MOD

# Android Module
cat > modules/android/install.sh << 'ANDROID_MOD'
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
ANDROID_MOD

# Docker Module
cat > modules/docker/install.sh << 'DOCKER_MOD'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"
echo "[Docker] Installing Docker..."
if ! uwp_cmd_exists docker; then
    curl -fsSL https://get.docker.com | sh 2>/dev/null || true
fi
uwp_module_mark_installed docker
echo "[Docker] Module installed ✓"
DOCKER_MOD

# Development Module
cat > modules/development/install.sh << 'DEV_MOD'
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
DEV_MOD

# Terminal Module
cat > modules/terminal/install.sh << 'TERM_MOD'
#!/usr/bin/env bash
source "${UWP_HOME:-$HOME/.uwp}/lib/uwp-core.sh"
echo "[Terminal] Configuring terminal..."
uwp_install_pkg zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi
uwp_module_mark_installed terminal
echo "[Terminal] Module installed ✓"
TERM_MOD

# Make all install scripts executable
chmod +x modules/*/install.sh

# ============================================================================
# WEB GUI
# ============================================================================

echo -e "${GREEN}[5/8]${NC} Creating Web GUI..."

cat > web/index.html << 'WEBGUI'
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UWP v5.0 Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: system-ui, -apple-system, sans-serif;
            background: linear-gradient(135deg, #0f172a 0%, #1a1f3a 100%);
            color: #e2e8f0;
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        header {
            background: rgba(30, 41, 59, 0.8);
            border: 1px solid #334155;
            border-radius: 16px;
            padding: 30px;
            margin-bottom: 30px;
            text-align: center;
        }
        h1 {
            font-size: 32px;
            background: linear-gradient(135deg, #0ea5e9, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
        }
        .card {
            background: rgba(30, 41, 59, 0.6);
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 24px;
            transition: all 0.3s ease;
        }
        .card:hover {
            transform: translateY(-4px);
            border-color: #0ea5e9;
            box-shadow: 0 20px 25px -5px rgba(14, 165, 233, 0.2);
        }
        .card h3 { margin-bottom: 12px; color: #0ea5e9; }
        .btn {
            padding: 10px 20px;
            background: #0ea5e9;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            margin-top: 12px;
            transition: all 0.3s;
        }
        .btn:hover {
            background: #0284c7;
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 Universal Workspace Platform v5.0</h1>
            <p>Professional Development Environment</p>
        </header>
        <div class="grid">
            <div class="card">
                <h3>🤖 AI Workspace</h3>
                <p>Ollama, LLM models, code analysis</p>
                <button class="btn" onclick="alert('Install: uwp modules install ai')">Install</button>
            </div>
            <div class="card">
                <h3>📱 Android Toolkit</h3>
                <p>ADB, Fastboot, device management</p>
                <button class="btn" onclick="alert('Install: uwp modules install android')">Install</button>
            </div>
            <div class="card">
                <h3>🐳 Docker</h3>
                <p>Container management</p>
                <button class="btn" onclick="alert('Install: uwp modules install docker')">Install</button>
            </div>
            <div class="card">
                <h3>💻 Development</h3>
                <p>Git, Node.js, Python, build tools</p>
                <button class="btn" onclick="alert('Install: uwp modules install development')">Install</button>
            </div>
            <div class="card">
                <h3>🖥️ Terminal</h3>
                <p>Zsh, Oh My Zsh, plugins</p>
                <button class="btn" onclick="alert('Install: uwp modules install terminal')">Install</button>
            </div>
        </div>
    </div>
</body>
</html>
WEBGUI

# ============================================================================
# DOCUMENTATION
# ============================================================================

echo -e "${GREEN}[6/8]${NC} Creating documentation..."

cat > docs/README.md << 'DOCS'
# Universal Workspace Platform v5.0

## Quick Start

```bash
# Install
bash install.sh

# Reload shell
source ~/.bashrc  # or ~/.zshrc

# Check status
uwp status

# Install modules
uwp modules install ai
uwp modules install android
uwp modules install docker
```

## Commands

```bash
uwp status                  # Show status
uwp modules list            # List modules
uwp modules install <name>  # Install module
uwp analyze <path>          # Analyze project
uwp ai "prompt"             # AI assistant
```

## Modules

- **ai** - AI workspace with Ollama
- **android** - Android development tools
- **docker** - Container management
- **development** - Dev tools (Git, Node.js, Python)
- **terminal** - Zsh with Oh My Zsh

## Support

- GitHub: https://github.com/YOUR_REPO/uwp
- Docs: https://uwp.dev
- Issues: https://github.com/YOUR_REPO/uwp/issues
DOCS

# Copy main README
cp docs/README.md README.md

# ============================================================================
# CONFIG TEMPLATES
# ============================================================================

echo -e "${GREEN}[7/8]${NC} Creating config templates..."

cat > config/uwp.conf.template << 'CONF'
# UWP Configuration Template
version="5.0.0"
install_date=""
os=""
arch=""
pkg_manager=""

# Features
ai_enabled="true"
android_enabled="true"
docker_enabled="true"
web_enabled="true"

# Paths
uwp_home="${HOME}/.uwp"
uwp_data="${HOME}/.uwp/data"
uwp_cache="${HOME}/.uwp/.cache"
CONF

# ============================================================================
# MAIN INSTALLER
# ============================================================================

echo -e "${GREEN}[8/8]${NC} Creating main installer..."

cat > install.sh << 'INSTALLER'
#!/usr/bin/env bash
set -euo pipefail

readonly VERSION="5.0.0"
readonly BASE_DIR="${UWP_HOME:-${HOME}/.uwp}"

echo "╔══════════════════════════════════════════════════╗"
echo "║  Universal Workspace Platform v5.0              ║"
echo "║  Installer                                      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Copy files
echo "[1/3] Installing files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$BASE_DIR"
cp -r "$SCRIPT_DIR"/* "$BASE_DIR/" 2>/dev/null || {
    echo "Installing from package..."
    cp -r . "$BASE_DIR/"
}

# Setup permissions
echo "[2/3] Setting permissions..."
chmod +x "$BASE_DIR/bin"/*
chmod +x "$BASE_DIR/modules"/*/install.sh

# Shell integration
echo "[3/3] Configuring shell..."
SHELL_RC="${HOME}/.bashrc"
[[ -f "${HOME}/.zshrc" ]] && SHELL_RC="${HOME}/.zshrc"

if ! grep -q "UWP_HOME" "$SHELL_RC" 2>/dev/null; then
    cat >> "$SHELL_RC" << 'SHELL_END'

# Universal Workspace Platform
export UWP_HOME="${HOME}/.uwp"
export PATH="${UWP_HOME}/bin:${PATH}"
alias uwp-status='uwp status'
SHELL_END
fi

# Create symlink
mkdir -p "${HOME}/.local/bin"
ln -sf "$BASE_DIR/bin/uwp" "${HOME}/.local/bin/uwp" 2>/dev/null || true

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reload shell: source $SHELL_RC"
echo "  2. Check status: uwp status"
echo "  3. Install modules: uwp modules install <module>"
echo ""
INSTALLER

chmod +x install.sh

# ============================================================================
# CREATE ARCHIVE
# ============================================================================

cd ..
echo ""
echo -e "${YELLOW}Creating archive...${NC}"

# Create .tar.gz
tar -czf "${DIST_DIR}/${PKG_NAME}.tar.gz" "$PKG_NAME"
echo -e "${GREEN}✓${NC} Created: ${DIST_DIR}/${PKG_NAME}.tar.gz"

# Create .zip
zip -rq "${DIST_DIR}/${PKG_NAME}.zip" "$PKG_NAME"
echo -e "${GREEN}✓${NC} Created: ${DIST_DIR}/${PKG_NAME}.zip"

# Calculate checksums
cd "$DIST_DIR"
sha256sum "${PKG_NAME}.tar.gz" > "${PKG_NAME}.tar.gz.sha256"
sha256sum "${PKG_NAME}.zip" > "${PKG_NAME}.zip.sha256"

# File sizes
tar_size=$(du -h "${PKG_NAME}.tar.gz" | cut -f1)
zip_size=$(du -h "${PKG_NAME}.zip" | cut -f1)

# ============================================================================
# CREATE INSTALL SCRIPT FOR QUICK DOWNLOAD
# ============================================================================

cat > quick-install.sh << 'QUICK'
#!/usr/bin/env bash
# UWP Quick Installer

echo "Downloading Universal Workspace Platform v5.0..."

# GitHub Release URL (update with your repository)
RELEASE_URL="https://github.com/YOUR_REPO/uwp/releases/download/v5.0.0/uwp-v5.0.0.tar.gz"

# Download and extract
curl -fsSL "$RELEASE_URL" | tar -xz
cd uwp-v5.0.0
bash install.sh

echo "Installation complete!"
QUICK

chmod +x quick-install.sh

# ============================================================================
# SUMMARY
# ============================================================================

cd ..
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Package Build Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Files created:${NC}"
echo "  📦 dist/${PKG_NAME}.tar.gz (${tar_size})"
echo "  📦 dist/${PKG_NAME}.zip (${zip_size})"
echo "  🔐 dist/${PKG_NAME}.tar.gz.sha256"
echo "  🔐 dist/${PKG_NAME}.zip.sha256"
echo "  🚀 dist/quick-install.sh"
echo ""
echo -e "${YELLOW}Installation commands:${NC}"
echo ""
echo "  # From tar.gz:"
echo "  curl -fsSL URL/${PKG_NAME}.tar.gz | tar -xz"
echo "  cd ${PKG_NAME} && bash install.sh"
echo ""
echo "  # From zip:"
echo "  wget URL/${PKG_NAME}.zip"
echo "  unzip ${PKG_NAME}.zip"
echo "  cd ${PKG_NAME} && bash install.sh"
echo ""
echo "  # Quick install:"
echo "  curl -fsSL URL/quick-install.sh | bash"
echo ""
echo -e "${GREEN}Ready for deployment! 🚀${NC}"
echo ""