#!/usr/bin/env bash
################################################################################
# AI Code Analyzer - UWP v5.0
# Pokročilá analýza kódu s AI návrhy
################################################################################

set -euo pipefail

UWP_HOME="${UWP_HOME:-${HOME}/.uwp}"
source "${UWP_HOME}/lib/uwp-core.sh" 2>/dev/null || exit 1

PROJECT_PATH="${1:-.}"
REPORT_DIR="${UWP_HOME}/data/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/analysis_${TIMESTAMP}.md"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ============================================================================
# ANALYSIS FUNCTIONS
# ============================================================================

analyze_project_stats() {
    echo "📊 Collecting project statistics..."
    
    local total_files=$(find "$PROJECT_PATH" -type f 2>/dev/null | wc -l)
    local total_dirs=$(find "$PROJECT_PATH" -type d 2>/dev/null | wc -l)
    local total_size=$(du -sh "$PROJECT_PATH" 2>/dev/null | cut -f1)
    local total_lines=$(find "$PROJECT_PATH" -type f -name "*.js" -o -name "*.py" -o -name "*.java" -o -name "*.cpp" 2>/dev/null | xargs cat 2>/dev/null | wc -l)
    
    cat >> "$REPORT_FILE" << EOF
# 📊 Project Analysis Report

**Generated:** $(date)
**Project:** $(basename "$PROJECT_PATH")
**Location:** $PROJECT_PATH

## Statistics

| Metric | Value |
|--------|-------|
| Total Files | $total_files |
| Total Directories | $total_dirs |
| Total Size | $total_size |
| Lines of Code | $total_lines |

EOF
}

analyze_file_types() {
    echo "📁 Analyzing file types..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## File Distribution

EOF
    
    # Count by extension
    find "$PROJECT_PATH" -type f 2>/dev/null | \
        sed 's/.*\.//' | \
        sort | uniq -c | sort -rn | head -10 | \
        while read count ext; do
            echo "| \`.$ext\` | $count |" >> "$REPORT_FILE"
        done
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

analyze_code_quality() {
    echo "🔍 Analyzing code quality..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## Code Quality Issues

EOF
    
    # Find TODOs, FIXMEs, HACKs
    local issues=$(grep -RniE "TODO|FIXME|HACK|BUG|XXX" "$PROJECT_PATH" 2>/dev/null | head -20)
    
    if [[ -n "$issues" ]]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$issues" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    else
        echo "✓ No immediate issues found" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

analyze_dependencies() {
    echo "📦 Analyzing dependencies..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## Dependencies

EOF
    
    # Check for package.json
    if [[ -f "$PROJECT_PATH/package.json" ]]; then
        echo "### Node.js (package.json)" >> "$REPORT_FILE"
        echo "\`\`\`json" >> "$REPORT_FILE"
        jq '.dependencies // {}' "$PROJECT_PATH/package.json" 2>/dev/null >> "$REPORT_FILE" || \
            grep -A 20 '"dependencies"' "$PROJECT_PATH/package.json" 2>/dev/null >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Check for requirements.txt
    if [[ -f "$PROJECT_PATH/requirements.txt" ]]; then
        echo "### Python (requirements.txt)" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        head -20 "$PROJECT_PATH/requirements.txt" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    # Check for Cargo.toml
    if [[ -f "$PROJECT_PATH/Cargo.toml" ]]; then
        echo "### Rust (Cargo.toml)" >> "$REPORT_FILE"
        echo "\`\`\`toml" >> "$REPORT_FILE"
        grep -A 10 '\[dependencies\]' "$PROJECT_PATH/Cargo.toml" 2>/dev/null >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

analyze_complexity() {
    echo "📈 Analyzing complexity..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## Complexity Analysis

EOF
    
    # Find largest files
    echo "### Largest Files" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    find "$PROJECT_PATH" -type f -name "*.js" -o -name "*.py" -o -name "*.java" 2>/dev/null | \
        xargs wc -l 2>/dev/null | sort -rn | head -10 | \
        while read lines file; do
            if [[ "$file" != "total" ]]; then
                echo "- \`$(basename "$file")\`: $lines lines" >> "$REPORT_FILE"
            fi
        done
    
    # Find deeply nested directories
    echo "" >> "$REPORT_FILE"
    echo "### Directory Depth" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    find "$PROJECT_PATH" -type d 2>/dev/null | \
        awk -F'/' '{print NF-1, $0}' | sort -rn | head -5 | \
        while read depth dir; do
            echo "- Depth $depth: \`$(basename "$dir")\`" >> "$REPORT_FILE"
        done
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

analyze_security() {
    echo "🔒 Running security checks..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## Security Scan

EOF
    
    # Check for common security issues
    local security_patterns=(
        "password"
        "secret"
        "api_key"
        "apikey"
        "token"
        "credentials"
        "private_key"
    )
    
    local found_issues=0
    
    for pattern in "${security_patterns[@]}"; do
        local matches=$(grep -RniE "$pattern" "$PROJECT_PATH" 2>/dev/null | grep -v ".git" | grep -v "node_modules" | head -5)
        if [[ -n "$matches" ]]; then
            echo "⚠️ Found potential **$pattern** in code:" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
            echo "$matches" >> "$REPORT_FILE"
            echo "\`\`\`" >> "$REPORT_FILE"
            ((found_issues++))
        fi
    done
    
    if [[ $found_issues -eq 0 ]]; then
        echo "✓ No obvious security issues detected" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

ai_suggestions() {
    echo "🤖 Generating AI suggestions..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## AI Recommendations

EOF
    
    if command -v ollama &>/dev/null; then
        # Prepare project summary for AI
        local summary="Project at $PROJECT_PATH with:"
        summary="$summary\n- Files: $(find "$PROJECT_PATH" -type f 2>/dev/null | wc -l)"
        summary="$summary\n- Languages: $(find "$PROJECT_PATH" -type f 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -3 | awk '{print $2}' | tr '\n' ', ')"
        
        echo "Generating AI analysis (this may take a moment)..." >&2
        
        # Get AI suggestions
        local ai_response=$(timeout 30s ollama run phi3:mini "As a code reviewer, analyze this project and provide 5 specific improvement suggestions: $summary" 2>/dev/null || echo "AI analysis timed out")
        
        if [[ "$ai_response" != *"timed out"* ]]; then
            echo "$ai_response" >> "$REPORT_FILE"
        else
            cat >> "$REPORT_FILE" << 'EOF'
### General Recommendations

1. **Code Organization**
   - Review file structure and ensure logical grouping
   - Consider separating concerns (models, views, controllers)

2. **Documentation**
   - Add README.md with setup instructions
   - Document complex functions and modules
   - Include inline comments for tricky logic

3. **Testing**
   - Implement unit tests for critical functions
   - Add integration tests for main workflows
   - Set up CI/CD pipeline

4. **Performance**
   - Profile code for bottlenecks
   - Optimize database queries
   - Implement caching where appropriate

5. **Security**
   - Review authentication and authorization
   - Validate all user inputs
   - Keep dependencies up to date
EOF
        fi
    else
        cat >> "$REPORT_FILE" << 'EOF'
### General Recommendations

1. **Install AI Module** for detailed analysis: `uwp modules install ai`
2. **Code Review**: Review for security vulnerabilities
3. **Documentation**: Ensure README and inline docs are complete
4. **Testing**: Add comprehensive test coverage
5. **Dependencies**: Keep all dependencies updated
EOF
    fi
    
    cat >> "$REPORT_FILE" << 'EOF'

EOF
}

generate_action_plan() {
    echo "📋 Creating action plan..."
    
    cat >> "$REPORT_FILE" << 'EOF'
## Action Plan

### Priority 1 - Critical
- [ ] Address security issues if any
- [ ] Fix broken dependencies
- [ ] Resolve TODO/FIXME items

### Priority 2 - Important
- [ ] Improve code documentation
- [ ] Add unit tests
- [ ] Refactor complex files

### Priority 3 - Enhancement
- [ ] Optimize performance
- [ ] Update dependencies
- [ ] Improve project structure

---

*Report generated by Universal Workspace Platform v5.0*
EOF
}

# ============================================================================
# MAIN ANALYSIS
# ============================================================================

main() {
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  AI Code Analyzer - UWP v5.0"
    echo "═══════════════════════════════════════════════"
    echo ""
    
    # Validate project path
    if [[ ! -d "$PROJECT_PATH" ]]; then
        echo -e "${YELLOW}Error: Directory not found: $PROJECT_PATH${NC}" >&2
        exit 1
    fi
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Initialize report
    > "$REPORT_FILE"
    
    echo -e "${BLUE}Analyzing project: ${CYAN}$(basename "$PROJECT_PATH")${NC}"
    echo ""
    
    # Run analyses
    analyze_project_stats
    analyze_file_types
    analyze_code_quality
    analyze_dependencies
    analyze_complexity
    analyze_security
    ai_suggestions
    generate_action_plan
    
    echo ""
    echo -e "${GREEN}✓ Analysis complete!${NC}"
    echo -e "${BLUE}Report saved to: ${CYAN}${REPORT_FILE}${NC}"
    echo ""
    echo "View report:"
    echo "  cat $REPORT_FILE"
    echo ""
    echo "Or open in editor:"
    echo "  nano $REPORT_FILE"
    echo ""
}

main "$@"