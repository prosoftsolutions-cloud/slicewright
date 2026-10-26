---
type: decision
status: accepted
date: 2026-10-25
---

# 0010 The finished-run fixture is an overlay on the sample

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D14 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- The self-test must prove that each smoke check fails on a finished run with one thing broken, without a headless session.
- A finished run is the sample project plus what the pipeline added: the feature, its documentation, the `slice/` records and the entry in the records index.
- `prepare` makes a run's copy from a source folder: it writes the test configuration, appends `/slice/` to the copy's `.gitignore`, and commits it all.

## Decision

- `tests/fixtures/finished-run/` holds only what a passing run adds or changes: `greet.sh` with the feature, `doc/product/spec/greeting.md`, which mentions `--shout`, the `slice/` records, and `.slicewright/slices/index.md`.
- It has no `.gitignore` and no `.slicewright/smoke.json`, because `prepare` writes both.
- For each smoke case, the self-test copies `tests/sample/project/`, lays the overlay on top, runs `sh tests/smoke.sh prepare` on the result, breaks one thing, and runs `sh tests/smoke.sh check`.
- The fixture's `slice/` folder is committed in this repo. The repo's `/slice/` rule in `.gitignore` matches only the root.

## Alternatives

- **A full snapshot of a finished run.** Rejected: it duplicates the sample and its git history, and drifts from the sample.

## Consequences

- There is no second copy of the sample to drift from it. A change to the sample reaches the fixture. [Concepts](../concepts.md) states this as the rule that every value has one source.
- Breaking the acceptance check is simple: put the sample's own `greet.sh` back and commit. Only check 6 fails.
- The fixture's records are stand-ins, a heading and one line each. They can drift from what tracking and consolidate really write. Only a real smoke run shows that, as a failing check.
- The fixture has no session output, so checks 1 and 2 fail in every smoke case. The self-test therefore can't show that one failing check from 3 to 8, on its own, makes the command fail.
- Agents working on this repo may think the fixture's `slice/` folder must not be committed. The [Testing](../../overview/testing.md) page says that it is.
