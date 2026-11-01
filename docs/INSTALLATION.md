# Install and invoke the Claude skill

## Personal parent skill

Place the repository itself in Claude Code's personal skills directory:

```bash
git clone https://github.com/lightspeedwp/ls-wp-db-migrate.git \
  ~/.claude/skills/ls-wp-db-migrate
```

Do not clone again over an existing checkout. The entrypoint must be
`~/.claude/skills/ls-wp-db-migrate/SKILL.md`; `~/claude/skills/` without the leading
dot is a different directory and is not the default personal skill location.

Start a new Claude Code session and type:

```text
/ls-wp-db-migrate preflight /absolute/path/export.sql /absolute/path/studio-site
```

The stage arguments are `preflight`, `prepare`, `migrate`, `verify` and `recover`.
With a natural-language request the parent chooses the relevant sub-skill. Nested
`skills/<name>/SKILL.md` files are read by the parent; this layout does not register
nested personal slash commands. No settings toggle or permission allow-list is needed.

## Optional plugin mode

To expose the parent and each sub-skill as independent namespaced commands, test
this checkout as a plugin in a separate session:

```bash
claude --plugin-dir ~/.claude/skills/ls-wp-db-migrate
```

The existing plugin namespace is `wp-db-migrate`. Commands include:

```text
/wp-db-migrate:ls-wp-db-migrate
/wp-db-migrate:ls-wp-db-preflight
/wp-db-migrate:ls-wp-db-prepare
/wp-db-migrate:ls-wp-db-migrate-import
/wp-db-migrate:ls-wp-db-verify
/wp-db-migrate:ls-wp-db-recover
```

The manifest loads the root skill with `"skills": ["./"]`; Claude also scans the
standard `skills/` directory. The plugin name is retained for existing marketplace
users. Personal and plugin modes can coexist, but using one mode avoids duplicate
entries. No plugin installation or global configuration change is performed here.

## Dependencies and verification

Node.js runs `lib/sql-tool.cjs`; Studio CLI handles local imports and bundled WP-CLI.
Remote export workflows additionally need authorised SSH access and remote WP-CLI.
Check the installed CLI's help before migrating. Install development dependencies
with `npm ci` only when running the Jest suite.

```bash
claude plugin validate .
npm test -- --runInBand
```

References, checked 1 November 2026:

- [Claude Code skills](https://code.claude.com/docs/en/skills)
- [Claude plugin manifest](https://code.claude.com/docs/en/plugins-reference)
- [Studio CLI](https://developer.wordpress.com/docs/developer-tools/studio/cli/)
