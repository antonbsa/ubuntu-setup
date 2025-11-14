#!/bin/bash

# =============================================================================
# Ubuntu Developer Setup - Main Installation Script
# =============================================================================
# This script orchestrates the complete setup of a fresh Ubuntu system for
# development work. It installs and configures all necessary tools, applications,
# and settings based on the configuration file.
#
# Usage:
#   1. Copy config.template.yaml to config.yaml and customize it
#   2. Make this script executable: chmod +x main.sh
#   3. Run: ./main.sh
#
# All operations are logged to ~/ubuntu-setup.log
# =============================================================================

set -e  # Exit on error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Source utilities
source "$SCRIPTS_DIR/utils.sh"

# Configuration file
CONFIG_FILE="$SCRIPT_DIR/config.yaml"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.template.yaml"

# =============================================================================
# Pre-flight Checks
# =============================================================================

preflight_checks() {
    log_section "PRE-FLIGHT CHECKS"
    
    # Check if running on Ubuntu
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS. This script is designed for Ubuntu."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is designed for Ubuntu. Detected: $ID"
        exit 1
    fi
    
    log_success "Running on Ubuntu $VERSION"
    
    # Check for config file
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warning "Config file not found at $CONFIG_FILE"
        
        if [[ -f "$CONFIG_TEMPLATE" ]]; then
            log_info "Copying template config file..."
            cp "$CONFIG_TEMPLATE" "$CONFIG_FILE"
            log_info "Please edit $CONFIG_FILE and run this script again."
            
            if ask_confirmation "Do you want to proceed with default configuration?"; then
                log_info "Proceeding with default configuration"
            else
                log_info "Please edit $CONFIG_FILE and run this script again."
                exit 0
            fi
        else
            log_error "Template config file not found at $CONFIG_TEMPLATE"
            exit 1
        fi
    fi
    
    log_success "Configuration file found: $CONFIG_FILE"
    
    # Check for sudo access
    if ! sudo -v; then
        log_error "This script requires sudo access. Please run with a user that has sudo privileges."
        exit 1
    fi
    
    log_success "Sudo access confirmed"
    
    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    
    log_success "Pre-flight checks completed"
}

# =============================================================================
# Display Configuration Summary
# =============================================================================

display_config_summary() {
    log_section "CONFIGURATION SUMMARY"
    
    echo -e "${BLUE}The following components will be installed/configured:${NC}"
    echo ""
    
    # Parse config and display enabled options
    if check_config_enabled ".installation.common_packages" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Core system packages and updates"
    fi
    
    if check_config_enabled ".installation.nodejs" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Node.js (via NVM) and NPM packages"
    fi
    
    if check_config_enabled ".installation.docker" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Docker"
    fi
    
    if check_config_enabled ".installation.editors.vscode" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Visual Studio Code"
    fi
    
    if check_config_enabled ".installation.browsers.google_chrome" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Google Chrome"
    fi
    
    if check_config_enabled ".installation.terminals.terminator" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Terminator"
    fi
    
    if check_config_enabled ".installation.slack" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Slack"
    fi
    
    if check_config_enabled ".installation.discord" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Discord"
    fi
    
    if check_config_enabled ".installation.obsidian" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Obsidian"
    fi
    
    if check_config_enabled ".installation.vlc" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} VLC Media Player"
    fi
    
    if check_config_enabled ".gnome.configure" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} GNOME settings"
    fi
    
    if check_config_enabled ".git.setup" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Git configuration"
    fi
    
    echo ""
    log_info "Configuration file: $CONFIG_FILE"
    log_info "Log file: $LOG_FILE"
    echo ""
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main_installation() {
    log_section "STARTING UBUNTU SETUP"
    
    local start_time
    start_time=$(date +%s)
    
    # Section A: Core System Setup
    log_info "Running Section A: Core System Setup"
    bash "$SCRIPTS_DIR/01-core-system.sh" "$CONFIG_FILE"
    
    # Section B: Development Tools
    log_info "Running Section B: Development Tools"
    bash "$SCRIPTS_DIR/02-dev-tools.sh" "$CONFIG_FILE"
    
    # Section C: Productivity Tools
    log_info "Running Section C: Productivity Tools"
    bash "$SCRIPTS_DIR/03-productivity-tools.sh" "$CONFIG_FILE"
    
    # Section D: System Configuration
    log_info "Running Section D: System Configuration"
    bash "$SCRIPTS_DIR/04-system-config.sh" "$CONFIG_FILE"
    
    # Section E: BBB Job Setup (optional)
    log_info "Running Section E: BBB Job Setup (optional)"
    bash "$SCRIPTS_DIR/05-bbb-setup.sh" "$CONFIG_FILE"
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    log_section "SETUP COMPLETED"
    log_success "Total installation time: ${minutes}m ${seconds}s"
}

# =============================================================================
# Final Summary
# =============================================================================

final_summary() {
    log_section "SETUP SUMMARY"
    
    # Display apps requiring user interaction
    print_interaction_summary
    
    # Additional notes
    echo ""
    log_info "Next Steps:"
    echo -e "  ${BLUE}1.${NC} Log out and log back in for group changes (Docker, ZSH) to take effect"
    echo -e "  ${BLUE}2.${NC} Review the log file for any warnings or errors: $LOG_FILE"
    echo -e "  ${BLUE}3.${NC} Sign in to applications listed above"
    echo -e "  ${BLUE}4.${NC} Bluetooth headphones will auto-switch to A2DP (high-quality) if installed"
    echo ""
    
    log_success "Ubuntu developer setup completed successfully!"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Initialize logging
    init_log
    
    # Welcome message
    echo ""
    echo "========================================="
    echo "  Ubuntu Developer Setup Script"
    echo "========================================="
    echo ""
    
    # Run pre-flight checks
    preflight_checks
    
    # Display configuration summary
    display_config_summary
    
    # Ask for final confirmation
    if ! ask_confirmation "Do you want to proceed with the installation?" "y"; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Run main installation
    main_installation
    
    # Display final summary
    final_summary
    
    echo ""
    echo "========================================="
    echo "  Setup Complete!"
    echo "========================================="
    echo ""
}

# Execute main function
main "$@"
