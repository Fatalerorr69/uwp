#!/usr/bin/env bash

# UWP Docker Module Setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Docker
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        log_success "Docker installed: $DOCKER_VERSION"
        return 0
    else
        log_warning "Docker is not installed"
        return 1
    fi
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    # Check distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    else
        OS=$(uname -s)
    fi
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            log_info "Installing Docker on Ubuntu/Debian..."
            sudo apt update
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io
            ;;
            
        "CentOS Linux"|"Red Hat Enterprise Linux")
            log_info "Installing Docker on RHEL/CentOS..."
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            ;;
            
        "Darwin") # macOS
            log_info "Please install Docker Desktop for macOS: https://www.docker.com/products/docker-desktop/"
            return 1
            ;;
            
        *)
            log_error "Unsupported OS: $OS"
            log_info "Please install Docker manually: https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully!"
    log_info "You may need to log out and back in for group changes to take effect"
}

# Docker Compose
setup_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose is already installed"
        return
    fi
    
    log_info "Installing Docker Compose..."
    
    # Install Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose installed: $COMPOSE_VERSION"
}

# UWP Docker Templates
setup_uwp_templates() {
    log_info "Setting up UWP Docker templates..."
    
    UWP_DOCKER_DIR="$HOME/.universal-workspace/modules/docker_module"
    mkdir -p "$UWP_DOCKER_DIR/templates"
    
    # Create basic templates
    cat > "$UWP_DOCKER_DIR/templates/node.dockerfile" << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF
    
    cat > "$UWP_DOCKER_DIR/templates/python.dockerfile" << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "main.py"]
EOF
    
    cat > "$UWP_DOCKER_DIR/templates/docker-compose.yml" << 'EOF'
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - .:/app
    environment:
      - NODE_ENV=development
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: example
EOF
    
    log_success "Docker templates created"
}

# Docker Utilities
create_docker_utilities() {
    log_info "Creating Docker utilities..."
    
    UWP_DOCKER_DIR="$HOME/.universal-workspace/modules/docker_module"
    
    # Create docker stats script
    cat > "$UWP_DOCKER_DIR/docker-stats.sh" << 'EOF'
#!/usr/bin/env bash
# UWP Docker Statistics

echo "🐳 Docker Containers:"
echo "===================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📊 Docker Stats:"
echo "================"
docker stats --no-stream 2>/dev/null || echo "Stats not available"

echo ""
echo "🖼️  Docker Images:"
echo "================="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -10
EOF
    
    chmod +x "$UWP_DOCKER_DIR/docker-stats.sh"
    
    # Create docker cleanup script
    cat > "$UWP_DOCKER_DIR/docker-cleanup.sh" << 'EOF'
#!/usr/bin/env bash
# UWP Docker Cleanup

echo "🧹 Cleaning up Docker..."
echo ""

# Stop all containers
echo "Stopping containers..."
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all containers
echo "Removing containers..."
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove all images
echo "Removing images..."
docker rmi $(docker images -q) 2>/dev/null || true

# Remove unused volumes
echo "Removing volumes..."
docker volume prune -f

# Remove unused networks
echo "Removing networks..."
docker network prune -f

echo ""
echo "✅ Docker cleanup complete!"
EOF
    
    chmod +x "$UWP_DOCKER_DIR/docker-cleanup.sh"
    
    log_success "Docker utilities created"
}

# Main function
main() {
    echo "🐳 UWP Docker Module Setup"
    echo "=========================="
    echo ""
    
    # Check if Docker is installed
    if ! check_docker; then
        echo "Docker is required for this module."
        read -p "Do you want to install Docker? [y/N]: " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_docker
        else
            log_warning "Skipping Docker installation"
            exit 0
        fi
    fi
    
    # Setup Docker Compose
    setup_docker_compose
    
    # Setup UWP templates
    setup_uwp_templates
    
    # Create utilities
    create_docker_utilities
    
    echo ""
    echo "🎉 UWP Docker Module setup complete!"
    echo ""
    echo "Available commands:"
    echo "  docker-stats.sh    - Show Docker statistics"
    echo "  docker-cleanup.sh  - Clean Docker resources"
    echo ""
    echo "Templates available in:"
    echo "  ~/.universal-workspace/modules/docker_module/templates/"
}

# Run main function
main "$@"
