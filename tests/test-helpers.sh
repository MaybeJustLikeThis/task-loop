#!/usr/bin/env bash
# 纯 bash 断言辅助，零依赖。每个测试 source 本文件后调用。
TEST_PASS=0
TEST_FAIL=0

assert_eq() {  # actual expected name
  if [ "$1" = "$2" ]; then
    echo "  PASS: $3"; TEST_PASS=$((TEST_PASS+1))
  else
    echo "  FAIL: $3 -- expected [$2] got [$1]"; TEST_FAIL=$((TEST_FAIL+1))
  fi
}

assert_match() {  # pattern text name   (text 含 pattern 即过)
  if echo "$2" | grep -q "$1"; then
    echo "  PASS: $3"; TEST_PASS=$((TEST_PASS+1))
  else
    echo "  FAIL: $3 -- [$2] 不含 [$1]"; TEST_FAIL=$((TEST_FAIL+1))
  fi
}

assert_exit() {  # expected_code cmd...  (运行 cmd，断言退出码)
  local exp="$1"; shift
  "$@" >/dev/null 2>&1; local code=$?
  if [ "$code" = "$exp" ]; then
    echo "  PASS: 退出码 $exp ($*)"; TEST_PASS=$((TEST_PASS+1))
  else
    echo "  FAIL: 期望退出码 $exp 实际 $code ($*)"; TEST_FAIL=$((TEST_FAIL+1))
  fi
}

summary() {
  echo "---- $TEST_PASS passed, $TEST_FAIL failed ----"
  [ "$TEST_FAIL" = 0 ]
}
