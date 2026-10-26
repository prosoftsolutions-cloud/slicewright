---
type: decision
status: accepted
date: 2026-10-25
---

# 0005 The smoke configuration overrides only intake's context

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D5 and D6 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- The smoke run has no gate and no person. A stage whose context waits for a person, or needs a remote, ends the run with an error.
- The spec allows only the overrides the sample needs, and the testing page lists each one with its reason.
- The default intake context asks for the "latest sources", which needs a remote that the copy doesn't have. It also says to "ask user", which no one can answer headless.
- No other param of the seven stages needs a person, a remote, GitHub or a deployment.
- Plan returns `NO_TASK_TYPE` for work that fits no task type, and the sample is a small command-line program in shell.

## Decision

- There is exactly one override: intake's `params.context`, in `tests/smoke/pipeline.json`. It says that the version control is git with no remote, and that the sample's `AGENTS.md` names the tools. It keeps the clean-tree check, and drops the check against a remote and the "ask user" step.
- There is no `taskTypes` override. The sample's `AGENTS.md` says that, in the pipeline's task types, `greet.sh` and `test.sh` are backend code, the program and the command-line interface it exposes, and that its doc pages are `documentation`.
- The sample's request states every choice, so clarify has no open question.
- Every override is listed on the [Testing](../../overview/testing.md) page, with its reason.

## Alternatives

- **Overriding clarify so that it asks no blocking question.** Rejected: it changes what the run tests. The fully specified request covers it instead.
- **A `cli` task type in the test configuration's `sharedParams`.** Rejected: it is a second override, and the run would stop testing the defaults' task types. It stays the fallback if a run ever returns `NO_TASK_TYPE`, and the testing page would then list it.

## Consequences

- The run tests the defaults with one change, and the testing page says what it is and why.
- The smoke run doesn't cover intake's check against a remote.
- A run can still fail with nothing broken, on the model's behavior alone: clarify asking a blocking question, or plan returning `NO_TASK_TYPE`. Every run is kept, and `sh tests/smoke.sh check <folder>` evaluates it again at no cost.
