---
type: decision
status: accepted
date: 2026-10-27
---

# 0011 The research skill has the shape of the design skill, section by section

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D1 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- Slicewright ran features, not research: no stage answered questions from sources with evidence. The slice adds one internal stage, `slice:research`, that answers the questions in `spec.md` with research agents, merges their findings into `research.md`, and has review agents check it. The spec named the design stage as the model for the agents, the review and the record.
- The plugin holds no program code. A stage is a `SKILL.md`, and the runner's subagent reads only that skill: a skill can't include another skill's text.
- The design skill has sections 0 to 6: the arguments, the slice, the brief, the design agents in parallel with one retry, the merge, a review whose prompt carries only the documents and the answer form, and the save with a record in `design-reviews.md`. The clarify skill uses the same review and record form.
- The design rules: a skill holds the protocol, and the content lives in the configured `context`. No hardcoded examples, limits or choices in a skill.
- The research stage isn't in the default pipeline, and `plugins/slice/defaults.json` doesn't change. This repo's research pipeline runs it ([0016](0016-the-research-pipeline-holds-only-pipeline.md)).

## Decision

- `plugins/slice/skills/research/SKILL.md` has sections 0 to 6 with the design skill's names: read the arguments, read the slice, prepare the brief, run the research agents, merge, review, save and return. The agent entry format, the "ignore any other key" rule, the documentation line every agent prompt carries, the one retry, the shape of the review prompt and the record in `design-reviews.md` are the design skill's, word for word where they can be.
- Only what is research differs: the brief, the research agent's prompt and answer form, the merge rules, the template of `research.md` and the rules for a later run.
- The skill holds the protocol: the confidence scale, the answer form, the template, the rerun rules and the result block. The sources, the order of trust between kinds of sources, the citation form, what counts as evidence, what is published and whether issues are filed live in the project's configuration, as the stage's `context` and agents.
- Its params are `activeSlicePath`, `knowledge`, `context`, `researchAgents` and `reviewAgents`. Its review record goes under `## research, <time>` in `design-reviews.md`, the file clarify and design write.
- `SPEC_NOT_READY` mirrors the design stage: a blocking question left open at the questions gate would otherwise be researched on a guess.

## Alternatives

- **A shorter skill that refers to the design skill's text.** Rejected: a skill must be complete on its own, because the runner's subagent reads only it.
- **A review form and a record file of its own.** Rejected: the record in `design-reviews.md` would differ between stages for no reason, and one file keeps a slice's document reviews together.

## Consequences

- A reviewer who knows the design skill knows the research skill. Each rule is in one place per skill, but the shared shape now exists in three skills, clarify, design and research, and a change to it is made in each.
- The stage's params are in no default stage, so `defaults.json` no longer shows every stage's params, while the README still says it does. The code review rated that a suggestion, and no fix was decided. [Research stage](../../product/spec/research-stage.md) documents the params.
- The stage has never run. The slice's test stage ran only the smoke suite, which runs the default pipeline, so the first research topic after the merge is the stage's first run. [Building blocks](../building-blocks.md) shows the stage's place, and [Research stage](../../product/spec/research-stage.md) says what it does.
