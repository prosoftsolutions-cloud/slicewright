---
type: decision
status: accepted
date: 2026-10-25
---

# 0003 The test stage waits for a smoke run in steps: `start`, then `wait` again and again

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D3 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md). Its handling of a run that stopped without finishing was settled in the slice's review rounds 1 and 2 (findings R1-F1 and R2-F1).

## Context

- A smoke run takes up to 90 minutes. A shell command that a stage's agent runs lasts at most 10 minutes.
- The test stage's fixed suite prompt forbids `cd`, and chaining with `&&`, `;`, pipes or loops. It says to give long commands the longest timeout the shell tool allows.
- A probe showed that a process started with `nohup … &` from a script outlives the shell call that started it, and that the call returns at once. A `sleep` loop inside a script isn't blocked.

## Decision

- `sh tests/smoke.sh start` prepares the copy, starts the session part with `nohup`, and returns at once. Its last line, `run: <folder>`, names the run folder.
- `sh tests/smoke.sh wait <folder>` blocks inside the script for at most `WAIT_SECONDS`, 540 seconds.
  - While the run is going, it exits 3.
  - Once the run has ended, it prints the saved report and exits 0 or 1, as the report says.
- The `smoke` entry in the `test` stage's `testAgents`, in `.slicewright/config.json`, runs `start`, then the same `wait` while it exits 3. It reports each check as one test, and the run folder as the artifacts.
- When the run hasn't ended and the process recorded as `smoke_pid` is gone, `wait` records the run as ended, as the background part would have. It adds `cost_usd` and `duration_ms` to `run.txt`, each `unknown` when the session didn't report it. It saves the report as `checks.txt`, writes `ended` last, and exits as the report says.

## Alternatives

- **One blocking command.** Rejected: a shell call lasts at most 10 minutes.
- **The shell tool's background mode, or Monitor.** Rejected: their notifications reach a subagent only between turns, and an until-loop in the command breaks the suite prompt.
- **`wait` evaluating the checks of a stopped run without recording them, and always exiting 1.** This was the first version. Rejected in review: the run then kept no check results and no cost or duration, and `wait` could exit 1 for a run whose saved report had passed.

## Consequences

- The suite needs only the shell tool. It keeps the suite prompt's rules: one command per call, no loop in the command, and every call under 10 minutes.
- A detached run that dies doesn't make the suite wait forever: `wait` finds `smoke_pid` gone, records the run, and reports it.
- `wait` exits the same way on every path: from the report once the run has ended, 3 while it is going, and 2 when it couldn't run. [Concepts](../concepts.md) states this as the rule for check commands.
- The branch for a run that stopped without finishing is proven only on hand-made run folders. No self-test case runs `wait`, and a real background run killed partway is unproven.
- [Runtime](../runtime.md) shows the flow, and [Testing](../../overview/testing.md) gives the commands and their output.
