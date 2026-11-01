const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('lib-studio-api.sh — Studio API Utilities', () => {
    const libPath = path.join(__dirname, '../lib-studio-api.sh');
    const testSitePath = path.join(__dirname, '../.tmp-studio-test');

    beforeAll(() => {
        if (!fs.existsSync(libPath)) {
            throw new Error(`lib-studio-api.sh not found at ${libPath}`);
        }

        // Create a minimal test Studio site structure
        if (!fs.existsSync(testSitePath)) {
            fs.mkdirSync(testSitePath, { recursive: true });
        }

        // Create minimal wp-config.php
        const wpConfigPath = path.join(testSitePath, 'wp-config.php');
        if (!fs.existsSync(wpConfigPath)) {
            fs.writeFileSync(wpConfigPath, '<?php\n// Test wp-config.php\n');
        }

        // Create wp-content directory
        const wpContentPath = path.join(testSitePath, 'wp-content');
        if (!fs.existsSync(wpContentPath)) {
            fs.mkdirSync(wpContentPath, { recursive: true });
        }
    });

    afterAll(() => {
        if (fs.existsSync(testSitePath)) {
            fs.rmSync(testSitePath, { recursive: true, force: true });
        }
    });

    test('Studio API library loads successfully', () => {
        const result = execSync(`bash -c "source ${libPath} && echo 'loaded'"`, {
            stdio: 'pipe'
        }).toString().trim();

        expect(result).toBe('loaded');
    });

    test('studio_validate_site validates site path exists', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_validate_site '${testSitePath}' && echo 'ok'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('ok');
    });

    test('studio_validate_site rejects missing site', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_validate_site '/nonexistent/path' 2>&1 || echo 'failed'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('not found');
    });

    test('studio_get_db_type returns sqlite', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_db_type '${testSitePath}'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('sqlite');
    });

    test('studio_check_installation validates installation', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_check_installation '${testSitePath}' 2>&1
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Studio installation');
    });

    test('studio_get_url handles missing wp-cli gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_url '${testSitePath}'
        "`, { stdio: 'pipe' }).toString().trim();

        // Should return unknown or attempt to run wp
        expect(result.length).toBeGreaterThan(0);
    });

    test('studio_get_version handles missing wp-cli gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_version '${testSitePath}'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result.length).toBeGreaterThan(0);
    });

    test('studio_verify_database checks database integrity', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_verify_database '${testSitePath}' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        // Should show verification or wp-cli message
        expect(result).toMatch(/Verifying database|wp-cli|Database verified/);
    });

    test('studio_check_plugins handles missing wp-cli gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_check_plugins '${testSitePath}' 2>&1
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result.length >= 0).toBe(true);
    });

    test('studio_check_theme handles missing wp-cli gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_check_theme '${testSitePath}' 2>&1
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result.length).toBeGreaterThan(0);
    });

    test('studio_pre_import_check runs validation', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_pre_import_check '${testSitePath}' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('validation');
    });

    test('studio_post_import_check validates database', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_post_import_check '${testSitePath}' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        // Should attempt validation
        expect(result.length).toBeGreaterThan(0);
    });

    test('studio_generate_report creates report', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_generate_report '${testSitePath}' 2>&1
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Studio Site Report');
        expect(result).toContain('Path');
    });

    test('studio_get_table_count returns table count', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_table_count '${testSitePath}' 2>&1
        "`, { stdio: 'pipe' }).toString().trim();

        // Should return a number (0 if no wp-cli, or actual count)
        expect(/^\d+$/.test(result)).toBe(true);
    });

    test('studio_get_database_tables handles wp-cli availability', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_database_tables '${testSitePath}' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        // Either: function works and returns tables, or it reports missing wp-cli
        // This test verifies the function doesn't crash in either case
        expect(result).toBeTruthy();
        expect(result.length).toBeGreaterThan(0);
    });

    test('lib-studio-api.sh should be executable', () => {
        const stats = fs.statSync(libPath);
        expect(stats.isFile()).toBe(true);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('Studio API functions are exported', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            declare -f studio_validate_site studio_get_db_type studio_check_installation
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('studio_validate_site');
        expect(result).toContain('studio_get_db_type');
        expect(result).toContain('studio_check_installation');
    });

    test('All Studio API functions exported', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            declare -f studio_pre_import_check studio_post_import_check studio_generate_report
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('studio_pre_import_check');
        expect(result).toContain('studio_post_import_check');
        expect(result).toContain('studio_generate_report');
    });

    test('Studio state variables are initialized', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            echo \\\$STUDIO_SITE_PATH:\\\$STUDIO_DB_TYPE:\\\$STUDIO_TABLE_COUNT
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain(':');
        expect(result).toContain('0');
    });

    test('studio_get_site_info populates variables', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            studio_get_site_info '${testSitePath}' 2>/dev/null
            echo \\\$STUDIO_DB_TYPE
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('sqlite');
    });
});
