---
name: ls-wp-db-preflight
description: Inspect WordPress SQL exports and local Studio prerequisites before migration. Use for dependency checks, table inventories, source URLs and prefix compatibility without importing data.
---

# Migration preflight

## Locate shared resources

Read [the parent skill](../../SKILL.md) for the shared operating contract. Resolve
this sub-skill's directory (in Claude Code, `${CLAUDE_SKILL_DIR}`) and go up two
levels to the repository root. Set `REPO` to that absolute path in the command
examples. Never assume the current working directory is this checkout.

Establish `DUMP` (an absolute path to an uncompressed MySQL-format `.sql`) and
`SITE` (the requested local Studio site). If the input is compressed, extract a
working copy without replacing the original. Obtain a remote export only if the
user has authorised remote access; a site URL alone is not SSH configuration.

```bash
node --version
studio --version
studio import --help
studio export --help
node "$REPO/lib/sql-tool.cjs" tables "$DUMP" --json
node "$REPO/lib/sql-tool.cjs" site-urls "$DUMP" --studio-site "$SITE" --json
```

Use command exit codes and JSON findings together: `sql-tool` returns 0 for pass,
1 for findings requiring review, and 2 for usage or execution errors. Capture and
review each result rather than chaining them with `&&` and losing later findings.
If the target does not exist, inspect the dump without `--studio-site`, then resolve
whether the user wants a new Studio site before creating it.

Report table sizes/rows, prefixes, source URL candidates, missing tools and any
multisite or prefix mismatch. Preserve core content tables such as `postmeta`;
size alone is not a reason to exclude them. Choose exclusions in
[prepare](../ls-wp-db-prepare/SKILL.md).

The legacy `scripts/preflight-check.sh` checks additional tools and a fixed
`~/.studio` path and may stop early. Do not treat it as a complete dependency audit.
Local Studio commands use Studio's bundled WP-CLI; standalone `wp` is only needed
for workflows that actually call it, such as a remote WP-CLI export.
