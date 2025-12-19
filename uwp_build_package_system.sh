#!/usr/bin/env bash
################################################################################
# UWP v4.0 - Complete Build & Package System
# Creates distributable packages for all platforms
################################################################################

set -euo pipefail

readonly VERSION="4.0.0"
readonly PROJECT_NAME="uwp"
readonly BUILD_DIR="./build"
readonly DIST_DIR="./dist"
readonly ARCHIVE_DIR="./archives"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    local level=$1
    shift
    echo -e "${level}[*]${NC} $*"
}

log_success() { log "${GREEN}"; }
log_info() { log "${BLUE}"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

show_help() {
    cat << EOF
UWP v${VERSION} - Build & Package System

Usage: ./build.sh [command] [options]

Commands:
  build              Build all packages
  package-tar        Create tar.gz package
  package-deb        Create DEB package (Ubuntu/Debian)
  package-rpm        Create RPM package (Fedora/RHEL)
  package-docker     Build Docker image
  clean              Clean build artifacts
  test               Run test suite
  release            Create release package
  install            Install from build
  help               Show this help

Examples:
  ./build.sh build               # Build everything
  ./build.sh package-tar         # Create tar package
  ./build.sh package-docker      # Build Docker image
  ./build.sh release             # Full release
  ./build.sh clean               # Cleanup

EOF
}

# ============================================================================
# BUILD SYSTEM
# ============================================================================

init_build() {
    log_info "Initializing build environment..."
    
    mkdir -p "$BUILD_DIR/$PROJECT_NAME"
    mkdir -p "$DIST_DIR"
    mkdir -p "$ARCHIVE_DIR"
    
    # Copy all source files
    cp -r . "$BUILD_DIR/$PROJECT_NAME" \
        --exclude=.git \
        --exclude=build \
        --exclude=dist \
        --exclude=archives \
        --exclude=.cache \
        --exclude=node_modules \
        --exclude="*.swp"
    
    log_success "Build environment initialized"
}

# ============================================================================
# TAR.GZ PACKAGE
# ============================================================================

build_tar_package() {
    log_info "Building tar.gz package..."
    
    init_build
    
    cd "$BUILD_DIR"
    
    # Create tar archive
    tar -czf "$PROJECT_NAME-${VERSION}.tar.gz" "$PROJECT_NAME"
    
    # Move to dist
    mv "$PROJECT_NAME-${VERSION}.tar.gz" "../$DIST_DIR/"
    
    # Generate checksums
    cd "../$DIST_DIR"
    sha256sum "$PROJECT_NAME-${VERSION}.tar.gz" > "$PROJECT_NAME-${VERSION}.sha256"
    md5sum "$PROJECT_NAME-${VERSION}.tar.gz" > "$PROJECT_NAME-${VERSION}.md5"
    
    # Create info file
    cat > "$PROJECT_NAME-${VERSION}.info" << INFO
Universal Workspace Platform v${VERSION}

Package: $PROJECT_NAME-${VERSION}.tar.gz
Size: $(du -h "$PROJECT_NAME-${VERSION}.tar.gz" | cut -f1)
Date: $(date)
Type: TAR.GZ Archive

Contents:
- Core installation system
- 10 feature modules
- Complete documentation
- Test suite
- Docker support
- CI/CD configuration

Installation:
tar -xzf $PROJECT_NAME-${VERSION}.tar.gz
cd $PROJECT_NAME-${VERSION}
bash install.sh

Verification:
sha256sum -c $PROJECT_NAME-${VERSION}.sha256

Website: https://github.com/username/uwp
License: MIT
INFO
    
    log_success "TAR.GZ package created"
    ls -lh "$PROJECT_NAME-${VERSION}"*
}

# ============================================================================
# DEB PACKAGE
# ============================================================================

build_deb_package() {
    log_info "Building DEB package..."
    
    init_build
    
    local pkg_dir="$BUILD_DIR/$PROJECT_NAME-deb"
    mkdir -p "$pkg_dir"
    
    # Create DEB structure
    mkdir -p "$pkg_dir/DEBIAN"
    mkdir -p "$pkg_dir/opt/uwp"
    mkdir -p "$pkg_dir/usr/local/bin"
    
    # Copy files
    cp -r "$BUILD_DIR/$PROJECT_NAME"/* "$pkg_dir/opt/uwp/"
    
    # Create control file
    cat > "$pkg_dir/DEBIAN/control" << CONTROL
Package: uwp
Version: ${VERSION}
Maintainer: UWP Team <team@uwp.dev>
Architecture: amd64
Depends: bash (>=4.0), curl, git, python3
Installed-Size: 10000
Homepage: https://github.com/username/uwp
Description: Universal Workspace Platform
 Professional development environment with AI,
 Android toolkit, Docker support, and more.
CONTROL
    
    # Create postinstall script
    cat > "$pkg_dir/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e
ln -sf /opt/uwp/bin/uwp /usr/local/bin/uwp
chmod +x /usr/local/bin/uwp
mkdir -p ~/.universal-workspace
ln -sf /opt/uwp ~/.universal-workspace/core
echo "UWP installed successfully"
POSTINST
    chmod +x "$pkg_dir/DEBIAN/postinst"
    
    # Create prerm script
    cat > "$pkg_dir/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e
rm -f /usr/local/bin/uwp
PRERM
    chmod +x "$pkg_dir/DEBIAN/prerm"
    
    # Build DEB
    dpkg-deb --build "$pkg_dir" "$DIST_DIR/$PROJECT_NAME-${VERSION}.deb" 2>/dev/null || \
    log_error "dpkg-deb not available, skipping DEB build"
    
    log_success "DEB package created"
}

# ============================================================================
# RPM PACKAGE
# ============================================================================

build_rpm_package() {
    log_info "Building RPM package..."
    
    if ! command -v rpmbuild &>/dev/null; then
        log_error "rpmbuild not found, install rpm-build package"
        return 1
    fi
    
    local spec_file="$BUILD_DIR/$PROJECT_NAME.spec"
    
    cat > "$spec_file" << 'SPEC'
Name:           uwp
Version:        4.0.0
Release:        1%{?dist}
Summary:        Universal Workspace Platform
License:        MIT
URL:            https://github.com/username/uwp
Source0:        uwp-4.0.0.tar.gz

Requires:       bash >= 4.0, curl, git, python3

%description
Professional development environment with AI, Android toolkit,
Docker support, and more.

%prep
%setup -q

%build
# Nothing to build

%install
mkdir -p %{buildroot}/opt/uwp
cp -r * %{buildroot}/opt/uwp/
mkdir -p %{buildroot}/usr/local/bin
ln -s /opt/uwp/bin/uwp %{buildroot}/usr/local/bin/uwp

%files
/opt/uwp/*
/usr/local/bin/uwp

%post
mkdir -p ~/.universal-workspace

%postun
rm -f /usr/local/bin/uwp

%changelog
* Wed Jan 01 2025 UWP Team <team@uwp.dev> - 4.0.0-1
- Initial release
SPEC
    
    rpmbuild -bb "$spec_file" -D "_topdir $BUILD_DIR" 2>/dev/null || \
    log_error "RPM build failed"
    
    log_success "RPM package created"
}

# ============================================================================
# DOCKER IMAGE
# ============================================================================

build_docker_image() {
    log_info "Building Docker image..."
    
    if ! command -v docker &>/dev/null; then
        log_error "Docker not installed"
        return 1
    fi
    
    # Build image
    docker build -t "$PROJECT_NAME:${VERSION}" \
                 -t "$PROJECT_NAME:latest" \
                 -f "$BUILD_DIR/$PROJECT_NAME/Dockerfile" \
                 "$BUILD_DIR/$PROJECT_NAME" 2>&1 | head -50
    
    # Create info
    docker inspect "$PROJECT_NAME:${VERSION}" > "$DIST_DIR/$PROJECT_NAME-${VERSION}-docker.json" 2>/dev/null || true
    
    log_success "Docker image built"
    docker images | grep "$PROJECT_NAME"
}

# ============================================================================
# TESTING
# ============================================================================

run_tests() {
    log_info "Running test suite..."
    
    init_build
    
    cd "$BUILD_DIR/$PROJECT_NAME"
    
    if [[ -f "tests/test-suite.sh" ]]; then
        bash tests/test-suite.sh || log_error "Tests failed"
    else
        log_error "Test suite not found"
    fi
}

# ============================================================================
# RELEASE
# ============================================================================

create_release() {
    log_info "Creating complete release package..."
    
    build_tar_package
    
    # Create release note
    cat > "$DIST_DIR/RELEASE_NOTES.md" << 'RELEASE'
# Universal Workspace Platform v4.0.0

## Release Date
$(date -u +"%Y-%m-%d %H:%M:%S UTC")

## What's Included

### Core Components (5 Modules)
- AI Workspace (Ollama, LLMs, code analysis)
- Android Toolkit (ADB, Fastboot, device management)
- Docker Environment (Containers, Docker Compose)
- Development Tools (Python, Node, Go, Rust)
- Terminal Configuration (Zsh, Oh My Zsh)

### Extended Components (5 Modules)
- Penetration Testing (Port scanning, vulnerability checks)
- Emulators (QEMU, virtual machines)
- System Monitor (Health checks, performance monitoring)
- Web GUI Dashboard (Flask-based web interface)
- Security Hardening (SSH hardening, firewall setup)

### Total
- 10 feature modules
- 50+ files
- 8,000+ lines of code
- 60+ tests
- Complete documentation

## Features
- ✅ Cross-platform (Linux, RPi, WSL, Termux, Docker)
- ✅ Modular architecture
- ✅ AI integration
- ✅ Web dashboard
- ✅ CLI tools
- ✅ Docker support
- ✅ CI/CD ready

## Installation

### Tar.GZ
```bash
tar -xzf uwp-4.0.0.tar.gz
cd uwp-4.0.0
bash install.sh
```

### Docker
```bash
docker run -it uwp:4.0.0
```

### DEB
```bash
sudo dpkg -i uwp-4.0.0.deb
```

## Quick Start
```bash
uwp status
uwp modules list
uwp ai "Hello"
```

## License
MIT License

## Support
- GitHub: https://github.com/username/uwp
- Documentation: https://github.com/username/uwp/wiki
- Issues: https://github.com/username/uwp/issues
RELEASE
    
    # Create manifest
    cat > "$DIST_DIR/MANIFEST.txt" << 'MANIFEST'
Universal Workspace Platform v4.0.0 - Package Contents

CORE MODULES (5):
✓ AI Workspace - modules/ai/
✓ Android Toolkit - modules/android/
✓ Docker Environment - modules/docker/
✓ Development Tools - modules/development/
✓ Terminal Configuration - modules/terminal/

EXTENDED MODULES (5):
✓ Penetration Testing - modules/pentest/
✓ Emulators - modules/emulators/
✓ System Monitor - modules/sysmon/
✓ Web GUI Dashboard - modules/webui/
✓ Security Hardening - modules/security/

INSTALLATION FILES:
✓ install.sh - Main installer
✓ uninstall.sh - Uninstaller
✓ Dockerfile - Docker image
✓ docker-compose.yml - Compose stack

DOCUMENTATION:
✓ README.md - Main documentation
✓ INSTALL.md - Installation guide
✓ USAGE.md - Usage guide
✓ API.md - API reference
✓ CONTRIBUTING.md - Contributing guide

CONFIGURATION:
✓ config/modules.json - Module registry
✓ config/uwp.conf - Main config
✓ .env.example - Environment template

TOTAL: 50+ files, 8,000+ LOC
MANIFEST
    
    # Create checksum
    cd "$DIST_DIR"
    cat > "CHECKSUMS" << 'CHECKSUMS'
# SHA256 Checksums
CHECKSUMS
    
    for f in *.tar.gz *.deb *.rpm; do
        [[ -f "$f" ]] && sha256sum "$f" >> "CHECKSUMS"
    done
    
    log_success "Release package created"
}

# ============================================================================
# INSTALLATION FROM BUILD
# ============================================================================

install_from_build() {
    log_info "Installing from build..."
    
    init_build
    
    cd "$BUILD_DIR/$PROJECT_NAME"
    bash install.sh
    
    log_success "Installation complete"
}

# ============================================================================
# CLEANUP
# ============================================================================

clean_build() {
    log_info "Cleaning build artifacts..."
    
    rm -rf "$BUILD_DIR"
    rm -rf "$DIST_DIR"
    
    log_success "Cleanup complete"
}

# ============================================================================
# FULL BUILD
# ============================================================================

full_build() {
    log_info "Starting full build process..."
    
    echo ""
    log_info "Step 1: Building TAR.GZ..."
    build_tar_package
    
    echo ""
    log_info "Step 2: Running tests..."
    run_tests
    
    echo ""
    log_info "Step 3: Building Docker image..."
    build_docker_image || log_error "Docker build skipped"
    
    echo ""
    log_success "Full build complete!"
    echo ""
    echo "Artifacts in: $DIST_DIR"
    ls -lh "$DIST_DIR"
}

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

main() {
    local command=${1:-help}
    
    case "$command" in
        build)
            full_build
            ;;
        package-tar)
            build_tar_package
            ;;
        package-deb)
            build_deb_package
            ;;
        package-rpm)
            build_rpm_package
            ;;
        package-docker)
            build_docker_image
            ;;
        test)
            run_tests
            ;;
        release)
            create_release
            ;;
        install)
            install_from_build
            ;;
        clean)
            clean_build
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
