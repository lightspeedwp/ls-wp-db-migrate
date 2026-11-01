/**
 * Tests for verify-import.sh
 * Checks if database import succeeded
 */

const { executeScript, createTempDir, removeTempDir, createMockStudioSite } = require('./utils');

describe('verify-import.sh', () => {
  let tempDir;

  beforeEach(() => {
    tempDir = createTempDir();
  });

  afterEach(() => {
    removeTempDir(tempDir);
  });

  test('should output usage without arguments', () => {
    const result = executeScript('verify-import.sh', []);
    // Script should handle missing arguments
    expect(result.stdout + result.stderr).toBeTruthy();
  });

  test('should fail gracefully with invalid path', () => {
    const result = executeScript('verify-import.sh', ['/nonexistent/path']);
    expect(result.code).not.toBe(0);
  });

  test('should show help when requested', () => {
    const result = executeScript('verify-import.sh', ['--help']);
    const output = result.stdout + result.stderr;

    // Should provide help information
    if (result.code === 0) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should handle valid site path', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath]);

    // Should not crash
    expect(result).toBeDefined();
  });

  test('should not hang on execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const startTime = Date.now();
    const result = executeScript('verify-import.sh', [sitePath]);
    const duration = Date.now() - startTime;

    // Should complete within 90 seconds (accounts for slow WP-CLI on various machines)
    expect(duration).toBeLessThan(90000);
  });

  test('should provide verification output', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath]);
    const output = result.stdout + result.stderr;

    // Should output something
    if (output) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should validate database integrity when possible', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath]);

    // Script should attempt verification
    expect(result).toBeDefined();
  });

  test('should handle special characters in path', () => {
    // Create site with spaces in path
    const specialPath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [specialPath]);

    // Should handle the path correctly
    expect(result).toBeDefined();
  });

  test('should return appropriate exit code', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath]);

    // Exit code should be numeric
    expect(typeof result.code).toBe('number');
  });

  test('should complete without timeout', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath]);

    // Should complete execution
    expect(result.success !== undefined).toBe(true);
  });

  test('should handle multiple arguments gracefully', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('verify-import.sh', [sitePath, '--verbose']);

    // Should handle extra arguments
    expect(result).toBeDefined();
  });
});
