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

# Component flags
INSTALL_SWARM=true
INSTALL_AGENTS=true
INSTALL_COMMANDS=true
INSTALL_MCP_MGREP=true
INSTALL_MCP_PLAYWRITER=true

# Functions
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
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    while true; do
        echo -ne "${YELLOW}?${RESET} $prompt"
        read -r response
        response=${response:-$default}
        
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${CROSS} Please answer yes or no.";;
        esac
    done
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local all_good=true
    
    # Check opencode
    if command -v opencode &> /dev/null; then
        print_success "opencode found ($(opencode --version))"
    else
        print_error "opencode not found"
        echo -e "  ${ARROW} Install from: ${BLUE}https://opencode.ai/docs${RESET}"
        all_good=false
    fi
    
    # Check bun
    if command -v bun &> /dev/null; then
        print_success "bun found ($(bun --version))"
    else
        print_error "bun not found"
        echo -e "  ${ARROW} Install from: ${BLUE}https://bun.sh${RESET}"
        all_good=false
    fi
    
    # Check git
    if command -v git &> /dev/null; then
        print_success "git found"
    else
        print_error "git not found"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        echo ""
        print_error "Missing prerequisites. Please install them and try again."
        exit 1
    fi
}

configure_components() {
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

print_post_install() {
    print_section "Installation Complete!"
    
    echo ""
    echo -e "${GREEN}${BOLD}${STAR} Your OpenCode config is ready!${RESET}"
    echo ""
    
    if [ -n "$BACKUP_DIR" ]; then
        print_warning "Previous config backed up to: $BACKUP_DIR"
        echo ""
    fi
    
    echo -e "${BOLD}Next steps:${RESET}"
    echo ""
    echo -e "${ARROW} Authenticate with providers:"
    echo ""
    echo -e "  ${CYAN}# Claude (required)${RESET}"
    echo -e "  opencode auth login"
    echo -e "  ${YELLOW}→${RESET} Select: Anthropic → Claude Pro/Max"
    echo ""
    echo -e "  ${CYAN}# ChatGPT (for oracle agent)${RESET}"
    echo -e "  opencode auth login"
    echo -e "  ${YELLOW}→${RESET} Select: OpenAI → ChatGPT Plus/Pro"
    echo ""
    echo -e "  ${CYAN}# Google Gemini (for frontend/multimodal)${RESET}"
    echo -e "  opencode auth login"
    echo -e "  ${YELLOW}→${RESET} Select: Google → OAuth with Google (Antigravity)"
    echo ""
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

# Main installation flow
main() {
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
    
    print_post_install
}

# Run main
main
