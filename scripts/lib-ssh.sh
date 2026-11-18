#!/usr/bin/env bash
# lib-ssh.sh — SSH utility library for remote WordPress operations
# Execute commands on remote servers, manage database exports via SSH, handle authentication
#
# Usage:
#   source lib-ssh.sh
#   ssh_test_connection "user@host" "/var/www/html"
#   ssh_export_db "user@host" "/var/www/html" "local_file.sql"
#   ssh_get_db_size "user@host" "/var/www/html"

# These libraries use `declare -g` and associative arrays, which need Bash 4.2+.
# macOS ships Bash 3.2 as /bin/bash; stop with a clear message instead of
# failing later on a confusing syntax error.
if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
    echo "Error: ${BASH_SOURCE[0]##*/} needs Bash 4.2 or later; this is Bash ${BASH_VERSION}." >&2
    echo "On macOS: brew install bash, then run the script with that bash (or put it first on PATH)." >&2
    return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC2034
# SSH state
declare -g SSH_HOST=""
declare -g SSH_USER=""
declare -g SSH_PORT=22
declare -g SSH_KEY=""
declare -g SSH_KEY_TYPE=""
declare -g REMOTE_WP_PATH=""
declare -g SSH_TIMEOUT=30
# Optional known_hosts file holding the pinned keys for the intended hosts.
# When empty, ssh uses ~/.ssh/known_hosts. Either way an unknown or changed
# host key stops the connection; keys are never accepted automatically.
declare -g SSH_KNOWN_HOSTS="${SSH_KNOWN_HOSTS:-}"
declare -g -a SSH_CMD=()

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Remote paths and table names are interpolated into a command that the remote
# shell parses, so only allow characters that cannot change that command.
# Absolute path: letters, digits, dot, underscore, slash, plus and hyphen.
ssh_valid_remote_path() {
    [[ "$1" =~ ^/[A-Za-z0-9._/+-]*$ ]]
}

# MySQL table name as WordPress uses it: letters, digits, underscore, dollar
# and hyphen.
ssh_valid_table_name() {
    [[ "$1" =~ ^[A-Za-z0-9_$-]+$ ]]
}

# Print "cd <path>" with the configured remote path shell-quoted.
ssh_remote_cd() {
    printf 'cd %q' "$REMOTE_WP_PATH"
}

# Build the ssh command and its options in SSH_CMD.
# StrictHostKeyChecking=yes: ssh refuses a host whose key is not already in
# known_hosts, instead of trusting it on first use.
ssh_build_cmd() {
    SSH_CMD=(ssh)
    SSH_CMD+=(-o "ConnectTimeout=$SSH_TIMEOUT")
    SSH_CMD+=(-o StrictHostKeyChecking=yes)
    SSH_CMD+=(-p "$SSH_PORT")

    if [[ -n "$SSH_KNOWN_HOSTS" ]]; then
        SSH_CMD+=(-o "UserKnownHostsFile=$SSH_KNOWN_HOSTS")
    fi

    if [[ -n "$SSH_KEY" ]]; then
        SSH_CMD+=(-i "$SSH_KEY")
    fi
}

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

    if ! ssh_valid_remote_path "$wp_path"; then
        echo -e "${RED}Error: Remote WordPress path must be absolute and use only letters, digits, '.', '_', '/', '+' or '-': '$wp_path'${NC}" >&2
        return 1
    fi

    if [[ ! "$ssh_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: SSH port must be a number, got '$ssh_port'${NC}" >&2
        return 1
    fi

    if [[ -n "$SSH_KNOWN_HOSTS" ]] && [[ ! -f "$SSH_KNOWN_HOSTS" ]]; then
        echo -e "${RED}Error: SSH_KNOWN_HOSTS file not found: $SSH_KNOWN_HOSTS${NC}" >&2
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
    ssh_build_cmd
    local -a ssh_cmd=("${SSH_CMD[@]}")

    # Test connection, keeping ssh's own message to explain a failure
    local ssh_error
    if ! ssh_error=$("${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "exit 0" 2>&1 >/dev/null); then
        echo -e "${RED}❌ Failed to connect to $SSH_USER@$SSH_HOST:$SSH_PORT${NC}" >&2
        if [[ -n "$ssh_error" ]]; then
            printf '%s\n' "$ssh_error" | sed 's/^/  /' >&2
            if [[ "$ssh_error" == *"Host key verification failed"* ]]; then
                ssh_host_key_hint
            fi
        fi
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
    ssh_build_cmd
    local -a ssh_cmd=("${SSH_CMD[@]}")

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
    ssh_build_cmd
    local -a ssh_cmd=("${SSH_CMD[@]}")

    # Execute and capture output. stdout is the result the caller parses;
    # stderr (auth, DNS, host key, WP-CLI errors) goes to the caller's stderr
    # so the real cause of a failure stays visible.
    "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "$cmd"
}

# Check if WP-CLI is available on remote host
ssh_check_wp_cli() {
    local output
    output=$(ssh_exec_output "which wp")

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
    output=$(ssh_exec_output "$(ssh_remote_cd) && wp db size --format=bytes")

    if [[ -z "$output" ]] || [[ "$output" == *"Error"* ]]; then
        echo -e "${YELLOW}Note: Could not determine remote database size${NC}" >&2
        echo "0"
        return 0
    fi

    echo "$output"
}

# Explain what to do when ssh refuses an unknown or changed host key.
ssh_host_key_hint() {
    echo -e "${YELLOW}The host key for $SSH_HOST is not in known_hosts, or it changed.${NC}" >&2
    echo "  Keys are not accepted automatically. Get the host's fingerprint from its" >&2
    echo "  administrator or hosting panel, compare it with:" >&2
    echo "    ssh-keyscan -p $SSH_PORT $SSH_HOST | ssh-keygen -lf -" >&2
    echo "  and only when they match, add the key to ~/.ssh/known_hosts (or to the" >&2
    echo "  file named in SSH_KNOWN_HOSTS)." >&2
}

# Print what ssh or the remote command wrote to stderr, if anything.
ssh_report_stderr() {
    local err_file="$1"
    if [[ -s "$err_file" ]]; then
        echo -e "${YELLOW}ssh/WP-CLI said (full text in $err_file):${NC}" >&2
        sed 's/^/  /' "$err_file" >&2
        if grep -q 'Host key verification failed' "$err_file"; then
            ssh_host_key_hint
        fi
    fi
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
    local export_cmd
    export_cmd="$(ssh_remote_cd) && wp db export"

    # Add table exclusions if provided. WP-CLI takes one comma-separated
    # --exclude_tables option; every name is checked before it is used.
    if [[ -n "$exclude_tables" ]]; then
        local table
        local -a tables=()
        IFS=',' read -r -a tables <<< "$exclude_tables"
        for table in "${tables[@]}"; do
            if ! ssh_valid_table_name "$table"; then
                echo -e "${RED}Error: Invalid table name in exclusion list: '$table'${NC}" >&2
                return 1
            fi
        done
        local joined
        joined=$(IFS=','; echo "${tables[*]}")
        export_cmd="$export_cmd --exclude_tables=$joined"
    fi

    export_cmd="$export_cmd -"

    # Build SSH command
    ssh_build_cmd
    local -a ssh_cmd=("${SSH_CMD[@]}")

    # Execute remote export. Only stdout is the dump: ssh and WP-CLI
    # messages on stderr go to a separate file and never into the SQL.
    local err_file="${local_file}.err"
    if ! "${ssh_cmd[@]}" "$SSH_USER@$SSH_HOST" "$export_cmd" > "$local_file" 2> "$err_file"; then
        echo -e "${RED}❌ Database export failed${NC}" >&2
        ssh_report_stderr "$err_file"
        return 1
    fi

    # Verify file was created and has content
    if [[ ! -f "$local_file" ]] || [[ ! -s "$local_file" ]]; then
        echo -e "${RED}❌ Export file is empty or was not created${NC}" >&2
        ssh_report_stderr "$err_file"
        return 1
    fi

    # A mysqldump/mariadb-dump file starts with a comment ("-- MySQL dump",
    # "-- MariaDB dump" or a "/*M!...*/" line). Anything else is not a dump.
    local first_line
    first_line=$(grep -m 1 -v '^[[:space:]]*$' "$local_file" | head -c 200)
    if [[ ! "$first_line" =~ ^(--|/\*) ]]; then
        echo -e "${RED}❌ Export file does not look like an SQL dump. It starts with:${NC}" >&2
        echo "  $first_line" >&2
        ssh_report_stderr "$err_file"
        return 1
    fi

    if [[ -s "$err_file" ]]; then
        echo -e "${YELLOW}Messages from ssh/WP-CLI (kept out of the dump, saved to $err_file):${NC}" >&2
        sed 's/^/  /' "$err_file" >&2
    else
        rm -f "$err_file"
    fi

    local file_size
    file_size=$(du -h "$local_file" | cut -f1)

    echo -e "${GREEN}✓ Database exported to: $local_file ($file_size)${NC}"
    return 0
}

# Get remote WordPress version
ssh_get_wp_version() {
    local output
    output=$(ssh_exec_output "$(ssh_remote_cd) && wp core version")

    if [[ -z "$output" ]] || [[ "$output" == *"Error"* ]]; then
        echo "unknown"
        return 1
    fi

    echo "$output"
}

# Get remote site URL
ssh_get_site_url() {
    local output
    output=$(ssh_exec_output "$(ssh_remote_cd) && wp option get siteurl")

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
    wp_path_check=$(ssh_exec_output "test -f $(printf %q "$REMOTE_WP_PATH/wp-config.php") && echo 'found' || echo 'not found'")

    if [[ "$wp_path_check" != "found" ]]; then
        echo -e "${RED}❌ wp-config.php not found at $REMOTE_WP_PATH${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ WordPress installation verified${NC}"
    return 0
}

# Export functions
export -f ssh_valid_remote_path
export -f ssh_valid_table_name
export -f ssh_remote_cd
export -f ssh_build_cmd
export -f ssh_host_key_hint
export -f ssh_configure
export -f ssh_test_connection
export -f ssh_exec
export -f ssh_exec_output
export -f ssh_check_wp_cli
export -f ssh_get_db_size
export -f ssh_report_stderr
export -f ssh_export_db
export -f ssh_get_wp_version
export -f ssh_get_site_url
export -f ssh_verify_wordpress
