---
name: research
description: Internal Slicewright research stage. Coordinates research agents and review agents to answer the research questions in spec.md from sources, with cited evidence and a confidence, and writes research.md with the answers, conclusions, options, a recommendation and follow-ups, for a person to decide on. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Research

Answer the questions spec.md asks, from sources, with evidence, and write it down so that a person can decide. You coordinate: research agents answer from their angle, you merge their findings into one document, review agents check it, and you handle what they find. Never write code here, and never change the project's documentation.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `knowledge`: the project's documentation, which may be missing: `sources`, each with a `name`, a `path` when it is a folder in the project or a `skill` that reaches it, and a `context` saying what is there and how to read it; and `publishTo`, the name of the source the slice's documentation changes go to
- `context`: the project's rules for this stage, which may be missing, such as the sources of its own knowledge beyond the documentation, the order of trust between kinds of sources, how to cite, and what counts as evidence
- `researchAgents`: the agents that answer the questions. Each entry is one angle or one kind of source, and its `context` says which. When missing, you research everything yourself.
- `reviewAgents`: the agents that review the merged draft. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. A reviewer's `context` is its review instructions: what to look for; empty means a general review.

Each agent entry has:

- `executionMode`: `fork` runs it as a subagent; `inline` means you take that role yourself, following its context
- `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
- `context`: its role and when it applies; empty means the general role
- `name`: a label for the record, which may be missing

Ignore any other key. The context is rules for you to follow. Never copy it into a file.

The project's documentation: read each source in `knowledge.sources` as its `context` describes, and only the parts your work needs. When a source can't be reached, say so in your result, treat what you needed from it as an assumption, and go on. Pages this slice has already changed in the source that `knowledge.publishTo` names are staged in `<activeSlicePath>/docs/`, at their paths in that source: read a staged page instead of the published one, and a `<path>.delete` file there means that page is being removed. Every prompt you give an agent carries this line after its instructions, unless `knowledge` is missing: `The project's documentation: {each source: its name, its path or its skill, and its context} Pages this slice has changed are staged in {activeSlicePath}/docs/ at the same paths: read those instead of the published ones.`

Never ask the user anything. What you can't settle becomes an open question in research.md, and a later stage takes it to a person. Never change any file but `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md`.

## 1. Read the slice

- `<activeSlicePath>/spec.md`: the questions to answer. The questions are its requirements, `R<n>`; the scope names the sources in and out; each acceptance criterion says what a good answer to its question contains; the constraints hold the rules of evidence for this topic. If it doesn't exist, return `NO_SPEC`. If it still has an open question with `Blocks design: yes`, return `SPEC_NOT_READY`, naming the question. Return either before anything is written, so the error's `files` is `none`.
- `<activeSlicePath>/input.md`: the request, and the decisions recorded with it.
- `<activeSlicePath>/research.md`, when it exists from an earlier run: a person may have decided, settled questions and left review notes in it. Match questions and follow-ups by their text, not their number. Keep `## Decisions` as it is, and treat each line as settled: never ask it again, and never make it an open question. Keep every filled `Decision:` line as it is, the recommendation's and each follow-up's. Keep the answer, evidence and disagreements of each question whose text the current spec still asks, unless a note under Review notes names it. Rework what each note asks, then remove the note. Drop the questions the spec no longer asks. Research the new questions and the ones the notes name. When this run recommends a different option and the recommendation's `Decision:` line is filled, say so in the Recommendation text right above that line, and leave the line as it is.

## 2. Prepare the brief

Gather what every research agent needs, once, so they don't each repeat it:

- **The project's documentation:** start where each source's `context` says, then read only the pages that bear on the questions. Read a page staged in `<activeSlicePath>/docs/` instead of the published one. Treat pages the documentation marks as deprecated or out of date as unreliable: anything you take from them becomes an assumption. Skip this when no `knowledge` was given.
- **The sources the context names,** such as the code or the records of earlier slices: read each where it bears on the questions.
- **The rules of evidence and citation:** from the context and from the spec's Constraints, as one list, with the sources the spec's scope rules out.

The brief holds the paths of spec.md and input.md; the questions this run researches, which are every requirement, or on a later run the new ones and the ones a review note names, with the note's text; what the project's own knowledge says on each question, each fact with the path it came from; and the rules.

## 3. Run the research agents

Start every `fork` entry at once, in parallel, with your tool for starting subagents (Agent), using this prompt:

````text
You are a research agent for one research slice.
{for an entry with a skill: Invoke the {skill} skill, and research with it.}
{the entry's context, or, when it is empty: Research every question, from any source the rules allow.}

Read the questions and the request: {paths of spec.md and input.md}. The questions
are the spec's requirements, and each acceptance criterion says what a good answer
to its question contains.
What is already known:
{the brief}

Answer each question the brief lists, from your angle and from the sources the rules
allow. Read every source yourself, and cite it as the rules say. Confidence is one of:
- low: inferred, or from a secondary source, or disputed
- medium: stated by one source you read
- high: stated by two independent sources, or by the primary source for the matter
- sure: shown by the project's own code or documentation, or checked by you yourself
Never change any file, and never ask the user anything.

Answer in this form, one block per question, in the spec's order:
R<n>:
- Claim: {one fact}. Source: {cited as the rules say}. Confidence: {low | medium | high | sure}
Disagreements: {each place your sources differ, with what each says; or none}
For a question your angle doesn't answer, write instead:
R<n>: nothing found: {why}
End with:
Sources not reached: {each source you couldn't open; or none}
````

The documentation line from section 0 follows the prompt, unless `knowledge` is missing. Take the role of each `inline` entry yourself, answering in the same form. Without `researchAgents`, answer every question yourself in the same form. If a research agent fails, or answers without the form, start it once more. If it fails again, cover its angle yourself, and say so in the result.

## 4. Merge

Merge the findings into one research document:

1. **Evidence.** Every claim with a source is evidence. A claim without a source is not evidence: don't write it.
2. **One answer per question.** Give each question one answer, with its confidence: the lowest confidence of the evidence the answer depends on; `high` when two independent sources state the same; `sure` for what the brief found in the project's own code or documentation. A question nothing answers gets "not answered: {why}".
3. **Disagreements.** Where findings disagree, say which one the answer follows and why, by the context's order of trust between kinds of sources. When the context gives none, give a reason of your own.
4. **Conclusions.** What the answers mean together for the goal in spec.md.
5. **Options.** One per course of action the conclusions allow, each with what speaks for it and what speaks against it.
6. **Recommendation.** One option and why, ending with an empty `Decision:` line for the person.
7. **Unknowns.** Settle each one, in this order:
   1. Answer it from the sources.
   2. Otherwise choose a default with a reason, apply it, and list it under Assumptions.
   3. Otherwise make it an open question. Choose a recommended answer, apply it in the draft, and name what depends on it.

   A line under Decisions settles its question: never ask it again.
8. **Follow-ups.** Later work the research shows, each with an empty `Decision:` line, unless kept from an earlier run.
9. **Scope.** Answer what the spec asks, and add nothing.

Fill in this template:

```markdown
---
slice: {id from input.md; leave this line out when it has none}
---

# Research: {the slice's title, as input.md gives it}

## Questions

### R1 {the question, as the spec states it}

- **Answer** ({low | medium | high | sure}): {the answer; or "not answered: {why}"}
- **Evidence:**
  - {the claim}. Source: {cited as the rules say}. Confidence: {low | medium | high | sure}
- **Disagreements:** {which sources differ on what, which one the answer follows and why; or "none"}

## Conclusions

{what the answers mean together}

## Options

### O1 {the option}

- **For:** {...}
- **Against:** {...}

## Recommendation

{the option, and why}

Decision:

## Decisions

- {the question}: {the answer}

## Assumptions

- {assumption}: {why it holds, such as a source that couldn't be reached}

## Open questions

- **Q1** {question} {why it matters}
  - Options: A) {option} B) {option}
  - Recommended: {option}, because {reason}. This draft applies it.
  - Affects: {R2, O1; or "nothing in the draft"}

## Follow-ups

- **F1** {title}: {what, and why it matters}
  Decision:

## Review notes

- {the question or section}: {the person's request}
```

Always keep Questions, Conclusions and Recommendation. Leave out the `slice:` line when input.md has no id, and any other section that would be empty. Decisions appears only as kept from an earlier run: never write it yourself. Review notes appears only with the notes you haven't applied.

Then check your draft and fix it in place:

- a requirement of the spec without its `### R<n>`
- an evidence line without `Source:` or without one of the four confidence words
- a source the spec rules out
- a confidence the evidence doesn't justify
- an option without for and against
- a recommendation that isn't one of the options
- a changed line under Decisions, or a changed filled `Decision:` line
- an applied review note left in place
- placeholders, TODOs or sections that contradict each other

## 5. Review

This step is required unless `reviewAgents` is an empty list, and checking the draft yourself doesn't replace it. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent). Give each the prompt below, with the full spec and the full draft where it says `{SPEC}` and `{RESEARCH}`. Take the role of each `inline` entry yourself. The prompt carries only what this stage relies on: the documents and the answer form. What to review comes from each entry's context, or from its skill.

````text
You are reviewing a research document before a person decides on it. You haven't
seen how it was produced, and that is the point: judge only what is written, against
the spec and the sources it cites.
{for an entry with a skill: Invoke the {skill} skill, and review with it.}

{the entry's context; when it is empty: Review the research for anything that would
lead the person's decision wrong.}

Spec:

{SPEC}

Research:

{RESEARCH}

An issue is something that would lead the decision wrong: an answer the evidence
doesn't support, a source that doesn't say what is claimed, or a recommendation the
conclusions don't give. Wording, style and uneven detail are not issues; what would
only improve the document is a recommendation. Approve unless something serious is wrong.

Answer in this form:
Status: Approved | Issues found
Issues:
- [section] the issue, and why it would mislead the decision
Recommendations (optional, they don't block approval):
- ...
````

Then handle what the reviewers report:

- **Issues:** check each one against the spec, the sources and the draft. When it holds, fix the draft. When it doesn't, leave the draft as it is and note why. Never apply an issue without checking it, and never drop one without a reason.
- **Recommendations:** apply those that clearly improve the research without widening it. Add the rest to Open questions, so the person can judge them.
- **Contradictions:** when reviewers disagree, decide with a reason, or make it an open question.
- **Failures:** if a review agent fails, or answers without the form, start it once more. If it fails again, its review didn't run.

Only when you have no tool for starting subagents, review the draft yourself, following each entry's instructions, and record that the reviews didn't run.

## 6. Save and return

Write `<activeSlicePath>/research.md` with the Write tool, replacing the earlier version. Leave out the review notes you have applied, and the Review notes section when it is empty. If the write fails, return `WRITE_FAILED`.

Then append the review record to `<activeSlicePath>/design-reviews.md`, creating it with the heading `# Design reviews` when it is missing. Run `date -u +%Y-%m-%dT%H:%M:%SZ` as a command on its own for the time, then write the file with the Write or Edit tool, not a shell command:

```markdown
## research, {time}

### {the reviewer's name, or else "Reviewer <n>" with its skill or agent}

- Status: {Approved | Issues found | Did not run: <why>}
- Issue [{section}]: {the issue} → {fixed: how | rejected: why}
- Recommendation: {the recommendation} → {applied | Q<n>}
```

When the review was skipped because `reviewAgents` is an empty list, write `Review skipped: no review agents configured` under the heading instead.

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: research.md is saved, with the number of questions answered of those asked, the number of open questions and of follow-ups, and any research agent you had to cover yourself>
files: <activeSlicePath>/research.md, <activeSlicePath>/design-reviews.md
```

On failure, end with this instead:

```text
result: error
code: <NO_SPEC | SPEC_NOT_READY | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```

A later stage takes research.md to a person, who writes into it, and this stage keeps what they wrote: `Decision: {the decision in the person's words}` or `Decision: none: {why}` under Recommendation; `Decision: file` or `Decision: no issue` on a follow-up's line; `- {question}: {answer}` under Decisions; `- {question or section}: {request}` under Review notes.
