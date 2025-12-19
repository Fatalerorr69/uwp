#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - Validation & Testing Framework
# 🧪 Comprehensive Quality Assurance System
################################################################################

set -euo pipefail

readonly TEST_VERSION="4.0.0"
readonly TEST_LOG="${HOME}/.universal-workspace/logs/tests.log"
readonly TEST_REPORT="${HOME}/.universal-workspace/reports/test-report.html"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ============================================================================
# LOGGING & REPORTING
# ============================================================================

test_log() {
    local level=$1
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$TEST_LOG"
}

test_assert() {
    local condition=$1
    local message=$2
    
    ((TESTS_RUN++))
    
    if eval "$condition"; then
        echo "✓ $message"
        test_log "PASS" "$message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "✗ $message"
        test_log "FAIL" "$message"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_skip() {
    local message=$1
    echo "⊘ $message (skipped)"
    test_log "SKIP" "$message"
    ((TESTS_SKIPPED++))
}

# ============================================================================
# STRUCTURAL TESTS
# ============================================================================

test_directory_structure() {
    echo "=== Directory Structure Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    
    test_assert "[[ -d '$base_dir' ]]" "Base directory exists"
    test_assert "[[ -d '$base_dir/bin' ]]" "Bin directory exists"
    test_assert "[[ -d '$base_dir/lib' ]]" "Lib directory exists"
    test_assert "[[ -d '$base_dir/config' ]]" "Config directory exists"
    test_assert "[[ -d '$base_dir/modules' ]]" "Modules directory exists"
    test_assert "[[ -d '$base_dir/plugins' ]]" "Plugins directory exists"
    test_assert "[[ -d '$base_dir/logs' ]]" "Logs directory exists"
    test_assert "[[ -d '$base_dir/data' ]]" "Data directory exists"
}

test_files_exist() {
    echo ""
    echo "=== Files Existence Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    
    test_assert "[[ -f '$base_dir/lib/uwp-core.sh' ]]" "Core library exists"
    test_assert "[[ -f '$base_dir/bin/uwp' ]]" "Main CLI tool exists"
    test_assert "[[ -x '$base_dir/bin/uwp' ]]" "CLI tool is executable"
    test_assert "[[ -f '$base_dir/config/modules.json' ]]" "Modules registry exists"
    test_assert "[[ -f '$base_dir/config/uwp.conf' ]]" "Configuration file exists"
}

# ============================================================================
# SYNTAX TESTS
# ============================================================================

test_bash_syntax() {
    echo ""
    echo "=== Bash Syntax Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    local shell_files=(
        "$base_dir/lib/uwp-core.sh"
        "$base_dir/bin/uwp"
        "$base_dir/modules/ai/install.sh"
        "$base_dir/modules/android/install.sh"
        "$base_dir/modules/docker/install.sh"
    )
    
    for file in "${shell_files[@]}"; do
        if [[ -f "$file" ]]; then
            if bash -n "$file" 2>/dev/null; then
                test_assert "true" "Syntax check: $(basename $file)"
            else
                test_assert "false" "Syntax check: $(basename $file)"
            fi
        else
            test_skip "Syntax check: $(basename $file) (file not found)"
        fi
    done
}

test_json_syntax() {
    echo ""
    echo "=== JSON Syntax Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    local json_files=(
        "$base_dir/config/modules.json"
    )
    
    if ! command -v jq &>/dev/null; then
        test_skip "JSON validation (jq not installed)"
        return
    fi
    
    for file in "${json_files[@]}"; do
        if [[ -f "$file" ]]; then
            if jq empty "$file" 2>/dev/null; then
                test_assert "true" "JSON syntax: $(basename $file)"
            else
                test_assert "false" "JSON syntax: $(basename $file)"
            fi
        fi
    done
}

# ============================================================================
# FUNCTIONALITY TESTS
# ============================================================================

test_cli_commands() {
    echo ""
    echo "=== CLI Command Tests ==="
    
    if ! command -v uwp &>/dev/null; then
        test_skip "CLI tests (uwp not in PATH)"
        return
    fi
    
    test_assert "uwp status 2>/dev/null | grep -q 'Universal Workspace'" "Status command works"
    test_assert "uwp modules list 2>/dev/null | grep -q 'ai\\|android'" "Modules list works"
    test_assert "uwp help 2>/dev/null | grep -q 'Usage:'" "Help command works"
    test_assert "uwp config get UWP_HOME 2>/dev/null | grep -q 'universal-workspace'" "Config get works"
}

test_module_functionality() {
    echo ""
    echo "=== Module Functionality Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    
    # AI module
    if [[ -f "$base_dir/modules/ai/scripts/analyze.sh" ]]; then
        test_assert "[[ -x '$base_dir/modules/ai/scripts/analyze.sh' ]]" "AI analyze script is executable"
    else
        test_skip "AI analyze script (not found)"
    fi
    
    # Android module
    if command -v adb &>/dev/null; then
        test_assert "adb devices 2>/dev/null | grep -q 'List of'" "ADB functional"
    else
        test_skip "ADB functionality (not installed)"
    fi
    
    # Docker module
    if command -v docker &>/dev/null; then
        test_assert "docker version 2>/dev/null | grep -q 'Client'" "Docker functional"
    else
        test_skip "Docker functionality (not installed)"
    fi
}

test_library_functions() {
    echo ""
    echo "=== Library Function Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    
    if [[ ! -f "$base_dir/lib/uwp-core.sh" ]]; then
        test_skip "Library functions (core library not found)"
        return
    fi
    
    # Source library
    source "$base_dir/lib/uwp-core.sh" 2>/dev/null || return
    
    # Test functions exist
    test_assert "declare -f uwp_command_exists >/dev/null 2>&1" "uwp_command_exists function"
    test_assert "declare -f uwp_config_get >/dev/null 2>&1" "uwp_config_get function"
    test_assert "declare -f uwp_config_set >/dev/null 2>&1" "uwp_config_set function"
    test_assert "declare -f uwp_module_exists >/dev/null 2>&1" "uwp_module_exists function"
    
    # Test function behavior
    test_assert "uwp_command_exists bash" "Command detection works"
    test_assert "! uwp_command_exists nonexistent_command_xyz" "Nonexistent command detection"
}

# ============================================================================
# SYSTEM INTEGRATION TESTS
# ============================================================================

test_system_integration() {
    echo ""
    echo "=== System Integration Tests ==="
    
    # PATH integration
    test_assert "[[ -x /usr/local/bin/uwp ]] || [[ -x \$HOME/.local/bin/uwp ]]" "CLI in PATH"
    
    # Module access
    test_assert "[[ -d \$HOME/.universal-workspace/modules/ai ]]" "AI module accessible"
    test_assert "[[ -d \$HOME/.universal-workspace/modules/android ]]" "Android module accessible"
    
    # Configuration persistence
    if command -v uwp &>/dev/null; then
        uwp config set TEST_KEY "test_value" 2>/dev/null || true
        test_assert "uwp config get TEST_KEY 2>/dev/null | grep -q test_value" "Config persistence"
    fi
}

# ============================================================================
# PERFORMANCE TESTS
# ============================================================================

test_performance() {
    echo ""
    echo "=== Performance Tests ==="
    
    # CLI response time
    if command -v uwp &>/dev/null; then
        local start=$(date +%s%N)
        uwp status >/dev/null 2>&1
        local end=$(date +%s%N)
        local duration=$((($end - $start) / 1000000))  # Convert to ms
        
        if [[ $duration -lt 1000 ]]; then
            test_assert "true" "CLI response time < 1s (${duration}ms)"
        else
            test_assert "false" "CLI response time < 1s (${duration}ms)"
        fi
    fi
}

# ============================================================================
# SECURITY TESTS
# ============================================================================

test_security() {
    echo ""
    echo "=== Security Tests ==="
    
    local base_dir="${HOME}/.universal-workspace"
    
    # File permissions
    if [[ -f "$base_dir/config/uwp.conf" ]]; then
        local perms=$(stat -c "%a" "$base_dir/config/uwp.conf" 2>/dev/null || stat -f "%OLp" "$base_dir/config/uwp.conf")
        if [[ "$perms" =~ ^.00$ ]] || [[ "$perms" =~ ^600$ ]]; then
            test_assert "true" "Config file permissions secure (600)"
        else
            test_assert "false" "Config file permissions secure ($perms)"
        fi
    fi
    
    # No hardcoded secrets
    if [[ -f "$base_dir/lib/uwp-core.sh" ]]; then
        test_assert "! grep -r 'password\\|secret\\|token\\|key' $base_dir/lib/ 2>/dev/null | grep -v '^#'" "No hardcoded secrets in core"
    fi
}

# ============================================================================
# COMPATIBILITY TESTS
# ============================================================================

test_compatibility() {
    echo ""
    echo "=== Compatibility Tests ==="
    
    # Bash version
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        test_assert "true" "Bash 4+ required"
    else
        test_assert "false" "Bash 4+ required"
    fi
    
    # OS compatibility
    local os=$(uname -s)
    case "$os" in
        Linux|Darwin)
            test_assert "true" "Supported OS: $os"
            ;;
        *)
            test_skip "OS compatibility ($os)"
            ;;
    esac
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_test_report() {
    echo ""
    echo "=== Test Report Generation ==="
    
    local success_rate=0
    if [[ $TESTS_RUN -gt 0 ]]; then
        success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
    fi
    
    cat > "$TEST_REPORT" << HTML
<!DOCTYPE html>
<html>
<head>
    <title>UWP Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: #333; color: white; padding: 20px; border-radius: 5px; }
        .summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 20px 0; }
        .stat { background: white; padding: 20px; border-radius: 5px; text-align: center; }
        .stat h3 { margin: 0; }
        .passed { color: #4CAF50; }
        .failed { color: #f44336; }
        .skipped { color: #FFC107; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #333; color: white; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Universal Workspace Platform - Test Report</h1>
        <p>Generated: $(date)</p>
    </div>
    
    <div class="summary">
        <div class="stat">
            <h3>$TESTS_RUN</h3>
            <p>Total Tests</p>
        </div>
        <div class="stat">
            <h3 class="passed">$TESTS_PASSED</h3>
            <p>Passed</p>
        </div>
        <div class="stat">
            <h3 class="failed">$TESTS_FAILED</h3>
            <p>Failed</p>
        </div>
        <div class="stat">
            <h3 class="skipped">$TESTS_SKIPPED</h3>
            <p>Skipped</p>
        </div>
    </div>
    
    <h2>Success Rate: ${success_rate}%</h2>
    <p>Test Logs: <a href="file://$TEST_LOG">$TEST_LOG</a></p>
</body>
</html>
HTML
    
    echo "✓ Test report generated: $TEST_REPORT"
}

# ============================================================================
# MAIN TEST SUITE
# ============================================================================

main() {
    mkdir -p "$(dirname "$TEST_LOG")"
    mkdir -p "$(dirname "$TEST_REPORT")"
    
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║  Universal Workspace Platform v$TEST_VERSION - Test Suite   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Run all tests
    test_directory_structure
    test_files_exist
    test_bash_syntax
    test_json_syntax
    test_cli_commands
    test_module_functionality
    test_library_functions
    test_system_integration
    test_performance
    test_security
    test_compatibility
    
    # Summary
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                      Test Summary                         ║"
    echo "╠═══════════════════════════════════════════════════════════╣"
    echo "║  Total Tests:    $TESTS_RUN"
    echo "║  Passed:         $TESTS_PASSED ✓"
    echo "║  Failed:         $TESTS_FAILED ✗"
    echo "║  Skipped:        $TESTS_SKIPPED ⊘"
    
    if [[ $TESTS_RUN -gt 0 ]]; then
        local success_rate=$((TESTS_PASSED * 100 / TESTS_RUN))
        echo "║  Success Rate:   ${success_rate}%"
    fi
    
    echo "╚═══════════════════════════════════════════════════════════╝"
    
    # Generate report
    generate_test_report
    
    # Exit code
    [[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
}

main "$@"
