---
id: R2-T02
title: Acceptance check covers letters outside a to z, and greet.sh without the option
type: test
depends: [R2-T01]
covers: [R2-F2, R2-F3]
---

# R2-T02 Acceptance check covers letters outside a to z, and greet.sh without the option

## Goal

`tests/sample/accept.sh` also checks that a letter outside a to z stays as it is under `--shout`, under a UTF-8 locale, and that `greet.sh` without the option still greets the world, and still refuses too many arguments and an unknown option. A run whose `greet.sh` breaks either rule of the request then fails smoke check 6.

## Context

**The finding, R2-F2: the acceptance check misses the request's rule that only a to z become upper case.**

- Where: `tests/sample/accept.sh:63`.
- Bar: R3 ("an acceptance check for that request") and R6.6, below. The outcome is in `tests/sample/request.md:7`: "Only the letters a to z become A to Z. Every other character stays as it is".
- Problem: the one case for this rule, `greet.sh --shout ada-lovelace_42`, has only ASCII characters, so it shows that `-`, `_` and digits stay, but not that other letters do. A `greet.sh` that uses `tr '[:lower:]' '[:upper:]'` passes all ten cases, yet under this machine's UTF-8 locale it turns `ë` into `Ë`. Check 6 would then report a working feature that breaks the request.
- Proof: a copy of `tests/fixtures/finished-run` whose `greet.sh` uses `tr '[:lower:]' '[:upper:]'`; `sh tests/sample/accept.sh <scratch>/locale` → `10 passed, 0 failed`; `sh <scratch>/locale/greet.sh --shout zoë` → `HELLO, ZOË!`; `sh tests/fixtures/finished-run/greet.sh --shout zoë` → `HELLO, ZOë!`.
- Suggested fix: add a `run` case to `tests/sample/accept.sh` with a letter outside a to z, such as `--shout zoë` → `HELLO, ZOë!`, exit 0, built with `printf` octal escapes to keep the file ASCII, and run under a UTF-8 locale so that a locale-aware upper-caser can fail it. The fixture already passes it; the unchanged sample's count becomes `3 passed, 8 failed`.
- Decision: fix.

**The finding, R2-F3: the acceptance check misses the request's "without the option, nothing changes".**

- Where: `tests/sample/accept.sh:61`.
- Bar: R3 and R6.6, below. The outcome is in `tests/sample/request.md:8`: "Without the option, nothing changes".
- Problem: without `--shout`, only `greet.sh Ada` and `greet.sh -x` are checked. No case runs `greet.sh` with no name, with an empty name, with `Ada Bob` or with `-x Ada`. Those are left to the copy's own `test.sh` (check 5), which the pipeline is asked to change, while R3 keeps the acceptance check out of its reach. A run that changes the default greeting passes check 6.
- Proof: a copy of `tests/fixtures/finished-run` whose `greet.sh` has `name=World` in place of `name=world`; `sh tests/sample/accept.sh <scratch>/noopt` → `10 passed, 0 failed`; `sh <scratch>/noopt/greet.sh` → `Hello, World!`, while `sh tests/sample/project/greet.sh` → `Hello, world!`.
- Suggested fix: add `run` cases to `tests/sample/accept.sh` for `greet.sh` (`Hello, world!`, 0), `greet.sh ''` (`Hello, world!`, 0), `greet.sh Ada Bob` (`greet: too many arguments`, 2) and `greet.sh -x Ada` (`greet: unknown option: -x`, 2), with the expectations of `tests/sample/project/test.sh`. The sample and the fixture already pass all four, so AC4 and the self-test still hold.
- Decision: fix.

**What the request says, in `tests/sample/request.md`, lines 7 and 8:**

- Only the letters a to z become A to Z. Every other character stays as it is: `sh greet.sh --shout ada-lovelace_42` prints `HELLO, ADA-LOVELACE_42!`.
- Without the option, nothing changes, and other arguments starting with `-` are still unknown options.

**What the sample does today without the option,** in `tests/sample/project/test.sh`: no name and an empty name both print `Hello, world!` and exit 0; `Ada Bob` prints `greet: too many arguments` on stderr and exits 2; `-x Ada` prints `greet: unknown option: -x` on stderr and exits 2.

**The requirements it must keep meeting:**

- **R3** The sample has a request for one small, fully specified feature, and an acceptance check for that request. The acceptance check is kept outside the sample's files, so the pipeline never sees or changes it. The sample builds and tests with no package install and no network.
- **R6.6** The acceptance check passes against the copy.
- **AC4** (R3) Given a fresh copy of the sample, when the acceptance check runs against that unchanged copy, then it fails, because the requested feature doesn't exist yet.
- The design's contract for `accept.sh <project folder>`: it prints `ok`/`not ok` lines, never writes to the folder, and exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing. Each case compares stdout, stderr and the exit status exactly, and its name is `greet.sh <args>`.

**The locale.** `C.UTF-8` is a UTF-8 locale on this machine and on common Linux systems. Under it, `tr '[:lower:]' '[:upper:]'` turns `ë` into `Ë`, in `sh` and in `dash`, while the fixture's `tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'` leaves it. In UTF-8, `ë` is the two bytes octal `303 253`. Setting `LC_ALL` in the script, exported, makes the case independent of the caller's locale: check 6 runs `accept.sh` from whatever shell runs `tests/smoke.sh`.

## Interfaces

**Uses:**

- `run CASE WANT_STDOUT WANT_STDERR WANT_STATUS [GREET_ARGS...]`: from `tests/sample/accept.sh`, as it is. It runs `sh "$greet" GREET_ARGS...` twice, with stdin from `/dev/null`, and compares stdout, stderr and the status exactly.

## Changes

- `tests/sample/accept.sh` (changed)
  - Add four `run` calls next to the existing cases without the option, so that block reads, in this order:
    1. `run 'greet.sh Ada' 'Hello, Ada!' '' 0 Ada` (existing)
    2. new: `run 'greet.sh' 'Hello, world!' '' 0`
    3. new: `run "greet.sh ''" 'Hello, world!' '' 0 ''`. The name is in double quotes so that the two single quotes show in it, as in the existing `greet.sh --shout ''` case.
    4. new: `run 'greet.sh Ada Bob' '' 'greet: too many arguments' 2 Ada Bob`
    5. `run 'greet.sh -x' '' 'greet: unknown option: -x' 2 -x` (existing)
    6. new: `run 'greet.sh -x Ada' '' 'greet: unknown option: -x' 2 -x Ada`
  - Right after `run 'greet.sh --shout ada-lovelace_42' …`, as the last `run` call and before the doc case, add the case for a letter outside a to z. Set `LC_ALL=C.UTF-8` and export it just before it, so it runs under a UTF-8 locale; the doc case after it is unaffected. Build the name and the expected output with `printf` octal escapes, so the file stays ASCII. Give it a short comment saying why it runs last and under that locale. For example:

    ```sh
    # Only a to z become A to Z. This case runs last, under a UTF-8 locale, where
    # an upper-caser that follows the locale would also change the e with diaeresis.
    # Octal escapes keep this file ASCII.
    LC_ALL=C.UTF-8
    export LC_ALL
    zoe=$(printf 'zo\303\253')
    run "greet.sh --shout $zoe" "$(printf 'HELLO, ZO\303\253!')" '' 0 --shout "$zoe"
    ```

  - The cases then number fifteen: the six with `--shout` first, as now; the six without it; `greet.sh --shout ada-lovelace_42`; `greet.sh --shout zoë`; and the doc case, last as now.
  - Nothing else changes: the usage, the checks of the folder and `greet.sh`, `run`, `pass`, `fail`, the doc case, the totals line and the exit statuses.

## Verify

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for every attempt.

- `dash -n tests/sample/accept.sh`: no output, exit 0.
- `file tests/sample/accept.sh`: its description includes `ASCII text`.
- `mktemp -d`: prints `<tmp>`.
- `cp -R tests/fixtures/finished-run <tmp>/locale`: exit 0. Read `<tmp>/locale/greet.sh`, then with the Edit tool replace `tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'` with `tr '[:lower:]' '[:upper:]'`.
- `env LC_ALL=C.UTF-8 sh <tmp>/locale/greet.sh --shout zoë`: `HELLO, ZOË!`, with an upper-case `Ë`. This `greet.sh` breaks R2-F2's rule.
- `cp -R tests/fixtures/finished-run <tmp>/noopt`: exit 0. Read `<tmp>/noopt/greet.sh`, then with the Edit tool replace `name=world` with `name=World`.
- `sh <tmp>/noopt/greet.sh`: `Hello, World!`. This `greet.sh` breaks R2-F3's rule.
- **R2-F2 and R2-F3 repro, before the change:** `sh tests/sample/accept.sh <tmp>/locale` and `sh tests/sample/accept.sh <tmp>/noopt`: each `10 passed, 0 failed`, exit 0. This is the failure.
- **R2-F2, after the change:** `sh tests/sample/accept.sh <tmp>/locale`:
  - `not ok - greet.sh --shout zoë`, with what it expected and got;
  - an `ok` line for each of the other fourteen cases;
  - last line `14 passed, 1 failed`, exit 1.
- `env LC_ALL=C sh tests/sample/accept.sh <tmp>/locale`: the same output, exit 1. The case sets its own locale, whatever the caller's is.
- **R2-F3, after the change:** `sh tests/sample/accept.sh <tmp>/noopt`:
  - `not ok - greet.sh` and `not ok - greet.sh ''`, each with what it expected and got;
  - an `ok` line for each of the other thirteen cases, among them `ok - greet.sh Ada Bob` and `ok - greet.sh -x Ada`;
  - last line `13 passed, 2 failed`, exit 1.
- **R6.6 on a passing run:** `sh tests/sample/accept.sh tests/fixtures/finished-run`: fifteen `ok` lines, among them `ok - greet.sh`, `ok - greet.sh ''`, `ok - greet.sh Ada Bob`, `ok - greet.sh -x Ada` and `ok - greet.sh --shout zoë`; last line `15 passed, 0 failed`; exit 0.
- `dash tests/sample/accept.sh tests/fixtures/finished-run`: the same output, exit 0.
- `env LC_ALL=C sh tests/sample/accept.sh tests/fixtures/finished-run`: the same output, exit 0.
- **AC4:** `sh tests/sample/accept.sh tests/sample/project`: exactly seven `ok` lines, for `greet.sh Ada --shout`, `greet.sh Ada`, `greet.sh`, `greet.sh ''`, `greet.sh Ada Bob`, `greet.sh -x` and `greet.sh -x Ada`; `not ok - greet.sh --shout zoë` among the rest; last line `7 passed, 8 failed`; exit 1.
- `git status --porcelain`: `tests/sample/accept.sh` is the only changed path.

## Boundaries

- `tests/sample/project/`, `tests/sample/request.md` and `tests/fixtures/finished-run/` don't change. The fixture's `greet.sh` already gives the expected output for the five new cases, and the sample's for the four without the option.
- `accept.sh` keeps its interface: one argument, the output lines, the totals line, the exit statuses, and it never writes to the folder. It stays ASCII.
- `tests/smoke.sh` (R2-T01) and `tests/selftest.sh` don't change. The self-test runs `accept.sh` through check 6, and needs no new case.
- `slice/docs/overview/testing.md` doesn't change in this task: it doesn't list the acceptance cases or their counts.
- Nothing under `plugins/slice/` or `.slicewright/stable/` changes.
