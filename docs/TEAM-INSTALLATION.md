# Team Installation Guide

Get the WordPress Database Migration tool installed in Claude for your entire team in under 5 minutes.

## Overview

This guide covers three installation methods:

1. **Claude Skill** (project-level) — Recommended for team projects
2. **Claude Plugin** (global) — For individual machines
3. **CLI Scripts Only** (no Claude) — For build automation

Choose based on your team's setup.

---

## Method 1: As a Claude Skill (Project-Level)

**Best for:** Teams working on the same project, version control, shared configuration.

### Step 1: Copy the Skill to Your Project

#### Option A: Clone the Repository

```bash
# From your project root
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git

# Or add as a submodule (recommended for git projects)
git submodule add https://github.com/lightspeedwp/ls-wp-db-migrate.git skills/wp-db-migrate
```

#### Option B: Use Symlink (macOS/Linux)

```bash
# Link from your .claude/skills/ folder
ln -s /path/to/wp-db-migrate/skill ~/.claude/skills/ls-wp-db-migrate
```

#### Option C: Copy to Your Project

```bash
# Copy the skill folder to your project
cp -r wp-db-migrate/skill /path/to/your/project/.claude/skills/
```

### Step 2: Enable in Claude Code Settings

1. **Open Claude Code** with your project
2. **Open Settings** (gear icon in the sidebar)
3. **Look for "Skills"** section
4. **Find "wp-db-migrate"** in the list
5. **Toggle it on** (enable)
6. **Reload** the Code tab (Cmd+R or Ctrl+R)

### Step 3: Verify Installation

Test that it's working:

```bash
# In Claude Code terminal
./wp-migrate-clone-to-studio.sh --help
```

**You should see:**

```
WordPress Database Migration Tool
Usage: ./wp-migrate-clone-to-studio.sh --from URL --to PATH [OPTIONS]
...
```

### Sharing with Team

Once installed in your project:

```bash
# Commit to git
git add .claude/skills/wp-db-migrate
git commit -m "Add wp-db-migrate skill for team"
git push

# Team members pull and enable in their Claude Code settings
```

**For each team member:**

1. Pull the latest code (`git pull`)
2. Open Claude Code
3. Enable skill in Settings
4. Test with `--help` command

---

## Method 2: As a Claude Plugin (Individual Installation)

**Best for:** Personal use, entire macOS setup, all your projects.

### Step 1: Get the Plugin URL

```bash
# Get the plugin directory
echo "$HOME/.claude/plugins/marketplaces/lightspeedwp/wp-db-migrate"

# Or from the GitHub repository
# https://github.com/lightspeedwp/ls-wp-db-migrate/plugin
```

### Step 2: Install in Claude

1. **Open Claude** (chat or code)
2. **Go to Settings** (gear icon)
3. **Look for "Plugins" or "Integrations"**
4. **Click "Add Plugin from GitHub"** or **"Install Plugin"**
5. **Paste the GitHub URL:**
   ```
   https://github.com/lightspeedwp/ls-wp-db-migrate
   ```
6. **Follow the installation prompts**
7. **Restart Claude**

### Step 3: Use in Claude

Once installed, use anywhere:

```
In any Claude chat:
/wp-migrate-clone-to-studio --from https://example.com --to ~/Studio/site

Or for help:
/wp-migrate-clone-to-studio --help
```

### Updating to Latest Version

```bash
# Check for updates
# In Claude → Settings → Plugins → wp-db-migrate → Check for Updates

# Or manually reinstall
# Remove the old version and reinstall following Step 1-2 above
```

---

## Method 3: CLI Scripts Only (No Claude)

**Best for:** CI/CD automation, servers, standalone usage.

### Step 1: Download Scripts

```bash
# Clone the repository
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git

# Or download specific scripts
curl -O https://raw.githubusercontent.com/lightspeedwp/wp-db-migrate/main/scripts/wp-migrate-clone-to-studio.sh
curl -O https://raw.githubusercontent.com/lightspeedwp/wp-db-migrate/main/scripts/lib-*.sh
```

### Step 2: Make Executable

```bash
chmod +x wp-migrate-clone-to-studio.sh
chmod +x lib-*.sh
```

### Step 3: Add to PATH (Optional)

```bash
# Add to your PATH so you can run from anywhere
export PATH="$PATH:/path/to/wp-db-migrate/skill/scripts"

# Or copy to /usr/local/bin
sudo cp scripts/*.sh /usr/local/bin/
```

### Step 4: Use Directly

```bash
# Run from any directory
./wp-migrate-clone-to-studio.sh --from URL --to PATH

# Or if in PATH
wp-migrate-clone-to-studio.sh --from URL --to PATH
```

---

## Dependencies Check

Before using the tool, make sure you have:

### Required on Your Machine

- ✅ **WordPress Studio** — [Download](https://developer.wordpress.com/studio/)
- ✅ **wp-cli** — `brew install wp-cli` (macOS) or [Install guide](https://wp-cli.org/)
- ✅ **gzip** — Usually pre-installed
- ✅ **bash** — macOS/Linux have this by default

### Required on Remote Server (for SSH export)

- ✅ **SSH access** — To your staging/production server
- ✅ **wp-cli** — Installed on the remote server
- ✅ **WP-CLI rights** — User can run `wp db export`

### Quick Dependency Check

```bash
# Run this to verify everything is installed
./scripts/preflight-check.sh

# Output will show:
# ✓ WordPress Studio installed
# ✓ wp-cli installed
# ✓ gzip available
# ✓ SSH configured (if using SSH export)
```

---

## Team First-Time Setup Checklist

### For Your Project Lead

- [ ] Choose installation method (Method 1 recommended for teams)
- [ ] Set up the skill in `.claude/skills/` or project `.github/skills/`
- [ ] Create a `.wp-db-migrate.conf` config file with shared settings
- [ ] Document team workflows and best practices
- [ ] Run preflight check to verify all dependencies
- [ ] Do a test migration from staging to make sure everything works
- [ ] Document the URL patterns and server credentials needed
- [ ] Create team documentation with your specific setup

### For Each Team Member

- [ ] Pull the latest code (includes the skill)
- [ ] Enable the skill in Claude Code settings
- [ ] Run preflight check: `./scripts/preflight-check.sh`
- [ ] Test with: `./wp-migrate-clone-to-studio.sh --help`
- [ ] Do a dry-run test: `./wp-migrate-clone-to-studio.sh --dry-run --from URL --to ~/Studio/test`
- [ ] Read [Getting Started](getting-started.md) guide

---

## Troubleshooting Installation

### "Skill not appearing in Settings"

1. Make sure the skill is in the correct directory:

   ```bash
   ls ~/.claude/skills/ls-wp-db-migrate/
   ```

2. Restart Claude Code (Cmd+R or Ctrl+R)

3. Check the skill folder structure:
   ```bash
   # Should have SKILL.md at minimum
   ls ~/.claude/skills/ls-wp-db-migrate/
   SKILL.md
   scripts/
   plugin/
   ```

### "Command not found when running script"

1. Make sure it's executable:

   ```bash
   chmod +x wp-migrate-clone-to-studio.sh
   ```

2. Run with full path:

   ```bash
   ./wp-migrate-clone-to-studio.sh --help
   ```

3. Or add to PATH:
   ```bash
   export PATH="$PATH:$(pwd)/skill/scripts"
   ```

### "preflight-check.sh shows missing dependencies"

Install missing tools:

**WordPress Studio:**

- Download from [WordPress Studio official site](https://developer.wordpress.com/studio/)

**wp-cli:**

```bash
# macOS
brew install wp-cli

# Linux
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
```

**SSH Access:**

```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa user@staging.example.com 'echo Connected'
```

### "Claude isn't recognizing the skill"

1. Clear Claude's cache:
   - Close Claude completely
   - Delete `~/.claude/` (or just clear the cache folder)
   - Reopen Claude

2. Reinstall the skill:

   ```bash
   rm -rf ~/.claude/skills/ls-wp-db-migrate
   git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git
   ln -s $(pwd)/wp-db-migrate/skill ~/.claude/skills/ls-wp-db-migrate
   ```

3. Reload Claude

---

## Next Steps

Once installed and working:

1. **Read [Getting Started](getting-started.md)** — 5-minute quick start
2. **Review [Best Practices](best-practices.md)** — Safe migration strategies
3. **Set up config file** — See [Configuration Guide](configuration.md)
4. **Run your first migration** — Try a staging → local clone
5. **Check [Reliability Guide](reliability.md)** — Understand error recovery
6. **Review [Analytics Guide](analytics.md)** — Understand performance reports

---

## Team Communication

### Share with Your Team

Copy this message to your team Slack/email:

```
The WordPress Database Migration tool (wp-db-migrate) is now available!

Install in Claude Code by:
1. Enable the skill in Settings → Skills → wp-db-migrate
2. Test with: ./wp-migrate-clone-to-studio.sh --help

Then follow the Getting Started guide: [link to docs/GETTING-STARTED.md]

For questions, see the FAQ: [link to docs/FAQ.md]
```

### Setup Meeting

1. Walk through the installation steps together
2. Each person verifies with `preflight-check.sh`
3. Everyone runs a test dry-run migration
4. Demo a real migration from staging
5. Answer questions and set up team workflows

---

## Common Team Workflows

### Workflow: Sync Staging to Local Daily

**Setup once:**

```bash
# Create a config file with your settings
cat > .wp-db-migrate.conf <<EOF
FROM_URL=https://staging.example.com
TO_PATH=~/Studio/project
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EOF
```

**Run daily:**

```bash
./wp-migrate-clone-to-studio.sh --use-config
```

### Workflow: Onboard New Team Members

1. **Create fresh Studio site**

   ```bash
   studio create project-clone
   ```

2. **Run migration**

   ```bash
   ./wp-migrate-clone-to-studio.sh \
     --from https://staging.example.com \
     --to ~/Studio/project-clone
   ```

3. **Verify**
   ```bash
   cd ~/Studio/project-clone
   studio open project-clone
   ```

---

## Getting Help

- **Installation issues?** → See troubleshooting section above
- **Usage questions?** → See [FAQ](faq.md)
- **Errors during migration?** → See [Troubleshooting](troubleshooting.md)
- **Want to optimize?** → See [Best Practices](best-practices.md)
- **Need recovery help?** → See [Reliability Guide](reliability.md)

---

**Ready to migrate?** Once installed, start with `./wp-migrate-clone-to-studio.sh --help` to see all options.
