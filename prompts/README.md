# Agent Prompts

System instructions and Claude agent configuration files for the WordPress Database Migration skill.

## Quick Overview

These files configure how Claude agents interact with wp-db-migrate:

- System prompts that define agent behavior
- Skill instructions for Claude integration
- GitHub-specific setup guidance
- Example workflows

## Files in This Directory

### [github-setup.md](github-setup.md)

Configure GitHub integration with wp-db-migrate for CI/CD and automation.

**When to use:**

- Setting up automated database migrations in GitHub Actions
- Configuring org-wide Claude agents for database work
- Integrating with GitHub's workflow and repository structure

**Covers:**

- Monorepo and multi-skill repository structure
- GitHub Actions workflow integration
- Credential and secret management
- CI/CD pipeline setup with wp-db-migrate

## How to Use These Prompts

### For a Single Project

1. Copy the relevant prompt to `.claude/agents/` in your project
2. Reference it in your `.claude/agents/agent-name.md`
3. Customize for your repository structure

### For Organization-Wide Setup

1. Place prompts in `.github/agents/` in your `.github` repository
2. Enable them in organization settings
3. All projects inherit the configuration

### In Claude Directly

1. Copy prompt content into Claude's agent instructions
2. Adjust paths and context for your repository
3. Test with a small migration first

## Customization Guide

Each prompt is templated for common patterns. To customize:

**Replace these placeholders:**

- `{ORG_NAME}` → Your organization name
- `{REPO_NAME}` → Your repository name
- `{SKILL_PATH}` → Path to wp-db-migrate skill
- `{STUDIO_PATH}` → Your Studio site path

**Example:**

````markdown
# Before

skill_location: {SKILL_PATH}/skill

# After

skill_location: /Users/ash/.claude/skills/wp-db-migrate/skill

````bash

## Adding New Prompts

To create a new agent prompt file:

1. **Create the file** — `my-workflow.md` in this directory
2. **Start with a header** — Explain purpose, when to use, what it enables
3. **Define the scope** — What can this agent do? What not?
4. **Include examples** — Show typical usage patterns
5. **Link to docs** — Reference relevant documentation
6. **Update this README** — Add an entry with description

**Template:**
```markdown
# Agent: {Name}

Configure Claude agents for {purpose}.

## When to Use
- Use case 1
- Use case 2

## What This Agent Can Do
- ✅ Capability 1
- ✅ Capability 2
- ❌ Cannot do X (security boundary)

## Setup Instructions
[...]

## Example Workflows
[...]
```bash

## Best Practices

1. **Keep prompts focused** — One agent per use case
2. **Include constraints** — Document what agents should NOT do
3. **Test before sharing** — Verify prompts work in practice
4. **Version control** — Commit prompt changes with your code
5. **Document changes** — Update this README when adding prompts

## Related Resources

- [Main README](../README.md) — Project overview
- [SKILL.md](../SKILL.md) — Complete skill documentation
- [Installation Guide](../docs/INSTALLATION.md) — Setup instructions
```bash
```bash
