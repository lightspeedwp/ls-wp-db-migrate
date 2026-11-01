const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('wp-migrate-clone-to-studio.sh — Phase 2 Orchestration', () => {
    const scriptPath = path.join(__dirname, '../wp-migrate-clone-to-studio.sh');

    test('script should exist and be executable', () => {
        expect(fs.existsSync(scriptPath)).toBe(true);
        const stats = fs.statSync(scriptPath);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('should display help message', () => {
        const result = execSync(`bash "${scriptPath}" --help`, { stdio: 'pipe' }).toString();

        expect(result).toContain('WordPress Database Migration to Studio');
        expect(result).toContain('--from URL');
        expect(result).toContain('--to PATH');
        expect(result).toContain('--compress');
        expect(result).toContain('--parallel');
        expect(result).toContain('--dry-run');
    });

    test('should require --from argument', () => {
        expect.assertions(1);
        try {
            execSync(`bash "${scriptPath}" --to /tmp/test 2>&1`, { stdio: 'pipe' });
            throw new Error('Should have exited with error');
        } catch (e) {
            expect(e.stdout.toString()).toContain('Error: --from URL is required');
        }
    });

    test('should require --to argument', () => {
        expect.assertions(1);
        try {
            execSync(`bash "${scriptPath}" --from https://example.com 2>&1`, { stdio: 'pipe' });
            throw new Error('Should have exited with error');
        } catch (e) {
            expect(e.stdout.toString()).toContain('Error: --to PATH is required');
        }
    });

    test('should validate Studio path exists', () => {
        expect.assertions(1);
        try {
            execSync(`bash "${scriptPath}" --from https://example.com --to /nonexistent/path 2>&1`, { stdio: 'pipe' });
            throw new Error('Should have exited with error');
        } catch (e) {
            expect(e.stdout.toString()).toContain('Error: Studio path not found');
        }
    });

    test('should support --exclude-tables option', () => {
        const result = execSync(`bash "${scriptPath}" --help`, { stdio: 'pipe' }).toString();
        expect(result).toContain('--exclude-tables LIST');
    });

    test('should support --jobs option for parallelism', () => {
        const result = execSync(`bash "${scriptPath}" --help`, { stdio: 'pipe' }).toString();
        expect(result).toContain('--jobs N');
    });

    test('should display options status in banner', () => {
        const tmpDir = fs.mkdtempSync(path.join(__dirname, '..', '.tmp-'));
        try {
            const result = execSync(`bash "${scriptPath}" --from https://example.com --to "${tmpDir}" --dry-run 2>&1`, { stdio: 'pipe' }).toString();

            expect(result).toContain('WordPress Database Migration to Studio');
            expect(result).toContain('https://example.com');
            expect(result).toContain('Compression=');
            expect(result).toContain('Parallel=');
            expect(result).toContain('DRY-RUN MODE');
        } finally {
            fs.rmSync(tmpDir, { recursive: true, force: true });
        }
    });

    test('should support --no-compress flag', () => {
        const result = execSync(`bash "${scriptPath}" --help`, { stdio: 'pipe' }).toString();
        expect(result).toContain('--no-compress');
    });

    test('should support --no-parallel flag', () => {
        const result = execSync(`bash "${scriptPath}" --help`, { stdio: 'pipe' }).toString();
        expect(result).toContain('--no-parallel');
    });

    test('script should be properly formatted', () => {
        const content = fs.readFileSync(scriptPath, 'utf-8');

        expect(content).toContain('set -euo pipefail');
        expect(content).toContain('parse_args()');
        expect(content).toContain('validate_inputs()');
        expect(content).toContain('main()');
    });

    test('script should source optimization libraries', () => {
        const content = fs.readFileSync(scriptPath, 'utf-8');

        expect(content).toContain('source "$SCRIPT_DIR/lib-table-analyzer.sh"');
        expect(content).toContain('source "$SCRIPT_DIR/lib-compress.sh"');
        expect(content).toContain('source "$SCRIPT_DIR/lib-parallel.sh"');
    });

    test('script should define all orchestration steps', () => {
        const content = fs.readFileSync(scriptPath, 'utf-8');

        expect(content).toContain('export_database()');
        expect(content).toContain('analyze_and_optimize()');
        expect(content).toContain('compress_database()');
        expect(content).toContain('import_database()');
        expect(content).toContain('finalize()');
    });

    test('should display color-coded output', () => {
        const content = fs.readFileSync(scriptPath, 'utf-8');

        expect(content).toContain('RED=');
        expect(content).toContain('GREEN=');
        expect(content).toContain('YELLOW=');
        expect(content).toContain('BLUE=');
        expect(content).toContain('CYAN=');
    });

    test('should handle dry-run mode', () => {
        const tmpDir = fs.mkdtempSync(path.join(__dirname, '..', '.tmp-'));
        try {
            const result = execSync(`bash "${scriptPath}" --from https://example.com --to "${tmpDir}" --dry-run 2>&1`, { stdio: 'pipe' }).toString();

            expect(result).toContain('DRY-RUN MODE');
            expect(result).toContain('no changes will be made');
        } finally {
            fs.rmSync(tmpDir, { recursive: true, force: true });
        }
    });
});
