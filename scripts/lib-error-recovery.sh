#!/bin/bash
# lib-error-recovery.sh — Error recovery and rollback for WordPress database migration
# Provides automatic recovery on import failure, partial import handling, and crash recovery
#
# Exported functions:
#   recovery_init(studio_path)                 — Initialize recovery tracking
#   recovery_checkpoint(stage_name)            — Create checkpoint after each stage
#   recovery_detect_failure(exit_code, stage)  — Detect and classify failure
#   recovery_suggest_remediation(failure_type) — Suggest recovery options
#   recovery_rollback_partial(studio_path)     — Rollback partial import
#   recovery_restore_checkpoint(studio_path)   — Restore from checkpoint
#   recovery_generate_error_report(report_path) — Generate detailed error report
#
# Usage:
#   source "$SCRIPT_DIR/lib-error-recovery.sh"
#   recovery_init "$TO_PATH"
#   recovery_checkpoint "stage-1-export"
#   # ... run migration stages ...
#   if [[ $? -ne 0 ]]; then
#       recovery_detect_failure $? "import"
#       recovery_suggest_remediation "$FAILURE_TYPE"
#   fi

set -euo pipefail

# Recovery state (global variables at script scope)
# shellcheck disable=SC2034
RECOVERY_ENABLED=false
RECOVERY_PATH=""
FAILURE_TYPE=""
RECOVERY_LOG=""
CHECKPOINTS=()
LAST_CHECKPOINT=""

# Initialize recovery system
recovery_init() {
    local studio_path="$1"

    # shellcheck disable=SC2034
    RECOVERY_ENABLED=true
    RECOVERY_PATH="$studio_path/.recovery"
    RECOVERY_LOG="$RECOVERY_PATH/recovery.log"

    # Create recovery directory
    mkdir -p "$RECOVERY_PATH"
    chmod 700 "$RECOVERY_PATH"

    # Initialize log file
    echo "Recovery initialized at $(date)" > "$RECOVERY_LOG"
    echo "Studio path: $studio_path" >> "$RECOVERY_LOG"
}

# Create checkpoint after each stage
recovery_checkpoint() {
    local stage_name="$1"
    local checkpoint_file
    checkpoint_file="$RECOVERY_PATH/checkpoint-$stage_name-$(date +%s)"

    if [[ ! -d "$RECOVERY_PATH" ]]; then
        return 0
    fi

    # Record checkpoint metadata
    cat > "$checkpoint_file.meta" <<EOF
stage=$stage_name
timestamp=$(date +%s)
date=$(date)
EOF

    CHECKPOINTS+=("$stage_name")
    LAST_CHECKPOINT="$stage_name"

    echo "Checkpoint: $stage_name" >> "$RECOVERY_LOG"
}

# Detect and classify failure
recovery_detect_failure() {
    local exit_code="$1"
    local stage="$2"

    if [[ $exit_code -eq 0 ]]; then
        FAILURE_TYPE=""
        return 0
    fi

    # Classify failure by exit code and stage
    case "$stage" in
        "export")
            FAILURE_TYPE="export-failed"
            ;;
        "compress")
            FAILURE_TYPE="compression-failed"
            ;;
        "import")
            if grep -q "Table.*already exists" "$RECOVERY_LOG" 2>/dev/null; then
                FAILURE_TYPE="table-exists"
            elif grep -q "disk space" "$RECOVERY_LOG" 2>/dev/null; then
                FAILURE_TYPE="disk-full"
            elif grep -q "memory" "$RECOVERY_LOG" 2>/dev/null; then
                FAILURE_TYPE="out-of-memory"
            else
                FAILURE_TYPE="import-failed"
            fi
            ;;
        "validate")
            FAILURE_TYPE="validation-failed"
            ;;
        *)
            FAILURE_TYPE="unknown-failure"
            ;;
    esac

    if [[ -n "$RECOVERY_LOG" ]]; then
        echo "Failure detected: $FAILURE_TYPE (stage: $stage, exit: $exit_code)" >> "$RECOVERY_LOG"
    fi
}

# Suggest recovery options
recovery_suggest_remediation() {
    local failure_type="$1"

    case "$failure_type" in
        "export-failed")
            echo "❌ Export failed. Remediation:"
            echo "  1. Verify SSH connection: ssh -i KEY user@host 'echo ok'"
            echo "  2. Check if wp-cli is installed: ssh user@host 'wp --version'"
            echo "  3. Verify remote WordPress path exists: ssh user@host 'ls -la /path/to/wp-config.php'"
            echo "  4. Try reducing parallel jobs: --jobs 2"
            ;;
        "compression-failed")
            echo "❌ Compression failed. Remediation:"
            echo "  1. Check disk space: df -h"
            echo "  2. Try without compression: --no-compress"
            echo "  3. Verify temp directory is writable: ls -la /tmp"
            ;;
        "table-exists")
            echo "❌ Import failed: table already exists. Remediation:"
            echo "  1. Delete and recreate Studio site: studio delete <site> && studio create <site>"
            echo "  2. Retry migration: $0 --use-config"
            ;;
        "disk-full")
            echo "❌ Import failed: disk space full. Remediation:"
            echo "  1. Check available space: df -h"
            echo "  2. Need at least 3x database size (export + compressed + import)"
            echo "  3. Free up space or migrate to a system with more storage"
            ;;
        "out-of-memory")
            echo "❌ Import failed: out of memory. Remediation:"
            echo "  1. Reduce parallel jobs: --jobs 2"
            echo "  2. Close other applications to free memory"
            echo "  3. Try on a system with more RAM"
            ;;
        "import-failed")
            echo "❌ Import failed. Remediation:"
            echo "  1. Reduce parallel jobs: --jobs 2"
            echo "  2. Check database corruption: wp db check"
            echo "  3. Repair database if needed: wp db repair"
            echo "  4. Recreate Studio site and retry"
            ;;
        "validation-failed")
            echo "❌ Validation failed. Remediation:"
            echo "  1. Check database integrity: wp db check"
            echo "  2. Verify WordPress installation: wp core is-installed"
            echo "  3. Check for missing tables: wp db tables --format=count"
            ;;
        *)
            echo "❌ Migration failed. Remediation:"
            echo "  1. Check the log file: $RECOVERY_LOG"
            echo "  2. Try with reduced parallel jobs: --jobs 2"
            echo "  3. Try without compression: --no-compress"
            echo "  4. Recreate Studio site if needed: studio delete <site> && studio create <site>"
            ;;
    esac
}

# Rollback partial import
recovery_rollback_partial() {
    local studio_path="$1"

    if [[ ! -d "$studio_path" ]]; then
        echo "Studio path not found: $studio_path"
        return 1
    fi

    echo "Rolling back partial import..."

    # Drop all tables from partial import
    cd "$studio_path"
    wp db tables --format=csv | tr ',' '\n' | while read -r table; do
        if [[ -n "$table" && "$table" != "name" ]]; then
            wp db query "DROP TABLE IF EXISTS $table"
        fi
    done

    echo "✓ Partial import rolled back"
}

# Restore from checkpoint
recovery_restore_checkpoint() {
    local studio_path="$1"
    local checkpoint_stage="$2"

    if [[ ! -d "$RECOVERY_PATH" ]]; then
        echo "❌ No recovery checkpoints available"
        return 1
    fi

    echo "Restoring from checkpoint: $checkpoint_stage"

    # Find checkpoint file
    local checkpoint_file=""
    for cp in "$RECOVERY_PATH"/checkpoint-"$checkpoint_stage"-*; do
        if [[ -f "$cp.meta" ]]; then
            checkpoint_file="$cp"
            break
        fi
    done

    if [[ -z "$checkpoint_file" ]]; then
        echo "❌ Checkpoint not found: $checkpoint_stage"
        return 1
    fi

    # Restore would require saving checkpoint data (database dumps, exports)
    # For now, provide guidance
    echo "Checkpoint found: $checkpoint_file"
    echo "Manual restore:"
    echo "  1. Delete current Studio site: studio delete $studio_path"
    echo "  2. Recreate: studio create $studio_path"
    echo "  3. Retry migration from the checkpoint stage"

    return 0
}

# Generate detailed error report
recovery_generate_error_report() {
    local report_path="$1"
    local studio_path="${2:-.}"

    if [[ ! -d "$RECOVERY_PATH" ]]; then
        echo "❌ No recovery data available"
        return 1
    fi

    cat > "$report_path" <<EOF
# Migration Error Report
Generated: $(date)

## Summary
- Failure Type: ${FAILURE_TYPE:-unknown}
- Last Checkpoint: ${LAST_CHECKPOINT:-none}
- Checkpoints: ${#CHECKPOINTS[@]}

## Checkpoints
EOF

    for checkpoint in "${CHECKPOINTS[@]}"; do
        echo "  - $checkpoint" >> "$report_path"
    done

    cat >> "$report_path" <<EOF

## Recovery Log
EOF

    if [[ -f "$RECOVERY_LOG" ]]; then
        cat "$RECOVERY_LOG" >> "$report_path"
    fi

    cat >> "$report_path" <<EOF

## System Information
- Disk Space: $(df -h "$studio_path" | tail -1)
- Available Memory: $(free -h | grep Mem | awk '{print $7}')
- CPU Cores: $(nproc)

## Next Steps
See remediation suggestions above based on failure type.
EOF

    echo "✓ Error report generated: $report_path"
}

export -f recovery_init
export -f recovery_checkpoint
export -f recovery_detect_failure
export -f recovery_suggest_remediation
export -f recovery_rollback_partial
export -f recovery_restore_checkpoint
export -f recovery_generate_error_report
