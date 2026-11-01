---
type: architecture
---

# Risks and technical debt

What a person chose to leave open: the review findings and tests they deferred, and the root causes of bugs that stay unfixed. A slice that fixes one removes its row.

| Risk | What it risks | Reason | Owner | Date | Source |
|---|---|---|---|---|---|
| The smoke test's cost is unmeasured, and the one-minute limit is unproven | Nobody knows what a smoke run costs. [Testing](../overview/testing.md) gives no measured cost or duration, and the one passing run's cost stayed in its run folder's `run.txt`, under the OS's temporary folder, which no longer exists. The duration rests on that one run, about 53 minutes against a 90-minute limit. Nothing has shown a one-minute limit stopping a run, so the watchdog's stop and the report's `time limit:` line are unproven. The `isolation` check passed on a real session, but the report doesn't say what the developer's own setup had enabled, so that criterion is shown only as far as the report goes. | A person chose to build the tests without a smoke run, and accepted the finding at review. The first real run came with the slice "Research flow" (issue #16): its `test` stage ran the `smoke` suite, which started the run and waited for it in steps, and the run passed all eight checks in about 53 minutes at revision acec9eb. That proved the seven-stage run passing within 90 minutes, the suite reporting a run far longer than one shell command may last, and the run folder keeping the session's output. The run's cost, and the measured numbers on the testing page, weren't among what that slice set out to change, and no run was made with `--minutes 1`. A follow-up runs `sh tests/smoke.sh --minutes 1`, and adds the measured cost and duration of a passing run to the testing page. | not named | 2026-10-25 | [R1-F3](../../.slicewright/slices/2026-10-25-issue-2/code-reviews.md) of the slice "Tests" (issue #2); narrowed by [run 1](../../.slicewright/slices/2026-10-27-issue-16/test-reports.md) of the slice "Research flow" (issue #16) |
