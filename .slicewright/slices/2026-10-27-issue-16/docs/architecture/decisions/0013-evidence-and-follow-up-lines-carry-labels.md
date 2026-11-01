---
type: decision
status: accepted
date: 2026-10-27
---

# 0013 Evidence lines carry `Source:` and `Confidence:`, and a follow-up has a title before a colon and a `Decision:` line of its own

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D3 and D4 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md). The rule that says where a follow-up's title is was added at the slice's design review.

## Context

- The spec asks that each evidence line of `research.md` has a source and one of the four confidence words, that the Recommendation ends with an empty `Decision:` line, and that every follow-up ends with one, for the person to fill at `results-review`.
- The research reviewer opens the cited source to check a claim, so the source has to stand out from the claim. A citation holds commas, parentheses, a link and a date.
- `file-issues` needs a title for the issue and for its exact-title search ([0017](0017-file-issues-finds-an-issue-by-exact-title.md)), and `results-review` writes `Decision: file` or `Decision: no issue` on each follow-up. The design review found that the `file-issues` context looked for an issue with the same title without saying where a follow-up's title is, so two runs could pick different titles and file a duplicate.
- The review record already ends an advisory finding's line with a ` · Decision:` suffix.

## Decision

- Each evidence line is `- {claim}. Source: {cited as the rules say}. Confidence: {low | medium | high | sure}`. The answer line is `- **Answer** ({confidence}): {text}`.
- Each follow-up is `- **F<n>** {title}: {what, and why it matters}`, with an indented `Decision:` line of its own below it. The title is the text between the id and the first colon.
- The `file-issues` context in `research.json` states the same shape and the same title rule, so the skill that writes the line and the context that reads it agree.

## Alternatives

- **A compact `claim (source, level)`.** Rejected: the source is hard to tell from the claim when a citation has commas or parentheses.
- **A table for the evidence.** Rejected: long citations break tables.
- **`Decision:` at the end of the follow-up's line, as the ` · Decision:` suffix of advisory findings.** Rejected: that suffix ends a line a person doesn't otherwise edit. Here the person fills it, and a line of its own is what the spec asks for.
- **The follow-up's first sentence as its title.** Rejected: brittle.

## Consequences

- A reviewer, a person, `file-issues` and the research page find the source, the confidence and the title at a fixed place. The skill's self-check looks for an evidence line without `Source:` or a confidence word.
- The lines are a contract between the plugin's skill and this repo's contexts: `results-review`, `file-issues` and the `research` knowledge agent. A project that writes its own contexts reads the same shape. [Building blocks](../building-blocks.md) describes `research.md` as that interface.
- The exact-title search ([0017](0017-file-issues-finds-an-issue-by-exact-title.md)) depends on a title staying the same between runs, which the rerun rules keep ([0014](0014-a-later-research-run-keeps-what-a-person-wrote.md)).
- Unproven in a run: no research stage has written a `research.md` yet.
