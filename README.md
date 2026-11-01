# LightSpeed WordPress database migration

A Claude parent skill with focused sub-skills for preparing WordPress MySQL/MariaDB
exports and importing them into local WordPress Studio sites.

## Structure

```text
ls-wp-db-migrate/
├── SKILL.md                         # Parent skill and stage router
├── skills/
│   ├── ls-wp-db-preflight/SKILL.md
│   ├── ls-wp-db-prepare/SKILL.md
│   ├── ls-wp-db-migrate-import/SKILL.md
│   ├── ls-wp-db-verify/SKILL.md
│   └── ls-wp-db-recover/SKILL.md
├── lib/sql-tool.cjs                 # SQL analysis and sanitisation
├── scripts/                         # Shared helpers and Jest tests
├── evals/                           # Behavioural scenarios
├── docs/                            # Supporting guides
└── .claude-plugin/plugin.json       # Optional plugin packaging
```

## Use in Claude Code

With this checkout at `~/.claude/skills/ls-wp-db-migrate/`, start a new Claude Code
session and invoke:

```text
/ls-wp-db-migrate preflight /absolute/path/export.sql /absolute/path/studio-site
/ls-wp-db-migrate prepare /absolute/path/export.sql /absolute/path/studio-site
/ls-wp-db-migrate migrate /absolute/path/prepared.sql /absolute/path/studio-site
/ls-wp-db-migrate verify /absolute/path/studio-site
/ls-wp-db-migrate recover /absolute/path/studio-site
```

The parent loads the relevant nested instructions. Independent sub-skill slash
commands are available through the optional plugin, not through recursive personal
skill discovery. See [installation](docs/INSTALLATION.md) for both modes.

## Validation

```bash
npm test -- --runInBand
claude plugin validate .
```

Migration instructions start at [SKILL.md](SKILL.md). The bundled SQL tool runs with
`node lib/sql-tool.cjs`; inspect its usage before running it. Back up the local target
before importing. Legacy helpers have incomplete workflows: recovery helpers do not
import, and the clone orchestrator is not the local-file import path.

Existing detailed guides in `docs/` may describe older CLI versions; prefer installed
CLI help and the maintained skill instructions when they disagree. No live migration
is required to install or validate the skill.
