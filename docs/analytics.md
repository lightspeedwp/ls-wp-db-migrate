# Migration Analytics & Reporting

Track migration performance, understand what happened, and generate reports for documentation and CI/CD pipelines.

## Overview

Every migration generates detailed analytics—how long each stage took, compression effectiveness, import speed, table statistics. Use these reports to optimize future migrations, document changes for your team, and integrate with CI/CD systems.

## Enabling Reports

Reports are enabled by default. To explicitly enable or configure:

```bash
# Enable reports (default behavior)
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --enable-reports

# Specify custom reports directory
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --enable-reports \
  --reports-dir ~/migration-reports

# Disable reports (if you don't need them)
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --disable-reports
```

## Report Formats

Reports are generated in three formats for different use cases:

### 1. Markdown Report (Human-Readable)

**File:** `migration-report.md`

**Use for:** Documentation, team communication, visual review

**Contents:**

```markdown
# WordPress Database Migration Report

**Migration Date:** 2026-10-30 14:30:00 UTC

## Execution Summary

| Metric         | Value     |
| -------------- | --------- |
| Total Duration | 847s      |
| Total Tables   | 94        |
| Total Rows     | 1,250,000 |

## Stage Breakdown

| Stage    | Duration | Status  |
| -------- | -------- | ------- |
| export   | 180s     | success |
| analyze  | 30s      | success |
| compress | 120s     | success |
| import   | 480s     | success |
| validate | 37s      | success |

## Performance Metrics

| Metric            | Value     |
| ----------------- | --------- |
| compression_ratio | 72.5%     |
| import_throughput | 2.45 MB/s |
| total_tables      | 94        |
| total_rows        | 1250000   |
| total_size        | 384 MB    |
| total_duration    | 847 s     |

## Table Statistics

| Table          | Rows   | Size     |
| -------------- | ------ | -------- |
| wp_posts       | 1,240  | 52.3 MB  |
| wp_postmeta    | 45,000 | 124.8 MB |
| wp_users       | 15     | 48 KB    |
| wp_comments    | 850    | 3.2 MB   |
| wp_commentmeta | 2,100  | 1.4 MB   |
| ...            | ...    | ...      |
```

### 2. JSON Report (Machine-Readable)

**File:** `metrics.json`

**Use for:** CI/CD pipelines, automated processing, data analysis

**Contents:**

```json
{
  "migration": {
    "start_time": "2026-10-30T14:30:00Z",
    "end_time": "2026-10-30T14:44:07Z",
    "duration_seconds": 847
  },
  "stages": {
    "export": {"duration": 180, "status": "success"},
    "analyze": {"duration": 30, "status": "success"},
    "compress": {"duration": 120, "status": "success"},
    "import": {"duration": 480, "status": "success"},
    "validate": {"duration": 37, "status": "success"}
  },
  "tables": {
    "wp_posts": {"rows": 1240, "size": 54823424},
    "wp_postmeta": {"rows": 45000, "size": 131006464},
    "wp_users": {"rows": 15, "size": 49152},
    ...
  },
  "metrics": {
    "total_tables": {"value": 94, "unit": "count"},
    "total_rows": {"value": 1250000, "unit": "rows"},
    "total_size": {"value": 402653184, "unit": "bytes"},
    "total_duration": {"value": 847, "unit": "seconds"},
    "compression_ratio": {"value": 72.5, "unit": "%"},
    "import_throughput": {"value": 2.45, "unit": "MB/s"}
  }
}
```

### 3. CSV Report (Spreadsheet Format)

**File:** `table-statistics.csv`

**Use for:** Analysis in Excel, pivot tables, trend tracking

**Contents:**

```csv
table,rows,size_bytes,size_mb
wp_posts,1240,54823424,52.28
wp_postmeta,45000,131006464,124.88
wp_users,15,49152,0.05
wp_comments,850,3355443,3.20
wp_commentmeta,2100,1468006,1.40
wp_options,350,892104,0.85
wp_usermeta,245,561090,0.53
wp_links,0,0,0.00
wp_term_relationships,4200,201984,0.19
wp_term_taxonomy,580,31640,0.03
wp_terms,600,82430,0.08
wp_termmeta,1200,93840,0.09
...
```

## Understanding Key Metrics

### Duration Metrics

**Total Duration:** Total time for entire migration (sum of all stages)

```
= export_time + analyze_time + compress_time + import_time + validate_time
= 180 + 30 + 120 + 480 + 37 = 847 seconds (~14 minutes)
```

**Stage Duration:** Time spent in each phase

- **Export (180s):** Downloading database from source server
- **Analyze (30s):** Scanning structure, counting tables/rows
- **Compress (120s):** Gzipping database (~14% of total)
- **Import (480s):** Importing into SQLite (~57% of total)
- **Validate (37s):** Verifying import success (~4% of total)

### Compression Metrics

**Compression Ratio:** How much space was saved

```
Compression Ratio = (1 - compressed_size / original_size) × 100
                  = (1 - 108 MB / 384 MB) × 100
                  = 72.5%
```

**Interpretation:**

- `70-80%` = Excellent (typical for MySQL with text data)
- `50-70%` = Good (if you excluded large text fields)
- `<50%` = Poor (may indicate already compressed data)

**Size Savings:**

```
Original:  384 MB
Compressed: 108 MB
Saved:     276 MB (72% reduction)
```

### Import Performance

**Import Throughput:** How fast data was imported

```
Import Throughput = database_size / import_time
                  = 384 MB / 480 seconds
                  = 2.45 MB/second
```

**Interpretation:**

- `>2 MB/s` = Good (typical with 4-8 jobs)
- `1-2 MB/s` = Moderate (may need more jobs)
- `<1 MB/s` = Slow (check system resources)

**Typical Performance:**

```
Single-threaded:  0.3-0.5 MB/s
With --jobs 4:    2.0-3.0 MB/s
With --jobs 8:    3.0-5.0 MB/s
Parallel max:     4.0-6.0 MB/s
```

### Table Statistics

**Table Size Distribution:** Which tables use most space

```
wp_postmeta: 124.8 MB (33% of total)
wp_posts:     52.3 MB (14% of total)
wp_comments:   3.2 MB (1% of total)
wp_options:    0.9 MB (<1% of total)
... rest:      2.9 MB (1% of total)
```

**Large Table Impact:**

- Tables >50 MB may cause memory issues during import
- Excluding large tables speeds up import significantly
- Consider excluding `wp_postmeta` or other large tables

**Row Count Analysis:**

```
Total Rows: 1,250,000
Average per table: 13,297 rows
Largest: wp_postmeta (45,000 rows)
Smallest: wp_links (0 rows)
```

## Accessing Reports

### Default Location

Reports are saved to: `~/Studio/my-site/.reports/`

```bash
ls -lh ~/Studio/my-site/.reports/
# migration-report.md       # Human-readable summary
# metrics.json             # Machine-readable data
# table-statistics.csv     # Spreadsheet data
```

### Custom Location

```bash
# Check where reports were saved
ls -lh ~/my-reports/
```

### View Reports Immediately

```bash
# Markdown report (in terminal)
cat ~/Studio/my-site/.reports/migration-report.md

# JSON report (pretty-printed)
cat ~/Studio/my-site/.reports/metrics.json | jq .

# CSV report
open ~/Studio/my-site/.reports/table-statistics.csv
```

## Using Reports for Optimization

### 1. Identify Slow Stages

**Question:** Why did import take so long?

```bash
# Check import_throughput in report
# If < 2 MB/s:
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --jobs 8  # Increase parallel jobs
```

### 2. Find Large Tables to Exclude

**Question:** Which tables should I exclude next time?

```bash
# From table-statistics.csv, sort by size_mb descending
# Large tables: wp_postmeta, wp_posts, wp_commentmeta

# Re-run excluding them:
./wp-migrate-clone-to-studio.sh \
  --from https://example.com \
  --to ~/Studio/site \
  --exclude-tables wp_postmeta,wp_actionscheduler_logs
```

### 3. Track Compression Effectiveness

**Question:** Is compression worth the time investment?

```
Scenario 1: Without compression
- Database size: 384 MB
- Transfer time: ~120s at 3.2 MB/s

Scenario 2: With compression
- Compression: 120s
- Compressed size: 108 MB
- Transfer time: ~34s at 3.2 MB/s
- Total compression cost: 120 - (120 - 34) = 34 seconds
- Net time saved: -86 seconds (compression adds time)
- Benefit: Local transfer is faster, good for CI/CD
```

### 4. Benchmark System Performance

**Question:** How does my machine compare to others?

**Baseline targets:**

```
Database Size: 100-500 MB
- Export: 2-5 min
- Compress: 1-2 min
- Import: 5-10 min
- Total: 10-15 min

If your times are 2-3x slower:
- Check system load (other processes running?)
- Check disk speed (SSD vs HDD?)
- Check network (for SSH export)
```

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Run migration with analytics
  run: |
    ./wp-migrate-clone-to-studio.sh \
      --from ${{ secrets.STAGING_URL }} \
      --to ~/Studio/test-site \
      --enable-reports \
      --reports-dir ./migration-data

- name: Store reports as artifacts
  uses: actions/upload-artifact@v3
  with:
    name: migration-reports
    path: migration-data/

- name: Parse JSON metrics for CI context
  run: |
    DURATION=$(jq '.migration.duration_seconds' migration-data/metrics.json)
    TABLES=$(jq '.metrics.total_tables.value' migration-data/metrics.json)
    echo "Migration completed in ${DURATION}s with ${TABLES} tables"
```

### GitLab CI Example

```yaml
migrate_staging:
  script:
    - ./wp-migrate-clone-to-studio.sh \
      --from $STAGING_URL \
      --to ~/Studio/test-site \
      --enable-reports \
      --reports-dir ./migration-data
  artifacts:
    paths:
      - migration-data/
    expire_in: 30 days
```

## Team Reporting

### Weekly Migration Summary

Create a summary for your team:

```markdown
# Migration Report - Week of Oct 30

## Overview

- 3 migrations this week
- Average duration: 14 min
- Total data migrated: 1.2 GB
- Success rate: 100%

## Performance Trends

| Metric            | Week 1   | Week 2    | Change |
| ----------------- | -------- | --------- | ------ |
| Avg Import Time   | 12 min   | 14 min    | ↑      |
| Compression Ratio | 71%      | 72.5%     | ↑      |
| Avg Throughput    | 2.1 MB/s | 2.45 MB/s | ↑      |

## Optimizations Applied

- Excluded wp_postmeta (reduced by 124 MB)
- Increased parallel jobs from 4 to 8
- Result: Import time down from 18 min → 8 min

## Database Growth

- Largest table: wp_postmeta (124 MB, 45k rows)
- Growth rate: ~15 MB/week
- Projected size in 6 months: 576 MB

## Recommendations

1. Archive old posts/comments to reduce wp_postmeta size
2. Clean up action scheduler logs monthly
3. Consider caching strategies to reduce wp_options queries
```

## Troubleshooting Reports

### Reports Not Generated

**Problem:** Expected `metrics.json` not found

**Solutions:**

1. Check if reports were enabled:

   ```bash
   # Did you use --enable-reports?
   ./wp-migrate-clone-to-studio.sh \
     --from https://example.com \
     --to ~/Studio/site \
     --enable-reports
   ```

2. Check reports directory:

   ```bash
   ls -lh ~/Studio/site/.reports/
   # or
   ls -lh ~/custom-reports-dir/
   ```

3. Check migration log for errors:
   ```bash
   ./wp-migrate-clone-to-studio.sh ... --verbose --log-file migration.log
   cat migration.log | grep -i "report"
   ```

### Metrics Look Unusual

**Problem:** Compression ratio is 0% or import throughput is very low

**Check:**

1. Did the migration actually complete?

   ```bash
   cd ~/Studio/my-site
   studio wp db tables --format=count
   ```

2. Is the data accurate?

   ```bash
   # Verify database isn't empty
   studio wp db query "SELECT COUNT(*) FROM wp_posts;"
   ```

3. Check full report for any errors:
   ```bash
   cat ~/Studio/site/.reports/migration-report.md
   ```

## See Also

- [Reliability & Error Recovery](reliability.md) — Handle failures gracefully
- [Best Practices](best-practices.md) — Optimization strategies
- [Troubleshooting](troubleshooting.md) — Common issues
- [CLI Reference](configuration.md) — All command-line options
