#!/bin/bash
# lib-reports.sh — Reports and analytics for WordPress database migration
# Generates migration statistics, performance logs, and audit trails
#
# Exported functions:
#   reports_init(report_dir)                   — Initialize reporting
#   reports_log_metric(name, value, unit)      — Log a metric
#   reports_log_stage(stage, duration, status) — Log stage completion
#   reports_track_table(table, rows, size)     — Track table statistics
#   reports_calculate_stats()                  — Calculate aggregate statistics
#   reports_export_json(output_file)           — Export metrics as JSON
#   reports_export_summary(output_file)        — Export human-readable summary
#   reports_export_csv(output_file)            — Export table statistics as CSV
#
# Usage:
#   source "$SCRIPT_DIR/lib-reports.sh"
#   reports_init "/path/to/reports"
#   reports_log_stage "export" 120 "success"
#   reports_track_table "wp_posts" 1000 5242880

set -euo pipefail

# Report state (global variables at script scope)
REPORTS_ENABLED=false
REPORTS_DIR=""
MIGRATION_START_TIME=""
MIGRATION_END_TIME=""
STAGES=()
declare -A STAGE_DURATIONS=()
declare -A STAGE_STATUS=()
TABLES=()
declare -A TABLE_ROWS=()
declare -A TABLE_SIZE=()
declare -A METRICS=()
declare -A METRIC_UNITS=()

# Initialize reporting
reports_init() {
    local report_dir="$1"

    REPORTS_ENABLED=true
    REPORTS_DIR="$report_dir"
    MIGRATION_START_TIME=$(date +%s)

    # Create reports directory
    mkdir -p "$REPORTS_DIR"

    # Initialize metadata file
    cat > "$REPORTS_DIR/migration.meta" <<EOF
start_time=$(date)
start_timestamp=$MIGRATION_START_TIME
host=$(hostname)
user=$(whoami)
EOF
}

# Log a metric
reports_log_metric() {
    local name="$1"
    local value="$2"
    local unit="${3:-}"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    METRICS["$name"]="$value"
    if [[ -n "$unit" ]]; then
        METRIC_UNITS["$name"]="$unit"
    fi
}

# Log stage completion
reports_log_stage() {
    local stage="$1"
    local duration="$2"
    local status="$3"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    STAGES+=("$stage")
    STAGE_DURATIONS["$stage"]="$duration"
    STAGE_STATUS["$stage"]="$status"
}

# Track table statistics
reports_track_table() {
    local table="$1"
    local rows="$2"
    local size="$3"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    TABLES+=("$table")
    TABLE_ROWS["$table"]="$rows"
    TABLE_SIZE["$table"]="$size"
}

# Calculate aggregate statistics
reports_calculate_stats() {
    local -i total_tables=0
    local -i total_rows=0
    local -i total_size=0
    local -i total_duration=0

    # Calculate totals
    for table in "${TABLES[@]}"; do
        total_tables=$((total_tables + 1))
        total_rows=$((total_rows + TABLE_ROWS["$table"]))
        total_size=$((total_size + TABLE_SIZE["$table"]))
    done

    for stage in "${STAGES[@]}"; do
        total_duration=$((total_duration + STAGE_DURATIONS["$stage"]))
    done

    # Calculate derived metrics
    local compression_ratio=0
    if [[ -n "${METRICS[compressed_size]:-}" && -n "${METRICS[original_size]:-}" ]]; then
        compression_ratio=$(awk "BEGIN {printf \"%.1f\", (1 - ${METRICS[compressed_size]:-0} / ${METRICS[original_size]:-1}) * 100}")
    fi

    local import_throughput=0
    if [[ ${METRICS[original_size]:-0} -gt 0 && ${STAGE_DURATIONS[import]:-0} -gt 0 ]]; then
        import_throughput=$(awk "BEGIN {printf \"%.2f\", ${METRICS[original_size]:-0} / ${STAGE_DURATIONS[import]:-1} / 1048576}")
    fi

    # Log calculated metrics
    reports_log_metric "total_tables" "$total_tables" "count"
    reports_log_metric "total_rows" "$total_rows" "rows"
    reports_log_metric "total_size" "$total_size" "bytes"
    reports_log_metric "total_duration" "$total_duration" "seconds"
    reports_log_metric "compression_ratio" "$compression_ratio" "%"
    reports_log_metric "import_throughput" "$import_throughput" "MB/s"
}

# Format bytes to human-readable
_format_bytes() {
    local bytes="$1"

    if ((bytes == 0)); then
        echo "0 B"
        return
    fi

    local units=("B" "KB" "MB" "GB")
    local size="$bytes"
    local unit_idx=0

    while ((size > 1024 && unit_idx < 3)); do
        ((size /= 1024))
        ((unit_idx++))
    done

    echo "$size ${units[$unit_idx]}"
}

# Export metrics as JSON
reports_export_json() {
    local output_file="$1"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    MIGRATION_END_TIME=$(date +%s)
    local elapsed=$((MIGRATION_END_TIME - MIGRATION_START_TIME))

    cat > "$output_file" <<'EOF'
{
  "migration": {
    "start_time": "PLACEHOLDER_START",
    "end_time": "PLACEHOLDER_END",
    "duration_seconds": PLACEHOLDER_DURATION
  },
  "stages": {
EOF

    local first=true
    for stage in "${STAGES[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$output_file"
        fi
        printf '    "%s": {"duration": %d, "status": "%s"}' "$stage" "${STAGE_DURATIONS[$stage]}" "${STAGE_STATUS[$stage]}" >> "$output_file"
    done

    cat >> "$output_file" <<EOF
  },
  "tables": {
EOF

    first=true
    for table in "${TABLES[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$output_file"
        fi
        printf '    "%s": {"rows": %d, "size": %d}' "$table" "${TABLE_ROWS[$table]}" "${TABLE_SIZE[$table]}" >> "$output_file"
    done

    cat >> "$output_file" <<EOF
  },
  "metrics": {
EOF

    first=true
    for metric in "${!METRICS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo "," >> "$output_file"
        fi
        local unit="${METRIC_UNITS[$metric]:-}"
        printf '    "%s": {"value": %s, "unit": "%s"}' "$metric" "${METRICS[$metric]}" "$unit" >> "$output_file"
    done

    cat >> "$output_file" <<EOF
  }
}
EOF

    # Replace placeholders
    sed -i '' "s|PLACEHOLDER_START|$(date -u +%Y-%m-%dT%H:%M:%SZ)|g" "$output_file"
    sed -i '' "s|PLACEHOLDER_END|$(date -u +%Y-%m-%dT%H:%M:%SZ)|g" "$output_file"
    sed -i '' "s|PLACEHOLDER_DURATION|$elapsed|g" "$output_file"
}

# Export human-readable summary
reports_export_summary() {
    local output_file="$1"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    MIGRATION_END_TIME=$(date +%s)
    local elapsed=$((MIGRATION_END_TIME - MIGRATION_START_TIME))

    {
        echo "# WordPress Database Migration Report"
        echo ""
        echo "**Migration Date:** $(date)"
        echo ""

        # Execution summary
        echo "## Execution Summary"
        echo ""
        echo "| Metric | Value |"
        echo "|--------|-------|"
        echo "| Total Duration | ${elapsed}s |"
        echo "| Total Tables | ${#TABLES[@]} |"
        echo "| Total Rows | $(printf '%d\n' "${TABLE_ROWS[@]}" | awk '{sum+=$1} END {print sum}') |"
        echo ""

        # Stage breakdown
        echo "## Stage Breakdown"
        echo ""
        echo "| Stage | Duration | Status |"
        echo "|-------|----------|--------|"
        for stage in "${STAGES[@]}"; do
            echo "| $stage | ${STAGE_DURATIONS[$stage]}s | ${STAGE_STATUS[$stage]} |"
        done
        echo ""

        # Performance metrics
        echo "## Performance Metrics"
        echo ""
        echo "| Metric | Value |"
        echo "|--------|-------|"
        for metric in "${!METRICS[@]}"; do
            local unit="${METRIC_UNITS[$metric]:-}"
            echo "| $metric | ${METRICS[$metric]} $unit |"
        done
        echo ""

        # Table statistics
        echo "## Table Statistics"
        echo ""
        echo "| Table | Rows | Size |"
        echo "|-------|------|------|"
        for table in "${TABLES[@]}"; do
            local formatted_size
            formatted_size=$(_format_bytes "${TABLE_SIZE[$table]}")
            echo "| $table | ${TABLE_ROWS[$table]} | $formatted_size |"
        done
        echo ""

    } > "$output_file"
}

# Export table statistics as CSV
reports_export_csv() {
    local output_file="$1"

    if [[ ! $REPORTS_ENABLED ]]; then
        return 0
    fi

    {
        echo "table,rows,size_bytes,size_mb"
        for table in "${TABLES[@]}"; do
            local size_mb
            size_mb=$(awk "BEGIN {printf \"%.2f\", ${TABLE_SIZE[$table]} / 1048576}")
            echo "$table,${TABLE_ROWS[$table]},${TABLE_SIZE[$table]},$size_mb"
        done
    } > "$output_file"
}

export -f reports_init
export -f reports_log_metric
export -f reports_log_stage
export -f reports_track_table
export -f reports_calculate_stats
export -f reports_export_json
export -f reports_export_summary
export -f reports_export_csv
