#!/bin/bash
# scripts/healthcheck.sh

# Kontrola, zda jsou všechny služby funkční

# Kontrola AI modulu
if ! curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "AI module is not responding"
    exit 1
fi

# Kontrola dev serveru
if ! curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "Dev server is not responding"
    exit 1
fi

# Kontrola databáze
if ! pg_isready -h uwp-db -p 5432 > /dev/null 2>&1; then
    echo "Database is not ready"
    exit 1
fi

# Kontrola Redis
if ! redis-cli -h uwp-redis ping > /dev/null 2>&1; then
    echo "Redis is not responding"
    exit 1
fi

echo "All services are healthy"
exit 0
