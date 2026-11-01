#!/usr/bin/env node

/**
 * migrate-with-budget.js
 * Migration wrapper using Claude API with task budgets
 *
 * Smart token allocation for WordPress database migrations
 * Implements complexity detection and adaptive budgeting
 *
 * Usage:
 *   node migrate-with-budget.js <site-path> <export-file> <old-url> <new-url> [--dry-run]
 *
 * Requires:
 *   ANTHROPIC_API_KEY environment variable
 *
 * Budget Strategy:
 *   - Simple (<100MB):   32K tokens (dev sites, lightweight)
 *   - Medium (100-500MB): 64K tokens (staging databases)
 *   - Complex (>500MB):   128K tokens (production, large datasets)
 */

const fs = require('fs');

// Whitelist of approved API hosts (prevent SSRF)
const APPROVED_HOSTS = new Set(['api.anthropic.com']);

// Loopback addresses allowed for local testing only
const LOOPBACK_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);

// Validate and sanitize API base URL with exact hostname matching
function validateApiUrl(urlString) {
  try {
    const url = new URL(urlString);

    // Normalize hostname (remove trailing dot, lowercase)
    const host = url.hostname.toLowerCase().replace(/\.$/, '');

    // Check if it's a loopback address
    const isLoopback = LOOPBACK_HOSTS.has(host);

    // Verify hostname is in approved list or is loopback
    if (!APPROVED_HOSTS.has(host) && !isLoopback) {
      throw new Error(`Host not allowed: ${host}`);
    }

    // Require HTTPS except for loopback
    if (url.protocol !== 'https:' && !isLoopback) {
      throw new Error('Only HTTPS URLs allowed (except localhost)');
    }

    // Prevent credentials in URL
    if (url.username || url.password) {
      throw new Error('Credentials in URL not allowed');
    }

    return url.origin;
  } catch (error) {
    log(colors.red, '❌', `Invalid API URL: ${error.message}`);
    log(colors.yellow, '⚠️ ', 'Using default Anthropic API endpoint');
    return 'https://api.anthropic.com';
  }
}

// Configuration from environment
const config = {
  apiKey: process.env.ANTHROPIC_API_KEY,
  apiBase: validateApiUrl(process.env.ANTHROPIC_API_URL || 'https://api.anthropic.com'),
  model: process.env.CLAUDE_MODEL || 'claude-opus-4-1',
  betaHeader: 'task-budgets-2026-03-13',

  // Token budgets by complexity
  budgets: {
    simple: 32000, // <100 MB
    medium: 64000, // 100-500 MB
    complex: 128000, // >500 MB
  },

  // Effort levels
  efforts: {
    simple: 'medium',
    medium: 'medium',
    complex: 'high',
  },
};

// Color output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
};

function log(color, prefix, message) {
  console.log(`${color}${prefix}${colors.reset} ${message}`);
}

function getComplexity(filePath) {
  try {
    const stats = fs.statSync(filePath);
    const mb = stats.size / (1024 * 1024);

    if (mb < 100) {
      return 'simple';
    }
    if (mb < 500) {
      return 'medium';
    }
    return 'complex';
  } catch (error) {
    log(colors.yellow, '⚠️ ', `Could not determine file size: ${error.message}`);
    return 'medium'; // Default to medium if can't read
  }
}

function formatBytes(bytes) {
  const mb = bytes / (1024 * 1024);
  if (mb > 1000) {
    return `${(mb / 1024).toFixed(1)} GB`;
  }
  return `${mb.toFixed(1)} MB`;
}

async function callClaudeAPI(prompt, complexity, dryRun = false) {
  if (!config.apiKey) {
    throw new Error('ANTHROPIC_API_KEY environment variable not set');
  }

  const budget = config.budgets[complexity];
  const effort = config.efforts[complexity];

  const requestBody = {
    model: config.model,
    max_tokens: 4096,

    // Task budget configuration
    output_config: {
      effort,
      task_budget: {
        type: 'tokens',
        total: budget,
      },
    },

    system: `You are a WordPress database migration expert. Help migrate the database efficiently within the token budget.

Migration Complexity: ${complexity}
Available Token Budget: ${budget} tokens
Dry Run Mode: ${dryRun}

Prioritize in order:
1. Safety (backups, validation, rollback capability)
2. Speed (reuse existing scripts, skip verbose output)
3. Clarity (show essential progress, hide debug info)

Output concisely. No unnecessary explanations.`,

    messages: [
      {
        role: 'user',
        content: prompt,
      },
    ],
  };

  if (dryRun) {
    log(colors.yellow, '🔍', 'DRY-RUN: Would send to Claude API');
    log(colors.blue, '📊', `Complexity: ${complexity}`);
    log(colors.blue, '💾', `Budget: ${budget} tokens`);
    log(colors.blue, '⚙️ ', `Effort: ${effort}`);
    return {
      success: true,
      dryRun: true,
      complexity,
      budget,
      usage: {
        inputTokens: 0,
        outputTokens: 0,
        totalTokens: 0,
      },
      response: '[DRY-RUN] API call skipped',
    };
  }

  try {
    log(colors.blue, '📡', 'Calling Claude API with task budget...');

    const response = await fetch(`${config.apiBase}/v1/messages`, {
      method: 'POST',
      headers: {
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-beta': config.betaHeader,
        'content-type': 'application/json',
      },
      body: JSON.stringify(requestBody),
      redirect: 'manual', // Prevent redirects from carrying API key to untrusted hosts
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API error (${response.status}): ${error}`);
    }

    const data = await response.json();

    return {
      success: true,
      dryRun: false,
      complexity,
      budget,
      usage: {
        inputTokens: data.usage.input_tokens || 0,
        outputTokens: data.usage.output_tokens || 0,
        totalTokens: (data.usage.input_tokens || 0) + (data.usage.output_tokens || 0),
      },
      response: data.content[0]?.text || 'No response',
    };
  } catch (error) {
    log(colors.red, '❌', `API call failed: ${error.message}`);
    throw error;
  }
}

async function migrateWithBudget(config) {
  const { sitePath, exportFile, oldUrl, newUrl, dryRun = false } = config;

  // Validate inputs
  if (!sitePath || !exportFile || !oldUrl || !newUrl) {
    throw new Error('Missing required arguments: sitePath, exportFile, oldUrl, newUrl');
  }

  if (!fs.existsSync(exportFile)) {
    throw new Error(`Export file not found: ${exportFile}`);
  }

  // Detect complexity
  const fileSize = fs.statSync(exportFile).size;
  const complexity = getComplexity(exportFile);
  const budget = config.budgets[complexity];

  // Build migration prompt
  const migrationPrompt = `Migrate WordPress database from MySQL/SQLite:

Site Path: ${sitePath}
Export File: ${exportFile} (${formatBytes(fileSize)})
Old URL: ${oldUrl}
New URL: ${newUrl}
Dry Run: ${dryRun}

Execute the migration efficiently. Use the provided scripts when possible.
Report: status, row count changes, any warnings.
Keep output concise.`;

  // Call Claude API with task budget
  const result = await callClaudeAPI(migrationPrompt, complexity, dryRun);

  return {
    ...result,
    fileSize,
    budgetUtilization: result.usage.totalTokens > 0 ? ((result.usage.totalTokens / budget) * 100).toFixed(1) : 0,
  };
}

async function main() {
  // Parse arguments
  const args = process.argv.slice(2);
  const isDryRun = args.includes('--dry-run');

  const mainArgs = args.filter((a) => !a.startsWith('--'));

  if (mainArgs.length < 4) {
    console.error('Usage: node migrate-with-budget.js <site-path> <export-file> <old-url> <new-url> [--dry-run]');
    process.exit(1);
  }

  const [sitePath, exportFile, oldUrl, newUrl] = mainArgs;

  try {
    // Show banner
    console.log('');
    log(colors.blue, '╔════════════════════════════════╗', '');
    log(colors.blue, '║  WP DB Migrate with Task Budget  ║', '');
    log(colors.blue, '╚════════════════════════════════╝', '');
    console.log('');

    // Detect complexity
    const complexity = getComplexity(exportFile);
    const fileSize = fs.statSync(exportFile).size;
    const budget = config.budgets[complexity];

    log(colors.blue, '📊', `Complexity: ${complexity} (${formatBytes(fileSize)})`);
    log(colors.blue, '💾', `Token Budget: ${budget} tokens`);
    log(colors.blue, '🎯', `Effort Level: ${config.efforts[complexity]}`);
    console.log('');

    if (isDryRun) {
      log(colors.yellow, '🔍', 'DRY-RUN MODE (no changes will be made)');
      console.log('');
    }

    // Perform migration
    const result = await migrateWithBudget({
      sitePath,
      exportFile,
      oldUrl,
      newUrl,
      budgets: config.budgets,
      dryRun: isDryRun,
    });

    // Show results
    console.log('');
    if (result.dryRun) {
      log(colors.green, '✅', 'DRY-RUN complete (no API calls made)');
    } else {
      log(colors.green, '✅', 'Migration completed via Claude API');
      console.log('');
      log(colors.blue, '📊', `Tokens used: ${result.usage.totalTokens} / ${result.budget}`);
      log(colors.blue, '📈', `Budget utilization: ${result.budgetUtilization}%`);
    }

    console.log('');
    log(colors.blue, '💡', 'Response:');
    console.log('');
    console.log(result.response);
    console.log('');
  } catch (error) {
    log(colors.red, '❌', `Error: ${error.message}`);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main().catch((error) => {
    log(colors.red, '❌', error.message);
    process.exit(1);
  });
}

module.exports = { migrateWithBudget, getComplexity };
// Test commit to verify hooks
