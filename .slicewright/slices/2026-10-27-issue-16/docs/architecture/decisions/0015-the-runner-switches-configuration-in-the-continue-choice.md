---
type: decision
status: accepted
date: 2026-10-27
---

# 0015 The runner switches to the slice's configuration in the **Continue** choice, not before the question

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D7 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- A slice remembers its configuration: tracking writes `config: <file name>` into `status.md` for a configuration other than `config.json`. Before this slice, only `/slice:resume` without `--config` read it back, through one sentence in the runner's section 1, "When resuming without `--config`…".
- In `new` mode the runner loads the configuration in section 1 and checks it in section 2 before it finds a slice in progress and asks the person, in section 3: **Continue** or **Start new**. **Continue** said "go on as in `resume` below", which refers to section 3's resume steps, not to section 1, so the switch never happened. A research slice continued with `/slice:new` would have gone on with the default pipeline: its stage of the same name with the wrong context, or a stop where there is none.
- With `--config` given, the given configuration must be used, as before. **Start new** must not change.

## Decision

- Section 1 keeps its "when resuming" sentence.
- The **Continue** bullet of section 3, `new`, step 1, gains: when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file loaded, load that configuration as in section 1, check it as in section 2, and say so; then go on as in `resume`, and say that the request typed with `/slice:new` is not used.
- `Skill(slice:research)` joins the runner's `allowed-tools`, as every stage skill the plugin ships must.

## Alternatives

- **Reading `status.md` in section 1, before the question.** Rejected: it would switch before the person has chosen, and **Start new** would then start the typed request with the old slice's configuration.
- **A new section for the switch.** Rejected: more text for the same rule.

## Consequences

- A research slice in progress is continued with its pipeline from either command, and the person is told which configuration is loaded. With `--config` given, the condition fails and the given configuration stays, so `/slice:new --config config` keeps `config.json` on purpose. [Runtime](../runtime.md) shows the three paths, and [Named configurations](../../product/spec/named-configurations.md) gives the rules.
- On that path the runner loads a configuration twice, the default first and then the slice's. `status.md` is the one source of which pipeline a slice runs with.
- The change is two lines of the runner. It has been checked by reading the text: the session runs are hand checks, left to the first use after the merge.
- The switch needs a `status.md`, which exists only after intake succeeds. A research run that fails in intake's checks has no configuration to recover ([0016](0016-the-research-pipeline-holds-only-pipeline.md)).
