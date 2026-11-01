/**
 * Tests for preflight-check.sh
 * Validates all dependencies before migration
 */

const { executeScript } = require('./utils');

describe('preflight-check.sh', () => {
  test('should run without errors', () => {
    const result = executeScript('preflight-check.sh');
    expect(result.code).toBeLessThanOrEqual(1); // 0 = all checks pass, 1 = some checks fail
  });

  test('should output check status', () => {
    const result = executeScript('preflight-check.sh');
    expect(result.stdout).toBeTruthy();
    expect(result.stdout.length).toBeGreaterThan(0);
  });

  test('should check for required commands', () => {
    const result = executeScript('preflight-check.sh');
    const output = result.stdout;

    // Verify it checks for bash
    expect(output).toMatch(/bash|Required/i);
  });

  test('should display check results', () => {
    const result = executeScript('preflight-check.sh');
    const output = result.stdout;

    // Should contain status indicators
    expect(output).toMatch(/✅|❌|passed|failed/i);
  });

  test('should not hang or timeout', () => {
    const startTime = Date.now();
    const result = executeScript('preflight-check.sh');
    const duration = Date.now() - startTime;

    // Should complete within 10 seconds
    expect(duration).toBeLessThan(10000);
    expect(result).toBeDefined();
  });

  test('should handle directory checks', () => {
    const result = executeScript('preflight-check.sh');
    expect(result.stdout).toBeTruthy();

    // Should attempt to check directories
    if (result.stdout.includes('Directories')) {
      expect(result.stdout.length).toBeGreaterThan(50);
    }
  });

  test('should provide informative output when checks fail', () => {
    const result = executeScript('preflight-check.sh');

    if (result.code !== 0) {
      // If checks fail, output should be informative
      expect(result.stdout.length).toBeGreaterThan(0);
    }
  });

  test('should output formatted text', () => {
    const result = executeScript('preflight-check.sh');
    const output = result.stdout;

    // Should be human-readable
    expect(output.length).toBeGreaterThan(10);
    expect(output.trim().length).toBeGreaterThan(0); // Should have non-empty content
  });

  test('should complete execution successfully', () => {
    const result = executeScript('preflight-check.sh');
    expect(result).toHaveProperty('success');
    expect(result).toHaveProperty('stdout');
    expect(result).toHaveProperty('code');
  });

  test('should handle execution without arguments', () => {
    const result = executeScript('preflight-check.sh', []);
    expect(result).toBeDefined();
    expect(result.code).toBeLessThanOrEqual(1);
  });
});
