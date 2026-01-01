#!/usr/bin/env bash
#
# Integration tests for ocdc-down command
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.bash"

BIN_DIR="$(dirname "$SCRIPT_DIR")/bin"

echo "Testing ocdc-down..."
echo ""

# =============================================================================
# Setup/Teardown
# =============================================================================

setup() {
  setup_test_env
  mkdir -p "$TEST_CACHE_DIR/overrides"
}

teardown() {
  cleanup_test_env
}

# =============================================================================
# Tests
# =============================================================================

test_ocdc_down_shows_help() {
  local output=$("$BIN_DIR/ocdc" down --help 2>&1)
  assert_contains "$output" "Usage:"
  assert_contains "$output" "ocdc-down"
}

test_ocdc_down_handles_no_instances() {
  echo '{}' > "$TEST_CACHE_DIR/ports.json"
  local output=$("$BIN_DIR/ocdc" down --all 2>&1)
  assert_contains "$output" "Stopping all"
}

test_ocdc_down_prune_removes_stale() {
  # Add a fake entry with a port that's not in use
  cat > "$TEST_CACHE_DIR/ports.json" << 'EOF'
{
  "/fake/path": {
    "port": 19999,
    "repo": "fake-repo",
    "branch": "main"
  }
}
EOF
  
  local output=$("$BIN_DIR/ocdc" down --prune 2>&1)
  assert_contains "$output" "Pruning stale"
  
  # Verify the entry was removed
  local remaining=$(cat "$TEST_CACHE_DIR/ports.json")
  assert_equals "{}" "$remaining"
}

test_ocdc_down_removes_port_assignment() {
  # Create a test repo
  local test_repo="$TEST_DIR/test-repo"
  mkdir -p "$test_repo"
  git -C "$test_repo" init -q
  git -C "$test_repo" config user.email "test@test.com"
  git -C "$test_repo" config user.name "Test"
  
  # Resolve the real path (macOS /var -> /private/var)
  local real_repo=$(cd "$test_repo" && pwd -P)
  
  # Add a port assignment for it
  cat > "$TEST_CACHE_DIR/ports.json" << EOF
{
  "$real_repo": {
    "port": 13000,
    "repo": "test-repo",
    "branch": "main"
  }
}
EOF
  
  cd "$test_repo"
  local output=$("$BIN_DIR/ocdc" down 2>&1)
  assert_contains "$output" "Stopped"
  
  # Verify the entry was removed
  local remaining=$(jq -r 'keys | length' "$TEST_CACHE_DIR/ports.json")
  assert_equals "0" "$remaining"
}

# =============================================================================
# Run Tests
# =============================================================================

echo "Command Usage Tests:"

for test_func in \
  test_ocdc_down_shows_help \
  test_ocdc_down_handles_no_instances \
  test_ocdc_down_prune_removes_stale \
  test_ocdc_down_removes_port_assignment
do
  setup
  run_test "${test_func#test_}" "$test_func"
  teardown
done

print_summary
