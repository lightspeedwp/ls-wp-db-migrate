/**
 * lib-ssh.sh against a fake `ssh` on PATH.
 *
 * The fake records its arguments (one per line) and prints a short dump, so
 * these tests check exactly what would be sent to a remote host without any
 * network access.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const libPath = path.join(__dirname, '../lib-ssh.sh');

let tmpDir;
let argsFile;

/**
 * Write a fake ssh into a fresh bin folder.
 *
 * @param {string} body Shell lines run after the arguments are recorded.
 */
function writeFakeSsh(body = '') {
  const binDir = path.join(tmpDir, 'bin');
  fs.mkdirSync(binDir, { recursive: true });
  const script = [
    '#!/usr/bin/env bash',
    `printf '%s\\n' "$@" > "${argsFile}"`,
    body ||
            [
              "echo '-- MySQL dump 10.13'",
              "echo 'CREATE TABLE wp_options (option_id int);'",
            ].join('\n'),
    '',
  ].join('\n');
  const fakeSsh = path.join(binDir, 'ssh');
  fs.writeFileSync(fakeSsh, script, { mode: 0o755 });
  return binDir;
}

/**
 * Source lib-ssh.sh and run a snippet with the fake ssh first on PATH.
 *
 * @param {string} snippet Bash run after sourcing the library.
 * @param {string} binDir  Folder holding the fake ssh.
 * @param {Object} env     Extra environment variables.
 */
function runWithFakeSsh(snippet, binDir, env = {}) {
  return spawnSync('bash', ['-c', `source "${libPath}"\n${snippet}`], {
    encoding: 'utf8',
    env: { ...process.env, PATH: `${binDir}:${process.env.PATH}`, ...env },
  });
}

/** Arguments the fake ssh received, one array entry per argument. */
function recordedArgs() {
  if (!fs.existsSync(argsFile)) {
    return null;
  }
  return fs.readFileSync(argsFile, 'utf8').replace(/\n$/, '').split('\n');
}

beforeEach(() => {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'lib-ssh-'));
  argsFile = path.join(tmpDir, 'ssh-args.txt');
});

afterEach(() => {
  fs.rmSync(tmpDir, { recursive: true, force: true });
});

describe('lib-ssh.sh remote command building (LS-4797)', () => {
  test('rejects a remote path containing a single quote before calling ssh', () => {
    const binDir = writeFakeSsh();
    const out = path.join(tmpDir, 'out.sql');
    const result = runWithFakeSsh(
      `ssh_export_db 'dev@host.example' "/srv/it's" '${out}'`,
      binDir,
    );

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('Remote WordPress path');
    expect(recordedArgs()).toBeNull();
  });

  test('rejects a relative remote path', () => {
    const result = runWithFakeSsh(
      'ssh_configure \'dev@host.example\' \'var/www\'',
      writeFakeSsh(),
    );

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('must be absolute');
  });

  test('rejects a non-numeric port', () => {
    const result = runWithFakeSsh(
      'ssh_configure \'dev@host.example\' \'/var/www\' \'\' \'22; id\'',
      writeFakeSsh(),
    );

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('SSH port must be a number');
  });

  test('rejects an injected table name before calling ssh', () => {
    const binDir = writeFakeSsh();
    const out = path.join(tmpDir, 'out.sql');
    const result = runWithFakeSsh(
      `ssh_export_db 'dev@host.example' '/srv/www' '${out}' "wp_a,wp_b'; touch PWNED; '"`,
      binDir,
    );

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain('Invalid table name');
    expect(recordedArgs()).toBeNull();
  });

  test('sends one --exclude_tables option for valid exclusions', () => {
    const binDir = writeFakeSsh();
    const out = path.join(tmpDir, 'out.sql');
    const result = runWithFakeSsh(
      `ssh_export_db 'dev@host.example' '/srv/www/example.com' '${out}' 'wp_a,wp_b'`,
      binDir,
    );

    expect(result.status).toBe(0);
    const args = recordedArgs();
    expect(args[args.length - 1]).toBe(
      'cd /srv/www/example.com && wp db export --exclude_tables=wp_a,wp_b -',
    );
    expect(args.join(' ')).not.toContain('--skip-tables');
  });

  test('sends no exclusion option when none are given', () => {
    const binDir = writeFakeSsh();
    const out = path.join(tmpDir, 'out.sql');
    runWithFakeSsh(
      `ssh_export_db 'dev@host.example' '/srv/www' '${out}'`,
      binDir,
    );

    const args = recordedArgs();
    expect(args[args.length - 1]).toBe('cd /srv/www && wp db export -');
  });
});
