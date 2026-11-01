---
type: decision
status: accepted
date: 2026-10-27
---

# 0018 The research page is named from the slice's title, with the records folder's slug rule spelled out

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D10 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- The `research` knowledge agent writes `architecture/research/<name>.md`, the path the issue gave. The spec asks that a later consolidation of the same slice updates that page rather than adding another, so two runs must compute the same name.
- Consolidate names a records folder `<date>-<id>`, or `<date>-<title in lowercase words joined with ->` for a slice without an id, and intake names the branch `slice/<number>-<title in lowercase words joined with ->`. "Words joined with `-`", left to an agent, can come out differently for punctuation, such as the colon in this slice's title.
- The `adr` agent links to the research page, and runs after the `research` agent, in list order.

## Decision

- The `research` agent's context in `research.json` states the rule: `<name>` is the slice's title from `status.md` in lowercase, where words are runs of letters and digits and everything else separates them, joined with `-`, the way a records folder is named for a slice without an id. This slice's title would give `research-flow-a-slice-research-stage-and-a-research-pipeline`, which is also how intake named its branch.
- The page's frontmatter has `type: research`, `date` from `created` in `status.md`, and `source` when `input.md` has one. When the page exists from an earlier consolidation, the agent updates it under the same name.
- The `adr` agent links to the page the `research` agent staged, instead of deriving the slug again.

## Alternatives

- **Naming the page from the id, `issue-<n>`.** Rejected: the spec names the title, and a title says what the page is about.
- **Leaving the rule to the agent.** Rejected: two consolidations could disagree on punctuation and leave two pages.

## Consequences

- The branch, the records folder and the page share one slug rule, and a later consolidation of the same slice finds its page. A topic revisited by a new slice with another title gets another page.
- The rule is written in `research.json`'s context, as a precise reading of the consolidate skill's words for a records folder. If the skill's naming changes, the context follows it.
- `doc/architecture/research/` doesn't exist yet. The first research slice creates it, and the `index` agent's added sentence lists the new folder in `architecture/index.md`. Unproven until then. [Research pipeline](../../product/spec/research-pipeline.md) gives the agent's context.
