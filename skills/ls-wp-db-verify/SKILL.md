---
name: ls-wp-db-verify
description: Verify an imported local WordPress Studio database and preview or apply URL replacement. Use for source-to-local URL mapping, row-count checks and post-import site validation.
---

# Verify and replace URLs

## Locate shared resources

Read [the parent skill](../../SKILL.md) for the shared operating contract. Resolve
this sub-skill's directory (in Claude Code, `${CLAUDE_SKILL_DIR}`) and go up two
levels to the repository root. Set `REPO` to that absolute path in the command
examples. Never assume the current working directory is this checkout.

Establish `SITE`, the reviewed source/target URL mapping and expected tables/counts
from the prepared dump. Check installed `studio wp --help` and WP-CLI search-replace
help before applying version-dependent flags. Read current `siteurl` and `home`;
Studio may already have updated them. Distinct source home/site URLs or multisite
require separate mappings, not a guessed single replacement.

Preview each required replacement with serialization-aware WP-CLI:

```bash
studio wp search-replace "$OLD_URL" "$NEW_URL" --all-tables --dry-run --path "$SITE"
```

Show the counts and intended mapping. If the requested migration already authorises
this mapping, proceed; otherwise resolve permission before applying the same command
without `--dry-run`. `scripts/replace-urls.sh` writes immediately and is not a preview.

Read and check actual output from:

```bash
studio wp option get siteurl --path "$SITE"
studio wp option get home --path "$SITE"
studio wp db tables --path "$SITE"
studio wp post list --format=count --path "$SITE"
studio wp user list --format=count --path "$SITE"
```

Compare included-table row counts using supported commands for the SQLite-backed
site and the prepared dump. Account for excluded tables, preserved local users and
intentional URL changes. Check database integrity only through a command supported
by the installed SQLite integration. Check the requested pages and admin login in
a browser when available; report unperformed checks explicitly.

`scripts/verify-import.sh` suppresses some errors and prints a success banner even
when counts fail. Treat it as supplementary output, not proof of a valid import.
Report measured counts, URL mappings, exclusions, backup path and remaining issues.
