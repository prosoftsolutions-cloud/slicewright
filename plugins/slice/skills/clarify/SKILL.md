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
- `knowledge`: the project's documentation, which may be missing: `sources`, each with a `name`, a `path` when it is a folder in the project or a `skill` that reaches it, and a `context` saying what is there and how to read it; and `publishTo`, the name of the source the slice's documentation changes go to
- `context`: the project's rules for this stage, which may be missing
- `reviewAgents`: the agents that review the draft. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you review yourself, following its context
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: its review instructions: what to look for; empty means a general review
  - `name`: a label for the record, which may be missing

Ignore any other key. The context is rules and pointers for you to follow. Never copy it into the spec or any other file.

The project's documentation: read each source in `knowledge.sources` as its `context` describes, and only the parts your work needs. When a source can't be reached, say so in your result, treat what you needed from it as an assumption, and go on. Pages this slice has already changed in the source that `knowledge.publishTo` names are staged in `<activeSlicePath>/docs/`, at their paths in that source: read a staged page instead of the published one, and a `<path>.delete` file there means that page is being removed. Every prompt you give an agent carries this line after its instructions, unless `knowledge` is missing: `The project's documentation: {each source: its name, its path or its skill, and its context} Pages this slice has changed are staged in {activeSlicePath}/docs/ at the same paths: read those instead of the published ones.`

Never ask the user anything, even when running in the main conversation. What you can't settle becomes an open question in the spec, and a later stage takes it to a person.

## 1. Read the request

Read `<activeSlicePath>/input.md`; it holds the request. If it doesn't exist, return an error with code `NO_INPUT`.

## 2. Gather context

Find everything you can before you decide that something is a question for a person.

- **Sources the context names:** read every one.
- **The project's documentation:** start where each source's `context` says, then read only the pages related to the request. Treat pages the documentation marks as deprecated or out of date as unreliable: anything you take from them becomes an assumption. If the documentation isn't there, say so in the result and continue; never create it. Skip this when no `knowledge` was given.
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

This step is required unless `reviewAgents` is an empty list, and checking the draft yourself doesn't replace it. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent). Give each the prompt below, with the full draft where it says `{SPEC}`. Take the role of each `inline` entry yourself. The prompt carries only what this stage relies on: the draft and the answer form. What to review comes from each entry's context, or from its skill.

````text
You are reviewing a feature spec before a person approves it for design. You
haven't seen how it was produced, and that is the point: judge only what is written.
{for an entry with a skill: Invoke the {skill} skill, and review with it.}

{the entry's context; when it is empty: Review the spec for anything that would
lead the design wrong.}

Spec:

{SPEC}

An issue is something that would lead the design wrong. Wording, style and uneven
detail are not issues; what would only improve the spec is a recommendation.
Approve unless something serious is missing.

Answer in this form:
Status: Approved | Issues found
Issues:
- [section] the issue, and why it would mislead the design
Recommendations (optional, they don't block approval):
- ...
````

The default reviewer's checklist, in the plugin's `defaults.json`, is adapted from the spec reviewer in Superpowers (MIT).

Then handle what the reviewers report:

- **Issues:** check each one against the request, the code and the draft. When it holds, fix the draft. When it doesn't, leave the draft as it is and note why. Never apply an issue without checking it, and never drop one without a reason.
- **Recommendations:** apply those that clearly improve the spec without widening it. Add the rest to Open questions, so the person can judge them.
- **Contradictions:** when reviewers disagree, decide with a reason, or make it an open question.
- **Failures:** if a review agent fails, or answers without the form, start it once more. If it fails again, its review didn't run.

Only when you have no tool for starting subagents, review the draft yourself, following each entry's instructions, and record that the reviews didn't run.

## 6. Save and return

Write `<activeSlicePath>/spec.md` with the Write tool, replacing a draft from an earlier run. If the write fails, return `WRITE_FAILED`.

Then append the review record to `<activeSlicePath>/design-reviews.md`, creating it with the heading `# Design reviews` when it is missing. Run `date -u +%Y-%m-%dT%H:%M:%SZ` as a command on its own for the time, then write the file with the Write or Edit tool, not a shell command:

```markdown
## clarify, {time}

### {the reviewer's name, or else "Reviewer <n>" with its skill or agent}

- Status: {Approved | Issues found | Did not run: <why>}
- Issue [{section}]: {the issue} → {fixed: how | rejected: why}
- Recommendation: {the recommendation} → {applied | Q<n>}
```

When the review was skipped because `reviewAgents` is an empty list, write `Review skipped: no review agents configured` under the heading instead.

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the draft is saved, with the number of open questions and how many block design>
files: <activeSlicePath>/spec.md, <activeSlicePath>/design-reviews.md
```

On failure, end with this instead:

```text
result: error
code: <NO_INPUT | INPUT_UNCLEAR | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
