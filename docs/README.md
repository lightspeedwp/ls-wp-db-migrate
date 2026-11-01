# Documentation Index

Complete guide to all documentation for the WordPress Database Migration skill and CLI tools.

## Quick Navigation

| Document                                   | Best For                                       | Read Time |
| ------------------------------------------ | ---------------------------------------------- | --------- |
| [INSTALLATION.md](INSTALLATION.md)         | Setting up the skill and CLI tools             | 5 min     |
| [TESTING.md](TESTING.md)                   | Understanding the test suite (Jest + BATS)     | 10 min    |
| [TEST-SUMMARY.md](TEST-SUMMARY.md)         | Viewing test results and coverage metrics      | 3 min     |
| [JEST-SETUP.md](JEST-SETUP.md)             | Configuring Jest and running unit tests        | 8 min     |
| [OPTIMIZATION.md](OPTIMIZATION.md)         | Speeding up migrations and database operations | 7 min     |
| [STUDIO-CLI-GUIDE.md](STUDIO-CLI-GUIDE.md) | Using WordPress Studio CLI commands            | 12 min    |

## Documentation by Use Case

### I'm New — Getting Started

1. Read [Main README](../README.md) for overview
2. Follow [INSTALLATION.md](INSTALLATION.md) to install
3. See [../scripts/README.md](../README.md) for quick command reference

### I Need to Migrate a Database

1. Run `./scripts/preflight-check.sh` to verify setup
2. Follow instructions in [../README.md](../README.md) → "💡 Usage Examples"
3. Refer to [STUDIO-CLI-GUIDE.md](STUDIO-CLI-GUIDE.md) for troubleshooting

### I Want to Run Tests

1. Install dependencies: `npm install`
2. Read [TESTING.md](TESTING.md) for complete guide
3. Run `npm test` for Jest, `npm run test:bats` for BATS, or `npm run test:all` for both
4. See [TEST-SUMMARY.md](TEST-SUMMARY.md) for current results

### I'm Optimizing Performance

1. Start with [OPTIMIZATION.md](OPTIMIZATION.md)
2. Check [JEST-SETUP.md](JEST-SETUP.md) for test performance tuning
3. Review [STUDIO-CLI-GUIDE.md](STUDIO-CLI-GUIDE.md) for CLI optimization

### I'm Contributing or Extending

1. Read [TESTING.md](TESTING.md) to understand test structure
2. Review [JEST-SETUP.md](JEST-SETUP.md) for configuration
3. See [IMPROVEMENTS.md](IMPROVEMENTS.md) for roadmap

## Document Overview

**INSTALLATION.md** — Complete setup guide covering:

- Prerequisites and dependencies
- Installation as Claude skill, plugin, or CLI
- Verification steps

**TESTING.md** — Testing strategy and execution:

- Jest unit tests (192 passing)
- BATS integration tests (23 passing)
- 100% code coverage enforcement
- Running tests locally and in CI/CD

**TEST-SUMMARY.md** — Current test results:

- Pass/fail counts by script
- Coverage metrics
- Last run timestamp

**JEST-SETUP.md** — Jest configuration details:

- babel.config.js setup
- jest.config.js configuration
- Coverage thresholds
- Custom reporters

**OPTIMIZATION.md** — Performance tuning guide:

- Database optimization
- Script performance tuning
- Import speed improvements
- Memory management

**STUDIO-CLI-GUIDE.md** — WordPress Studio reference:

- CLI command reference
- Workflow examples
- Troubleshooting procedures
- Common issues and solutions

## Navigation Tips

- **Browse by topic:** Use the "Documentation by Use Case" section above
- **Search across docs:** All files use consistent formatting and terminology
- **Links work both directions:** Jump between related documents easily
- **Return to main docs:** Each document links back to this index
