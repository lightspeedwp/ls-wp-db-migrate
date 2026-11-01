#!/bin/bash

# WordPress Database Migration - Dependency Verification Script
# Verifies all required and optional dependencies for wp-db-migrate
# Usage: ./setup-dependencies.sh [--install] [--verbose]

set -e

INSTALL_MODE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
REQUIRED_FOUND=0
REQUIRED_MISSING=0
OPTIONAL_FOUND=0
OPTIONAL_MISSING=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --install)
      INSTALL_MODE=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "WordPress Database Migration - Dependency Setup"
      echo ""
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --install    Install missing dependencies via Homebrew"
      echo "  --verbose    Show detailed output"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  WordPress Database Migration - Dependency Check      ║${NC}"
echo -e "${BLUE}║  Version 1.1.0                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check if command exists
check_command() {
  local cmd=$1
  local name=$2
  local required=$3

  if command -v "$cmd" &> /dev/null; then
    local version
    version=$("$cmd" --version 2>/dev/null || echo "installed")
    echo -e "${GREEN}✓${NC} $name"
    [[ $VERBOSE == true ]] && echo "  └─ $(echo "$version" | head -1)"
    if [[ $required == "true" ]]; then
      ((REQUIRED_FOUND++))
    else
      ((OPTIONAL_FOUND++))
    fi
    return 0
  else
    if [[ $required == "true" ]]; then
      echo -e "${RED}✗${NC} $name ${RED}(REQUIRED)${NC}"
      ((REQUIRED_MISSING++))
    else
      echo -e "${YELLOW}○${NC} $name ${YELLOW}(optional)${NC}"
      ((OPTIONAL_MISSING++))
    fi
    return 1
  fi
}

# Function to install package via Homebrew
install_package() {
  local package=$1
  local name=$2

  if [[ $INSTALL_MODE == true ]]; then
    echo -e "${BLUE}Installing${NC} $name..."
    if brew install "$package"; then
      echo -e "${GREEN}✓ Installed${NC} $name"
      return 0
    else
      echo -e "${RED}✗ Failed to install${NC} $name"
      return 1
    fi
  fi
}

# Section 1: Required Core Dependencies
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Required Core Dependencies${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

check_command "bash" "Bash Shell (3.0+)" "true" || install_package "bash" "Bash Shell"
check_command "gzip" "Gzip (compression)" "true" || install_package "gzip" "Gzip"
check_command "git" "Git (version control)" "true" || install_package "git" "Git"

echo ""

# Section 2: WordPress Studio (Required for import)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}WordPress Studio (Required)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

if [[ -d "$HOME/Library/Application Support/WordPress Studio" ]] || command -v studio &>/dev/null; then
  echo -e "${GREEN}✓${NC} WordPress Studio"
  ((REQUIRED_FOUND++))
else
  echo -e "${RED}✗${NC} WordPress Studio ${RED}(REQUIRED)${NC}"
  echo -e "  ${YELLOW}Install from:${NC} https://developer.wordpress.com/studio/"
  ((REQUIRED_MISSING++))
fi

echo ""

# Section 3: WordPress CLI (Required for database operations)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}WordPress CLI (Required for database operations)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

check_command "wp" "WP-CLI" "true" || install_package "wp-cli" "WP-CLI"

echo ""

# Section 4: SSH & Remote Access (Required for SSH export)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}SSH & Remote Access${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

check_command "ssh" "SSH Client" "true"
check_command "ssh-keygen" "SSH Key Generation" "true"
check_command "ssh-copy-id" "SSH Key Installation" "false"

echo ""

# Section 5: Database Tools (Optional but recommended)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Database Tools (Optional but Recommended)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

check_command "mysql" "MySQL Client" "false" || install_package "mysql-client" "MySQL Client"
check_command "sqlite3" "SQLite3 CLI" "false" || install_package "sqlite" "SQLite3"

echo ""

# Section 6: Developer Tools (Required for this project)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Developer Tools (Required for Testing & Development)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

check_command "node" "Node.js" "true" || install_package "node" "Node.js"
check_command "npm" "NPM (Node Package Manager)" "true"
check_command "shellcheck" "ShellCheck (shell linting)" "false" || install_package "shellcheck" "ShellCheck"

echo ""

# Section 7: Code Editors (Recommended)
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Code Editors & IDEs (Recommended)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

if [[ -d "/Applications/Visual Studio Code.app" ]] || command -v code &>/dev/null; then
  echo -e "${GREEN}✓${NC} Visual Studio Code"
  ((OPTIONAL_FOUND++))
else
  echo -e "${YELLOW}○${NC} Visual Studio Code ${YELLOW}(optional)${NC}"
  ((OPTIONAL_MISSING++))
fi

echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"

echo -e "Required Dependencies:  ${GREEN}$REQUIRED_FOUND found${NC}, ${RED}$REQUIRED_MISSING missing${NC}"
echo -e "Optional Dependencies:  ${GREEN}$OPTIONAL_FOUND found${NC}, ${YELLOW}$OPTIONAL_MISSING missing${NC}"

echo ""

if [[ $REQUIRED_MISSING -eq 0 ]]; then
  echo -e "${GREEN}✓ All required dependencies are installed!${NC}"
  echo ""
  echo -e "${YELLOW}Next steps:${NC}"
  echo "1. Run: cd ~/.claude/skills/wp-db-migrate"
  echo "2. Run: npm install"
  echo "3. Run: ./skill/scripts/preflight-check.sh"
  echo "4. Test with: ./skill/scripts/migrate-recovery.sh --help"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Missing $REQUIRED_MISSING required dependencies!${NC}"
  echo ""

  if [[ $INSTALL_MODE == false ]]; then
    echo -e "${YELLOW}To install missing dependencies:${NC}"
    echo "  $0 --install"
    echo ""
    echo -e "${YELLOW}Or install manually:${NC}"
    if ! command -v bash &>/dev/null; then
      echo "  brew install bash"
    fi
    if ! command -v gzip &>/dev/null; then
      echo "  brew install gzip"
    fi
    if ! command -v git &>/dev/null; then
      echo "  brew install git"
    fi
    if ! command -v wp &>/dev/null; then
      echo "  brew install wp-cli"
    fi
    if ! command -v node &>/dev/null; then
      echo "  brew install node"
    fi
    echo ""
    echo "After installing, run this script again to verify."
  fi

  exit 1
fi
