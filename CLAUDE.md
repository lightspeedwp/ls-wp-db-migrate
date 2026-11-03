# Working on ls-wp-db-migrate

The repository root is the personal Claude skill at
`~/.claude/skills/ls-wp-db-migrate/`. Read [SKILL.md](SKILL.md) for migration work;
load only the relevant sub-skills from `skills/`. Shared tools are in root `scripts/`
and `lib/`, not `scripts/`.

For repository maintenance, preserve local changes, inspect scripts before relying
on their advertised features and run checks appropriate to the change:

```bash
npm test -- --runInBand
claude plugin validate .
```

Jest tests live in `scripts/__tests__/`; BATS integration tests are in `tests/`.
Do not execute migrations, connect to remote hosts or alter real Studio databases
to test documentation or packaging. Use temporary fixtures and mocked CLIs.

The plugin manifest is `.claude-plugin/plugin.json`; `plugin/manifest.json` is legacy
metadata and is not a Claude Code loader configuration. No permission or model
settings changes are required to use this skill. See [installation](docs/INSTALLATION.md).

This repository will use Shell Scripts, it is better to interact with WP CLI and DB queries.
