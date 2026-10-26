---
type: decision
status: accepted
date: 2026-10-25
---

# 0004 The smoke test's configuration is generated at run time from the working copy's defaults

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D4 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- The smoke run must test the working copy's own defaults. Each of its seven stages must have the `skill`, `executionMode` and `params` of the stage of the same name in `plugins/slice/defaults.json`, read when the command runs, apart from the overrides the testing page lists. Nothing under `tests/` may hold a copy of those params.
- The runner takes `/slice:new --config <name>`. It merges `defaults.json`, then `~/.slicewright/<name>`, then `.slicewright/<name>`, then `.slicewright/<name>.local.json`. A later `pipeline` replaces the earlier one whole, and `sharedParams` merge key by key.

## Decision

- `prepare` generates the configuration when a run starts: `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq <repo>/plugins/slice/defaults.json`. It writes the result to `<copy>/.slicewright/smoke.json`.
- `tests/smoke/pipeline.json` holds only the list of stages and the overrides.
- Each of the seven stages is the whole default stage of that name, without its `next` and `onError`. Its `params` are deep-merged with its override. Its `next` is the following stage, and the last stage, consolidate, has none.
- The file holds only `pipeline`, so `sharedParams` come from the defaults.
- The session starts with `/slice:new --config smoke.json`.
- An override for a stage outside the list, or a stage that the defaults don't have exactly once, is an error, and `prepare` exits 2.

## Alternatives

- **A test configuration written by hand under `tests/`.** Rejected: it copies the defaults' params, and a copy drifts from them.
- **Taking only `skill`, `executionMode` and `params` from each default stage.** Rejected: it would drop a field such as `agent` or `args` if a default stage gained one.
- **Writing the copy's `.slicewright/config.json`.** Rejected: it hides which configuration the run used, while `config: smoke.json` in `status.md` shows it.
- **A self-test case that compares the generated configuration with the defaults.** Rejected: no requirement asks for it, and the generation makes the match hold by construction. The slice compared them once, by hand.

## Consequences

- A change to `defaults.json` reaches the next smoke run with no change under `tests/`. [Concepts](../concepts.md) states this as the rule that every value has one source.
- Check 3 takes its expected stage names from the generated `smoke.json`, so the stage list has one source, `pipeline.json`.
- The run has no gates and no `onError`, so any error ends it. It doesn't test the gates or the `onError` routes.
- A user's `~/.slicewright/smoke.json` would be merged in, so the command refuses to start when one exists ([0006](0006-the-smoke-session-is-isolated-from-the-developers-setup.md)).
- [0005](0005-the-smoke-configuration-overrides-only-intakes-context.md) says which override there is, and [Testing](../../overview/testing.md) lists it.
