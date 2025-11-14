#!/bin/bash

# =============================================================================
# Utility Functions for Ubuntu Setup
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file location
LOG_FILE="${HOME}/ubuntu-setup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[${TIMESTAMP}] [INFO] $message" >> "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[${TIMESTAMP}] [SUCCESS] $message" >> "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[${TIMESTAMP}] [WARNING] $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[${TIMESTAMP}] [ERROR] $message" >> "$LOG_FILE"
}

log_section() {
    local message="$1"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$message${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "[${TIMESTAMP}] ======================================== $message ========================================" >> "$LOG_FILE"
}

# =============================================================================
# Confirmation Functions
# =============================================================================

ask_confirmation() {
    local message="$1"
    local default="${2:-n}" # Default to 'n' if not provided
    
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo -e "${YELLOW}$message $prompt${NC}"
    read -r response
    
    # Use default if empty
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "User confirmed: $message"
        return 0
    else
        log_info "User declined: $message"
        return 1
    fi
}

# =============================================================================
# Package Check Functions
# =============================================================================

is_installed() {
    local package="$1"
    
    if command -v "$package" &> /dev/null; then
        return 0
    elif dpkg -l | grep -q "^ii  $package "; then
        return 0
    else
        return 1
    fi
}

check_and_log_installed() {
    local package="$1"
    local display_name="${2:-$package}"
    
    if is_installed "$package"; then
        log_warning "$display_name is already installed. Skipping."
        return 0
    else
        log_info "$display_name is not installed. Proceeding with installation."
        return 1
    fi
}

# =============================================================================
# Config File Functions
# =============================================================================

get_config_value() {
    local key="$1"
    local config_file="$2"
    
    # Use yq to parse YAML if available, otherwise use grep/sed
    if command -v yq &> /dev/null; then
        yq eval "$key" "$config_file" 2>/dev/null
    else
        # Fallback to basic grep/sed parsing
        grep -A1 "$key" "$config_file" | tail -n1 | sed 's/.*: //' | tr -d '"' | tr -d "'"
    fi
}

check_config_enabled() {
    local key="$1"
    local config_file="$2"
    local value
    
    value=$(get_config_value "$key" "$config_file")
    
    if [[ "$value" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# File Backup Functions
# =============================================================================

backup_file() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
        return 0
    else
        log_warning "File $file does not exist. No backup needed."
        return 1
    fi
}

# =============================================================================
# Error Handling
# =============================================================================

handle_error() {
    local exit_code=$?
    local message="$1"
    
    if [[ $exit_code -ne 0 ]]; then
        log_error "$message (Exit code: $exit_code)"
        return 1
    fi
    return 0
}

# =============================================================================
# User Interaction Tracking
# =============================================================================

declare -a REQUIRES_USER_INTERACTION

add_requires_interaction() {
    local app="$1"
    local reason="$2"
    REQUIRES_USER_INTERACTION+=("$app|$reason")
}

print_interaction_summary() {
    if [[ ${#REQUIRES_USER_INTERACTION[@]} -gt 0 ]]; then
        log_section "SOFTWARE REQUIRING USER INTERACTION"
        echo -e "${YELLOW}The following applications require manual login/setup:${NC}"
        echo ""
        
        for item in "${REQUIRES_USER_INTERACTION[@]}"; do
            IFS='|' read -r app reason <<< "$item"
            echo -e "  ${GREEN}•${NC} ${BLUE}$app${NC}: $reason"
            echo "  • $app: $reason" >> "$LOG_FILE"
        done
        
        echo ""
    fi
}

# =============================================================================
# Initialize Log File
# =============================================================================

init_log() {
    echo "========================================" >> "$LOG_FILE"
    echo "Ubuntu Setup Script - Started at ${TIMESTAMP}" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    log_info "Log file: $LOG_FILE"
}
