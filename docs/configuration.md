# Configuration & Profiles Guide

Master the `.wp-db-migrate.conf` configuration file to save time on repeated migrations.

## What is a Configuration Profile?

A configuration profile is a simple text file (`.wp-db-migrate.conf`) that stores your migration settings. Instead of typing the same options every time, you create a file once and reuse it.

**Benefits:**

- ✅ Type settings once, reuse forever
- ✅ Share configs with your team
- ✅ Environment-specific profiles (staging, production, testing)
- ✅ Override individual settings with command-line flags
- ✅ Version control friendly (commit to git)

## Creating Your First Config File

### Step 1: Create `.wp-db-migrate.conf`

Create a new file in your project directory:

```bash
# In your project root
cat > .wp-db-migrate.conf <<EOF
# WordPress Database Migration Configuration
# Created: 2026-10-30

FROM_URL=https://staging.example.com
TO_PATH=~/Studio/my-site
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_cache
COMPRESS=true
PARALLEL_JOBS=4
DRY_RUN=false
VERBOSE=false
EOF
```

### Step 2: Use the Config

```bash
# Auto-detect and load .wp-db-migrate.conf
./wp-migrate-clone-to-studio.sh --use-config

# Or specify a config file
./wp-migrate-clone-to-studio.sh --config ~/.wp-db-migrate.conf
```

## All Configuration Options

### Required Settings

```ini
FROM_URL=https://staging.example.com     # Source site URL
TO_PATH=~/Studio/my-site                 # Target Studio path
```

### SSH Settings (for remote export)

```ini
SSH_HOST=staging.example.com             # SSH hostname
SSH_USER=deploy                          # SSH username
SSH_PORT=22                              # SSH port (default: 22)
SSH_KEY=~/.ssh/staging_key               # SSH private key (optional)
WP_PATH=/var/www/html                    # Remote WordPress path
```

### Database Settings

```ini
EXCLUDE_TABLES=wp_logs,wp_cache          # Comma-separated tables to skip
```

### Performance Settings

```ini
COMPRESS=true                            # Enable gzip compression (default: true)
PARALLEL=true                            # Enable parallel import (default: true)
PARALLEL_JOBS=4                          # Number of parallel jobs (default: auto-detect)
```

### Execution Settings

```ini
DRY_RUN=false                            # Preview without making changes
VERBOSE=false                            # Show detailed output
```

## Config File Precedence

When you run a migration, settings are applied in this order (highest priority first):

```
1. Command-line flags      (highest priority)
   ./wp-migrate-clone-to-studio.sh --use-config --jobs 8
                                                   ↑↑↑↑↑ overrides config

2. Configuration file      (.wp-db-migrate.conf or --config FILE)
   PARALLEL_JOBS=4

3. Default values          (lowest priority)
   auto-detect CPU cores
```

**Example:** If your config says `PARALLEL_JOBS=4` but you run with `--jobs 8`, the CLI flag wins:

```bash
# Config has PARALLEL_JOBS=4
# But this command uses 8 jobs instead
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

## Config File Search Paths

When you use `--use-config`, the script looks in these locations (first match wins):

1. `./.wp-db-migrate.conf` (current directory)
2. `~/.wp-db-migrate.conf` (home directory)

Or specify a custom path:

```bash
./wp-migrate-clone-to-studio.sh --config /etc/wp-migrate/.wp-db-migrate.conf
```

## Real-World Examples

### Staging to Local Development

```ini
# .wp-db-migrate.conf
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/staging-mirror
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_cache_logs
COMPRESS=true
PARALLEL_JOBS=4
```

Usage:

```bash
./wp-migrate-clone-to-studio.sh --use-config
```

### Quick Testing (Dry-Run)

```ini
# .wp-db-migrate.conf.test
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/test-site
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
DRY_RUN=true
VERBOSE=true
```

Usage:

```bash
./wp-migrate-clone-to-studio.sh --config .wp-db-migrate.conf.test
```

### Minimal Config (with SSH prompt)

```ini
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/my-site
```

Usage:

```bash
./wp-migrate-clone-to-studio.sh --use-config \
  --ssh-host staging.example.com \
  --ssh-user deploy
```

## Environment-Specific Configs

Create separate configs for different environments:

```bash
# Staging config
cat > .wp-db-migrate.conf.staging <<EOF
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/staging-clone
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EOF

# Production config
cat > .wp-db-migrate.conf.prod <<EOF
FROM_URL=https://example.com
TO_PATH=~/Studio/prod-clone
SSH_HOST=prod.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EXCLUDE_TABLES=wp_users,wp_usermeta
EOF
```

Usage:

```bash
# Use staging config
./wp-migrate-clone-to-studio.sh --config .wp-db-migrate.conf.staging

# Use production config
./wp-migrate-clone-to-studio.sh --config .wp-db-migrate.conf.prod
```

## Tips & Tricks

### 1. Commit Config to Git

```bash
# Add to version control for team sharing
git add .wp-db-migrate.conf
git commit -m "Add migration config for staging"
```

### 2. Override Single Settings

```bash
# Use config but override one setting
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

### 3. Test Before Running

```bash
# Create a test config
cp .wp-db-migrate.conf .wp-db-migrate.conf.test

# Add DRY_RUN=true
echo "DRY_RUN=true" >> .wp-db-migrate.conf.test

# Test the migration
./wp-migrate-clone-to-studio.sh --config .wp-db-migrate.conf.test
```

### 4. Performance Tuning

Adjust for your system:

```ini
# Slow network/server
PARALLEL_JOBS=2
COMPRESS=true

# Fast local network
PARALLEL_JOBS=8
COMPRESS=false
```

## Troubleshooting Config Issues

### Config file not found

```bash
# Make sure file exists in expected location
ls -la .wp-db-migrate.conf
ls -la ~/.wp-db-migrate.conf
```

### Settings not being applied

```bash
# Check which config is being loaded (use --verbose)
./wp-migrate-clone-to-studio.sh --use-config --verbose

# Verify file contents
cat .wp-db-migrate.conf
```

### Command-line flag not overriding config

```bash
# Remember: CLI flags have highest priority
./wp-migrate-clone-to-studio.sh --use-config --jobs 8  # This works
./wp-migrate-clone-to-studio.sh --config FILE --jobs 8  # This also works
```

## See Also

- [Getting Started](getting-started.md) — Basic usage
- [Best Practices](best-practices.md) — Configuration best practices
- [Advanced Usage](advanced.md) — Advanced config options
