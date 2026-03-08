#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local cmd="$2"
    printf "  %-45s " "$name"
    if eval "$cmd" &>/dev/null 2>&1; then
        echo "✓"
        PASS=$((PASS + 1))
    else
        echo "✗"
        FAIL=$((FAIL + 1))
    fi
}

run_test_output() {
    local name="$1"
    local cmd="$2"
    local expect="$3"
    printf "  %-45s " "$name"
    local output
    output=$(eval "$cmd" 2>&1) || true
    if echo "$output" | grep -qi "$expect"; then
        echo "✓"
        PASS=$((PASS + 1))
    else
        echo "✗ (expected '$expect')"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Orch Test Suite ==="
echo ""

echo "Prerequisites:"
run_test "go installed" "command -v go"
run_test "tmux installed" "command -v tmux"
run_test "gh installed" "command -v gh"
run_test "claude installed" "command -v claude"
run_test "gh authenticated" "gh auth status"

echo ""
echo "Linear CLI:"
run_test "linear binary exists" "command -v linear"
run_test "linear --help works" "linear --help"
run_test_output "linear me (API key valid)" "cd $(dirname $0) && linear me" "thunk"
run_test_output "linear teams" "cd $(dirname $0) && linear teams" "THU"
run_test_output "linear projects" "cd $(dirname $0) && linear projects" "Tidy"
run_test_output "linear issues list" "cd $(dirname $0) && linear issues list --limit 1" "THU"
run_test_output "linear issues list --project" "cd $(dirname $0) && linear issues list --project 'Tidy desktop time tracker' --limit 1" "THU"
run_test_output "linear initiatives list" "cd $(dirname $0) && linear initiatives list" ""

echo ""
echo "Session CLI:"
run_test "session binary exists" "command -v session"
run_test "session --help works" "session --help"
run_test_output "session list works" "session list" ""
run_test_output "session inbox works" "session inbox" ""
run_test_output "session orch --help" "session orch --help" "orchestrator"
run_test_output "session watchdog --help" "session watchdog --help" "orch"

echo ""
echo "Environment:"
run_test ".env exists" "test -f $(dirname $0)/.env"
run_test_output "LINEAR_API_KEY is set" "grep -c LINEAR_API_KEY $(dirname $0)/.env" "1"
run_test "inbox directory exists" "test -d $(dirname $0)/inbox"
run_test "~/src directory exists" "test -d $HOME/src"
run_test_output "man linear works" "man -w linear" "linear.1"

echo ""
echo "Watchdog:"
run_test_output "launchd agent loaded" "launchctl list" "session-watchdog"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
