const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('lib-compress.sh', () => {
    let testDir;
    let testDumpFile;
    let compressedFile;

    beforeAll(() => {
        testDir = path.join(__dirname, '../.tmp-compress-test');
        if (!fs.existsSync(testDir)) {
            fs.mkdirSync(testDir, { recursive: true });
        }

        // Create a sample SQL dump with repetitive content (compresses well)
        testDumpFile = path.join(testDir, 'test-dump.sql');
        const sampleSQL = `
CREATE TABLE \`wp_posts\` (
  \`ID\` bigint(20) NOT NULL AUTO_INCREMENT,
  \`post_author\` bigint(20) NOT NULL,
  \`post_date\` datetime NOT NULL,
  \`post_content\` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO \`wp_posts\` VALUES
(1, 1, '2024-01-01 12:00:00', 'This is test post content'),
(2, 1, '2024-01-02 12:00:00', 'This is test post content'),
(3, 1, '2024-01-03 12:00:00', 'This is test post content');
`;

        // Write sample SQL repeated multiple times to ensure compression
        fs.writeFileSync(testDumpFile, sampleSQL.repeat(100));
    });

    afterAll(() => {
        if (fs.existsSync(testDir)) {
            fs.rmSync(testDir, { recursive: true, force: true });
        }
    });

    test('should compress a SQL dump file', () => {
        compressedFile = path.join(testDir, 'test-dump.sql.gz');

        const result = execSync(`
            source ${path.join(__dirname, '../lib-compress.sh')}
            compress_file "${testDumpFile}" "${compressedFile}"
        `, { shell: '/bin/bash', stdio: 'pipe' }).toString();

        expect(fs.existsSync(compressedFile)).toBe(true);
        expect(result).toContain('Compression complete');
    });

    test('should achieve 70%+ compression on SQL dump', () => {
        const originalSize = fs.statSync(testDumpFile).size;
        const compressedSize = fs.statSync(compressedFile).size;
        const ratio = (1 - compressedSize / originalSize) * 100;

        expect(ratio).toBeGreaterThan(70);
    });

    test('should decompress a gzip file', () => {
        const decompressedFile = path.join(testDir, 'test-dump-restored.sql');

        const result = execSync(`
            source ${path.join(__dirname, '../lib-compress.sh')}
            decompress_file "${compressedFile}" "${decompressedFile}"
        `, { shell: '/bin/bash', stdio: 'pipe' }).toString();

        expect(fs.existsSync(decompressedFile)).toBe(true);
        expect(result).toContain('Decompression complete');
    });

    test('should restore original file on decompression', () => {
        const decompressedFile = path.join(testDir, 'test-dump-restored.sql');
        const originalContent = fs.readFileSync(testDumpFile, 'utf-8');
        const decompressedContent = fs.readFileSync(decompressedFile, 'utf-8');

        expect(decompressedContent).toBe(originalContent);
    });

    test('should detect compressed files', () => {
        const isCompressed = execSync(`
            source ${path.join(__dirname, '../lib-compress.sh')}
            is_compressed "${compressedFile}" && echo "true" || echo "false"
        `, { shell: '/bin/bash', stdio: 'pipe' }).toString().trim();

        expect(isCompressed).toBe('true');
    });

    test('should estimate compression savings', () => {
        const result = execSync(`
            source ${path.join(__dirname, '../lib-compress.sh')}
            estimate_compression "${testDumpFile}"
        `, { shell: '/bin/bash', stdio: 'pipe' }).toString();

        expect(result).toContain('Compression Estimate');
        expect(result).toContain('Original size:');
        expect(result).toContain('Compressed');
    });

    test('should handle missing files gracefully', () => {
        const result = execSync(`
            source ${path.join(__dirname, '../lib-compress.sh')}
            compress_file "/nonexistent/file.sql" "/tmp/output.gz" 2>&1 || echo "error"
        `, { shell: '/bin/bash', stdio: 'pipe' }).toString();

        expect(result).toContain('not found');
    });
});
