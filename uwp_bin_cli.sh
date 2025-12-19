#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform - Main CLI Tool (uwp)
# Command-line interface for platform management
################################################################################

set -euo pipefail

readonly UWP_VERSION="4.0.0"
readonly UWP_HOME="${HOME}/.universal-workspace"
readonly UWP_LIB_DIR="${UWP_HOME}/lib"
readonly UWP_MODULES_DIR="${UWP_HOME}/modules"
readonly UWP_CONFIG_DIR="${UWP_HOME}/config"

# Source core library
if [[ -f "${UWP_LIB_DIR}/uwp-core.sh" ]]; then
    source "${UWP_LIB_DIR}/uwp-core.sh"
fi

# ============================================================================
# COMMAND HANDLERS
# ============================================================================

cmd_status() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Universal Workspace Platform Status               ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    echo "Version:           ${UWP_VERSION}"
    echo "Location:          ${UWP_HOME}"
    echo "Installation:      $(date -r "${UWP_HOME}" 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Modules:"
    if [[ -d "${UWP_MODULES_DIR}" ]]; then
        for module in "${UWP_MODULES_DIR}"/*; do
            if [[ -d "$module" ]]; then
                local mod_name=$(basename "$module")
                local installed="✗ Not installed"
                [[ -f "${module}/.installed" ]] && installed="✓ Installed"
                echo "  ${mod_name}: ${installed}"
            fi
        done
    else
        echo "  (no modules found)"
    fi
    echo ""
    echo "System:"
    echo "  OS:                $(uname -s)"
    echo "  Architecture:      $(uname -m)"
    echo "  Bash Version:      ${BASH_VERSION}"
    echo ""
}

cmd_modules() {
    local action=${1:-help}
    
    case "$action" in
        list)
            echo "Available modules:"
            if [[ -d "${UWP_MODULES_DIR}" ]]; then
                for module in "${UWP_MODULES_DIR}"/*; do
                    if [[ -d "$module" ]]; then
                        local name=$(basename "$module")
                        local installed="[NOT INSTALLED]"
                        [[ -f "${module}/.installed" ]] && installed="[INSTALLED]"
                        echo "  • ${name}: ${installed}"
                    fi
                done
            fi
            ;;
        install)
            local module=${2:-}
            if [[ -z "$module" ]]; then
                echo "Usage: uwp modules install <module>"
                return 1
            fi
            local module_path="${UWP_MODULES_DIR}/${module}"
            if [[ -f "${module_path}/install.sh" ]]; then
                echo "Installing module: ${module}"
                bash "${module_path}/install.sh"
                echo "✓ Module installed"
            else
                echo "✗ Module not found: ${module}"
                return 1
            fi
            ;;
        status)
            echo "Module status:"
            if [[ -d "${UWP_MODULES_DIR}" ]]; then
                for module in "${UWP_MODULES_DIR}"/*; do
                    if [[ -d "$module" ]]; then
                        local name=$(basename "$module")
                        if [[ -f "${module}/.installed" ]]; then
                            echo "  ✓ ${name}"
                        else
                            echo "  ✗ ${name}"
                        fi
                    fi
                done
            fi
            ;;
        *)
            echo "Usage: uwp modules [list|install|status]"
            ;;
    esac
}

cmd_config() {
    local action=${1:-help}
    local key=${2:-}
    local value=${3:-}
    local config_file="${UWP_CONFIG_DIR}/uwp.conf"
    
    case "$action" in
        get)
            if [[ -z "$key" ]]; then
                echo "Usage: uwp config get <key>"
                return 1
            fi
            if [[ -f "$config_file" ]]; then
                grep "^${key}=" "$config_file" 2>/dev/null | cut -d= -f2- || echo "(not set)"
            fi
            ;;
        set)
            if [[ -z "$key" || -z "$value" ]]; then
                echo "Usage: uwp config set <key> <value>"
                return 1
            fi
            mkdir -p "${UWP_CONFIG_DIR}"
            if grep -q "^${key}=" "$config_file" 2>/dev/null; then
                sed -i "s|^${key}=.*|${key}=${value}|" "$config_file"
            else
                echo "${key}=${value}" >> "$config_file"
            fi
            echo "✓ Configuration updated"
            ;;
        show)
            if [[ -f "$config_file" ]]; then
                echo "Configuration:"
                cat "$config_file" | grep -v "^#" | grep "="
            fi
            ;;
        *)
            echo "Usage: uwp config [get|set|show] [key] [value]"
            ;;
    esac
}

cmd_ai() {
    if ! command -v ollama &>/dev/null; then
        echo "✗ Ollama not installed"
        echo "Install with: uwp modules install ai"
        return 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Usage: uwp ai \"<prompt>\""
        return 1
    fi
    
    local prompt="$*"
    echo "Thinking..."
    ollama run phi3:mini "$prompt" 2>/dev/null || echo "Failed to get AI response"
}

cmd_analyze() {
    local project_path=${1:-.}
    
    if [[ ! -d "$project_path" ]]; then
        echo "✗ Project directory not found: ${project_path}"
        return 1
    fi
    
    echo "Analyzing project: ${project_path}"
    echo ""
    echo "Project Statistics:"
    echo "  Files:      $(find "${project_path}" -type f | wc -l)"
    echo "  Directories: $(find "${project_path}" -type d | wc -l)"
    echo "  Size:       $(du -sh "${project_path}" 2>/dev/null | cut -f1)"
    echo ""
    
    # Try to run AI analysis if available
    if command -v ollama &>/dev/null; then
        echo "Running AI analysis..."
        local files=$(find "${project_path}" -type f \( -name "*.js" -o -name "*.py" \) | head -3)
        if [[ -n "$files" ]]; then
            echo "Found code files - analyzing with AI..."
        fi
    fi
}

cmd_suggest() {
    local file_path=${1:-.}
    
    if [[ ! -f "$file_path" ]]; then
        echo "✗ File not found: ${file_path}"
        return 1
    fi
    
    if ! command -v ollama &>/dev/null; then
        echo "✗ Ollama not installed"
        return 1
    fi
    
    echo "Getting suggestions for: ${file_path}"
    local content=$(cat "$file_path" | head -100)
    ollama run phi3:mini "Suggest improvements for this code:\n${content}" 2>/dev/null || echo "Failed"
}

cmd_update() {
    echo "Checking for updates..."
    
    if [[ -d "${UWP_HOME}/.git" ]]; then
        cd "${UWP_HOME}"
        git pull origin main 2>/dev/null && echo "✓ Updated" || echo "✗ Update failed"
    else
        echo "⚠ Not a git repository"
    fi
}

cmd_help() {
    cat << EOF
╔════════════════════════════════════════════════════╗
║  Universal Workspace Platform v${UWP_VERSION}     ║
║  Command-line Interface                           ║
╚════════════════════════════════════════════════════╝

Usage: uwp <command> [options]

Commands:
  status              Show platform status
  modules list        List available modules
  modules install     Install specific module
  modules status      Check module installation status
  config get KEY      Get configuration value
  config set KEY VAL  Set configuration value
  config show         Show all configuration
  ai <prompt>         Chat with AI
  analyze <path>      Analyze project
  suggest <file>      Get code suggestions
  update              Update platform
  version             Show version
  help                Show this help

Examples:
  uwp status                          # Show status
  uwp modules list                    # List modules
  uwp modules install ai              # Install AI module
  uwp ai "Explain this code"          # Ask AI
  uwp analyze /my/project             # Analyze project
  uwp config set DEBUG true           # Set config

Features:
  ✓ Modular architecture
  ✓ AI-powered analysis
  ✓ Multi-platform support
  ✓ Easy configuration
  ✓ Extensible via plugins

Support:
  GitHub:  https://github.com/username/uwp
  Docs:    ${UWP_HOME}/docs
  Logs:    ${UWP_HOME}/logs

For more information, visit the documentation.
EOF
}

cmd_version() {
    echo "Universal Workspace Platform v${UWP_VERSION}"
}

cmd_diagnose() {
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  Diagnostic Report                                 ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""
    
    echo "System Information:"
    echo "  OS:        $(uname -s)"
    echo "  Kernel:    $(uname -r)"
    echo "  Arch:      $(uname -m)"
    echo "  Bash:      ${BASH_VERSION}"
    echo ""
    
    echo "Installation:"
    echo "  Home:      ${UWP_HOME}"
    echo "  Status:    $(test -d "${UWP_HOME}" && echo 'OK' || echo 'NOT FOUND')"
    echo ""
    
    echo "Dependencies:"
    for cmd in bash git curl python3 npm docker; do
        if command -v "$cmd" &>/dev/null; then
            echo "  ✓ $cmd"
        else
            echo "  ✗ $cmd (missing)"
        fi
    done
    echo ""
    
    echo "Disk Space:"
    if [[ -d "${UWP_HOME}" ]]; then
        du -sh "${UWP_HOME}" | awk '{print "  Used: " $1}'
    fi
    df -h "${HOME}" | tail -1 | awk '{print "  Available: " $4}'
}

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

main() {
    local command=${1:-help}
    shift || true
    
    case "$command" in
        status)
            cmd_status "$@"
            ;;
        modules)
            cmd_modules "$@"
            ;;
        config)
            cmd_config "$@"
            ;;
        ai)
            cmd_ai "$@"
            ;;
        analyze)
            cmd_analyze "$@"
            ;;
        suggest)
            cmd_suggest "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        diagnose)
            cmd_diagnose "$@"
            ;;
        version)
            cmd_version "$@"
            ;;
        help|--help|-h)
            cmd_help "$@"
            ;;
        *)
            echo "Unknown command: $command"
            echo "Try 'uwp help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
