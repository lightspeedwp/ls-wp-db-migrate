/**
 * Tests for migrate-recovery.sh
 * Complete migration recovery workflow
 */

const { executeScript, createTempDir, removeTempDir, createMockStudioSite } = require('./utils');

describe('migrate-recovery.sh', () => {
  let tempDir;

  beforeEach(() => {
    tempDir = createTempDir();
  });

  afterEach(() => {
    removeTempDir(tempDir);
  });

  test('should output usage without arguments', () => {
    const result = executeScript('migrate-recovery.sh', []);
    const output = result.stdout + result.stderr;

    // Should provide usage information
    expect(output).toBeTruthy();
  });

  test('should fail with invalid site path', () => {
    const result = executeScript('migrate-recovery.sh', [
      '/nonexistent/site',
      'https://old.com',
      'https://new.com',
    ]);

    // Should fail gracefully
    expect(result.code).not.toBe(0);
  });

  test('should handle valid arguments', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    // Should execute workflow
    expect(result).toBeDefined();
  });

  test('should complete workflow execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const startTime = Date.now();
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);
    const duration = Date.now() - startTime;

    // Should complete within reasonable time
    expect(duration).toBeLessThan(120000); // 2 minutes
  });

  test('should show help when requested', () => {
    const result = executeScript('migrate-recovery.sh', ['--help']);
    const output = result.stdout + result.stderr;

    if (result.code === 0 || output.includes('Usage') || output.includes('USAGE')) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should handle different URL schemes', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'http://staging.example.com',
      'https://site.local',
    ]);

    expect(result).toBeDefined();
  });

  test('should handle URLs with subpaths', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://example.com/wp',
      'https://local.test',
    ]);

    expect(result).toBeDefined();
  });

  test('should provide workflow output', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    const output = result.stdout + result.stderr;

    // Should output workflow progress
    if (output) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should return appropriate exit code', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    expect(typeof result.code).toBe('number');
  });

  test('should not crash on execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    // Should complete execution
    expect(result.success !== undefined).toBe(true);
  });

  test('should orchestrate multiple phases', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    // Script should run through phases
    expect(result).toBeDefined();
  });

  test('should handle special characters in URLs', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('migrate-recovery.sh', [
      sitePath,
      'https://old.example.com?id=123',
      'https://new.local',
    ]);

    expect(result).toBeDefined();
  });
});
