# WP DB Migrate Scripts

Quick CLI scripts to help with database migration and recovery workflows.

## Quick Start (Recommended)

Run the complete recovery workflow in one command:

```bash
./scripts/migrate-recovery.sh /path/to/studio/site "https://old-url.com" "https://new-url.local"
```bash

**Example:**
```bash
./scripts/migrate-recovery.sh /Users/ash/Studio/the-safari-partners \
  "https://thesafaripartners.lightspeedwp.dev" \
  "https://thesafaripartners.local"
```bash

This walks you through all steps:
1. Verify the database imported successfully
2. Replace URLs in the database
3. Start the WordPress server

---

## Individual Scripts

### 1. Verify Import

Check if your database imported successfully:

```bash
./scripts/verify-import.sh /path/to/studio/site
```bash

Shows:
- Post count
- User count
- Table count
- Current site URLs

**Example:**
```bash
./scripts/verify-import.sh /Users/ash/Studio/the-safari-partners
```bash

---

### 2. Replace URLs

Replace old site URL with new local URL in the entire database:

```bash
./scripts/replace-urls.sh /path/to/studio/site "https://old-url.com" "https://new-url.local"
```bash

**Example:**
```bash
./scripts/replace-urls.sh /Users/ash/Studio/the-safari-partners \
  "https://thesafaripartners.lightspeedwp.dev" \
  "https://thesafaripartners.local"
```bash

---

### 3. Start Server

Start the WordPress Studio server:

```bash
./scripts/start-server.sh /path/to/studio/site
```bash

**Example:**
```bash
./scripts/start-server.sh /Users/ash/Studio/the-safari-partners
```bash

---

## Adding to Your PATH

For easy access from anywhere, add these scripts to your PATH:

```bash
# Add this to your ~/.zshrc or ~/.bash_profile
export PATH="$PATH:/Users/ash/Studio/thisonetimeonacid/.claude/skills/wp-db-migrate/scripts"
```bash

Then you can run from anywhere:

```bash
migrate-recovery.sh /Users/ash/Studio/the-safari-partners "https://old.com" "https://new.local"
verify-import.sh /Users/ash/Studio/my-site
replace-urls.sh /Users/ash/Studio/my-site "https://old.com" "https://new.local"
start-server.sh /Users/ash/Studio/my-site
```bash

---

## Troubleshooting

### "Permission denied"
Make sure scripts are executable:
```bash
chmod +x /Users/ash/Studio/thisonetimeonacid/.claude/skills/wp-db-migrate/scripts/*.sh
```bash

### "Studio command not found"
Make sure Studio CLI is installed and in your PATH:
```bash
which studio
studio --version
```bash

### Script fails partway through
Run the individual scripts to see which step is failing:
```bash
verify-import.sh /path/to/site
# Then if that passes:
replace-urls.sh /path/to/site "old" "new"
# Then if that passes:
start-server.sh /path/to/site
```bash

---

## What These Scripts Do

All scripts:
- ✅ Run with clear, colored output
- ✅ Validate inputs before running
- ✅ Show progress as they work
- ✅ Verify results and report success/failure
- ✅ Use `set -e` to stop on errors

They're safe to run repeatedly — search-replace is idempotent, and starting an already-running server is fine.
