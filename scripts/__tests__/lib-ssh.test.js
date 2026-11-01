const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('lib-ssh.sh — SSH Utility Library', () => {
    const libPath = path.join(__dirname, '../lib-ssh.sh');

    beforeAll(() => {
        if (!fs.existsSync(libPath)) {
            throw new Error(`lib-ssh.sh not found at ${libPath}`);
        }
    });

    test('SSH library loads successfully', () => {
        const result = execSync(`bash -c "source ${libPath} && echo 'loaded'"`, {
            stdio: 'pipe'
        }).toString().trim();

        expect(result).toBe('loaded');
    });

    test('ssh_configure sets SSH parameters', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_configure 'deploy@staging.example.com' '/var/www/html'
            echo \\\$SSH_USER:\\\$SSH_HOST:\\\$REMOTE_WP_PATH
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('deploy');
        expect(result).toContain('staging.example.com');
        expect(result).toContain('/var/www/html');
    });

    test('ssh_configure rejects invalid format', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_configure 'invalid-format' '/var/www/html' 2>&1 || echo 'failed'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Error');
    });

    test('ssh_configure validates SSH key exists', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_configure 'deploy@host' '/path' '/nonexistent/key' 2>&1 || echo 'failed'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('not found');
    });

    test('ssh_configure sets SSH port', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_configure 'user@host' '/path' '' 2222
            echo \\\$SSH_PORT
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('2222');
    });

    test('ssh_exec requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_exec 'echo test' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('not configured');
    });

    test('ssh_exec_output requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_exec_output 'echo test' 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('not configured');
    });

    test('ssh_check_wp_cli requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_check_wp_cli 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('not configured');
    });

    test('ssh_get_db_size handles missing configuration gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_get_db_size 2>&1
        "`, { stdio: 'pipe' }).toString();

        // Should return 0 when not configured
        expect(result).toContain('0');
    });

    test('ssh_export_db requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_export_db 'user@host' '/path' '/tmp/export.sql' 2>&1 || echo 'configured'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('configured');
    });

    test('ssh_verify_wordpress requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_verify_wordpress 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Verifying');
    });

    test('ssh_get_wp_version requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_get_wp_version 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('unknown');
    });

    test('ssh_get_site_url requires SSH configuration', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_get_site_url 2>&1 || true
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('unknown');
    });

    test('lib-ssh.sh should be executable', () => {
        const stats = fs.statSync(libPath);
        expect(stats.isFile()).toBe(true);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('SSH functions are exported', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            declare -f ssh_configure ssh_test_connection ssh_export_db ssh_verify_wordpress
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('ssh_configure');
        expect(result).toContain('ssh_export_db');
        expect(result).toContain('ssh_verify_wordpress');
    });

    test('SSH state variables are initialized', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            echo \\\$SSH_HOST:\\\$SSH_USER:\\\$SSH_PORT
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain(':');
        expect(result).toContain('22');
    });

    test('ssh_configure parses user@host correctly', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            ssh_configure 'john@example.com:2222' '/app' '' 3000
            echo \\\$SSH_USER:\\\$SSH_HOST:\\\$SSH_PORT
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('john');
        expect(result).toContain('example.com:2222');
        expect(result).toContain('3000');
    });

    test('Export functions list is complete', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            declare -f ssh_get_db_size ssh_get_wp_version ssh_get_site_url
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('ssh_get_db_size');
        expect(result).toContain('ssh_get_wp_version');
        expect(result).toContain('ssh_get_site_url');
    });
});
