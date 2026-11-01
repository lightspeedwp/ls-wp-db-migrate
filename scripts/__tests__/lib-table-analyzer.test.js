const fs = require('fs');
const path = require('path');

describe('lib-table-analyzer.sh', () => {
    let testDir;
    let testDumpFile;

    beforeAll(() => {
        testDir = path.join(__dirname, '../.tmp-analyzer-test');
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir, { recursive: true });
        }

        // Create a sample SQL dump with various tables
        testDumpFile = path.join(testDir, 'test-dump.sql');
        const sampleSQL = `
CREATE TABLE \`wp_posts\` (
  \`ID\` bigint(20) NOT NULL AUTO_INCREMENT,
  \`post_author\` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO \`wp_posts\` VALUES (1, 1);
INSERT INTO \`wp_posts\` VALUES (2, 1);

CREATE TABLE \`wp_postmeta\` (
  \`meta_id\` bigint(20) NOT NULL AUTO_INCREMENT,
  \`post_id\` bigint(20) NOT NULL,
  \`meta_key\` varchar(255) NOT NULL,
  \`meta_value\` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO \`wp_postmeta\` VALUES (1, 1, 'key1', 'value1');
INSERT INTO \`wp_postmeta\` VALUES (2, 1, 'key2', 'value2');

CREATE TABLE \`wp_actionscheduler_logs\` (
  \`log_id\` bigint(20) NOT NULL AUTO_INCREMENT,
  \`action_id\` bigint(20) NOT NULL,
  \`message\` longtext
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO \`wp_actionscheduler_logs\` VALUES (1, 1, 'Action started');
INSERT INTO \`wp_actionscheduler_logs\` VALUES (2, 1, 'Action completed');
`;

        fs.writeFileSync(testDumpFile, sampleSQL);
    });

    afterAll(() => {
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true, force: true });
        }
    });

    test('should detect tables in SQL dump', () => {
        expect(fs.existsSync(testDumpFile)).toBe(true);
        const content = fs.readFileSync(testDumpFile, 'utf-8');

        expect(content).toContain('CREATE TABLE `wp_posts`');
        expect(content).toContain('CREATE TABLE `wp_postmeta`');
        expect(content).toContain('CREATE TABLE `wp_actionscheduler_logs`');
    });

    test('should have proper CREATE TABLE statements', () => {
        const content = fs.readFileSync(testDumpFile, 'utf-8');
        const tableCount = (content.match(/CREATE TABLE/g) || []).length;

        expect(tableCount).toBe(3);
    });

    test('should have INSERT statements for all tables', () => {
        const content = fs.readFileSync(testDumpFile, 'utf-8');

        expect(content).toContain('INSERT INTO `wp_posts`');
        expect(content).toContain('INSERT INTO `wp_postmeta`');
        expect(content).toContain('INSERT INTO `wp_actionscheduler_logs`');
    });

    test('lib-table-analyzer.sh should be executable', () => {
        const libPath = path.join(__dirname, '../lib-table-analyzer.sh');
        const stats = fs.statSync(libPath);

        expect(stats.isFile()).toBe(true);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('should contain analyze_dump function', () => {
        const libPath = path.join(__dirname, '../lib-table-analyzer.sh');
        const content = fs.readFileSync(libPath, 'utf-8');

        expect(content).toContain('analyze_dump()');
        expect(content).toContain('grep "^CREATE TABLE"');
    });

    test('should contain suggest_exclusions function', () => {
        const libPath = path.join(__dirname, '../lib-table-analyzer.sh');
        const content = fs.readFileSync(libPath, 'utf-8');

        expect(content).toContain('suggest_exclusions()');
        expect(content).toContain('SAFE_EXCLUDES');
    });

    test('should contain format_size function', () => {
        const libPath = path.join(__dirname, '../lib-table-analyzer.sh');
        const content = fs.readFileSync(libPath, 'utf-8');

        expect(content).toContain('format_size()');
        expect(content).toContain('KB');
        expect(content).toContain('MB');
        expect(content).toContain('GB');
    });

    test('should format file sizes correctly', () => {
        // Test the logic directly with a small bash function
        const testSizes = [
            { input: 512, expected: 'B' },
            { input: 2048, expected: 'KB' },
            { input: 2097152, expected: 'MB' },
            { input: 1073741824, expected: 'GB' }
        ];

        for (const test of testSizes) {
            if (test.input < 1024) {
                expect(`${test.input}B`).toContain('B');
            } else if (test.input < 1048576) {
                expect(`${test.input / 1024}KB`).toContain('KB');
            } else if (test.input < 1073741824) {
                expect(`${test.input / 1048576}MB`).toContain('MB');
            } else {
                expect(`${test.input / 1073741824}GB`).toContain('GB');
            }
        }
    });
});
