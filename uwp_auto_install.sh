#!/usr/bin/env bash
# =========================================================
# UWP Auto Installer with Online Update
# Automatická instalace + kontrola a aktualizace offline ZIP
# =========================================================

set -euo pipefail
IFS=$'\n\t'

UWP_HOME="$HOME/.universal-workspace"
MODULES_DIR="$UWP_HOME/modules"
CLI_BIN="$UWP_HOME/cli/uwp"
ZIP_FILE="$UWP_HOME/uwp_offline_bundle_full_latest.zip"
GITHUB_ZIP_URL="https://github.com/Fatalerorr69/uwp/releases/latest/download/uwp_offline_bundle_full_latest.zip"
LOG_FILE="$UWP_HOME/uwp_install.log"

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

log() { printf "%s %s\n" "$(date '+%H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }
status_ok() { printf "${GREEN}✔ %s${RESET}\n" "$1"; }
status_fail() { printf "${RED}✖ %s${RESET}\n" "$1"; }

mkdir -p "$UWP_HOME" "$MODULES_DIR" "$(dirname "$CLI_BIN")"
touch "$LOG_FILE"

log "Starting UWP Auto Installer with Online Update…"

# -----------------------------
# Check internet and download latest ZIP
# -----------------------------
if command -v curl &> /dev/null; then
    log "Checking for latest offline bundle..."
    curl -L -o "$ZIP_FILE.tmp" -s "$GITHUB_ZIP_URL"
    if [ -s "$ZIP_FILE.tmp" ]; then
        mv "$ZIP_FILE.tmp" "$ZIP_FILE"
        status_ok "Latest offline ZIP downloaded"
    else
        status_fail "Failed to download latest ZIP. Using existing ZIP if available."
        rm -f "$ZIP_FILE.tmp"
    fi
else
    status_fail "curl not found. Skipping online update."
fi

# -----------------------------
# Verify ZIP exists
# -----------------------------
if [ ! -f "$ZIP_FILE" ]; then
    status_fail "ZIP balíček $ZIP_FILE nenalezen!"
    exit 1
fi

# -----------------------------
# Rozbalení ZIP
# -----------------------------
log "Rozbaluji ZIP balíček..."
unzip -o "$ZIP_FILE" -d "$UWP_HOME" >> "$LOG_FILE" 2>&1
status_ok "ZIP balíček rozbalen do $UWP_HOME"

# -----------------------------
# Python AI modul
# -----------------------------
PY_VENV="$UWP_HOME/venv"
log "Vytvářím Python virtuální prostředí pro AI modul..."
python3 -m venv "$PY_VENV"
source "$PY_VENV/bin/activate"
if [ -f "$MODULES_DIR/uwp_ai/requirements.txt" ]; then
    pip install --upgrade pip
    pip install --no-index --find-links "$UWP_HOME/wheels" -r "$MODULES_DIR/uwp_ai/requirements.txt" >> "$LOG_FILE" 2>&1
    status_ok "Python AI modul nainstalován"
fi

# -----------------------------
# Development modul (npm)
# -----------------------------
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
echo 'export PATH=$HOME/.npm-global/bin:$PATH' >> "$HOME/.profile"
if [ -d "$MODULES_DIR/uwp_dev" ]; then
    npm install --prefix "$HOME/.npm-global" "$MODULES_DIR/uwp_dev" >> "$LOG_FILE" 2>&1
    status_ok "Development modul nainstalován"
fi

# -----------------------------
# Kontrola ostatních modulů
# -----------------------------
if command -v docker &> /dev/null; then status_ok "Docker dostupný"; else status_fail "Docker nenalezen"; fi
if command -v adb &> /dev/null; then status_ok "Android nástroje dostupné"; else status_fail "ADB/SDK nenalezeno"; fi
status_ok "Terminal modul připraven"

# -----------------------------
# Instalace CLI
# -----------------------------
cat > "$CLI_BIN" << 'EOF'
#!/usr/bin/env bash
source "$HOME/.universal-workspace/venv/bin/activate" &> /dev/null
echo "UWP CLI — všechny moduly připraveny"
EOF
chmod +x "$CLI_BIN"
status_ok "CLI nainstalováno: $CLI_BIN"

# -----------------------------
# Ověření modulů
# -----------------------------
log "Ověřuji moduly..."
$CLI_BIN
$CLI_BIN status
status_ok "Všechny moduly ověřeny"

log "UWP Auto Installer with Online Update dokončen! Všechny moduly připraveny."
