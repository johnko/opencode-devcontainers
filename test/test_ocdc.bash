#!/usr/bin/env bash
#
# Tests for ocdc main entry point
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helper.bash"

BIN_DIR="$(dirname "$SCRIPT_DIR")/bin"

echo "Testing ocdc..."
echo ""

# =============================================================================
# Setup/Teardown
# =============================================================================

setup() {
  setup_test_env
}

teardown() {
  cleanup_test_env
}

# =============================================================================
# Tests
# =============================================================================

test_ocdc_exists() {
  if [[ ! -f "$BIN_DIR/ocdc" ]]; then
    echo "ocdc script does not exist"
    return 1
  fi
  if [[ ! -x "$BIN_DIR/ocdc" ]]; then
    echo "ocdc script is not executable"
    return 1
  fi
  return 0
}

test_ocdc_version() {
  local output=$("$BIN_DIR/ocdc" version 2>&1)
  assert_contains "$output" "ocdc"
  # Should contain a version number pattern
  if ! echo "$output" | grep -qE '[0-9]+\.[0-9]+'; then
    echo "Version output should contain version number"
    echo "Got: $output"
    return 1
  fi
  return 0
}

test_ocdc_help() {
  local output=$("$BIN_DIR/ocdc" help 2>&1)
  assert_contains "$output" "Usage:"
  assert_contains "$output" "ocdc"
  assert_contains "$output" "up"
  assert_contains "$output" "down"
  assert_contains "$output" "exec"
  assert_contains "$output" "list"
  assert_contains "$output" "go"
}

test_ocdc_help_flag() {
  local output=$("$BIN_DIR/ocdc" --help 2>&1)
  assert_contains "$output" "Usage:"
}

test_ocdc_version_flag() {
  local output=$("$BIN_DIR/ocdc" --version 2>&1)
  assert_contains "$output" "ocdc"
}

test_ocdc_no_args_shows_tui_or_help() {
  # With no args in non-interactive mode, should show help or try TUI
  # For now, we'll accept either behavior
  local output=$("$BIN_DIR/ocdc" 2>&1 || true)
  # Should not error with "unknown command" or similar
  if [[ "$output" == *"unknown"* ]] || [[ "$output" == *"Unknown"* ]]; then
    echo "ocdc with no args should not show unknown command error"
    return 1
  fi
  return 0
}

test_ocdc_up_dispatches() {
  # Test that ocdc up --help works (dispatches to dcup)
  local output=$("$BIN_DIR/ocdc" up --help 2>&1)
  assert_contains "$output" "dcup" || assert_contains "$output" "devcontainer"
}

test_ocdc_down_dispatches() {
  local output=$("$BIN_DIR/ocdc" down --help 2>&1)
  assert_contains "$output" "dcdown" || assert_contains "$output" "Stop"
}

test_ocdc_exec_dispatches() {
  local output=$("$BIN_DIR/ocdc" exec --help 2>&1)
  assert_contains "$output" "dcexec" || assert_contains "$output" "Execute"
}

test_ocdc_list_dispatches() {
  local output=$("$BIN_DIR/ocdc" list --help 2>&1)
  assert_contains "$output" "dclist" || assert_contains "$output" "List"
}

test_ocdc_go_dispatches() {
  local output=$("$BIN_DIR/ocdc" go --help 2>&1)
  assert_contains "$output" "dcgo" || assert_contains "$output" "Navigate"
}

test_ocdc_unknown_command() {
  local output
  if output=$("$BIN_DIR/ocdc" notarealcommand 2>&1); then
    echo "Should fail for unknown command"
    return 1
  fi
  assert_contains "$output" "Unknown command" || assert_contains "$output" "unknown"
}

# =============================================================================
# Run Tests
# =============================================================================

echo "Main Entry Point Tests:"

for test_func in \
  test_ocdc_exists \
  test_ocdc_version \
  test_ocdc_help \
  test_ocdc_help_flag \
  test_ocdc_version_flag \
  test_ocdc_no_args_shows_tui_or_help \
  test_ocdc_up_dispatches \
  test_ocdc_down_dispatches \
  test_ocdc_exec_dispatches \
  test_ocdc_list_dispatches \
  test_ocdc_go_dispatches \
  test_ocdc_unknown_command
do
  setup
  run_test "${test_func#test_}" "$test_func"
  teardown
done

print_summary
