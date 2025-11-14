#!/bin/bash

# =============================================================================
# Productivity Tools Installation - Section C
# Installs: Obsidian, Peek, VLC, terminal tools, Slack, Discord, www folder
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="${1:-$HOME/ubuntu-setup/config.yaml}"

# =============================================================================
# Obsidian
# =============================================================================

install_obsidian() {
    log_info "Installing Obsidian..."
    
    if ! check_config_enabled ".installation.obsidian" "$CONFIG_FILE"; then
        log_warning "Obsidian installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "obsidian" "Obsidian"; then
        return 0
    fi
    
    # Download latest Obsidian AppImage
    local obsidian_url="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.3/Obsidian-1.5.3.AppImage"
    local install_dir="$HOME/.local/bin"
    
    mkdir -p "$install_dir"
    
    wget "$obsidian_url" -O "$install_dir/Obsidian.AppImage"
    chmod +x "$install_dir/Obsidian.AppImage"
    
    # Create desktop entry
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/obsidian.desktop" << EOF
[Desktop Entry]
Name=Obsidian
Exec=$install_dir/Obsidian.AppImage
Icon=obsidian
Type=Application
Categories=Office;
EOF
    
    log_success "Obsidian installed successfully"
    
    # Clone obsidian-notes repository if URL provided
    local obsidian_repo_url
    obsidian_repo_url=$(get_config_value ".workspace.repositories.obsidian_notes" "$CONFIG_FILE")
    
    if [[ -n "$obsidian_repo_url" ]]; then
        local vault_path="$HOME/www/personal/obsidian-notes"
        
        if [[ -d "$vault_path" ]]; then
            log_warning "Obsidian vault already exists at $vault_path. Skipping clone."
        else
            log_info "Cloning Obsidian notes repository from $obsidian_repo_url..."
            mkdir -p "$HOME/www/personal"
            git clone "$obsidian_repo_url" "$vault_path"
            
            if [[ $? -eq 0 ]]; then
                log_success "Obsidian notes repository cloned"
            else
                log_error "Failed to clone Obsidian notes repository"
            fi
        fi
    else
        log_info "No Obsidian repository URL configured. Skipping vault clone."
    fi
}

# =============================================================================
# Peek (Screen Recorder)
# =============================================================================

install_peek() {
    log_info "Installing Peek..."
    
    if check_and_log_installed "peek" "Peek"; then
        return 0
    fi
    
    sudo apt install -y peek
    
    log_success "Peek installed successfully"
}

# =============================================================================
# VLC Media Player
# =============================================================================

install_vlc() {
    log_info "Installing VLC Media Player..."
    
    if ! check_config_enabled ".installation.vlc" "$CONFIG_FILE"; then
        log_warning "VLC installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "vlc" "VLC Media Player"; then
        return 0
    fi
    
    sudo apt install -y vlc
    
    log_success "VLC Media Player installed successfully"
}

# =============================================================================
# Terminal Tools
# =============================================================================

install_terminal_tools() {
    log_info "Installing terminal tools..."
    
    if ! check_config_enabled ".installation.terminal_tools" "$CONFIG_FILE"; then
        log_warning "Terminal tools installation is disabled in config. Skipping."
        return 0
    fi
    
    local tools=("bat" "htop" "tmux" "curl" "wget" "jq")
    
    for tool in "${tools[@]}"; do
        if check_and_log_installed "$tool" "$tool"; then
            continue
        fi
        
        log_info "Installing $tool..."
        sudo apt install -y "$tool"
    done
    
    log_success "Terminal tools installed successfully"
}

# =============================================================================
# Slack
# =============================================================================

install_slack() {
    log_info "Installing Slack..."
    
    if ! check_config_enabled ".installation.slack" "$CONFIG_FILE"; then
        log_warning "Slack installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "slack" "Slack"; then
        return 0
    fi
    
    # Download and install Slack
    wget https://downloads.slack-edge.com/releases/linux/4.36.140/prod/x64/slack-desktop-4.36.140-amd64.deb -O /tmp/slack.deb
    sudo apt install -y /tmp/slack.deb
    rm /tmp/slack.deb
    
    log_success "Slack installed successfully"
    add_requires_interaction "Slack" "Sign in to your workspace"
}

# =============================================================================
# Discord
# =============================================================================

install_discord() {
    log_info "Installing Discord..."
    
    if ! check_config_enabled ".installation.discord" "$CONFIG_FILE"; then
        log_warning "Discord installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "discord" "Discord"; then
        return 0
    fi
    
    # Download and install Discord
    wget "https://discord.com/api/download?platform=linux&format=deb" -O /tmp/discord.deb
    sudo apt install -y /tmp/discord.deb
    rm /tmp/discord.deb
    
    log_success "Discord installed successfully"
    add_requires_interaction "Discord" "Sign in to your account"
}

# =============================================================================
# Create www Folder Structure
# =============================================================================

create_www_folder() {
    log_info "Creating www folder structure..."
    
    if ! check_config_enabled ".workspace.create_www_folder" "$CONFIG_FILE"; then
        log_warning "WWW folder creation is disabled in config. Skipping."
        return 0
    fi
    
    local www_dir="$HOME/www"
    
    if [[ -d "$www_dir" ]]; then
        log_warning "www directory already exists. Checking subdirectories..."
    else
        mkdir -p "$www_dir"
        log_success "Created www directory"
    fi
    
    # Create subdirectories
    local subdirs=("hub" "personal")
    
    for subdir in "${subdirs[@]}"; do
        local dir_path="$www_dir/$subdir"
        if [[ -d "$dir_path" ]]; then
            log_info "Directory $dir_path already exists. Skipping."
        else
            mkdir -p "$dir_path"
            log_success "Created $dir_path"
        fi
    done
    
    log_success "www folder structure created successfully"
}

# =============================================================================
# Main Function
# =============================================================================

setup_productivity_tools() {
    log_section "PRODUCTIVITY TOOLS INSTALLATION"
    
    install_obsidian
    install_peek
    install_vlc
    install_terminal_tools
    install_slack
    install_discord
    create_www_folder
    
    log_success "Productivity tools installation completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_productivity_tools "$@"
fi
