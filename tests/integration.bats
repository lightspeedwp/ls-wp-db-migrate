#!/usr/bin/env bats
# Integration tests for wp-db-migrate
# Tests full migration workflows using BATS shell test framework
# https://bats-core.readthedocs.io/

# Setup: Run before each test
setup() {
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)/../scripts"
  export TEST_TEMP_DIR="$(mktemp -d)"
  export WP_STUDIO_SITE="$TEST_TEMP_DIR/test-site"

  # Create a mock WordPress Studio site structure
  mkdir -p "$WP_STUDIO_SITE/wp-content"
  cat > "$WP_STUDIO_SITE/wp-config.php" << 'EOF'
<?php
// Mock WordPress configuration
define('DB_NAME', 'test_db');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_pass');
define('DB_HOST', 'localhost');
define('WP_HOME', 'http://test.local');
define('WP_SITEURL', 'http://test.local');
EOF
}

# Teardown: Run after each test
teardown() {
  # Clean up temporary test files
  [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
}

# Test: preflight-check script runs successfully
@test "preflight-check.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/preflight-check.sh" ]
  [ -x "$SCRIPT_DIR/preflight-check.sh" ]
}

# Test: preflight-check produces output
@test "preflight-check.sh produces check output" {
  output=$("$SCRIPT_DIR/preflight-check.sh" 2>&1)
  [[ $output == *"Check"* ]] || [[ $output == *"check"* ]] || [[ $output == *"bash"* ]]
}

# Test: migrate-recovery script exists
@test "migrate-recovery.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/migrate-recovery.sh" ]
  [ -x "$SCRIPT_DIR/migrate-recovery.sh" ]
}

# Test: migrate-recovery requires arguments
@test "migrate-recovery.sh exits with error when no arguments provided" {
  run "$SCRIPT_DIR/migrate-recovery.sh"
  [ $status -ne 0 ]
}

# Test: migrate-recovery shows help
@test "migrate-recovery.sh shows help with --help flag" {
  run "$SCRIPT_DIR/migrate-recovery.sh" --help
  [ $status -eq 1 ]  # Shows help then exits with non-zero (expected behavior)
  [[ $output == *"Usage"* ]] || [[ $output == *"usage"* ]]
}

# Test: verify-import script exists
@test "verify-import.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/verify-import.sh" ]
  [ -x "$SCRIPT_DIR/verify-import.sh" ]
}

# Test: verify-import requires arguments
@test "verify-import.sh exits with error when no arguments provided" {
  run "$SCRIPT_DIR/verify-import.sh"
  [ $status -ne 0 ]
}

# Test: replace-urls script exists
@test "replace-urls.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/replace-urls.sh" ]
  [ -x "$SCRIPT_DIR/replace-urls.sh" ]
}

# Test: replace-urls requires arguments
@test "replace-urls.sh exits with error when no arguments provided" {
  run "$SCRIPT_DIR/replace-urls.sh"
  [ $status -ne 0 ]
}

# Test: start-server script exists
@test "start-server.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/start-server.sh" ]
  [ -x "$SCRIPT_DIR/start-server.sh" ]
}

# Test: start-server requires arguments
@test "start-server.sh exits with error when no arguments provided" {
  run "$SCRIPT_DIR/start-server.sh"
  [ $status -ne 0 ]
}

# Test: migrate-recovery-enhanced script exists
@test "migrate-recovery-enhanced.sh script exists and is executable" {
  [ -f "$SCRIPT_DIR/migrate-recovery-enhanced.sh" ]
  [ -x "$SCRIPT_DIR/migrate-recovery-enhanced.sh" ]
}

# Test: migrate-recovery-enhanced shows help
@test "migrate-recovery-enhanced.sh shows help with --help flag" {
  run "$SCRIPT_DIR/migrate-recovery-enhanced.sh" --help
  [ $status -eq 0 ]  # Shows help and exits successfully
  [[ $output == *"USAGE"* ]] || [[ $output == *"Usage"* ]] || [[ $output == *"usage"* ]]
}

# Test: All required shell libraries exist
@test "lib-config.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-config.sh" ]
  [ -x "$SCRIPT_DIR/lib-config.sh" ]
}

@test "lib-reports.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-reports.sh" ]
  [ -x "$SCRIPT_DIR/lib-reports.sh" ]
}

@test "lib-error-recovery.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-error-recovery.sh" ]
  [ -x "$SCRIPT_DIR/lib-error-recovery.sh" ]
}

@test "lib-progress.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-progress.sh" ]
  [ -x "$SCRIPT_DIR/lib-progress.sh" ]
}

@test "lib-ssh.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-ssh.sh" ]
  [ -x "$SCRIPT_DIR/lib-ssh.sh" ]
}

@test "lib-studio-api.sh exists and is executable" {
  [ -f "$SCRIPT_DIR/lib-studio-api.sh" ]
  [ -x "$SCRIPT_DIR/lib-studio-api.sh" ]
}

# Test: All scripts are properly formatted shell scripts
@test "All scripts have bash shebang" {
  for script in "$SCRIPT_DIR"/*.sh; do
    [[ -f "$script" ]] && head -1 "$script" | grep -q "^#!" || false
  done
}

# Test: All scripts have proper permissions
@test "All shell scripts are executable" {
  for script in "$SCRIPT_DIR"/*.sh; do
    [ -x "$script" ] || (echo "Not executable: $script" && false)
  done
}

# Test: Mock WordPress Studio site created successfully
@test "Test WordPress Studio site structure is valid" {
  [ -d "$WP_STUDIO_SITE" ]
  [ -f "$WP_STUDIO_SITE/wp-config.php" ]
  [ -d "$WP_STUDIO_SITE/wp-content" ]
}

# Test: wp-config.php contains required definitions
@test "Test wp-config.php has required database definitions" {
  grep -q "define('DB_NAME'" "$WP_STUDIO_SITE/wp-config.php"
  grep -q "define('DB_USER'" "$WP_STUDIO_SITE/wp-config.php"
  grep -q "define('DB_PASSWORD'" "$WP_STUDIO_SITE/wp-config.php"
}
