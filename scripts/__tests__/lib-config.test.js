const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('lib-config.sh — Configuration Parser', () => {
    let testDir;
    let configFile;

    beforeAll(() => {
        testDir = path.join(__dirname, '../.tmp-config-test');
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir, { recursive: true });
        }

        // Create a sample config file
        configFile = path.join(testDir, '.wp-db-migrate.conf');
        const homeDir = process.env.HOME || '/home/user';
        const sampleConfig = `# WordPress Database Migration Configuration
FROM_URL=https://staging.example.com
TO_PATH=${homeDir}/.studio/sites/my-project
SSH_HOST=staging.example.com
SSH_USER=deploy
WP_PATH=/var/www/html
EXCLUDE_TABLES=wp_actionscheduler_logs,wp_cache
COMPRESS=true
PARALLEL_JOBS=4
DRY_RUN=false
VERBOSE=false
`;
        fs.writeFileSync(configFile, sampleConfig);
    });

    afterAll(() => {
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true, force: true });
        }
    });

    test('Config library loads successfully', () => {
        const result = execSync(`bash -c "source ${path.join(__dirname, '../lib-config.sh')} && echo 'loaded'"`, {
            stdio: 'pipe'
        }).toString().trim();

        expect(result).toBe('loaded');
    });

    test('config_load loads configuration file', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_get 'from_url'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('https://staging.example.com');
    });

    test('config_get retrieves stored values', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_get 'ssh_host'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('staging.example.com');
    });

    test('config_get returns default when key missing', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_get 'nonexistent_key' 'default_value'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('default_value');
    });

    test('config_require validates required keys present', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_require 'from_url'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('https://staging.example.com');
    });

    test('config_require_keys validates multiple keys', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_require_keys 'from_url' 'to_path' 'ssh_host'
            echo 'success'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('success');
    });

    test('config_print_summary displays configuration', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_print_summary
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Configuration Summary');
        expect(result).toContain('from_url');
    });

    test('config handles comments in files', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_get 'from_url'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('https://staging.example.com');
    });

    test('config_export_env exports as environment variables', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_export_env
            # In same shell, exported vars are accessible
            echo \\\$WP_DB_MIGRATE_FROM_URL
        "`, { stdio: 'pipe', shell: '/bin/bash' }).toString().trim();

        expect(result).toContain('staging.example.com');
    });

    test('config_clear resets configuration', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            config_load '${configFile}'
            config_clear
            config_get 'from_url' 'empty'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('empty');
    });

    test('lib-config.sh should be executable', () => {
        const libPath = path.join(__dirname, '../lib-config.sh');
        const stats = fs.statSync(libPath);

        expect(stats.isFile()).toBe(true);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('lib-config.sh functions are exported', () => {
        const result = execSync(`bash -c "
            source ${path.join(__dirname, '../lib-config.sh')}
            declare -f config_load config_get config_require config_apply_env_overrides
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('config_load');
        expect(result).toContain('config_get');
        expect(result).toContain('config_require');
    });
});
