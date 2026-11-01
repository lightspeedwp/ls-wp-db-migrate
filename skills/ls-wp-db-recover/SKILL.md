---
name: ls-wp-db-recover
description: Diagnose a failed local WordPress Studio import and restore a verified backup when authorised. Use for partial imports, SQL compatibility errors or rollback requests.
---

# Recover a failed import

## Locate shared resources

Read [the parent skill](../../SKILL.md) for the shared operating contract. Resolve
this sub-skill's directory (in Claude Code, `${CLAUDE_SKILL_DIR}`) and go up two
levels to the repository root. Set `REPO` to that absolute path in the command
examples. Never assume the current working directory is this checkout.

Capture the failing command, exit status and relevant error/table without exposing
credentials or customer rows. Stop automatic retries. Preserve the original dump,
prepared output, reports and verified pre-import backup.

Determine whether the database is unchanged, partly imported or unusable. Read
[prepare](../../SKILL.md) for SQL findings and exclusion changes.
Do not exclude a core table merely to bypass a failing import.

If the user requests rollback (or existing authorisation includes it), verify the
backup belongs to this site and is non-empty, inspect `studio import --help`, then:

```bash
test -s "$BACKUP"
studio import "$BACKUP" --path "$SITE"
```

Check each command separately and verify restored counts and URLs against the
pre-import baseline. A restore failure is a hard stop: report the state and error,
keep the backup, and request the missing information or action. Do not loop restores.
If rollback is not authorised, present the exact backup and local target for review.

Propose a corrected preparation/import only after identifying a concrete cause.
A retry that changes exclusions or account policy needs that scope resolved first.
Use [verify](../../SKILL.md) after any successful restore or corrected import.
