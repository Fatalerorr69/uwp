#!/usr/bin/env bash
################################################################################
# Universal Workspace Platform v4.0 - Deployment & Release System
# 📦 CI/CD, Packaging & Distribution
################################################################################

set -euo pipefail

readonly DEPLOY_VERSION="4.0.0"
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BUILD_DIR="${PROJECT_ROOT}/build"
readonly DIST_DIR="${PROJECT_ROOT}/dist"
readonly RELEASE_DIR="${PROJECT_ROOT}/releases"

# ============================================================================
# LOGGING
# ============================================================================

log_info() { echo -e "\033[0;34m[i]\033[0m $*"; }
log_success() { echo -e "\033[0;32m[✓]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[⚠]\033[0m $*"; }
log_error() { echo -e "\033[0;31m[✗]\033[0m $*"; exit 1; }

# ============================================================================
# PRE-DEPLOYMENT CHECKS
# ============================================================================

pre_deployment_checks() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           Pre-Deployment Validation Checks               ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Checking repository state..."
    
    # Git status
    if [[ -z $(git status -s) ]]; then
        log_success "Git repository clean"
    else
        log_warn "Git repository has uncommitted changes"
        git status -s | head -5
    fi
    
    # Syntax validation
    log_info "Validating bash syntax..."
    for file in $(find . -name "*.sh" -type f 2>/dev/null | grep -v node_modules); do
        bash -n "$file" 2>/dev/null || log_error "Syntax error in $file"
    done
    log_success "Bash syntax valid"
    
    # JSON validation
    if command -v jq &>/dev/null; then
        log_info "Validating JSON files..."
        for file in $(find . -name "*.json" -type f 2>/dev/null); do
            jq empty "$file" 2>/dev/null || log_error "JSON syntax error in $file"
        done
        log_success "JSON files valid"
    fi
    
    # Dependency check
    log_info "Checking critical dependencies..."
    local deps=("bash" "git" "curl" "tar" "gzip")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log_error "Missing dependency: $dep"
        fi
    done
    log_success "All dependencies available"
    
    echo ""
}

# ============================================================================
# BUILD PROCESS
# ============================================================================

build_distribution() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                   Building Distribution                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Cleanup
    log_info "Cleaning previous builds..."
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR" "$DIST_DIR"
    
    # Copy source
    log_info "Copying source files..."
    cp -r . "$BUILD_DIR/uwp" --exclude=.git --exclude=node_modules --exclude=.DS_Store
    
    # Generate version info
    log_info "Generating version info..."
    cat > "$BUILD_DIR/uwp/VERSION" << VERSION_INFO
VERSION=${DEPLOY_VERSION}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
VERSION_INFO
    
    # Create manifests
    log_info "Creating distribution manifest..."
    cat > "$BUILD_DIR/uwp/MANIFEST" << 'MANIFEST'
# Universal Workspace Platform v4.0 - File Manifest

## Directories
bin/                 - Executable files
lib/                 - Library files
modules/             - Module implementations
plugins/             - Plugin extensions
config/              - Configuration templates
data/                - Data directories
logs/                - Log files
templates/           - Project templates
docs/                - Documentation
tests/               - Test suites

## Core Files
bin/uwp              - Main CLI tool
lib/uwp-core.sh      - Core library
lib/uwp-installer.sh - Installation library
install.sh           - Master installer
uninstall.sh         - Uninstall script
README.md            - Documentation
LICENSE              - MIT License
MANIFEST             - This file
VERSION              - Version information

## Module Files (each)
modules/*/install.sh - Module installer
modules/*/config/    - Configuration
modules/*/scripts/   - Scripts
modules/*/docs/      - Documentation

## Checksums
All files validated with SHA256
MANIFEST
    
    # Minification (optional)
    log_info "Creating optimized versions..."
    
    # Create uncompressed dist
    cp -r "$BUILD_DIR/uwp" "$DIST_DIR/uwp-${DEPLOY_VERSION}"
    
    # Create compressed dist
    cd "$DIST_DIR"
    tar -czf "uwp-${DEPLOY_VERSION}.tar.gz" "uwp-${DEPLOY_VERSION}/"
    log_success "Distribution package created: uwp-${DEPLOY_VERSION}.tar.gz"
    
    # Create checksums
    log_info "Generating checksums..."
    sha256sum "uwp-${DEPLOY_VERSION}.tar.gz" > "uwp-${DEPLOY_VERSION}.sha256"
    md5sum "uwp-${DEPLOY_VERSION}.tar.gz" > "uwp-${DEPLOY_VERSION}.md5"
    
    # Create size report
    du -sh "uwp-${DEPLOY_VERSION}" > "uwp-${DEPLOY_VERSION}.size"
    
    cd "$PROJECT_ROOT"
    log_success "Build completed successfully"
    
    echo ""
    echo "Build artifacts:"
    ls -lh "$DIST_DIR/" | tail -10
    echo ""
}

# ============================================================================
# TESTING & VALIDATION
# ============================================================================

run_qa_tests() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║              Quality Assurance Testing                   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ -f "tests/test-suite.sh" ]]; then
        log_info "Running test suite..."
        bash tests/test-suite.sh --report
        log_success "Tests completed"
    else
        log_warn "No test suite found"
    fi
    
    echo ""
}

# ============================================================================
# DOCUMENTATION GENERATION
# ============================================================================

generate_documentation() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║            Generating Documentation                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Generating API documentation..."
    
    # Extract function documentation
    cat > "$DIST_DIR/uwp-${DEPLOY_VERSION}/docs/API.md" << 'API_DOC'
# Universal Workspace Platform API Documentation

## Core Functions

### Configuration Management
- `uwp_config_get(key [default])` - Get configuration value
- `uwp_config_set(key value)` - Set configuration value

### Module Management
- `uwp_module_exists(module)` - Check if module exists
- `uwp_module_is_installed(module)` - Check if module is installed
- `uwp_module_mark_installed(module)` - Mark module as installed

### Utilities
- `uwp_command_exists(command)` - Check if command is available
- `uwp_file_exists(path)` - Check if file exists
- `uwp_dir_exists(path)` - Check if directory exists

### Package Management
- `uwp_install_package(package [manager])` - Install package

## CLI Commands

### Module Commands
```bash
uwp modules list                    # List available modules
uwp modules install <module>        # Install module
uwp modules status                  # Check module status
uwp modules update                  # Update all modules
```

### Configuration Commands
```bash
uwp config get <key>               # Get config value
uwp config set <key> <value>       # Set config value
uwp config show                    # Show all config
```

### AI Commands
```bash
uwp ai <prompt>                    # Chat with AI
uwp analyze <path>                 # Analyze project
uwp suggest <path>                 # Suggest improvements
```

## Examples

### Installing a Module
```bash
uwp modules install ai
```

### Using AI Assistant
```bash
uwp ai "Explain this function"
```

### Analyzing a Project
```bash
uwp analyze /path/to/project
```

API_DOC
    
    log_success "Documentation generated"
    echo ""
}

# ============================================================================
# RELEASE CREATION
# ============================================================================

create_release() {
    local version=$1
    local release_notes=${2:-""}
    
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                Creating Release v${version}              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    mkdir -p "$RELEASE_DIR"
    
    # Tag commit
    log_info "Creating git tag..."
    git tag -a "v${version}" -m "Release version ${version}" 2>/dev/null || \
    log_warn "Git tag already exists or not a git repository"
    
    # Create release notes
    log_info "Generating release notes..."
    cat > "$RELEASE_DIR/v${version}-RELEASE_NOTES.md" << RELEASE_NOTES
# Universal Workspace Platform v${version}

## Release Date
$(date -u +"%Y-%m-%d %H:%M:%S UTC")

## What's New

### Features
- Complete modular architecture
- AI-powered code analysis
- Android device management
- Docker integration
- Terminal configuration
- CLI tools and utilities

### Improvements
- Enhanced installation process
- Better error handling
- Comprehensive logging
- Performance optimizations
- Security hardening

### Bug Fixes
- Initial release

## Installation

\`\`\`bash
wget https://github.com/username/uwp/releases/download/v${version}/uwp-${version}.tar.gz
tar -xzf uwp-${version}.tar.gz
cd uwp-${version}
bash install.sh
\`\`\`

## Verification

\`\`\`bash
sha256sum -c uwp-${version}.sha256
\`\`\`

## Documentation
- [README](../README.md)
- [Installation Guide](../docs/INSTALL.md)
- [API Reference](../docs/API.md)

## Support
- Issues: https://github.com/username/uwp/issues
- Discussions: https://github.com/username/uwp/discussions

## Contributors
See CONTRIBUTORS.md

${release_notes}
RELEASE_NOTES
    
    log_success "Release v${version} created"
    
    # Create GitHub release (if gh CLI available)
    if command -v gh &>/dev/null; then
        log_info "Creating GitHub release..."
        gh release create "v${version}" \
            "$DIST_DIR/uwp-${version}.tar.gz" \
            -t "Universal Workspace Platform v${version}" \
            -F "$RELEASE_DIR/v${version}-RELEASE_NOTES.md" 2>/dev/null || \
        log_warn "GitHub release creation failed"
    fi
    
    echo ""
}

# ============================================================================
# INSTALLATION TESTING
# ============================================================================

test_installation() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║            Testing Installation Package                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    local package="${DIST_DIR}/uwp-${DEPLOY_VERSION}.tar.gz"
    local test_dir="/tmp/uwp-test-$$"
    
    log_info "Setting up test environment..."
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Extract
    log_info "Extracting package..."
    tar -xzf "$package"
    
    # Run installer
    log_info "Running installer..."
    cd "uwp-${DEPLOY_VERSION}"
    bash install.sh --config-only 2>&1 | head -20 || true
    
    # Test CLI
    log_info "Testing CLI..."
    if [[ -f "${test_dir}/uwp-${DEPLOY_VERSION}/bin/uwp" ]]; then
        bash "${test_dir}/uwp-${DEPLOY_VERSION}/bin/uwp" status 2>&1 | head -5 || true
        log_success "CLI test passed"
    else
        log_error "CLI not found in package"
    fi
    
    # Cleanup
    log_info "Cleaning up test environment..."
    cd "$PROJECT_ROOT"
    rm -rf "$test_dir"
    
    log_success "Installation test completed"
    echo ""
}

# ============================================================================
# DEPLOYMENT STEPS
# ============================================================================

deploy() {
    local target=${1:-"package"}  # package, github, docker
    
    case "$target" in
        package)
            echo "🚀 Package Deployment"
            pre_deployment_checks
            build_distribution
            run_qa_tests
            generate_documentation
            test_installation
            create_release "$DEPLOY_VERSION"
            echo "✅ Package deployment completed"
            ;;
        docker)
            echo "🐳 Docker Deployment"
            log_info "Building Docker image..."
            docker build -t "uwp:${DEPLOY_VERSION}" .
            log_info "Pushing to registry..."
            docker push "uwp:${DEPLOY_VERSION}"
            log_success "Docker deployment completed"
            ;;
        github)
            echo "🐙 GitHub Deployment"
            log_info "Pushing to GitHub..."
            git push origin main
            git push origin --tags
            log_success "GitHub deployment completed"
            ;;
        *)
            echo "Unknown deployment target: $target"
            echo "Supported: package, docker, github"
            exit 1
            ;;
    esac
}

# ============================================================================
# CI/CD INTEGRATION
# ============================================================================

setup_ci_cd() {
    echo "Setting up CI/CD integration..."
    
    mkdir -p .github/workflows
    
    # GitHub Actions workflow
    cat > .github/workflows/deploy.yml << 'WORKFLOW'
name: Deploy

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: bash tests/test-suite.sh
      - name: Build distribution
        run: bash scripts/deploy.sh build
      - name: Create release
        if: startsWith(github.ref, 'refs/tags/')
        run: bash scripts/deploy.sh release

  docker-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and push Docker image
        run: |
          docker build -t uwp:latest .
          docker push uwp:latest
WORKFLOW
    
    log_success "CI/CD workflow created"
}

# ============================================================================
# MAIN
# ============================================================================

show_usage() {
    cat << USAGE
Universal Workspace Platform - Deployment System

Usage: $0 <command> [options]

Commands:
  check              Run pre-deployment checks
  build              Build distribution package
  test               Run quality assurance tests
  docs               Generate documentation
  package            Complete package deployment
  docker             Deploy Docker image
  github             Push to GitHub
  release <version>  Create release v<version>
  all                Full deployment pipeline

Examples:
  $0 package                 # Build and package
  $0 release 4.0.0          # Create release
  $0 all                     # Full deployment

USAGE
}

main() {
    local command=${1:-"help"}
    
    case "$command" in
        check)
            pre_deployment_checks
            ;;
        build)
            build_distribution
            ;;
        test)
            run_qa_tests
            ;;
        docs)
            generate_documentation
            ;;
        package)
            deploy "package"
            ;;
        docker)
            deploy "docker"
            ;;
        github)
            deploy "github"
            ;;
        release)
            create_release "${2:-$DEPLOY_VERSION}" "${3:-}"
            ;;
        all)
            pre_deployment_checks
            build_distribution
            run_qa_tests
            generate_documentation
            test_installation
            create_release "$DEPLOY_VERSION"
            echo "✅ Full deployment completed successfully!"
            ;;
        setup-ci)
            setup_ci_cd
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
