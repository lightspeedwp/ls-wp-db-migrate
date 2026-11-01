# Setup Requirements & Dependencies

Complete guide for setting up wp-db-migrate on your development machine.

## Quick Start (macOS)

```bash
# 1. Clone wp-db-migrate to ~/.claude/skills/
cd ~/.claude/skills/
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git wp-db-migrate
cd wp-db-migrate

# 2. Verify dependencies
./scripts/setup-dependencies.sh --verbose

# 3. Install missing dependencies (optional)
./scripts/setup-dependencies.sh --install

# 4. Run preflight check
./scripts/preflight-check.sh

# 5. Test your setup
./scripts/migrate-recovery.sh --help
```

## System Requirements

### Operating System

- **macOS 10.15+** (Catalina or later)
- **Linux** (Ubuntu 18.04+, Debian 9+)
- **Windows** (WSL 2 with Ubuntu)

### Hardware

- **Disk Space**: 10 GB minimum (for databases during migration)
- **RAM**: 4 GB minimum (8 GB recommended for large databases)
- **Network**: Stable connection (for SSH export from remote servers)

## Required Dependencies

### 1. Core Shell Tools

| Tool     | Version | Purpose         | Install                |
| -------- | ------- | --------------- | ---------------------- |
| **Bash** | 3.0+    | Script runtime  | `brew install bash`    |
| **Gzip** | 1.3+    | Compression     | Pre-installed on macOS |
| **Git**  | 2.0+    | Version control | `brew install git`     |

### 2. WordPress Studio (Critical)

**Required for**: Database import into SQLite

```bash
# Install from: https://developer.wordpress.com/studio/
# Or via script:
curl -fsSL https://wordpress.studio/install.sh | bash
```

**Verify installation:**

```bash
studio --version
# or check for application in ~/Applications/WordPress Studio.app
```

### 3. WordPress CLI (wp-cli)

**Required for**: Database operations (export, validation, URL replacement)

```bash
# Install via Homebrew
brew install wp-cli

# Verify installation
wp --version

# Test with WordPress Studio site
cd ~/.studio/sites/your-site
wp db tables
```

### 4. SSH Client & Keys

**Required for**: Remote database export via SSH

```bash
# SSH is pre-installed on macOS
ssh --version

# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your-email@example.com"
# or for older systems:
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Test SSH connection to your server
ssh -i ~/.ssh/your-key user@your-server.com 'echo Connected'
```

**SSH Key Setup:**

1. Generate a key pair (see above)
2. Copy public key to remote server: `ssh-copy-id -i ~/.ssh/your-key user@your-server.com`
3. Store private key securely: `chmod 600 ~/.ssh/your-key`
4. Add to 1Password for team access

## Recommended Dependencies

### 1. Database Clients

**MySQL/MariaDB Client** — For advanced database debugging

```bash
brew install mysql-client
mysql --version
```

**SQLite3** — For direct SQLite database inspection

```bash
brew install sqlite
sqlite3 --version
```

### 2. Development Tools

**Node.js & NPM** — For testing and validation

```bash
brew install node
node --version
npm --version
```

**ShellCheck** — For shell script linting

```bash
brew install shellcheck
shellcheck --version
```

## LightSpeed Team Setup

Based on the **LightSpeed Mac Setup Guide**, ensure you have:

### Security & Credentials

- ✅ 1Password installed and configured
- ✅ SSH keys generated and stored in 1Password
- ✅ GitHub SSH keys configured (`ssh-keygen`, `ssh-add`)

### Development Environment

- ✅ Homebrew installed and up to date: `brew update && brew doctor`
- ✅ Git configured: `git config user.name` and `git config user.email`
- ✅ Xcode Command Line Tools: `xcode-select --install`

### AI & Code Review

- ✅ Claude Desktop app installed (for Skill integration)
- ✅ VS Code or VS Code Insiders (for development)
- ✅ GitHub Copilot (optional, complements wp-db-migrate)

### Workspace

- ✅ Google Drive for Desktop configured with team drive
- ✅ Slack and Linear access for team collaboration

## Dependency Verification

### Automated Check

Run the dependency verification script to check all requirements:

```bash
# Check dependencies (no changes)
./scripts/setup-dependencies.sh

# Check with detailed output
./scripts/setup-dependencies.sh --verbose

# Automatically install missing dependencies
./scripts/setup-dependencies.sh --install
```

**Output Example:**

```
╔════════════════════════════════════════════════════════╗
║  WordPress Database Migration - Dependency Check      ║
║  Version 1.1.0                                        ║
╚════════════════════════════════════════════════════════╝

Required Core Dependencies
═══════════════════════════════════════════════════════
✓ Bash Shell (3.0+)
✓ Gzip (compression)
✓ Git (version control)

WordPress Studio (Required)
═══════════════════════════════════════════════════════
✓ WordPress Studio

WordPress CLI (Required for database operations)
═══════════════════════════════════════════════════════
✓ WP-CLI

SSH & Remote Access
═══════════════════════════════════════════════════════
✓ SSH Client
✓ SSH Key Generation
○ SSH Key Installation (optional)

Database Tools (Optional but Recommended)
═══════════════════════════════════════════════════════
✓ MySQL Client
✓ SQLite3 CLI

Developer Tools (Required for Testing & Development)
═══════════════════════════════════════════════════════
✓ Node.js
✓ NPM (Node Package Manager)
✓ ShellCheck (shell linting)

Code Editors & IDEs (Recommended)
═══════════════════════════════════════════════════════
✓ Visual Studio Code

═══════════════════════════════════════════════════════
Summary
═══════════════════════════════════════════════════════
Required Dependencies:  7 found, 0 missing
Optional Dependencies:  6 found, 1 missing

✓ All required dependencies are installed!
```

### Manual Verification

Check individual tools:

```bash
# Bash
bash --version

# Gzip
gzip --version

# Git
git --version

# WordPress Studio
studio --version

# WordPress CLI
wp --version

# SSH
ssh -V

# Node.js & NPM
node --version
npm --version

# MySQL Client (optional)
mysql --version

# SQLite3 (optional)
sqlite3 --version
```

## Troubleshooting

### "WordPress Studio not found"

**Solution 1: Check installation path**

```bash
ls -la ~/Library/Application\ Support/WordPress\ Studio
```

**Solution 2: Add to PATH**

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="$PATH:/Applications/WordPress Studio.app/Contents/bin"
source ~/.zshrc
```

**Solution 3: Reinstall**

```bash
curl -fsSL https://wordpress.studio/install.sh | bash
```

### "wp-cli not found"

**Solution 1: Install via Homebrew**

```bash
brew install wp-cli
```

**Solution 2: Install via Composer**

```bash
composer create-project wp-cli/wp-cli --no-dev
```

**Solution 3: Install standalone PHAR**

```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
```

### "SSH connection failed"

**Solution 1: Check SSH key permissions**

```bash
# SSH key should be 600 (read/write owner only)
ls -la ~/.ssh/your-key
chmod 600 ~/.ssh/your-key
```

**Solution 2: Test SSH connection**

```bash
ssh -vvv -i ~/.ssh/your-key user@your-server.com
# -vvv shows detailed debug output
```

**Solution 3: Add SSH key to agent**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/your-key
ssh user@your-server.com
```

### "wp-cli not found on remote server"

**Solution 1: Install on remote server**

```bash
ssh user@your-server.com
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp --version
```

**Solution 2: Use with full path**
If wp-cli is in a non-standard location:

```bash
./scripts/migrate-recovery.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --ssh-host example.com \
  --ssh-user deploy \
  --wp-cli-path /home/deploy/bin/wp
```

## Team Onboarding

### For New Team Members

1. **Clone the repository**

   ```bash
   git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git
   cd wp-db-migrate
   ```

2. **Run dependency check**

   ```bash
   ./scripts/setup-dependencies.sh
   ```

3. **Install missing dependencies**

   ```bash
   ./scripts/setup-dependencies.sh --install
   ```

4. **Install Node dependencies**

   ```bash
   npm install
   ```

5. **Run tests to verify setup**

   ```bash
   npm test
   ```

6. **Test the skill**
   ```bash
   ./scripts/preflight-check.sh
   ./scripts/migrate-recovery.sh --help
   ```

### For Team Leads

Share this checklist with new team members:

- [ ] Homebrew installed and updated
- [ ] Git configured (name, email)
- [ ] SSH keys generated and stored in 1Password
- [ ] WordPress Studio installed
- [ ] WP-CLI installed
- [ ] wp-db-migrate cloned locally
- [ ] Dependencies verified: `./scripts/setup-dependencies.sh`
- [ ] Tests pass: `npm test`
- [ ] Preflight check passes: `./scripts/preflight-check.sh`

## Environment Variables

Optional environment variables for advanced configuration:

```bash
# SSH Configuration
export WP_DB_MIGRATE_SSH_HOST="your-server.com"
export WP_DB_MIGRATE_SSH_USER="deploy"
export WP_DB_MIGRATE_SSH_KEY="~/.ssh/deploy_key"
export WP_DB_MIGRATE_SSH_PORT="22"

# WordPress Studio
export WP_DB_MIGRATE_STUDIO_PATH="~/Studio"

# Compression
export WP_DB_MIGRATE_COMPRESS="true"

# Parallel Processing
export WP_DB_MIGRATE_JOBS="4"

# Dry-run Mode
export WP_DB_MIGRATE_DRY_RUN="false"
```

## Continuous Integration

### GitHub Actions Setup

The test suite runs on every push and PR. Ensure your local environment matches CI:

```bash
# Run the same tests as CI
npm run test:all

# Check code quality
npm run lint
npm run format:check
```

## Support

- **Setup issues?** → Check [troubleshooting](troubleshooting.md) section
- **Dependency help?** → Run `./scripts/setup-dependencies.sh --help`
- **General questions?** → See [FAQ](faq.md)

## Next Steps

Once dependencies are verified:

1. ✅ [Read Team Installation Guide](TEAM-INSTALLATION.md) — Set up the skill/plugin
2. ✅ [Review Getting Started](getting-started.md) — Run your first migration
3. ✅ [Check Best Practices](best-practices.md) — Safe migration strategies

---

**Last Updated:** October 2026  
**Version:** 1.1.0  
**Maintenance:** Reviewed quarterly to ensure compatibility
