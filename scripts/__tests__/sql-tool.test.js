const fs = require('fs');
const os = require('os');
const path = require('path');
const { sanitise, siteUrls, preflight, run } = require('../../lib/sql-tool.cjs');

const DUMP_HEAD = `CREATE TABLE \`wp_options\` (
  \`option_id\` bigint(20) UNSIGNED NOT NULL,
  \`option_name\` varchar(191) NOT NULL DEFAULT '',
  \`option_value\` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO \`wp_options\` (\`option_id\`, \`option_name\`, \`option_value\`) VALUES
(1, 'siteurl', 'https://staging.example.com'),
(2, 'home', 'https://staging.example.com'),
(3, 'note', 'ADD CONSTRAINT x FOREIGN KEY (y) REFERENCES z (y);');

CREATE TABLE \`wp_wc_download_log\` (
  \`download_log_id\` bigint(20) UNSIGNED NOT NULL,
  \`permission_id\` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

`;

describe('sql-tool.cjs — Studio import fixes', () => {
    let dir;

    beforeEach(() => {
        dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sql-tool-test-'));
    });

    afterEach(() => {
        fs.rmSync(dir, { recursive: true, force: true });
    });

    const write = (name, text) => {
        const file = path.join(dir, name);
        fs.writeFileSync(file, text);
        return file;
    };

    test('sanitise removes an ALTER TABLE that only adds a foreign key', () => {
        const input = write(
            'fk-only.sql',
            `${DUMP_HEAD}ALTER TABLE \`wp_wc_download_log\`
  ADD CONSTRAINT \`fk_wp_wc_download_log_permission_id\` FOREIGN KEY (\`permission_id\`) REFERENCES \`wp_woocommerce_downloadable_product_permissions\` (\`permission_id\`) ON DELETE CASCADE;
COMMIT;
`
        );
        const out = path.join(dir, 'out.sql');
        const result = sanitise(input, { out });
        const text = fs.readFileSync(out, 'latin1');

        expect(text).not.toMatch(/ALTER TABLE `wp_wc_download_log`/);
        expect(text).toMatch(/COMMIT;/);
        // Data that only mentions a foreign key is left alone.
        expect(text).toMatch(/'ADD CONSTRAINT x FOREIGN KEY \(y\) REFERENCES z \(y\);'/);
        const edit = result.edits.find((e) => e.rule === 'foreign-key');
        expect(edit).toMatchObject({ table: 'wp_wc_download_log', count: 1 });
    });

    test('sanitise keeps the other clauses of a mixed ALTER TABLE', () => {
        const input = write(
            'fk-mixed.sql',
            `${DUMP_HEAD}ALTER TABLE \`wp_wc_download_log\`
  ADD PRIMARY KEY (\`download_log_id\`),
  ADD CONSTRAINT \`fk_a\` FOREIGN KEY (\`permission_id\`) REFERENCES \`p\` (\`permission_id\`) ON DELETE CASCADE,
  ADD KEY \`permission_id\` (\`permission_id\`),
  ADD FOREIGN KEY (\`permission_id\`) REFERENCES \`p\` (\`permission_id\`);
`
        );
        const out = path.join(dir, 'out.sql');
        const result = sanitise(input, { out });
        const text = fs.readFileSync(out, 'latin1');

        expect(text).toContain(
            'ALTER TABLE `wp_wc_download_log`\n  ADD PRIMARY KEY (`download_log_id`),\n  ADD KEY `permission_id` (`permission_id`);\n'
        );
        expect(text).not.toMatch(/FOREIGN KEY \(`permission_id`\)/);
        expect(result.edits.find((e) => e.rule === 'foreign-key').count).toBe(2);
    });

    test('site-urls plans the SQLite-safe helper instead of wp search-replace', () => {
        const site = path.join(dir, 'my site');
        fs.mkdirSync(site);
        fs.writeFileSync(path.join(site, 'wp-config.php'), "<?php\n$table_prefix = 'wp_';\n");
        const config = write(
            'cli.json',
            JSON.stringify({ sites: [{ path: site, customDomain: 'my-site.local' }] })
        );
        const input = write('urls.sql', DUMP_HEAD);
        const previous = process.env.STUDIO_CLI_CONFIG;
        process.env.STUDIO_CLI_CONFIG = config;
        let result;
        try {
            result = siteUrls(input, { studioSite: site });
        } finally {
            if (previous === undefined) {
                delete process.env.STUDIO_CLI_CONFIG;
            } else {
                process.env.STUDIO_CLI_CONFIG = previous;
            }
        }
        const helper = path.join(__dirname, '..', 'studio-search-replace.php');

        expect(result.urlReplacement.command).toBe(
            `studio wp --path '${site}' eval-file '${helper}' dry 'staging.example.com' 'https://my-site.local'`
        );
        expect(result.urlReplacement.command).not.toMatch(/search-replace /);
        expect(fs.existsSync(helper)).toBe(true);
    });

    test('sanitise removes MariaDB-only table options but keeps the table comment', () => {
        const input = write(
            'options.sql',
            `CREATE TABLE \`wp_stats\` (
  \`id\` bigint(20) unsigned NOT NULL,
  \`note\` varchar(100) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PAGE_COMPRESSED=1 is in this comment' \`PAGE_COMPRESSED\`='ON' \`PAGE_COMPRESSION_LEVEL\`=6;

CREATE TABLE \`wp_enc\` (
  \`id\` int(11) NOT NULL
) ENGINE=Aria PAGE_CHECKSUM=1 TRANSACTIONAL=1 \`ENCRYPTED\`='YES' \`ENCRYPTION_KEY_ID\`=2;
`
        );
        const out = path.join(dir, 'out.sql');
        const result = sanitise(input, { out });
        const text = fs.readFileSync(out, 'latin1');

        expect(text).toContain(") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PAGE_COMPRESSED=1 is in this comment';\n");
        expect(text).toContain(') ENGINE=Aria;\n');
        expect(text).not.toMatch(/PAGE_CHECKSUM|TRANSACTIONAL|ENCRYPT|PAGE_COMPRESSION_LEVEL|`PAGE_COMPRESSED`/);
        const options = result.edits.filter((e) => e.rule === 'table-option');
        expect(options.map((e) => [e.table, e.count])).toEqual([
            ['wp_stats', 2],
            ['wp_enc', 4],
        ]);
    });

    test('sanitise leaves a table without MariaDB-only options unchanged', () => {
        const input = write('plain.sql', DUMP_HEAD);
        const out = path.join(dir, 'out.sql');
        const result = sanitise(input, { out });

        expect(result.edits.some((e) => e.rule === 'table-option')).toBe(false);
        expect(fs.readFileSync(out, 'latin1')).toContain(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;\n');
    });

    test('sanitise reports BIGINT UNSIGNED values SQLite cannot store, without changing them', () => {
        const input = write(
            'bigint.sql',
            `CREATE TABLE \`wp_big\` (
  \`id\` bigint(20) unsigned NOT NULL,
  \`signed_id\` bigint(20) NOT NULL,
  \`note\` varchar(30) NOT NULL
) ENGINE=InnoDB;

INSERT INTO \`wp_big\` VALUES (9223372036854775807,1,'largest that fits'),(9223372036854775808,2,'one over'),('18446744073709551615',3,'quoted');
INSERT INTO \`wp_big\` VALUES (1,9223372036854775807,'12345678901234567890123');
`
        );
        const out = path.join(dir, 'out.sql');
        const result = sanitise(input, { out });
        const finding = result.findings.find((f) => f.check === 'integer-too-large');

        expect(finding).toMatchObject({ severity: 'fail', table: 'wp_big', line: 7 });
        expect(finding.detail).toMatch(/^2 value\(s\) in id /);
        expect(finding.detail).toContain('9223372036854775808');
        expect(result.findings.filter((f) => f.check === 'integer-too-large')).toHaveLength(1);
        expect(result.status).toBe('findings');
        expect(fs.readFileSync(out, 'latin1')).toContain('(9223372036854775808,2,');
    });

    test('sanitise passes the ALTER ... MODIFY ... AUTO_INCREMENT that follows ADD PRIMARY KEY through unchanged', () => {
        // Checked against Studio's SQLite driver 3.0.2 and 3.1.3: the primary key survives this pair.
        const alter = `ALTER TABLE \`wp_options\`
  ADD PRIMARY KEY (\`option_id\`),
  ADD UNIQUE KEY \`option_name\` (\`option_name\`);

ALTER TABLE \`wp_options\`
  MODIFY \`option_id\` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
`;
        const input = write('modify.sql', `${DUMP_HEAD}${alter}`);
        const out = path.join(dir, 'out.sql');
        sanitise(input, { out });

        expect(fs.readFileSync(out, 'latin1')).toContain(alter);
    });
});

describe('sql-tool.cjs — Studio export checks', () => {
    let dir;

    beforeEach(() => {
        dir = fs.mkdtempSync(path.join(os.tmpdir(), 'sql-tool-test-'));
    });

    afterEach(() => {
        fs.rmSync(dir, { recursive: true, force: true });
    });

    // What Studio's export writes: every value made only of digits goes out unquoted.
    const STUDIO_EXPORT = `DROP TABLE IF EXISTS \`wp_postmeta\`;
CREATE TABLE \`wp_postmeta\` (
  \`meta_id\` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  \`post_id\` bigint(20) unsigned NOT NULL DEFAULT '0',
  \`meta_key\` varchar(255) DEFAULT NULL,
  \`meta_value\` longtext,
  PRIMARY KEY (\`meta_id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;
INSERT INTO \`wp_postmeta\` VALUES (1,10,'_postcode','0021');
INSERT INTO \`wp_postmeta\` VALUES (2,10,'_phone',0821234567);
INSERT INTO \`wp_postmeta\` VALUES (3,10,'_count',42);
INSERT INTO \`wp_postmeta\` VALUES (4,10,'_zip',007);
`;

    const write = (name, text) => {
        const file = path.join(dir, name);
        fs.writeFileSync(file, text);
        return file;
    };

    test('preflight fails on unquoted numbers in text columns that MySQL would change', () => {
        const input = write('studio.sql', STUDIO_EXPORT);
        const result = preflight(input);
        const finding = result.findings.find((f) => f.check === 'unquoted-text-number');

        expect(finding).toMatchObject({ severity: 'fail', table: 'wp_postmeta', line: 10, autoFixable: true });
        // 42 keeps its value as a number, so only the two with leading zeros count.
        expect(finding.detail).toMatch(/^2 value\(s\) in the text column meta_value /);
        expect(result.output).toBeNull();
        expect(result.edits).toEqual([]);
    });

    test('preflight --out writes a copy with those values quoted and leaves the input alone', () => {
        const input = write('studio.sql', STUDIO_EXPORT);
        const out = path.join(dir, 'studio-mysql.sql');
        const result = preflight(input, { out });
        const text = fs.readFileSync(out, 'latin1');

        expect(fs.readFileSync(input, 'latin1')).toBe(STUDIO_EXPORT);
        expect(text).toContain("VALUES (2,10,'_phone','0821234567');");
        expect(text).toContain("VALUES (3,10,'_count','42');");
        expect(text).toContain("VALUES (4,10,'_zip','007');");
        // Integer columns keep their unquoted numbers.
        expect(text).toContain("VALUES (1,10,'_postcode','0021');");
        expect(result.findings.some((f) => f.check === 'unquoted-text-number')).toBe(false);
        expect(result.edits).toEqual([
            expect.objectContaining({ rule: 'requote-number', table: 'wp_postmeta', count: 3, line: 10 }),
        ]);
        expect(result.output).toMatchObject({ path: out, createTables: 1, inserts: 4 });
    });

    test('preflight --out refuses to overwrite an existing file without --force', () => {
        const input = write('studio.sql', STUDIO_EXPORT);
        const out = write('existing.sql', 'keep me');

        expect(() => preflight(input, { out })).toThrow(/already exists/);
        expect(fs.readFileSync(out, 'latin1')).toBe('keep me');
        expect(fs.readdirSync(dir).some((f) => f.endsWith('.partial'))).toBe(false);
    });

    test('the CLI passes --out and --force to preflight', () => {
        const input = write('studio.sql', STUDIO_EXPORT);
        const out = write('existing.sql', 'old');
        const { code, stdout } = run(['preflight', input, '--out', out, '--force', '--json']);
        const result = JSON.parse(stdout);

        expect(result.edits[0].rule).toBe('requote-number');
        expect(fs.readFileSync(out, 'latin1')).toContain("'007'");
        // DROP TABLE is still reported as a warning.
        expect(code).toBe(1);
    });
});
