# Developer Onboarding Checklist: wp-db-migrate

Complete this checklist to get wp-db-migrate set up and ready to use on your machine.

**Estimated Time:** 30–45 minutes  
**Prerequisites:** macOS with Homebrew, basic terminal familiarity

---

## ✅ Phase 1: Verify Your Machine (5 minutes)

Your machine needs the right tools installed before you can use wp-db-migrate.

### Step 1.1: Clone the Repository

All developers must clone wp-db-migrate to the same location for consistency:

```bash
# Clone to ~/.claude/skills/
cd ~/.claude/skills/
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git wp-db-migrate
cd wp-db-migrate
```

- [ ] Repository cloned to `~/.claude/skills/ls-wp-db-migrate/`
- [ ] You're in the `wp-db-migrate` directory

### Step 1.2: Check Dependencies

```bash
# Run the automated dependency check
./scripts/setup-dependencies.sh --verbose
```

**What you should see:**

- ✓ All required dependencies (green checkmarks)
- ✓ Optional dependencies (some may show as yellow/optional)
- Summary showing: "All required dependencies are installed!"

- [ ] Dependency check completed
- [ ] All required dependencies are installed

### Step 1.3: Install Missing Dependencies (if needed)

If the dependency check showed missing tools:

```bash
# Automatically install via Homebrew
./scripts/setup-dependencies.sh --install

# OR install manually (see Setup Requirements guide)
# Individual tool installation docs: ~/.claude/skills/ls-wp-db-migrate/docs/SETUP-REQUIREMENTS.md
```

**Troubleshooting:** See [Setup Requirements Guide](setup-requirements.md#troubleshooting)

- [ ] Missing dependencies installed (if any)
- [ ] Re-run dependency check to verify: `./scripts/setup-dependencies.sh`

---

## ✅ Phase 2: Install Project Dependencies (5 minutes)

Set up Node.js packages needed for testing and development.

### Step 2.1: Install NPM Dependencies

```bash
npm install
```

Wait for installation to complete (may take 2–3 minutes on first run).

- [ ] `npm install` completed without errors
- [ ] `node_modules/` folder created

### Step 2.2: Verify Installation

```bash
# Check Node.js version
node --version

# Check NPM version
npm --version

# Verify packages installed
ls -la node_modules | head -20
```

- [ ] Node.js is version 14.0 or higher
- [ ] NPM is version 6.0 or higher
- [ ] `node_modules/` contains packages

---

## ✅ Phase 3: Run Tests (5 minutes)

Verify everything is working correctly by running the test suite.

### Step 3.1: Run All Tests

```bash
npm test
```

This runs the full test suite (should take 1–2 minutes).

**Expected output:**

```
Test Suites: 15 passed, 15 total
Tests:       192 passed, 192 total
```

- [ ] All test suites passed
- [ ] 192 tests passed
- [ ] No test failures

### Step 3.2: Run Tests with Coverage (optional)

```bash
npm test -- --coverage
```

- [ ] Coverage report generated (optional verification)
- [ ] Coverage > 85% for all files

---

## ✅ Phase 4: Verify Scripts Work (5 minutes)

Test that the migration scripts run correctly.

### Step 4.1: Check Preflight

```bash
./scripts/preflight-check.sh
```

This runs detailed environment checks.

**Expected output:**

- Database drivers detected
- WordPress Studio availability confirmed
- Storage space confirmed

- [ ] Preflight check passed
- [ ] All requirements confirmed

### Step 4.2: Test Help Command

```bash
./scripts/migrate-recovery.sh --help
```

This should display usage information for the main migration script.

- [ ] Help displayed successfully
- [ ] Script is executable and working

### Step 4.3: Test Dry-Run Mode (optional)

```bash
# Create a test directory first (if you have WordPress Studio)
# ./scripts/migrate-recovery-enhanced.sh --dry-run ~/Studio/test-site "https://example.com" "https://test.local"
```

_Skip this step if you don't have WordPress Studio set up yet._

- [ ] Dry-run mode works (or skipped if no test site)

---

## ✅ Phase 5: Understand the Tool (10 minutes)

Read the essential documentation to understand how wp-db-migrate works.

### Step 5.1: Read Getting Started

Open and read: [Getting Started Guide](getting-started.md)

**Key concepts to understand:**

- The 5-stage migration workflow
- How to run your first migration
- Common options and flags

- [ ] You've read the Getting Started guide
- [ ] You understand the 5-stage workflow

### Step 5.2: Review Best Practices

Open and read: [Best Practices Guide](best-practices.md)

**Key concepts:**

- Safe migration strategies
- Backup procedures
- When to use dry-run mode
- How to handle production databases

- [ ] You've read Best Practices
- [ ] You know how to run migrations safely

### Step 5.3: Bookmark Documentation

Bookmark these links for quick reference:

- [ ] [Setup Requirements](setup-requirements.md) — Dependencies & troubleshooting
- [ ] [Team Installation](TEAM-INSTALLATION.md) — How to install for your team
- [ ] [FAQ](faq.md) — 30+ common questions
- [ ] [Troubleshooting](troubleshooting.md) — Problem solving guide
- [ ] [Reliability Guide](reliability.md) — Error recovery & resilience

---

## ✅ Phase 6: Connect with Your Team (5 minutes)

Get aligned with your team on how to use wp-db-migrate.

### Step 6.1: Ask About Team Workflows

Talk to your team lead about:

- [ ] Which installation method your team uses (Skill, Plugin, or CLI)
- [ ] Where to find team configuration files (`.wp-db-migrate.conf`)
- [ ] Your team's standard migration process
- [ ] Any team-specific documentation or workflows

### Step 6.2: Enable in Claude (if using Skill/Plugin)

If your team uses the Claude Skill or Plugin:

```bash
# For Skill installation:
# Open Claude Code → Settings → Skills
# Find "wp-db-migrate" and toggle it on
```

**Or for Plugin:**

```
# In Claude → Settings → Plugins
# Add from GitHub: https://github.com/lightspeedwp/ls-wp-db-migrate
```

- [ ] Skill/Plugin enabled in Claude (if applicable)
- [ ] You can see `/wp-migrate-clone-to-studio` command available

---

## ✅ Phase 7: Ready to Use (No checklist items)

You're now ready to run migrations! 🎉

### Next Steps

Choose based on what you need to do:

**I want to run my first migration:**
→ Follow [Getting Started](getting-started.md)

**I need to understand error recovery:**
→ Read [Reliability Guide](reliability.md)

**I want to optimize performance:**
→ Read [Advanced Usage](advanced.md)

**I have a specific question:**
→ Check [FAQ](faq.md)

**Something isn't working:**
→ Check [Troubleshooting](troubleshooting.md)

---

## 🆘 Troubleshooting This Checklist

### "Dependency check failed"

**Solution:**

1. Read: [Setup Requirements: Troubleshooting](setup-requirements.md#troubleshooting)
2. Run: `./scripts/setup-dependencies.sh --verbose`
3. Install missing tools: `./scripts/setup-dependencies.sh --install`

### "npm install failed"

**Solution:**

1. Check Node.js version: `node --version` (should be 14+)
2. Clear npm cache: `npm cache clean --force`
3. Try again: `npm install`
4. If still failing, check [SETUP-REQUIREMENTS.md](setup-requirements.md)

### "Tests are failing"

**Solution:**

1. Ensure all dependencies installed: `./scripts/setup-dependencies.sh`
2. Verify Node.js/NPM versions are correct
3. Check [TESTING.md](TESTING.md) for detailed test info
4. Ask your team lead if there are environment-specific setup steps

### "Scripts won't run"

**Solution:**

1. Make scripts executable: `chmod +x scripts/*.sh`
2. Check shell: `echo $SHELL` (should end in `bash` or `zsh`)
3. Run preflight check: `./scripts/preflight-check.sh`

### "I'm stuck"

**Get help:**

1. Ask your team lead
2. Check [FAQ](faq.md) for common questions
3. Search [Troubleshooting Guide](troubleshooting.md)
4. Read [Reliability Guide](reliability.md) for error recovery

---

## 📋 Final Verification

Before you consider yourself "onboarded", verify all of these:

- [ ] ✅ Phase 1: Dependencies verified
- [ ] ✅ Phase 2: NPM dependencies installed
- [ ] ✅ Phase 3: Tests pass (192 tests)
- [ ] ✅ Phase 4: Scripts work (`preflight-check.sh`, `--help`)
- [ ] ✅ Phase 5: Documentation read (Getting Started + Best Practices)
- [ ] ✅ Phase 6: Connected with team
- [ ] ✅ Phase 7: Ready to run migrations

**If you checked all items above, congratulations! 🎉 You're ready to use wp-db-migrate!**

---

## 📞 Need Help?

**Before asking for help, try:**

1. Running dependency check: `./scripts/setup-dependencies.sh --verbose`
2. Checking the [FAQ](faq.md)
3. Reading [Troubleshooting Guide](troubleshooting.md)
4. Searching [Reliability Guide](reliability.md)

**If you're still stuck:**

- Ask your team lead
- Share the output of `./scripts/setup-dependencies.sh --verbose`
- Reference the specific step in this checklist

---

**Onboarding completed:** ___________  
**Your name:** ___________  
**Date:** ___________

_Print this checklist and check items off as you complete them, or track progress digitally._

---

**Documentation Links:**

- [Team Installation Guide](TEAM-INSTALLATION.md)
- [Getting Started](getting-started.md)
- [Setup Requirements](setup-requirements.md)
- [Best Practices](best-practices.md)
- [FAQ](faq.md)
- [Troubleshooting](troubleshooting.md)
- [Reliability Guide](reliability.md)
- [Advanced Usage](advanced.md)
- [Analytics Guide](analytics.md)
- [Documentation Hub](README-GUIDE.md)

**Last Updated:** October 2026  
**Version:** 1.1.0
