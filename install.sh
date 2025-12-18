#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Icons
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
ARROW="${BLUE}→${RESET}"
STAR="${YELLOW}★${RESET}"

# Config
REPO_URL="git@github.com:AnishDe12020/opencode-config.git"
INSTALL_DIR="$HOME/.config/opencode"
BACKUP_DIR=""
NON_INTERACTIVE=false
SETUP_AUTH=false

# Platform detection
OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      PLATFORM="unknown" ;;
 esac

# Component flags
INSTALL_SWARM=true
INSTALL_AGENTS=true
INSTALL_COMMANDS=true
INSTALL_MCP_MGREP=true
INSTALL_MCP_PLAYWRITER=true
ENABLE_NOTIFICATIONS=true

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|--non-interactive|-y)
                NON_INTERACTIVE=true
                shift
                ;;
            --setup-auth)
                SETUP_AUTH=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --yes, -y               Non-interactive mode (installs all components)"
                echo "  --setup-auth            Guide through authentication setup after install"
                echo "  --help, -h              Show this help message"
                echo ""
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
    done
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║   OpenCode Config Installer v1.0     ║"
    echo "  ║   by @AnishDe12020                    ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_section() {
    echo ""
    echo -e "${CYAN}${BOLD}▸ $1${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

print_step() {
    echo -e "${ARROW} $1"
}

print_success() {
    echo -e "${CHECK} $1"
}

print_error() {
    echo -e "${CROSS} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${RESET}  $1"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local response
    
    if [ "$NON_INTERACTIVE" = true ]; then
        case "$default" in
            [Yy]*) return 0 ;;
            *) return 1 ;;
        esac
    fi
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    if [ ! -t 0 ] && [ ! -r /dev/tty ]; then
        echo ""
        print_error "No interactive terminal available and --yes flag not provided"
        echo -e "  ${ARROW} When piping the installer, use: ${CYAN}curl ... | bash -s -- --yes${RESET}"
        echo -e "  ${ARROW} Or run directly: ${CYAN}bash install.sh${RESET}"
        exit 1
    fi
    
    local input_source="/dev/stdin"
    if [ ! -t 0 ]; then
        input_source="/dev/tty"
    fi
    
    while true; do
        echo -ne "${YELLOW}?${RESET} $prompt"
        read -r response <"$input_source"
        response=${response:-$default}
        
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${CROSS} Please answer yes or no.";;
        esac
    done
}

detect_package_manager() {
    if [ "$PLATFORM" = "macos" ]; then
        if command -v brew &> /dev/null; then
            echo "brew"
        fi
    elif [ "$PLATFORM" = "linux" ]; then
        if command -v apt &> /dev/null; then
            echo "apt"
        elif command -v dnf &> /dev/null; then
            echo "dnf"
        elif command -v yum &> /dev/null; then
            echo "yum"
        elif command -v pacman &> /dev/null; then
            echo "pacman"
        fi
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    print_step "Detected platform: ${BOLD}$PLATFORM${RESET}"
    local pkg_mgr=$(detect_package_manager)
    if [ -n "$pkg_mgr" ]; then
        print_step "Package manager: ${BOLD}$pkg_mgr${RESET}"
    fi
    echo ""
    
    local all_good=true
    
    if command -v opencode &> /dev/null; then
        print_success "opencode found ($(opencode --version))"
    else
        print_error "opencode not found"
        echo -e "  ${ARROW} Install from: ${BLUE}https://opencode.ai/docs${RESET}"
        all_good=false
    fi
    
    if command -v bun &> /dev/null; then
        print_success "bun found ($(bun --version))"
    else
        print_error "bun not found"
        echo -e "  ${ARROW} Install from: ${BLUE}https://bun.sh${RESET}"
        if [ "$PLATFORM" = "macos" ] && [ -n "$pkg_mgr" ]; then
            echo -e "  ${ARROW} Quick install: ${CYAN}brew install oven-sh/bun/bun${RESET}"
        elif [ "$PLATFORM" = "linux" ]; then
            echo -e "  ${ARROW} Quick install: ${CYAN}curl -fsSL https://bun.sh/install | bash${RESET}"
        fi
        all_good=false
    fi
    
    if command -v git &> /dev/null; then
        print_success "git found"
    else
        print_error "git not found"
        if [ "$PLATFORM" = "macos" ] && [ "$pkg_mgr" = "brew" ]; then
            echo -e "  ${ARROW} Install: ${CYAN}brew install git${RESET}"
        elif [ "$PLATFORM" = "linux" ]; then
            if [ "$pkg_mgr" = "apt" ]; then
                echo -e "  ${ARROW} Install: ${CYAN}sudo apt install git${RESET}"
            elif [ "$pkg_mgr" = "dnf" ]; then
                echo -e "  ${ARROW} Install: ${CYAN}sudo dnf install git${RESET}"
            elif [ "$pkg_mgr" = "pacman" ]; then
                echo -e "  ${ARROW} Install: ${CYAN}sudo pacman -S git${RESET}"
            fi
        fi
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        echo ""
        print_error "Missing prerequisites. Please install them and try again."
        exit 1
    fi
}

configure_components() {
    if [ "$NON_INTERACTIVE" = true ]; then
        print_section "Component Configuration"
        echo -e "${BOLD}Installing all components (non-interactive mode)${RESET}"
        print_success "All components enabled"
        return
    fi
    
    print_section "Component Configuration"
    
    echo -e "${BOLD}Select components to install:${RESET}"
    echo ""
    
    if prompt_yes_no "Install Swarm Orchestrator (parallel task execution with git worktrees)" "y"; then
        INSTALL_SWARM=true
        print_success "Swarm orchestrator enabled"
    else
        INSTALL_SWARM=false
        print_warning "Swarm orchestrator disabled"
    fi
    
    if prompt_yes_no "Install Custom Agents (orchestrator, worker, reviewer)" "y"; then
        INSTALL_AGENTS=true
        print_success "Custom agents enabled"
    else
        INSTALL_AGENTS=false
        print_warning "Custom agents disabled"
    fi
    
    if prompt_yes_no "Install Slash Commands (/swarm, /graphite, /review, etc)" "y"; then
        INSTALL_COMMANDS=true
        print_success "Slash commands enabled"
    else
        INSTALL_COMMANDS=false
        print_warning "Slash commands disabled"
    fi
    
    echo ""
    echo -e "${BOLD}MCP Servers:${RESET}"
    echo ""
    
    if prompt_yes_no "Install mgrep MCP (semantic code search)" "y"; then
        INSTALL_MCP_MGREP=true
        print_success "mgrep MCP enabled"
    else
        INSTALL_MCP_MGREP=false
        print_warning "mgrep MCP disabled"
    fi
    
    if prompt_yes_no "Install playwriter MCP (browser automation)" "y"; then
        INSTALL_MCP_PLAYWRITER=true
        print_success "playwriter MCP enabled"
    else
        INSTALL_MCP_PLAYWRITER=false
        print_warning "playwriter MCP disabled"
    fi
    
    echo ""
    echo -e "${BOLD}Platform Features:${RESET}"
    echo ""
    
    if prompt_yes_no "Enable desktop notifications (task completion alerts)" "y"; then
        ENABLE_NOTIFICATIONS=true
        print_success "Notifications enabled"
    else
        ENABLE_NOTIFICATIONS=false
        print_warning "Notifications disabled"
    fi
}

backup_existing() {
    if [ -d "$INSTALL_DIR" ]; then
        BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%s)"
        print_section "Backing Up Existing Config"
        print_step "Moving $INSTALL_DIR to $BACKUP_DIR"
        mv "$INSTALL_DIR" "$BACKUP_DIR"
        print_success "Backup created at: $BACKUP_DIR"
    fi
}

clone_repo() {
    print_section "Cloning Repository"
    print_step "Cloning from $REPO_URL"
    
    if git clone "$REPO_URL" "$INSTALL_DIR" 2>&1 | grep -q "Permission denied\|Host key verification failed"; then
        print_error "SSH authentication failed"
        echo ""
        print_warning "Falling back to HTTPS..."
        REPO_URL="https://github.com/AnishDe12020/opencode-config.git"
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
    
    print_success "Repository cloned"
}

remove_unwanted_components() {
    print_section "Configuring Components"
    
    cd "$INSTALL_DIR"
    
    if [ "$INSTALL_SWARM" = false ]; then
        print_step "Removing swarm components..."
        rm -rf tool/swarm-*.ts command/swarm*.md agent/ plugin/swarm.ts
        print_success "Swarm removed"
    fi
    
    if [ "$INSTALL_AGENTS" = false ]; then
        print_step "Removing custom agents..."
        rm -rf agent/
        print_success "Custom agents removed"
    fi
    
    if [ "$INSTALL_COMMANDS" = false ]; then
        print_step "Removing slash commands..."
        rm -rf command/
        print_success "Slash commands removed"
    fi
    
    if [ "$INSTALL_MCP_MGREP" = false ] || [ "$INSTALL_MCP_PLAYWRITER" = false ]; then
        print_step "Updating MCP configuration..."
        
        if [ "$INSTALL_MCP_MGREP" = false ]; then
            if command -v jq &> /dev/null; then
                jq 'del(.mcp.mgrep)' opencode.json > opencode.json.tmp && mv opencode.json.tmp opencode.json
                rm -f tool/mgrep.ts
            fi
            print_success "mgrep MCP removed"
        fi
        
        if [ "$INSTALL_MCP_PLAYWRITER" = false ]; then
            if command -v jq &> /dev/null; then
                jq 'del(.mcp.playwriter)' opencode.json > opencode.json.tmp && mv opencode.json.tmp opencode.json
            fi
            print_success "playwriter MCP removed"
        fi
    fi
}

install_dependencies() {
    print_section "Installing Dependencies"
    print_step "Running bun install..."
    
    cd "$INSTALL_DIR"
    bun install > /dev/null 2>&1
    
    print_success "Dependencies installed"
}

setup_notifications() {
    if [ "$ENABLE_NOTIFICATIONS" = false ]; then
        return
    fi
    
    print_section "Setting Up Notifications"
    
    local notifier_installed=false
    
    if [ "$PLATFORM" = "macos" ]; then
        if command -v terminal-notifier &> /dev/null; then
            print_success "terminal-notifier already installed"
            notifier_installed=true
        elif command -v osascript &> /dev/null; then
            print_success "osascript available (built-in)"
            notifier_installed=true
        else
            print_warning "No notification tool found"
            if command -v brew &> /dev/null; then
                if prompt_yes_no "Install terminal-notifier via brew?" "y"; then
                    print_step "Installing terminal-notifier..."
                    brew install terminal-notifier > /dev/null 2>&1
                    print_success "terminal-notifier installed"
                    notifier_installed=true
                fi
            fi
        fi
    elif [ "$PLATFORM" = "linux" ]; then
        if command -v notify-send &> /dev/null; then
            print_success "notify-send already installed"
            notifier_installed=true
        else
            print_warning "notify-send not found"
            local pkg_mgr=$(detect_package_manager)
            
            if [ -n "$pkg_mgr" ]; then
                local install_cmd=""
                case "$pkg_mgr" in
                    apt) install_cmd="sudo apt install libnotify-bin" ;;
                    dnf) install_cmd="sudo dnf install libnotify" ;;
                    yum) install_cmd="sudo yum install libnotify" ;;
                    pacman) install_cmd="sudo pacman -S libnotify" ;;
                esac
                
                if [ -n "$install_cmd" ]; then
                    echo -e "  ${ARROW} Install with: ${CYAN}$install_cmd${RESET}"
                    if prompt_yes_no "Install notify-send now?" "y"; then
                        print_step "Installing libnotify..."
                        eval "$install_cmd" > /dev/null 2>&1
                        print_success "libnotify installed"
                        notifier_installed=true
                    fi
                fi
            fi
        fi
    fi
    
    if [ "$notifier_installed" = true ]; then
        print_step "Enabling session-notification hook..."
        cd "$INSTALL_DIR"
        
        if [ -f "oh-my-opencode.json" ]; then
            if command -v jq &> /dev/null; then
                local disabled_hooks=$(jq -r '.disabled_hooks // [] | join(",")' oh-my-opencode.json)
                if [[ "$disabled_hooks" == *"session-notification"* ]]; then
                    jq '.disabled_hooks = (.disabled_hooks // [] | map(select(. != "session-notification")))' oh-my-opencode.json > oh-my-opencode.json.tmp
                    mv oh-my-opencode.json.tmp oh-my-opencode.json
                    print_success "Notifications enabled in config"
                else
                    print_success "Notifications already enabled"
                fi
            fi
        fi
    else
        print_warning "Notifications setup skipped - install tools manually if needed"
    fi
}

configure_platform_optimizations() {
    print_section "Platform Optimizations"
    
    if [ "$PLATFORM" = "macos" ]; then
        if [ "$INSTALL_SWARM" = true ]; then
            print_step "Checking Spotlight indexing..."
            
            local swarm_dir="$INSTALL_DIR/.swarm"
            if [ -d "$swarm_dir" ]; then
                if [ ! -f "$swarm_dir/.metadata_never_index" ]; then
                    print_step "Excluding .swarm/ from Spotlight indexing..."
                    touch "$swarm_dir/.metadata_never_index"
                    print_success "Spotlight exclusion added"
                else
                    print_success "Spotlight already excluded"
                fi
            fi
        fi
        
        print_success "macOS optimizations applied"
        
    elif [ "$PLATFORM" = "linux" ]; then
        if [ "$INSTALL_SWARM" = true ]; then
            print_step "Checking inotify limits..."
            
            local current_watches=$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo "unknown")
            local current_instances=$(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo "unknown")
            
            if [ "$current_watches" != "unknown" ] && [ "$current_watches" -lt 524288 ]; then
                print_warning "inotify watches limit is low ($current_watches)"
                echo -e "  ${ARROW} Recommended for large projects: 524288"
                echo -e "  ${ARROW} Add to ${CYAN}/etc/sysctl.conf${RESET}:"
                echo -e "      ${CYAN}fs.inotify.max_user_watches=524288${RESET}"
                echo -e "      ${CYAN}fs.inotify.max_user_instances=512${RESET}"
                echo -e "  ${ARROW} Apply with: ${CYAN}sudo sysctl -p${RESET}"
            else
                print_success "inotify limits OK"
            fi
        fi
        
        print_success "Linux optimizations checked"
    fi
}

setup_authentication() {
    print_section "Authentication Setup"
    
    echo ""
    echo -e "${BOLD}Choose authentication method:${RESET}"
    echo ""
    echo -e "  ${CYAN}1. Interactive (requires browser)${RESET}"
    echo -e "     Open browser to authenticate with each provider"
    echo ""
    echo -e "  ${CYAN}2. Headless (manual token entry)${RESET}"
    echo -e "     Authenticate on another device, then copy tokens"
    echo ""
    
    local method
    while true; do
        echo -ne "${YELLOW}?${RESET} Select method [1/2]: "
        if [ ! -t 0 ] && [ -r /dev/tty ]; then
            read -r method </dev/tty
        else
            read -r method
        fi
        
        case "$method" in
            1)
                print_step "Starting interactive authentication..."
                echo ""
                echo -e "${CYAN}# Claude (required)${RESET}"
                opencode auth login || true
                echo ""
                echo -e "${CYAN}# ChatGPT (for oracle agent)${RESET}"
                opencode auth login || true
                echo ""
                echo -e "${CYAN}# Google Gemini (for frontend/multimodal)${RESET}"
                opencode auth login || true
                echo ""
                print_success "Authentication complete"
                break
                ;;
            2)
                print_step "Headless authentication instructions:"
                echo ""
                echo -e "${YELLOW}On a machine with a browser:${RESET}"
                echo -e "  1. Run: ${CYAN}opencode auth login${RESET}"
                echo -e "  2. Authenticate with each provider"
                echo -e "  3. Locate auth files in: ${CYAN}~/.config/opencode/${RESET}"
                echo ""
                echo -e "${YELLOW}Copy these files to this machine:${RESET}"
                echo -e "  ${CYAN}- anthropic.auth.json${RESET}     (Claude)"
                echo -e "  ${CYAN}- openai.auth.json${RESET}        (ChatGPT)"
                echo -e "  ${CYAN}- antigravity-accounts.json${RESET} (Google/Gemini)"
                echo ""
                echo -e "${YELLOW}Transfer command example:${RESET}"
                echo -e "  ${CYAN}scp user@local-machine:~/.config/opencode/*.json ~/.config/opencode/${RESET}"
                echo ""
                print_warning "Press Enter when files are copied..."
                if [ ! -t 0 ] && [ -r /dev/tty ]; then
                    read -r </dev/tty
                else
                    read -r
                fi
                break
                ;;
            *)
                echo -e "${CROSS} Please select 1 or 2"
                ;;
        esac
    done
}

print_post_install() {
    print_section "Installation Complete!"
    
    echo ""
    echo -e "${GREEN}${BOLD}${STAR} Your OpenCode config is ready!${RESET}"
    echo ""
    
    if [ -n "$BACKUP_DIR" ]; then
        print_warning "Previous config backed up to: $BACKUP_DIR"
        echo ""
    fi
    
    echo -e "${BOLD}Installed components:${RESET}"
    echo ""
    [ "$INSTALL_SWARM" = true ] && echo -e "  ${CHECK} Swarm orchestrator"
    [ "$INSTALL_AGENTS" = true ] && echo -e "  ${CHECK} Custom agents"
    [ "$INSTALL_COMMANDS" = true ] && echo -e "  ${CHECK} Slash commands"
    [ "$INSTALL_MCP_MGREP" = true ] && echo -e "  ${CHECK} mgrep MCP"
    [ "$INSTALL_MCP_PLAYWRITER" = true ] && echo -e "  ${CHECK} playwriter MCP"
    [ "$ENABLE_NOTIFICATIONS" = true ] && echo -e "  ${CHECK} Desktop notifications"
    echo ""
    
    if [ "$SETUP_AUTH" = false ]; then
        echo -e "${BOLD}Next steps:${RESET}"
        echo ""
        echo -e "${ARROW} Authenticate with providers:"
        echo ""
        echo -e "  ${CYAN}# Interactive mode:${RESET}"
        echo -e "  opencode auth login"
        echo ""
        echo -e "  ${CYAN}# Or run installer with auth setup:${RESET}"
        echo -e "  curl -fsSL https://raw.githubusercontent.com/AnishDe12020/opencode-config/main/install.sh | bash -s -- --setup-auth"
        echo ""
        echo -e "  ${CYAN}# Headless/SSH? See README for manual token setup${RESET}"
        echo ""
    fi
    
    echo -e "${ARROW} Start OpenCode:"
    echo -e "  ${CYAN}opencode${RESET}"
    echo ""
    echo -e "${ARROW} Verify setup:"
    echo -e "  ${CYAN}opencode mcp list${RESET}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}Documentation:${RESET} ${BLUE}https://github.com/AnishDe12020/opencode-config${RESET}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

main() {
    parse_args "$@"
    
    print_header
    
    check_prerequisites
    
    echo ""
    if ! prompt_yes_no "Continue with installation?" "y"; then
        print_warning "Installation cancelled"
        exit 0
    fi
    
    configure_components
    
    backup_existing
    
    clone_repo
    
    remove_unwanted_components
    
    install_dependencies
    
    setup_notifications
    
    configure_platform_optimizations
    
    if [ "$SETUP_AUTH" = true ]; then
        setup_authentication
    fi
    
    print_post_install
}

main "$@"
