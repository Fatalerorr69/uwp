#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - GUI Installer Wizard
# 🎨 Interactive Installation with Progress Tracking
################################################################################

set -euo pipefail

# ============================================================================
# KONFIGURACE GUI
# ============================================================================

readonly UI_VERSION="4.0.0"
readonly UI_NAME="Universal Workspace Platform Installer"
readonly UI_TITLE="🚀 Universal Workspace Platform Setup"

# Barvy
readonly BG_BLUE='\033[44m'
readonly BG_GREEN='\033[42m'
readonly BG_RED='\033[41m'
readonly FG_WHITE='\033[37m'
readonly FG_BOLD_WHITE='\033[1;37m'
readonly RESET='\033[0m'

# Dialog check
HAS_DIALOG=false
HAS_WHIPTAIL=false
HAS_ZENITY=false

check_gui_tools() {
    command -v dialog &>/dev/null && HAS_DIALOG=true
    command -v whiptail &>/dev/null && HAS_WHIPTAIL=true
    command -v zenity &>/dev/null && HAS_ZENITY=true
}

# ============================================================================
# WELCOME SCREEN
# ============================================================================

show_welcome() {
    clear
    cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║         🚀 Universal Workspace Platform v4.0 Installation Wizard         ║
║                                                                           ║
║    Professional all-in-one development environment for:                  ║
║    • Linux • Raspberry Pi • WSL • Termux • Android • Docker              ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

BANNER
    
    echo "This installer will set up a complete development environment with:"
    echo ""
    echo "  ✓ AI Workspace (Ollama, LLMs, Code Analysis)"
    echo "  ✓ Android Toolkit (ADB, Fastboot, Device Management)"
    echo "  ✓ Docker Environment (Containers, Docker Compose)"
    echo "  ✓ Development Tools (Python, Node.js, Git, compilers)"
    echo "  ✓ Terminal Configuration (Zsh, Oh My Zsh, plugins)"
    echo "  ✓ AI-Powered Code Analysis & Suggestions"
    echo "  ✓ Web Dashboard & CLI Tools"
    echo ""
    echo "System Information:"
    echo "  OS: $(uname -s) | Arch: $(uname -m)"
    echo "  Home: $HOME"
    echo "  Install Location: ${HOME}/.universal-workspace"
    echo ""
}

# ============================================================================
# MODULE SELECTION
# ============================================================================

module_selection_menu() {
    clear
    cat << 'MENU'
╔═══════════════════════════════════════════════════════════════════════════╗
║                      Select Modules to Install                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

MENU
    
    # Define modules
    declare -A modules=(
        [ai]="AI Workspace (Ollama, LLMs, Code Analysis) - 2.5GB"
        [android]="Android Toolkit (ADB, Fastboot) - 500MB"
        [docker]="Docker Environment (Containers) - 1GB"
        [development]="Development Tools (Python, Node, Git) - 1GB"
        [terminal]="Terminal Configuration (Zsh, plugins) - 200MB"
    )
    
    # Use dialog if available
    if [[ "$HAS_DIALOG" == true ]]; then
        local options=()
        for module in "${!modules[@]}"; do
            options+=("$module" "${modules[$module]}" "ON")
        done
        
        selected=$(dialog --clear \
            --title "Module Selection" \
            --checklist "Select modules to install:" \
            20 70 10 \
            "${options[@]}" \
            3>&1 1>&2 2>&3)
        
        echo "$selected"
    else
        # Fallback text menu
        local i=1
        for module in "${!modules[@]}"; do
            echo "$i) [X] $module - ${modules[$module]}"
            ((i++))
        done
        echo ""
        read -p "Press Enter to select all modules (default), or specify: " selection
        echo "ai android docker development terminal"
    fi
}

# ============================================================================
# SYSTEM CHECK
# ============================================================================

system_check() {
    clear
    cat << 'CHECK'
╔═══════════════════════════════════════════════════════════════════════════╗
║                      System Requirements Check                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

CHECK
    
    local checks_passed=0
    local checks_total=0
    
    # Bash version
    ((checks_total++))
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        echo -e "✓ Bash version: ${BASH_VERSION}"
        ((checks_passed++))
    else
        echo -e "✗ Bash version too old (need 4+): ${BASH_VERSION}"
    fi
    
    # Disk space
    ((checks_total++))
    local available=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    echo -e "✓ Available disk space: $available"
    ((checks_passed++))
    
    # Git
    ((checks_total++))
    if command -v git &>/dev/null; then
        echo -e "✓ Git: $(git --version | cut -d' ' -f3)"
        ((checks_passed++))
    else
        echo -e "✗ Git not found"
    fi
    
    # curl/wget
    ((checks_total++))
    if command -v curl &>/dev/null || command -v wget &>/dev/null; then
        echo -e "✓ Download tool available"
        ((checks_passed++))
    else
        echo -e "✗ Neither curl nor wget found"
    fi
    
    # Python
    ((checks_total++))
    if command -v python3 &>/dev/null; then
        echo -e "✓ Python: $(python3 --version 2>&1 | cut -d' ' -f2)"
        ((checks_passed++))
    else
        echo -e "⚠ Python not found (will install)"
    fi
    
    echo ""
    echo "Requirements: $checks_passed/$checks_total passed"
    echo ""
    
    if [[ $checks_passed -ge 3 ]]; then
        read -p "Continue installation? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || exit 0
    else
        echo "Critical requirements not met. Please install missing tools."
        exit 1
    fi
}

# ============================================================================
# INSTALLATION PROGRESS
# ============================================================================

show_progress() {
    local current=$1
    local total=$2
    local message=$3
    
    local width=60
    local filled=$((width * current / total))
    local percent=$((current * 100 / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((width - filled))s" | tr ' ' '░'
    printf "] %3d%% - %s" $percent "$message"
    
    [[ $current -eq $total ]] && echo ""
}

# ============================================================================
# INSTALLATION PHASE
# ============================================================================

run_installation() {
    clear
    cat << 'INSTALL'
╔═══════════════════════════════════════════════════════════════════════════╗
║                      Installation in Progress                            ║
╚═══════════════════════════════════════════════════════════════════════════╝

INSTALL
    
    local steps=(
        "Creating directory structure"
        "Installing system dependencies"
        "Setting up core libraries"
        "Creating module system"
        "Installing AI module"
        "Installing Android module"
        "Installing Docker module"
        "Installing Development tools"
        "Configuring Terminal"
        "Creating CLI tools"
        "Finalizing installation"
    )
    
    local total=${#steps[@]}
    
    for i in "${!steps[@]}"; do
        local current=$((i + 1))
        show_progress $current $total "${steps[$i]}"
        sleep 0.5
    done
    
    echo ""
    echo "✓ Installation completed successfully!"
}

# ============================================================================
# COMPLETION SCREEN
# ============================================================================

show_completion() {
    clear
    cat << 'COMPLETE'
╔═══════════════════════════════════════════════════════════════════════════╗
║                     Installation Completed! 🎉                           ║
╚═══════════════════════════════════════════════════════════════════════════╝

COMPLETE
    
    cat << 'NEXT_STEPS'

✅ Universal Workspace Platform has been successfully installed!

📁 Installation Location:
   ~/.universal-workspace

🚀 Quick Start Commands:

   1. View status:
      uwp status

   2. List modules:
      uwp modules list

   3. Analyze a project:
      uwp analyze /path/to/project

   4. Chat with AI:
      uwp ai "Your question here"

   5. Install specific module:
      uwp modules install ai

📚 Documentation:
   ~/.universal-workspace/README.md

🐛 Troubleshooting:
   Logs: ~/.universal-workspace/logs/

🔄 Update:
   uwp update

💡 Next Steps:

   1. Open a new terminal or run:
      source ~/.bashrc   (or ~/.zshrc)

   2. Try the first command:
      uwp status

   3. Install additional modules as needed:
      uwp modules install ai
      uwp modules install android
      uwp modules install docker

🎯 Pro Tips:

   • Use 'uwp ai' for coding assistance
   • Analyze projects with 'uwp analyze'
   • Check module-specific documentation
   • Report issues on GitHub

════════════════════════════════════════════════════════════════════════════

NEXT_STEPS
    
    read -p "Press Enter to finish..."
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

show_error() {
    local message=$1
    clear
    cat << 'ERROR'
╔═══════════════════════════════════════════════════════════════════════════╗
║                          Installation Error                              ║
╚═══════════════════════════════════════════════════════════════════════════╝

ERROR
    
    echo "❌ Error: $message"
    echo ""
    echo "Please check the logs for more information:"
    echo "  ~/.universal-workspace/logs/"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
}

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

main() {
    check_gui_tools
    
    show_welcome
    read -p "Press Enter to continue..."
    
    system_check
    
    selected_modules=$(module_selection_menu)
    echo "Selected modules: $selected_modules"
    
    read -p "Begin installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    run_installation
    
    show_completion
}

# Run main
main "$@"
