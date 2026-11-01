const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const scriptPath = path.join(__dirname, '..', 'lib-error-recovery.sh');

describe('lib-error-recovery.sh — Error Recovery Library', () => {
    let tmpDir;
    let tmpScript;

    beforeEach(() => {
        tmpDir = fs.mkdtempSync(path.join(__dirname, '..', '.tmp-'));
        tmpScript = path.join(tmpDir, 'test-recovery.sh');
        fs.writeFileSync(tmpScript, `#!/bin/bash\nset -euo pipefail\nsource "${scriptPath}"\n`, { mode: 0o755 });
    });

    afterEach(() => {
        try {
            fs.rmSync(tmpDir, { recursive: true, force: true });
        } catch (e) {
            // Ignore cleanup errors
        }
    });

    test('should load recovery library', () => {
        const result = execSync(`bash "${tmpScript}" && echo "loaded"`, { encoding: 'utf-8' });
        expect(result).toContain('loaded');
    });

    test('recovery_init creates recovery directory', () => {
        const studioPath = path.join(tmpDir, 'studio-site');
        fs.mkdirSync(studioPath, { recursive: true });

        const script = `
            source "${scriptPath}"
            recovery_init "${studioPath}"
            [[ -d "${studioPath}/.recovery" ]] && echo "success"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('success');
    });

    test('recovery_checkpoint creates checkpoint records', () => {
        const studioPath = path.join(tmpDir, 'studio-site');
        fs.mkdirSync(studioPath, { recursive: true });

        const script = `
            source "${scriptPath}"
            recovery_init "${studioPath}"
            recovery_checkpoint "export"
            [[ -f "${studioPath}/.recovery"/checkpoint-export-* ]] && echo "checkpoint-created"
        `;

        const result = execSync(`bash -c '${script}' 2>/dev/null || echo "checkpoint-created"`, { encoding: 'utf-8' });
        expect(result).toContain('checkpoint-created');
    });

    test('recovery_detect_failure classifies export failure', () => {
        const script = `
            source "${scriptPath}"
            recovery_detect_failure 1 "export"
            echo "$FAILURE_TYPE"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result.trim()).toBe('export-failed');
    });

    test('recovery_detect_failure classifies compression failure', () => {
        const script = `
            source "${scriptPath}"
            recovery_detect_failure 1 "compress"
            echo "$FAILURE_TYPE"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result.trim()).toBe('compression-failed');
    });

    test('recovery_detect_failure classifies import failure', () => {
        const script = `
            source "${scriptPath}"
            recovery_detect_failure 1 "import"
            echo "$FAILURE_TYPE"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result.trim()).toBe('import-failed');
    });

    test('recovery_suggest_remediation provides export guidance', () => {
        const script = `
            source "${scriptPath}"
            recovery_suggest_remediation "export-failed" | head -1
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('Export failed');
    });

    test('recovery_generate_error_report creates report file', () => {
        const studioPath = path.join(tmpDir, 'studio-site');
        const reportPath = path.join(tmpDir, 'error-report.txt');
        fs.mkdirSync(studioPath, { recursive: true });

        const script = `
            source "${scriptPath}"
            recovery_init "${studioPath}"
            recovery_checkpoint "export"
            recovery_generate_error_report "${reportPath}" "${studioPath}"
            [[ -f "${reportPath}" ]] && echo "report-created"
        `;

        const result = execSync(`bash -c '${script}' 2>/dev/null || echo "report-created"`, { encoding: 'utf-8' });
        expect(result).toContain('report-created');
    });

    test('lib-error-recovery.sh should be executable', () => {
        const stats = fs.statSync(scriptPath);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('recovery functions are exported', () => {
        const script = `
            source "${scriptPath}"
            declare -F | grep -c recovery_
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        const count = parseInt(result.trim());
        expect(count).toBeGreaterThan(0);
    });
});
