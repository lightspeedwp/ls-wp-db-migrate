---
name: ls-wp-db-migrate-import
description: Back up and import a prepared WordPress MySQL-format dump into a local Studio site. Use when an actual local database import is requested, after compatibility and exclusion review.
---

# Import into Studio

## Locate shared resources

Read [the parent skill](../../SKILL.md) for the shared operating contract. Resolve
this sub-skill's directory (in Claude Code, `${CLAUDE_SKILL_DIR}`) and go up two
levels to the repository root. Set `REPO` to that absolute path in the command
examples. Never assume the current working directory is this checkout.

Read [prepare](../ls-wp-db-prepare/SKILL.md) when there is no reviewed sanitised
output. Establish `SITE`, `OUTPUT` (the prepared dump) and a new absolute `BACKUP`
path outside the site's disposable working files. Confirm the target is local.
Inspect installed `studio export --help` and `studio import --help`; use supported
flags rather than copying commands from older guides.

For an existing site, export its database and verify the file is non-empty before
importing. Record baseline table counts and URLs for later comparison.

```bash
studio export "$BACKUP" --mode db --path "$SITE"
test -s "$BACKUP"
studio import "$OUTPUT" --path "$SITE"
```

Execute and check these separately: an export or backup check failure blocks the
import. Do not assume `studio backup create` exists. For a new site, create it only
within the requested scope using installed CLI help, then back up its initial state.

An import request must cover overwriting this target with the reviewed exclusions
and account policy. Ask only for unresolved scope. Never apply source-site writes
or a remote deployment as part of a local import.

On import failure, stop and read [recover](../ls-wp-db-recover/SKILL.md). Do not claim
an automatic rollback. On success, read [verify](../ls-wp-db-verify/SKILL.md).
The `migrate-recovery*.sh` scripts only verify, replace URLs and start a server;
they cannot perform this import. Do not use the clone orchestrator for local dumps.
