#!/bin/bash
# lib-ssh.sh — SSH utility library for remote WordPress operations
# Execute commands on remote servers, manage database exports via SSH, handle authentication
#
# Usage:
#   source lib-ssh.sh
#   ssh_test_connection "user@host" "/var/www/html"
#   ssh_export_db "user@host" "/var/www/html" "local_file.sql"
#   ssh_get_db_size "user@host" "/var/www/html"

# shellcheck disable=SC2034
# SSH state
declare -g SSH_HOST=""
declare -g SSH_USER=""
declare -g SSH_PORT=22
declare -g SSH_KEY=""
declare -g SSH_KEY_TYPE=""
declare -g REMOTE_WP_PATH=""
declare -g SSH_TIMEOUT=30

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configure SSH connection
ssh_configure() {
    local user_host="$1"
    local wp_path="$2"
    local ssh_key="${3:-}"
    local ssh_port="${4:-22}"

    # Parse user@host format
    if [[ "$user_host" == *"@"* ]]; then
        SSH_USER="${user_host%%@*}"
        SSH_HOST="${user_host##*@}"
    else
        echo -e "${RED}Error: Expected format 'user@host', got '$user_host'${NC}" >&2
        return 1
    fi

    REMOTE_WP_PATH="$wp_path"
    SSH_PORT="$ssh_port"

    # Use provided key or look for standard locations
    if [[ -n "$ssh_key" ]]; then
        SSH_KEY="$ssh_key"
        if [[ ! -f "$SSH_KEY" ]]; then
            echo -e "${RED}Error: SSH key not found: $SSH_KEY${NC}" >&2
            return 1
        fi
    fi

    return 0
}

# Test SSH connection to remote host
ssh_test_connection() {
    local user_host="$1"
    local wp_path="${2:-/var/www/html}"

    ssh_configure "$user_host" "$wp_path" || return 1

    echo -e "${BLUE}Testing SSH connection to $SSH_HOST...${NC}"

    # Build SSH command with options
    local ssh_cmd=(ssh)
    ssh_cmd+=(-o "ConnectTimeout=$SSH_TIMEOUT")
    ssh_cmd+=(-o StrictHostKeyChecking=accept-new)
    ssh_cmd+=(-p "$SSH_PORT")

    if [[ -n "$SSH_KEY" ]]; then
        ssh_cmd+=(-i "$SSH_KEY")
    fi

    # Test connection
    if ! "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "exit 0" 2>/dev/null; then
        echo -e "${RED}❌ Failed to connect to $SSH_USER@$SSH_HOST:$SSH_PORT${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ SSH connection successful${NC}"
    return 0
}

# Execute remote command via SSH
ssh_exec() {
    local cmd="$1"

    if [[ -z "$SSH_HOST" ]]; then
        echo -e "${RED}Error: SSH not configured. Call ssh_configure first.${NC}" >&2
        return 1
    fi

    # Build SSH command
    local ssh_cmd=(ssh)
    ssh_cmd+=(-o "ConnectTimeout=$SSH_TIMEOUT")
    ssh_cmd+=(-o StrictHostKeyChecking=accept-new)
    ssh_cmd+=(-p "$SSH_PORT")

    if [[ -n "$SSH_KEY" ]]; then
        ssh_cmd+=(-i "$SSH_KEY")
    fi

    # Execute remote command
    "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "$cmd" 2>&1
}

# Execute remote command and capture output
ssh_exec_output() {
    local cmd="$1"

    if [[ -z "$SSH_HOST" ]]; then
        echo -e "${RED}Error: SSH not configured. Call ssh_configure first.${NC}" >&2
        return 1
    fi

    # Build SSH command
    local ssh_cmd=(ssh)
    ssh_cmd+=(-o "ConnectTimeout=$SSH_TIMEOUT")
    ssh_cmd+=(-o StrictHostKeyChecking=accept-new)
    ssh_cmd+=(-p "$SSH_PORT")

    if [[ -n "$SSH_KEY" ]]; then
        ssh_cmd+=(-i "$SSH_KEY")
    fi

    # Execute and capture output
    "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "$cmd" 2>/dev/null
}

# Check if WP-CLI is available on remote host
ssh_check_wp_cli() {
    local output
    output=$(ssh_exec_output "which wp" 2>&1)

    if [[ -z "$output" ]] || [[ "$output" == *"not found"* ]]; then
        echo -e "${RED}❌ WP-CLI not found on remote host${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ WP-CLI available at: $output${NC}"
    return 0
}

# Get remote database size
ssh_get_db_size() {
    local output
    output=$(ssh_exec_output "cd '$REMOTE_WP_PATH' && wp db size --format=bytes" 2>&1)

    if [[ -z "$output" ]] || [[ "$output" == *"Error"* ]]; then
        echo -e "${YELLOW}Note: Could not determine remote database size${NC}" >&2
        echo "0"
        return 0
    fi

    echo "$output"
}

# Export database from remote host
ssh_export_db() {
    local user_host="$1"
    local wp_path="$2"
    local local_file="$3"
    local exclude_tables="${4:-}"

    ssh_configure "$user_host" "$wp_path" || return 1

    echo -e "${BLUE}Exporting database from $SSH_HOST:$wp_path...${NC}"

    # Build wp db export command
    local export_cmd="cd '$REMOTE_WP_PATH' && wp db export"

    # Add table exclusions if provided
    if [[ -n "$exclude_tables" ]]; then
        # Convert comma-separated list to wp db export format
        local tables_to_skip
        tables_to_skip=$(echo "$exclude_tables" | tr ',' '\n' | sed 's/^/--skip-tables=/' | tr '\n' ' ')
        export_cmd="$export_cmd $tables_to_skip"
    fi

    export_cmd="$export_cmd -"

    # Build SSH command
    local ssh_cmd=(ssh)
    ssh_cmd+=(-o "ConnectTimeout=$SSH_TIMEOUT")
    ssh_cmd+=(-o StrictHostKeyChecking=accept-new)
    ssh_cmd+=(-p "$SSH_PORT")

    if [[ -n "$SSH_KEY" ]]; then
        ssh_cmd+=(-i "$SSH_KEY")
    fi

    # Execute remote export and pipe to local file
    if ! "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "$export_cmd" > "$local_file" 2>&1; then
        echo -e "${RED}❌ Database export failed${NC}" >&2
        return 1
    fi

    # Verify file was created and has content
    if [[ ! -f "$local_file" ]] || [[ ! -s "$local_file" ]]; then
        echo -e "${RED}❌ Export file is empty or was not created${NC}" >&2
        return 1
    fi

    local file_size
    file_size=$(du -h "$local_file" | cut -f1)

    echo -e "${GREEN}✓ Database exported to: $local_file ($file_size)${NC}"
    return 0
}

# Get remote WordPress version
ssh_get_wp_version() {
    local output
    output=$(ssh_exec_output "cd '$REMOTE_WP_PATH' && wp core version" 2>&1)

    if [[ -z "$output" ]] || [[ "$output" == *"Error"* ]]; then
        echo "unknown"
        return 1
    fi

    echo "$output"
}

# Get remote site URL
ssh_get_site_url() {
    local output
    output=$(ssh_exec_output "cd '$REMOTE_WP_PATH' && wp option get siteurl" 2>&1)

    if [[ -z "$output" ]] || [[ "$output" == *"Error"* ]]; then
        echo "unknown"
        return 1
    fi

    echo "$output"
}

# Verify remote WordPress installation
ssh_verify_wordpress() {
    echo -e "${BLUE}Verifying remote WordPress installation...${NC}"

    ssh_check_wp_cli || return 1

    # Check WordPress installation
    local wp_path_check
    wp_path_check=$(ssh_exec_output "test -f '$REMOTE_WP_PATH/wp-config.php' && echo 'found' || echo 'not found'" 2>&1)

    if [[ "$wp_path_check" != "found" ]]; then
        echo -e "${RED}❌ wp-config.php not found at $REMOTE_WP_PATH${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ WordPress installation verified${NC}"
    return 0
}

# Export functions
export -f ssh_configure
export -f ssh_test_connection
export -f ssh_exec
export -f ssh_exec_output
export -f ssh_check_wp_cli
export -f ssh_get_db_size
export -f ssh_export_db
export -f ssh_get_wp_version
export -f ssh_get_site_url
export -f ssh_verify_wordpress
