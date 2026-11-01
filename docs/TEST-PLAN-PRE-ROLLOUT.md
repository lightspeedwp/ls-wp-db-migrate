# Pre-Rollout Test Plan: wp-db-migrate Workflow

Complete testing plan for validating wp-db-migrate with a team member before full team rollout.

**Duration:** 1.5-2 hours (includes troubleshooting margins)  
**Goal:** Verify complete workflow works smoothly and identify any blockers  
**Test Environment:** Staging database (non-critical data)  
**Success Criteria:** All steps complete without critical errors

---

## Phase 1: Pre-Test Setup (15 minutes)

### 1.1 Schedule & Preparation

- [ ] Schedule test session (1.5-2 hours with team member)
- [ ] Provide team member with: TEAM-ANNOUNCEMENT.md + ONBOARDING-CHECKLIST.md
- [ ] Prepare test database export (from staging, ~200-500MB recommended)
- [ ] Create empty WordPress Studio site for testing
- [ ] Have SSH access details ready (if testing remote export)
- [ ] Prepare feedback collection form (see end of this plan)

### 1.2 Verify Test Environment

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Verify dependencies on test machine
./scripts/setup-dependencies.sh --verbose

# Expected: All required dependencies installed ✓
```

**What to check:**

- [ ] Bash shell available
- [ ] WordPress Studio installed and running
- [ ] WP-CLI available
- [ ] git installed
- [ ] SSH keys configured (if testing remote export)

### 1.3 Create Test WordPress Studio Site

```bash
studio create test-migrate-site
```

**What to verify:**

- [ ] Site created successfully
- [ ] Site accessible at localhost
- [ ] Database exists in ~/Studio/test-migrate-site

---

## Phase 2: Basic Workflow Test (45 minutes)

### 2.1 Dry-Run Mode (10 minutes)

**Goal:** Preview migration without making changes

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Run with dry-run flag
./scripts/migrate-recovery-enhanced.sh --dry-run \
  ~/.studio/sites/test-migrate-site \
  "https://staging.example.com" \
  "https://test-migrate-site.local"
```

**What to verify:**

- [ ] Script starts successfully
- [ ] Database analysis completes
- [ ] Shows: table count, row count, total size
- [ ] Shows: suggested exclusions
- [ ] Estimated import time displayed
- [ ] No errors in output
- [ ] Output is color-coded (green ✓, yellow ⚠️)

**Expected output includes:**

```
✓ Database Analysis
├─ Tables: 42 found
├─ Rows: 1.2M total
├─ Size: 450MB uncompressed
└─ Estimated: 120-150 seconds import time

Suggested Exclusions (won't break site):
  - wp_actionscheduler_logs (145MB)
  - wp_cache (78MB)
```

### 2.2 Actual Migration (25 minutes)

**Goal:** Complete full migration workflow

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Run actual migration (no --dry-run)
./scripts/migrate-recovery.sh \
  ~/.studio/sites/test-migrate-site \
  "https://staging.example.com" \
  "https://test-migrate-site.local"
```

**Watch for these stages:**

**Stage 1: Export Database** (2-5 min)

- [ ] ✓ Export database message
- [ ] ✓ Spinner animating
- [ ] ✓ "Complete" message

**Stage 2: Sanitize Database** (1-2 min)

- [ ] ✓ Sanitizing output
- [ ] ✓ MySQL → SQLite conversion shown
- [ ] ✓ "Complete" message

**Stage 3: Backup & Import** (30-60 sec)

- [ ] ✓ Backup created message
- [ ] ✓ Import starting
- [ ] ✓ Progress indicator (if shown)
- [ ] ✓ "Import Complete" message

**Stage 4: URL Replacement** (2-5 min)

- [ ] ✓ Dry-run counts shown
- [ ] ✓ Asks for approval
- [ ] ✓ Apply replacement confirmed
- [ ] ✓ "URLs replaced" message

**Stage 5: Validation** (1-2 min)

- [ ] ✓ Site load test (HTTP 200)
- [ ] ✓ Table count verification
- [ ] ✓ Database integrity check
- [ ] ✓ "Validation Complete" message

### 2.3 Post-Migration Verification (10 minutes)

**Goal:** Verify data integrity and site functionality

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Verify import success
./scripts/verify-import.sh ~/.studio/sites/test-migrate-site
```

**What to check:**

- [ ] ✓ Database check passes
- [ ] ✓ Table count matches source
- [ ] ✓ Row count matches source
- [ ] ✓ No corruption detected

**Manual verification in WordPress Studio:**

```bash
# Open site in browser
studio open test-migrate-site
```

**What to verify in browser:**

- [ ] ✓ Site loads (no 500 errors)
- [ ] ✓ WordPress dashboard accessible
- [ ] ✓ At least one post visible
- [ ] ✓ At least one page visible
- [ ] ✓ Navigation menus working
- [ ] ✓ Media library loads
- [ ] ✓ Site URL correct (should be test-migrate-site.local)

**CLI verification:**

```bash
cd ~/.studio/sites/test-migrate-site

# Check site is installed
wp core is-installed
# Expected: Success

# Check post count (should match source)
wp post list --format=count
# Expected: Number > 0

# Check site URL
wp option get siteurl
# Expected: https://test-migrate-site.local
```

---

## Phase 3: Database Size Reduction Testing (30 minutes)

### 3.1 Create New Test Site (5 min)

```bash
studio create test-migrate-minimal
```

### 3.2 Test with Exclusions (20 min)

**Goal:** Verify size reduction works

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Migration with table exclusions
./scripts/migrate-recovery.sh \
  ~/.studio/sites/test-migrate-minimal \
  "https://staging.example.com" \
  "https://test-migrate-minimal.local" \
  --exclude-tables wp_actionscheduler_logs,wp_cache,wp_activity_log
```

**What to verify:**

- [ ] ✓ Script completes successfully
- [ ] ✓ Exclusion messages shown (tables being skipped)
- [ ] ✓ Final file size is smaller than dry-run showed
- [ ] ✓ Import time is faster than first test
- [ ] ✓ Site still functions properly after import

**Measure size reduction:**

```bash
# Compare the sizes
# Test 1 (full): Note the final size
# Test 2 (minimal): Note the final size
# Calculate: (full - minimal) / full × 100% = reduction percentage
# Expected: 40-60% reduction with default exclusions
```

### 3.3 Verify Site Still Works (5 min)

```bash
# Open and test minimal migration
studio open test-migrate-minimal

# CLI verification
cd ~/.studio/sites/test-migrate-minimal
wp post list | head -3
wp page list | head -3
```

**What to verify:**

- [ ] ✓ Site loads normally
- [ ] ✓ Posts visible
- [ ] ✓ Pages visible
- [ ] ✓ No critical features missing

---

## Phase 4: Remote Database Export Testing (20 minutes)

**SKIP if no staging server access; test with local export instead**

### 4.1 Test SSH Connection (5 min)

```bash
# Create new test site
studio create test-migrate-ssh

# Test SSH connection first (use your SSH key path)
ssh -i ~/.ssh/your-key user@staging.example.com 'echo Connected'
# Expected: "Connected"

# Verify WP-CLI on remote
ssh -i ~/.ssh/your-key user@staging.example.com 'wp --version'
# Expected: version number
```

**What to verify:**

- [ ] ✓ SSH connection works
- [ ] ✓ WP-CLI available on remote
- [ ] ✓ SSH key permissions correct (600)

### 4.2 Run Remote Migration (15 min)

```bash
# Migration directly from remote server
./scripts/migrate-recovery.sh \
  ~/Studio/test-migrate-ssh \
  "https://staging.example.com" \
  "https://test-migrate-ssh.local" \
  --ssh-host staging.example.com \
  --ssh-user deploy \
  --ssh-key ~/.ssh/your-key
```

**What to verify:**

- [ ] ✓ SSH connection established
- [ ] ✓ Remote database exported via SSH
- [ ] ✓ No "Connection refused" errors
- [ ] ✓ No "Permission denied" errors
- [ ] ✓ Entire workflow completes successfully
- [ ] ✓ Final site works correctly

---

## Phase 5: Error Scenarios Testing (15 minutes)

**Test how errors are handled**

### 5.1 Test Missing WordPress Studio Site (5 min)

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Try to migrate to non-existent site
./scripts/migrate-recovery.sh \
  ~/.studio/sites/non-existent-site \
  "https://staging.example.com" \
  "https://test.local"
```

**What to verify:**

- [ ] ✓ Script fails gracefully
- [ ] ✓ Error message is clear
- [ ] ✓ Explains what's wrong (site not found)
- [ ] ✓ Suggests solution (create site first)

### 5.2 Test Invalid Source URL (5 min)

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Try with invalid URL
./scripts/migrate-recovery.sh \
  ~/.studio/sites/test-migrate-site \
  "https://non-existent-staging-url.com" \
  "https://test.local"
```

**What to verify:**

- [ ] ✓ Script fails gracefully
- [ ] ✓ Error message is clear
- [ ] ✓ No partial data left behind
- [ ] ✓ Site remains intact (rollback works)

### 5.3 Test Verification (5 min)

```bash
cd ~/.claude/skills/ls-wp-db-migrate

# Run verify on site that had errors
./scripts/verify-import.sh ~/.studio/sites/test-migrate-site
```

**What to verify:**

- [ ] ✓ Verify script doesn't crash on incomplete sites
- [ ] ✓ Reports status clearly
- [ ] ✓ Provides helpful troubleshooting info

---

## Phase 6: Documentation Verification (15 minutes)

### 6.1 Check Setup Documentation

**Have team member review:**

- [ ] ✓ [Setup Requirements](setup-requirements.md) — Accurate for their machine
- [ ] ✓ [Onboarding Checklist](ONBOARDING-CHECKLIST.md) — Easy to follow
- [ ] ✓ [Getting Started](getting-started.md) — Covers what they just did

**Ask:**

- Was anything unclear?
- Were there steps not documented?
- Did they need additional help?

### 6.2 Check Troubleshooting Guide

- [ ] ✓ [Troubleshooting](troubleshooting.md) — Covers errors they encountered
- [ ] ✓ [FAQ](faq.md) — Answers their questions
- [ ] ✓ [Best Practices](best-practices.md) — Clear and actionable

### 6.3 Check Help References

- [ ] ✓ `--help` flag works: `./scripts/migrate-recovery.sh --help`
- [ ] ✓ Help message is clear and complete
- [ ] ✓ Options documented accurately

---

## Feedback Collection Form

**For team member to complete after test:**

### Part 1: Installation & Setup

- ✓ Dependency verification worked smoothly?
- ⚠️ Any issues with tool installation?
- 💬 How long did setup take? (expected: 15-20 min)

### Part 2: Basic Workflow

- ✓ Dry-run gave useful preview?
- ✓ Actual migration completed without errors?
- ✓ Migration time matched estimate?
- 💬 Any confusing output or messages?

### Part 3: Verification

- ✓ Site opened and worked correctly?
- ✓ Data integrity confirmed?
- ✓ Posts/pages/media visible?
- 💬 Did anything seem broken or incomplete?

### Part 4: Size Reduction (if tested)

- ✓ Exclusions worked as expected?
- 💬 How much storage was saved? (actual %)
- ✓ Site still worked with excluded tables?

### Part 5: Remote Export (if tested)

- ✓ SSH connection worked smoothly?
- ✓ Remote database export worked?
- ✓ No permission issues?

### Part 6: Documentation

- ✓ Setup guide clear and complete?
- ✓ Onboarding checklist easy to follow?
- ✓ Troubleshooting guide helpful?
- 💬 What docs need improvement?

### Part 7: Overall

- 💬 Confidence level for using this alone (1-10)?
- 💬 Would you use wp-db-migrate for production sites?
- 💬 Any features missing or improvements needed?
- 💬 General comments/feedback?

---

## Success Criteria

### Critical (Must Pass)

- [ ] ✓ Dependency verification passes
- [ ] ✓ Dry-run completes without errors
- [ ] ✓ Full migration workflow completes
- [ ] ✓ Post-migration site opens and loads
- [ ] ✓ Data integrity verified (row counts match)
- [ ] ✓ Error scenarios handled gracefully

### Important (Should Pass)

- [ ] ✓ All 5 migration stages work smoothly
- [ ] ✓ Size reduction works as expected
- [ ] ✓ Remote export works (if tested)
- [ ] ✓ Documentation is clear and accurate
- [ ] ✓ Team member feels confident to do this alone

### Nice to Have

- [ ] ✓ Performance meets expectations
- [ ] ✓ UI/output messages are clear
- [ ] ✓ All features tested work as documented
- [ ] ✓ No surprises or unexpected behaviors

---

## Rollback Plan (If Critical Issues Found)

If critical failures occur:

1. **Delete test site**

   ```bash
   studio delete test-migrate-site
   ```

2. **Document the issue**
   - What step failed?
   - What error message?
   - What environment (OS, tools)?

3. **Check logs**

   ```bash
   # Look for detailed error logs
   ls -la ~/Studio/test-migrate-site/wp-content/debug.log
   ```

4. **Investigate with team**
   - Was this expected?
   - Is it a known limitation?
   - Should we fix before rollout?

---

## Post-Test Debrief (15 minutes)

### 1. Review Results

- Did everything work as expected?
- Which phases had issues?
- Were errors clear and actionable?

### 2. Identify Gaps

- What documentation needs improvement?
- Were there confusing steps?
- Should we adjust anything before team rollout?

### 3. Plan Next Steps

- Is this ready for full team rollout?
- Do we need to fix anything?
- Should we do another test with different database size?

### 4. Collect Recommendations

- Anything to improve before team sees it?
- Any risks we should prepare for?
- Any training to add for the team?

---

## Documentation to Give Team Member

1. **Before test:** `~/.claude/skills/ls-wp-db-migrate/docs/TEAM-ANNOUNCEMENT.md`
2. **During test:** `~/.claude/skills/ls-wp-db-migrate/docs/ONBOARDING-CHECKLIST.md` + Getting Started
3. **For troubleshooting:** `~/.claude/skills/ls-wp-db-migrate/docs/TROUBLESHOOTING.md` + FAQ
4. **After test:** This feedback form

---

## Test Environment Cleanup (After Test)

```bash
# Remove test sites
studio delete test-migrate-site
studio delete test-migrate-minimal
studio delete test-migrate-ssh  # if tested

# Clean up any temporary files
rm -rf ~/.claude/temp-test-databases/
```

---

## Test Results Summary Template

**Share with team lead after test:**

```
wp-db-migrate Pre-Rollout Test Results
=====================================

Test Date: [date]
Test Environment: [machine OS/specs]
Database Size Tested: [size]
Overall Result: ✓ PASSED / ⚠️ PARTIAL / ✗ BLOCKED

Critical Tests:
  ✓ Dependency verification
  ✓ Dry-run mode
  ✓ Full migration workflow
  ✓ Post-migration verification
  ✓ Error handling

Optional Tests:
  ✓ Database size reduction
  [✓ or ⚠️] Remote database export
  [✓ or ⚠️] Large database handling

Feedback Highlights:
  - Installation: [smooth / had issues]
  - Documentation: [clear / needs improvement]
  - Confidence: [high / medium / low]

Blockers (if any):
  - [issue 1]
  - [issue 2]

Recommendations:
  - [improvement 1]
  - [improvement 2]

Ready for team rollout: ✓ YES / ⚠️ WITH FIXES / ✗ NO

Next Steps:
  [ ] Address any identified issues
  [ ] Schedule team announcement
  [ ] Hold 30-minute onboarding session
```

---

## Estimated Timeline

- Setup & prep: 15 min
- Basic workflow: 45 min
- Size reduction test: 30 min
- Remote export test: 20 min (optional)
- Error scenarios: 15 min
- Documentation review: 15 min
- Debrief: 15 min

**Total: 1.5-2 hours** (plus troubleshooting margin)

---

## What Successful Looks Like

After this test, your team member should:

- ✓ Understand the complete 5-stage workflow
- ✓ Know how to run their first migration alone
- ✓ Understand database size reduction options
- ✓ Know where to find troubleshooting help
- ✓ Feel confident to help other team members
- ✓ Be able to identify when something went wrong
- ✓ Have realistic expectations for time & storage

**Result: Ready to roll out to full team! 🚀**
