# Integration with LightSpeed Hosting Skills

Complete guide for integrating wp-db-migrate with LightSpeed hosting ecosystem for end-to-end production → local → staging workflows.

---

## Overview

This guide shows how to combine **wp-db-migrate** with **ls-hosting-*** skills for complete WordPress development workflows:

1. **Extract** database, files, and site info from production/staging
2. **Migrate** database locally to WordPress Studio
3. **Configure** local environment (plugins, themes, media)
4. **Develop** locally with WordPress agent skills
5. **Deploy** changes back to staging/production

---

## Complete Workflow: Production → Local Development

### Phase 1: Extract from Production (15–20 minutes)

Use LightSpeed hosting skills to get backups and site files:

```bash
# 1. Get database backup from production/staging
/ls-hosting-sync-live-to-staging
# or
/ls-hosting-fetch-tools production

# 2. Extract database file (typically named db.sql or similar)
# Check your downloads folder or follow ls-hosting output

# 3. Get plugins and themes
/ls-hosting-fetch-tools production
# Downloads wp-content/plugins and wp-content/themes

# 4. Note production URLs and site details
# You'll need these for wp-db-migrate next
```

**What you'll have:**

- ✅ Database backup (SQL file)
- ✅ Plugins directory
- ✅ Themes directory
- ✅ Production site URL (e.g., https://example.com)

### Phase 2: Migrate Database Locally (10–30 minutes)

Use wp-db-migrate to import into WordPress Studio:

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# 1. Create WordPress Studio site
studio create my-project

# 2. Run migration with database reduction
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_activity_log

# 3. Verify import succeeded
./scripts/verify-import.sh ~/.studio/sites/my-project
```

**Flags reference:**

- `--exclude-tables` — Skip large non-essential tables (saves 40–70% space)
- `--dry-run` — Preview without importing
- `--verbose` — Detailed output for troubleshooting
- `--no-compress` — Disable compression (rarely needed)

**What happens:**

- ✅ Database exported from production backup
- ✅ MySQL → SQLite converted
- ✅ Imported into WordPress Studio
- ✅ URLs rewritten (production → local)
- ✅ Validated and ready to use

### Phase 3: Configure Locally (10 minutes)

Set up plugins, themes, and media paths:

```bash
# 1. Copy plugins from ls-hosting download
cp -r /path/to/downloaded/plugins/* \
  ~/.studio/sites/my-project/wp-content/plugins/

# 2. Copy themes from ls-hosting download
cp -r /path/to/downloaded/themes/* \
  ~/.studio/sites/my-project/wp-content/themes/

# 3. Configure media paths
# Edit: ~/.studio/sites/my-project/wp-config.php
# Add these constants (before define('WP_DEBUG', ...)):

define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );
define( 'WP_CONTENT_URL', 'https://production.example.com/wp-content' );

# OR copy media subset locally if you need offline access
mkdir -p ~/.studio/sites/my-project/wp-content/uploads
scp -r user@production.com:/var/www/html/wp-content/uploads/2025 \
  ~/.studio/sites/my-project/wp-content/uploads/

# 4. Verify configuration
cd ~/.studio/sites/my-project
wp option get siteurl
wp plugin list | head -10
wp media list | head -3
```

**Why this approach:**

- ✅ Plugins/themes run against real code from production
- ✅ Media served from production (zero local storage)
- ✅ Images always in sync with production
- ✅ Can override for specific development if needed

### Phase 4: Local Development (Ongoing)

Work on themes and plugins locally:

```bash
# 1. Open WordPress Studio
studio open my-project

# 2. Open VS Code for theme/plugin development
code ~/.studio/sites/my-project/wp-content/themes/my-theme
code ~/.studio/sites/my-project/wp-content/plugins/my-plugin

# 3. Use WordPress agent skills for helpers
/wordpress-agent theme-debug
/wordpress-agent plugin-info my-plugin
/wordpress-agent hook-finder wp_head

# 4. Test changes
# The site reloads automatically as you save files
studio open my-project  # Refresh in browser
```

**Daily workflow:**

- Edit theme/plugin files in VS Code
- Save changes
- Refresh WordPress Studio site in browser
- Test functionality
- Commit changes locally

### Phase 5: Deploy Back to Staging/Production (5–10 minutes)

Use LightSpeed hosting skills to deploy changes:

```bash
# 1. Commit your changes
cd ~/.studio/sites/my-project/wp-content/themes/my-theme
git add .
git commit -m "Theme updates for client feedback"

# 2. Deploy with ls-hosting skills
/ls-hosting-deploy-full-site
# Deploys your local changes back to staging

# 3. Test on staging
# Visit: https://staging.example.com
# Verify all changes work

# 4. Sync content back (if you made content edits)
/ls-hosting-sync-content staging production
```

---

## When to Use Each Tool

| Goal                                 | Tool          | Command                            |
| ------------------------------------ | ------------- | ---------------------------------- |
| Get database from production         | ls-hosting    | `/ls-hosting-sync-live-to-staging` |
| Get plugins/themes from production   | ls-hosting    | `/ls-hosting-fetch-tools`          |
| Migrate database to WordPress Studio | wp-db-migrate | `./migrate-recovery.sh`            |
| Verify import succeeded              | wp-db-migrate | `./verify-import.sh`               |
| Configure media paths                | Manual edit   | Edit `wp-config.php`               |
| Deploy theme/plugin changes          | ls-hosting    | `/ls-hosting-deploy-full-site`     |
| Sync content between environments    | ls-hosting    | `/ls-hosting-sync-content`         |

---

## Common Workflows

### Workflow 1: Clone Production to Local

**Goal:** Get a local copy of production for development

```bash
# 1. Get database from production
/ls-hosting-sync-live-to-staging

# 2. Get plugins and themes
/ls-hosting-fetch-tools production

# 3. Migrate database locally
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache

# 4. Copy plugins/themes
cp -r ~/Downloads/plugins/* ~/.studio/sites/my-project/wp-content/plugins/
cp -r ~/Downloads/themes/* ~/.studio/sites/my-project/wp-content/themes/

# 5. Configure media (add to wp-config.php)
define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );

# 6. Done! Open in Studio
studio open my-project
```

**Time:** ~30–45 minutes total

### Workflow 2: Update Theme on Staging

**Goal:** Edit theme locally, deploy to staging

```bash
# 1. Clone production to local (see Workflow 1)

# 2. Edit theme locally
code ~/.studio/sites/my-project/wp-content/themes/my-theme
# Make changes, test in browser

# 3. Deploy to staging
/ls-hosting-deploy-full-site

# 4. Verify on staging
# Visit: https://staging.example.com
```

**Time:** ~5–15 minutes (after initial clone)

### Workflow 3: Reduce Large Database

**Goal:** Clone production but with smaller database for faster local development

```bash
# 1. Get database from production
/ls-hosting-sync-live-to-staging

# 2. Analyze database size
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/preflight-check.sh

# 3. Create reduction profile (in ~/.claude/skills/ls-wp-db-migrate)
cat > production-minimal.conf <<EOF
EXCLUDE_TABLES=wp_postmeta,wp_actionscheduler_logs,wp_cache,wp_activity_log,wp_searchindex
COMPRESS=true
PARALLEL_JOBS=auto
EOF

# 4. Dry-run to preview
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --config production-minimal.conf

# 5. Run actual migration
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --config production-minimal.conf
```

**Result:** 5GB production → ~500MB local (90% reduction)

**Time:** ~15–25 minutes

### Workflow 4: Sync Latest Production Data

**Goal:** Update local database with latest production changes (without losing local theme edits)

```bash
# 1. Backup current local site (optional but recommended)
studio backup my-project

# 2. Get latest database from production
/ls-hosting-sync-live-to-staging

# 3. Migrate latest database
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache

# 4. Theme/plugin files unchanged (still your local edits)
# Media paths still point to production
# Database now has latest production content

# 5. Test
studio open my-project
```

**Important:** Your theme/plugin changes are preserved. Only database is updated.

**Time:** ~10–15 minutes

---

## Integration Points

### With WordPress Agent Skills

After setup, use individual WordPress agent skills for WordPress-specific help:

**For Plugin Development:**

```bash
/wp-plugin-development
# Guides on plugin architecture, hooks, settings API, security
```

**For Block/Theme Development:**

```bash
/wp-block-development
# Gutenberg blocks: block.json, attributes, deprecations

/wp-block-themes
# Block themes: theme.json, templates, patterns
```

**For General WordPress Operations:**

```bash
/wp-wpcli-and-ops
# WP-CLI commands, multisite, automation

/wp-rest-api
# REST API routing, endpoints, authentication
```

**Available Skills at `~/.claude/skills/wordpress-agent/`:**

- `wp-plugin-development` — Plugin architecture and security
- `wp-block-development` — Gutenberg blocks
- `wp-block-themes` — Block theme development
- `wp-rest-api` — REST API patterns
- `wp-wpcli-and-ops` — WP-CLI and operations
- `wp-performance` — Profiling and optimization
- `wp-interactivity-api` — Frontend interactivity with data-wp directives
- `wp-abilities-api` — Capability-based permissions
- And more... (see `~/.claude/skills/wordpress-agent/README.md`)

Skills are available globally and automatically loaded when you invoke them in Claude.

### With VS Code

Develop directly in VS Code while WordPress Studio runs:

```bash
# Terminal 1: Keep Studio running
studio open my-project

# Terminal 2: Edit in VS Code
code ~/.studio/sites/my-project/wp-content/themes/my-theme

# Save files and refresh browser
# Changes live immediately
```

### With Claude

Use Claude in the IDE to:

- Generate theme components
- Debug plugin issues
- Optimize WordPress queries
- Review code against WordPress standards

Use the `/wordpress-agent` skills alongside wp-db-migrate for full context.

---

## Troubleshooting

### "ls-hosting skills not found"

Make sure LightSpeed hosting skills are installed:

```bash
cd ~/.claude/skills/
ls -la | grep ls-hosting
# Should see several ls-hosting-* directories
```

If missing, check with your team lead or Claude setup documentation.

### "Database migration fails with SSH"

Verify SSH access to production:

```bash
ssh -i ~/.ssh/your-key user@production.com 'wp --version'
# Should show WP-CLI version
```

If it fails, check:

- SSH key permissions: `chmod 600 ~/.ssh/your-key`
- Remote WP-CLI installed: `wp --version` on remote server
- SSH keys added to 1Password

### "Media images not loading locally"

Check media configuration in `wp-config.php`:

```bash
cd ~/.studio/sites/my-project
grep UPLOADS wp-config.php
# Should show: define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );

# Verify production is reachable
curl https://production.example.com/wp-content/uploads/
# Should return 200 OK
```

### "Plugins not showing after migration"

Copy plugins from ls-hosting download:

```bash
cp -r ~/Downloads/plugins/* ~/.studio/sites/my-project/wp-content/plugins/
cd ~/.studio/sites/my-project
wp plugin list
```

### "Site slower after migration"

Rebuild search index:

```bash
cd ~/.studio/sites/my-project
wp index build
```

Or clear cache:

```bash
wp cache flush
```

---

## Best Practices

1. **Always use dry-run first** — Preview changes before importing

   ```bash
   ./scripts/migrate-recovery-enhanced.sh --dry-run ...
   ```

2. **Exclude non-essential tables** — Saves space and import time

   ```bash
   --exclude-tables wp_actionscheduler_logs,wp_cache,wp_activity_log
   ```

3. **Keep production URLs in media config** — Avoids storage bloat

   ```php
   define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );
   ```

4. **Test on staging before production** — Use ls-hosting to deploy to staging first

   ```bash
   /ls-hosting-deploy-full-site  # Deploy to staging
   /ls-hosting-sync-content staging production  # Then promote to production
   ```

5. **Backup before major migrations** — WordPress Studio has backup support

   ```bash
   studio backup my-project
   ```

6. **Keep local theme/plugin changes committed** — Easy to sync between environments
   ```bash
   cd ~/.studio/sites/my-project/wp-content/themes/my-theme
   git commit -m "Theme updates"
   ```

---

## See Also

- [Getting Started](getting-started.md) — First migration walkthrough
- [Large Database Handling](large-databases.md) — Size reduction strategies
- [Local Media Setup](LOCAL-MEDIA-SETUP.md) — Media configuration details
- [Best Practices](best-practices.md) — Safe migration strategies
- [Troubleshooting](troubleshooting.md) — Problem solving guide

---

**Ready to integrate?** Start with [Complete Workflow](#complete-workflow-production--local-development) section above.
