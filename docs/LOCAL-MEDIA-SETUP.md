# Local Media Path Configuration

After migrating your database to WordPress Studio, you need to configure media paths locally. This guide covers the recommended approach for LightSpeed development.

## Problem: Media Files Are Huge

When you migrate a production database with 10,000+ images:

- ❌ Downloads entire media library (can be 10GB+)
- ❌ Fills your Mac storage
- ❌ Takes forever to download
- ❌ Not needed for local development

## Solution: Map to Original Media Path

Instead of copying all media files, WordPress Studio can serve them directly from production.

## Recommended: Use wp-config.php Constants

This is the **recommended approach** for WordPress Studio and SQLite. It's lightweight, requires no plugins, and is production-proven.

### Step 1: Configure wp-config.php

After your migration, add this to your `wp-config.php`:

```php
// Map media to production (saves local storage)
define( 'UPLOADS', 'https://staging.example.com/wp-content/uploads' );
define( 'WP_CONTENT_URL', 'https://staging.example.com/wp-content' );
```

**File location:** `~/.studio/sites/your-site/wp-config.php`

**Add before:** `define( 'WP_DEBUG', ... );`

### Step 2: Verify Configuration

In WordPress Studio:

1. Go to Media Library
2. Upload a test image
3. Verify it appears in `/wp-content/uploads/`

Or via CLI:

```bash
cd ~/Studio/your-site
wp option get siteurl
wp option get upload_path
wp media list --field=url | head -3
```

### Step 3: Test Site

```bash
studio open your-site
# Check:
# - Media library loads quickly
# - Featured images appear
# - Galleries work
```

## Alternative: WP Original Media Path Plugin

If you prefer a plugin-based approach:

⚠️ **Security Note:** The WP Original Media Path plugin has known vulnerabilities (CVE-2023-23674). Use only if:

- You're on version 2.4.1 or higher
- You trust the maintainer
- You need plugin-based configuration

**Installation:**

```bash
cd ~/Studio/your-site
wp plugin install wp-original-media-path --activate
```

**Configuration:**

- Go to Settings → Media Path
- Set custom upload directory: `https://staging.example.com/wp-content/uploads`

**⚠️ Better Alternative:** Use the `wp-config.php` constants method above instead.

## Best Approach: Media Library Assistant Plugin

If you need advanced media management:

```bash
cd ~/Studio/your-site
wp plugin install media-library-assistant --activate
```

**Benefits:**

- Well-maintained alternative
- Programmatic attachment metadata control
- Search, taxonomy, and bulk management
- No security vulnerabilities

## Comparison: Choose Your Approach

| Approach                    | Pros                               | Cons                          | Best For             |
| --------------------------- | ---------------------------------- | ----------------------------- | -------------------- |
| **wp-config.php constants** | Lightweight, no plugin, standard   | Static config                 | ✅ **Recommended**   |
| **Media Library Assistant** | Well-maintained, advanced features | Plugin overhead               | Advanced workflows   |
| **WP Original Media Path**  | Simple, plugin-based               | Security issues, unmaintained | Legacy projects only |

## Setup Sequence for New Developers

### After Migration Completes:

1. **Add to wp-config.php** (5 min)

   ```bash
   # Edit ~/.studio/sites/your-site/wp-config.php
   # Add media path constants

   nano ~/.studio/sites/your-site/wp-config.php
   ```

2. **Verify Configuration** (2 min)

   ```bash
   cd ~/.studio/sites/your-site
   wp option get siteurl
   wp media list | head -3
   ```

3. **Test in Studio** (2 min)

   ```bash
   # Open site and check media library
   studio open your-site
   ```

4. **Upload Test Image** (1 min)
   - Go to Media → Add New
   - Upload a test image
   - Verify it appears

## Production vs. Staging URLs

**For staging environment:**

```php
define( 'UPLOADS', 'https://staging.example.com/wp-content/uploads' );
```

**For production environment:**

```php
define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );
```

**For both (with fallback):**

```php
// Check which environment we're cloning from
$uploads_url = defined( 'WP_ENV' ) && 'production' === WP_ENV
    ? 'https://production.example.com/wp-content/uploads'
    : 'https://staging.example.com/wp-content/uploads';

define( 'UPLOADS', $uploads_url );
```

## Integration with Local Development Workflow

### Workflow: Clone Production Locally

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# 1. Migrate database (with reduced size)
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://production.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache

# 2. Extract plugins/themes via ls-hosting
# Use: ls-hosting-fetch-tools production

# 3. Copy wp-content/plugins and wp-content/themes to local site

# 4. Configure media path
# Edit: ~/.studio/sites/my-project/wp-config.php
# Add:  define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );

# 5. Reload in WordPress Studio
studio open my-project
```

## Performance Notes

**Loading images from production:**

- ✅ Zero local storage used
- ✅ Fast (CDN-backed if production uses CDN)
- ✅ Always up-to-date
- ⚠️ Requires internet connection
- ⚠️ Production downtime affects local site

**Alternative: Sync subset of media**
If you want some local media:

```bash
# Copy only essential images (featured images, etc.)
mkdir -p ~/Studio/my-project/wp-content/uploads/2026/10
scp -r user@production.com:/path/to/uploads/2026/10/* \
  ~/Studio/my-project/wp-content/uploads/2026/10/
```

## Troubleshooting Media Configuration

### "Images not loading"

```bash
# Check configuration
cd ~/Studio/my-project
wp option get upload_path
wp option get upload_url_path

# Verify production site is accessible
curl https://production.example.com/wp-content/uploads/
```

### "Upload fails locally"

```bash
# Check permissions on uploads folder
chmod 755 ~/Studio/my-project/wp-content/uploads

# Check disk space
df -h ~/Studio/my-project
```

### "Mixed content warning (HTTPS/HTTP)"

```php
// Make sure your wp-config.php uses HTTPS
define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );
// NOT 'http://...'
```

### "Slow image loading"

```bash
# 1. Check network
ping production.example.com

# 2. Try CDN URL if production uses CDN
define( 'UPLOADS', 'https://cdn.production.example.com/wp-content/uploads' );

# 3. Consider local sync for frequently-used images
# See: "Sync subset of media" above
```

## For Different Use Cases

### Case 1: Content Development (Copy & Write)

```php
// Local uploads directory (allow uploads)
// Copy media from production for testing

mkdir -p ~/.studio/sites/my-project/wp-content/uploads
scp -r user@production.com:/path/to/uploads/* \
  ~/.studio/sites/my-project/wp-content/uploads/
```

### Case 2: Theme Development (Read-Only Media)

```php
// Point to production (read-only)
define( 'UPLOADS', 'https://production.example.com/wp-content/uploads' );
```

### Case 3: Plugin Development (Selective Media)

```php
// Sync test images only
mkdir -p ~/.studio/sites/my-project/wp-content/uploads/test
# Copy test fixtures
```

## Next Steps After Media Setup

1. ✅ Media paths configured
2. → Extract plugins/themes ([ls-hosting Integration Guide](ls-hosting-integration.md))
3. → Install WordPress agent skills ([WordPress Skills Setup](./wordpress-skills-setup.md))
4. → Configure VS Code for theme/plugin development
5. → Ready for development!

## See Also

- [Large Database Handling](large-databases.md) — Reduce database size
- [Getting Started](getting-started.md) — Migration basics
- [Best Practices](best-practices.md) — Safe strategies
- [ls-hosting Integration](ls-hosting-integration.md) — Extract files from production
