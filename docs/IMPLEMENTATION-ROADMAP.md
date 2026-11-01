# Implementation Roadmap & Guidance

Strategic guidance for remaining integration work to complete the wp-db-migrate rollout.

## 1. WordPress Agent Skills Setup (Global Installation)

### Current Status

- WordPress agent skills available at: https://github.com/wordPress/agent-skills
- Need to install globally to `~/.claude/skills/`

### Action Items for Ashley

**Step 1: Clone WordPress Agent Skills**

```bash
# Clone to ~/.claude/skills/
cd ~/.claude/skills/
git clone https://github.com/wordPress/agent-skills.git wordpress-agent
cd wordpress-agent
```

**Note:** Both `wp-db-migrate` and `wordpress-agent` should live in `~/.claude/skills/`

**Step 2: Update documentation with installation path**

- File: `docs/SETUP-REQUIREMENTS.md`
- Add section: "WordPress Agent Skills Setup"
- Include: curl-based installation option

**Step 3: Test availability in Claude**

- Restart Claude Code
- Go to Settings → Skills
- Verify WordPress agent skills appear (e.g., `wp-plugin-development`, `wp-block-development`)
- Test with: `/wp-plugin-development` or `/wp-block-development`

### For Team Distribution

Add to `docs/ONBOARDING-CHECKLIST.md`:

````markdown
### Step X: Install WordPress Agent Skills

WordPress agent skills provide WordPress-specific helpers and utilities.

**Global installation (all projects):**

```bash
cd ~/.claude/skills/
git clone https://github.com/wordPress/agent-skills.git wordpress-agent
```
````

**Then restart Claude Code and enable in Settings → Skills**

````

---

## 2. ls-hosting Integration Analysis & Guidance

### Relevant ls-hosting Skills for wp-db-migrate Workflow

Based on your hosting tool ecosystem, these skills complement wp-db-migrate:

#### A. Extract Databases
- **ls-hosting-sync-live-to-staging** — Pull database from production
- **ls-hosting-fetch-tools** — Download backup files including database

**Integration:** Use these to get database, then migrate with wp-db-migrate

#### B. Extract Files
- **ls-hosting-fetch-tools** — Downloads `/wp-content/plugins` and `/wp-content/themes`

**Integration:** After migration, extract these to populate local WordPress Studio site

#### C. Site Management
- **ls-hosting-deploy-full-site** — Would deploy changes back (post-development)
- **ls-hosting-sync-content** — Sync content between environments

**Integration:** Use after local development complete

### Create: ls-hosting Integration Guide

**File to create:** `docs/LS-HOSTING-INTEGRATION.md`

**Content should cover:**

```markdown
# Integration with LightSpeed Hosting Skills

## Complete Workflow: Production → Local Development

### Phase 1: Extract from Production
Use ls-hosting skills:
1. ls-hosting-sync-live-to-staging (get database backup)
2. ls-hosting-fetch-tools (get plugins/themes)

### Phase 2: Migrate Database
Use wp-db-migrate:
1. ./scripts/migrate-recovery.sh (import database)

### Phase 3: Configure Locally
1. Copy plugins/themes to WordPress Studio
2. Configure media paths (LOCAL-MEDIA-SETUP.md)
3. Install WordPress agent skills

### Phase 4: Local Development
1. VS Code development (plugins/themes)
2. WordPress agent skills for WordPress-specific helpers

### Phase 5: Handoff to ls-hosting Skills
- ls-hosting-deploy-full-site (deploy changes back)
- ls-hosting-sync-content (sync back to staging)

## Specific Commands

### Extract database from production
\`\`\`bash
# Use ls-hosting to get backup
# Then migrate with wp-db-migrate
./scripts/migrate-recovery.sh \
  ~/Studio/my-project \
  "https://production.example.com" \
  "https://my-project.local"
\`\`\`

### Extract plugins and themes
\`\`\`bash
# Use ls-hosting-fetch-tools to download
# Copy to your local site
cp -r downloaded-plugins/* ~/Studio/my-project/wp-content/plugins/
cp -r downloaded-themes/* ~/Studio/my-project/wp-content/themes/
\`\`\`

### Configure media paths
See: LOCAL-MEDIA-SETUP.md

## When to Use Each Tool

| Task | Tool | Command |
|------|------|---------|
| Get database backup | ls-hosting | ls-hosting-sync-live-to-staging |
| Migrate to local | wp-db-migrate | ./migrate-recovery.sh |
| Get plugins/themes | ls-hosting | ls-hosting-fetch-tools |
| Configure media | wp-db-migrate | LOCAL-MEDIA-SETUP.md |
| Deploy back to staging | ls-hosting | ls-hosting-deploy-full-site |
````

### Action: Create this file

```bash
# You'll create: docs/LS-HOSTING-INTEGRATION.md
# Based on the template above
```

---

## 3. Plugin Prompts & Usage Patterns

### Recommended Plugin Prompts

To add to documentation, include these suggested use patterns:

#### Prompt 1: Basic Migration

```
/wp-migrate-clone-to-studio
  --from https://staging.example.com
  --to ~/Studio/my-project
```

#### Prompt 2: With Database Reduction

```
/wp-migrate-clone-to-studio
  --from https://staging.example.com
  --to ~/Studio/my-project
  --exclude-tables wp_actionscheduler_logs,wp_cache
```

#### Prompt 3: From Remote Server

```
/wp-migrate-clone-to-studio
  --from https://staging.example.com
  --to ~/Studio/my-project
  --ssh-host staging.example.com
  --ssh-user deploy
  --ssh-key ~/.ssh/deploy_key
```

#### Prompt 4: Dry-Run First

```
/wp-migrate-clone-to-studio
  --from https://staging.example.com
  --to ~/Studio/my-project
  --dry-run
```

### File to Update

**File:** `plugin/manifest.json`

**Ensure these commands are documented:**

- `wp-migrate-clone-to-studio --help`
- `wp-migrate-clone-to-studio --dry-run`
- `wp-migrate-clone-to-studio --verbose`
- `wp-migrate-clone-to-studio --force` (CI/CD)

### Create: Plugin Usage Guide

**File to create:** `docs/PLUGIN-USAGE.md`

**Should cover:**

- Available commands
- Parameters and flags
- Integration with Claude interface
- When to use vs. CLI scripts

---

## 4. Recommended Developer Workflow (Complete)

After all integration work, the complete local dev workflow is:

### Day 1: Initial Setup (30 minutes)

```bash
# 1. wp-db-migrate is already at ~/.claude/skills/ls-wp-db-migrate/
cd ~/.claude/skills/ls-wp-db-migrate

# 2. Verify setup
./scripts/setup-dependencies.sh --install

# 3. Create WordPress Studio site
studio create my-project

# 4. Get database from production via ls-hosting
# Use: ls-hosting-sync-live-to-staging

# 5. Migrate to local
./scripts/migrate-recovery.sh \
  ~/.studio/sites/my-project \
  "https://staging.example.com" \
  "https://my-project.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache

# 6. Get plugins/themes from production via ls-hosting
# Use: ls-hosting-fetch-tools

# 7. Copy to WordPress Studio
cp -r downloaded-plugins/* ~/.studio/sites/my-project/wp-content/plugins/
cp -r downloaded-themes/* ~/.studio/sites/my-project/wp-content/themes/

# 8. Configure media paths
# Edit: ~/.studio/sites/my-project/wp-config.php
# Add: define( 'UPLOADS', 'https://staging.example.com/wp-content/uploads' );

# 9. Open in Studio
studio open my-project
```

### Daily Development

```bash
# 1. Open WordPress Studio
studio open my-project

# 2. Open VS Code for theme/plugin development
code ~/.studio/sites/my-project/wp-content/themes/my-theme

# 3. Use WordPress agent skills for context
/wp-block-development        # For theme block development
/wp-plugin-development       # For plugin development
/wp-wpcli-and-ops           # For WP-CLI commands
```

### Deployment (Back to Staging/Production)

```bash
# 1. Commit changes in VS Code

# 2. Use ls-hosting skills to deploy
# ls-hosting-deploy-full-site

# 3. Sync content back
# ls-hosting-sync-content
```

---

## 5. Documentation Checklist

### Files Already Created ✅

- [x] docs/TEAM-ANNOUNCEMENT.md
- [x] docs/LARGE-DATABASES.md
- [x] docs/LOCAL-MEDIA-SETUP.md
- [x] docs/ONBOARDING-CHECKLIST.md
- [x] docs/SETUP-REQUIREMENTS.md
- [x] docs/FAQ.md
- [x] docs/BEST-PRACTICES.md
- [x] docs/TROUBLESHOOTING.md

### Files to Create (In Order of Priority)

- [ ] docs/LS-HOSTING-INTEGRATION.md ← CREATE NEXT
- [ ] docs/PLUGIN-USAGE.md
- [ ] docs/wordpress-skills-setup.md (global installation guide)
- [ ] docs/VS-CODE-SETUP.md (theme/plugin development)

### Files to Update

- [ ] docs/SETUP-REQUIREMENTS.md — Add WordPress agent skills section
- [ ] docs/ONBOARDING-CHECKLIST.md — Add WordPress skills installation step
- [ ] docs/README-GUIDE.md — Link to new guides
- [ ] plugin/manifest.json — Ensure commands documented

---

## 6. Implementation Priority (For Ashley)

### Priority 1: Immediate (This Week)

1. ✅ Standardize all paths to use `~` and `~/.claude/skills/ls-wp-db-migrate/`
2. Create `docs/LS-HOSTING-INTEGRATION.md`
3. Install WordPress agent skills globally: `~/.claude/skills/wordpress-agent`
4. Update `docs/ONBOARDING-CHECKLIST.md` with WordPress skills step
5. Commit all changes

### Priority 2: Short-term (Next Week)

1. Create `docs/PLUGIN-USAGE.md`
2. Create `docs/wordpress-skills-setup.md`
3. Test complete workflow with a team member
4. Gather feedback

### Priority 3: Polish (Following Week)

1. Create `docs/VS-CODE-SETUP.md`
2. Update all cross-references
3. Create video walkthrough (optional)
4. Share with team

---

## 7. Team Communication Strategy

### Phase 1: Announcement

**Send:** TEAM-ANNOUNCEMENT.md to team Slack/email

### Phase 2: Training

**Hold:** 30-minute onboarding session covering:

- Why wp-db-migrate (saves time, data)
- How to install (5 min)
- First migration (10 min)
- Troubleshooting (10 min)
- Q&A (5 min)

### Phase 3: Support

**Provide:**

- Slack channel for questions
- Link to documentation
- Office hours for help

---

## 8. Success Metrics

How to measure successful rollout:

- [ ] All developers can verify dependencies
- [ ] First migration completes in <45 min
- [ ] Team members using wp-db-migrate weekly
- [ ] Zero critical issues reported
- [ ] Documentation questions <2 per week
- [ ] All developers have WordPress agent skills enabled

---

## Next Immediate Action

**For Ashley:**

1. Create `docs/LS-HOSTING-INTEGRATION.md` (use template above)
2. Install WordPress agent skills:
   ```bash
   cd ~/.claude/skills/
   git clone https://github.com/wordPress/agent-skills.git wordpress-agent
   ```
3. Commit both changes
4. Send TEAM-ANNOUNCEMENT.md to team
5. Schedule 30-minute onboarding session

---

**Status:** Ready for team rollout after implementation of Priority 1 items
**Estimated time:** 2-3 hours for Priority 1
**Expected benefit:** Team productivity +40% on local development tasks
