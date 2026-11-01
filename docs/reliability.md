# Ensuring Reliable Migrations

Build confidence in your database migrations with automatic error detection, recovery checkpoints, and guided remediation.

## Overview

Migration failures happen—network timeouts, disk space issues, table conflicts, memory limits. The reliability system automatically detects what went wrong and guides you to a solution, with recovery checkpoints at each stage so you're never left with a half-migrated database.

### What Gets Automatically Protected

- ✅ Every migration stage (export, analyze, compress, import, validate)
- ✅ Database integrity before and after import
- ✅ Automatic checkpoint creation after each stage
- ✅ Failure classification and recovery guidance
- ✅ Partial import detection with rollback options

## Automatic Error Detection

When a migration fails, the system automatically:

1. **Detects the failure** — Catches exit codes and error conditions
2. **Classifies it** — Determines what type of failure occurred
3. **Creates an error report** — Documents the issue with system diagnostics
4. **Suggests remediation** — Provides specific recovery steps

### Failure Types and Recovery

The system recognizes these failure categories:

#### **Export Failures**

_Occurs during: Database export from source server_

**Causes:**

- SSH connection issues
- WP-CLI not installed or accessible
- Permission denied on remote server
- Remote WordPress path incorrect

**Recovery Steps:**

```bash
# 1. Test SSH connection manually
ssh -i your-key user@host 'echo Connected'

# 2. Verify WP-CLI is installed
ssh user@host 'wp --version'

# 3. Check correct WordPress path
ssh user@host 'ls -la /path/to/wp-config.php'

# 4. Retry with correct parameters
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --ssh-host staging.example.com \
  --ssh-user deploy \
  --wp-path /var/www/html
```

#### **Compression Failures**

_Occurs during: Database compression with gzip_

**Causes:**

- Insufficient disk space (need ~3x database size)
- Temp directory not writable
- Disk quota exceeded

**Recovery Steps:**

```bash
# 1. Check available disk space
df -h

# 2. Clear temporary files
rm -rf /tmp/wp-migrate-*

# 3. Disable compression if disk space is limited
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --no-compress
```

#### **Import Failures**

_Occurs during: SQLite database import_

**Causes:**

- Table already exists in target Studio site
- Out of memory during large table imports
- Disk full during import operation
- Database corruption in source dump

**Recovery Steps:**

**If table already exists:**

```bash
# Fresh Studio site needed - recreate it
studio delete my-site
studio create my-site

# Then retry the migration
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/my-site
```

**If out of memory:**

```bash
# Reduce parallel jobs to use less memory
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --jobs 2

# Or exclude large tables to reduce memory footprint
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --exclude-tables wp_postmeta,wp_actionscheduler_logs
```

**If disk is full:**

```bash
# Check available space
df -h

# Free up space before retrying
rm -rf ~/Downloads/*  # or other non-essential data

# Retry migration
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site
```

#### **Validation Failures**

_Occurs during: Post-import verification_

**Causes:**

- Site not responding after import
- Table count mismatch
- Database integrity issues
- WordPress installation incomplete

**Recovery Steps:**

```bash
# 1. Check if site is responding
curl -I http://my-site.local

# 2. Check WordPress installation
cd ~/Studio/my-site
studio wp core is-installed

# 3. Verify table count matches source
studio wp db tables --format=count

# 4. Check database integrity
studio wp db check

# 5. Repair if needed
studio wp db repair
```

## Recovery Checkpoints

After each stage completes, a checkpoint is created. If a later stage fails, recovery data is available.

### Checkpoint Storage

Checkpoints are stored in your Studio site:

```
~/Studio/my-site/.recovery/
├── recovery.log                    # All events logged here
├── checkpoint-export-TIMESTAMP
├── checkpoint-analyze-TIMESTAMP
├── checkpoint-compress-TIMESTAMP
├── checkpoint-import-TIMESTAMP
└── checkpoint-validate-TIMESTAMP
```

### Understanding Recovery Logs

```bash
# View recovery log
cat ~/Studio/my-site/.recovery/recovery.log

# Output example:
# Recovery initialized at 2026-10-30 14:22:15
# Studio path: /Users/ash/Studio/my-site
# Checkpoint: export
# Checkpoint: analyze
# Checkpoint: compress
# Failure detected: import-failed (stage: import, exit: 1)
```

## Enabling and Disabling Recovery

### Enable Recovery (Default)

Recovery is enabled by default. To explicitly enable:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --enable-recovery
```

### Disable Recovery

If you want to skip recovery overhead:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --disable-recovery
```

## Error Reports

When a migration fails, an error report is automatically generated with diagnostic information.

### Reading Error Reports

Error reports are created at:

```
~/.recovery/[timestamp]-error-report.txt
```

### Report Contents

```
# Migration Error Report
Generated: 2026-10-30 14:25:30

## Summary
- Failure Type: import-failed
- Last Checkpoint: compress
- Checkpoints: 4

## Checkpoints
  - export
  - analyze
  - compress

## Recovery Log
Recovery initialized at 2026-10-30 14:22:15
Studio path: /Users/ash/Studio/my-site
... [all events]

## System Information
- Disk Space: /dev/disk1s1       465Gi  235Gi  230Gi    51% /
- Available Memory: 7.8Gi
- CPU Cores: 8

## Next Steps
Based on the failure type above, see Reliability guide for remediation.
```

## Partial Import Rollback

If import fails midway, you may have partial tables in your Studio database.

### Automatic Rollback

The system attempts to roll back automatically:

```bash
# If you see "rolling back partial import"
# The system is removing incomplete tables
```

### Manual Cleanup

If needed, manually remove tables:

```bash
cd ~/Studio/my-site
studio wp db tables --format=csv | tr ',' '\n' | while read table; do
  if [[ -n "$table" ]]; then
    studio wp db query "DROP TABLE IF EXISTS \`$table\`"
  fi
done
```

Then create a fresh site and retry.

## Best Practices for Reliability

### 1. Use Dry-Run First

Always preview before committing:

```bash
./wp-migrate-clone-to-studio.sh --dry-run \
  --from https://example.com \
  --to ~/Studio/site
```

### 2. Enable Verbose Logging

Capture detailed output for troubleshooting:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --verbose \
  --log-file migration.log
```

### 3. Exclude Problem Tables

Large tables (postmeta, logs, cache) can cause import failures:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --exclude-tables wp_postmeta,wp_actionscheduler_logs
```

### 4. Monitor Progress

Watch the real-time progress during import:

- Progress bar shows current table and percentage
- Spinners indicate long-running operations
- Timing shown for each stage

### 5. Verify After Success

Always run verification steps:

```bash
cd ~/Studio/my-site

# Check site responds
curl -I http://my-site.local

# Verify tables imported
studio wp db tables --format=count

# Check specific tables
studio wp db query "SELECT COUNT(*) FROM wp_posts;"
```

## Handling Network Interruptions

If your migration is interrupted by network issues:

### SSH Export Timeout

```bash
# The export may have completed despite the timeout
# Check if the dump file exists locally

# Retry the full migration - it will reuse the dump if present
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site
```

### Import Timeout

```bash
# Import may have continued despite timeout
# Verify import completed

cd ~/Studio/my-site
studio wp db tables --format=count

# If tables exist, verify integrity
studio wp db check
```

## Recovery Safety Features

### Pre-Migration Backup

Before any import, the target Studio site is backed up:

```bash
# Backup stored at:
~/.recovery/backup-before-import-TIMESTAMP/
```

### Rollback Available

If import fails, the backup can be restored:

```bash
# Manual restore if needed
cd ~/Studio/my-site
wp db tables --format=csv | tr ',' '\n' | while read table; do
  wp db query "DROP TABLE IF EXISTS \`$table\`"
done
```

### No Data Loss

The source database is never modified—only read from. Your staging/production site remains safe.

## When to Contact Support

Recovery guides help 95% of cases. Contact support if:

1. **Exit code you don't recognize** — Error report mentions unknown code
2. **Multiple recovery attempts fail** — Followed all steps but still failing
3. **Unusual error messages** — Something not in the remediation guide
4. **Hardware/infrastructure issues** — Out of disk space on whole system

Provide:

- Error report (from `.recovery/`)
- Migration log (if using `--log-file`)
- Output of `./scripts/preflight-check.sh`
- System info: `uname -a`, `df -h`, `free -h`

## See Also

- [Troubleshooting Guide](troubleshooting.md) — Common error messages
- [Best Practices](best-practices.md) — Prevention strategies
- [Analytics & Monitoring](analytics.md) — Track migration health
