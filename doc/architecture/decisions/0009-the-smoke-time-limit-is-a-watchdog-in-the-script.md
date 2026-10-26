---
type: decision
status: accepted
date: 2026-10-25
---

# 0009 The smoke time limit is a watchdog inside `smoke.sh`

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D10 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- A smoke run stops at a time limit of 90 minutes. Reaching it fails the run, and the command says that the limit stopped it. The limit is set in one place under `tests/`, and can be overridden for one run. There is no cost ceiling.
- macOS has no `timeout` command, and the tests may use only the `claude` CLI, `jq`, `git` and a POSIX shell ([0001](0001-plugin-tests-are-posix-sh-scripts.md)).

## Decision

- `LIMIT_MINUTES=90` at the top of `tests/smoke.sh` is the one place where the limit is set. `--minutes <n>`, a positive whole number, sets it for one run.
- A watchdog subshell checks the session's process every 5 seconds. At the limit, it writes `<run>/timed-out`, sends TERM, and sends KILL 30 seconds later if the session is still alive.
- A foreground run traps INT and TERM. It stops the session, records `interrupted: yes`, still evaluates the checks, and prints the report.
- The same watchdog limits checks 5 and 6 to `CHECK_SECONDS`, 120 seconds each.

## Alternatives

- **`timeout` or `gtimeout` from coreutils.** Rejected: it isn't installed on macOS.
- **perl's `alarm`.** Rejected: perl isn't one of the four tools.

## Consequences

- No tool has to be installed, and the limit has one source, as [Concepts](../concepts.md) asks.
- Only the time limit bounds what a run spends. Each run records its cost.
- The session can run up to 5 seconds past the limit before the watchdog sees it.
- KILL can leave the session's child processes running. TERM comes first, with 30 seconds' grace.
- That `--minutes 1` stops a real run is still unproven: no smoke run happened in the slice that made this decision.
