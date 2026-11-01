#!/bin/bash
# lib-parallel.sh — Parallel table import/processing
# Import multiple tables concurrently for 3-5x speedup
#
# Usage:
#   source lib-parallel.sh
#   parallel_import tables.txt dump.sql site_path

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Number of concurrent processes (auto-detect CPU count)
PARALLEL_JOBS=${PARALLEL_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}

# Cap at 10 to avoid overwhelming the system
if (( PARALLEL_JOBS > 10 )); then
    PARALLEL_JOBS=10
fi

# Temp directory for parallel work
PARALLEL_TMPDIR=$(mktemp -d)
trap 'rm -rf "$PARALLEL_TMPDIR"' EXIT

# Counter for progress tracking
TABLES_PROCESSED=0
TABLES_FAILED=0

# Extract a single table from SQL dump
extract_table() {
    local table_name="$1"
    local dump_file="$2"
    local output_file="$3"

    # Extract CREATE TABLE and INSERT statements for this table
    (
        grep "^CREATE TABLE.*\`$table_name\`" "$dump_file"
        grep "^INSERT INTO \`$table_name\`" "$dump_file" || true
    ) > "$output_file"

    return $?
}

# Import a single table into SQLite
import_single_table() {
    local table_sql="$1"
    local site_path="$2"
    local table_name="$3"

    local db_path="$site_path/wp-content/database/.sqlite-wal"

    if [[ ! -f "$db_path" ]]; then
        echo -e "${RED}Error: SQLite database not found at $db_path${NC}" >&2
        return 1
    fi

    # Import using sqlite3
    if sqlite3 "$db_path" < "$table_sql" 2>/dev/null; then
        ((TABLES_PROCESSED++))
        return 0
    else
        ((TABLES_FAILED++))
        echo -e "${RED}Failed to import table: $table_name${NC}" >&2
        return 1
    fi
}

# Wait for background jobs with progress tracking
wait_jobs() {
    local -a pids=("$@")
    local total=${#pids[@]}
    local completed=0

    while (( completed < total )); do
        completed=0
        for pid in "${pids[@]}"; do
            if ! kill -0 "$pid" 2>/dev/null; then
                ((completed++))
            fi
        done

        if (( completed < total )); then
            printf "\rProcessing tables... %d/%d complete" "$completed" "$total"
            sleep 0.5
        fi
    done

    printf "\n✓ All tables imported\n"
}

# Main parallel import function
parallel_import() {
    local dump_file="$1"
    local site_path="$2"
    local max_jobs="${3:-$PARALLEL_JOBS}"

    if [[ ! -f "$dump_file" ]]; then
        echo -e "${RED}Error: Dump file not found: $dump_file${NC}" >&2
        return 1
    fi

    if [[ ! -d "$site_path" ]]; then
        echo -e "${RED}Error: Site path not found: $site_path${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Extracting table list...${NC}"

    # Extract table names
    local -a tables=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^CREATE\ TABLE ]]; then
            table_name=$(echo "$line" | sed -n "s/^CREATE TABLE \`\(.*\)\`.*/\1/p")
            if [[ -n "$table_name" ]]; then
                tables+=("$table_name")
            fi
        fi
    done < <(grep "^CREATE TABLE" "$dump_file")

    local total_tables=${#tables[@]}
    echo -e "${CYAN}Found $total_tables tables${NC}"
    echo -e "${BLUE}Importing with $max_jobs concurrent processes...${NC}"

    local -a pids=()
    local active_jobs=0

    for table in "${tables[@]}"; do
        # Wait if we've reached max concurrent jobs
        while (( active_jobs >= max_jobs )); do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset "pids[$i]"
                    ((active_jobs--))
                fi
            done
            sleep 0.1
        done

        # Extract table to temp file
        local table_file="$PARALLEL_TMPDIR/$table.sql"
        extract_table "$table" "$dump_file" "$table_file"

        # Import in background
        {
            import_single_table "$table_file" "$site_path" "$table"
            rm -f "$table_file"
        } &

        pids+=($!)
        ((active_jobs++))

        # Progress indicator
        printf "\rLaunching imports... %d/%d" "$((${#pids[@]}))" "$total_tables"
    done

    printf "\n"

    # Wait for all background jobs
    wait "${pids[@]}"

    echo -e "${GREEN}✓ Parallel import complete${NC}"
    echo -e "${CYAN}Tables processed: $TABLES_PROCESSED${NC}"

    if (( TABLES_FAILED > 0 )); then
        echo -e "${YELLOW}Failed tables: $TABLES_FAILED${NC}"
        return 1
    fi

    return 0
}

# Sequential import (fallback if parallel fails)
sequential_import() {
    local dump_file="$1"
    local site_path="$2"

    if [[ ! -f "$dump_file" ]]; then
        echo -e "${RED}Error: Dump file not found: $dump_file${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Running sequential import...${NC}"

    local db_path="$site_path/wp-content/database/.sqlite-wal"

    if [[ ! -f "$db_path" ]]; then
        echo -e "${RED}Error: SQLite database not found at $db_path${NC}" >&2
        return 1
    fi

    # Simple sequential import
    if sqlite3 "$db_path" < "$dump_file" 2>/dev/null; then
        echo -e "${GREEN}✓ Sequential import complete${NC}"
        return 0
    else
        echo -e "${RED}Error: Sequential import failed${NC}" >&2
        return 1
    fi
}

# Get optimal job count
get_optimal_jobs() {
    # Use half of available CPUs to avoid system overload
    local cpu_count
    cpu_count=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)
    local optimal=$((cpu_count / 2))

    # Minimum 2, maximum 10
    if (( optimal < 2 )); then optimal=2; fi
    if (( optimal > 10 )); then optimal=10; fi

    echo "$optimal"
}

# Export functions
export -f extract_table
export -f import_single_table
export -f wait_jobs
export -f parallel_import
export -f sequential_import
export -f get_optimal_jobs

# Export variables
export PARALLEL_JOBS
export PARALLEL_TMPDIR
