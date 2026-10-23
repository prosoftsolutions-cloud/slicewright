---
name: clarify
description: Internal Slicewright clarify stage. Turns the slice's input.md into a draft spec.md, with its open questions and recommended answers, for a person to review. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Clarify

Turn the request into a draft spec that a person can review and the design stage can use. This stage settles what to build, not how: leave approaches and architecture to design unless a choice changes the requirements. Never write code here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `docPath`: the project's knowledge folder, which may be missing
- `context`: the project's rules for this stage, which may be missing

Ignore any other key. The context is rules and pointers for you to follow. Never copy it into the spec or any other file.

Never ask the user anything, even when running in the main conversation. What you can't settle becomes an open question in the spec, and a later stage takes it to a person.

## 1. Read the request

Read `<activeSlicePath>/input.md`; it holds the request. If it doesn't exist, return an error with code `NO_INPUT`.

## 2. Gather context

Find everything you can before you decide that something is a question for a person.

- **Sources the context names:** read every one.
- **Knowledge in `docPath`:** if the folder exists, read its `index.md` first, then follow links to the concepts related to the request, and read only those. Prefer pages that carry `verified`. Treat pages with `status: deprecated`, or with a `stale_after` date in the past, as unreliable: anything you take from them becomes an assumption. If the folder doesn't exist, say so in the result and continue. Never create it. Skip this when no `docPath` was given.
- **Project instructions:** `CLAUDE.md` and `AGENTS.md` files at the root and in the areas the request touches.
- **Code:** the modules, tests and configuration the request touches, and the patterns they follow.
- **Anything the request refers to.**

## 3. Analyze

1. **Size.** If the request holds several independent pieces, split it into slices, in order, with a one-line goal for each. This slice takes the first piece, and the rest become the spec's follow-up slices. Add an open question asking the person to confirm the split.
2. **Goal, scope and constraints.** Scope means the areas and paths that will change, and what stays out.
3. **Unknowns.** Settle each one, in this order:
   1. Answer it from the code or docs.
   2. Otherwise choose a default with a reason, apply it, and list it under Assumptions.
   3. Otherwise make it an open question. Only intent, priorities and business rules become questions. Choose a recommended answer, apply it in the draft, and name the requirements that depend on it.

   The draft reads as if every recommended answer were accepted, so the person reviews a concrete proposal.
4. If the request can't be understood well enough to draft anything, return an error with code `INPUT_UNCLEAR`, saying what is missing. A request that is already done, or that contradicts the code, is not unclear: draft the spec and make that the first open question.

## 4. Draft the spec

Fill in this template, following any spec rules in the context:

```markdown
---
slice: {id from input.md; leave this line out when it has none}
source: {ticket key or URL; leave this line out for free text}
---

# {Feature name}

## Goal

{One paragraph: what changes, for whom, and why it matters.}

## Scope

**Changes:** {the areas, modules or paths this slice will change}

**Out of scope:** {what this slice deliberately leaves alone}

## Requirements

- **R1** {a concrete behavior the design can plan without further questions}

## Acceptance criteria

- **AC1** (R1) Given {starting state}, when {action}, then {observable result}

## Constraints

- {technical or business constraints, and non-goals}

## Assumptions

- {assumption}: {why it holds: a default you chose, or taken from an unverified or stale doc page}

## Open questions

- **Q1** {question} {why it matters}
  - Options: A) {option} B) {option}
  - Recommended: {option}, because {reason}. This draft applies it.
  - Affects: {R2, AC3; or "nothing in the draft"}. Blocks design: {yes | no}

## Follow-up slices

- {one line for each later slice, when the request was split}
```

Number the requirements R1, R2 and so on. Give every requirement at least one acceptance criterion (AC1, AC2…) in Given/When/Then form that a test or a reviewer can check. Replace vague words like "fast" or "easy" with what actually happens. Put the questions that block design first. Leave out the Open questions and Follow-up slices sections when they would be empty, and the header between the `---` lines when it has no lines left.

Then check your draft and fix it in place:

- placeholders, TODOs or empty sections
- sections that contradict each other
- anything that could be read two ways
- work larger than one slice, or a declared scope that doesn't cover the requirements
- features nobody asked for

## 5. Review

This step is required, and checking the draft yourself doesn't replace it. Use your tool for starting subagents (Agent) to start a general-purpose subagent with the prompt below, putting the full draft where it says `{SPEC}`. Fix the issues it reports. Add each recommendation you don't apply to Open questions, so the person can judge it. Only when you have no tool for starting subagents, check the draft against the same list yourself, and say in the result that the fresh review didn't run.

````text
You are reviewing a feature spec before a person approves it for design. You
haven't seen how it was produced, and that is the point: judge only what is written.

Spec:

{SPEC}

Check:
- Completeness: placeholders, TODO, TBD, empty sections, a requirement without
  an acceptance criterion
- Consistency: sections that contradict each other; a declared scope that doesn't
  cover the requirements, or requirements outside it
- Clarity: a requirement or criterion that could be built two different ways
- Testability: an acceptance criterion that no test or reviewer could check
- Size: more than one slice of work, meaning independent pieces that should be split
- Extras: features or options the goal doesn't need
- Open questions: a question with no recommended answer, or a decision hidden in
  the requirements that should be an open question

Flag only what would lead the design wrong. Wording, style and uneven detail are
not issues. Approve unless something serious is missing.

Answer in this form:
Status: Approved | Issues found
Issues:
- [section] the issue, and why it would mislead the design
Recommendations (optional, they don't block approval):
- ...
````

The reviewer prompt is adapted from the spec reviewer in Superpowers (MIT).

## 6. Save and return

Write `<activeSlicePath>/spec.md` with the Write tool, replacing a draft from an earlier run. If the write fails, return `WRITE_FAILED`.

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the draft is saved, with the number of open questions and how many block design>
files: <activeSlicePath>/spec.md
```

On failure, end with this instead:

```text
result: error
code: <NO_INPUT | INPUT_UNCLEAR | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
