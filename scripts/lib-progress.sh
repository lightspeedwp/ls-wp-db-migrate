#!/bin/bash
# lib-progress.sh — Progress tracking and visual feedback library
# Provides progress bars, spinners, and stage tracking for long-running operations
#
# Usage:
#   source lib-progress.sh
#   progress_start "Importing database" 1000
#   progress_update 250
#   progress_complete "Import finished in 12s"
#   spinner_start "Validating..."
#   spinner_complete "Validation passed"
#   stage_start 1 "Export"
#   stage_complete

# shellcheck disable=SC2034
# Progress state
declare -g PROGRESS_LABEL=""
declare -g PROGRESS_TOTAL=0
declare -g PROGRESS_CURRENT=0
declare -g PROGRESS_START_TIME=0
declare -g SPINNER_PID=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Spinner frames
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
SPINNER_DELAY=0.1

# Initialize progress tracking
progress_start() {
    local label="$1"
    local total="${2:-0}"

    PROGRESS_LABEL="$label"
    PROGRESS_TOTAL="$total"
    PROGRESS_CURRENT=0
    PROGRESS_START_TIME=$(date +%s)

    if (( total > 0 )); then
        echo -e "${BLUE}📊 ${label}${NC}"
    fi
}

# Update progress bar (for operations with known total)
progress_update() {
    local current="$1"
    PROGRESS_CURRENT="$current"

    if (( PROGRESS_TOTAL == 0 )); then
        return 0
    fi

    local percent=$(( current * 100 / PROGRESS_TOTAL ))
    local filled=$(( percent / 5 ))
    local empty=$(( 20 - filled ))

    # Build progress bar
    local bar="["
    for (( i = 0; i < filled; i++ )); do
        bar+="█"
    done
    for (( i = 0; i < empty; i++ )); do
        bar+="░"
    done
    bar+="]"

    # Elapsed time
    local elapsed=$(( $(date +%s) - PROGRESS_START_TIME ))
    local elapsed_str="${elapsed}s"

    printf "\r%s %s %3d%% (%d/%d) %s" "$bar" "$(progress_spinner)" "$percent" "$current" "$PROGRESS_TOTAL" "$elapsed_str"
}

# Simple spinner for progress
progress_spinner() {
    local spinner_index=$(( (PROGRESS_CURRENT / 100) % 10 ))
    echo -n "${SPINNER_FRAMES[$spinner_index]}"
}

# Mark progress complete
progress_complete() {
    local message="${1:-Complete}"
    local elapsed=$(( $(date +%s) - PROGRESS_START_TIME ))

    echo ""
    echo -e "${GREEN}✓ ${PROGRESS_LABEL}: ${message} (${elapsed}s)${NC}"

    # Reset state
    PROGRESS_LABEL=""
    PROGRESS_TOTAL=0
    PROGRESS_CURRENT=0
}

# Mark progress failed
progress_fail() {
    local message="${1:-Failed}"
    local elapsed=$(( $(date +%s) - PROGRESS_START_TIME ))

    echo ""
    echo -e "${RED}❌ ${PROGRESS_LABEL}: ${message} (${elapsed}s)${NC}"

    # Reset state
    PROGRESS_LABEL=""
    PROGRESS_TOTAL=0
    PROGRESS_CURRENT=0
}

# Start animated spinner for indeterminate operations
spinner_start() {
    local message="$1"

    echo -ne "${BLUE}${SPINNER_FRAMES[0]} ${message}${NC}"

    # Run spinner in background
    (
        local i=1
        while true; do
            sleep "$SPINNER_DELAY"
            i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))
            echo -ne "\r${BLUE}${SPINNER_FRAMES[$i]} ${message}${NC}"
        done
    ) &
    SPINNER_PID=$!
}

# Complete spinner with success
spinner_complete() {
    local message="${1:-Done}"

    if (( SPINNER_PID > 0 )); then
        kill $SPINNER_PID 2>/dev/null || true
        SPINNER_PID=0
    fi

    echo -e "\r${GREEN}✓ ${message}${NC}"
}

# Complete spinner with failure
spinner_fail() {
    local message="${1:-Failed}"

    if (( SPINNER_PID > 0 )); then
        kill $SPINNER_PID 2>/dev/null || true
        SPINNER_PID=0
    fi

    echo -e "\r${RED}❌ ${message}${NC}"
}

# Show stage header
stage_start() {
    local stage_num="$1"
    local stage_label="$2"

    echo ""
    echo -e "${CYAN}╭──────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│ Stage $stage_num: ${stage_label}$(printf '%*s' $((35 - ${#stage_label})) '')│${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────╯${NC}"
}

# Show stage complete
stage_complete() {
    echo -e "${GREEN}✓ Stage complete${NC}"
}

# Show summary with timing
show_timing() {
    local start_time="$1"
    local label="${2:-Operation}"
    local elapsed=$(( $(date +%s) - start_time ))

    local minutes=$(( elapsed / 60 ))
    local seconds=$(( elapsed % 60 ))

    if (( minutes > 0 )); then
        echo -e "${GREEN}✓ ${label} completed in ${minutes}m ${seconds}s${NC}"
    else
        echo -e "${GREEN}✓ ${label} completed in ${seconds}s${NC}"
    fi
}

# Export functions for use in other scripts
export -f progress_start
export -f progress_update
export -f progress_complete
export -f progress_fail
export -f spinner_start
export -f spinner_complete
export -f spinner_fail
export -f stage_start
export -f stage_complete
export -f show_timing
