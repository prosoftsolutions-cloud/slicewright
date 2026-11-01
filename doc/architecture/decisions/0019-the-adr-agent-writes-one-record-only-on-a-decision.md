---
type: decision
status: accepted
date: 2026-10-27
---

# 0019 The research pipeline's `adr` agent writes at most one record, and only when the decision doesn't start with `none`

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D11 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md). Its `none` rule was settled at the slice's design review.

## Context

- The spec asks that a decision record exists exactly when the person wrote a decision other than `none` at `results-review`.
- `results-review` writes on the recommendation's `Decision:` line the decision in the person's words, or `none: <why>`. `accept` is open only when that line and every follow-up's are filled. So `none: <why>` is neither empty nor exactly `none`.
- `config.json`'s `adr` context asks for a record for each significant decision in `design.md`. A research slice has no `design.md`.
- The design review found that the first rule, "neither empty nor `none`", would make the agent write a record for `none: <why>`.
- The `research` agent runs before `adr`, so the research page is staged when `adr` starts ([0018](0018-the-research-page-is-named-from-the-slices-title.md)).

## Decision

- The `adr` agent's context in `research.json`: when the `Decision:` line under Recommendation in `research.md` is filled and doesn't start with `none`, one new record, `NNNN-<title>.md`, numbered after the last one, in the form of the records there: its context from the conclusions, the decision as the person wrote it, the other options as the alternatives with why each lost, its consequences, and a link to the research page this slice staged under `architecture/research/`. When the decision replaces an earlier record, that record is marked superseded and the two are linked. Nothing otherwise: an empty line, or one that starts with `none`, is no decision.
- "Starts with `none`" is the one rule shared by the writer, `results-review`, the `adr` agent, and the `research` page agent, which shows a `none` decision with its reason.

## Alternatives

- **Reusing `config.json`'s `adr` context.** Rejected: there is no `design.md`, and the agent would invent records from the conclusions.
- **"Neither empty nor exactly `none`".** The first draft. Rejected at the design review: `none: <why>` would count as a decision.
- **The `adr` agent deriving the page's slug itself.** Rejected: the staged page is there to link to, and one context names it ([0018](0018-the-research-page-is-named-from-the-slices-title.md)).

## Consequences

- A research slice leaves one record at most, from the person's decision, where a feature slice leaves one per design decision. Both kinds share the folder and the numbering. A record from a feature slice links to its design, and one from a research slice to its research page.
- The rule hangs on a prefix. A decision that begins with the word "none" in another sense, such as "None of the options; …", gets no record. The person sees the line at `results-review`.
- Unproven in a run. [Research pipeline](../../product/spec/research-pipeline.md) gives the context, and [Runtime](../runtime.md) the order of the three agents.
