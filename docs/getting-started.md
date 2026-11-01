# Getting Started with wp-db-migrate

Get your first WordPress database migration from MySQL to SQLite Studio in 5 minutes.

## Prerequisites

Before you start, make sure you have:

- **WordPress Studio installed** — [Download Studio](https://developer.wordpress.com/studio/)
- **Target Studio site created** — with wp-config.php already set up
- **Access to your staging/dev server** — either local file or via SSH
- **wp-migrate-clone-to-studio.sh script** — from this repository
- **Basic command-line skills** — comfortable with Terminal/PowerShell

## 5-Minute Quick Start

### Step 1: Identify Your Source Database

You need the MySQL/MariaDB database export. You can get this by:

**Option A: Local Export File**

```bash
# Export from your server manually
ssh user@staging.example.com
wp db export - > ~/database.sql
```

**Option B: Use SSH Directly** (auto-export)
The script can export remotely for you in Step 3.

### Step 2: Create a Studio Site

```bash
# Create a new Studio site
studio create my-site

# Navigate to the site
cd ~/Studio/my-site
```

### Step 3: Run the Migration

**Simplest approach** (with SSH auto-export):

```bash
# From your local machine
./wp-migrate-clone-to-studio.sh \
  --from https://staging.example.com \
  --to ~/Studio/my-site \
  --ssh-host staging.example.com \
  --ssh-user deploy \
  --wp-path /var/www/html
```

**Or with local export file:**

```bash
# Export manually first
ssh user@staging.example.com 'wp db export -' > /tmp/database.sql

# Then import to Studio
./wp-migrate-clone-to-studio.sh \
  --from https://staging.example.com \
  --to ~/Studio/my-site
```

### Step 4: Verify the Migration

```bash
# Check that the site loads
cd ~/Studio/my-site
studio wp wp user list

# View site in browser
studio open my-site
```

### Step 5: Replace URLs (if needed)

If your dev site uses a different URL than your staging site:

```bash
# Preview what will be replaced (dry-run)
cd ~/Studio/my-site
wp search-replace 'https://staging.example.com' 'http://my-site.local' --dry-run

# Apply the replacement
wp search-replace 'https://staging.example.com' 'http://my-site.local'
```

## Understanding the 5-Stage Workflow

When you run the migration, here's what happens:

```
╭──────────────────────────────────╮
│ Stage 1: Export Database         │ ← Downloads from dev/staging
╰──────────────────────────────────╯
         ↓
╭──────────────────────────────────╮
│ Stage 2: Analyze & Optimize      │ ← Scans structure
╰──────────────────────────────────╯
         ↓
╭──────────────────────────────────╮
│ Stage 3: Compress                │ ← Reduces size 70-80%
╰──────────────────────────────────╯
         ↓
╭──────────────────────────────────╮
│ Stage 4: Import                  │ ← Parallel processing
╰──────────────────────────────────╯
         ↓
╭──────────────────────────────────╮
│ Stage 5: Validate Import         │ ← Verifies success
╰──────────────────────────────────╯
         ↓
✓ Database migration complete in 10-15 minutes
```

## What Happens at Each Stage

### Stage 1: Export Database

- Connects to your source server (SSH or local file)
- Runs `wp db export` to download the database
- Shows file size of export
- **Duration:** 2-5 minutes depending on database size

### Stage 2: Analyze & Optimize

- Scans the database structure
- Counts tables and rows
- Suggests excludable tables (logs, cache, temp data)
- **Duration:** 30 seconds

### Stage 3: Compress

- Compresses database with gzip
- Achieves 70-80% size reduction
- **Duration:** 1-3 minutes

### Stage 4: Import

- Decompresses the database
- Imports into Studio's SQLite database
- Uses parallel processing (4 jobs by default)
- Shows progress as tables are imported
- **Duration:** 5-10 minutes

### Stage 5: Validate Import

- Verifies all tables were imported
- Checks database integrity
- Generates report with table count
- **Duration:** 30 seconds

## Common Issues & Quick Fixes

### ❌ "Studio path not found"

**Fix:** Make sure the Studio site directory exists

```bash
studio create my-site  # Create it first
```

### ❌ "SSH connection failed"

**Fix:** Verify SSH access works

```bash
ssh user@host 'echo Connected'  # Test connection first
```

### ❌ "WP-CLI not found on remote"

**Fix:** Ensure WP-CLI is installed on your server

```bash
ssh user@host 'wp --version'  # Check if installed
```

### ❌ "Import failed - table already exists"

**Fix:** This usually means you need a fresh Studio site

```bash
studio delete my-site  # Remove and recreate
studio create my-site
```

## Next Steps

Now that you understand the basics:

1. **Want to reuse settings?** → Learn about [Configuration Profiles](configuration.md)
2. **Want to optimize performance?** → Check [Advanced Usage](advanced.md)
3. **Need more details?** → Read [Best Practices](best-practices.md)
4. **Hit a problem?** → See [Troubleshooting](troubleshooting.md)

## Getting Help

Run the help command to see all options:

```bash
./wp-migrate-clone-to-studio.sh --help
```

This shows all available flags and options for customizing your migration.
