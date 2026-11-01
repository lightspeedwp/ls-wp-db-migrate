# Advanced Usage Guide

Power features and optimization techniques for experienced users.

## Remote SSH Database Export

Directly export databases from production or staging servers without manual downloads.

### Basic SSH Export

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://staging.example.com \
  --to ~/Studio/my-site \
  --ssh-host staging.example.com \
  --ssh-user deploy \
  --ssh-key ~/.ssh/deploy_key \
  --wp-path /var/www/html
```

### SSH Configuration

The script uses:

- SSH key-based authentication (recommended over passwords)
- Custom SSH ports (default 22)
- ConnectTimeout of 30 seconds
- Remote wp-cli for database export

### Troubleshooting SSH Connection

```bash
# Test SSH connection first
ssh -i ~/.ssh/deploy_key -p 22 deploy@staging.example.com 'echo Connected'

# Check wp-cli availability
ssh -i ~/.ssh/deploy_key -p 22 deploy@staging.example.com 'wp --version'

# Verify WordPress path
ssh -i ~/.ssh/deploy_key -p 22 deploy@staging.example.com 'ls -la /var/www/html/wp-config.php'
```

## Parallel Import Processing

Speed up import 3-5x by processing multiple tables in parallel.

### Auto-Detection (Recommended)

```bash
./wp-migrate-clone-to-studio.sh --use-config  # Uses all available CPU cores
```

### Manual Tuning

```bash
# 2 jobs (slow systems)
./wp-migrate-clone-to-studio.sh --use-config --jobs 2

# 4 jobs (standard)
./wp-migrate-clone-to-studio.sh --use-config --jobs 4

# 8 jobs (fast systems)
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

### How Parallel Processing Works

1. **Table Split** — Database split into chunks by table
2. **Parallel Execution** — Each job imports tables concurrently
3. **Progress Tracking** — Visual progress bar shows per-table completion
4. **Validation** — Final integrity check after all jobs complete

## Compression Tuning

Reduce file size by 70-80% for faster network transfers.

### When to Use Compression

**Enable (default):**

- Slow network connections
- Large databases (>500MB)
- Limited bandwidth
- Long transfer times

**Disable:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --no-compress
```

### Compression Performance

```
Database Size | Uncompressed | Compressed | Savings | Time
--------------|--------------|-----------|---------|------
100MB         | 100MB        | 25-30MB   | 70-75%  | 1s
500MB         | 500MB        | 125-150MB | 70-75%  | 5s
1GB           | 1GB          | 250-300MB | 70-75%  | 10s
5GB           | 5GB          | 1.2-1.5GB | 70-75%  | 50s
```

## Dry-Run Mode

Test migrations without making changes.

### Preview What Will Happen

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://staging.example.com \
  --to ~/Studio/my-site \
  --dry-run
```

Output shows:

- Database size and compression estimate
- Table count and row count
- Excludable tables (logs, cache)
- Import time estimate
- No changes are made

### Use Cases

- Verify configuration before real migration
- Check estimated time and disk space
- Test SSH connection without importing
- Practice the workflow

## Progress Tracking & Monitoring

Real-time visual feedback during migration.

### Visual Indicators

**Stage Headers:**

```
╔════════════════════════════════════════╗
║  Stage 1: Export Database              ║
╚════════════════════════════════════════╝
```

**Animated Spinner:**

```
⠙ Exporting database...
⠹ Exporting database...
⠸ Exporting database...
```

**Progress Bar:**

```
Importing: [████████░░░░░░░░░░░] 45%
```

**Timing:**

```
✓ Stage 1 complete (2m 15s elapsed)
```

### Monitor Long-Running Migrations

```bash
# Redirect output to a file for monitoring
./wp-migrate-clone-to-studio.sh --use-config > migration.log 2>&1 &

# Watch progress
tail -f migration.log

# Check final status
echo $?  # 0 = success, non-zero = failure
```

## Studio API Validation

Automatic pre- and post-import verification.

### What Gets Validated

**Pre-Import Check:**

- wp-config.php exists
- wp-content directory accessible
- WordPress installation detected
- Database accessible (if wp-cli available)

**Post-Import Check:**

- Database integrity verified
- Table count matches expected
- No corruption detected
- WordPress installation functional

### Graceful Handling

If wp-cli is not available:

- Validation is skipped
- Migration continues normally
- No error is raised

### Custom Validation

```bash
cd ~/Studio/my-site

# Check database integrity
wp db check

# Verify tables
wp db tables

# Test WordPress
wp core is-installed
wp option get siteurl
```

## Custom Table Exclusions

Skip specific tables during import.

### Exclude Tables in Config

```ini
EXCLUDE_TABLES=wp_users,wp_usermeta,wp_logs,wp_transients
```

### Exclude via Command Line

```bash
./wp-migrate-clone-to-studio.sh --use-config \
  --exclude-tables wp_users,wp_usermeta,wp_logs
```

### Common Exclusion Patterns

```bash
# Logs and cache
--exclude-tables wp_actionscheduler_logs,wp_cache,wp_transients

# Session data
--exclude-tables wp_sessions

# Search index (rebuild after import)
--exclude-tables wp_indexable,wp_indexable_attachment

# Large temporary tables
--exclude-tables wp_job_queue,wp_temp_*

# Monitoring data
--exclude-tables wp_monitoringalerts
```

### Re-Import Excluded Tables Later

```bash
# After migration, re-import a specific table
ssh user@staging.example.com 'wp db export wp_users - ' | \
  wp db import -

# Or just recreate empty schema
cd ~/Studio/my-site
wp db tables --scope=all | xargs wp db tables --drop-if-exists
```

## Environment Variables

Override config settings without editing files.

### Setting Variables

```bash
# Before running migration
export WP_DB_MIGRATE_FROM_URL="https://staging.example.com"
export WP_DB_MIGRATE_TO_PATH="~/Studio/my-site"
export WP_DB_MIGRATE_SSH_HOST="staging.example.com"
export WP_DB_MIGRATE_SSH_USER="deploy"
export WP_DB_MIGRATE_PARALLEL_JOBS="8"
export WP_DB_MIGRATE_COMPRESS="true"

# Then run
./wp-migrate-clone-to-studio.sh --use-config
```

### Priority Order

1. Command-line flags (highest)
2. Environment variables
3. Config file
4. Default values (lowest)

## Logging & Debugging

Detailed output for troubleshooting.

### Verbose Mode

```bash
./wp-migrate-clone-to-studio.sh --use-config --verbose
```

Shows:

- Every function call
- Configuration values loaded
- SSH commands executed
- Compression progress
- Import details
- Validation steps

### Save Output to File

```bash
./wp-migrate-clone-to-studio.sh --use-config --verbose \
  2>&1 | tee migration-$(date +%Y%m%d-%H%M%S).log
```

### Debug Specific Components

```bash
# Test SSH connection only
source scripts/lib-ssh.sh
ssh_configure "staging.example.com" "deploy" "~/.ssh/deploy_key" "22" "/var/www/html"
ssh_test_connection

# Test compression
source scripts/lib-compress.sh
compress_dump "/path/to/database.sql"

# Test config loading
source scripts/lib-config.sh
config_load ".wp-db-migrate.conf"
config_print_summary
```

## Performance Benchmarking

Measure your system's migration speed.

### Benchmark Template

```bash
#!/bin/bash
# Benchmark different configurations

echo "Testing compression performance..."
time ./wp-migrate-clone-to-studio.sh --use-config --compress --dry-run

echo "Testing parallel performance..."
for jobs in 2 4 8; do
  echo "Testing with $jobs parallel jobs..."
  time ./wp-migrate-clone-to-studio.sh --use-config --jobs $jobs --dry-run
done

echo "Benchmarks complete!"
```

### Interpreting Results

- **Compression stage** — Usually 10-30% of total time
- **Import stage** — Typically 50-70% of total time
- **Validation** — Usually <1 minute
- **Total** — Most migrations: 5-15 minutes

### Optimization Tips

- Use `--no-compress` if network is fast (>100Mbps)
- Increase `--jobs` on systems with 8+ cores
- Exclude large log/cache tables for faster imports
- Use SSD storage for faster I/O

## Advanced Configuration Scenarios

### Multi-Environment Setup

```bash
# Global config (shared)
cat > ~/.wp-db-migrate.conf <<EOF
COMPRESS=true
PARALLEL_JOBS=4
DRY_RUN=false
EOF

# Per-project staging config
cat > .wp-db-migrate.conf.staging <<EOF
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/staging-clone
SSH_HOST=staging.example.com
SSH_USER=deploy
EOF

# Per-project production config (with caution)
cat > .wp-db-migrate.conf.prod <<EOF
FROM_URL=https://example.com
TO_PATH=~/Studio/prod-backup
SSH_HOST=prod.example.com
SSH_USER=deploy
EXCLUDE_TABLES=wp_users,wp_usermeta
EOF
```

### CI/CD Integration

```bash
#!/bin/bash
# Automated nightly migration

set -euo pipefail

# Load config from environment
export WP_DB_MIGRATE_FROM_URL="${STAGING_URL}"
export WP_DB_MIGRATE_TO_PATH="${STUDIO_PATH}"
export WP_DB_MIGRATE_SSH_HOST="${STAGING_HOST}"
export WP_DB_MIGRATE_SSH_USER="${STAGING_USER}"
export WP_DB_MIGRATE_SSH_KEY="${STAGING_KEY}"

# Run migration
./wp-migrate-clone-to-studio.sh --use-config --verbose

# Verify success
cd "${STUDIO_PATH}"
wp db check || exit 1
echo "Migration successful at $(date)" >> /var/log/migrations.log
```

## See Also

- [Getting Started](getting-started.md) — Basic usage
- [Configuration Guide](configuration.md) — Config file reference
- [Best Practices](best-practices.md) — Safety strategies
- [Reliability & Error Recovery](reliability.md) — Handle failures gracefully
- [Analytics & Reporting](analytics.md) — Track performance and optimize
- [FAQ](faq.md) — Common questions
- [Troubleshooting](troubleshooting.md) — Problem solving
