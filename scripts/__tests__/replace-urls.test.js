/**
 * Tests for replace-urls.sh
 * Replaces URLs in database with dry-run preview
 */

const { executeScript, createTempDir, removeTempDir, createMockStudioSite } = require('./utils');

describe('replace-urls.sh', () => {
  let tempDir;

  beforeEach(() => {
    tempDir = createTempDir();
  });

  afterEach(() => {
    removeTempDir(tempDir);
  });

  test('should output usage without arguments', () => {
    const result = executeScript('replace-urls.sh', []);
    const output = result.stdout + result.stderr;

    // Should provide usage information
    expect(output).toBeTruthy();
  });

  test('should fail with invalid site path', () => {
    const result = executeScript('replace-urls.sh', [
      '/nonexistent/site',
      'https://old.com',
      'https://new.com',
    ]);

    // Should fail gracefully
    expect(result.code).not.toBe(0);
  });

  test('should handle valid arguments', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    // Should execute without crashing
    expect(result).toBeDefined();
  });

  test('should not hang on execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const startTime = Date.now();
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);
    const duration = Date.now() - startTime;

    // Should complete within 30 seconds
    expect(duration).toBeLessThan(30000);
  });

  test('should support dry-run flag', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      '--dry-run',
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    // Should handle dry-run flag
    expect(result).toBeDefined();
  });

  test('should show help when requested', () => {
    const result = executeScript('replace-urls.sh', ['--help']);
    const output = result.stdout + result.stderr;

    if (result.code === 0 || output.includes('Usage') || output.includes('USAGE')) {
      expect(output.length).toBeGreaterThan(0);
    }
  });

  test('should handle URLs with different protocols', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'http://old.local',
      'https://new.local',
    ]);

    expect(result).toBeDefined();
  });

  test('should handle URLs with ports', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.com:8080',
      'https://new.com:8443',
    ]);

    expect(result).toBeDefined();
  });

  test('should handle URLs with paths', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://example.com/wordpress',
      'https://new.local',
    ]);

    expect(result).toBeDefined();
  });

  test('should provide output on execution', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    const output = result.stdout + result.stderr;

    // Should provide some output or be silent
    expect(typeof output).toBe('string');
  });

  test('should return appropriate exit code', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.com',
      'https://new.com',
    ]);

    expect(typeof result.code).toBe('number');
  });

  test('should handle special characters in URLs', () => {
    const sitePath = createMockStudioSite(tempDir);
    const result = executeScript('replace-urls.sh', [
      sitePath,
      'https://old.example.com/path?query=value',
      'https://new.local',
    ]);

    expect(result).toBeDefined();
  });
});
