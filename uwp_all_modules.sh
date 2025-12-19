################################################################################
# Module 1: AI Workspace Module - modules/ai/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="ai"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[AI] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing AI Workspace module..."

# Create directory structure
mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/config"

# Install Ollama
if ! command -v ollama &>/dev/null; then
    log_info "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh 2>/dev/null || \
    log_info "Manual Ollama installation required"
fi

# Create AI analysis script
cat > "${MODULE_DIR}/scripts/analyze.sh" << 'ANALYZE_SCRIPT'
#!/usr/bin/env bash
PROJECT="${1:-.}"
if [[ ! -d "$PROJECT" ]]; then
    echo "Project not found: $PROJECT"
    exit 1
fi

echo "🔍 Analyzing project: $PROJECT"
du -sh "$PROJECT" | awk '{print "Size: " $1}'
find "$PROJECT" -type f | wc -l | awk '{print "Files: " $1}'
find "$PROJECT" -type d | wc -l | awk '{print "Directories: " $1}'

if command -v ollama &>/dev/null; then
    echo "Running AI analysis..."
    ollama run phi3:mini "Analyze this project and suggest improvements"
fi
ANALYZE_SCRIPT
chmod +x "${MODULE_DIR}/scripts/analyze.sh"

# Download AI models
log_info "Downloading AI models (this may take time)..."
if command -v ollama &>/dev/null; then
    ollama pull phi3:mini 2>/dev/null &
    ollama pull llama3.2:3b 2>/dev/null &
    wait
    log_success "AI models downloaded"
fi

# Mark as installed
touch "${MODULE_DIR}/.installed"
log_success "AI Workspace module installed"

################################################################################
# Module 2: Android Toolkit Module - modules/android/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="android"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Android] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Android Toolkit module..."

# Create directory structure
mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/config"

# Detect package manager and install ADB
if command -v apt-get &>/dev/null; then
    log_info "Installing ADB and Fastboot..."
    apt-get update &>/dev/null || true
    apt-get install -y android-tools-adb android-tools-fastboot &>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf install -y android-tools &>/dev/null || true
elif command -v pacman &>/dev/null; then
    pacman -S --noconfirm android-tools &>/dev/null || true
else
    log_info "Manual ADB installation may be required"
fi

# Create device info script
cat > "${MODULE_DIR}/scripts/device-info.sh" << 'DEVICE_SCRIPT'
#!/usr/bin/env bash
if ! command -v adb &>/dev/null; then
    echo "ADB not found"
    exit 1
fi

echo "=== Android Device Info ==="
adb devices -l
echo ""
echo "Device Properties:"
adb shell getprop ro.product.brand
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
DEVICE_SCRIPT
chmod +x "${MODULE_DIR}/scripts/device-info.sh"

# Create APK installer script
cat > "${MODULE_DIR}/scripts/install-apk.sh" << 'APK_SCRIPT'
#!/usr/bin/env bash
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path-to-apk>"
    exit 1
fi

APK="$1"
if [[ ! -f "$APK" ]]; then
    echo "APK file not found: $APK"
    exit 1
fi

echo "Installing APK: $APK"
adb install -r "$APK"
echo "Done"
APK_SCRIPT
chmod +x "${MODULE_DIR}/scripts/install-apk.sh"

# Setup udev rules for device detection
if [[ -w /etc/udev/rules.d/ ]]; then
    cat > /etc/udev/rules.d/51-android.rules << 'UDEV_RULES'
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
UDEV_RULES
    udevadm control --reload-rules 2>/dev/null || true
    log_success "Udev rules installed"
fi

touch "${MODULE_DIR}/.installed"
log_success "Android Toolkit module installed"

################################################################################
# Module 3: Docker Environment Module - modules/docker/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="docker"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Docker] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Docker Environment module..."

mkdir -p "${MODULE_DIR}/compose"
mkdir -p "${MODULE_DIR}/config"

# Install Docker
if ! command -v docker &>/dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | sh 2>/dev/null || \
    log_info "Manual Docker installation required"
fi

# Install Docker Compose
if ! command -v docker-compose &>/dev/null; then
    log_info "Installing Docker Compose..."
    curl -L https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64 \
        -o /usr/local/bin/docker-compose 2>/dev/null || true
    chmod +x /usr/local/bin/docker-compose 2>/dev/null || true
fi

# Create development stack
cat > "${MODULE_DIR}/compose/dev-stack.yml" << 'DEV_COMPOSE'
version: '3.9'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
    environment:
      - NODE_ENV=development

  database:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
DEV_COMPOSE

touch "${MODULE_DIR}/.installed"
log_success "Docker Environment module installed"

################################################################################
# Module 4: Development Tools Module - modules/development/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="development"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Dev] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Development Tools module..."

mkdir -p "${MODULE_DIR}/config"

# Install core tools
log_info "Installing core development tools..."
TOOLS="git curl wget nano vim python3 python3-pip nodejs npm build-essential"

if command -v apt-get &>/dev/null; then
    apt-get update &>/dev/null || true
    apt-get install -y $TOOLS &>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf install -y $TOOLS &>/dev/null || true
elif command -v pacman &>/dev/null; then
    pacman -S --noconfirm $TOOLS &>/dev/null || true
fi

# Setup Python virtual environment
if command -v python3 &>/dev/null; then
    log_info "Setting up Python virtual environment..."
    python3 -m venv "${UWP_HOME}/venv" 2>/dev/null || true
    source "${UWP_HOME}/venv/bin/activate"
    pip install --quiet wheel setuptools 2>/dev/null || true
fi

# Install global Node packages
if command -v npm &>/dev/null; then
    log_info "Installing Node packages..."
    npm install -g \
        typescript \
        eslint \
        prettier \
        ts-node \
        nodemon \
        webpack \
        vite \
        2>/dev/null || true
fi

touch "${MODULE_DIR}/.installed"
log_success "Development Tools module installed"

################################################################################
# Module 5: Terminal Configuration Module - modules/terminal/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="terminal"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Terminal] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Terminal Configuration module..."

mkdir -p "${MODULE_DIR}/config"

# Install Zsh
if ! command -v zsh &>/dev/null; then
    log_info "Installing Zsh..."
    if command -v apt-get &>/dev/null; then
        apt-get install -y zsh &>/dev/null || true
    elif command -v dnf &>/dev/null; then
        dnf install -y zsh &>/dev/null || true
    fi
fi

# Install Oh My Zsh
if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || true
fi

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
mkdir -p "${ZSH_CUSTOM}/plugins"

if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
fi

if [[ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" 2>/dev/null || true
fi

# Create custom zshrc configuration
cat > "${MODULE_DIR}/config/.zshrc-custom" << 'ZSHRC'
# Universal Workspace Platform - Custom Zsh Configuration

# Plugins
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    docker
    npm
    python
    rust
)

# Aliases
alias uwp='${UWP_HOME}/bin/uwp'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Functions
update-uwp() {
    uwp update
}

analyze-project() {
    uwp analyze "${1:-.}"
}

ai-chat() {
    uwp ai "$@"
}

# Prompt customization
PROMPT='%n@%m:%~$ '
ZSHRC

touch "${MODULE_DIR}/.installed"
log_success "Terminal Configuration module installed"
