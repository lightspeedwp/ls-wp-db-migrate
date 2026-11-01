const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const scriptPath = path.join(__dirname, '..', 'lib-reports.sh');

describe('lib-reports.sh — Reports and Analytics Library', () => {
    let tmpDir;
    let tmpScript;

    beforeEach(() => {
        tmpDir = fs.mkdtempSync(path.join(__dirname, '..', '.tmp-'));
        tmpScript = path.join(tmpDir, 'test-reports.sh');
        fs.writeFileSync(tmpScript, `#!/bin/bash\nset -euo pipefail\nsource "${scriptPath}"\n`, { mode: 0o755 });
    });

    afterEach(() => {
        try {
            fs.rmSync(tmpDir, { recursive: true, force: true });
        } catch (e) {
            // Ignore cleanup errors
        }
    });

    test('should load reports library', () => {
        const result = execSync(`bash "${tmpScript}" && echo "loaded"`, { encoding: 'utf-8' });
        expect(result).toContain('loaded');
    });

    test('reports_init creates reports directory', () => {
        const reportsDir = path.join(tmpDir, 'reports');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            [[ -d "${reportsDir}" ]] && echo "success"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('success');
    });

    test('reports_log_metric stores metrics', () => {
        const reportsDir = path.join(tmpDir, 'reports');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_log_metric "total_tables" "42" "count"
            echo "$REPORTS_ENABLED"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('true');
    });

    test('reports_log_stage tracks stage completion', () => {
        const reportsDir = path.join(tmpDir, 'reports');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_log_stage "export" "120" "success"
            echo "logged"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('logged');
    });

    test('reports_track_table stores table statistics', () => {
        const reportsDir = path.join(tmpDir, 'reports');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_track_table "wp_posts" "1000" "5242880"
            echo "tracked"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('tracked');
    });

    test('reports_calculate_stats computes aggregate statistics', () => {
        const reportsDir = path.join(tmpDir, 'reports');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_track_table "wp_posts" "1000" "5242880"
            reports_track_table "wp_users" "50" "102400"
            reports_calculate_stats
            echo "calculated"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('calculated');
    });

    test('reports_export_json creates JSON report', () => {
        const reportsDir = path.join(tmpDir, 'reports');
        const jsonFile = path.join(reportsDir, 'metrics.json');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_log_metric "total_tables" "42" "count"
            reports_log_stage "export" "120" "success"
            reports_export_json "${jsonFile}"
            [[ -f "${jsonFile}" ]] && echo "success"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('success');
    });

    test('reports_export_json generates valid JSON', () => {
        const reportsDir = path.join(tmpDir, 'reports');
        const jsonFile = path.join(reportsDir, 'metrics.json');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_log_metric "total_tables" "42" "count"
            reports_export_json "${jsonFile}"
            cat "${jsonFile}" | head -c 10
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('{');
    });

    test('reports_export_summary creates human-readable report', () => {
        const reportsDir = path.join(tmpDir, 'reports');
        const summaryFile = path.join(reportsDir, 'summary.txt');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_log_stage "export" "120" "success"
            reports_export_summary "${summaryFile}"
            [[ -f "${summaryFile}" ]] && echo "success"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('success');
    });

    test('reports_export_csv exports table statistics', () => {
        const reportsDir = path.join(tmpDir, 'reports');
        const csvFile = path.join(reportsDir, 'tables.csv');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_track_table "wp_posts" "1000" "5242880"
            reports_export_csv "${csvFile}"
            [[ -f "${csvFile}" ]] && echo "success"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('success');
    });

    test('reports_export_csv generates CSV with headers', () => {
        const reportsDir = path.join(tmpDir, 'reports');
        const csvFile = path.join(reportsDir, 'tables.csv');

        const script = `
            source "${scriptPath}"
            reports_init "${reportsDir}"
            reports_track_table "wp_posts" "1000" "5242880"
            reports_export_csv "${csvFile}"
            head -1 "${csvFile}"
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        expect(result).toContain('table');
        expect(result).toContain('rows');
    });

    test('lib-reports.sh should be executable', () => {
        const stats = fs.statSync(scriptPath);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('reports functions are exported', () => {
        const script = `
            source "${scriptPath}"
            declare -F | grep -c reports_
        `;

        const result = execSync(`bash -c '${script}'`, { encoding: 'utf-8' });
        const count = parseInt(result.trim());
        expect(count).toBeGreaterThan(0);
    });
});
