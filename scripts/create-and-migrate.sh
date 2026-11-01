#!/bin/bash
# create-and-migrate.sh
# Automatically creates a WordPress Studio site and migrates database
# Usage: ./create-and-migrate.sh <site-name> <export-file> <old-url> [new-url]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_NAME="${1:-}"
EXPORT_FILE="${2:-}"
OLD_URL="${3:-}"
NEW_URL="${4:-}"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Show usage
show_usage() {
    cat << 'EOF'
WordPress Studio Auto-Create & Migrate

USAGE:
  ./create-and-migrate.sh <site-name> <export-file> <old-url> [new-url]

ARGUMENTS:
  site-name      Name for the new Studio site
  export-file    Path to SQL export (.sql, .sql.gz, .sql.zip)
  old-url        Current site URL (e.g., staging.example.com)
  new-url        New site URL (default: <site-name>.local)

EXAMPLES:
  # Create 'my-staging' site with production backup
  ./create-and-migrate.sh my-staging backup.sql.gz prod.example.com staging.local

  # Create 'dev-site' with auto-generated local URL
  ./create-and-migrate.sh dev-site export.sql.gz old-site.com
  # Creates: dev-site.local

OPTIONS:
  --dry-run      Preview only, don't make changes
  --verbose      Detailed output
  --no-start     Create and migrate, but don't start server
EOF
}

# Parse optional flags
DRY_RUN=false
VERBOSE=false
START_SERVER=true

while [[ "$1" == --* ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        --no-start) START_SERVER=false; shift ;;
        --help) show_usage; exit 0 ;;
        *) echo "Unknown option: $1"; show_usage; exit 1 ;;
    esac
done

# Validate required arguments
if [ -z "$SITE_NAME" ] || [ -z "$EXPORT_FILE" ] || [ -z "$OLD_URL" ]; then
    echo -e "${RED}❌ Missing required arguments${NC}"
    echo ""
    show_usage
    exit 1
fi

# Set default new URL
if [ -z "$NEW_URL" ]; then
    NEW_URL="${SITE_NAME}.local"
fi

# Verify export file exists
if [ ! -f "$EXPORT_FILE" ]; then
    echo -e "${RED}❌ Export file not found: $EXPORT_FILE${NC}"
    exit 1
fi

# Get absolute path
EXPORT_FILE="$(cd "$(dirname "$EXPORT_FILE")" && pwd)/$(basename "$EXPORT_FILE")"

# Verify Studio CLI is available
if ! command -v studio &> /dev/null; then
    echo -e "${RED}❌ WordPress Studio CLI not found${NC}"
    echo "Install from: https://developer.wordpress.com/docs/developer-tools/studio/cli/"
    exit 1
fi

# Function to log messages
log() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

# Show summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  WordPress Studio Auto-Create & Migrate  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo "Site Name:    $SITE_NAME"
echo "Export File:  $EXPORT_FILE"
echo "Old URL:      $OLD_URL"
echo "New URL:      $NEW_URL"
echo "Dry Run:      $([ "$DRY_RUN" = true ] && echo "Yes" || echo "No")"
echo ""

if [ "$DRY_RUN" = true ]; then
    log_warning "Running in DRY-RUN mode (no changes will be made)"
    echo ""
fi

# Step 1: Create Studio site
log "Creating WordPress Studio site..."

if [ "$DRY_RUN" = true ]; then
    log "   [DRY-RUN] Would run: studio create \"$SITE_NAME\" --type wordpress"
    SITE_PATH="$HOME/Studio/$SITE_NAME"
else
    # Create the site with Studio CLI
    if studio create "$SITE_NAME" --type wordpress; then
        log_success "Site created: $SITE_NAME"
    else
        log_error "Failed to create Studio site"
        exit 1
    fi

    SITE_PATH="$HOME/Studio/$SITE_NAME"
fi

echo ""

# Verify site path
if [ ! -d "$SITE_PATH" ] && [ "$DRY_RUN" = false ]; then
    log_error "Site directory not found at: $SITE_PATH"
    exit 1
fi

log_success "Site path: $SITE_PATH"
echo ""

# Step 2: Run migration
log "Starting database migration..."
echo ""

MIGRATE_SCRIPT="$SCRIPT_DIR/migrate-recovery-enhanced.sh"

if [ ! -f "$MIGRATE_SCRIPT" ]; then
    log_error "Migration script not found: $MIGRATE_SCRIPT"
    exit 1
fi

# Build migration command
MIGRATE_ARGS=("$SITE_PATH" "$OLD_URL" "$NEW_URL")

if [ "$DRY_RUN" = true ]; then
    MIGRATE_ARGS=("--dry-run" "${MIGRATE_ARGS[@]}")
fi

if [ "$VERBOSE" = true ]; then
    MIGRATE_ARGS=("--verbose" "${MIGRATE_ARGS[@]}")
fi

# Run migration
if [ "$DRY_RUN" = true ]; then
    log "   [DRY-RUN] Would run: migrate-recovery-enhanced.sh ${MIGRATE_ARGS[*]}"
    echo ""
else
    bash "$MIGRATE_SCRIPT" "${MIGRATE_ARGS[@]}"

    if [ $? -ne 0 ]; then
        log_error "Migration failed"
        exit 1
    fi
fi

echo ""

# Step 3: Start server (optional)
if [ "$START_SERVER" = true ] && [ "$DRY_RUN" = false ]; then
    log "Starting WordPress server..."
    echo ""

    START_SCRIPT="$SCRIPT_DIR/start-server.sh"
    bash "$START_SCRIPT" "$SITE_PATH"
fi

# Final summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Setup Complete! ✅             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    log_warning "DRY-RUN complete. No changes were made."
    echo ""
    echo "To proceed with the actual migration, run:"
    echo "  $0 $SITE_NAME $EXPORT_FILE $OLD_URL $NEW_URL"
else
    log_success "Site created and database migrated"
    echo ""
    echo "Your site is ready:"
    echo "  URL:  https://$NEW_URL"
    echo "  Path: $SITE_PATH"
    echo ""
    echo "To stop the server:"
    echo "  studio stop \"$SITE_NAME\""
fi

echo ""
