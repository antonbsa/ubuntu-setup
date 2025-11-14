#!/bin/bash

# =============================================================================
# BBB Job Setup - Section E
# Configures: BBB aliases, docker setup, repo cloning, version-specific scripts
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

CONFIG_FILE="${1:-$HOME/ubuntu-setup/config.yaml}"

# =============================================================================
# Append BBB Aliases to ZSH
# =============================================================================

append_bbb_aliases() {
    log_info "Appending BBB aliases to ZSH configuration..."
    
    local bbb_aliases="$SCRIPT_DIR/../bbb/aliases.sh"
    local zsh_aliases="$HOME/.zsh-aliases.sh"
    
    if [[ ! -f "$bbb_aliases" ]]; then
        log_error "BBB aliases file not found at $bbb_aliases"
        return 1
    fi
    
    if [[ ! -f "$zsh_aliases" ]]; then
        log_warning "ZSH aliases file not found. Creating..."
        touch "$zsh_aliases"
    fi
    
    # Check if BBB aliases are already appended
    if grep -q "# BBB" "$zsh_aliases"; then
        log_warning "BBB aliases already present in ZSH aliases. Skipping."
        return 0
    fi
    
    # Append BBB aliases
    cat "$bbb_aliases" >> "$zsh_aliases"
    
    log_success "BBB aliases appended successfully"
}

# =============================================================================
# Copy BBB Setup Script
# =============================================================================

copy_bbb_setup_script() {
    log_info "Copying BBB setup script to home directory..."
    
    local source_script="$SCRIPT_DIR/../bbb/docker/bbb-setup.sh"
    local dest_script="$HOME/bbb-setup.sh"
    
    if [[ ! -f "$source_script" ]]; then
        log_error "BBB setup script not found at $source_script"
        return 1
    fi
    
    if [[ -f "$dest_script" ]]; then
        if ask_confirmation "bbb-setup.sh already exists in home directory. Overwrite?"; then
            backup_file "$dest_script"
            cp "$source_script" "$dest_script"
            chmod +x "$dest_script"
            log_success "BBB setup script overwritten"
        else
            log_info "Keeping existing bbb-setup.sh"
        fi
    else
        cp "$source_script" "$dest_script"
        chmod +x "$dest_script"
        log_success "BBB setup script copied to $dest_script"
    fi
}

# =============================================================================
# Create BBB Folder Structure
# =============================================================================

create_bbb_folders() {
    log_info "Creating BBB folder structure..."
    
    local bbb_dir="$HOME/www/bbb"
    local shared_dir="$bbb_dir/shared"
    
    mkdir -p "$bbb_dir"
    mkdir -p "$shared_dir"
    
    log_success "BBB folders created: $bbb_dir and $shared_dir"
}

# =============================================================================
# Clone BBB Docker Dev Repository
# =============================================================================

clone_bbb_docker_dev() {
    log_info "Cloning BBB Docker Dev repository..."
    
    local bbb_repo_url="https://github.com/iMDT/bbb-docker-dev"
    local clone_path="$HOME/www/bbb/bbb-docker-dev"
    
    if [[ -d "$clone_path" ]]; then
        log_warning "BBB Docker Dev repository already exists at $clone_path. Skipping clone."
        return 0
    fi
    
    git clone "$bbb_repo_url" "$clone_path"
    
    log_success "BBB Docker Dev repository cloned to $clone_path"
}

# =============================================================================
# Get BBB Versions from Repository
# =============================================================================

get_bbb_versions() {
    local repo_path="$HOME/www/bbb/bbb-docker-dev"
    
    if [[ ! -d "$repo_path" ]]; then
        log_error "BBB Docker Dev repository not found. Cannot determine versions."
        return 1
    fi
    
    cd "$repo_path" || return 1
    
    # Fetch all branches
    git fetch --all &>/dev/null
    
    # Get branches that look like version branches (v3.0, v3.1, etc.)
    local versions
    versions=$(git branch -r | grep -oE 'v[0-9]+\.[0-9]+' | sort -V | uniq)
    
    echo "$versions"
}

# =============================================================================
# Create BBB Version-Specific Scripts
# =============================================================================

create_bbb_version_scripts() {
    log_info "Checking available BBB versions..."
    
    local versions
    versions=$(get_bbb_versions)
    
    if [[ -z "$versions" ]]; then
        log_warning "No BBB versions found. Using default versions: v3.0 v3.1"
        versions="v3.0 v3.1"
    fi
    
    log_info "Available BBB versions:"
    echo "$versions"
    echo ""
    
    # Ask user which versions to set up
    log_info "Select which BBB versions to set up (space-separated):"
    echo "Available: $versions"
    echo "Example: v3.0 v3.1"
    echo "Or type 'all' to set up all versions"
    read -r selected_versions
    
    if [[ "$selected_versions" == "all" ]]; then
        selected_versions="$versions"
        log_info "Setting up all versions"
    fi
    
    # Get CPU configuration from config file
    local cpu_limit
    local cpu_count
    local cpu_max
    
    cpu_limit=$(get_config_value ".bbb.container.cpu_limit" "$CONFIG_FILE")
    cpu_limit=${cpu_limit:-auto}
    
    cpu_count=$(nproc)
    
    if [[ "$cpu_limit" == "auto" ]]; then
        cpu_max=$((cpu_count - 1))
        log_info "Using automatic CPU limit: 0-$cpu_max (all but one core)"
    else
        cpu_max="$cpu_limit"
        log_info "Using configured CPU limit: $cpu_max"
    fi
    
    # Get ulimit configuration
    local ulimit_nofile
    ulimit_nofile=$(get_config_value ".bbb.container.ulimit_nofile" "$CONFIG_FILE")
    ulimit_nofile=${ulimit_nofile:-5000}
    
    # Read additional container setup parameters
    local additional_params
    local additional_params_file="$SCRIPT_DIR/../bbb/docker/additional-container-setup.txt"
    
    if [[ -f "$additional_params_file" ]]; then
        additional_params=$(cat "$additional_params_file")
        # Replace CPU-MAX placeholder
        additional_params="${additional_params//\{CPU-MAX\}/$cpu_max}"
    else
        log_warning "Additional container setup file not found. Using default parameters."
        additional_params="--custom-script=bbb-setup.sh --docker-custom-params=\"--ulimit nofile=$ulimit_nofile:$ulimit_nofile --cpuset-cpus=0-$cpu_max -v \$HOME/www/bbb/shared:/home/bigbluebutton/shared:rw\""
    fi
    
    # Create script for each selected version
    for version in $selected_versions; do
        create_version_script "$version" "$additional_params"
    done
    
    log_success "BBB version-specific scripts created"
}

# =============================================================================
# Create Individual Version Script
# =============================================================================

create_version_script() {
    local version="$1"
    local additional_params="$2"
    
    # Convert version to short format (v3.0 -> 30)
    local version_short
    version_short=$(echo "$version" | sed 's/v//g' | sed 's/\.//g')
    
    # Get username suffix from config
    local username_suffix
    username_suffix=$(get_config_value ".bbb.container.username_suffix" "$CONFIG_FILE")
    username_suffix=${username_suffix:-anton}
    
    local script_name="create_bbb${version_short}.sh"
    local script_path="$HOME/$script_name"
    local container_name="bbb${version_short}-${username_suffix}"
    
    log_info "Creating script: $script_name for version $version"
    
    # Create the script
    cat > "$script_path" << EOF
#!/bin/bash

# BBB Container Creation Script for version $version
# Container name: $container_name

echo "Creating BBB $version container: $container_name"

cd "\$HOME/www/bbb/bbb-docker-dev" || exit 1

# Checkout the correct branch
git checkout "$version"

# Run the create_bbb.sh script with additional parameters
./create_bbb.sh \\
    $additional_params \\
    "$container_name"

echo "BBB $version container '$container_name' created successfully!"
echo "To start: docker start $container_name"
echo "To enter: docker exec -it $container_name /bin/bash"
EOF
    
    chmod +x "$script_path"
    
    log_success "Created $script_path"
}

# =============================================================================
# Append BBB Terminator Layout
# =============================================================================

append_bbb_terminator_layout() {
    log_info "Appending BBB Terminator layout..."
    
    local bbb_terminator_config="$SCRIPT_DIR/../bbb/terminator-settings.txt"
    local terminator_config="$HOME/.config/terminator/config"
    
    if [[ ! -f "$bbb_terminator_config" ]]; then
        log_error "BBB Terminator settings not found at $bbb_terminator_config"
        return 1
    fi
    
    if [[ ! -f "$terminator_config" ]]; then
        log_warning "Terminator config not found. Skipping layout configuration."
        return 0
    fi
    
    # Check if BBB layout already exists
    if grep -q "\[\[work-setup\]\]" "$terminator_config"; then
        log_warning "BBB work-setup layout already exists in Terminator config. Skipping."
        return 0
    fi
    
    # Read BBB terminator settings and replace placeholders
    local user_home="$HOME"
    local default_bbb_container="bbb30-anton"  # Default to v3.0
    
    local processed_config
    processed_config=$(cat "$bbb_terminator_config")
    processed_config="${processed_config//\{USER_HOME\}/$user_home}"
    processed_config="${processed_config//\{DEFAULT_BBB_CONTAINER\}/$default_bbb_container}"
    
    # Append to terminator config
    echo "" >> "$terminator_config"
    echo "$processed_config" >> "$terminator_config"
    
    log_success "BBB Terminator layout appended successfully"
}

# =============================================================================
# Main Function
# =============================================================================

setup_bbb_job() {
    log_section "BBB JOB SETUP"
    
    # Ask for confirmation before proceeding
    if ! ask_confirmation "Do you want to proceed with BBB job setup?"; then
        log_info "BBB job setup skipped by user."
        return 0
    fi
    
    append_bbb_aliases
    copy_bbb_setup_script
    create_bbb_folders
    clone_bbb_docker_dev
    create_bbb_version_scripts
    append_bbb_terminator_layout
    
    log_success "BBB job setup completed"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_bbb_job "$@"
fi
