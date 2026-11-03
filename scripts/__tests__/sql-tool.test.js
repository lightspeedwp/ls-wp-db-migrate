const fs = require('fs');
const os = require('os');
const path = require('path');
const { sanitise, siteUrls } = require('../../lib/sql-tool.cjs');

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
            if (previous === undefined) delete process.env.STUDIO_CLI_CONFIG;
            else process.env.STUDIO_CLI_CONFIG = previous;
        }
        const helper = path.join(__dirname, '..', 'studio-search-replace.php');

        expect(result.urlReplacement.command).toBe(
            `studio wp --path '${site}' eval-file '${helper}' dry 'staging.example.com' 'https://my-site.local'`
        );
        expect(result.urlReplacement.command).not.toMatch(/search-replace /);
        expect(fs.existsSync(helper)).toBe(true);
    });
});
