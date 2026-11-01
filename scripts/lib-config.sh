#!/bin/bash
# lib-config.sh — Configuration file parser and environment manager
# Load settings from .wp-db-migrate.conf and environment variable overrides
#
# Usage:
#   source lib-config.sh
#   config_load /path/to/.wp-db-migrate.conf
#   config_get "from_url"              # Get value with fallback
#   config_require "from_url"          # Require value or fail
#   config_apply_env_overrides         # Merge WP_DB_MIGRATE_* vars

# Configuration storage (associative array, global scope)
declare -A CONFIG=()

# Color codes
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration from file
config_load() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}Error: Config file not found: $config_file${NC}" >&2
        return 1
    fi

    # Read each line from config file
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" =~ ^# ]] && continue

        # Trim whitespace
        key="${key// /}"
        value="${value#\"}"
        value="${value%\"}"

        # Convert to lowercase for consistency (Bash 3.2 compatible)
        key_lower=$(printf '%s\n' "$key" | tr '[:upper:]' '[:lower:]')
        CONFIG["$key_lower"]="$value"
    done < "$config_file"

    return 0
}

# Get configuration value with default
config_get() {
    local key="$1"
    local default="${2:-}"
    local key_lower
    local value

    key_lower=$(printf '%s\n' "$key" | tr '[:upper:]' '[:lower:]')
    value="${CONFIG[$key_lower]:-$default}"

    echo "$value"
}

# Require a configuration value (fail if missing)
config_require() {
    local key="$1"
    local key_lower
    local value

    key_lower=$(printf '%s\n' "$key" | tr '[:upper:]' '[:lower:]')
    value="${CONFIG[$key_lower]:-}"

    if [[ -z "$value" ]]; then
        echo -e "${RED}❌ Missing required config: $key${NC}" >&2
        return 1
    fi

    echo "$value"
    return 0
}

# Apply environment variable overrides
# WP_DB_MIGRATE_FROM_URL, WP_DB_MIGRATE_TO_PATH, etc.
config_apply_env_overrides() {
    # Map env var names to config keys
    local -A env_map=(
        ["WP_DB_MIGRATE_FROM_URL"]="from_url"
        ["WP_DB_MIGRATE_TO_PATH"]="to_path"
        ["WP_DB_MIGRATE_SSH_HOST"]="ssh_host"
        ["WP_DB_MIGRATE_SSH_USER"]="ssh_user"
        ["WP_DB_MIGRATE_WP_PATH"]="wp_path"
        ["WP_DB_MIGRATE_EXCLUDE_TABLES"]="exclude_tables"
        ["WP_DB_MIGRATE_COMPRESS"]="compress"
        ["WP_DB_MIGRATE_PARALLEL"]="parallel"
        ["WP_DB_MIGRATE_JOBS"]="jobs"
        ["WP_DB_MIGRATE_DRY_RUN"]="dry_run"
        ["WP_DB_MIGRATE_VERBOSE"]="verbose"
    )

    # Override config with environment variables
    for env_var in "${!env_map[@]}"; do
        if [[ -n "${!env_var:-}" ]]; then
            config_key="${env_map[$env_var]}"
            CONFIG["$config_key"]="${!env_var}"
        fi
    done

    return 0
}

# Print configuration summary
config_print_summary() {
    echo -e "\n${BLUE}Configuration Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    for key in "${!CONFIG[@]}"; do
        value="${CONFIG[$key]}"
        # Mask sensitive values
        if [[ "$key" == *"password"* || "$key" == *"secret"* ]]; then
            value="***"
        fi
        printf "  %-30s %s\n" "$key:" "$value"
    done

    echo ""
    return 0
}

# Validate that required keys are present
config_require_keys() {
    local -a required_keys=("$@")
    local missing_keys=()

    for key in "${required_keys[@]}"; do
        key_lower="${key,,}"
        if [[ -z "${CONFIG[$key_lower]:-}" ]]; then
            missing_keys+=("$key")
        fi
    done

    if (( ${#missing_keys[@]} > 0 )); then
        echo -e "${RED}❌ Missing required configuration:${NC}" >&2
        printf "  - %s\n" "${missing_keys[@]}" >&2
        return 1
    fi

    return 0
}

# Export configuration as environment variables
config_export_env() {
    for key in "${!CONFIG[@]}"; do
        value="${CONFIG[$key]}"
        # Convert to uppercase for export
        export_key="WP_DB_MIGRATE_${key^^}"
        export "$export_key=$value"
    done

    return 0
}

# Clear all configuration
config_clear() {
    CONFIG=()
    return 0
}

# Export functions for use in other scripts
export -f config_load
export -f config_get
export -f config_require
export -f config_apply_env_overrides
export -f config_print_summary
export -f config_require_keys
export -f config_export_env
export -f config_clear
