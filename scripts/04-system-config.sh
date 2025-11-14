#!/bin/bash

# =============================================================================
# System Configuration - Section D
# Configures: Bluetooth, firewall, locale, GNOME settings, ZSH aliases, gitconfig
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="${1:-$HOME/ubuntu-setup/config.yaml}"

# =============================================================================
# Fix Bluetooth Headphones (A2DP Auto-Switch)
# =============================================================================

fix_bluetooth_a2dp() {
    log_info "Setting up Bluetooth A2DP auto-switch service..."
    
    if ! check_config_enabled ".security.bluetooth_a2dp_fix" "$CONFIG_FILE"; then
        log_warning "Bluetooth A2DP fix is disabled in config. Skipping."
        return 0
    fi
    
    local setup_script="$SCRIPT_DIR/../config/setup-a2dp-fix.sh"
    
    if [[ ! -f "$setup_script" ]]; then
        log_warning "Bluetooth A2DP setup script not found at $setup_script"
        return 1
    fi
    
    if ask_confirmation "Install Bluetooth A2DP auto-switch service? (Forces high-quality audio)"; then
        log_info "Running A2DP setup script..."
        bash "$setup_script"
        
        if [[ $? -eq 0 ]]; then
            log_success "Bluetooth A2DP auto-switch service installed successfully"
            log_info "Your Bluetooth headphones will now automatically use A2DP (high-quality) profile"
        else
            log_error "Failed to install A2DP auto-switch service"
            return 1
        fi
    else
        log_info "Skipping Bluetooth A2DP setup"
    fi
}

# =============================================================================
# Enable Firewall
# =============================================================================

enable_firewall() {
    log_info "Enabling firewall (UFW)..."
    
    if ! check_config_enabled ".security.enable_firewall" "$CONFIG_FILE"; then
        log_warning "Firewall setup is disabled in config. Skipping."
        return 0
    fi
    
    if sudo ufw status | grep -q "Status: active"; then
        log_warning "Firewall is already enabled. Skipping."
        return 0
    fi
    
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    log_success "Firewall enabled successfully"
}

# =============================================================================
# Fix Locale/UTF-8
# =============================================================================

fix_locale() {
    log_info "Configuring system locale..."
    
    local desired_locale
    desired_locale=$(get_config_value ".system.localization.locale" "$CONFIG_FILE")
    desired_locale=${desired_locale:-en_US.UTF-8}
    
    # Generate locale if not present
    if ! locale -a | grep -q "^${desired_locale}$"; then
        log_info "Generating locale: $desired_locale"
        sudo locale-gen "$desired_locale"
    fi
    
    # Set as default
    sudo update-locale LANG="$desired_locale" LC_ALL="$desired_locale"
    
    log_success "Locale configured to $desired_locale"
}

# =============================================================================
# GNOME Settings
# =============================================================================

configure_gnome() {
    log_info "Configuring GNOME settings..."
    
    if ! check_config_enabled ".gnome.configure" "$CONFIG_FILE"; then
        log_warning "GNOME configuration is disabled in config. Skipping."
        return 0
    fi
    
    # Dark mode
    log_info "Enabling dark mode..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
    
    # Power mode
    local power_mode
    power_mode=$(get_config_value ".gnome.settings.power_mode" "$CONFIG_FILE")
    power_mode=${power_mode:-performance}
    
    log_info "Setting power mode to: $power_mode..."
    if command -v powerprofilesctl &> /dev/null; then
        powerprofilesctl set "$power_mode" 2>/dev/null || log_warning "Could not set power mode to $power_mode"
    else
        log_warning "powerprofilesctl not available. Install power-profiles-daemon to set power mode."
    fi
    
    # Icon size
    log_info "Setting dock icon size to 30..."
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 30
    
    # Automatic suspend: read from config
    local suspend_timeout
    suspend_timeout=$(get_config_value ".gnome.settings.suspend_timeout" "$CONFIG_FILE")
    suspend_timeout=${suspend_timeout:-6000}
    
    log_info "Setting automatic suspend to $((suspend_timeout / 60)) minutes..."
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout "$suspend_timeout"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout "$suspend_timeout"
    
    # Night light: 17:30 to 08:00, 33% warmth
    log_info "Configuring night light..."
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 17.5  # 17:30
    gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 8.0     # 08:00
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3700    # ~33% warmth
    
    log_success "GNOME settings configured successfully"
}

# =============================================================================
# ZSH Aliases
# =============================================================================

setup_zsh_aliases() {
    log_info "Setting up ZSH aliases..."
    
    local aliases_source="$SCRIPT_DIR/../config/zsh-aliases.sh"
    local zshrc="$HOME/.zshrc"
    
    if [[ ! -f "$aliases_source" ]]; then
        log_error "Aliases file not found at $aliases_source"
        return 1
    fi
    
    if [[ ! -f "$zshrc" ]]; then
        log_warning ".zshrc not found. Creating..."
        touch "$zshrc"
    fi
    
    # Check if aliases are already sourced
    if grep -q "source.*zsh-aliases.sh" "$zshrc"; then
        log_warning "ZSH aliases already configured in .zshrc. Skipping."
        return 0
    fi
    
    # Copy aliases file to home directory
    cp "$aliases_source" "$HOME/.zsh-aliases.sh"
    
    # Add source command to .zshrc
    cat >> "$zshrc" << 'EOF'

# Custom aliases
if [ -f ~/.zsh-aliases.sh ]; then
    source ~/.zsh-aliases.sh
fi
EOF
    
    log_success "ZSH aliases configured successfully"
}

# =============================================================================
# Git Configuration
# =============================================================================

setup_gitconfig() {
    log_info "Configuring Git..."
    
    if ! check_config_enabled ".git.setup" "$CONFIG_FILE"; then
        log_warning "Git configuration is disabled in config. Skipping."
        return 0
    fi
    
    local git_name
    local git_email
    local git_branch
    
    git_name=$(get_config_value ".user.name" "$CONFIG_FILE")
    git_email=$(get_config_value ".user.github_email" "$CONFIG_FILE")
    git_branch=$(get_config_value ".git.default_branch" "$CONFIG_FILE")
    
    git_name=${git_name:-Anton B}
    git_branch=${git_branch:-main}
    
    if [[ -n "$git_email" ]]; then
        log_info "Setting Git user email: $git_email"
        git config --global user.email "$git_email"
    else
        log_warning "Git email not found in config. Skipping email configuration."
    fi
    
    if [[ -n "$git_name" ]]; then
        log_info "Setting Git user name: $git_name"
        git config --global user.name "$git_name"
    fi
    
    log_info "Setting default branch to: $git_branch"
    git config --global init.defaultBranch "$git_branch"
    
    # Additional useful Git configurations
    git config --global pull.rebase false
    git config --global core.editor "code --wait"
    
    log_success "Git configured successfully"
}

# =============================================================================
# Timezone Configuration
# =============================================================================

configure_timezone() {
    log_info "Configuring timezone..."
    
    local timezone
    timezone=$(get_config_value ".system.localization.timezone" "$CONFIG_FILE")
    
    if [[ -n "$timezone" ]]; then
        log_info "Setting timezone to: $timezone"
        sudo timedatectl set-timezone "$timezone"
        log_success "Timezone set to $timezone"
    else
        log_info "No timezone specified in config. Keeping current timezone."
    fi
}

# =============================================================================
# Main Function
# =============================================================================

setup_system_configuration() {
    log_section "SYSTEM CONFIGURATION"
    
    fix_bluetooth_a2dp
    enable_firewall
    fix_locale
    configure_timezone
    configure_gnome
    setup_zsh_aliases
    setup_gitconfig
    
    log_success "System configuration completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_system_configuration "$@"
fi
