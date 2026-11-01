# Agent guidance

Read [CLAUDE.md](CLAUDE.md) for repository maintenance and [SKILL.md](SKILL.md) for
migration workflows. This repository is a parent skill with five focused sub-skills
in `skills/`; these share root `scripts/`, `lib/`, `docs/` and `evals/`.

Preserve existing uncommitted work. Keep instructions aligned with actual CLI
behaviour and avoid unsupported claims about backups, rollback or dry-run safety.
Validate packaging without touching live databases. Do not commit or push unless
requested. Installation and invocation: [docs/INSTALLATION.md](docs/INSTALLATION.md).
