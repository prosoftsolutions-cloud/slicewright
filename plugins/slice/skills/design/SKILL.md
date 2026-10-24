---
name: design
description: Internal Slicewright design stage. Coordinates design agents and review agents to turn the approved spec.md into design.md, with the approach, decisions and their alternatives, contracts, risks and open questions, for a person to review. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Design

Decide how to build what spec.md describes, and write it down so that a person can review it and the plan stage can break it into tasks. You coordinate: design agents explore the code and propose, you merge their proposals into one design, review agents check it, and you handle what they find. Never write code here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `docPath`: the project's knowledge folder, which may be missing
- `context`: the project's rules for this stage, which may be missing, such as where its patterns are described, which documentation tools to use, and what a design must cover
- `designAgents`: the agents that explore the code and propose the design. When missing, you design everything yourself.
- `reviewAgents`: the agents that review the merged draft. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. A reviewer's `context` is its review instructions: what to look for; empty means a general review.

Each agent entry has:

- `executionMode`: `fork` runs it as a subagent; `inline` means you take that role yourself, following its context
- `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
- `context`: its role and when it applies; empty means the general role
- `name`: a label for the record, which may be missing

Ignore any other key. The context is rules for you to follow. Never copy it into a file.

Never ask the user anything. What you can't settle becomes an open question in design.md, and a later stage takes it to a person.

## 1. Read the slice

- `<activeSlicePath>/spec.md`: what to build. If it doesn't exist, return `NO_SPEC`. If it still has an open question that blocks design, return `SPEC_NOT_READY`, naming the question.
- `<activeSlicePath>/input.md`: the request, and the decisions recorded with it.
- `<activeSlicePath>/design.md`, when it exists from an earlier run: a person may have answered questions and left review notes in it. Keep those answers as confirmed decisions, and rework what the notes ask for.

## 2. Prepare the brief

Gather what every design agent needs, once, so they don't each repeat it:

- **Sources the context names:** read every one.
- **Knowledge in `docPath`:** if the folder exists, read its `index.md` first, then follow links to the concepts related to the spec, and read only those. Prefer pages that carry `verified`. Treat pages with `status: deprecated`, or with a `stale_after` date in the past, as unreliable: anything you take from them becomes an assumption. Skip this when no `docPath` was given.
- **Project instructions:** `CLAUDE.md` and `AGENTS.md` files at the root and in the areas the spec touches.

The brief holds the paths of spec.md and input.md, the confirmed answers and review notes from an earlier design.md, and what you learned above that matters for this spec, with the paths it came from.

## 3. Run the design agents

An entry applies unless its context limits it to something this slice doesn't touch. Start every `fork` entry that applies at once, in parallel, with your tool for starting subagents (Agent), using this prompt:

````text
You are a design agent for one feature slice.
{the entry's context, or, when it is empty: Design the whole change.}

Read the spec and the request: {paths}
What is already known:
{the brief}

Explore the code your role covers: the files involved, the current behavior, the
patterns to follow, and the tests that cover it. Follow the existing patterns. When
docs and code disagree, the code is right. Check external libraries and APIs against
their documentation, not from memory. Never change any file, and never ask the user
anything.

Answer with these sections, leaving out any that would be empty:
Findings: the files involved, with paths; current behavior; patterns; tests
Approach: how your part works
Decisions: each choice, why, and the alternatives with why each lost
Contracts: the exact shapes your part provides or needs
Risks: each risk, with its mitigation
Questions: each question, its options, your recommended answer and why, and what it affects
````

Take the role of each `inline` entry yourself, answering in the same sections. If a design agent fails, or answers without these sections, start it once more. If it fails again, cover its part yourself, and say so in the result.

## 4. Merge

Merge the answers into one design:

1. **One approach.** The parts must work together to meet every requirement and acceptance criterion in the spec.
2. **Conflicts.** When proposals disagree, choose one with a reason, and record the other as an alternative of that decision. When the choice depends on what the person wants, make it an open question.
3. **Contracts.** Define each shared shape once. What one part provides must match exactly what another part needs.
4. **Unknowns.** Settle each one, in this order:
   1. Answer it from the code or docs.
   2. Otherwise choose a default with a reason, apply it, and list it under Assumptions.
   3. Otherwise make it an open question. Choose a recommended answer, apply it in the design, and name what depends on it. A question blocks when a different answer would change the approach or the tasks. A question that can be answered later without changing either doesn't block.
5. **Scope.** Prefer the simplest approach that meets the requirements and fits the existing patterns. Add nothing the spec doesn't ask for.
6. **Risks.** Always cover changes that are destructive or hard to reverse (data, schemas, infrastructure, public contracts), and security and performance concerns.

Fill in this template, following any design rules in the context:

```markdown
---
slice: {id from input.md; leave this line out when it has none}
---

# Design: {feature name}

## Context

{The current state and the constraints the approach depends on. Point to spec.md for the goal and the requirements instead of repeating them.}

## Approach

{How the solution works, in a few paragraphs: which parts change and how they work together.}

## Affected areas

| Area | Files or modules | Change |
|---|---|---|
| {area} | {paths} | {what changes there} |

## Decisions

### D1 {the decision}

- **Choice:** {what was chosen}
- **Why:** {the reason}
- **Alternatives:** {alternative}: {why it lost}

## Contracts

{The exact shapes that several parts depend on: signatures, data structures, endpoints, events, error cases.}

## Data and migration

{Changes to stored data or schemas, how existing data is migrated, and how to roll back.}

## Risks

- {risk} → {mitigation}

## Assumptions

- {assumption}: {why it holds: a default you chose, or taken from an unverified or stale doc page}

## Open questions

- **Q1** {question} {why it matters}
  - Options: A) {option} B) {option}
  - Recommended: {option}, because {reason}. This design applies it.
  - Affects: {D2, Contracts; or "nothing in the design"}. Blocks: {yes | no}

## Requirements coverage

| Requirement | Covered by |
|---|---|
| R1 | {decisions, contracts or areas that deliver it} |
```

Always keep Context, Approach, Affected areas and Requirements coverage. Leave out any other section that would be empty, and put the blocking questions first. Every requirement and acceptance criterion in the spec appears in Requirements coverage.

Then check your draft and fix it in place:

- a requirement or acceptance criterion that nothing covers
- work the spec doesn't ask for, or anything that contradicts the spec
- a decision without a reason or without alternatives
- a contract that two parts could read differently
- a destructive or hard-to-reverse change without a mitigation
- placeholders, TODOs or sections that contradict each other

## 5. Review

This step is required unless `reviewAgents` is an empty list, and checking the draft yourself doesn't replace it. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent). Give each the prompt below, with the full spec and the full draft where it says `{SPEC}` and `{DESIGN}`. Take the role of each `inline` entry yourself. The prompt carries only what this stage relies on: the documents and the answer form. What to review comes from each entry's context, or from its skill.

````text
You are reviewing a technical design before a person approves it and it is broken
into tasks. You haven't seen how it was produced, and that is the point: judge only
what is written, against the spec.
{for an entry with a skill: Invoke the {skill} skill, and review with it.}

{the entry's context; when it is empty: Review the design for anything that would
lead the plan or the implementation wrong.}

Spec:

{SPEC}

Design:

{DESIGN}

An issue is something that would lead the plan or the implementation wrong.
Wording, style and uneven detail are not issues; what would only improve the design
is a recommendation. Approve unless something serious is missing.

Answer in this form:
Status: Approved | Issues found
Issues:
- [section] the issue, and why it would mislead the plan or the implementation
Recommendations (optional, they don't block approval):
- ...
````

Then handle what the reviewers report:

- **Issues:** check each one against the spec, the code and the draft. When it holds, fix the draft. When it doesn't, leave the draft as it is and note why. Never apply an issue without checking it, and never drop one without a reason.
- **Recommendations:** apply those that clearly improve the design without widening it. Add the rest to Open questions, so the person can judge them.
- **Contradictions:** when reviewers disagree, decide with a reason, or make it an open question.
- **Failures:** if a review agent fails, or answers without the form, start it once more. If it fails again, its review didn't run.

Only when you have no tool for starting subagents, review the draft yourself, following each entry's instructions, and record that the reviews didn't run.

## 6. Save and return

Write `<activeSlicePath>/design.md` with the Write tool, replacing the earlier version. Leave out review notes you have applied. If the write fails, return `WRITE_FAILED`.

Then append the review record to `<activeSlicePath>/design-reviews.md`, creating it with the heading `# Design reviews` when it is missing. Run `date -u +%Y-%m-%dT%H:%M:%SZ` as a command on its own for the time, then write the file with the Write or Edit tool, not a shell command:

```markdown
## design, {time}

### {the reviewer's name, or else "Reviewer <n>" with its skill or agent}

- Status: {Approved | Issues found | Did not run: <why>}
- Issue [{section}]: {the issue} → {fixed: how | rejected: why}
- Recommendation: {the recommendation} → {applied | Q<n>}
```

When the review was skipped because `reviewAgents` is an empty list, write `Review skipped: no review agents configured` under the heading instead.

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the design is saved, with the number of decisions and of open questions, how many block, and any design agent you had to cover yourself>
files: <activeSlicePath>/design.md, <activeSlicePath>/design-reviews.md
```

On failure, end with this instead:

```text
result: error
code: <NO_SPEC | SPEC_NOT_READY | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
