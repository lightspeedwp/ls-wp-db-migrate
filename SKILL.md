---
name: ls-wp-db-migrate
description: Prepare and migrate MySQL or MariaDB WordPress exports into local WordPress Studio sites, including table analysis, sanitisation, URL replacement, verification and failed-import recovery. Use for staging-to-local database workflows, not remote deployments or file/media synchronisation.
---

# LightSpeed WordPress database migration

This repository is the parent Claude skill. Its focused sub-skills live in `skills/`
and share `lib/`, `scripts/` and `docs/` at the repository root.

## Route the request

Request: $ARGUMENTS

Read the relevant sub-skill before acting; load only the stages needed. A stage name
at the start of the request selects that stage. With no stage, infer it from the
request; a complete migration follows preflight → prepare → migrate → verify.

| Stage | Read | Use for |
| --- | --- | --- |
| `preflight` | [Preflight](skills/ls-wp-db-preflight/SKILL.md) | Dependencies, source tables, URLs and target prefix |
| `prepare` | [Prepare](skills/ls-wp-db-prepare/SKILL.md) | Sanitising an export and choosing exclusions |
| `migrate` | [Migrate](skills/ls-wp-db-migrate-import/SKILL.md) | Backing up and importing into a local Studio site |
| `verify` | [Verify](skills/ls-wp-db-verify/SKILL.md) | URL replacement, counts and site checks |
| `recover` | [Recover](skills/ls-wp-db-recover/SKILL.md) | Diagnosing a failed import and restoring a backup |

For example: `/ls-wp-db-migrate preflight /path/to/export.sql /path/to/studio-site`.
These are routed arguments, not nested slash commands. Plugin installations also
register the sub-skills individually; see [installation](docs/INSTALLATION.md).

## Shared operating contract

- Resolve this file's directory as the repository root, regardless of the user's
  working directory. In Claude Code this is `${CLAUDE_SKILL_DIR}`. Resolve relative
  links from the file containing them. Sub-skills also explain direct invocation.
- Establish the source export, local target path, source/destination URLs, table
  prefix and account/exclusion choices before import. Reuse information supplied.
- Scope writes to the requested local site and working files. Preserve the original
  dump. A request for analysis or a plan does not authorise import or URL changes.
- Before replacing an existing database, make and verify a recoverable backup.
  Proceed within existing authorisation; ask only when the target or destructive
  scope is unresolved. Restore only with authorisation covering that overwrite.
- Use the bundled `node lib/sql-tool.cjs` for dump analysis and sanitisation.
  Studio imports MySQL-format SQL and translates it; do not convert it to native
  SQLite syntax or load it with `sqlite3`.
- Inspect the installed CLI's help before using version-dependent Studio commands.
  Inspect helpers before relying on them: `migrate-recovery*.sh` are post-import
  helpers, not import engines. The clone orchestrator does not implement a complete
  local-file import, and its dry-run path can still attempt remote SSH operations.
- Stop on command failure or blocking findings. Report completed steps, pending
  checks, backup/output paths and errors. Do not infer success from a banner or
  promise automatic rollback, performance gains or row-count parity without evidence.

For CLI syntax use [WordPress Studio CLI](https://developer.wordpress.com/docs/developer-tools/studio/cli/).
For Claude discovery use [Claude Code skills](https://code.claude.com/docs/en/skills).
