# Integration Tests — BATS

End-to-end shell script testing using BATS (Bash Automated Testing System).

## What This Directory Contains

Integration tests that verify the wp-db-migrate CLI scripts work correctly in real-world scenarios. These tests:

- Execute actual migration scripts in a controlled environment
- Verify all migration phases (analysis, sanitization, import, URL replacement, validation)
- Test error handling and edge cases
- Ensure bash 3.2+ compatibility across macOS and Linux

## Test Files

- **integration.bats** — Complete BATS test suite for all scripts
  - 23 integration tests
  - Covers script existence, executability, help output, and argument validation
  - Mock WordPress Studio site fixture in setup()

## Running Tests

### Install BATS

**macOS:**

```bash
brew install bats-core
```bash

**Linux (Ubuntu/Debian):**
```bash
apt-get install bats
```bash

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local/
```bash

### Run All Tests

```bash
npm run test:bats
```bash

### Run a Single Test File

```bash
bats tests/integration.bats
```bash

### Run with Verbose Output

```bash
bats --verbose tests/integration.bats
```bash

### Run Specific Tests by Name

```bash
bats tests/integration.bats --filter "preflight"
```bash

## Test Structure

BATS tests follow this pattern:

```bash
@test "description of what is tested" {
  # Setup
  run command arg1 arg2
  
  # Assertions
  [ "$status" -eq 0 ]
  [[ "$output" == *"expected text"* ]]
}
```bash

### Common Test Assertions

- `[ "$status" -eq 0 ]` — Exit code is 0 (success)
- `[ "$status" -ne 0 ]` — Exit code is non-zero (failure)
- `[[ "$output" == *"text"* ]]` — Output contains text
- `[[ ! "$output" == *"text"* ]]` — Output does not contain text
- `[ -f "$file" ]` — File exists
- `[ -d "$dir" ]` — Directory exists

## Test Coverage

Tests verify:
- ✅ Scripts exist and are executable
- ✅ Help output (`--help` flag)
- ✅ Argument validation
- ✅ Library file discovery
- ✅ Mock WordPress Studio site interaction
- ✅ Bash 3.2+ compatibility

## Running Jest and BATS Together

Run both test suites:

```bash
npm run test:all
```bash

This runs:
1. Jest unit tests (in `__tests__/`)
2. BATS integration tests (in `tests/`)

## Adding New Tests

To add a new BATS test:

1. Open `tests/integration.bats`
2. Add a new `@test` block at the end
3. Use existing tests as templates
4. Run the suite to verify

Example:

```bash
@test "my-script.sh validates input correctly" {
  run ./scripts/my-script.sh invalid-arg
  [ "$status" -ne 0 ]
  [[ "$output" == *"Error"* ]]
}
```bash

## Troubleshooting

### BATS Not Found
```bash
bats --version  # Check if installed
which bats      # Verify location
```bash

### Test Fails: "command not found"
Ensure scripts are executable:
```bash
chmod +x scripts/*.sh
```bash

### Mock Fixture Issues
Check that `setup()` function creates the mock WordPress Studio site correctly. See the fixture definition in `integration.bats`.

## Bash Compatibility

Tests run on Bash 3.2+ (tested on macOS and Linux). This ensures compatibility across different systems.

## Related Documentation

- [Testing Guide](../docs/TESTING.md) — Complete testing overview
- [Scripts Guide](../scripts/README.md) — Script reference
- [BATS Official Docs](https://github.com/bats-core/bats-core) — BATS documentation
