---
id: R1-T02
title: Acceptance check covers the three missing outcomes
type: test
depends: [R1-T01]
covers: [R1-F2]
---

# R1-T02 Acceptance check covers the three missing outcomes

## Goal

`tests/sample/accept.sh` also checks `greet.sh Ada --shout`, `greet.sh --shout -x` and `greet.sh --shout ''`, so a run whose `greet.sh` breaks those outcomes of the request fails smoke check 6.

## Context

**The finding, R1-F2: the acceptance check misses three outcomes the request states.**

- Where: `tests/sample/accept.sh:55`.
- Bar: R3 ("an acceptance check for that request") and R6.6, below. The outcomes are in `tests/sample/request.md`, lines 4 to 6.
- Problem: `accept.sh` never runs `greet.sh Ada --shout` (must print `greet: too many arguments` and exit 2), `greet.sh --shout -x` (must print `greet: unknown option: -x` and exit 2) or `greet.sh --shout ''` (must print `HELLO, WORLD!`). A run whose `greet.sh` takes `--shout` in either position, or shouts a name that starts with `-`, passes check 6. So the smoke test would report a working feature that breaks the request.
- Proof: `sh tests/sample/accept.sh <folder>`, on a folder whose `greet.sh` takes `--shout` in either position and skips the unknown-option rule after it → `7 passed, 0 failed`. Yet `sh <folder>/greet.sh Ada --shout` → `HELLO, ADA!`, and `sh <folder>/greet.sh --shout -x` → `HELLO, -X!`.
- Suggested fix: add the three cases as `run` calls in `tests/sample/accept.sh`. The fixture's `greet.sh` already gives the expected output for all three (exit 2 with `greet: too many arguments`, exit 2 with `greet: unknown option: -x`, and `HELLO, WORLD!`), so the self-test still passes.
- Decision: fix.

**What the request says, in `tests/sample/request.md`:**

- `sh greet.sh --shout` prints `HELLO, WORLD!` and exits 0. An empty name after `--shout` is the same as no name.
- The option counts only as the first argument, followed by at most one name. `sh greet.sh --shout Ada Bob` and `sh greet.sh Ada --shout` both print `greet: too many arguments` on stderr and exit 2.
- A name never starts with `-`: after `--shout`, such an argument is an unknown option, so `sh greet.sh --shout -x` prints `greet: unknown option: -x` on stderr and exits 2.

**The requirements it must keep meeting:**

- **R3** The sample has a request for one small, fully specified feature, and an acceptance check for that request. The acceptance check is kept outside the sample's files, so the pipeline never sees or changes it.
- **R6.6** The acceptance check passes against the copy.
- **AC4** (R3) Given a fresh copy of the sample, when the acceptance check runs against that unchanged copy, then it fails, because the requested feature doesn't exist yet.
- The design's contract for `accept.sh <project folder>`: it prints `ok`/`not ok` lines, never writes to the folder, and exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing. Each case compares stdout, stderr and the exit status exactly, and its name is `greet.sh <args>`.

## Interfaces

**Uses:**

- `run CASE WANT_STDOUT WANT_STDERR WANT_STATUS [GREET_ARGS...]`: from `tests/sample/accept.sh`, as it is. It runs `sh "$greet" GREET_ARGS...` and compares stdout, stderr and the status exactly.

## Changes

- `tests/sample/accept.sh` (changed)
  - Add three `run` calls among the existing ones, in the request's order, so the cases read:
    1. `greet.sh --shout Ada` (existing)
    2. `greet.sh --shout` (existing)
    3. new: `run "greet.sh --shout ''" 'HELLO, WORLD!' '' 0 --shout ''`. The name is in double quotes so that the two single quotes show in it.
    4. `greet.sh --shout Ada Bob` (existing)
    5. new: `run 'greet.sh Ada --shout' '' 'greet: too many arguments' 2 Ada --shout`
    6. new: `run 'greet.sh --shout -x' '' 'greet: unknown option: -x' 2 --shout -x`
    7. `greet.sh Ada` (existing)
    8. `greet.sh -x` (existing)
    9. `greet.sh --shout ada-lovelace_42` (existing)
    10. the doc case (existing), last as now.
  - Nothing else changes: the usage, the checks of the folder and `greet.sh`, `run`, `pass`, `fail`, the doc case, the totals line and the exit statuses.

## Verify

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for every attempt.

- `dash -n tests/sample/accept.sh`: no output, exit 0.
- `mktemp -d`: prints `<tmp>`.
- `cp -R tests/fixtures/finished-run <tmp>/loose`: exit 0.
- Read `<tmp>/loose/greet.sh`, then replace it with the Write tool by this `greet.sh`, which breaks the request in the three ways the finding names:

  ```sh
  #!/bin/sh
  # Breaks the request: --shout in either position, no unknown-option rule
  # after --shout, and an empty name after --shout shouted as it is.
  shout=no
  if [ "${1-}" = --shout ]; then
    shout=yes
    shift
  elif [ "${2-}" = --shout ]; then
    shout=yes
    set -- "$1"
  else
    case ${1-} in
    -*)
      printf 'greet: unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    esac
  fi
  if [ "$#" -gt 1 ]; then
    printf 'greet: too many arguments\n' >&2
    exit 2
  fi
  if [ "$shout" = yes ]; then
    printf 'Hello, %s!\n' "${1-world}" | tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  else
    printf 'Hello, %s!\n' "${1:-world}"
  fi
  ```

- `sh <tmp>/loose/greet.sh Ada --shout`: `HELLO, ADA!`. `sh <tmp>/loose/greet.sh --shout -x`: `HELLO, -X!`. `sh <tmp>/loose/greet.sh --shout ''`: `HELLO, !`. The loose `greet.sh` breaks the request.
- **R1-F2 repro, before the change:** `sh tests/sample/accept.sh <tmp>/loose`: `7 passed, 0 failed`, exit 0. This is the failure.
- **R1-F2, after the change:** `sh tests/sample/accept.sh <tmp>/loose`:
  - `not ok - greet.sh --shout ''`, `not ok - greet.sh Ada --shout` and `not ok - greet.sh --shout -x`, each with what it expected and got;
  - an `ok` line for each of the other seven cases;
  - last line `7 passed, 3 failed`, exit 1.
- **R6.6 on a passing run:** `sh tests/sample/accept.sh tests/fixtures/finished-run`: ten `ok` lines, among them `ok - greet.sh --shout ''`, `ok - greet.sh Ada --shout` and `ok - greet.sh --shout -x`; last line `10 passed, 0 failed`; exit 0.
- `dash tests/sample/accept.sh tests/fixtures/finished-run`: the same output, exit 0.
- **AC4:** `sh tests/sample/accept.sh tests/sample/project`: `ok - greet.sh Ada --shout`, `not ok - greet.sh --shout ''`, `not ok - greet.sh --shout -x`; last line `3 passed, 7 failed`; exit 1.
- `git status --porcelain`: `tests/sample/accept.sh` is the only changed path.

## Boundaries

- `tests/sample/project/`, `tests/sample/request.md` and `tests/fixtures/finished-run/` don't change. The fixture's `greet.sh` already gives the expected output for the three new cases.
- `accept.sh` keeps its interface: one argument, the output lines, the totals line, the exit statuses, and it never writes to the folder.
- `tests/smoke.sh` (R1-T01) and `tests/selftest.sh` don't change. The self-test runs `accept.sh` through check 6, and needs no new case.
- `slice/docs/overview/testing.md` doesn't change in this task: it doesn't list the acceptance cases.
