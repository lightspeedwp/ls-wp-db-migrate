# 🚀 LightSpeed Developer Announcement: wp-db-migrate Plugin Available

**Date:** October 2026  
**From:** LightSpeed Development Team  
**For:** All Developers Using WordPress Studio & Local Development

---

## 📢 What's New

We've released **wp-db-migrate** — a professional-grade WordPress database migration tool integrated into Claude. It lets you:

✅ **Clone production/staging databases to local WordPress Studio**  
✅ **Automatically reduce large databases** for faster local development  
✅ **Run migrations from command line** with full backup/recovery  
✅ **Use in Claude** with our new Plugin & Skills  
✅ **Integrate with other LightSpeed hosting tools** (ls-hosting-*)

---

## 🎯 Quick Start (5 minutes)

### Step 1: Clone to Claude Skills Folder

All developers must have the git repo available at `~/.claude/skills/ls-wp-db-migrate/`:

```bash
# Clone the repo to your Claude skills folder
cd ~/.claude/skills/
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git wp-db-migrate
cd wp-db-migrate

# Verify all dependencies
./scripts/setup-dependencies.sh --verbose

# Auto-install if needed
./scripts/setup-dependencies.sh --install
```

### Step 2: Install the Plugin (Optional)

You can also install as a Claude Plugin for easier access:

1. Open Claude
2. Go to Settings → Plugins
3. Search for **wp-db-migrate** in the LightSpeed plugin list
4. Click Install
5. Test with: `/wp-migrate-clone-to-studio --help`

**Note:** The git repo at `~/.claude/skills/ls-wp-db-migrate/` is required regardless of plugin installation. CLI commands reference it.

### Step 3: Follow Onboarding Checklist

Open: `~/.claude/skills/ls-wp-db-migrate/docs/ONBOARDING-CHECKLIST.md`

This walks you through:

- ✅ Dependency verification
- ✅ Project setup
- ✅ Running tests
- ✅ Understanding the workflow
- ✅ Team integration

**Time:** 30-45 minutes to complete

---

## 📖 Essential Reading (in order)

1. **[Setup Requirements](setup-requirements.md)** (5 min)
   - System requirements
   - What tools you need (wp-cli, studio-cli, etc.)
   - Dependency verification

2. **[Getting Started](getting-started.md)** (5 min)
   - Your first migration in 5 minutes
   - 5-stage workflow overview
   - Command examples

3. **[Best Practices](best-practices.md)** (15 min)
   - Safe migration strategies
   - Backup procedures
   - When to use dry-run mode
   - Production database safety

4. **[FAQ](faq.md)** (10 min)
   - 30+ common questions answered
   - Quick reference guide

5. **[Troubleshooting](troubleshooting.md)** (when needed)
   - Common errors and solutions
   - Recovery procedures

---

## 🔧 Critical Tools You Need

These must be installed **globally** on your machine:

### 1. WordPress Studio (Latest)

```bash
# Download latest from https://developer.wordpress.com/studio/
# Or install via script:
curl -fsSL https://wordpress.studio/install.sh | bash
```

**Why:** Local WordPress development environment  
**Important:** Keep it up to date for compatibility

### 2. WP-CLI (WordPress Command Line)

```bash
brew install wp-cli
```

**Why:** Database export/import and site management  
**Crucial:** wp-db-migrate uses this for all database operations

### 3. Studio CLI

```bash
# Included with WordPress Studio
studio --version
```

**Why:** Manage local WordPress Studio sites  
**Crucial:** Handles the import and validation steps

### 4. SSH Key Setup (for remote databases)

```bash
# Generate if you don't have one:
ssh-keygen -t ed25519 -C "your-email@lightspeed.agency"

# Add to remote server:
ssh-copy-id -i ~/.ssh/your-key user@staging.example.com

# Test connection:
ssh -i ~/.ssh/your-key user@staging.example.com
```

**Why:** Export databases from staging/production servers  
**Crucial:** Required for remote database migration

---

## 🛠️ Common Workflows

### Workflow 1: Clone Staging to Local Development

```bash
# 1. Create a WordPress Studio site
studio create my-project

# 2. Run migration (interactive)
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://staging.example.com" \
  "https://my-project.local"

# 3. Site is ready with staging data
studio open my-project
```

### Workflow 2: Export from Remote Server

```bash
# Uses SSH to export directly from production/staging
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://example.com" \
  "https://my-project.local" \
  --ssh-host staging.example.com \
  --ssh-user deploy \
  --ssh-key ~/.ssh/deploy_key
```

### Workflow 3: Reduce Large Database

For large databases (>500MB), you can:

**Option A: Scan and propose reductions**

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Ask wp-db-migrate to analyze and suggest reductions
./scripts/preflight-check.sh

# Then specify exclusions:
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_postmeta,wp_actionscheduler_logs,wp_cache
```

**Option B: Use pre-configured profiles**

```bash
# Copy team config with optimized settings
cp .wp-db-migrate.conf.sample .wp-db-migrate.conf

# Edit to your needs:
# EXCLUDE_TABLES=wp_postmeta,wp_actionscheduler_logs
# COMPRESS=true
# PARALLEL_JOBS=4
```

**Option C: Dry-run first to see what will be removed**

```bash
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/.studio/sites/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_postmeta
```

See: **[Large Database Handling Guide](large-databases.md)** for detailed strategies

---

## 🔗 Integration with LightSpeed Hosting Tools & WordPress Skills

### Complete Workflow: Production → Local → Staging

wp-db-migrate works with **ls-hosting-*** skills for complete end-to-end workflows:

**Step 1: Extract from Production (use ls-hosting)**

```bash
/ls-hosting-sync-live-to-staging    # Get database backup
/ls-hosting-fetch-tools             # Get plugins/themes
```

**Step 2: Migrate Locally (use wp-db-migrate)**

```bash
cd ~/.claude/skills/ls-wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local"
```

**Step 3: Configure & Develop (use WordPress agent skills)**

```bash
# For WordPress-specific development help
/wp-plugin-development      # Plugin architecture
/wp-block-development       # Gutenberg blocks
/wp-wpcli-and-ops          # WP-CLI operations
```

**Step 4: Deploy Changes (use ls-hosting)**

```bash
/ls-hosting-deploy-full-site        # Deploy to staging
/ls-hosting-sync-content            # Sync to production
```

See: **[ls-hosting Integration Guide](ls-hosting-integration.md)** for complete workflow details

---

## 💡 What You Need to Know: Basics

### 1. WordPress Studio Sites

- Each developer should have WordPress Studio sites for local work
- Sites are isolated SQLite databases (not MySQL)
- wp-db-migrate converts MySQL → SQLite automatically

### 2. The 5-Stage Workflow

```
Stage 1: Export Database
  └─ From MySQL/MariaDB (remote or local)

Stage 2: Sanitize
  └─ Remove MySQL-only syntax, exclude large tables

Stage 3: Import
  └─ Into WordPress Studio (SQLite)

Stage 4: Replace URLs
  └─ Production URL → localhost URL

Stage 5: Validate
  └─ Verify integrity, load test, count checks
```

### 3. Dry-Run Mode (Always Use First)

```bash
--dry-run    # Preview without making changes
```

This shows exactly what will happen without committing.

### 4. Backup & Recovery

- Automatic backup created before import
- Auto-rollback on failure
- Manual recovery possible anytime

### 5. Performance Tuning

```bash
--jobs 4           # Parallel processing (adjust based on CPU)
--no-compress      # Skip compression (if network is fast)
--exclude-tables   # Skip large tables (logs, cache, etc.)
```

---

## ❓ Common Questions (Quick Answers)

**Q: Is it safe to run on production data?**  
A: No. Always export during off-hours, test on fresh sites first.

**Q: What if the import times out?**  
A: Data usually imports fine anyway. Run `verify-import.sh` to check.

**Q: Can I rollback after importing?**  
A: Yes. Backup is created before import.

**Q: Should I exclude logging tables?**  
A: Yes. `wp_actionscheduler_logs` is safe to exclude and speeds up.

**Q: How do I reduce a 5GB database to manageable size?**  
A: See: [Large Database Handling Guide](large-databases.md)

See: **[Full FAQ](faq.md)** for 30+ questions

---

## 📋 Best Practices Summary

✅ **Always** use dry-run first  
✅ **Always** backup before import  
✅ **Always** verify post-import  
✅ **Don't** migrate during production hours  
✅ **Don't** trust untested migrations  
✅ **Do** exclude non-essential tables  
✅ **Do** use compression for large databases  
✅ **Do** verify your SSH setup before remote export

Full guide: **[Best Practices](best-practices.md)**

---

## 🆘 Troubleshooting Quick Links

- **SSH connection failed?** → [Troubleshooting: SSH](troubleshooting.md#ssh-connection-issues)
- **Import failed?** → [Troubleshooting: Import](troubleshooting.md#database-import-failed)
- **Slow migration?** → [Troubleshooting: Performance](troubleshooting.md#migration-is-too-slow)
- **URL replacement issues?** → [Troubleshooting: URLs](troubleshooting.md#url-replacement-issues)
- **Still stuck?** → [Full Troubleshooting Guide](troubleshooting.md)

---

## 🧠 WordPress Agent Skills Available

Your team now has **WordPress agent skills** installed globally at `~/.claude/skills/wordpress-agent/`. Use these when working on WordPress code:

- **`/wp-plugin-development`** — Plugin architecture, hooks, security, settings API
- **`/wp-block-development`** — Gutenberg blocks, block.json, deprecations
- **`/wp-block-themes`** — Block themes, theme.json, templates, patterns
- **`/wp-rest-api`** — REST API routes, endpoints, authentication
- **`/wp-wpcli-and-ops`** — WP-CLI commands, multisite, automation
- **`/wp-performance`** — Performance profiling, caching, optimization
- **And 10+ more skills** — See `~/.claude/skills/wordpress-agent/README.md`

These skills help Claude give you **WordPress-expert guidance** directly in your IDE or Claude, following current best practices.

## 🎓 Getting Help

1. **Check [FAQ](faq.md)** — Answers 30+ common questions
2. **Read [Troubleshooting](troubleshooting.md)** — Problem-solving guide
3. **Run setup check** — `./scripts/setup-dependencies.sh --verbose`
4. **Use WordPress skills** — `/wp-plugin-development`, `/wp-block-development`, etc.
5. **Ask your team lead** — Your team has setup experience
6. **Check [ls-hosting Integration](ls-hosting-integration.md)** — Complete workflow guide

---

## 📚 Full Documentation

- [Documentation Hub](README-GUIDE.md) — All guides organized
- [Setup Requirements](setup-requirements.md) — Dependencies & system setup
- [Team Installation](TEAM-INSTALLATION.md) — Install for your team
- [Onboarding Checklist](ONBOARDING-CHECKLIST.md) — Step-by-step setup
- [Getting Started](getting-started.md) — First migration guide
- [Best Practices](best-practices.md) — Safe strategies
- [Advanced Usage](advanced.md) — Power features
- [Reliability Guide](reliability.md) — Error recovery
- [Analytics Guide](analytics.md) — Performance tracking
- [Configuration Guide](configuration.md) — Setup & profiles
- [FAQ](faq.md) — Common questions
- [Troubleshooting](troubleshooting.md) — Problem solving

---

## ✅ Your First 30 Minutes

1. **Clone to skills folder** (2 min)

   ```bash
   cd ~/.claude/skills/
   git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git wp-db-migrate
   ```

2. **Verify setup** (5 min)
   - Run: `cd ~/.claude/skills/ls-wp-db-migrate && ./scripts/setup-dependencies.sh --verbose`

3. **Install plugin (optional)** (3 min)
   - Settings → Plugins → Add wp-db-migrate (for easier access in Claude)

4. **Read essentials** (15 min)
   - Setup Requirements → Getting Started → Best Practices

5. **Follow checklist** (5 min)
   - Run: `~/.claude/skills/ls-wp-db-migrate/docs/ONBOARDING-CHECKLIST.md`

**Then:** You're ready for your first migration!
**Bonus:** Try `/wp-plugin-development` in Claude for WordPress help!

---

## 🚀 Next Steps

- [ ] Install the plugin from LightSpeed list
- [ ] Run setup verification script
- [ ] Follow onboarding checklist
- [ ] Read Getting Started guide
- [ ] Test with a non-critical database
- [ ] Read your team's setup documentation

---

**Questions?** Ask your team lead or check the [Documentation Hub](README-GUIDE.md)

**Ready to migrate?** Start with [Getting Started](getting-started.md)

**Need help?** See [Troubleshooting](troubleshooting.md)

---

**Version:** 1.1.0  
**Last Updated:** October 2026  
**Maintained by:** LightSpeed Development Team
