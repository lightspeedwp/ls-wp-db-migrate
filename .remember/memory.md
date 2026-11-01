# wp-db-migrate: Project Context & Memory

## Project Overview

**Purpose:** Professional-grade WordPress database migration skill for Claude. Migrates databases from MySQL/MariaDB to SQLite in WordPress Studio with safety gates, validation, and rollback capability.

**Tech Stack:**

- Primary: Bash (shell scripts for migration automation)
- Secondary: Node.js/JavaScript (Jest tests, CLI tools)
- Testing: Jest (unit tests, 192 passing) + BATS (integration tests, 23 passing)
- Target: WordPress Studio, SQLite databases

## Key Characteristics

### Safety First

- Backup before import with auto-rollback
- Dry-run mode to preview changes
- Pre-flight dependency checks
- Explicit confirmation gates at each step
- Post-import validation

### Technology Constraints

- **Bash compatibility:** 3.2+ (macOS and Linux)
- **No external dependencies:** Scripts work standalone
- **SQLite focus:** Sanitizes MySQL-specific syntax
- **Studio integration:** Works with `studio` CLI

## Project Structure

````bash
skill/          - Claude skill (primary deliverable)
  ├── SKILL.md  - Complete documentation
  ├── scripts/  - Migration automation scripts
  ├── api/      - JavaScript automation tools
  ├── evals/    - Skill evaluation test cases
  └── prompts/  - Agent instruction files

__tests__/      - Jest unit tests (100% coverage enforced)
tests/          - BATS integration tests
docs/           - Documentation guides
plugin/         - Claude plugin manifest
```bash

## Development Workflow

### Testing Requirements
- **Jest:** 192+ tests, 100% coverage on all metrics
- **BATS:** 23+ integration tests for shell scripts
- **Command:** `npm run test:all` (runs Jest + BATS)

### Code Standards
- Bash: 3.2+ compatible, `set -e` for safety
- JavaScript: ESLint, 2-space indentation
- All: Prettier formatting, EditorConfig

### Git Workflow
- Branch prefix: `wp-db-{feature}`
- Commit format: Conventional (type: description)
- Requires: All tests passing, no coverage decrease

## Key Decisions

1. **Skill-first design:** CLI tools derived from skill, not vice versa
2. **SQLite strategy:** Remove MySQL-only syntax, suggest table exclusions
3. **Safety gates:** Every operation requires confirmation or dry-run
4. **Test coverage:** 100% enforced (Jest + BATS)
5. **Bash compatibility:** Must work on macOS (3.2) and Linux

## Common Tasks

### Run Tests
```bash
npm test              # Jest only
npm run test:bats    # BATS only
npm run test:all     # Both (required before commit)
```bash

### Migrate a Database
```bash
./scripts/preflight-check.sh  # Verify setup
./scripts/migrate-recovery-enhanced.sh --dry-run \
  /path/to/studio/site "old-url" "new-url"
./scripts/migrate-recovery.sh \
  /path/to/studio/site "old-url" "new-url"
```bash

### Update Documentation
- Edit `SKILL.md` (source of truth)
- Update `docs/` folder to reflect changes
- Cross-reference with README.md

## Team/Maintainer Info

**Repo:** https://github.com/lightspeedwp/ls-wp-db-migrate
**Type:** LightSpeed WP skill (WordPress + SQLite focused)
**Status:** Production-ready (v1.1.0)

## Important Notes for Claude Sessions

1. **Always run tests:** `npm run test:all` validates changes
2. **Bash compatibility:** Test on macOS (3.2) not just modern Bash
3. **Documentation first:** Update SKILL.md before changing scripts
4. **Safety matters:** Changes affect database operations—extreme care needed
5. **Mock WordPress:** Tests use mock Studio sites, not real databases
````
