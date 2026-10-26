---
type: decision
status: accepted
date: 2026-10-25
---

# 0002 One smoke command with subcommands

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D2 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- The smoke level runs in several ways: the whole run in the foreground by hand, in the background from the test stage, and again on a kept run, to evaluate its checks without a new session.
- The self-test must prove the smoke checks on a finished-run fixture, without a headless session.
- Each separate command needs its own permission rule.

## Decision

- One script, `tests/smoke.sh`.
  - With no subcommand, and an optional `--minutes <n>`, it runs the whole run in the foreground.
  - `start`, `wait <run folder>`, `check <run folder>` and `prepare <source folder> <run folder>` are its subcommands.
  - `_finish <run folder>` is internal: the session part of a background run, which `start` starts.
- The self-test builds each smoke case's run folder with `prepare` and evaluates it with `check`. That is the code a real run uses.

## Alternatives

- **A separate script for each step.** Rejected: more paths, and more permission rules.
- **A library that several scripts source.** Rejected: a second interface to the same functions.

## Consequences

- One permission prefix, `Bash(sh tests/smoke.sh:*)`, covers the smoke level.
- The self-test proves the very copy step and checks that a real run uses, not a copy of them.
- The self-test calls only `prepare` and `check`. `start`, `wait`, the watchdog and `--minutes` have no test that runs without a model. Reviews named this as advisory findings in every round, and no fix was decided.
- [Testing](../../overview/testing.md) lists the subcommands, their output and their exit statuses. [0003](0003-the-test-stage-waits-for-a-smoke-run-in-steps.md) says why `start` and `wait` exist.
