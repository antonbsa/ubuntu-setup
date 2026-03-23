#!/bin/bash

# =============================================================================
# System Configuration - Section D
# Configures: Bluetooth, firewall, locale, GNOME settings, ZSH aliases, gitconfig
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# =============================================================================
# Fix Bluetooth Headphones (A2DP Auto-Switch)
# =============================================================================

fix_bluetooth_a2dp() {
    local config_file="$1"

    log_info "Setting up Bluetooth A2DP auto-switch service..."
    
    if ! check_config_enabled ".security.bluetooth_a2dp_fix" "$config_file"; then
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
    local config_file="$1"

    log_info "Enabling firewall (UFW)..."
    
    if ! check_config_enabled ".security.enable_firewall" "$config_file"; then
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
    local config_file="$1"

    log_info "Configuring system locale..."
    
    local desired_locale
    desired_locale=$(get_config_value ".system.localization.locale" "$config_file")
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
    local config_file="$1"

    log_info "Configuring GNOME settings..."

    if ! check_config_enabled ".gnome.configure" "$config_file"; then
        log_warning "GNOME configuration is disabled in config. Skipping."
        return 0
    fi

    local desktop_session="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    if [[ "$desktop_session" != *"GNOME"* && "$desktop_session" != *"ubuntu:GNOME"* ]]; then
        log_warning "GNOME is not the active desktop session. Skipping GNOME settings."
        return 0
    fi

    local dark_mode
    local power_mode
    local dock_icon_size
    local suspend_timeout
    local night_light_enabled
    local night_light_schedule_from
    local night_light_schedule_to
    local night_light_temperature

    dark_mode=$(get_config_value ".gnome.settings.dark_mode" "$config_file")
    power_mode=$(get_config_value ".gnome.settings.power_mode" "$config_file")
    dock_icon_size=$(get_config_value ".gnome.settings.dock_icon_size" "$config_file")
    suspend_timeout=$(get_config_value ".gnome.settings.suspend_timeout" "$config_file")
    night_light_enabled=$(get_config_value ".gnome.settings.night_light.enabled" "$config_file")
    night_light_schedule_from=$(get_config_value ".gnome.settings.night_light.schedule_from" "$config_file")
    night_light_schedule_to=$(get_config_value ".gnome.settings.night_light.schedule_to" "$config_file")
    night_light_temperature=$(get_config_value ".gnome.settings.night_light.temperature" "$config_file")

    dark_mode=${dark_mode:-true}
    power_mode=${power_mode:-performance}
    dock_icon_size=${dock_icon_size:-30}
    suspend_timeout=${suspend_timeout:-6000}
    night_light_enabled=${night_light_enabled:-true}
    night_light_schedule_from=${night_light_schedule_from:-17.5}
    night_light_schedule_to=${night_light_schedule_to:-8.0}
    night_light_temperature=${night_light_temperature:-3700}

    if [[ "$dark_mode" == "true" ]]; then
        log_info "Enabling dark mode..."
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'
    else
        log_info "Disabling dark mode..."
        gsettings set org.gnome.desktop.interface color-scheme 'default'
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
    fi

    log_info "Setting power mode to: $power_mode..."
    if command -v powerprofilesctl &> /dev/null; then
        powerprofilesctl set "$power_mode" 2>/dev/null || log_warning "Could not set power mode to $power_mode"
    else
        log_warning "powerprofilesctl not available. Install power-profiles-daemon to set power mode."
    fi

    log_info "Setting dock icon size to $dock_icon_size..."
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size "$dock_icon_size"

    log_info "Setting automatic suspend to $((suspend_timeout / 60)) minutes..."
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout "$suspend_timeout"
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout "$suspend_timeout"

    log_info "Configuring night light..."
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled "$night_light_enabled"

    if [[ "$night_light_enabled" == "true" ]]; then
        gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
        gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from "$night_light_schedule_from"
        gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to "$night_light_schedule_to"
        gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature "$night_light_temperature"
    fi

    log_success "GNOME settings configured successfully"
}

# =============================================================================
# ZSH Aliases
# =============================================================================

setup_zsh_aliases() {
    log_info "Setting up ZSH aliases..."

    local aliases_source="$SCRIPT_DIR/../config/zsh_aliases.sh"
    local zshrc_before_source="$SCRIPT_DIR/../config/zshrc-before-source.sh"
    local zshrc_after_source="$SCRIPT_DIR/../config/zshrc.sh"
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
    if grep -q "source.*zsh_aliases.sh" "$zshrc"; then
        log_warning "ZSH aliases already configured in .zshrc. Skipping."
        return 0
    fi

    # Copy aliases file to home directory
    cp "$aliases_source" "$HOME/.zsh_aliases.sh"

    # Insert before-source content right before "source $ZSH/oh-my-zsh.sh"
    if [[ -f "$zshrc_before_source" ]]; then
        if grep -q 'source \$ZSH/oh-my-zsh.sh' "$zshrc"; then
            local source_line_num
            source_line_num=$(grep -n 'source \$ZSH/oh-my-zsh.sh' "$zshrc" | head -1 | cut -d: -f1)
            sed -i "$((source_line_num - 1))r $zshrc_before_source" "$zshrc"
        else
            log_warning "Could not find 'source \$ZSH/oh-my-zsh.sh' in .zshrc. Appending before-source content at the end."
            printf '\\n' >> "$zshrc"
            cat "$zshrc_before_source" >> "$zshrc"
        fi
    fi

    # Append aliases source and zshrc.sh content at the end
    cat >> "$zshrc" << 'EOF'

# Custom aliases
if [ -f ~/.zsh_aliases.sh ]; then
    source ~/.zsh_aliases.sh
fi
EOF

    if [[ -f "$zshrc_after_source" ]]; then
        printf '\\n' >> "$zshrc"
        cat "$zshrc_after_source" >> "$zshrc"
    fi

    log_success "ZSH aliases configured successfully"
}

# =============================================================================
# Git Configuration
# =============================================================================

setup_gitconfig() {
    local config_file="$1"

    log_info "Configuring Git..."
    
    if ! check_config_enabled ".git.setup" "$config_file"; then
        log_warning "Git configuration is disabled in config. Skipping."
        return 0
    fi
    
    local git_name
    local git_email
    local git_branch
    
    git_name=$(get_config_value ".user.name" "$config_file")
    git_email=$(get_config_value ".user.github_email" "$config_file")
    git_branch=$(get_config_value ".git.default_branch" "$config_file")
    
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
    local config_file="$1"

    log_info "Configuring timezone..."
    
    local timezone
    timezone=$(get_config_value ".system.localization.timezone" "$config_file")
    
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
    local config_file="${1:-$HOME/ubuntu-setup/config.yaml}"

    log_section "SYSTEM CONFIGURATION"
    
    fix_bluetooth_a2dp "$config_file"
    enable_firewall "$config_file"
    fix_locale "$config_file"
    configure_timezone "$config_file"
    configure_gnome "$config_file"
    setup_zsh_aliases
    setup_gitconfig "$config_file"
    
    log_success "System configuration completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_system_configuration "$@"
fi
