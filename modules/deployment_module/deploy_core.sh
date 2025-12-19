#!/usr/bin/env bash

# UWP Deployment Core Module

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# UWP Paths
UWP_HOME="$HOME/.universal-workspace"
UWP_MODULES="$UWP_HOME/modules"
UWP_CONFIGS="$UWP_CONFIGS"
DEPLOY_LOG="$UWP_HOME/logs/deploy_$(date +%Y%m%d_%H%M%S).log"

# Logging
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
        *) color=$NC ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
    echo "[$timestamp] [$level] $message" >> "$DEPLOY_LOG"
}

# Backup existing installation
backup_uwp() {
    log "INFO" "Creating backup of existing UWP installation..."
    
    local backup_dir="$UWP_HOME/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup configs
    if [ -d "$UWP_CONFIGS" ]; then
        cp -r "$UWP_CONFIGS" "$backup_dir/"
        log "SUCCESS" "Configs backed up to $backup_dir/configs"
    fi
    
    # Backup logs
    if [ -d "$UWP_HOME/logs" ]; then
        cp -r "$UWP_HOME/logs" "$backup_dir/"
        log "SUCCESS" "Logs backed up"
    fi
    
    # Create backup manifest
    cat > "$backup_dir/backup_manifest.json" << EOF
{
    "backup_date": "$(date -Iseconds)",
    "uwp_version": "4.0.0",
    "backup_type": "pre_deploy",
    "contents": ["configs", "logs"]
}
EOF
    
    log "SUCCESS" "Backup created: $backup_dir"
    echo "$backup_dir"
}

# Deploy module
deploy_module() {
    local module_name="$1"
    local source_dir="$2"
    local target_dir="$UWP_MODULES/$module_name"
    
    log "INFO" "Deploying module: $module_name"
    
    # Remove old module if exists
    if [ -d "$target_dir" ]; then
        log "INFO" "Removing old version of $module_name"
        rm -rf "$target_dir"
    fi
    
    # Copy new module
    if [ -d "$source_dir" ]; then
        mkdir -p "$target_dir"
        cp -r "$source_dir"/* "$target_dir/"
        log "SUCCESS" "Module $module_name deployed"
        return 0
    else
        log "ERROR" "Source directory not found: $source_dir"
        return 1
    fi
}

# Deploy configuration
deploy_config() {
    local config_name="$1"
    local source_file="$2"
    local target_file="$UWP_CONFIGS/$config_name"
    
    log "INFO" "Deploying config: $config_name"
    
    # Create configs directory if it doesn't exist
    mkdir -p "$UWP_CONFIGS"
    
    # Backup existing config if it exists
    if [ -f "$target_file" ]; then
        cp "$target_file" "$target_file.backup.$(date +%Y%m%d)"
        log "INFO" "Existing config backed up"
    fi
    
    # Deploy new config
    if [ -f "$source_file" ]; then
        cp "$source_file" "$target_file"
        log "SUCCESS" "Config $config_name deployed"
        return 0
    else
        log "WARNING" "Source config not found: $source_file"
        return 1
    fi
}

# Validate deployment
validate_deployment() {
    log "INFO" "Validating deployment..."
    
    local validation_passed=true
    
    # Check if modules exist
    local modules=("ai_module" "dev_module" "docker_module" "terminal_module" "validator_module")
    
    for module in "${modules[@]}"; do
        if [ -d "$UWP_MODULES/$module" ]; then
            log "SUCCESS" "Module exists: $module"
        else
            log "ERROR" "Module missing: $module"
            validation_passed=false
        fi
    done
    
    # Check if uwp command works
    if command -v uwp &> /dev/null; then
        log "SUCCESS" "UWP CLI is accessible"
    else
        log "ERROR" "UWP CLI not found in PATH"
        validation_passed=false
    fi
    
    if [ "$validation_passed" = true ]; then
        log "SUCCESS" "Deployment validation passed"
        return 0
    else
        log "ERROR" "Deployment validation failed"
        return 1
    fi
}

# Rollback to backup
rollback() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        log "ERROR" "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log "INFO" "Rolling back to backup: $backup_dir"
    
    # Restore configs
    if [ -d "$backup_dir/configs" ]; then
        rm -rf "$UWP_CONFIGS"
        cp -r "$backup_dir/configs" "$UWP_CONFIGS"
        log "SUCCESS" "Configs restored"
    fi
    
    # Restore logs
    if [ -d "$backup_dir/logs" ]; then
        cp -r "$backup_dir/logs"/* "$UWP_HOME/logs/" 2>/dev/null || true
        log "INFO" "Logs restored"
    fi
    
    log "SUCCESS" "Rollback completed"
}

# Main deployment function
deploy() {
    local deployment_dir="${1:-.}"
    
    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║        UWP DEPLOYMENT SYSTEM              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    
    # Create log directory
    mkdir -p "$(dirname "$DEPLOY_LOG")"
    
    # Step 1: Backup
    log "INFO" "Starting UWP deployment..."
    local backup_dir=$(backup_uwp)
    
    # Step 2: Deploy modules
    log "INFO" "Deploying modules from: $deployment_dir"
    
    if [ -d "$deployment_dir/modules" ]; then
        for module in "$deployment_dir"/modules/*; do
            if [ -d "$module" ]; then
                module_name=$(basename "$module")
                deploy_module "$module_name" "$module"
            fi
        done
    else
        log "WARNING" "No modules directory found in $deployment_dir"
    fi
    
    # Step 3: Deploy configs
    if [ -d "$deployment_dir/configs" ]; then
        for config in "$deployment_dir"/configs/*; do
            if [ -f "$config" ]; then
                config_name=$(basename "$config")
                deploy_config "$config_name" "$config"
            fi
        done
    fi
    
    # Step 4: Update CLI
    log "INFO" "Updating CLI..."
    if [ -f "$deployment_dir/auto_install.sh" ]; then
        # Update CLI symlink
        if [ -w "/usr/local/bin" ]; then
            sudo ln -sf "$UWP_HOME/cli/uwp" /usr/local/bin/uwp 2>/dev/null || true
            log "SUCCESS" "CLI symlink updated"
        fi
    fi
    
    # Step 5: Validate
    if validate_deployment; then
        log "SUCCESS" "Deployment completed successfully!"
        
        echo ""
        echo -e "${GREEN}════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ DEPLOYMENT SUCCESSFUL${NC}"
        echo -e "${GREEN}════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${BLUE}Summary:${NC}"
        echo "  - Backup created: $backup_dir"
        echo "  - Modules deployed: $(ls -1 "$UWP_MODULES" | wc -l)"
        echo "  - Log file: $DEPLOY_LOG"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Test installation: uwp --status"
        echo "  2. Check logs if needed: less $DEPLOY_LOG"
        echo "  3. Remove backup if not needed: rm -rf $backup_dir"
        
        return 0
    else
        log "ERROR" "Deployment validation failed, rolling back..."
        
        # Rollback on failure
        rollback "$backup_dir"
        
        echo ""
        echo -e "${RED}════════════════════════════════════════════${NC}"
        echo -e "${RED}❌ DEPLOYMENT FAILED - ROLLED BACK${NC}"
        echo -e "${RED}════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}Details:${NC}"
        echo "  - Original backup: $backup_dir"
        echo "  - System restored to pre-deployment state"
        echo "  - Error log: $DEPLOY_LOG"
        
        return 1
    fi
}

# Parse arguments
case "$1" in
    --deploy|-d)
        deploy "${2:-.}"
        ;;
        
    --backup|-b)
        backup_uwp
        ;;
        
    --rollback|-r)
        if [ -n "$2" ]; then
            rollback "$2"
        else
            echo "Usage: $0 --rollback <backup-directory>"
        fi
        ;;
        
    --validate|-v)
        validate_deployment
        ;;
        
    --help|-h)
        echo "UWP Deployment Core Module"
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --deploy, -d [dir]    Deploy UWP from directory (default: current)"
        echo "  --backup, -b          Create backup of current installation"
        echo "  --rollback, -r <dir>  Rollback to backup directory"
        echo "  --validate, -v        Validate current deployment"
        echo "  --help, -h            Show this help"
        ;;
        
    *)
        echo "UWP Deployment Core Module"
        echo "Use --help for usage information"
        ;;
esac
