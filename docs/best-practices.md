# Best Practices for Safe & Efficient Migrations

Proven strategies for successful WordPress database migrations from MySQL to SQLite Studio.

## Pre-Migration Checklist

Before you run any migration:

- [ ] **Studio site exists** — Created with `studio create my-site`
- [ ] **SSH access verified** — Can connect to source server if using SSH export
- [ ] **Backup created** — Have a backup of source database
- [ ] **No active users** — Pause development on staging during migration
- [ ] **Database size checked** — Know how large the export will be
- [ ] **Disk space available** — At least 3x the database size (export + compressed + import)
- [ ] **URLs documented** — Know source URL and target URL for replacements

## Backup & Recovery Strategy

### Always Create Backups

**Before migration:**

```bash
# Backup your Studio site (if it already has data)
cd ~/Studio/my-site
wp db export backup-before-migration.sql

# Or manually via Studio
studio backup create my-site
```

**Keep the database export:**

```bash
# The script creates this automatically
# But save it to version control
cp /tmp/export.sql ./exports/staging-$(date +%Y%m%d).sql
```

### Recovery Procedure

If something goes wrong:

```bash
# 1. Delete the Studio site
studio delete my-site

# 2. Recreate it
studio create my-site

# 3. Re-run migration or restore from backup
./wp-migrate-clone-to-studio.sh --use-config

# Or restore your backup
cd ~/Studio/my-site
wp db import backup-before-migration.sql
```

## Performance Optimization

### Compression Settings

**When to enable compression:**

- Slow network connection
- Large databases (>500MB)
- Transferring over slow links

**When to disable compression:**

- Fast local network
- Small databases (<100MB)
- SSD storage (compression overhead)

```bash
./wp-migrate-clone-to-studio.sh --use-config --compress   # Enable
./wp-migrate-clone-to-studio.sh --use-config --no-compress # Disable
```

### Parallel Processing

**Auto-detect (recommended):**

```bash
./wp-migrate-clone-to-studio.sh --use-config  # Uses all CPU cores
```

**Manual tuning:**

- **2 jobs** — Slow systems, limited CPU
- **4 jobs** — Standard, most systems
- **8+ jobs** — Fast systems, many cores

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

### Typical Performance

| Database Size | Compression | Parallel | Time   |
| ------------- | ----------- | -------- | ------ |
| 100MB         | Yes         | Yes      | 5 min  |
| 500MB         | Yes         | Yes      | 8 min  |
| 1GB           | Yes         | Yes      | 12 min |
| 5GB           | Yes         | Yes      | 20 min |

## Table Exclusion Strategy

### What to Exclude

**Always safe to exclude:**

- Logs tables: `wp_actionscheduler_logs`, `wp_logs`
- Cache tables: `wp_cache`, `wp_transients`
- Temporary data: `wp_postmeta` (if only temp tags)
- Session tables: `wp_sessions`

**Be careful excluding:**

- User tables: `wp_users`, `wp_usermeta` (might need for local testing)
- Post tables: `wp_posts`, `wp_postmeta` (content data)

### Usage

```bash
# Exclude tables in config
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_cache

# Or via command line
./wp-migrate-clone-to-studio.sh --use-config \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_transients
```

## URL Replacement Safety

### Dry-Run Before Replacing

**Always test first:**

```bash
cd ~/Studio/my-site

# Preview changes (DRY-RUN)
wp search-replace 'https://staging.example.com' 'http://my-site.local' --dry-run

# Review the output carefully
# Check: number of replacements, affected tables
```

**Then apply:**

```bash
# Apply for real
wp search-replace 'https://staging.example.com' 'http://my-site.local'
```

### Common URL Patterns

```bash
# HTTP to local
wp search-replace 'https://staging.example.com' 'http://my-site.local'

# Remove protocol
wp search-replace '://example.com' '://my-site.local'

# Replace domain only (keep paths)
wp search-replace 'staging.example.com' 'my-site.local'
```

## Post-Import Validation

After migration completes:

```bash
cd ~/Studio/my-site

# 1. Check user count
wp user list

# 2. Check post count
wp post list --post_type=post --format=count

# 3. Check database integrity
wp db check

# 4. View site in browser
studio open my-site
```

## Security Best Practices

### SSH Keys

**Use SSH keys instead of passwords:**

```bash
# Generate a key (if you don't have one)
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key

# Add public key to server
ssh-copy-id -i ~/.ssh/deploy_key.pub user@staging.example.com

# Use in migration
./wp-migrate-clone-to-studio.sh --use-config --ssh-key ~/.ssh/deploy_key
```

### Protect Configuration Files

```bash
# Don't commit production credentials
echo ".wp-db-migrate.conf.prod" >> .gitignore

# Or use environment variables
export WP_DB_MIGRATE_SSH_KEY="~/.ssh/prod_key"
export WP_DB_MIGRATE_SSH_USER="deploy"
```

### Data Privacy

**Exclude user data if needed:**

```bash
EXCLUDE_TABLES=wp_users,wp_usermeta,wp_user_roles
```

**Or anonymize user data:**

```bash
cd ~/Studio/my-site
wp user update admin --user_email="admin@local.test" --user_pass="PASSWORD"
```

## Troubleshooting Common Issues

### Migration Too Slow

**Try:**

1. Increase parallel jobs: `--jobs 8`
2. Disable compression: `--no-compress` (if network is fast)
3. Exclude large log tables: `--exclude-tables wp_actionscheduler_logs`

### Import Fails

**Try:**

1. Create fresh Studio site: `studio delete my-site && studio create my-site`
2. Reduce parallel jobs: `--jobs 2`
3. Check available disk space: `df -h`

### URLs Not Replacing

**Try:**

1. Use dry-run first: `wp search-replace 'from' 'to' --dry-run`
2. Check exact URLs in database: `wp db query "SELECT option_value FROM wp_options LIMIT 5"`
3. Replace before importing (on source database)

## Documentation Links

- [Getting Started](getting-started.md) — Quick tutorial
- [Configuration Guide](configuration.md) — Config file reference
- [Advanced Usage](advanced.md) — Power features
- [Troubleshooting](troubleshooting.md) — Problem solving
- [FAQ](faq.md) — Common questions
