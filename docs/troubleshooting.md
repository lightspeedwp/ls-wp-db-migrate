# Troubleshooting Guide

Diagnosis and solutions for common issues.

> **Pro Tip:** Check the [Reliability & Error Recovery](reliability.md) guide for proactive strategies to prevent common failures before they happen. This guide helps you fix issues after they occur.

## Error Messages

### "Studio path not found"

**Error:**

```
Error: Studio path does not exist: ~/Studio/my-site
```

**Cause:** The target Studio site directory doesn't exist.

**Solution:**

```bash
# Create the Studio site first
studio create my-site

# Then run migration
./wp-migrate-clone-to-studio.sh --from URL --to ~/Studio/my-site
```

---

### "SSH connection failed"

**Error:**

```
Error: SSH connection failed to host
Connection timeout or permission denied
```

**Diagnosis:**

```bash
# Test SSH connection
ssh -i KEY user@host 'echo ok'

# Check SSH key permissions
ls -la ~/.ssh/deploy_key
# Should be: -rw------- (600)

# Verify wp-cli is installed
ssh -i KEY user@host 'which wp'

# Check WordPress path
ssh -i KEY user@host 'ls -la /var/www/html/wp-config.php'
```

**Solutions:**

**If SSH key permission is wrong:**

```bash
chmod 600 ~/.ssh/deploy_key
```

**If wp-cli not found:**

```bash
# Install wp-cli on remote server
ssh user@host 'curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar'
ssh user@host 'chmod +x wp-cli.phar && sudo mv wp-cli.phar /usr/local/bin/wp'
```

**If using custom SSH port:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --ssh-port 2222
```

---

### "WP-CLI not found on remote"

**Error:**

```
Error: wp-cli is not installed on remote server
```

**Solution 1: Install wp-cli**

```bash
# On remote server (via SSH)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Verify installation
wp --version
```

**Solution 2: Export manually**

```bash
# Export database manually
ssh user@host 'mysqldump -u user -p database > /tmp/export.sql'

# Download export
scp user@host:/tmp/export.sql /tmp/database.sql

# Import manually
./wp-migrate-clone-to-studio.sh --from URL --to PATH
# Script will detect local export file
```

---

### "Table already exists"

**Error:**

```
Error: Table wp_posts already exists
Could not import database
```

**Cause:** Importing to a non-empty Studio site (previous data exists).

**Solution:**

```bash
# Delete and recreate Studio site
studio delete my-site
studio create my-site

# Then retry migration
./wp-migrate-clone-to-studio.sh --use-config
```

---

### "Database import failed"

**Error:**

```
Error: Could not execute statement on import
SQL error in table import
```

**Causes:**

1. Not enough disk space
2. Parallel jobs too high (memory issue)
3. Corrupted database export
4. Incompatible SQLite schema, such as
   `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY` (run the export through
   `node lib/sql-tool.cjs sanitise`, which removes these)

**Solutions:**

**Check disk space:**

```bash
df -h
du -sh ~/Studio/my-site
# Need at least 3x database size
```

**Reduce parallel jobs:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 2
```

**Check export integrity:**

```bash
# Verify export file
file /tmp/export.sql
gunzip -t /tmp/export.sql.gz  # If compressed

# Check for corruption
head -100 /tmp/export.sql
tail -20 /tmp/export.sql
```

**Try without compression:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --no-compress
```

---

## Performance Issues

### "Migration is too slow"

**Measure current performance:**

```bash
time ./wp-migrate-clone-to-studio.sh --use-config
```

**Optimization strategies:**

**1. Increase parallel jobs**

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

**2. Disable compression (if network is fast)**

```bash
./wp-migrate-clone-to-studio.sh --use-config --no-compress
```

**3. Exclude large unnecessary tables**

```bash
./wp-migrate-clone-to-studio.sh --use-config \
  --exclude-tables wp_actionscheduler_logs,wp_cache
```

**4. Check system resources**

```bash
# macOS
vm_stat
top -l 1 | grep "PhysMem"

# Linux
free -h
top -b -n 1 | head -20
```

**5. Use SSD instead of HDD**

- SSD I/O is 10x faster than HDD
- Move Studio to SSD if possible

---

### "High memory usage"

**Symptom:** Migration slows down or crashes with "out of memory" error.

**Solution:**

**Reduce parallel jobs:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 2
```

**Monitor memory usage:**

```bash
# macOS
watch -n 1 'vm_stat | grep "Pages free"'

# Linux
watch -n 1 free -h
```

---

## SSH Connection Issues

### "Permission denied (publickey)"

**Error:**

```
Permission denied (publickey)
```

**Causes:**

1. SSH key not authorized on server
2. Wrong key specified
3. Key permissions incorrect

**Solution:**

**1. Add public key to server:**

```bash
ssh-copy-id -i ~/.ssh/deploy_key.pub user@host
```

**2. Check key is correct:**

```bash
ssh -i ~/.ssh/deploy_key user@host 'echo ok'
```

**3. Fix key permissions:**

```bash
chmod 600 ~/.ssh/deploy_key
chmod 644 ~/.ssh/deploy_key.pub
```

---

### "Connection timed out"

**Error:**

```
Connection timed out
```

**Causes:**

1. Network unreachable
2. Firewall blocking SSH
3. Server down
4. Wrong hostname

**Solution:**

**Test connectivity:**

```bash
# Check if server is reachable
ping staging.example.com

# Test SSH port
nc -zv staging.example.com 22

# Try direct SSH
ssh -v user@staging.example.com
# -v shows detailed debugging
```

**Fix firewall/network:**

- Check server firewall allows SSH (port 22 or custom)
- Check local network allows outbound SSH
- Verify hostname is correct
- Try from different network if possible

---

## URL Replacement Issues

### "URLs not replacing"

**Symptom:** After migration, URLs still point to staging/production.

**Diagnosis:**

**1. Check what URLs need replacing:**

```bash
cd ~/Studio/my-site
wp option get siteurl
wp option get home
```

**2. Find all URLs in database:**

```bash
wp db query "SELECT option_value FROM wp_options WHERE option_value LIKE '%example.com%' LIMIT 5"
```

**Solution:**

**Preview replacement (dry-run):**

```bash
wp search-replace 'https://staging.example.com' 'http://my-site.local' --dry-run
```

**Apply replacement:**

```bash
wp search-replace 'https://staging.example.com' 'http://my-site.local'
```

**For serialized data:**

```bash
# wp-cli handles serialized automatically
wp search-replace 'staging.example.com' 'my-site.local' --all-tables-with-prefix
```

---

### "Replacement breaks site"

**Symptom:** After URL replacement, site shows errors or breaks.

**Solution:**

**Revert changes:**

```bash
# Replace back to original URL
cd ~/Studio/my-site
wp search-replace 'http://my-site.local' 'https://staging.example.com'
```

**Check what went wrong:**

```bash
# View error logs
wp debug-log show

# Check WordPress core files
wp core verify-checksums
```

**Try more specific replacement:**

```bash
# Instead of replacing domain everywhere:
wp search-replace 'staging.example.com' 'my-site.local' wp_posts,wp_postmeta,wp_options
```

---

## Validation Issues

### "Database integrity check failed"

**Error:**

```
Database integrity check failed
Possible corruption detected
```

**Solution:**

**Run WordPress database check:**

```bash
cd ~/Studio/my-site
wp db check
```

**Repair if needed:**

```bash
wp db repair
```

**Check database file:**

```bash
# Check SQLite file integrity
sqlite3 wp-content/database/.ht.sqlite "PRAGMA integrity_check;"

# If corrupted, restore and re-import
studio delete my-site
studio create my-site
./wp-migrate-clone-to-studio.sh --use-config
```

---

### "Table count mismatch"

**Error:**

```
Expected 47 tables, found 42
```

**Cause:** Some tables failed to import or were excluded.

**Solution:**

**Check what's missing:**

```bash
cd ~/Studio/my-site
wp db tables --scope=all
```

**Import missing tables manually:**

```bash
# Export specific table from staging
ssh user@staging.com 'wp db export wp_custom_table -' > /tmp/table.sql

# Import to Studio
wp db import /tmp/table.sql
```

**Or re-run migration:**

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 2
```

---

## Recovery Procedures

### "Rollback to backup"

If something goes wrong, recover from backup:

**1. Delete failed migration:**

```bash
studio delete my-site
```

**2. Recreate site:**

```bash
studio create my-site
```

**3. Restore from backup:**

```bash
cd ~/Studio/my-site
wp db import /path/to/backup.sql
```

**Or re-run migration:**

```bash
./wp-migrate-clone-to-studio.sh --use-config
```

---

### "Partial import recovery"

If import stopped partway:

**Option 1: Start over**

```bash
studio delete my-site
studio create my-site
./wp-migrate-clone-to-studio.sh --use-config
```

**Option 2: Resume import**

```bash
# Check what was imported
cd ~/Studio/my-site
wp db tables --format=count

# Continue with remaining tables (usually faster second time)
./wp-migrate-clone-to-studio.sh --use-config --jobs 2
```

---

## Testing & Verification

### "Verify migration succeeded"

**Checklist:**

```bash
cd ~/Studio/my-site

# 1. Check database exists
wp db check

# 2. Count tables (compare to source)
wp db tables --format=count

# 3. Check specific tables
wp post list --format=count
wp user list --format=count
wp option get siteurl

# 4. Test WordPress
wp core is-installed

# 5. Open in browser
studio open my-site
# Check site loads
# Check pages/posts render
# Check plugins loaded
```

### "Compare source and target"

**On source (production/staging):**

```bash
wp db tables --format=count                # Table count
wp post list --format=count                # Post count
wp user list --format=count                # User count
wp option get siteurl                      # Site URL
```

**On target (Studio):**

```bash
cd ~/Studio/my-site
wp db tables --format=count                # Should match
wp post list --format=count                # Should match
wp user list --format=count                # Should match (if users included)
wp option get siteurl                      # Check if replaced
```

---

## Getting Help

### "Collect debug information"

If you need to report an issue, gather:

```bash
# Run with verbose output
./wp-migrate-clone-to-studio.sh --use-config --verbose > debug.log 2>&1

# System information
uname -a >> debug.log
df -h >> debug.log

# WordPress information
cd ~/Studio/my-site
wp --version >> debug.log
wp core verify-checksums >> debug.log

# Share the log file
cat debug.log | head -200  # First 200 lines
```

### "Common fixes summary"

| Problem        | Quick Fix                                 |
| -------------- | ----------------------------------------- |
| SSH fails      | `ssh -i KEY user@host 'echo ok'`          |
| wp-cli missing | Install wp-cli on remote                  |
| Table exists   | `studio delete && studio create`          |
| Disk full      | Check `df -h` and free space              |
| Too slow       | Increase `--jobs` or disable `--compress` |
| Memory error   | Reduce `--jobs` to 2                      |
| URL wrong      | `wp search-replace old new`               |
| Corrupted DB   | `wp db repair`                            |
| Partial import | Re-run migration with `--jobs 2`          |

---

## Documentation Links

- [Getting Started](getting-started.md) — Quick start
- [Configuration Guide](configuration.md) — Config reference
- [Best Practices](best-practices.md) — Safe strategies
- [Reliability & Error Recovery](reliability.md) — Handle failures and recover
- [Analytics & Reporting](analytics.md) — Track performance metrics
- [Advanced Usage](advanced.md) — Power features
- [FAQ](faq.md) — Common questions
