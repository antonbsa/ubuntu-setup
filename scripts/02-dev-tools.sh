#!/bin/bash

# =============================================================================
# Development Tools Installation - Section B
# Installs: NVM, GitHub CLI, VSCode, Docker, Chrome, Insomnia, Terminator,
#           ZSH, Flameshot, SSH keys, NPM global packages
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="${1:-$HOME/ubuntu-setup/config.yaml}"

# =============================================================================
# NVM (Node Version Manager)
# =============================================================================

install_nvm() {
    log_info "Installing NVM..."
    
    if ! check_config_enabled ".installation.nodejs" "$CONFIG_FILE"; then
        log_warning "Node.js installation is disabled in config. Skipping NVM."
        return 0
    fi
    
    if [[ -d "$HOME/.nvm" ]]; then
        log_warning "NVM is already installed. Skipping."
        return 0
    fi
    
    # Install NVM (LTS version installer)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install LTS Node.js
    log_info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    log_success "NVM and Node.js LTS installed successfully"
}

# =============================================================================
# GitHub CLI
# =============================================================================

install_gh_cli() {
    log_info "Installing GitHub CLI..."
    
    if check_and_log_installed "gh" "GitHub CLI"; then
        return 0
    fi
    
    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    sudo apt update
    sudo apt install -y gh
    
    log_success "GitHub CLI installed successfully"
    add_requires_interaction "GitHub CLI" "Run 'gh auth login' to authenticate"
}

# =============================================================================
# Visual Studio Code
# =============================================================================

install_vscode() {
    log_info "Installing Visual Studio Code..."
    
    if ! check_config_enabled ".installation.editors.vscode" "$CONFIG_FILE"; then
        log_warning "VSCode installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "code" "Visual Studio Code"; then
        return 0
    fi
    
    # Add Microsoft GPG key and repository
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    
    sudo apt update
    sudo apt install -y code
    
    log_success "Visual Studio Code installed successfully"
    add_requires_interaction "Visual Studio Code" "Sign in to sync settings and extensions"
}

# =============================================================================
# Docker
# =============================================================================

install_docker() {
    log_info "Installing Docker..."
    
    if ! check_config_enabled ".installation.docker" "$CONFIG_FILE"; then
        log_warning "Docker installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "docker" "Docker"; then
        return 0
    fi
    
    # Install prerequisites
    sudo apt install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker "$USER"
    
    log_success "Docker installed successfully"
    log_warning "You need to log out and log back in for docker group changes to take effect"
}

# =============================================================================
# Google Chrome
# =============================================================================

install_chrome() {
    log_info "Installing Google Chrome..."
    
    if ! check_config_enabled ".installation.browsers.google_chrome" "$CONFIG_FILE"; then
        log_warning "Google Chrome installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "google-chrome" "Google Chrome"; then
        return 0
    fi
    
    # Download and install Chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome.deb
    sudo apt install -y /tmp/google-chrome.deb
    rm /tmp/google-chrome.deb
    
    log_success "Google Chrome installed successfully"
    add_requires_interaction "Google Chrome" "Sign in to sync bookmarks and settings"
}

# =============================================================================
# Insomnia
# =============================================================================

install_insomnia() {
    log_info "Installing Insomnia..."
    
    if check_and_log_installed "insomnia" "Insomnia"; then
        return 0
    fi
    
    # Add Insomnia repository
    echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" | sudo tee /etc/apt/sources.list.d/insomnia.list
    
    sudo apt update
    sudo apt install -y insomnia
    
    log_success "Insomnia installed successfully"
}

# =============================================================================
# Terminator
# =============================================================================

install_terminator() {
    log_info "Installing Terminator..."
    
    if ! check_config_enabled ".installation.terminals.terminator" "$CONFIG_FILE"; then
        log_warning "Terminator installation is disabled in config. Skipping."
        return 0
    fi
    
    if check_and_log_installed "terminator" "Terminator"; then
        return 0
    fi
    
    sudo apt install -y terminator
    
    # Apply base configuration if it doesn't exist
    local config_dir="$HOME/.config/terminator"
    local config_file="$config_dir/config"
    local base_config="$SCRIPT_DIR/../config/base-terminator-settings.txt"
    
    if [[ ! -f "$config_file" ]]; then
        mkdir -p "$config_dir"
        if [[ -f "$base_config" ]]; then
            cp "$base_config" "$config_file"
            log_success "Applied base Terminator configuration"
        fi
    else
        if ask_confirmation "Terminator config already exists. Overwrite with base configuration?"; then
            backup_file "$config_file"
            cp "$base_config" "$config_file"
            log_success "Overwritten Terminator configuration with base settings"
        fi
    fi
    
    log_success "Terminator installed successfully"
}

# =============================================================================
# ZSH and Oh My Zsh
# =============================================================================

install_zsh() {
    log_info "Installing ZSH and Oh My Zsh..."
    
    if check_and_log_installed "zsh" "ZSH"; then
        log_info "ZSH already installed"
    else
        sudo apt install -y zsh
        log_success "ZSH installed successfully"
    fi
    
    # Install Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_warning "Oh My Zsh is already installed. Skipping."
    else
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed successfully"
    fi
    
    # Set ZSH as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting ZSH as default shell..."
        sudo chsh -s "$(which zsh)" "$USER"
        log_warning "Please log out and log back in for the shell change to take effect"
    fi
}

# =============================================================================
# Flameshot
# =============================================================================

install_flameshot() {
    log_info "Installing Flameshot..."
    
    if check_and_log_installed "flameshot" "Flameshot"; then
        return 0
    fi
    
    sudo apt install -y flameshot
    
    # Add keyboard shortcuts
    log_info "Setting up Flameshot keyboard shortcuts..."
    
    # Custom keyboard shortcuts need to be set via gsettings
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
    
    # Direct Print key
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Flameshot Print'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'flameshot gui'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding 'Print'
    
    # Shift+Super+S
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Flameshot Combo'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'flameshot gui'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Shift><Super>s'
    
    log_success "Flameshot installed and keyboard shortcuts configured"
}

# =============================================================================
# SSH Key Setup
# =============================================================================

setup_ssh_keys() {
    log_info "Setting up SSH keys..."
    
    if ! check_config_enabled ".user.ssh.generate" "$CONFIG_FILE"; then
        log_warning "SSH key generation is disabled in config. Skipping."
        return 0
    fi
    
    local ssh_dir="$HOME/.ssh"
    local key_type
    local comment
    
    key_type=$(get_config_value ".user.ssh.key_type" "$CONFIG_FILE")
    key_type=${key_type:-ed25519}
    
    comment=$(get_config_value ".user.ssh.comment" "$CONFIG_FILE")
    comment=${comment:-$(get_config_value ".user.github_email" "$CONFIG_FILE")}
    
    local key_file="$ssh_dir/id_$key_type"
    
    if [[ -f "$key_file" ]]; then
        log_warning "SSH key already exists at $key_file. Skipping generation."
        log_info "Public key:"
        cat "${key_file}.pub"
        return 0
    fi
    
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    
    log_info "Generating SSH key (type: $key_type)..."
    ssh-keygen -t "$key_type" -C "$comment" -f "$key_file" -N ""
    
    log_success "SSH key generated successfully"
    log_info "Public key:"
    cat "${key_file}.pub"
    
    add_requires_interaction "SSH Key" "Add the public key above to GitHub/GitLab/etc."
}

# =============================================================================
# NPM Global Packages
# =============================================================================

install_npm_global_packages() {
    log_info "Installing NPM global packages..."
    
    if ! check_config_enabled ".installation.nodejs" "$CONFIG_FILE"; then
        log_warning "Node.js installation is disabled in config. Skipping NPM packages."
        return 0
    fi
    
    # Ensure NVM is loaded
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v npm &> /dev/null; then
        log_error "NPM is not available. Please install Node.js first."
        return 1
    fi
    
    # Install TypeScript
    log_info "Installing TypeScript..."
    npm install -g typescript
    
    # Install Playwright with browsers
    log_info "Installing Playwright..."
    npm install -g playwright
    npx playwright install --with-deps
    
    log_success "NPM global packages installed successfully"
}

# =============================================================================
# Main Function
# =============================================================================

setup_dev_tools() {
    log_section "DEVELOPMENT TOOLS INSTALLATION"
    
    install_nvm
    install_gh_cli
    install_vscode
    install_docker
    install_chrome
    install_insomnia
    install_terminator
    install_zsh
    install_flameshot
    setup_ssh_keys
    install_npm_global_packages
    
    log_success "Development tools installation completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_dev_tools "$@"
fi
