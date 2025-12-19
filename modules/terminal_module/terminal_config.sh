#!/usr/bin/env bash

# UWP Terminal Module Configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# UWP Info
UWP_HOME="$HOME/.universal-workspace"
UWP_CONFIGS="$UWP_HOME/configs"

# Load terminal config
load_config() {
    local config_file="$UWP_CONFIGS/terminal_config.json"
    
    if [ -f "$config_file" ]; then
        cat "$config_file"
    else
        echo '{"theme":"default","plugins":[],"aliases":{}}'
    fi
}

# Save terminal config
save_config() {
    local config_file="$UWP_CONFIGS/terminal_config.json"
    mkdir -p "$(dirname "$config_file")"
    echo "$1" > "$config_file"
}

# Apply theme
apply_theme() {
    local theme="$1"
    
    case $theme in
        "dark")
            # Dark theme
            export PS1="\[${PURPLE}\][\u@\h \[${CYAN}\]\W\[${PURPLE}\]]\[${NC}\] \$ "
            ;;
        "light")
            # Light theme
            export PS1="\[${BLUE}\][\u@\h \[${GREEN}\]\W\[${BLUE}\]]\[${NC}\] \$ "
            ;;
        "minimal")
            # Minimal theme
            export PS1="\[${YELLOW}\]\W\[${NC}\] \$ "
            ;;
        "uwp")
            # UWP theme
            export PS1="\[${RED}\]UWP\[${NC}\] \[${CYAN}\][\W]\[${NC}\] \$ "
            ;;
        *)
            # Default theme
            export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ "
            ;;
    esac
}

# Setup aliases
setup_aliases() {
    local aliases="$1"
    
    # Clear existing UWP aliases
    unalias uwp-status 2>/dev/null || true
    unalias uwp-update 2>/dev/null || true
    
    # Parse and set aliases from JSON
    echo "$aliases" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for alias, command in data.get('aliases', {}).items():
    print(f'alias {alias}=\"{command}\"')
" | while read alias_line; do
        eval "$alias_line"
    done
    
    # Default UWP aliases
    alias uwp-status='uwp --status'
    alias uwp-update='uwp --update'
    alias uwp-ai='uwp --ai'
    alias uwp-dev='uwp --dev'
    alias uwp-docker='uwp --docker'
    
    # System aliases
    alias ll='ls -la'
    alias la='ls -A'
    alias l='ls -CF'
    
    # Git aliases
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline --graph'
}

# Setup plugins
setup_plugins() {
    local plugins="$1"
    
    echo "$plugins" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for plugin in data.get('plugins', []):
    print(f'Loading plugin: {plugin}')
" | while read line; do
        echo -e "${BLUE}[TERMINAL]${NC} $line"
    done
}

# Interactive configuration
interactive_config() {
    echo -e "${CYAN}🖥️  UWP Terminal Configuration${NC}"
    echo "=============================="
    echo ""
    
    # Current config
    local current_config=$(load_config)
    
    # Theme selection
    echo -e "${YELLOW}Select theme:${NC}"
    echo "1) Dark"
    echo "2) Light"
    echo "3) Minimal"
    echo "4) UWP"
    echo "5) Default"
    echo -n "Choice [1-5]: "
    read theme_choice
    
    case $theme_choice in
        1) theme="dark" ;;
        2) theme="light" ;;
        3) theme="minimal" ;;
        4) theme="uwp" ;;
        *) theme="default" ;;
    esac
    
    # Plugin selection
    echo ""
    echo -e "${YELLOW}Enable plugins?${NC}"
    echo -n "Enable git prompt? [y/N]: "
    read git_prompt
    
    plugins=[]
    if [[ $git_prompt =~ ^[Yy]$ ]]; then
        plugins+=("git-prompt")
    fi
    
    # Create new config
    local new_config=$(cat << EOF
{
    "theme": "$theme",
    "plugins": [${plugins[@]}],
    "aliases": {
        "..": "cd ..",
        "...": "cd ../..",
        "uwp-cd": "cd ~/.universal-workspace",
        "uwp-logs": "tail -f ~/.universal-workspace/logs/*.log"
    }
}
EOF
)
    
    # Save config
    save_config "$new_config"
    
    echo -e "${GREEN}✅ Configuration saved!${NC}"
    echo ""
    echo -e "${BLUE}Note:${NC} Some changes require terminal restart"
}

# Main function
main() {
    # Parse arguments
    case "$1" in
        --config|-c)
            interactive_config
            ;;
            
        --theme|-t)
            if [ -n "$2" ]; then
                apply_theme "$2"
                echo -e "${GREEN}Theme applied: $2${NC}"
            else
                echo "Usage: $0 --theme <theme-name>"
            fi
            ;;
            
        --status|-s)
            echo -e "${CYAN}UWP Terminal Configuration:${NC}"
            echo "================================"
            load_config | python3 -m json.tool
            ;;
            
        --apply|-a)
            echo -e "${BLUE}Applying terminal configuration...${NC}"
            local config=$(load_config)
            local theme=$(echo "$config" | python3 -c "import json,sys; print(json.load(sys.stdin)['theme'])")
            apply_theme "$theme"
            setup_aliases "$config"
            setup_plugins "$config"
            echo -e "${GREEN}✅ Configuration applied!${NC}"
            ;;
            
        --help|-h)
            echo "UWP Terminal Module"
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --config, -c    Interactive configuration"
            echo "  --theme, -t     Set theme (dark/light/minimal/uwp/default)"
            echo "  --status, -s    Show current configuration"
            echo "  --apply, -a     Apply current configuration"
            echo "  --help, -h      Show this help"
            ;;
            
        *)
            # Default: apply configuration
            local config=$(load_config)
            local theme=$(echo "$config" | python3 -c "import json,sys; print(json.load(sys.stdin).get('theme', 'default'))")
            apply_theme "$theme"
            setup_aliases "$config"
            ;;
    esac
}

# Run main function
main "$@"

# Always set some basic aliases (even if not in config)
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# UWP welcome message
echo -e "${CYAN}Welcome to UWP Terminal!${NC}"
echo -e "Type 'uwp --help' for UWP commands"
