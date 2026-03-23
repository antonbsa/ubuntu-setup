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

# Failure tracking
FAILURE_CONTEXT=""
IN_ERROR_TRAP=0
LAST_ERROR_SIGNATURE=""
declare -a FAILURES

declare -a REQUIRES_USER_INTERACTION

current_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[$(current_timestamp)] [INFO] $message" >> "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[$(current_timestamp)] [SUCCESS] $message" >> "$LOG_FILE"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[$(current_timestamp)] [WARNING] $message" >> "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[$(current_timestamp)] [ERROR] $message" >> "$LOG_FILE"
}

log_section() {
    local message="$1"
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$message${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "[$(current_timestamp)] ======================================== $message ========================================" >> "$LOG_FILE"
}

# =============================================================================
# Failure Tracking
# =============================================================================

set_failure_context() {
    FAILURE_CONTEXT="$1"
}

clear_failure_context() {
    FAILURE_CONTEXT=""
}

get_failure_count() {
    echo "${#FAILURES[@]}"
}

record_failure() {
    local component="$1"
    local reason="$2"
    local item="$component|$reason"

    if [[ "$item" == "$LAST_ERROR_SIGNATURE" ]]; then
        return 0
    fi

    LAST_ERROR_SIGNATURE="$item"
    FAILURES+=("$item")
    log_error "$component: $reason"
}

on_error() {
    local exit_code="$1"
    local line_no="$2"
    local command="$3"

    if [[ "$IN_ERROR_TRAP" == "1" || "$exit_code" == "0" ]]; then
        return 0
    fi

    IN_ERROR_TRAP=1
    local component="${FAILURE_CONTEXT:-Setup}"
    record_failure "$component" "Command failed at line $line_no: $command (exit code: $exit_code)"
    IN_ERROR_TRAP=0
    return 0
}

run_group_step() {
    local context="$1"
    shift

    set_failure_context "$context"
    "$@"
    local exit_code=$?
    clear_failure_context
    return $exit_code
}

print_failure_summary() {
    if [[ ${#FAILURES[@]} -eq 0 ]]; then
        return 0
    fi

    log_section "FAILURE SUMMARY"
    echo -e "${YELLOW}The following steps failed during setup:${NC}"
    echo ""

    for item in "${FAILURES[@]}"; do
        IFS='|' read -r component reason <<< "$item"
        echo -e "  ${RED}•${NC} ${BLUE}$component${NC}: $reason"
        echo "  • $component: $reason" >> "$LOG_FILE"
    done

    echo ""
}

# =============================================================================
# Confirmation Functions
# =============================================================================

ask_confirmation() {
    local message="$1"
    local default="${2:-n}" # Default to 'n' if not provided
    local response=""
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    echo -e "${YELLOW}$message $prompt${NC}"

    if [[ -r /dev/tty ]]; then
        read -r response < /dev/tty
    else
        log_warning "No interactive terminal detected for confirmation prompt: $message"
    fi

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

    if ! command -v yq &> /dev/null; then
        log_error "yq is required to read configuration values. Please re-run pre-flight checks."
        return 1
    fi

    yq eval "$key" "$config_file" 2>/dev/null
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

is_dry_run() {
    [[ "${DRY_RUN:-0}" == "1" ]]
}

init_log() {
    echo "========================================" >> "$LOG_FILE"
    echo "Ubuntu Setup Script - Started at $(current_timestamp)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    log_info "Log file: $LOG_FILE"
}
