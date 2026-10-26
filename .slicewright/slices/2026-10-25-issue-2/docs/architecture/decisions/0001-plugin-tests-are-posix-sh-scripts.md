---
type: decision
status: accepted
date: 2026-10-25
---

# 0001 Plugin tests are POSIX sh scripts, run as `sh tests/<name>.sh`

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D1 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- Slicewright had no tests. A new version of the plugin was checked by hand: `claude plugin validate`, then a headless run on a scratch project that someone set up and read each time.
- The repo has no runtime and no package manager. The tools at hand are the `claude` CLI, `jq`, `git` and `/bin/sh`. On macOS, `/bin/sh` is bash in POSIX mode, and `dash` exists too.
- Tests live outside `plugins/slice/`, because an installed plugin is a copy of its folder (issue #1).
- A stage's agent runs one command per call, with no chaining, and each command it runs needs a permission rule.

## Decision

- The tests are three commands at the top of `tests/`: `static.sh`, `smoke.sh` and `selftest.sh`. Each runs from the repo root as `sh tests/<name>.sh`.
- Their jq programs, awk programs and data files are in `tests/static/` and `tests/smoke/`.
- Every script uses POSIX sh only: no `local`, no arrays, no `[[ ]]`, no `sed -i` and no `grep -r`.
- They need only the `claude` CLI, `jq`, `git` and the standard utilities, plus `mktemp`.

## Alternatives

- **`./tests/<name>.sh` with an executable bit.** Rejected: it needs a mode change in version control, and gives each command a different permission prefix.
- **Bash.** Rejected: it isn't on every Linux by default, and the spec asks only for a POSIX shell.
- **A test framework, such as bats.** Rejected: it is a new tool to install, in a repo that installs nothing.

## Consequences

- Nothing has to be installed. Each command has one permission prefix, such as `Bash(sh tests/smoke.sh:*)`.
- `/bin/sh` on macOS accepts bash-only syntax, so it doesn't show it. Each script is checked with `dash -n`, and the self-test also runs under `dash`. [Concepts](../concepts.md) states this as the rule for every shell script.
- With no framework, each script prints its own `PASS` and `FAIL` lines and sets its own exit status. [Concepts](../concepts.md) gives the rule that check commands follow.
- [Testing](../../overview/testing.md) describes the three commands.
