#!/usr/bin/env bash

# UWP System Validator Module

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
UWP_CONFIGS="$UWP_HOME/configs"
UWP_LOGS="$UWP_HOME/logs"

# Log file
LOG_FILE="$UWP_LOGS/validator_$(date +%Y%m%d_%H%M%S).log"

# Logging functions
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
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Validation functions
validate_directory_structure() {
    log "INFO" "Validating UWP directory structure..."
    
    local directories=(
        "$UWP_HOME"
        "$UWP_MODULES"
        "$UWP_CONFIGS"
        "$UWP_LOGS"
        "$UWP_HOME/cache"
    )
    
    local missing_dirs=0
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            log "SUCCESS" "Directory exists: $dir"
        else
            log "ERROR" "Directory missing: $dir"
            ((missing_dirs++))
        fi
    done
    
    if [ $missing_dirs -eq 0 ]; then
        log "SUCCESS" "Directory structure validation passed"
        return 0
    else
        log "ERROR" "Directory structure validation failed: $missing_dirs directories missing"
        return 1
    fi
}

validate_modules() {
    log "INFO" "Validating UWP modules..."
    
    local modules=(
        "ai_module"
        "dev_module"
        "docker_module"
        "terminal_module"
        "validator_module"
    )
    
    local missing_modules=0
    
    for module in "${modules[@]}"; do
        local module_path="$UWP_MODULES/$module"
        
        if [ -d "$module_path" ]; then
            # Check for required files based on module
            case $module in
                "ai_module")
                    if [ -f "$module_path/ai_main.py" ] && [ -f "$module_path/requirements.txt" ]; then
                        log "SUCCESS" "AI module: OK"
                    else
                        log "WARNING" "AI module: Missing some files"
                    fi
                    ;;
                    
                "dev_module")
                    if [ -f "$module_path/dev_main.js" ] && [ -f "$module_path/package.json" ]; then
                        log "SUCCESS" "Dev module: OK"
                    else
                        log "WARNING" "Dev module: Missing some files"
                    fi
                    ;;
                    
                "docker_module")
                    if [ -f "$module_path/docker_setup.sh" ]; then
                        log "SUCCESS" "Docker module: OK"
                    else
                        log "WARNING" "Docker module: Missing setup script"
                    fi
                    ;;
                    
                "terminal_module")
                    if [ -f "$module_path/terminal_config.sh" ]; then
                        log "SUCCESS" "Terminal module: OK"
                    else
                        log "WARNING" "Terminal module: Missing config script"
                    fi
                    ;;
                    
                "validator_module")
                    if [ -f "$module_path/validator.sh" ]; then
                        log "SUCCESS" "Validator module: OK"
                    else
                        log "WARNING" "Validator module: Missing validator script"
                    fi
                    ;;
            esac
        else
            log "ERROR" "Module missing: $module"
            ((missing_modules++))
        fi
    done
    
    if [ $missing_modules -eq 0 ]; then
        log "SUCCESS" "Module validation passed"
        return 0
    else
        log "ERROR" "Module validation failed: $missing_modules modules missing"
        return 1
    fi
}

validate_configs() {
    log "INFO" "Validating configuration files..."
    
    local configs=(
        "uwp_config.json"
        "ai_config.json"
        "dev_config.json"
        "docker_config.json"
    )
    
    local missing_configs=0
    local invalid_configs=0
    
    for config in "${configs[@]}"; do
        local config_path="$UWP_CONFIGS/$config"
        
        if [ -f "$config_path" ]; then
            # Validate JSON syntax
            if python3 -m json.tool "$config_path" > /dev/null 2>&1; then
                log "SUCCESS" "Config valid: $config"
            else
                log "ERROR" "Config invalid JSON: $config"
                ((invalid_configs++))
            fi
        else
            log "WARNING" "Config missing: $config"
            ((missing_configs++))
        fi
    done
    
    if [ $missing_configs -eq 0 ] && [ $invalid_configs -eq 0 ]; then
        log "SUCCESS" "Config validation passed"
        return 0
    else
        log "ERROR" "Config validation failed: $missing_configs missing, $invalid_configs invalid"
        return 1
    fi
}

validate_dependencies() {
    log "INFO" "Validating system dependencies..."
    
    local dependencies=(
        "python3"
        "pip3"
        "node"
        "npm"
        "docker"
        "git"
    )
    
    local missing_deps=0
    
    for dep in "${dependencies[@]}"; do
        if command -v "$dep" &> /dev/null; then
            local version=$("$dep" --version 2>/dev/null | head -n1)
            log "SUCCESS" "$dep: $version"
        else
            log "WARNING" "Dependency missing: $dep"
            ((missing_deps++))
        fi
    done
    
    if [ $missing_deps -eq 0 ]; then
        log "SUCCESS" "Dependency validation passed"
        return 0
    else
        log "WARNING" "Dependency validation: $missing_deps dependencies missing (some may be optional)"
        return 1
    fi
}

validate_permissions() {
    log "INFO" "Validating file permissions..."
    
    local files_to_check=(
        "$UWP_MODULES/ai_module/ai_main.py"
        "$UWP_MODULES/dev_module/dev_main.js"
        "$UWP_MODULES/docker_module/docker_setup.sh"
        "$UWP_MODULES/terminal_module/terminal_config.sh"
        "$UWP_MODULES/validator_module/validator.sh"
    )
    
    local permission_issues=0
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            if [ -x "$file" ]; then
                log "SUCCESS" "File executable: $(basename "$file")"
            else
                log "WARNING" "File not executable: $(basename "$file")"
                ((permission_issues++))
            fi
        fi
    done
    
    if [ $permission_issues -eq 0 ]; then
        log "SUCCESS" "Permission validation passed"
        return 0
    else
        log "WARNING" "Permission validation: $permission_issues files not executable"
        return 1
    fi
}

validate_symlinks() {
    log "INFO" "Validating symlinks..."
    
    # Check if uwp command is available
    if command -v uwp &> /dev/null; then
        log "SUCCESS" "UWP CLI symlink exists"
        return 0
    else
        log "ERROR" "UWP CLI symlink missing"
        return 1
    fi
}

# Generate report
generate_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$UWP_LOGS/validation_report_$(date +%Y%m%d).md" << EOF
# UWP Validation Report
**Generated:** $timestamp

## Summary
- **UWP Home:** $UWP_HOME
- **Validation Time:** $(date '+%Y-%m-%d %H:%M:%S')
- **Log File:** $LOG_FILE

## System Information
- **OS:** $(uname -s) $(uname -r)
- **Shell:** $SHELL
- **User:** $USER

## Validation Results
\`\`\`
$(tail -50 "$LOG_FILE")
\`\`\`

## Recommendations
1. Review any ERROR messages above
2. Fix missing dependencies if needed
3. Run \`uwp --update\` to update UWP
4. Check $UWP_LOGS for detailed logs

---
*Generated by UWP Validator Module v1.0*
EOF
    
    log "INFO" "Report generated: $UWP_LOGS/validation_report_$(date +%Y%m%d).md"
}

# Main validation function
validate_all() {
    echo -e "${PURPLE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║        UWP SYSTEM VALIDATION              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    
    # Create log directory if it doesn't exist
    mkdir -p "$UWP_LOGS"
    
    # Run all validations
    local results=()
    
    log "INFO" "Starting comprehensive UWP validation..."
    echo ""
    
    validate_directory_structure
    results+=($?)
    echo ""
    
    validate_modules
    results+=($?)
    echo ""
    
    validate_configs
    results+=($?)
    echo ""
    
    validate_dependencies
    results+=($?)
    echo ""
    
    validate_permissions
    results+=($?)
    echo ""
    
    validate_symlinks
    results+=($?)
    echo ""
    
    # Generate report
    generate_report
    
    # Calculate overall status
    local failed=0
    for result in "${results[@]}"; do
        if [ $result -ne 0 ]; then
            ((failed++))
        fi
    done
    
    echo ""
    echo -e "${PURPLE}════════════════════════════════════════════${NC}"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}✅ ALL VALIDATIONS PASSED!${NC}"
        echo -e "${GREEN}UWP system is healthy and ready to use.${NC}"
    elif [ $failed -le 2 ]; then
        echo -e "${YELLOW}⚠️  SOME WARNINGS DETECTED${NC}"
        echo -e "${YELLOW}UWP is functional but has some minor issues.${NC}"
    else
        echo -e "${RED}❌ VALIDATION FAILURES DETECTED${NC}"
        echo -e "${RED}UWP has issues that need attention.${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. View full log: less $LOG_FILE"
    echo "2. Check report: $UWP_LOGS/validation_report_$(date +%Y%m%d).md"
    echo "3. Run specific module tests if needed"
    echo ""
}

# Quick validation
quick_validate() {
    log "INFO" "Running quick validation..."
    
    # Just check the basics
    if [ -d "$UWP_HOME" ] && [ -f "$UWP_MODULES/ai_module/ai_main.py" ] && command -v uwp &> /dev/null; then
        echo -e "${GREEN}✅ UWP is installed and working${NC}"
        return 0
    else
        echo -e "${RED}❌ UWP installation issues detected${NC}"
        return 1
    fi
}

# Parse arguments
case "$1" in
    --full|-f)
        validate_all
        ;;
        
    --quick|-q)
        quick_validate
        ;;
        
    --report|-r)
        generate_report
        echo -e "${GREEN}Report generated${NC}"
        ;;
        
    --help|-h)
        echo "UWP Validator Module"
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  --full, -f    Run full validation (default)"
        echo "  --quick, -q   Run quick validation"
        echo "  --report, -r  Generate validation report"
        echo "  --help, -h    Show this help"
        ;;
        
    *)
        validate_all
        ;;
esac
