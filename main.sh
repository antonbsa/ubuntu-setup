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
DRY_RUN=0

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                ;;
            -h|--help)
                echo "Usage: ./main.sh [--dry-run]"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                echo "Usage: ./main.sh [--dry-run]"
                exit 1
                ;;
        esac
        shift
    done
}

ensure_yq() {
    if command -v yq &> /dev/null; then
        log_success "yq is already available"
        return 0
    fi

    log_info "Installing yq for configuration parsing..."

    local version="v4.44.6"
    local arch

    case "$(uname -m)" in
        x86_64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l)
            arch="arm"
            ;;
        *)
            log_error "Unsupported architecture for automatic yq installation: $(uname -m)"
            exit 1
            ;;
    esac

    local binary_url="https://github.com/mikefarah/yq/releases/download/${version}/yq_linux_${arch}"
    local install_path="/usr/local/bin/yq"

    if ! curl -fsSL "$binary_url" -o /tmp/yq; then
        log_error "Failed to download yq from $binary_url"
        exit 1
    fi

    sudo install -m 0755 /tmp/yq "$install_path"
    rm -f /tmp/yq

    if ! command -v yq &> /dev/null; then
        log_error "yq installation completed but the command is still unavailable"
        exit 1
    fi

    log_success "Installed yq to $install_path"
}

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

    if is_dry_run; then
        if ! command -v yq &> /dev/null; then
            log_error "Dry-run mode requires yq to already be installed."
            exit 1
        fi

        log_info "Dry-run mode enabled. Skipping sudo validation and system changes."
        log_success "Pre-flight checks completed"
        return 0
    fi

    # Check for sudo access
    if ! sudo -v; then
        log_error "This script requires sudo access. Please run with a user that has sudo privileges."
        exit 1
    fi

    log_success "Sudo access confirmed"
    ensure_yq

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

    if check_config_enabled ".installation.peek" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Peek"
    fi

    if check_config_enabled ".installation.insomnia" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Insomnia"
    fi

    if check_config_enabled ".installation.flameshot" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Flameshot"
    fi

    if check_config_enabled ".installation.terminal_tools.bat" "$CONFIG_FILE" ||        check_config_enabled ".installation.terminal_tools.htop" "$CONFIG_FILE" ||        check_config_enabled ".installation.terminal_tools.tmux" "$CONFIG_FILE" ||        check_config_enabled ".installation.terminal_tools.jq" "$CONFIG_FILE"; then
        echo -e "  ${GREEN}✓${NC} Terminal tools"
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

    if is_dry_run; then
        log_section "DRY RUN MODE"
        log_info "No changes will be made. The setup would perform the following sections:"
        log_info "Would run Section A: Core System Setup"
        log_info "Would run Section B: Development Tools"
        log_info "Would run Section C: Productivity Tools"
        log_info "Would run Section D: System Configuration"
        log_info "Would run Section E: BBB Job Setup (optional)"
        return 0
    fi

    local start_time
    start_time=$(date +%s)

    # Section A: Core System Setup
    log_info "Running Section A: Core System Setup"
    source "$SCRIPTS_DIR/01-core-system.sh"
    setup_core_system "$CONFIG_FILE"

    # Section B: Development Tools
    log_info "Running Section B: Development Tools"
    source "$SCRIPTS_DIR/02-dev-tools.sh"
    setup_dev_tools "$CONFIG_FILE"

    # Section C: Productivity Tools
    log_info "Running Section C: Productivity Tools"
    source "$SCRIPTS_DIR/03-productivity-tools.sh"
    setup_productivity_tools "$CONFIG_FILE"

    # Section D: System Configuration
    log_info "Running Section D: System Configuration"
    source "$SCRIPTS_DIR/04-system-config.sh"
    setup_system_configuration "$CONFIG_FILE"

    # Section E: BBB Job Setup (optional)
    log_info "Running Section E: BBB Job Setup (optional)"
    source "$SCRIPTS_DIR/05-bbb-setup.sh"
    setup_bbb_job "$CONFIG_FILE"

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

    if is_dry_run; then
        log_info "Dry-run completed successfully. No changes were applied."
        return 0
    fi

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
    parse_args "$@"

    if is_dry_run; then
        LOG_FILE="/dev/null"
    fi

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

    if ! is_dry_run; then
        # Ask for final confirmation
        if ! ask_confirmation "Do you want to proceed with the installation?" "y"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
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
