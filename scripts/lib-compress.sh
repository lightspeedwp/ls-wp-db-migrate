#!/bin/bash
# lib-compress.sh — Handle compression/decompression with progress tracking
# Reduces file size by 70-80% for faster transfers
#
# Usage:
#   source lib-compress.sh
#   compress_file input.sql output.sql.gz
#   decompress_file input.sql.gz output.sql

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

# Calculate compression ratio
calc_ratio() {
    local original=$1
    local compressed=$2

    if (( original == 0 )); then
        echo "0%"
        return
    fi

    local ratio=$((100 - (compressed * 100 / original)))
    echo "$ratio%"
}

# Compress file with progress tracking
compress_file() {
    local input="$1"
    local output="$2"
    local verbose="${3:-false}"

    if [[ ! -f "$input" ]]; then
        echo -e "${RED}Error: Input file not found: $input${NC}" >&2
        return 1
    fi

    if [[ -z "$output" ]]; then
        echo -e "${RED}Error: Output file path required${NC}" >&2
        return 1
    fi

    # Check if gzip is available
    if ! command -v gzip &> /dev/null; then
        echo -e "${RED}Error: gzip not found${NC}" >&2
        return 1
    fi

    local input_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input" 2>/dev/null)

    echo -e "${BLUE}Compressing database...${NC}"
    echo -e "Input:  $(format_size $input_size)"

    # Compress with maximum compression (-9)
    gzip -9 < "$input" > "$output" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Compression failed${NC}" >&2
        rm -f "$output"
        return 1
    fi

    local output_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
    local ratio=$(calc_ratio "$input_size" "$output_size")

    echo -e "Output: $(format_size $output_size)"
    echo -e "Ratio:  ${GREEN}$ratio smaller${NC}"
    echo -e "${GREEN}✓ Compression complete${NC}"

    return 0
}

# Decompress file with progress tracking
decompress_file() {
    local input="$1"
    local output="$2"
    local verbose="${3:-false}"

    if [[ ! -f "$input" ]]; then
        echo -e "${RED}Error: Input file not found: $input${NC}" >&2
        return 1
    fi

    if [[ -z "$output" ]]; then
        echo -e "${RED}Error: Output file path required${NC}" >&2
        return 1
    fi

    # Check if file is gzip compressed
    if ! file "$input" | grep -q "gzip compressed"; then
        echo -e "${YELLOW}Warning: File doesn't appear to be gzip compressed${NC}"
    fi

    local input_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input" 2>/dev/null)

    echo -e "${BLUE}Decompressing database...${NC}"
    echo -e "Input:  $(format_size $input_size)"

    # Decompress
    gzip -d < "$input" > "$output" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Decompression failed${NC}" >&2
        rm -f "$output"
        return 1
    fi

    local output_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null)
    local ratio=$(calc_ratio "$output_size" "$input_size")

    echo -e "Output: $(format_size $output_size)"
    echo -e "Expansion: ${GREEN}$ratio${NC}"
    echo -e "${GREEN}✓ Decompression complete${NC}"

    return 0
}

# Check if a file is compressed
is_compressed() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    file "$file" | grep -q "gzip compressed"
    return $?
}

# Auto-detect and decompress if needed
auto_decompress() {
    local input="$1"
    local output="$2"

    if is_compressed "$input"; then
        decompress_file "$input" "$output"
    else
        # Just copy if not compressed
        cp "$input" "$output"
    fi
}

# Get compression savings estimate (for planning)
estimate_compression() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: File not found: $file${NC}" >&2
        return 1
    fi

    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)

    # Average SQL dumps compress at 70-80%
    local compressed_estimate=$((size / 4))  # ~75% reduction
    local time_saved_seconds=$((size / 1048576 / 20))  # Estimate 20MB/s transfer

    echo -e "${CYAN}Compression Estimate${NC}"
    echo -e "Original size:     $(format_size $size)"
    echo -e "Compressed (~75%): $(format_size $compressed_estimate)"
    echo -e "Savings:           $(format_size $((size - compressed_estimate)))"

    if (( time_saved_seconds > 60 )); then
        echo -e "Transfer time saved: ~$((time_saved_seconds / 60)) minutes"
    else
        echo -e "Transfer time saved: ~${time_saved_seconds}s"
    fi
}

# Export functions
export -f format_size
export -f calc_ratio
export -f compress_file
export -f decompress_file
export -f is_compressed
export -f auto_decompress
export -f estimate_compression
