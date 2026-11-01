const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

describe('lib-progress.sh — Progress Tracking Library', () => {
    const libPath = path.join(__dirname, '../lib-progress.sh');

    beforeAll(() => {
        if (!fs.existsSync(libPath)) {
            throw new Error(`lib-progress.sh not found at ${libPath}`);
        }
    });

    test('Progress library loads successfully', () => {
        const result = execSync(`bash -c "source ${libPath} && echo 'loaded'"`, {
            stdio: 'pipe'
        }).toString().trim();

        expect(result).toBe('loaded');
    });

    test('progress_start initializes progress tracking', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            progress_start 'Test' 100
            echo \\\$PROGRESS_LABEL
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('Test');
    });

    test('progress_update updates current progress', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            progress_start 'Test' 100
            progress_update 50
            echo \\\$PROGRESS_CURRENT
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toContain('50');
    });

    test('progress_complete shows completion message', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            progress_start 'Test' 100
            progress_complete 'Success'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Success');
        expect(result).toContain('✓');
    });

    test('progress_fail shows failure message', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            progress_start 'Test' 100
            progress_fail 'Error occurred'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Error');
        expect(result).toContain('❌');
    });

    test('spinner_start and spinner_complete work together', (done) => {
        setTimeout(() => {
            const result = execSync(`bash -c "
                source ${libPath}
                spinner_start 'Testing'
                sleep 0.2
                spinner_complete 'Test done'
            "`, { stdio: 'pipe' }).toString();

            expect(result).toContain('done');
            expect(result).toContain('✓');
            done();
        }, 500);
    });

    test('spinner_fail shows failure', (done) => {
        setTimeout(() => {
            const result = execSync(`bash -c "
                source ${libPath}
                spinner_start 'Testing'
                sleep 0.2
                spinner_fail 'Test failed'
            "`, { stdio: 'pipe' }).toString();

            expect(result).toContain('failed');
            expect(result).toContain('❌');
            done();
        }, 500);
    });

    test('stage_start displays stage header', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            stage_start 1 'Export'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Stage 1');
        expect(result).toContain('Export');
    });

    test('stage_complete marks stage finished', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            stage_complete
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Stage complete');
        expect(result).toContain('✓');
    });

    test('show_timing displays elapsed time', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            START=\\\$(date +%s)
            sleep 1
            show_timing \\\$START 'Test operation'
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Test operation');
        expect(result).toContain('completed');
        expect(result).toContain('✓');
    });

    test('lib-progress.sh should be executable', () => {
        const stats = fs.statSync(libPath);
        expect(stats.isFile()).toBe(true);
        expect(stats.mode & 0o111).toBeTruthy();
    });

    test('Progress functions are exported', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            declare -f progress_start progress_update progress_complete spinner_start stage_start
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('progress_start');
        expect(result).toContain('progress_update');
        expect(result).toContain('stage_start');
    });

    test('Progress handles zero total gracefully', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            progress_start 'Test' 0
            progress_update 0
            echo 'ok'
        "`, { stdio: 'pipe' }).toString().trim();

        expect(result).toBe('ok');
    });

    test('Multiple stage transitions work correctly', () => {
        const result = execSync(`bash -c "
            source ${libPath}
            stage_start 1 'First'
            stage_complete
            stage_start 2 'Second'
            stage_complete
        "`, { stdio: 'pipe' }).toString();

        expect(result).toContain('Stage 1');
        expect(result).toContain('Stage 2');
        expect(result).toContain('First');
        expect(result).toContain('Second');
    });

    test('Progress completes with timing', (done) => {
        setTimeout(() => {
            const result = execSync(`bash -c "
                source ${libPath}
                progress_start 'Timing test' 100
                progress_update 50
                progress_complete 'Done'
            "`, { stdio: 'pipe' }).toString();

            expect(result).toContain('s)');
            done();
        }, 200);
    });

    test('Spinner terminates cleanly', (done) => {
        setTimeout(() => {
            execSync(`bash -c "
                source ${libPath}
                spinner_start 'Test'
                sleep 0.1
                spinner_complete
                echo 'done'
            "`, { stdio: 'pipe' });
            done();
        }, 500);
    });
});
