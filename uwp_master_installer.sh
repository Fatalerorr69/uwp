#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - Master Installer (Full Version)
# Plně automatizovaný, zahrnuje skutečné instalace všech modulů
################################################################################

set -euo pipefail
IFS=$'\n\t'

SCRIPT_VERSION="4.0.0"
BASE_DIR="${HOME}/uwp"
CONFIG_DIR="${BASE_DIR}/config"
BIN_DIR="${BASE_DIR}/bin"
LIB_DIR="${BASE_DIR}/lib"
MODULES_DIR="${BASE_DIR}/modules"
DATA_DIR="${BASE_DIR}/data"
LOG_DIR="${BASE_DIR}/logs"

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() {
    local level=$1; shift
    local msg="$*"
    mkdir -p "$LOG_DIR"
    echo -e "[${level}] $msg"
    echo "[${level}] $msg" >> "$LOG_DIR/install.log"
}

log_info() { log "INFO" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# ============================================================================
# 1️⃣ Inicializace adresářů
# ============================================================================
log_info "Inicializuji adresáře..."
mkdir -p "$BIN_DIR" "$LIB_DIR" "$MODULES_DIR" "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
log_success "Struktura vytvořena"

# ============================================================================
# 2️⃣ Core knihovna
# ============================================================================
cat > "$LIB_DIR/uwp-core.sh" << 'EOF'
#!/usr/bin/env bash
export UWP_LOADED=1

uwp_module_mark_installed() { touch "$UWP_MODULES_DIR/$1/.installed"; }
uwp_get_module_path() { echo "$UWP_MODULES_DIR/$1"; }
uwp_install_package() {
    local pkg=$1
    if command -v "$pkg" &>/dev/null; then return; fi
    if command -v apt &>/dev/null; then sudo apt install -y "$pkg"
    elif command -v pkg &>/dev/null; then pkg install -y "$pkg"
    elif command -v dnf &>/dev/null; then sudo dnf install -y "$pkg"
    elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm "$pkg"
    else echo "Manual install needed: $pkg"; fi
}
EOF
chmod +x "$LIB_DIR/uwp-core.sh"

# ============================================================================
# 3️⃣ Moduly s reálnou instalací
# ============================================================================
declare -A MODULES=( [ai]="AI Workspace" [android]="Android Toolkit" [docker]="Docker" [development]="Development Tools" [terminal]="Terminal" )

for module in "${!MODULES[@]}"; do
    MODULE_DIR="$MODULES_DIR/$module"
    mkdir -p "$MODULE_DIR/scripts"

    case "$module" in
        ai)
            cat > "$MODULE_DIR/install.sh" << EOF
#!/usr/bin/env bash
source "$LIB_DIR/uwp-core.sh"
echo "[AI] Instalace AI Workspace..."
uwp_install_package python3
uwp_install_package python3-pip
if command -v pip3 &>/dev/null; then
    pip3 install --quiet openai torch transformers langchain chromadb sentence-transformers
fi
echo "[AI] AI modul nainstalován ✓"
touch "$MODULE_DIR/.installed"
EOF
            ;;
        android)
            cat > "$MODULE_DIR/install.sh" << EOF
#!/usr/bin/env bash
source "$LIB_DIR/uwp-core.sh"
echo "[Android] Instalace Android Toolkit..."
uwp_install_package android-tools-adb
uwp_install_package android-tools-fastboot
sudo mkdir -p /etc/udev/rules.d
sudo tee /etc/udev/rules.d/51-android.rules > /dev/null << 'RULES'
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
RULES
sudo udevadm control --reload-rules || true
echo "[Android] Android modul nainstalován ✓"
touch "$MODULE_DIR/.installed"
EOF
            ;;
        docker)
            cat > "$MODULE_DIR/install.sh" << EOF
#!/usr/bin/env bash
source "$LIB_DIR/uwp-core.sh"
echo "[Docker] Instalace Docker..."
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sh
fi
if ! command -v docker-compose &>/dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
echo "[Docker] Docker modul nainstalován ✓"
touch "$MODULE_DIR/.installed"
EOF
            ;;
        development)
            cat > "$MODULE_DIR/install.sh" << EOF
#!/usr/bin/env bash
source "$LIB_DIR/uwp-core.sh"
echo "[Dev] Instalace vývojářských nástrojů..."
uwp_install_package git
uwp_install_package curl
uwp_install_package wget
uwp_install_package python3
uwp_install_package python3-pip
uwp_install_package nodejs
uwp_install_package npm
if command -v npm &>/dev/null; then
    npm install -g typescript eslint prettier ts-node
fi
echo "[Dev] Development modul nainstalován ✓"
touch "$MODULE_DIR/.installed"
EOF
            ;;
        terminal)
            cat > "$MODULE_DIR/install.sh" << EOF
#!/usr/bin/env bash
source "$LIB_DIR/uwp-core.sh"
echo "[Terminal] Instalace Zsh a Oh My Zsh..."
uwp_install_package zsh
if [[ ! -d "\$HOME/.oh-my-zsh" ]]; then
    sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
fi
echo "[Terminal] Terminal modul nainstalován ✓"
touch "$MODULE_DIR/.installed"
EOF
            ;;
    esac
    chmod +x "$MODULE_DIR/install.sh"
done

# ============================================================================
# 4️⃣ CLI
# ============================================================================
cat > "$BIN_DIR/uwp" << 'EOF'
#!/usr/bin/env bash
UWP_HOME="${HOME}/uwp"
PATH="$UWP_HOME/bin:$PATH"

case "$1" in
    status)
        echo "UWP full package | Base: $UWP_HOME"
        ls -1 "$UWP_HOME/modules"
        ;;
    modules)
        [[ -z "$2" ]] && { echo "Usage: uwp modules <name>"; exit 1; }
        bash "$UWP_HOME/modules/$2/install.sh"
        ;;
    help|*|--help|-h)
        echo "Commands: status | modules <name> | help"
        ;;
esac
EOF
chmod +x "$BIN_DIR/uwp"

if [[ $EUID -eq 0 ]]; then
    ln -sf "$BIN_DIR/uwp" /usr/local/bin/uwp
else
    mkdir -p "$HOME/.local/bin"
    ln -sf "$BIN_DIR/uwp" "$HOME/.local/bin/uwp"
fi

# ============================================================================
# 5️⃣ Hlavní instalace modulů
# ============================================================================
log_info "Instaluji všechny moduly..."
for module in "${!MODULES[@]}"; do
    bash "$MODULES_DIR/$module/install.sh"
done
log_success "Všechny moduly nainstalovány"

# ============================================================================
# 6️⃣ Závěr
# ============================================================================
log_success "UWP Master Installer dokončen"
echo -e "${GREEN}Použij CLI: uwp status | uwp modules <name>${NC}"
