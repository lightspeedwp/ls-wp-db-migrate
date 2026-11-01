---
name: ls-wp-db-prepare
description: Sanitise a MySQL or MariaDB WordPress dump for local Studio import. Use for SQL compatibility findings, table exclusions, prefix changes or preserving local accounts.
---

# Prepare an export

## Locate shared resources

Read [the parent skill](../../SKILL.md) for the shared operating contract. Resolve
this sub-skill's directory (in Claude Code, `${CLAUDE_SKILL_DIR}`) and go up two
levels to the repository root. Set `REPO` to that absolute path in the command
examples. Never assume the current working directory is this checkout.

Run [preflight](../ls-wp-db-preflight/SKILL.md) if the dump's tables, URLs or target
prefix have not been inspected. Set `DUMP`, `SITE` and a new absolute `OUTPUT` path.

```bash
node "$REPO/lib/sql-tool.cjs" sanitise "$DUMP" \
  --studio-site "$SITE" --out "$OUTPUT" --json
```

This writes a new MySQL-format dump and reports edits/findings. The original is
preserved. Read the result even when the exit code is 1; stop on blocking findings.
Do not overwrite a previous output or use `--force` without resolving its ownership.

Select optional flags from the user's needs and the actual table inventory:

- `--exclude 'actionscheduler_logs'` (repeatable, or comma-separated): match the
  full table name or its unprefixed name; quote wildcard patterns. Report matches
  and impact before importing. Resolve exclusions that remove required content.
- `--prefix wp_`: rename imported tables to the confirmed target prefix; do not
  guess the prefix, especially for multisite or mixed-prefix exports.
- `--keep-users`: leave the export's users/usermeta out so the local accounts
  survive. This does **not** mean import source accounts. Ensure imported tables
  use the target prefix, as the tool requires.
- Wordfence tables are omitted by default. Explain this and keep its plugin
  deactivated locally, or use `--keep-wordfence` when the user requires those tables.

Record the input hash, output path, edits, excluded tables and unresolved findings
from the tool's report. Sanitisation does not anonymise personal/customer data.
Continue to [migrate](../ls-wp-db-migrate-import/SKILL.md) only if import is requested.
