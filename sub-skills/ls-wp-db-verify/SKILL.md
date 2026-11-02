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
from the prepared dump. Read current `siteurl` and `home`; Studio's importer may
already have updated them. Distinct source home/site URLs or multisite require
separate mappings, not a guessed single replacement.

Do not use `studio wp search-replace` on a Studio site: after a phpMyAdmin-style
dump (`ALTER TABLE ... MODIFY ... AUTO_INCREMENT`), the SQLite driver's `DESCRIBE`
no longer reports primary keys, so WP-CLI skips every such table and reports
0 replacements. Preview each replacement with the bundled helper instead. It
reads keys from `SHOW KEYS`, uses WP-CLI's serialisation-aware `SearchReplacer`,
and matches http/https, `www.` and JSON-escaped (`https:\/\/`) forms of the
source host(s) (a bare host, comma-separated for several):

```bash
studio wp --path "$SITE" eval-file "$REPO/scripts/studio-search-replace.php" dry "$OLD_HOST" "$NEW_URL"
```

`sql-tool site-urls` and `sanitise` with `--studio-site` print this command with
the hosts filled in. Show the per-table counts and intended mapping. If the
requested migration already authorises this mapping, proceed; otherwise resolve
permission before running it again with `apply` in place of `dry`. A warning names
any table without a primary key that still holds matches; those are not changed.
`scripts/replace-urls.sh` applies immediately and is not a preview.

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
