#!/usr/bin/env bash

# UWP Dev Module Environment Setup

echo "🚀 Setting up UWP Development Environment..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed!"
    echo "📦 Installing Node.js..."
    
    # Try to install Node.js
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y nodejs npm
    elif command -v yum &> /dev/null; then
        sudo yum install -y nodejs npm
    elif command -v brew &> /dev/null; then
        brew install node
    else
        echo "⚠️  Please install Node.js manually: https://nodejs.org"
        exit 1
    fi
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Create UWP dev directory
UWP_DEV_DIR="$HOME/.universal-workspace/modules/dev_module"
mkdir -p "$UWP_DEV_DIR"

# Install npm packages
echo "📦 Installing npm packages..."
cd "$UWP_DEV_DIR"
npm install --silent

# Create global symlink if possible
if [ -w "/usr/local/bin" ]; then
    echo "🔗 Creating global symlink..."
    sudo ln -sf "$UWP_DEV_DIR/dev_main.js" /usr/local/bin/uwp-dev 2>/dev/null || true
fi

echo "✨ UWP Development Environment setup complete!"
echo ""
echo "Usage:"
echo "  uwp-dev status          # Show dev module status"
echo "  uwp-dev list            # List projects"
echo "  uwp-dev new <name>      # Create new project"
echo "  uwp-dev new <name> -t node    # Create Node.js project"
echo ""
