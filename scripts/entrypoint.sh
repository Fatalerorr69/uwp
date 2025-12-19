#!/bin/bash
# scripts/entrypoint.sh

set -euo pipefail

echo "🚀 Starting UWP v5.0.0"

# Načtení environment proměnných
source /opt/uwp/scripts/load_env.sh

# Vytvoření struktury adresářů
mkdir -p /opt/uwp/{data,logs,projects,cache,configs}

# Inicializace databáze
if [ "$INIT_DB" = "true" ]; then
    echo "📦 Initializing database..."
    python3 /opt/uwp/scripts/init_db.py
fi

# Spuštění hlavních služeb
echo "🔧 Starting UWP services..."

# Spustit AI modul v pozadí
if [ "$ENABLE_AI" = "true" ]; then
    echo "🤖 Starting AI module..."
    python3 /opt/uwp/modules/ai_module/ai_main.py --service &
    AI_PID=$!
fi

# Spustit dev server
if [ "$ENABLE_DEV" = "true" ]; then
    echo "💻 Starting development server..."
    node /opt/uwp/modules/dev_module/dev_server.js &
    DEV_PID=$!
fi

# Hlavní proces
echo "✅ UWP is ready!"
exec "$@"
