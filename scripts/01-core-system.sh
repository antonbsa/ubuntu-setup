#!/bin/bash

# =============================================================================
# Core System Setup - Section A
# Updates system and installs essential base packages
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="${1:-$HOME/ubuntu-setup/config.yaml}"

setup_core_system() {
    log_section "CORE SYSTEM SETUP"
    
    # Check if this step is enabled in config
    if ! check_config_enabled ".installation.common_packages" "$CONFIG_FILE"; then
        log_warning "Common packages installation is disabled in config. Skipping."
        return 0
    fi
    
    log_info "Starting core system setup..."
    
    # Update package lists
    log_info "Updating package lists..."
    sudo apt update
    handle_error "Failed to update package lists"
    
    # Upgrade existing packages
    log_info "Upgrading existing packages..."
    sudo apt upgrade -y
    handle_error "Failed to upgrade packages"
    
    # Install essential base packages
    log_info "Installing essential base packages..."
    sudo apt install -y \
        build-essential \
        curl \
        wget \
        unzip \
        zip \
        ca-certificates \
        software-properties-common \
        apt-transport-https \
        pkg-config \
        libssl-dev \
        tree
    
    if handle_error "Failed to install essential packages"; then
        log_success "Essential packages installed successfully"
    fi
    
    # Clean up
    log_info "Cleaning up unnecessary packages..."
    sudo apt autoremove -y
    sudo apt autoclean -y
    handle_error "Failed to clean up packages"
    
    log_success "Core system setup completed successfully"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_core_system "$@"
fi
