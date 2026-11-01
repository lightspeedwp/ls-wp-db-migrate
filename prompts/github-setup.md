# GitHub Backup Setup — Structured Prompts

Intelligent prompts for handling database backups stored in GitHub repositories.

## When User Mentions GitHub

User says something like:

- "I have a backup in GitHub"
- "The export is in a private repo"
- "Can you pull from GitHub?"
- "The backup is at github.com/org/repo"

## Structured Information Gathering

Gather these fields in order:

### 1. Repository URL

````bash
Question: "What's the repository URL?"
Expected: https://github.com/org/repo
Examples:
  - https://github.com/lightspeedwp/backup-archive
  - https://github.com/myteam/wordpress-exports
Pattern: https://github.com/<owner>/<repo>
```bash

### 2. Branch/Reference (Optional)
```bash
Question: "Which branch? (default: main)"
Expected: main, develop, releases, etc.
Smart Default: 'main' (most common)
Pattern: Detect if not provided
```bash

### 3. File Path in Repository
```bash
Question: "Where's the backup file?"
Expected: backups/production.sql.gz
Examples:
  - backups/prod-2026-10-29.sql.gz
  - exports/database.sql
  - releases/v2.0/backup.sql.zip
Pattern: Support wildcards: backups/*.sql.gz
```bash

### 4. Authentication (If Private)
```bash
Question: "Is this a private repository?"
Logic:
  - Public: Use HTTPS clone
  - Private: Ask for auth method
    - "SSH key available?" → Use SSH
    - "GitHub PAT?" → Use HTTPS with token
Options:
  - Skip (assumes public)
  - SSH
  - GitHub Personal Access Token
  - GitHub App token
```bash

## Smart Detection

Automatically handle variations:

```bash
# Detect if already public
curl -s https://api.github.com/repos/<owner>/<repo> \
  | jq '.private' # false = public

# Find backup files automatically
# Search for: *.sql, *.sql.gz, *.sql.zip, *.sql.bz2

# Detect file size to estimate complexity
curl -s https://api.github.com/repos/<owner>/<repo>/contents/<path> \
  | jq '.size'
```bash

## Automation Script

Create: `skill/scripts/github-backup-setup.sh`

```bash
#!/bin/bash
# github-backup-setup.sh
# Handles GitHub backup repository setup

REPO_URL="${1:-}"
BRANCH="${2:-main}"
FILE_PATH="${3:-}"
AUTH_METHOD="${4:-auto}"

show_usage() {
    cat << 'EOF'
GitHub Backup Setup

USAGE:
  ./github-backup-setup.sh <repo-url> [branch] [file-path] [auth]

ARGUMENTS:
  repo-url       GitHub repository URL
  branch         Branch name (default: main)
  file-path      Path to backup file in repo
  auth           Authentication: auto|ssh|https|token

EXAMPLES:
  # Public repo with auto-detection
  ./github-backup-setup.sh https://github.com/org/repo backups/prod.sql.gz

  # Private repo with SSH
  ./github-backup-setup.sh https://github.com/org/repo main \
    backups/production.sql.gz ssh

  # Private repo with PAT
  ./github-backup-setup.sh https://github.com/org/repo main \
    releases/backup.sql.gz token
EOF
}

if [ -z "$REPO_URL" ]; then
    show_usage
    exit 1
fi

# Parse repo URL
OWNER=$(echo "$REPO_URL" | cut -d'/' -f4)
REPO=$(echo "$REPO_URL" | cut -d'/' -f5 | sed 's/.git$//')

echo "📦 GitHub Backup Setup"
echo "Repository: $OWNER/$REPO"
echo "Branch: $BRANCH"
echo ""

# Step 1: Check if public
echo "🔍 Checking repository access..."

REPO_INFO=$(curl -s "https://api.github.com/repos/$OWNER/$REPO")
IS_PRIVATE=$(echo "$REPO_INFO" | jq -r '.private // false')

if [ "$IS_PRIVATE" = "true" ]; then
    echo "🔒 Private repository detected"

    if [ "$AUTH_METHOD" = "auto" ]; then
        if [ -f ~/.ssh/id_rsa ]; then
            AUTH_METHOD="ssh"
            echo "✅ SSH key found, using SSH auth"
        elif [ -n "$GITHUB_TOKEN" ]; then
            AUTH_METHOD="https"
            echo "✅ GITHUB_TOKEN found, using token auth"
        else
            echo "⚠️  Private repo but no auth method found"
            echo "Set GITHUB_TOKEN or configure SSH key"
            exit 1
        fi
    fi
else
    echo "✅ Public repository"
    AUTH_METHOD="https"
fi

echo ""
echo "📥 Cloning repository (depth=1 for speed)..."

# Step 2: Clone repository
CLONE_URL="$REPO_URL"
if [ "$AUTH_METHOD" = "ssh" ]; then
    # Convert HTTPS to SSH
    CLONE_URL=$(echo "$REPO_URL" | sed 's#https://github.com/#git@github.com:#' | sed 's#/$##')
fi

# Clone with depth 1 (only last commit, faster)
if ! git clone "$CLONE_URL" /tmp/wp-backup-repo \
    --branch "$BRANCH" \
    --depth 1 \
    --single-branch 2>&1 | grep -v "Cloning"; then
    echo "❌ Failed to clone repository"
    exit 1
fi

echo "✅ Repository cloned"
echo ""

# Step 3: Find backup file
if [ -z "$FILE_PATH" ]; then
    echo "🔎 Searching for backup files..."

    # Search for backup files
    FOUND_FILES=$(find /tmp/wp-backup-repo \
        -type f \( -name "*.sql" -o -name "*.sql.gz" -o -name "*.sql.zip" -o -name "*.sql.bz2" \) \
        | head -10)

    if [ -z "$FOUND_FILES" ]; then
        echo "❌ No backup files found"
        echo ""
        echo "Files in repository:"
        ls -lh /tmp/wp-backup-repo | head -20
        exit 1
    fi

    # Use first found file
    FILE_PATH=$(echo "$FOUND_FILES" | head -1 | sed "s|/tmp/wp-backup-repo/||")
    echo "✅ Found backup: $FILE_PATH"
else
    if [ ! -f "/tmp/wp-backup-repo/$FILE_PATH" ]; then
        echo "❌ File not found: $FILE_PATH"
        echo ""
        echo "Available files:"
        find /tmp/wp-backup-repo -type f -name "*.sql*" | sed "s|/tmp/wp-backup-repo/||"
        exit 1
    fi
    echo "✅ File verified: $FILE_PATH"
fi

echo ""

# Step 4: Get file info
FULL_PATH="/tmp/wp-backup-repo/$FILE_PATH"
FILE_SIZE=$(du -h "$FULL_PATH" | cut -f1)

echo "📊 Backup File Information:"
echo "Path:      $FILE_PATH"
echo "Size:      $FILE_SIZE"
echo "Location:  $FULL_PATH"
echo ""

# Step 5: Return paths for next steps
echo "✅ Setup complete"
echo ""
echo "Export these for the next step:"
echo "export BACKUP_FILE='$FULL_PATH'"
echo "export BACKUP_SIZE='$FILE_SIZE'"
echo "export BACKUP_REPO='/tmp/wp-backup-repo'"
echo ""
echo "Ready to migrate. Next step:"
echo "  ../create-and-migrate.sh <site-name> '$FULL_PATH' <old-url> <new-url>"
echo ""
echo "Don't forget to cleanup:"
echo "  rm -rf /tmp/wp-backup-repo"
```bash

## One-Command Workflow

```bash
# All in one (if you want the skill to handle it)
./github-backup-setup.sh <repo> <branch> <file-path> | \
  source /dev/stdin && \
  ../create-and-migrate.sh my-site "$BACKUP_FILE" old.com new.local && \
  rm -rf "$BACKUP_REPO"
```bash

## Error Handling

### File Not Found
```bash
❌ File not found: backups/prod.sql.gz

Available files:
  - backups/production-2026-10-29.sql.gz
  - backups/staging-2026-10-28.sql.gz
  - exports/archive-2026-10-27.sql.zip

Did you mean: production-2026-10-29.sql.gz?
```bash

### Auth Failed
```bash
❌ Authentication failed

Private repository requires authentication.
Options:
  1. Set GITHUB_TOKEN environment variable
  2. Configure SSH key (ssh-keygen)
  3. Use GitHub App token
```bash

### Size Detection
```bash
📊 Large backup detected: 850 MB

⚠️  This might take 5-10 minutes to:
  1. Clone repository
  2. Extract backup
  3. Migrate database

Continue? (yes/no)
```bash

## Integration with Skill

The skill will offer this automatically:

```bash
User: "I have a backup in GitHub"

Skill: "Perfect! Let me help you set that up.

📋 I'll need:
   1. Repository URL
   2. Backup file location
   3. Authentication (if private)

Where's your backup?"
```bash

Then it can:
1. ✅ Run `github-backup-setup.sh` with answers
2. ✅ Use returned file path in `create-and-migrate.sh`
3. ✅ Auto-detect complexity from file size
4. ✅ Set appropriate task budget

---

**Status:** Ready to integrate
**Time to Implement:** ~30 minutes
**User Time Saved:** ~3 minutes per migration
````
