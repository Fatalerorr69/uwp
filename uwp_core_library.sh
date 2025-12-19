#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform - Core Library (uwp-core.sh)
# Essential functions and utilities for all modules
################################################################################

[[ -n "${UWP_CORE_LOADED:-}" ]] && return 0
export UWP_CORE_LOADED=1

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

export UWP_HOME="${UWP_HOME:-${HOME}/.universal-workspace}"
export UWP_CONFIG_DIR="${UWP_CONFIG_DIR:-${UWP_HOME}/config}"
export UWP_BIN_DIR="${UWP_BIN_DIR:-${UWP_HOME}/bin}"
export UWP_LIB_DIR="${UWP_LIB_DIR:-${UWP_HOME}/lib}"
export UWP_MODULES_DIR="${UWP_MODULES_DIR:-${UWP_HOME}/modules}"
export UWP_DATA_DIR="${UWP_DATA_DIR:-${UWP_HOME}/data}"
export UWP_LOG_DIR="${UWP_LOG_DIR:-${UWP_HOME}/logs}"
export UWP_CACHE_DIR="${UWP_CACHE_DIR:-${UWP_HOME}/.cache}"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

export UWP_RED='\033[0;31m'
export UWP_GREEN='\033[0;32m'
export UWP_YELLOW='\033[1;33m'
export UWP_BLUE='\033[0;34m'
export UWP_MAGENTA='\033[0;35m'
export UWP_CYAN='\033[0;36m'
export UWP_BOLD='\033[1m'
export UWP_DIM='\033[2m'
export UWP_NC='\033[0m'

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

uwp_log() {
    local level=$1
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "${UWP_LOG_DIR}"
    echo "[${timestamp}] [${level}] ${msg}" >> "${UWP_LOG_DIR}/uwp.log"
    
    case "$level" in
        ERROR)
            echo -e "${UWP_RED}[✗]${UWP_NC} ${msg}" >&2
            ;;
        WARN)
            echo -e "${UWP_YELLOW}[⚠]${UWP_NC} ${msg}"
            ;;
        INFO)
            echo -e "${UWP_BLUE}[i]${UWP_NC} ${msg}"
            ;;
        SUCCESS)
            echo -e "${UWP_GREEN}[✓]${UWP_NC} ${msg}"
            ;;
        DEBUG)
            [[ "${UWP_DEBUG:-0}" == "1" ]] && echo -e "${UWP_CYAN}[DEBUG]${UWP_NC} ${msg}"
            ;;
    esac
}

uwp_info() { uwp_log INFO "$@"; }
uwp_warn() { uwp_log WARN "$@"; }
uwp_error() { uwp_log ERROR "$@"; }
uwp_success() { uwp_log SUCCESS "$@"; }
uwp_debug() { uwp_log DEBUG "$@"; }

uwp_die() {
    uwp_error "$@"
    exit 1
}

# ============================================================================
# COMMAND & FILE UTILITIES
# ============================================================================

uwp_command_exists() {
    command -v "$1" &>/dev/null
}

uwp_require_command() {
    if ! uwp_command_exists "$1"; then
        uwp_error "Command required but not found: $1"
        return 1
    fi
}

uwp_file_exists() {
    [[ -f "$1" ]]
}

uwp_dir_exists() {
    [[ -d "$1" ]]
}

uwp_is_executable() {
    [[ -x "$1" ]]
}

uwp_get_file_size() {
    local file=$1
    if [[ -f "$file" ]]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# ============================================================================
# PATH & DIRECTORY UTILITIES
# ============================================================================

uwp_get_module_path() {
    local module=$1
    echo "${UWP_MODULES_DIR}/${module}"
}

uwp_get_config_path() {
    local config=$1
    echo "${UWP_CONFIG_DIR}/${config}"
}

uwp_get_data_path() {
    local subdir=$1
    echo "${UWP_DATA_DIR}/${subdir}"
}

uwp_get_log_path() {
    local name=$1
    echo "${UWP_LOG_DIR}/${name}.log"
}

uwp_ensure_dir() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || uwp_error "Failed to create directory: $dir"
    fi
    echo "$dir"
}

# ============================================================================
# STRING UTILITIES
# ============================================================================

uwp_trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space: