#!/bin/sh
# Acceptance check for the request in request.md, run against a copy of the sample project.
# Usage: sh accept.sh FOLDER
# It runs FOLDER/greet.sh and reads FOLDER/doc/product/spec/greeting.md, and never writes to FOLDER.
# It prints "ok - CASE" or "not ok - CASE: what it expected and got" for each case, then the totals.
# It exits 0 when all pass, 1 when any fails, and 2 on wrong usage or a missing folder or greet.sh.

if [ "$#" -ne 1 ]; then
  printf 'usage: sh accept.sh FOLDER\n' >&2
  exit 2
fi

dir=$1
if [ ! -d "$dir" ]; then
  printf 'accept: not a folder: %s\n' "$dir" >&2
  exit 2
fi

greet="$dir/greet.sh"
if [ ! -f "$greet" ]; then
  printf 'accept: no greet.sh in %s\n' "$dir" >&2
  exit 2
fi

passed=0
failed=0

pass() {
  passed=$((passed + 1))
  printf 'ok - %s\n' "$1"
}

fail() {
  failed=$((failed + 1))
  printf 'not ok - %s: %s\n' "$1" "$2"
}

nl='
'

# visible TEXT: prints TEXT with each newline written as \n, for a failure message.
visible() {
  rest=$1
  text=
  while :; do
    case $rest in
      *"$nl"*)
        text="$text${rest%%"$nl"*}\\n"
        rest=${rest#*"$nl"}
        ;;
      *)
        printf '%s' "$text$rest"
        return
        ;;
    esac
  done
}

# run CASE WANT_STDOUT WANT_STDERR WANT_STATUS [GREET_ARGS...]
# Each stream must be exactly the wanted line and its newline, or empty when
# nothing is wanted. The x printed after greet.sh keeps its trailing newlines,
# which $(...) would remove.
run() {
  name=$1
  want_out=$2
  want_err=$3
  want_status=$4
  shift 4
  if [ -n "$want_out" ]; then
    want_out="$want_out$nl"
  fi
  if [ -n "$want_err" ]; then
    want_err="$want_err$nl"
  fi
  out=$(sh "$greet" "$@" 2>/dev/null </dev/null; rc=$?; printf x; exit "$rc")
  status=$?
  out=${out%x}
  err=$(sh "$greet" "$@" 2>&1 >/dev/null </dev/null; printf x)
  err=${err%x}
  if [ "$out" = "$want_out" ] && [ "$err" = "$want_err" ] && [ "$status" = "$want_status" ]; then
    pass "$name"
  else
    fail "$name" "expected status $want_status, stdout \"$(visible "$want_out")\", stderr \"$(visible "$want_err")\"; got status $status, stdout \"$(visible "$out")\", stderr \"$(visible "$err")\""
  fi
}

run 'greet.sh --shout Ada' 'HELLO, ADA!' '' 0 --shout Ada
run 'greet.sh --shout' 'HELLO, WORLD!' '' 0 --shout
run "greet.sh --shout ''" 'HELLO, WORLD!' '' 0 --shout ''
run 'greet.sh --shout Ada Bob' '' 'greet: too many arguments' 2 --shout Ada Bob
run 'greet.sh Ada --shout' '' 'greet: too many arguments' 2 Ada --shout
run 'greet.sh --shout -x' '' 'greet: unknown option: -x' 2 --shout -x
run 'greet.sh Ada' 'Hello, Ada!' '' 0 Ada
run 'greet.sh' 'Hello, world!' '' 0
run "greet.sh ''" 'Hello, world!' '' 0 ''
run 'greet.sh Ada Bob' '' 'greet: too many arguments' 2 Ada Bob
run 'greet.sh -x' '' 'greet: unknown option: -x' 2 -x
run 'greet.sh -x Ada' '' 'greet: unknown option: -x' 2 -x Ada
run 'greet.sh --shout ada-lovelace_42' 'HELLO, ADA-LOVELACE_42!' '' 0 --shout ada-lovelace_42

# Only a to z become A to Z. This case runs last, under a UTF-8 locale, where
# an upper-caser that follows the locale would also change the e with diaeresis.
# Octal escapes keep this file ASCII.
LC_ALL=C.UTF-8
export LC_ALL
zoe=$(printf 'zo\303\253')
run "greet.sh --shout $zoe" "$(printf 'HELLO, ZO\303\253!')" '' 0 --shout "$zoe"

# The request asks for the option in this page, not anywhere under doc/.
if grep -q -e '--shout' "$dir/doc/product/spec/greeting.md" 2>/dev/null; then
  pass 'doc/product/spec/greeting.md mentions the option'
else
  fail 'doc/product/spec/greeting.md mentions the option' 'expected doc/product/spec/greeting.md to mention --shout; it does not, or is missing'
fi

printf '%s passed, %s failed\n' "$passed" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
