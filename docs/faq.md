# Frequently Asked Questions

Quick answers to common questions about wp-db-migrate.

## General Questions

### What is wp-db-migrate?

A tool that automates WordPress database migration from MySQL/MariaDB to SQLite in WordPress Studio. It handles export, optimization, compression, import, and validation in one command.

### Do I need this tool?

You need wp-db-migrate if you want to:

- Quickly clone a staging/production database to local Studio development
- Automate the migration process
- Avoid manual database exports and imports
- Optimize database performance for local development

You don't need it if you:

- Only work with local WordPress (already SQLite)
- Manually export/import databases
- Don't use WordPress Studio

### Is it safe to use on production databases?

Yes, but with caution:

- It **reads** the production database (export phase)
- It **never modifies** the source database
- It only writes to your local Studio site
- Always create backups before importing

**Best practice:** Test on staging first, then use on production.

### How long does a migration take?

Typical times for different database sizes:

| Size  | Time   | Compression | Parallel |
| ----- | ------ | ----------- | -------- |
| 100MB | 5 min  | Yes         | 4 jobs   |
| 500MB | 8 min  | Yes         | 4 jobs   |
| 1GB   | 12 min | Yes         | 4 jobs   |
| 5GB   | 20 min | Yes         | 4 jobs   |

**Note:** Times depend on network speed, CPU, and database complexity.

## Configuration Questions

### Where should I put the config file?

Option 1: Project directory (default)

```bash
.wp-db-migrate.conf  # Auto-detected
```

Option 2: Home directory (fallback)

```bash
~/.wp-db-migrate.conf  # Auto-detected
```

Option 3: Custom location

```bash
./wp-migrate-clone-to-studio.sh --config /path/to/config
```

### Can I have multiple config files?

Yes! Create environment-specific configs:

```bash
.wp-db-migrate.conf.staging     # Staging migrations
.wp-db-migrate.conf.prod        # Production migrations
.wp-db-migrate.conf.test        # Test migrations
```

Then use the right one:

```bash
./wp-migrate-clone-to-studio.sh --config .wp-db-migrate.conf.staging
```

### How do I override config settings?

Three ways (in priority order):

**1. Command-line flags (highest priority)**

```bash
./wp-migrate-clone-to-studio.sh --use-config --jobs 8
```

**2. Environment variables**

```bash
export WP_DB_MIGRATE_PARALLEL_JOBS="8"
./wp-migrate-clone-to-studio.sh --use-config
```

**3. Config file (lowest priority)**

```ini
PARALLEL_JOBS=4
```

**Result:** Command-line `--jobs 8` wins.

### Should I commit config to git?

- ✅ **Do commit:** Generic configs, non-sensitive settings
- ❌ **Don't commit:** Production credentials, private SSH keys

```bash
# Ignore production configs
echo ".wp-db-migrate.conf.prod" >> .gitignore

# Or use environment variables instead
export WP_DB_MIGRATE_SSH_KEY="~/.ssh/prod_key"
```

## Performance Questions

### How can I speed up migrations?

1. **Increase parallel jobs**

   ```bash
   ./wp-migrate-clone-to-studio.sh --use-config --jobs 8
   ```

2. **Disable compression** (if network is fast)

   ```bash
   ./wp-migrate-clone-to-studio.sh --use-config --no-compress
   ```

3. **Exclude unnecessary tables**

   ```bash
   --exclude-tables wp_actionscheduler_logs,wp_cache,wp_transients
   ```

4. **Use faster storage** (SSD vs HDD)

5. **Migrate at off-peak hours** (less server load)

### Why is compression slow?

Compression trades time for file size:

- **Enable:** Slower export, smaller file, faster transfer
- **Disable:** Faster export, larger file, slower transfer

**Choose based on network speed:**

- Slow network (<50Mbps) → Enable compression
- Fast network (>100Mbps) → Disable compression

### How many parallel jobs should I use?

Rule of thumb:

- **2 jobs:** Limited CPU (2 cores), slow systems
- **4 jobs:** Standard (4 cores), most systems
- **8 jobs:** Fast systems (8+ cores), high-end hardware

**Check your CPU cores:**

```bash
sysctl -n hw.ncpu  # macOS
nproc              # Linux
```

## SSH Export Questions

### Do I need SSH access to migrate?

No, but it's more convenient:

- **With SSH:** Automatic export, one command
- **Without SSH:** Manual export, then local import

### How do I set up SSH keys?

**Generate a key:**

```bash
ssh-keygen -t ed25519 -f ~/.ssh/deploy_key
```

**Add to server:**

```bash
ssh-copy-id -i ~/.ssh/deploy_key.pub user@server.com
```

**Test connection:**

```bash
ssh -i ~/.ssh/deploy_key user@server.com 'echo Connected'
```

**Use in migration:**

```bash
--ssh-key ~/.ssh/deploy_key
```

### What if the remote server doesn't have wp-cli?

The migration will fail with an error about wp-cli not found. You need to:

1. **Install wp-cli** on the remote server, or
2. **Export manually** and import locally

```bash
# Manual export
ssh user@server.com 'wp db export - ' > /tmp/database.sql

# Then import
./wp-migrate-clone-to-studio.sh --from URL --to PATH
```

### Can I use password authentication instead of SSH keys?

Not recommended, but possible with an SSH agent. Better option:

```bash
# Use ssh-add to cache key passphrase
ssh-add ~/.ssh/deploy_key

# Then run migration (uses cached key)
./wp-migrate-clone-to-studio.sh --use-config
```

## Table Exclusion Questions

### What tables can I safely exclude?

**Safe to exclude:**

- `wp_actionscheduler_logs` — Scheduled action logs
- `wp_cache` — Transient cache
- `wp_transients` — Temporary data
- `wp_sessions` — Session data

**Be careful excluding:**

- `wp_users`, `wp_usermeta` — User accounts and metadata
- `wp_posts`, `wp_postmeta` — Content and metadata
- `wp_options` — Site configuration

### Why would I exclude tables?

**Reasons to exclude:**

1. Reduce database size (faster transfer)
2. Skip unnecessary data (logs, cache)
3. Isolate environment-specific data
4. Avoid user account duplication

**Example:** Production has 200GB logs, but you only need content:

```bash
--exclude-tables wp_actionscheduler_logs,wp_wpforms_logs,wp_cache
```

### Can I import excluded tables later?

Yes! Export and import them separately:

```bash
# Export one table from production
ssh user@prod.com 'wp db export wp_users - ' > /tmp/wp_users.sql

# Import to Studio
cd ~/Studio/my-site
wp db import /tmp/wp_users.sql
```

## URL Replacement Questions

### Do I need to replace URLs?

Only if your development site uses a different URL than staging/production:

**You need to replace if:**

- Staging: `https://staging.example.com`
- Local: `http://my-site.local`

**You don't need to replace if:**

- Both use the same URL
- Your site uses relative URLs
- You want to keep the production URL temporarily

### How do I replace URLs safely?

**Always preview first (dry-run):**

```bash
cd ~/Studio/my-site
wp search-replace 'https://staging.example.com' 'http://my-site.local' --dry-run
```

**Then apply:**

```bash
wp search-replace 'https://staging.example.com' 'http://my-site.local'
```

### What about serialized data?

The wp-cli `search-replace` command automatically:

- Handles serialized data
- Updates string lengths
- Respects WordPress encoding

You can safely replace URLs with serialized data.

### Can I replace URLs before importing?

Yes! Replace on the source database before exporting:

```bash
# On staging server
ssh user@staging.com 'wp search-replace "staging.example.com" "example.com"'

# Then export and import to Studio
./wp-migrate-clone-to-studio.sh --use-config
```

## Troubleshooting Quick Answers

### "SSH connection failed"

**Check:**

```bash
ssh -i KEY user@host 'echo ok'  # Test SSH
ssh -i KEY user@host 'wp --version'  # Test wp-cli
ssh -i KEY user@host 'ls -la /path/to/wp-config.php'  # Test WordPress path
```

### "Table already exists"

**Solution:** Create a fresh Studio site

```bash
studio delete my-site
studio create my-site
./wp-migrate-clone-to-studio.sh --use-config
```

### "Disk space full"

**Check available space:**

```bash
df -h  # Check disk usage
du -sh ~/Studio/my-site  # Check site size
```

**Solution:** Delete large tables or move to SSD

### "Import failed"

**Try:**

1. Reduce parallel jobs: `--jobs 2`
2. Check database integrity: `wp db check`
3. Check available memory: `free -h` (Linux) or `vm_stat` (macOS)

## Advanced Questions

### Can I automate migrations in CI/CD?

Yes! Example GitHub Actions workflow:

```yaml
- name: Migrate database
  run: |
    ./wp-migrate-clone-to-studio.sh \
      --from "${{ secrets.STAGING_URL }}" \
      --to "$STUDIO_PATH" \
      --ssh-host "${{ secrets.SSH_HOST }}" \
      --ssh-user "${{ secrets.SSH_USER }}" \
      --ssh-key "${{ secrets.SSH_KEY }}"
```

### Can I migrate between two SQLite databases?

Not directly, but you can:

1. Export old SQLite as SQL
2. Import to new SQLite
3. Use standard MySQL tools

### Does this work with multisite?

The tool exports the entire database, including multisite tables. Multisite URLs will need replacing separately per site.

## Reliability & Error Recovery

### What happens if migration fails midway?

The tool detects the failure, classifies it, and provides recovery guidance:

1. **Automatic detection** — Identifies what went wrong (export failure, out of memory, disk full, etc.)
2. **Error report generated** — Documents the issue with system diagnostics
3. **Remediation guidance** — Provides specific recovery steps for that failure type
4. **Partial rollback available** — Can clean up incomplete data if needed

See [Reliability Guide](reliability.md) for all failure types and recovery procedures.

### Can I rollback if import fails?

Yes:

- **Automatic backup** created before import
- **Partial import detection** if import fails midway
- **Recovery checkpoints** stored at each stage
- **Manual rollback commands** available if needed

### What if the migration times out?

The import may have actually completed despite the timeout:

```bash
# Check if tables were imported
cd ~/Studio/my-site
studio wp db tables --format=count

# If tables exist, verify integrity
studio wp db check
```

### Are recovery features always on?

Yes, by default:

```bash
# To disable recovery (not recommended):
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --disable-recovery
```

## Analytics & Reporting

### Where are migration reports stored?

Reports are saved to your Studio site:

```
~/Studio/my-site/.reports/
├── migration-report.md     # Human-readable summary
├── metrics.json           # Machine-readable data
└── table-statistics.csv   # Spreadsheet format
```

Or specify a custom directory:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --reports-dir ~/migration-reports
```

### What do the reports tell me?

**Markdown Report:**

- Total time and stage breakdown
- Compression effectiveness
- Import throughput
- Table statistics

**JSON Report:**

- Machine-readable format for CI/CD
- All metrics with units
- Stage timing and status

**CSV Report:**

- Table-by-table breakdown
- Row counts and sizes
- Suitable for analysis in Excel

See [Analytics Guide](analytics.md) for detailed explanations.

### How can I use reports in CI/CD?

Parse the JSON report in your CI pipeline:

```yaml
- name: Parse migration metrics
  run: |
    DURATION=$(jq '.migration.duration_seconds' reports/metrics.json)
    TABLES=$(jq '.metrics.total_tables.value' reports/metrics.json)
    echo "Migrated $TABLES tables in ${DURATION}s"
```

### Why is my import speed slow?

Check your import throughput in the report:

- `>2 MB/s` = Good
- `1-2 MB/s` = Try increasing jobs: `--jobs 8`
- `<1 MB/s` = Check disk speed, memory, other processes

Exclude large tables to speed up:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --exclude-tables wp_postmeta,wp_actionscheduler_logs
```

### Can I disable reports if I don't need them?

Yes, to skip report generation:

```bash
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --disable-reports
```

Reports are enabled by default since they're useful for documentation and optimization.

## Need More Help?

- **Getting started?** → [Getting Started](getting-started.md)
- **Configuration help?** → [Configuration Guide](configuration.md)
- **Performance issues?** → [Best Practices](best-practices.md)
- **Advanced features?** → [Advanced Usage](advanced.md)
- **Want reliability?** → [Reliability & Error Recovery](reliability.md)
- **Want analytics?** → [Analytics & Reporting](analytics.md)
- **Problem solving?** → [Troubleshooting](troubleshooting.md)
- **Run the help command:**
  ```bash
  ./wp-migrate-clone-to-studio.sh --help
  ```
