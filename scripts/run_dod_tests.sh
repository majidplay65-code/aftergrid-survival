#!/usr/bin/env bash
# Run all DoD tests exactly like CI does, capturing per-test check counts and
# guarding on SCRIPT ERROR / ERROR: / WARNING: lines (same pattern as CI).
set -u
cd "$(dirname "$0")/.."

total_checks=0
failed_tests=0
summary=""

for script in tests/*_test.gd; do
  out=$(GODOT_SILENCE_ROOT_WARNING=1 godot --headless --path . -s "res://${script}" 2>&1)
  exit_code=$?
  checks=$(echo "$out" | grep -c '^PASS: ')
  fails=$(echo "$out" | grep -c '^FAIL: ')
  guard=$(echo "$out" | grep -E 'SCRIPT ERROR|ERROR:|WARNING:' | grep -v 'Started the engine' | head -3)
  total_checks=$((total_checks + checks))
  status="ok"
  if [ "$exit_code" -ne 0 ] || [ "$fails" -ne 0 ]; then
    status="FAILED(exit=$exit_code,fails=$fails)"
    failed_tests=$((failed_tests + 1))
  fi
  if [ -n "$guard" ]; then
    status="${status} GUARD_HIT"
    echo "  GUARD: $guard"
    failed_tests=$((failed_tests + 1))
  fi
  summary="${summary}$(printf '%-32s checks=%-4d %s\n' "${script##*/}" "$checks" "$status")"
done

echo "=================================================="
echo "$summary"
echo "=================================================="
echo "TOTAL_CHECKS=$total_checks"
echo "FAILED_TESTS=$failed_tests"
[ "$failed_tests" -eq 0 ] && exit 0 || exit 1
