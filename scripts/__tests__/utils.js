/**
 * Test utilities for wp-db-migrate scripts
 */

const { spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

/**
 * Execute a shell script and capture output (safe with spawnSync)
 */
function executeScript(scriptPath, args = []) {
  try {
    const fullPath = path.join(__dirname, '..', scriptPath);

    const result = spawnSync('bash', [fullPath, ...args], {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    return {
      success: result.status === 0,
      stdout: result.stdout || '',
      stderr: result.stderr || '',
      code: result.status || (result.error ? 1 : 0),
    };
  } catch (error) {
    return {
      success: false,
      stdout: '',
      stderr: error.message,
      code: 1,
    };
  }
}

/**
 * Create a temporary directory for testing
 */
function createTempDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'wp-db-migrate-test-'));
}

/**
 * Clean up a temporary directory
 */
function removeTempDir(dirPath) {
  if (fs.existsSync(dirPath)) {
    fs.rmSync(dirPath, { recursive: true, force: true });
  }
}

/**
 * Create a mock studio site structure
 */
function createMockStudioSite(tempDir) {
  const sitePath = path.join(tempDir, 'test-site');
  fs.mkdirSync(sitePath, { recursive: true });

  // Create WordPress directory structure
  fs.mkdirSync(path.join(sitePath, 'wp-content'), { recursive: true });
  fs.mkdirSync(path.join(sitePath, 'wp-content', 'debug.log'), { recursive: true });

  // Create a mock wp-config.php
  fs.writeFileSync(path.join(sitePath, 'wp-config.php'), `<?php
// Mock WordPress configuration
define('DB_NAME', 'test_db');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_pass');
define('DB_HOST', 'localhost');
?>`);

  return sitePath;
}

/**
 * Verify file exists and contains content
 */
function fileExists(filePath) {
  return fs.existsSync(filePath);
}

/**
 * Read file content
 */
function readFile(filePath) {
  if (fs.existsSync(filePath)) {
    return fs.readFileSync(filePath, 'utf-8');
  }
  return '';
}

/**
 * Write test data file
 */
function writeTestFile(filePath, content) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(filePath, content);
}

module.exports = {
  executeScript,
  createTempDir,
  removeTempDir,
  createMockStudioSite,
  fileExists,
  readFile,
  writeTestFile,
};
