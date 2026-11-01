# GitHub Configuration

Configuration and workflows for GitHub-specific features.

## Structure

````bash
.github/
├── README.md                     # This file
├── labeler.yml                  # Auto-labeling configuration
├── ISSUE_TEMPLATE/              # Issue templates
│   ├── bug.md                   # Bug report template
│   ├── feature.md               # Feature request template
│   └── question.md              # Question template
├── PULL_REQUEST_TEMPLATE/       # PR templates
│   └── default.md               # Standard PR template
└── workflows/                   # GitHub Actions
    ├── test.yml                 # Test on push/PR
    └── lint.yml                 # Lint and format check
```

## Files

### mergify.yml
Automated PR merge rules based on status checks and conditions.

**What it does:**
- Auto-merges approved PRs when all checks pass (main branch)
- Auto-merges PRs with single approval on develop branch
- Auto-merges documentation-only PRs
- Auto-merges test-only PRs without review
- Requests review if PR has conflicts
- Auto-updates branch when out of date (with `auto-merge` label)
- Dismisses reviews when new commits are pushed
- Closes stale draft PRs after 30 days

**Configuration:**
- **Method:** Squash merge (keeps history clean)
- **Delete branch:** Automatically deletes head branch after merge
- **Commit message:** Uses PR title + body

**Rules:**
1. **Documentation updates** — Auto-merge if dependabot or documentation changes
2. **Test updates** — Auto-merge if only tests change
3. **Approved PRs (main)** — Auto-merge with 1 approval + all checks passing
4. **Approve PRs (develop)** — Auto-merge with 1 approval on develop branch
5. **Conflict detection** — Requests review if conflicts exist
6. **Stale drafts** — Closes after 30 days of inactivity

**Enabling auto-merge for a PR:**
- PR must be on `main` or `develop` branch
- All checks must pass (Tests, Lint & Format)
- At least 1 approval required (except docs-only changes)
- Add `auto-merge` label to auto-update branch if out of date

### labeler.yml
Automatically applies labels to PRs based on changed files.

**How it works:**
- When a PR is opened or updated, GitHub Actions reads this file
- Labels are applied automatically based on which files changed
- Example: `"tests"` label applied when `__tests__/**` files change

**Customizing labels:**
Edit the file to add new label patterns. Use glob patterns to match files.

### Issue Templates
Help contributors report bugs and request features consistently.

**Templates:**
- `bug.md` — Report bugs with reproduction steps
- `feature.md` — Request new features with use cases
- `question.md` — Ask questions with context

### Pull Request Template
Standardizes PR descriptions and ensures quality checks.

**Template Location:** `PULL_REQUEST_TEMPLATE/default.md`

**Checklist includes:**
- Type of change
- Testing verification
- Documentation updates
- Bash compatibility check

### Workflows

#### test.yml
Runs Jest and BATS tests on multiple Node versions and operating systems.

**Triggers:** Push to main/develop, PRs to main/develop

**What it does:**
1. Installs Node.js (18.x, 20.x)
2. Runs Jest tests with coverage
3. Uploads coverage to Codecov
4. Runs BATS integration tests
5. Checks Bash version

**Customizing:**
- Change Node versions in `strategy.matrix.node-version`
- Modify test commands if npm scripts change
- Add more os options to `strategy.matrix.os`

#### lint.yml
Checks code quality and formatting.

**Triggers:** Push to main/develop, PRs to main/develop

**What it does:**
1. Runs ESLint (if configured)
2. Checks shell scripts with ShellCheck
3. Validates JSON files
4. Checks YAML formatting

## Adding New Workflows

To create a new workflow:

1. Create a file in `.github/workflows/` (e.g., `my-workflow.yml`)
2. Define triggers (`on:`)
3. Define jobs and steps
4. Test locally with `act` (see https://github.com/nektos/act)

**Template:**
```yaml
name: My Workflow

on:
  push:
    branches: [main, develop]

jobs:
  my-job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello, World!"
```bash

## Linking Templates

These templates are automatically offered when:
- Creating a new issue → Choose from issue templates
- Creating a new PR → Shown the PR template

## Organization Integration

LightSpeed WP has organization-wide defaults in [lightspeedwp/.github](https://github.com/lightspeedwp/.github):
- `branch-labels.yml` — Label types
- `branch-types.yml` — Branch naming conventions
- `issue-types.yml` — Issue categories
- `labels.yml` — Label definitions

This repo's `.github/labeler.yml` adds project-specific auto-labeling on top of org-wide labels.

## Mergify Setup & Usage

Mergify automates PR merging based on configurable rules.

### Getting Started with Mergify

1. **Install Mergify App:**
   - Visit https://github.com/apps/mergify
   - Click "Install"
   - Select the LightSpeed WP organization
   - Grant repo access

2. **Configuration:**
   - Mergify reads `.github/mergify.yml`
   - Rules are evaluated for each PR
   - Merge happens automatically when conditions match

### Security Considerations

**Why all rules require checks + review:**
- Prevents supply chain attacks through malicious test commits
- Ensures human verification even for "minor" changes
- Maintains code quality and security standards
- Complies with branch protection best practices

**Restrictions in place:**
- All auto-merge rules require passing Tests + Lint checks
- Documentation auto-merge restricted to dependabot only
- Test-only changes require 1 human approval
- **All approval-based merges blocked if `#changes-requested-reviews-by > 0`**
- **Reviews automatically dismissed when new commits pushed** (prevents stale approvals)
- No exceptions for draft PRs or locked issues
- Locked, blocked, or wip labels prevent auto-merge

**What prevents:**
- ✅ Stale approvals auto-merging after code changes
- ✅ Merging when reviewers request changes
- ✅ Supply chain attacks via test commits
- ✅ Bypassing review requirements
- ✅ Code changes sneaking through as "minor"

### Merge Rules Explained

**Rule 1: Documentation Updates (Dependabot Only)**
```yaml
author: dependabot[bot]
-files~=^(?!docs/)  # Ensures ONLY docs/ changes
```bash
Auto-merges PRs from Dependabot that only modify documentation. Restricted to dependabot to prevent abuse.

**Rule 2: Test Updates (Develop Branch Only)**
```yaml
-files~=^(?!(__tests__|tests)/)  # Ensures ONLY test changes
"#approved-reviews-by>=1"        # Requires 1 approval
base=develop                      # Only on develop, not main
```bash
Auto-merges test-only PRs on develop branch after human review. Main branch requires approval (see Rule 3).

**Rule 3: Approved PRs (main branch)**
```yaml
"#approved-reviews-by>=1"
base=main
```bash
Auto-merges when PR has at least 1 approval and all checks pass.

**Rule 4: Approved PRs (develop branch)**
```yaml
"#approved-reviews-by>=1"
base=develop
```bash
Auto-merges on develop with 1 approval (faster development iteration).

### Labels for Mergify Control

**Labels you can apply:**
- `auto-merge` — Will auto-update branch when out of date
- `blocked` — Prevents auto-merge even if all conditions met
- `wip` — Marks as work-in-progress, prevents merge

**Example:**
```bash
# Allow auto-update for out-of-date branch
gh pr edit PR_NUMBER --add-label auto-merge
```bash

### Merge Methods

Mergify uses **squash merge** by default:
- Combines all commits into one
- Keeps git history clean
- Uses PR title + body as commit message

**Benefits:**
- Linear history on main branch
- Easy to revert entire PR if needed
- Clear attribution to original PR

### Customizing Merge Rules

Edit `.github/mergify.yml` to change behavior:

**To require 2 approvals:**
```yaml
"#approved-reviews-by>=2"
```bash

**To require specific reviewer:**
```yaml
"reviewed-by=@lightspeedwp/maintainers"
```bash

**To skip certain PRs:**
```yaml
"-label=manual-merge"
```bash

**To add new conditions:**
```yaml
- name: Custom rule
  conditions:
    - check-success=Tests
    - "-draft"
  actions:
    merge:
      method: squash
```bash

### Monitoring Mergify

**Check Mergify status:**
- Click "Details" next to Mergify check on PR
- See what conditions are met/unmet
- Review merge decisions

**Mergify Dashboard:**
- https://dashboard.mergify.io
- Requires GitHub app permissions
- Shows recent merges and decisions

### Troubleshooting Mergify

**PR not merging:**
1. Check that all required checks pass (Tests, Lint & Format)
2. Verify branch is not `draft`
3. Check PR is on approved branch (main or develop)
4. Ensure no `blocked` label
5. Click Mergify check to see detailed reason

**Wrong merge method:**
- Edit `.github/mergify.yml` and change `method:`
- Options: `squash`, `merge`, `rebase`

**Want to merge manually:**
- Add `manual-merge` label to skip auto-merge
- Or add `blocked` label temporarily

## Troubleshooting

**Labels not applying:**
- Check that files changed match glob patterns in `labeler.yml`
- Labels are applied to PRs, not commits
- GitHub Actions must be enabled in repo settings

**Workflows not running:**
- Check branch protection rules don't require approval
- Verify workflows are not marked as disabled
- Check GitHub Actions quota hasn't been exceeded

**Templates not appearing:**
- Ensure filenames match exactly (case-sensitive on Linux)
- Template must have YAML frontmatter (`---`)
- Clear browser cache if recently changed

## Testing Locally

Test workflows locally with `act`:

```bash
# Install act
brew install act

# Run all workflows
act

# Run specific workflow
act -j test

# Dry run (don't actually run)
act -n
```bash

See [nektos/act](https://github.com/nektos/act) for full documentation.
````
