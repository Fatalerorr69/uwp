#!/bin/bash
# uwp-docker.sh - Hlavní spouštěcí skript

set -euo pipefail

# Barvy
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

UWP_DIR="${HOME}/.uwp-docker"

show_help() {
    cat << EOF
UWP Docker Manager v5.0
══════════════════════

Commands:
  start       Start UWP services
  stop        Stop UWP services
  restart     Restart UWP services
  status      Show service status
  logs        Show container logs
  update      Update UWP to latest version
  backup      Create backup
  restore     Restore from backup
  shell       Open shell in container
  purge       Remove all containers and volumes
  help        Show this help

Examples:
  ./uwp-docker.sh start
  ./uwp-docker.sh logs -f
  ./uwp-docker.sh shell uwp-core
  ./uwp-docker.sh backup
EOF
}

start_services() {
    echo "🚀 Starting UWP Docker services..."
    
    # Zkontrolovat Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose is not installed"
        exit 1
    fi
    
    # Vytvořit adresářovou strukturu
    mkdir -p "${UWP_DIR}"/{volumes,configs,ssl,backups}
    
    # Spustit služby
    docker-compose up -d
    
    echo "✅ UWP services started"
    echo ""
    echo "🌐 Access URLs:"
    echo "   Main UI:     http://localhost:8080"
    echo "   AI API:      http://localhost:5000"
    echo "   Dev Server:  http://localhost:3000"
    echo "   Monitoring:  http://localhost:3001"
    echo "   Portainer:   http://localhost:9000"
}

stop_services() {
    echo "🛑 Stopping UWP services..."
    docker-compose down
    echo "✅ Services stopped"
}

backup_data() {
    echo "💾 Creating backup..."
    
    BACKUP_DIR="${UWP_DIR}/backups/uwp_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "${BACKUP_DIR}"
    
    # Backup volumes
    docker run --rm \
        -v uwp-data:/source \
        -v "${BACKUP_DIR}:/backup" \
        alpine tar czf /backup/uwp-data.tar.gz -C /source .
    
    # Backup database
    docker exec uwp-db pg_dump -U uwp uwp > "${BACKUP_DIR}/database.sql"
    
    # Backup konfigurace
    cp -r configs/ "${BACKUP_DIR}/"
    
    echo "✅ Backup created: ${BACKUP_DIR}"
}

restore_backup() {
    if [ -z "${1:-}" ]; then
        echo "Usage: ./uwp-docker.sh restore <backup_directory>"
        exit 1
    fi
    
    echo "🔄 Restoring from backup: $1"
    
    # Zastavit služby
    docker-compose down
    
    # Obnovit data
    docker run --rm \
        -v uwp-data:/target \
        -v "$1:/backup" \
        alpine tar xzf /backup/uwp-data.tar.gz -C /target
    
    # Obnovit databázi
    docker-compose up -d db
    sleep 10
    docker exec -i uwp-db psql -U uwp uwp < "$1/database.sql"
    
    echo "✅ Backup restored"
}

# Hlavní logika
case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        stop_services
        sleep 2
        start_services
        ;;
    status)
        docker-compose ps
        ;;
    logs)
        docker-compose logs "${@:2}"
        ;;
    backup)
        backup_data
        ;;
    restore)
        restore_backup "${2:-}"
        ;;
    shell)
        if [ -z "${2:-}" ]; then
            echo "Usage: ./uwp-docker.sh shell <container_name>"
            exit 1
        fi
        docker exec -it "${2}" bash
        ;;
    update)
        echo "🔄 Updating UWP..."
        git pull origin main
        docker-compose build --no-cache
        docker-compose up -d
        echo "✅ Update completed"
        ;;
    purge)
        echo "⚠️  This will remove ALL UWP containers and volumes!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker-compose down -v --rmi all
            rm -rf "${UWP_DIR}"
            echo "✅ All UWP data removed"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
