# Handling Large Databases (500MB+)

Guide for reducing database size when migrating large production/staging databases to WordPress Studio locally.

## Problem: Database Too Large

**Symptoms:**

- Export file > 500MB
- Migration takes 20+ minutes
- Mac storage fills quickly
- Import memory errors
- System slowdown during migration

**Root Cause:** WordPress databases contain non-essential data:

- Post meta (revisions, duplicate entries)
- User logs and activity
- Cache tables
- Action scheduler logs
- Search indexes

## Solution: Reduce Database Size Radically

### Option 1: Scan & Propose Reductions (Recommended First Time)

Let wp-db-migrate analyze your database and suggest what to exclude:

```bash
# 1. Export your database (manually or via ls-hosting)
ssh user@staging.com "wp db export - " > staging-db.sql

# 2. Analyze with wp-db-migrate
./scripts/preflight-check.sh

# This shows:
# - Total database size
# - Table breakdown by size
# - Suggested exclusions (tables > 100MB)
# - Estimated savings
```

**Example output:**

```
Database Analysis:
  Total size: 2.3 GB

  Large tables (candidates for exclusion):
  - wp_postmeta: 680MB (37%) → Safe to exclude (revisions, metas)
  - wp_actionscheduler_logs: 420MB (18%) → Safe to exclude (logs only)
  - wp_cache: 310MB (14%) → Safe to exclude (regenerates)
  - wp_post_revisions: 180MB (8%) → Safe to exclude (old versions)
  - wp_searchindex: 95MB (5%) → Safe to exclude (rebuilds)

  Estimated size after exclusion: 615 MB (73% reduction)
```

### Option 2: Use Preconfigured Profiles

LightSpeed provides optimized configurations for common scenarios:

#### Profile: Minimal Clone (Content Only)

```bash
# Copies: All pages + all posts + basic settings
# Excludes: User activity, logs, revisions, cache, search indexes

./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --config profiles/content-only.conf
```

**Contents of `profiles/content-only.conf`:**

```ini
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_postmeta,wp_cache,wp_users,wp_usermeta,wp_activity_log,wp_searchindex,wp_accesskeys,wp_referrer_links
COMPRESS=true
PARALLEL_JOBS=4
```

**Result:** ~70% size reduction

#### Profile: Pages Only (No Posts)

```bash
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --config profiles/pages-only.conf
```

**Contents of `profiles/pages-only.conf`:**

```ini
EXCLUDE_TABLES=wp_posts_page,wp_postmeta,wp_actionscheduler_logs,wp_cache,wp_users,wp_usermeta,wp_activity_log,wp_searchindex
COMPRESS=true
PARALLEL_JOBS=4
```

**Result:** ~60% size reduction

#### Profile: Development (Basic Content)

```bash
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --config profiles/development.conf
```

**Contents of `profiles/development.conf`:**

```ini
# Keep key content but remove activity/logs/cache
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_cache,wp_activity_log,wp_users,wp_usermeta,wp_searchindex,wp_accesskeys
COMPRESS=true
PARALLEL_JOBS=4
```

**Result:** ~50% size reduction

### Option 3: Manual Exclusion (Know What You're Doing)

For specific needs, specify exact tables to exclude:

```bash
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_users,wp_usermeta
```

**Safe to exclude (won't break site):**

- `wp_actionscheduler_logs` — Action scheduler history (safe, regenerates)
- `wp_cache` — Cache data (safe, regenerates)
- `wp_activity_log` — Admin audit log (safe, historical only)
- `wp_searchindex` — Search index (safe, rebuilds)
- `wp_accesskeys` — API keys (safe if not needed locally)
- `wp_referrer_links` — Redirect tracking (safe, statistical only)
- `wp_postmeta` — Post metadata (be careful! may break site if critical)

**Never exclude:**

- `wp_posts` — Your actual content
- `wp_postmeta` — Post settings (unless you're sure)
- `wp_options` — Site configuration
- `wp_terms` — Categories/tags
- `wp_links` — Navigation menus
- `wp_comments` — Comments/discussion

## Strategy: Staged Reduction

Don't just exclude everything. Use this approach:

### Step 1: Dry-Run with Minimal Exclusions (5 minutes)

```bash
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache
```

**Check:**

- Estimated final size
- Expected import time
- Any warnings

### Step 2: If Still Too Large, Exclude More (5 minutes)

```bash
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_activity_log,wp_searchindex
```

### Step 3: When Satisfied, Run for Real (10-30 minutes depending on size)

```bash
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_activity_log,wp_searchindex
```

## Performance Tips

### Compression (Default: ON)

```bash
# Reduces file size by 70-75% during transfer
# Keep enabled for large databases
--compress          # Enabled by default

# Disable only if network is very fast (>100 Mbps)
--no-compress
```

### Parallel Processing (Default: Auto)

```bash
# Use all available CPU cores
# Processes multiple tables simultaneously

--jobs 4            # 4 concurrent jobs (slower systems)
--jobs 8            # 8 concurrent jobs (fast systems)
--jobs auto         # Auto-detect (default)
```

**Impact:** Can reduce import time by 60-70%

### Storage (Before Import)

```bash
# Check available space (need 3x database size)
df -h ~/Studio

# Free up space if needed
# Move other projects temporarily
# Clear trash
# Run system cleanup
```

## Common Scenario: Production Database

**Starting size:** 5GB  
**Goal:** 500MB local clone

### Recommended approach:

```bash
# 1. Export from production (via ls-hosting-sync-live-to-staging)
# This gives you a fresh backup

# 2. Analyze what can be removed
./scripts/preflight-check.sh

# 3. Create aggressive exclusion config
cat > production-minimal.conf <<EOF
EXCLUDE_TABLES=wp_postmeta,wp_actionscheduler_logs,wp_cache,wp_users,wp_usermeta,wp_activity_log,wp_searchindex,wp_accesskeys,wp_referrer_links,wp_job_queue
COMPRESS=true
PARALLEL_JOBS=8
EOF

# 4. Dry-run first
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/Studio/my-project \
  "https://production.com" \
  "https://my-project.local" \
  --config production-minimal.conf

# 5. Verify size reduction looks good, then import
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://production.com" \
  "https://my-project.local" \
  --config production-minimal.conf
```

**Expected result:**

- 5GB → 500MB (90% reduction)
- Import time: 8-12 minutes
- Local storage: Manageable
- All essential content: Preserved

## After Import: Rebuild Search Index

If you excluded search indexes:

```bash
cd ~/Studio/my-project
wp index build
```

This rebuilds the search index from your imported content (usually 2-5 min for moderate sites).

## Troubleshooting Large Database Issues

### "Not enough disk space"

```bash
# Check available space
df -h

# You need: (database size × 3)
# Example: 1GB database = 3GB required space
```

**Solution:**

- Delete other WordPress Studio sites temporarily
- Move large files to external drive
- Use aggressive exclusions

### "Import timeout"

Usually harmless. Data likely imported:

```bash
# Check if import succeeded
./scripts/verify-import.sh ~/Studio/my-project

# If incomplete, try again with fewer parallel jobs
--jobs 2
```

### "Memory error during import"

```bash
# Reduce parallel jobs
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --jobs 1
```

### "Slow performance after import"

```bash
# Rebuild search index
wp index build

# Clear cache
wp cache flush

# Check database integrity
wp db check

# Check plugin count
wp plugin list
```

## Best Practices for Large Databases

1. **Always exclude logs/cache**

   ```
   wp_actionscheduler_logs
   wp_cache
   wp_activity_log
   ```

2. **Use compression**

   ```
   --compress  # Default, keeps it on
   ```

3. **Use parallel processing**

   ```
   --jobs 4    # or more depending on CPU
   ```

4. **Dry-run first**

   ```
   --dry-run   # See impact before committing
   ```

5. **Verify after import**

   ```
   ./verify-import.sh ~/Studio/my-project
   ```

6. **Document your exclusions**
   ```
   # Save successful config for future use
   cp production-minimal.conf ~/.wp-db-migrate-configs/
   ```

---

## Integration with ls-hosting

Use with LightSpeed hosting skills:

```bash
# 1. Extract database from production
# Use: ls-hosting-sync-live-to-staging

# 2. Reduce size with wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://staging.example.com" \
  "https://my-project.local"

# 3. Extract plugins/themes from production
# Use: ls-hosting-fetch-tools

# 4. Configure media paths locally
# Use: Media Path Configuration Guide
```

---

**See also:**

- [Getting Started](getting-started.md) — Basic migration
- [Best Practices](best-practices.md) — Safe strategies
- [Troubleshooting](troubleshooting.md) — Problem solving
- [Advanced Usage](advanced.md) — Power features
