#!/bin/sh
# greet prints a greeting.
# Usage: sh greet.sh [name]
# With no name, or an empty one, it greets the world.
# Errors go to stderr as "greet: message", with exit status 2.

case ${1-} in
-*)
  printf 'greet: unknown option: %s\n' "$1" >&2
  exit 2
  ;;
esac

if [ "$#" -gt 1 ]; then
  printf 'greet: too many arguments\n' >&2
  exit 2
fi

name=${1-}
if [ -z "$name" ]; then
  name=world
fi

printf 'Hello, %s!\n' "$name"
exit 0
