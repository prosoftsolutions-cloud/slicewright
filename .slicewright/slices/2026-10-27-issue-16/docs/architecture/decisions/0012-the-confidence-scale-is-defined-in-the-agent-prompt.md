---
type: decision
status: accepted
date: 2026-10-27
---

# 0012 The confidence scale is defined once, in the research agent's prompt, and the merge derives an answer's confidence from it

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D2 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- The spec defines four confidence levels in the skill, so that every project's findings use the same words, as the diagnose skill defines its levels: `low` is inferred, or from a secondary source, or disputed; `medium` is stated by one source the agent read; `high` is stated by two independent sources, or by the primary source for the matter; `sure` is shown by the project's own code or documentation, or checked by the agent itself. What counts as a credible source, and how to cite, stay in the project's `context`.
- A research agent sees only its prompt. It can't read the skill.
- Agents report a confidence per claim. `results-review` presents each answer with its confidence, so an answer needs one too.
- An agent's confidence is its own judgement.

## Decision

- The four levels and their definitions are in the research agent's prompt block, in the skill's section 3. The same form serves when the stage plays an `inline` entry, or researches everything itself because no `researchAgents` are configured.
- Section 4, the merge, gives each answer one confidence from its evidence: the lowest confidence of the evidence the answer depends on; `high` when two independent sources state the same, as the scale says; `sure` for what the brief found in the project's own code or documentation.
- A question nothing answers gets "not answered" with why, and no confidence.

## Alternatives

- **The scale in `research.json`'s context.** Rejected: the spec puts it in the skill so that every project uses the same words.
- **A "Confidence" section in the skill, which the prompt refers to by name.** Rejected: the agent can't read the skill.
- **The scale restated in section 4 for the merge.** Rejected: a second copy drifts. Section 4 names the levels and refers to the scale.

## Consequences

- Every `research.md` uses the same four words, so a reviewer, a person and the research page read them the same way. The skill's self-check and the review look for an evidence line without one of them.
- An answer is never more confident than its weakest evidence. Two agents agreeing lifts it to `high` only when their sources are independent.
- The confidence is still self-reported. The merge's lowest-of rule, and the reviewer's check for "a confidence the evidence doesn't justify", opening the source, are the two guards.
- Unproven in a run: the stage hasn't run yet ([0011](0011-the-research-skill-has-the-design-skills-shape.md)). [Research stage](../../product/spec/research-stage.md) gives the scale.
