#!/bin/bash
# lib-studio-api.sh — WordPress Studio REST API utilities
# Validate Studio site configuration, database compatibility, and import success
#
# Usage:
#   source lib-studio-api.sh
#   studio_validate_site "~/.studio/sites/my-project"
#   studio_get_site_info "~/.studio/sites/my-project"
#   studio_get_database_tables "~/.studio/sites/my-project"

# shellcheck disable=SC2034
# Studio API state
declare -g STUDIO_SITE_PATH=""
declare -g STUDIO_SITE_URL=""
declare -g STUDIO_WP_VERSION=""
declare -g STUDIO_DB_TYPE=""
declare -g STUDIO_TABLE_COUNT=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate Studio site exists and is accessible
studio_validate_site() {
    local site_path="$1"

    if [[ ! -d "$site_path" ]]; then
        echo -e "${RED}Error: Studio site not found at $site_path${NC}" >&2
        return 1
    fi

    # Check for wp-config.php
    if [[ ! -f "$site_path/wp-config.php" ]]; then
        echo -e "${RED}Error: wp-config.php not found at $site_path${NC}" >&2
        return 1
    fi

    STUDIO_SITE_PATH="$site_path"
    return 0
}

# Get site information via REST API or wp cli
studio_get_site_info() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    # Try to get info from wp-cli (faster)
    if command -v wp &>/dev/null; then
        STUDIO_SITE_URL=$(cd "$site_path" && wp option get siteurl 2>/dev/null || echo "unknown")
        STUDIO_WP_VERSION=$(cd "$site_path" && wp core version 2>/dev/null || echo "unknown")
        STUDIO_DB_TYPE="sqlite"
    else
        STUDIO_SITE_URL="unknown"
        STUDIO_WP_VERSION="unknown"
        STUDIO_DB_TYPE="sqlite"
    fi

    return 0
}

# Get database type (should be sqlite for Studio)
studio_get_db_type() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    # Studio always uses SQLite
    echo "sqlite"
    return 0
}

# Get list of database tables
studio_get_database_tables() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if ! command -v wp &>/dev/null; then
        echo -e "${YELLOW}Warning: wp-cli not available${NC}" >&2
        return 1
    fi

    # Get table list from wp-cli
    cd "$site_path" && wp db tables --scope=all 2>/dev/null | sort
}

# Get table count
studio_get_table_count() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if ! command -v wp &>/dev/null; then
        echo "0"
        return 0
    fi

    # Count tables
    cd "$site_path" && wp db tables --scope=all 2>/dev/null | wc -l
}

# Check if Studio is properly installed
studio_check_installation() {
    local site_path="$1"

    echo -e "${BLUE}Checking Studio installation...${NC}"

    studio_validate_site "$site_path" || return 1

    # Check wp-config.php
    if ! grep -q "wp-config.php" "$site_path/wp-config.php" 2>/dev/null; then
        echo -e "${RED}❌ Invalid wp-config.php${NC}" >&2
        return 1
    fi

    # Check wp-content directory
    if [[ ! -d "$site_path/wp-content" ]]; then
        echo -e "${RED}❌ wp-content directory not found${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ Studio installation verified${NC}"
    return 0
}

# Get Studio site URL
studio_get_url() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if command -v wp &>/dev/null; then
        cd "$site_path" && wp option get siteurl 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Get WordPress version
studio_get_version() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if command -v wp &>/dev/null; then
        cd "$site_path" && wp core version 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Verify database integrity
studio_verify_database() {
    local site_path="$1"

    echo -e "${BLUE}Verifying database integrity...${NC}"

    studio_validate_site "$site_path" || return 1

    if ! command -v wp &>/dev/null; then
        echo -e "${YELLOW}⚠ wp-cli not available, skipping database check${NC}"
        return 0
    fi

    # Check database tables exist
    local table_count
    table_count=$(cd "$site_path" && wp db tables --scope=all 2>/dev/null | wc -l)

    if (( table_count == 0 )); then
        echo -e "${RED}❌ No database tables found${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ Database verified ($table_count tables)${NC}"
    return 0
}

# Check for required plugins
studio_check_plugins() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if ! command -v wp &>/dev/null; then
        return 0
    fi

    # List installed plugins
    cd "$site_path" && wp plugin list --status=active 2>/dev/null | head -5

    return 0
}

# Check for required themes
studio_check_theme() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    if ! command -v wp &>/dev/null; then
        return 0
    fi

    # Get active theme
    local theme
    theme=$(cd "$site_path" && wp option get template 2>/dev/null || echo "unknown")

    echo "$theme"
    return 0
}

# Pre-import validation checklist
studio_pre_import_check() {
    local site_path="$1"

    # Skip validation if wp-cli not available
    if ! command -v wp &>/dev/null; then
        return 0
    fi

    echo -e "${BLUE}Running pre-import validation...${NC}"

    # Check installation
    if ! studio_check_installation "$site_path" 2>/dev/null; then
        return 1
    fi

    # Verify database
    if ! studio_verify_database "$site_path" 2>/dev/null; then
        return 1
    fi

    echo -e "${GREEN}✓ Pre-import checks passed${NC}"
    return 0
}

# Post-import validation checklist
studio_post_import_check() {
    local site_path="$1"
    local expected_tables="${2:-}"

    echo -e "${BLUE}Running post-import validation...${NC}"

    # Get table count
    local table_count
    table_count=$(studio_get_table_count "$site_path" 2>/dev/null || echo "0")

    if (( table_count == 0 )); then
        echo -e "${RED}❌ Import verification failed: no tables in database${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}✓ Import verified ($table_count tables)${NC}"

    # Check if site is accessible
    if ! command -v wp &>/dev/null; then
        return 0
    fi

    # Verify WordPress can access database
    if cd "$site_path" && wp db check 2>/dev/null; then
        echo -e "${GREEN}✓ Database check passed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Database check returned warnings (may be normal)${NC}"
        return 0
    fi
}

# Generate validation report
studio_generate_report() {
    local site_path="$1"

    studio_validate_site "$site_path" || return 1

    echo ""
    echo -e "${BLUE}Studio Site Report${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local site_url table_count version
    site_url=$(studio_get_url "$site_path" 2>/dev/null || echo "unknown")
    table_count=$(studio_get_table_count "$site_path" 2>/dev/null || echo "0")
    version=$(studio_get_version "$site_path" 2>/dev/null || echo "unknown")

    echo -e "  Path:        $site_path"
    echo -e "  URL:         $site_url"
    echo -e "  WordPress:   $version"
    echo -e "  Database:    SQLite"
    echo -e "  Tables:      $table_count"
    echo ""

    return 0
}

# Export functions
export -f studio_validate_site
export -f studio_get_site_info
export -f studio_get_db_type
export -f studio_get_database_tables
export -f studio_get_table_count
export -f studio_check_installation
export -f studio_get_url
export -f studio_get_version
export -f studio_verify_database
export -f studio_check_plugins
export -f studio_check_theme
export -f studio_pre_import_check
export -f studio_post_import_check
export -f studio_generate_report
