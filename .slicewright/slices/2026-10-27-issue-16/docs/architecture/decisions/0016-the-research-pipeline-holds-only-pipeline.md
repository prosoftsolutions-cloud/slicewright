---
type: decision
status: accepted
date: 2026-10-27
---

# 0016 `research.json` holds only `pipeline`, and repeats intake's and release's contexts

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D8 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- A named configuration is loaded instead of `config.json`, not on top of it: the runner reads `defaults.json`, `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>`. `research.json` gets nothing from `config.json`.
- The spec asks for `pipeline` and, only where it must differ from the defaults, `sharedParams`, with `activeSlicePath` staying `./slice`.
- `config.json`'s `sharedParams` are `activeSlicePath` `./slice`, a `knowledge` byte-identical to the defaults', and `taskTypes`. The research pipeline has no plan or implement stage, so it uses no task type.
- Its intake and release do what `config.json`'s do: the pre-start checks, the issue as the input and the branch; the push and the pull request.
- The smoke configuration holds only `pipeline` too ([0004](0004-the-smoke-test-configuration-is-generated-from-the-defaults.md)).

## Decision

- `.slicewright/research.json` has `pipeline` only. Its `sharedParams` are the defaults': `activeSlicePath` `./slice`, the defaults' `knowledge`, and the defaults' `taskTypes`, which no stage uses.
- Intake's and release's contexts are `config.json`'s, byte for byte. The `index` knowledge agent's context is `config.json`'s with one sentence added at the end: a folder whose `index.md` is new is listed in its parent's `index.md`.
- The pages that describe the file say what it repeats, from where, and why.

## Alternatives

- **Copying `config.json`'s `sharedParams`.** Rejected: a second copy of `knowledge` and `taskTypes` that drifts, and the task types are unused in this pipeline.

## Consequences

- A change to the defaults' `knowledge` or `activeSlicePath` reaches the research pipeline with no change to `research.json`. There is one slice at a time across both pipelines, and `start-slice.sh`'s leftover-slice note keeps working. [Concepts](../concepts.md) lists the file under one source per value.
- The two verbatim contexts can drift from `config.json`'s. No check compares them: the slice compared them by hand, and [Structure](../../overview/structure.md) says why they are repeated. A change to intake's or release's context in `config.json` is made in `research.json` too.
- Intake's fix message, verbatim from `config.json`, says to quit and run `sh start-slice.sh`, without `--config`. Intake is the first stage, and `status.md` exists only after it succeeds, so the **Continue** switch ([0015](0015-the-runner-switches-configuration-in-the-continue-choice.md)) can't recover the configuration, and the person adds `--config research` themselves. The code review rated this a suggestion and proposed a configuration-neutral sentence in both files; no fix was decided. [Research pipeline](../../product/spec/research-pipeline.md) lists it as a limitation.
- The `configs` check ([0020](0020-the-configs-check-is-defaults-jq-with-an-optional-base.md)) merges `research.json` onto the defaults the runner's way, so the file is proven as far as that check and the runner's own go. It hasn't run end to end.
