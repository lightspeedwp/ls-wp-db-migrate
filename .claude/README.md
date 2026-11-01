# Claude Code Configuration

Project-level configuration for Claude Code, Claude Skills, and Claude Agents.

## Structure

````bash
.claude/
├── README.md              # This file
├── settings.json          # Project settings and configuration
├── agents/                # Claude Agent definitions
│   └── wp-db-migrate-developer.md
├── skills/                # Claude Skills (symlinks or copies)
│   └── (skills linked from project)
└── prompts/               # System prompts and agent instructions
    └── (custom prompts)
```bash

## Configuration Files

### settings.json
Main configuration file for this Claude Code project.

**Key Sections:**
- `projectName` — Display name in Claude Code
- `defaultModel` — Default Claude model (opus-5-5 recommended)
- `codeStyle` — Code formatting preferences
- `testing` — Test framework and coverage thresholds
- `git` — Git workflow configuration
- `permissions` — Tool access and restrictions
- `documentation` — Project documentation structure
- `skills` — Enabled skills for the project
- `agents` — Enabled agents for the project

**Important settings:**
```json
{
  "testing": {
    "framework": "jest",
    "coverage": { "lines": 100 },
    "commands": {
      "unit": "npm test",
      "integration": "npm run test:bats",
      "all": "npm run test:all"
    }
  }
}
```bash

## Agents

Claude Agents are AI-powered helpers configured for specific workflows.

### wp-db-migrate-developer.md
Configure Claude to work on wp-db-migrate development.

**When to enable:**
- Working on skill or plugin code
- Writing or modifying scripts
- Adding tests
- Contributing to the project

**Capabilities:**
- Understands project structure and conventions
- Knows test coverage requirements (100%)
- Enforces documentation updates
- Knows Bash 3.2+ compatibility needs

**Using the agent:**
```bash
# Claude Code will suggest this agent when appropriate
# Or you can explicitly ask to use it
```bash

## Skills

Claude Skills extend Claude's capabilities for specific tasks.

**Project skills:**
- `wp-db-migrate` — Built-in skill for database migration

**Using skills:**
```bash
# In Claude Code or a chat
/wp-db-migrate

# With arguments
/wp-db-migrate --help
```bash

## Prompts

Custom system prompts and instructions for specific workflows.

**Location:** `.claude/prompts/` (create as needed)

**Usage:**
- System-wide agent instructions
- Workflow-specific guidance
- Quality gate definitions

## Development Workflow

### Using Agents in Development

1. **Open a coding task:** "Implement feature X"
2. **Claude suggests:** "Use wp-db-migrate-developer agent?"
3. **Accept:** Claude loads the agent configuration
4. **Work:** Agent provides relevant context and enforces standards
5. **Commit:** Agent helps with conventional commits

### Test Coverage Gate

The agent enforces 100% test coverage:
```json
"testing": {
  "coverage": {
    "branches": 100,
    "functions": 100,
    "lines": 100,
    "statements": 100
  }
}
```bash

Before committing, the agent verifies:
```bash
npm run test:all    # All tests pass
npm test            # Jest passes with coverage
npm run test:bats   # BATS integration tests pass
```bash

## Integration with settings.json

### Code Style
```json
"codeStyle": {
  "indentation": "spaces",
  "indentSize": 2
}
```bash

### Git Workflow
```json
"git": {
  "branchPrefix": "wp-db",
  "commitFormat": "conventional"
}
```bash

Branch names follow pattern: `wp-db-{feature-name}`
Commits follow convention: `type: description`

### Permissions
```json
"permissions": {
  "requiredTools": ["bash", "node", "npm", "git"],
  "restrictedOperations": ["force-push", "hard-reset"]
}
```bash

These settings are enforced when using agents.

## Extending Configuration

### Adding a New Agent

1. Create `.claude/agents/my-agent.md`
2. Follow the template from `wp-db-migrate-developer.md`
3. Define capabilities and constraints
4. Add to `settings.json`:
   ```json
   "agents": {
     "enabled": ["wp-db-migrate-developer", "my-agent"]
   }
````

### Adding Project Skills

1. Symlink skill from `.github/skills/`:
   ```bash
   ln -s /path/to/skill .claude/skills/my-skill
   ```
2. Register in `settings.json`:
   ```json
   "skills": {
     "enabled": ["wp-db-migrate", "my-skill"]
   }
   ```

### Custom Prompts

1. Create `.claude/prompts/my-prompt.md`
2. Define system instructions
3. Reference in agents or settings as needed

## Validation

Ensure configuration is valid:

````bash
# Validate JSON syntax
node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json'))"

# Check agent files exist
ls -la .claude/agents/

# Verify referenced skills
ls -la .claude/skills/
```bash

## Related Files

- [settings.json](./.claude/settings.json) — Configuration source
- [agents/](./agents/) — Agent definitions
- [../CLAUDE.md](../CLAUDE.md) — Project-level Claude instructions
- [../AGENTS.md](../AGENTS.md) — Agent definitions index

## Troubleshooting

**Agent not appearing:**
- Verify agent file exists in `.claude/agents/`
- Check filename matches pattern: `*.md`
- Ensure YAML frontmatter is present

**Settings not applying:**
- Validate `settings.json` syntax
- Restart Claude Code
- Check file permissions

**Skills not loading:**
- Verify skill path in symlink
- Check symlink targets exist
- Validate `settings.json` references

## Documentation

For more information:
- [Main README](../README.md) — Project overview
- [Agent Guide](agents/wp-db-migrate-developer.md) — Developer agent
- [GitHub Configuration](../README.md) — GitHub setup
- [Claude Code Docs](https://claude.com/docs) — Official documentation
````
