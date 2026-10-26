#!/bin/sh
# Tests for greet.sh. Usage: sh test.sh
# It prints "ok - NAME" or "not ok - NAME" for each test, then the totals.
# It exits 0 only when none failed, and writes no file.

greet="$(dirname "$0")/greet.sh"
passed=0
failed=0

# check NAME WANT_STDOUT WANT_STDERR WANT_STATUS [GREET_ARGS...]
check() {
  name=$1
  want_out=$2
  want_err=$3
  want_status=$4
  shift 4
  out=$(sh "$greet" "$@" 2>/dev/null </dev/null)
  status=$?
  err=$(sh "$greet" "$@" 2>&1 >/dev/null </dev/null)
  if [ "$out" = "$want_out" ] && [ "$err" = "$want_err" ] && [ "$status" = "$want_status" ]; then
    passed=$((passed + 1))
    printf 'ok - %s\n' "$name"
  else
    failed=$((failed + 1))
    printf 'not ok - %s\n' "$name"
    printf '# expected status %s, stdout "%s", stderr "%s"; got status %s, stdout "%s", stderr "%s"\n' \
      "$want_status" "$want_out" "$want_err" "$status" "$out" "$err"
  fi
}

check 'greets a name' 'Hello, Ada!' '' 0 Ada
check 'greets the world with no name' 'Hello, world!' '' 0
check 'greets the world with an empty name' 'Hello, world!' '' 0 ''
check 'rejects an unknown option' '' 'greet: unknown option: -x' 2 -x
check 'rejects too many arguments' '' 'greet: too many arguments' 2 Ada Bob
check 'reports an unknown option before too many arguments' '' 'greet: unknown option: -x' 2 -x Ada

printf '%s passed, %s failed\n' "$passed" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
