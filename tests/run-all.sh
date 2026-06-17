#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
for t in tests/test-*.sh; do
  [ "$t" = "tests/test-helpers.sh" ] && continue   # helpers 不是测试
  echo "=== $t ==="
  bash "$t" || { echo "FAILED: $t"; exit 1; }
done
echo "ALL TESTS PASSED"
