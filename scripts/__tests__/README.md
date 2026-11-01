# Test Suite: WordPress Database Migration

Comprehensive test coverage for the wp-db-migrate skill and plugin.

## What's Here

- **Unit Tests** — Test individual script functions and libraries
- **Integration Tests** — Test the complete 5-stage migration workflow
- **Mocks** — Fake Studio CLI, SSH, and database responses
- **Fixtures** — Sample database exports and configuration files
- **Jest Config** — Test runner configuration (JEST-SETUP.md for details)

## Running Tests

### Run All Tests
```bash
npm test
```

### Run Specific Test File
```bash
npm test -- migrate-recovery.test.js
```

### Run with Coverage Report
```bash
npm test -- --coverage
```

### Watch Mode (auto-rerun on changes)
```bash
npm test -- --watch
```

## Test Organization

```
__tests__/
├── unit/
│   ├── lib-ssh.test.js           # SSH operations
│   ├── lib-compress.test.js      # Compression/decompression
│   ├── lib-database.test.js      # Database validation
│   └── lib-*.test.js             # Other libraries
├── integration/
│   ├── migrate-full-workflow.test.js   # Complete migration
│   ├── migrate-recovery.test.js        # Recovery workflow
│   └── error-handling.test.js          # Failure scenarios
├── fixtures/
│   ├── sample-export.sql         # Small test database
│   ├── large-export.sql.gz       # Large test database
│   └── mock-responses.js         # Fake API responses
└── mocks/
    ├── studio-cli.mock.js        # Mock studio command
    ├── wp-cli.mock.js            # Mock wp command
    └── ssh.mock.js               # Mock SSH operations
```

## Key Test Scenarios

### Unit Tests
- ✅ SSH connection validation
- ✅ Compression/decompression
- ✅ Database export parsing
- ✅ URL replacement logic
- ✅ Error detection and recovery

### Integration Tests
- ✅ Full 5-stage workflow
- ✅ Table exclusion
- ✅ Backup and rollback
- ✅ URL replacement verification
- ✅ Post-import validation
- ✅ Timeout handling
- ✅ Disk space checking
- ✅ SSH connection failures
- ✅ Corrupted database handling

### Coverage Goals
- **Line Coverage**: > 90%
- **Branch Coverage**: > 85%
- **Function Coverage**: > 90%

## Adding New Tests

### Test Structure
```javascript
describe('Feature Name', () => {
  beforeEach(() => {
    // Setup
  });

  test('should do X when Y', () => {
    // Arrange
    const input = {...};
    
    // Act
    const result = functionUnderTest(input);
    
    // Assert
    expect(result).toBe(expected);
  });

  afterEach(() => {
    // Cleanup
  });
});
```

### Running Test Suite Before Commit
```bash
npm run test:all      # Run all tests + lint + coverage
npm run test:unit     # Unit tests only
npm run test:int      # Integration tests only
```

## Test Fixtures

### Sample Databases
- `fixtures/sample-export.sql` — 50 MB MySQL export (< 2 sec to process)
- `fixtures/large-export.sql.gz` — 500 MB gzipped export (realistic size)
- `fixtures/corrupted-export.sql` — Intentionally broken SQL for error testing

### Mock Responses
All external calls are mocked to avoid needing:
- Real WordPress Studio installed
- Real SSH access to servers
- Real databases

## Debugging Tests

### See Detailed Output
```bash
npm test -- --verbose
```

### Run Single Test
```bash
npm test -- migrate-recovery.test.js --testNamePattern="should handle"
```

### Enable Debugging
```bash
DEBUG=* npm test -- migrate-recovery.test.js
```

### VS Code Debugging
1. Set breakpoint in test file
2. Run: `node --inspect-brk node_modules/.bin/jest --runInBand`
3. Open `chrome://inspect` in DevTools

## Coverage Report

After running tests with coverage:
```bash
npm test -- --coverage
open coverage/lcov-report/index.html
```

This shows:
- Line-by-line coverage
- Branch coverage
- Uncovered lines highlighted
- File-by-file summary

## Pre-Push Verification

The test suite runs automatically before push via lefthook:
```bash
npm run test:all     # Runs unit + integration + coverage
```

If tests fail, the push is blocked. Fix the test, then:
```bash
git push
```

## Common Test Issues

### Timeout Errors
Increase jest timeout in test file:
```javascript
jest.setTimeout(10000); // 10 seconds
```

### Mock Not Matching
Check that mock setup matches the actual function call:
```javascript
jest.mock('../ssh', () => ({
  ssh_export: jest.fn().mockResolvedValue(...)
}));
```

### Coverage Gap
Run with `--verbose` to see which lines aren't covered, then:
1. Add test case for that scenario
2. Or document why it's not testable

## Continuous Integration

Tests run on every:
- **Push** — Local pre-push hook (lefthook)
- **Pull Request** — GitHub Actions CI
- **Pre-release** — Full test suite + coverage requirements

Current CI status: ✅ All 192 tests passing

---

**For test framework details:** See [JEST-SETUP.md](../JEST-SETUP.md)  
**For testing guide:** See [TESTING.md](../TESTING.md)  
**For coverage trends:** See [TEST-SUMMARY.md](../TEST-SUMMARY.md)
