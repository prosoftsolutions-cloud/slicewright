---
type: decision
status: accepted
date: 2026-10-27
---

# 0014 A later research run keeps what a person wrote, and matches questions and follow-ups by text

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D5 and D6 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- At `results-review` a person writes into `research.md`: the decision on the recommendation's `Decision:` line, `file` or `no issue` on each follow-up's, one line under `## Decisions` for each open question answered, and requests under `## Review notes`. The spec asks that a later run keeps all of it: filled `Decision:` lines never change, Decisions lines count as settled, and each note is reworked and then removed.
- `more-research` runs `research` again on the same spec. `re-scope` runs `clarify` again, which may renumber the questions, then `questions-review`, then `research`.
- Sending only the open questions to the agents is what makes `more-research` cheap.
- A rerun may recommend another option than the one the person decided on.

## Decision

- The stage matches questions and follow-ups by their text, not their number.
- On a later run it keeps `## Decisions` as it is, and treats each line as settled: never asked again, never an open question. It keeps every filled `Decision:` line as it is, the recommendation's and each follow-up's, whatever the words. It keeps the answer, evidence and disagreements of each question whose text the current spec still asks, unless a note under Review notes names it. It reworks what each note asks, then removes the note. It drops the questions the spec no longer asks, and researches the new ones and the ones the notes name.
- The brief lists which questions this run researches, and the agent prompt says to answer those.
- When the run recommends a different option and the recommendation's `Decision:` line is filled, the stage says so in the Recommendation text, right above the line, and leaves the line as it is.

## Alternatives

- **Redo everything on every run.** Rejected: it wastes the earlier evidence, and the spec asks to keep it.
- **Match by number.** Rejected: it breaks after a re-scope that renumbers.
- **Clear the `Decision:` line when the recommended option changes.** Rejected: a silent change would lose a person's decision, and the spec forbids it.
- **Move the old decision under Decisions when the recommendation changes.** Rejected: a rule for a rare case. A sentence is the smallest way to show the mismatch.

## Consequences

- `more-research` costs only the questions the notes name and the new ones, and a re-scope that renumbers loses nothing. [Runtime](../runtime.md) shows both loops.
- A person's decision can stand against a changed recommendation. The sentence above the line is all that flags it, and the person sees it at `results-review`.
- The skill's closing paragraph names the words this repo's `results-review` writes: `Decision: file`, `Decision: no issue` and `Decision: none: <why>`. They are the pipeline's choice, and the skill's rule, keep every filled line as it is, doesn't depend on them. The code review rated the paragraph a suggestion, and no fix was decided. For the same reason the skill says "a later stage", not `results-review`: a stage name is a configured choice.
- The rerun has been checked by reading the skill text against the spec's case, not by a run. [Research stage](../../product/spec/research-stage.md) gives the rules under Later runs.
