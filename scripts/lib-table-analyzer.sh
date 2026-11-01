#!/bin/bash
# lib-table-analyzer.sh — Analyze tables and suggest exclusions
# Helps reduce migration time by identifying and excluding non-critical large tables
#
# Usage:
#   source lib-table-analyzer.sh
#   analyze_dump /path/to/dump.sql
#   suggest_exclusions  # Returns list of excludable tables

# Table patterns that are commonly safe to exclude
declare -A SAFE_EXCLUDES=(
    ["logs"]="wp_actionscheduler_logs wp_ewwwio_queue wp_rank_tracker_logs"
    ["cache"]="wp_cache wp_postmeta_cached"
    ["sessions"]="wp_session wp_login_attempts"
    ["queue"]="wp_queue wp_async_tasks"
    ["trash"]="wp_trash"
)

# Store analysis results
ANALYZED_TABLES=()
ANALYZED_SIZES=()
ANALYZED_ROWS=()
TOTAL_SIZE=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Analyze database dump and extract table information
analyze_dump() {
    local dump_file="$1"

    if [[ ! -f "$dump_file" ]]; then
        echo -e "${RED}Error: Dump file not found: $dump_file${NC}" >&2
        return 1
    fi

    # Extract CREATE TABLE statements and calculate sizes
    echo -e "${BLUE}Analyzing database structure...${NC}"

    local table_name
    local table_size
    local row_estimate

    while IFS= read -r line; do
        if [[ "$line" =~ ^CREATE\ TABLE\ \`\(.*\)\` ]]; then
            table_name=$(echo "$line" | sed -n "s/^CREATE TABLE \`\(.*\)\`.*/\1/p")
            ANALYZED_TABLES+=("$table_name")

            # Count rows in INSERT statements (rough estimate)
            row_estimate=$(grep -c "^INSERT INTO \`$table_name\`" "$dump_file" 2>/dev/null || echo "0")
            ANALYZED_ROWS+=("$row_estimate")

            # Estimate size (count characters of INSERT statements)
            table_size=$(grep "^INSERT INTO \`$table_name\`" "$dump_file" 2>/dev/null | wc -c || echo "0")
            ANALYZED_SIZES+=("$table_size")
            TOTAL_SIZE=$((TOTAL_SIZE + table_size))
        fi
    done < <(grep "^CREATE TABLE" "$dump_file")

    echo -e "${GREEN}✓ Analysis complete${NC}"
    return 0
}

# Format bytes as human-readable size
format_size() {
    local bytes=$1
    if (( bytes < 1024 )); then
        echo "${bytes}B"
    elif (( bytes < 1048576 )); then
        echo "$((bytes / 1024))KB"
    elif (( bytes < 1073741824 )); then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Show summary of tables
show_table_summary() {
    local count=${#ANALYZED_TABLES[@]}

    echo -e "\n${CYAN}Database Summary${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Total tables: ${BLUE}$count${NC}"
    echo -e "Total size:   ${BLUE}$(format_size $TOTAL_SIZE)${NC}"
    echo ""

    # Sort tables by size (descending)
    local -a indices=()
    while IFS= read -r i; do
        indices+=("$i")
    done < <(for idx in "${!ANALYZED_SIZES[@]}"; do
        echo "$idx:${ANALYZED_SIZES[$idx]}"
    done | sort -t: -k2 -rn | cut -d: -f1)

    echo -e "${CYAN}Top 10 Largest Tables${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Table Name${NC:<40} ${BLUE}Size${NC:<12} ${BLUE}Rows${NC:<8}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local shown=0
    for i in "${indices[@]}"; do
        if (( shown >= 10 )); then break; fi
        printf "%-40s %-12s %-8s\n" \
            "${ANALYZED_TABLES[$i]}" \
            "$(format_size "${ANALYZED_SIZES[$i]}")" \
            "${ANALYZED_ROWS[$i]}"
        ((shown++))
    done
}

# Suggest tables that can be safely excluded
suggest_exclusions() {
    local -a suggestions=()
    local total_excluded=0

    # Check each table against safe exclude patterns
    for table in "${ANALYZED_TABLES[@]}"; do
        for category in "${!SAFE_EXCLUDES[@]}"; do
            if [[ " ${SAFE_EXCLUDES[$category]} " =~ ${table} ]]; then
                suggestions+=("$table")

                # Find index and add to total
                for idx in "${!ANALYZED_TABLES[@]}"; do
                    if [[ "${ANALYZED_TABLES[$idx]}" == "$table" ]]; then
                        total_excluded=$((total_excluded + ${ANALYZED_SIZES[$idx]}))
                        break
                    fi
                done
                break
            fi
        done
    done

    if [[ ${#suggestions[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tables recommended for exclusion${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}Suggested Exclusions (Safe to Skip)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "%-40s %s\n" "Table" "Reason"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    for table in "${suggestions[@]}"; do
        local reason=""
        if [[ "$table" == *"actionscheduler_logs"* ]]; then
            reason="Action scheduler logs (safe to exclude)"
        elif [[ "$table" == *"logs"* ]]; then
            reason="Debug/activity logs (safe to exclude)"
        elif [[ "$table" == *"cache"* ]]; then
            reason="Cache tables (rebuilt on first load)"
        elif [[ "$table" == *"session"* ]]; then
            reason="Session data (temporary, can be reset)"
        elif [[ "$table" == *"queue"* ]]; then
            reason="Job queue (will re-queue on next run)"
        fi
        printf "%-40s %s\n" "$table" "$reason"
    done

    local reduction_percent=$((total_excluded * 100 / TOTAL_SIZE))
    echo -e "\n${GREEN}Potential size reduction: $(format_size $total_excluded) ($reduction_percent%)${NC}"

    # Output list for use in scripts
    printf '%s\n' "${suggestions[@]}"
}

# Build exclude flag for mysqldump
get_exclude_flags() {
    local -a excludes=("$@")
    local flags=""

    for table in "${excludes[@]}"; do
        flags="$flags --ignore-table=<database>.$table"
    done

    echo "$flags"
}

# Export functions
export -f analyze_dump
export -f format_size
export -f show_table_summary
export -f suggest_exclusions
export -f get_exclude_flags
