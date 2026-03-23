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

set -Euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

source "$SCRIPTS_DIR/utils.sh"
trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR

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
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="arm" ;;
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

preflight_checks() {
    log_section "PRE-FLIGHT CHECKS"

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

    if ! sudo -v; then
        log_error "This script requires sudo access. Please run with a user that has sudo privileges."
        exit 1
    fi

    log_success "Sudo access confirmed"
    ensure_yq

    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    log_success "Pre-flight checks completed"
}

display_config_summary() {
    log_section "CONFIGURATION SUMMARY"

    echo -e "${BLUE}The following components will be installed/configured:${NC}"
    echo ""

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

run_setup_section() {
    local section_label="$1"
    local script_path="$2"
    local function_name="$3"

    log_info "Running $section_label"
    source "$script_path"

    if ! "$function_name" "$CONFIG_FILE"; then
        log_warning "$section_label completed with failures. Continuing to the next section."
    fi
}

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

    local start_time end_time duration minutes seconds
    start_time=$(date +%s)

    run_setup_section "Section A: Core System Setup" "$SCRIPTS_DIR/01-core-system.sh" setup_core_system
    run_setup_section "Section B: Development Tools" "$SCRIPTS_DIR/02-dev-tools.sh" setup_dev_tools
    run_setup_section "Section C: Productivity Tools" "$SCRIPTS_DIR/03-productivity-tools.sh" setup_productivity_tools
    run_setup_section "Section D: System Configuration" "$SCRIPTS_DIR/04-system-config.sh" setup_system_configuration
    run_setup_section "Section E: BBB Job Setup (optional)" "$SCRIPTS_DIR/05-bbb-setup.sh" setup_bbb_job

    end_time=$(date +%s)
    duration=$((end_time - start_time))
    minutes=$((duration / 60))
    seconds=$((duration % 60))

    log_section "SETUP COMPLETED"
    if [[ $(get_failure_count) -gt 0 ]]; then
        log_warning "Total installation time: ${minutes}m ${seconds}s"
        log_warning "Setup finished with $(get_failure_count) recorded failure(s)"
        return 1
    fi

    log_success "Total installation time: ${minutes}m ${seconds}s"
    return 0
}

final_summary() {
    log_section "SETUP SUMMARY"

    if is_dry_run; then
        log_info "Dry-run completed successfully. No changes were applied."
        return 0
    fi

    print_failure_summary
    print_interaction_summary

    echo ""
    log_info "Next Steps:"
    echo -e "  ${BLUE}1.${NC} Log out and log back in for group changes (Docker, ZSH) to take effect"
    echo -e "  ${BLUE}2.${NC} Review the log file for warnings/errors: $LOG_FILE"
    echo -e "  ${BLUE}3.${NC} Sign in to applications listed above"
    echo -e "  ${BLUE}4.${NC} Bluetooth headphones will auto-switch to A2DP (high-quality) if installed"
    echo ""

    if [[ $(get_failure_count) -gt 0 ]]; then
        log_warning "Ubuntu developer setup completed with failures. Review the summary above."
    else
        log_success "Ubuntu developer setup completed successfully!"
    fi
}

main() {
    parse_args "$@"

    if is_dry_run; then
        LOG_FILE="/dev/null"
    fi

    init_log

    echo ""
    echo "========================================="
    echo "  Ubuntu Developer Setup Script"
    echo "========================================="
    echo ""

    preflight_checks
    display_config_summary

    if ! is_dry_run; then
        if ! ask_confirmation "Do you want to proceed with the installation?" "y"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi

    main_installation || true
    final_summary

    echo ""
    echo "========================================="
    echo "  Setup Complete!"
    echo "========================================="
    echo ""
}

main "$@"
