#!/bin/sh
# greet prints a greeting.
# Usage: sh greet.sh [--shout] [name]
# With no name, or an empty one, it greets the world.
# With --shout as the first argument, it prints the greeting in upper case.
# Errors go to stderr as "greet: message", with exit status 2.

shout=no
if [ "${1-}" = --shout ]; then
  shout=yes
  shift
fi

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

if [ "$shout" = yes ]; then
  printf 'Hello, %s!\n' "$name" | tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
else
  printf 'Hello, %s!\n' "$name"
fi
exit 0
