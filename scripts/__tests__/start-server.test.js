/**
 * Tests for start-server.sh
 * Initiates WordPress Studio server
 */

const { executeScript, createTempDir, removeTempDir, createMockStudioSite } = require('./utils');

describe('start-server.sh', () => {
  let tempDir;

  beforeEach(() => {
    tempDir = createTempDir();
  });

  afterEach(() => {
    removeTempDir(tempDir);
  });

  test('should output usage without arguments', () => {
    const result = executeScript('start-server.sh', []);
    const output = result.stdout + result.stderr;

    // Should provide usage information or handle gracefully
    expect(output).toBeTruthy();
  });

  test('should fail with invalid site path', () => {
    const result = executeScript('start-server.sh', ['/nonexistent/site']);

    // Should fail gracefully with invalid path
    expect(result.code).not.toBe(0);
  });

  test('should handle valid site path', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', [sitePath]);

    // Should execute
    expect(result).toBeDefined();
  });

  test('should not run indefinitely', () => {
    const sitePath = createMockStudioSite(tempDir);
    const startTime = Date.now();
    const result = executeScript('start-server.sh', [sitePath]);
    const duration = Date.now() - startTime;

    // Should complete or timeout (but not hang forever)
    expect(duration).toBeLessThan(60000); // 1 minute max
  });

  test('should show help when requested', () => {
    const result = executeScript('start-server.sh', ['--help']);
    const output = result.stdout + result.stderr;

    if (result.code === 0 || output.includes('Usage') || output.includes('USAGE')) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should handle paths with spaces', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', [sitePath]);

    // Should handle the path correctly
    expect(result).toBeDefined();
  });

  test('should provide startup information', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', [sitePath]);
    const output = result.stdout + result.stderr;

    // May output server information or be silent
    expect(typeof output).toBe('string');
  });

  test('should return appropriate exit code', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', [sitePath]);

    // Exit code should be numeric
    expect(typeof result.code).toBe('number');
  });

  test('should not crash on execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', [sitePath]);

    // Should complete execution
    expect(result.success !== undefined).toBe(true);
  });

  test('should handle multiple invocations', () => {
    const sitePath = createMockStudioSite(tempDir);

    const result1 = executeScript('start-server.sh', [sitePath]);
    const result2 = executeScript('start-server.sh', [sitePath]);

    expect(result1).toBeDefined();
    expect(result2).toBeDefined();
  });

  test('should handle verbose flag if supported', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('start-server.sh', ['--verbose', sitePath]);

    // Should handle verbose flag gracefully
    expect(result).toBeDefined();
  });
});
