---
type: architecture
---

# Risks and technical debt

What a person chose to leave open: the review findings and tests they deferred, and the root causes of bugs that stay unfixed. A slice that fixes one removes its row.

| Risk | What it risks | Reason | Owner | Date | Source |
|---|---|---|---|---|---|
| The smoke test has never run for real | Nobody has seen the smoke test pass. A real run may fail where the self-test passes. These are unproven: the seven-stage run passing every check within 90 minutes, a one-minute limit stopping a run, the `test` stage's `smoke` suite reporting a run longer than 10 minutes, the `isolation` check on a session where the developer's own plugins, hooks and MCP servers are enabled, and a real run's folder keeping its session output, cost and duration. [Testing](../overview/testing.md) gives no measured cost or duration, so nobody knows what a run costs, or whether 90 minutes is enough. | A person chose to build the tests without a smoke run, and accepted the finding at review. A smoke run can't start before the tests are committed. A task's Verify and a quality gate may not run one. The `test` stage of the slice that built the tests loaded its configuration before the `smoke` suite existed. A follow-up slice runs `sh tests/smoke.sh` and `sh tests/smoke.sh --minutes 1`, runs the `test` stage's `smoke` suite, and adds the measured numbers to the testing page. | not named | 2026-10-25 | [R1-F3](../../.slicewright/slices/2026-10-25-issue-2/code-reviews.md) of the slice "Tests" (issue #2) |
