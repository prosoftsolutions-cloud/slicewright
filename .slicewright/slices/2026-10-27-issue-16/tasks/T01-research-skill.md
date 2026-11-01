---
id: T01
title: Research skill
type: plugin
depends: []
covers: [R1, R2, R3, R4, R5, R6, R7, AC1, AC2, AC3, AC4, AC5, AC6, AC7]
---

# T01 Research skill

## Goal

Add the new internal stage skill `plugins/slice/skills/research/SKILL.md`, modelled section by section on `plugins/slice/skills/design/SKILL.md`: it answers the questions in `spec.md` from sources with cited evidence and a confidence, merges the findings into `research.md`, has review agents check it, and records the review in `design-reviews.md`.

## Context

### Requirements

- **R1** A new internal skill, `plugins/slice/skills/research/SKILL.md`, with `name: research`, a description and `user-invocable: false`. Its arguments are a JSON object, and it uses only `activeSlicePath`, `knowledge`, `context`, `researchAgents` and `reviewAgents`, ignoring any other key. `researchAgents` and `reviewAgents` are lists whose entries have the agent format of every other stage: `executionMode` (`fork` or `inline`), `skill` or `agent` (`general-purpose` when neither is given), `context` and an optional `name`. Each `researchAgents` entry is one angle or one kind of source, and its `context` says which. When `researchAgents` is missing, the stage researches everything itself. When `reviewAgents` is missing, it uses one general-purpose reviewer; when it is an empty list, it skips the review. The stage never asks the person anything, never writes code, and changes no file but `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md`. It follows the skill conventions in `AGENTS.md`: one command per call, no `cd`, files written with the Write or Edit tool, no version control named in the skill text, plain English.
- **R2** The stage reads `<activeSlicePath>/spec.md`, which holds the research questions as its requirements, the scope with the sources in and out, and under each acceptance criterion what a good answer to its question contains. Without `spec.md` it returns `NO_SPEC`. When `spec.md` still has an open question marked as blocking design, it returns `SPEC_NOT_READY`, naming the question. It also reads `<activeSlicePath>/input.md`, and `<activeSlicePath>/research.md` when one exists from an earlier run (R5).
- **R3** Before the agents start, the stage gathers the project's own knowledge once, into a brief: the project's documentation as `knowledge` describes it, read only where it bears on the questions, with staged pages in `<activeSlicePath>/docs/` read instead of published ones; the sources the stage's `context` names, such as the code or the records of earlier slices; and the rules of evidence and citation from the stage's `context` and from the spec's Constraints. Then it starts every `fork` research agent at once, in parallel, with one prompt that carries the entry's context, the paths of `spec.md` and `input.md`, the brief, and the answer form; it plays each `inline` entry itself. An agent answers with findings per question: for each question of the spec, each finding as the claim, its source cited as the rules say, and its confidence; where its sources disagree, the disagreement; and "nothing found" for a question its angle doesn't answer. Confidence is one of `low`, `medium`, `high` or `sure`, defined in the skill: `low` is inferred, or from a secondary source, or disputed; `medium` is stated by one source the agent read; `high` is stated by two independent sources, or by the primary source for the matter; `sure` is shown by the project's own code or documentation, or checked by the agent itself. An agent never changes a file and never asks the person anything. An agent that fails, or answers without the form, is started once more; when it fails again, the stage covers its angle itself and says so in the result.
- **R4** The stage merges the findings into `<activeSlicePath>/research.md`, in this order, leaving out the header line `slice:` when `input.md` has no id, and the sections that would be empty, except Questions, Conclusions and Recommendation:
  1. a header with `slice: <id>`, then the title `# Research: <the slice's title, as input.md gives it>`
  2. `## Questions`: one `### R<n> <question>` per requirement of the spec, in the spec's order, with **Answer** (the answer, or "not answered" with why), **Evidence** (each claim with its source and its confidence; a claim without a source is not evidence and isn't written), and **Disagreements** (where sources differ, which one the answer follows and why; or "none")
  3. `## Conclusions`: what the answers mean together
  4. `## Options`: one `### O<n> <option>` per course of action the conclusions allow, each with its trade-offs, for and against
  5. `## Recommendation`: one option and why, ending with the line `Decision:` left empty for the person
  6. `## Decisions`: the answers a person gave to open questions at a review, one line each, `- <the question>: <the answer>`. The stage never writes this section itself: it keeps it as it is, and treats each line as settled.
  7. `## Assumptions`: each assumption with why it holds, such as a source that couldn't be reached
  8. `## Open questions`: each `Q<n>` with why it matters, lettered options, the recommended answer the draft applies, and what it affects, as in `spec.md` and `design.md`
  9. `## Follow-ups`: one `- **F<n>** <what, and why it matters>` per piece of later work, each ending with `Decision:` left empty for the person
  10. `## Review notes`: only when a person left notes (R5); the stage removes the notes it has applied
- **R5** On a later run, the stage keeps what a person wrote in the earlier `research.md`: the lines under Decisions count as settled and are never asked again, filled `Decision:` lines stay as they are, and each note under Review notes is reworked and then removed. Answers to questions that the current `spec.md` still asks are kept unless a note asks to redo them; questions the spec no longer asks are dropped, and new questions are researched.
- **R6** The review runs the way it does in the clarify and design stages: every `fork` review agent starts at once, with a prompt that carries only the full spec, the full draft and the answer form (`Status: Approved | Issues found`, `Issues`, `Recommendations`); the stage plays each `inline` entry itself. Each issue is checked against the spec, the sources and the draft, then fixed or rejected with a reason; a recommendation that clearly improves the draft without widening it is applied, and the rest become open questions; contradicting reviewers are decided with a reason or become an open question; a reviewer that fails or answers without the form is started once more, and then counts as not run. Only when the stage has no tool for starting subagents does it review the draft itself and record that the reviews didn't run.
- **R7** The stage writes `research.md` with the Write tool, replacing the earlier version, and returns `WRITE_FAILED` when that fails. It appends the review record to `<activeSlicePath>/design-reviews.md`, creating it with the heading `# Design reviews` when missing, under `## research, <time>`, in the form clarify and design use. Its result block follows `skills/run/SKILL.md`, section 4.3: on success `result: ok`, a one-sentence message with the number of questions answered, the open questions, the follow-ups and any angle the stage had to cover itself, and `files` naming both files; on failure `result: error` with `code` one of `NO_SPEC`, `SPEC_NOT_READY`, `WRITE_FAILED`, a message, a fix and the files it changed.

### Acceptance criteria

- **AC1** (R1) Given the working copy at the end of this slice, when `sh tests/static.sh` runs from the repo root, then it exits 0, and its `skills` check has accepted `plugins/slice/skills/research/SKILL.md` with `name: research`, a non-empty description and `user-invocable: false`.
- **AC2** (R2) Given a slice folder without `spec.md`, when the research stage runs, then it ends with `result: error`, `code: NO_SPEC`, and `files: none`. Given a `spec.md` whose open question Q1 says `Blocks design: yes`, when the stage runs, then it ends with `code: SPEC_NOT_READY` and a message naming Q1, and writes no `research.md`.
- **AC3** (R3) Given the skill text, when a reviewer reads it, then the brief holds the three parts R3 lists (the documentation, the sources the context names, and the rules of evidence and citation), the agent prompt carries the entry's context, the two paths, the brief and the answer form, the answer form has the claim, the source, the confidence and the disagreements per question, the four confidence levels are defined as in R3, and a failed agent is retried once and then covered by the stage with a note in the result. Given the hand run of AC11, when its research stage's transcript is read, then every `fork` entry of `researchAgents` was started at once, and each was started at most twice.
- **AC4** (R4) Given a `research.md` the stage wrote, when a reviewer reads it, then its sections are in R4's order, every requirement of `spec.md` has its `### R<n>` with an Answer, an Evidence list where each line has a source and one of the four confidence words, and a Disagreements line; the Recommendation ends with an empty `Decision:` line; every follow-up ends with an empty `Decision:` line; there is no Decisions section unless the earlier version had one; and no Review notes section remains from notes the stage applied.
- **AC5** (R5) Given an earlier `research.md` with one line under Decisions, the recommendation's `Decision:` filled, one follow-up `Decision: file`, and one note under Review notes asking to look at another source for R2, when the stage runs again, then the Decisions line and both Decision lines are unchanged, no open question asks what the Decisions line answers, R2's evidence has changed, and the Review notes section is gone.
- **AC6** (R6) Given one `fork` review agent, when the stage runs, then the agent's prompt holds the full `spec.md`, the full draft and the answer form and nothing else about how the draft was made, and `design-reviews.md` records each issue as fixed with how or rejected with why. Given `reviewAgents: []`, when the stage runs, then the record says `Review skipped: no review agents configured` and no reviewer starts.
- **AC7** (R7) Given a successful run, when it ends, then `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md` exist, the latter with a `## research, <time>` entry whose time came from `date -u +%Y-%m-%dT%H:%M:%SZ`, and the reply ends with `result: ok`, a message that gives the number of questions answered, of open questions and of follow-ups, and `files` naming both files.

### Constraints

- The skill holds the protocol and the template; the sources, the rules of evidence, the citation form, what is published and whether issues are filed stay in the stage's `context` (in `.slicewright/research.json`, which another task writes). No new top-level configuration key: the research stage's settings are its params, and only the five R1 names.
- `AGENTS.md`'s design rules and skill conventions: no hardcoded examples, limits or choices in the skill; never name a version control in the skill text; one command per call, never chained, never `cd`; files written with the Write or Edit tool; plain English, short sentences. The only command in the skill is the `date` line.
- The research stage never changes the project's documentation: the research page and the decision record are consolidate's work, from `research.md` and `deployments.md`.
- `plugins/slice/defaults.json` doesn't change: the research stage isn't in the default pipeline. Nothing under `.slicewright/stable/` changes.

### Design decisions

- **D1 The research skill mirrors the design skill section by section.** Sections 0 to 6 with the same names, the same agent entry format, the same documentation line, the same retry rule, the same review prompt shape and the same `design-reviews.md` record. Only the brief, the agent prompt and answer form, the merge rules, the template and the rerun rules differ. A skill must be complete on its own, because the runner's subagent reads only it: never refer to the design skill's text.
- **D2 The confidence scale is defined once, in the agent prompt, and the merge applies it.** The four levels and their definitions are in the research agent's prompt block in section 3, which is also the form the stage uses when it researches itself. Section 4 gives the answer its confidence: the lowest confidence of the evidence the answer depends on; `high` when two independent sources state the same, as the scale says; `sure` for what the brief found in the project's own code or documentation.
- **D3 Evidence lines carry the labels `Source:` and `Confidence:`.** Each evidence line is `- {claim}. Source: {cited as the rules say}. Confidence: {low | medium | high | sure}`; the answer line is `- **Answer** ({confidence}): {text}`.
- **D4 A follow-up has a title before a colon, and its `Decision:` on a line of its own.** `- **F<n>** {title}: {what, and why it matters}`, then an indented line `Decision:`. The title is the text between the id and the first colon. `results-review` writes `Decision: file` or `Decision: no issue` on that line. The `file-issues` context states the same shape.
- **D5 Rerun rules match questions and follow-ups by text, not by number.** On a later run, the stage keeps `## Decisions` verbatim, every filled `Decision:` line, and the answer, evidence and disagreements of each question whose text the current spec still asks, unless a review note names it; it reworks what each note asks and then removes the note; new questions and the questions notes name are researched; dropped questions are removed. The brief lists which questions this run researches, and the agent prompt says to answer those.
- **D6 A filled `Decision:` stays even when the recommendation changes.** When a rerun recommends a different option, the stage says so in the Recommendation text, right above the `Decision:` line, so the person sees it at `results-review`.

### Contract 1, the skill

Frontmatter, verbatim:

```yaml
---
name: research
description: Internal Slicewright research stage. Coordinates research agents and review agents to answer the research questions in spec.md from sources, with cited evidence and a confidence, and writes research.md with the answers, conclusions, options, a recommendation and follow-ups, for a person to decide on. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---
```

The sections, each in the design skill's form:

- **Intro:** answer the questions `spec.md` asks, from sources, with evidence, and write it down so that a person can decide. The stage coordinates: research agents answer from their angle, it merges the findings into one document, review agents check it, and it handles what they find. Never write code, and never change the project's documentation.
- **0. Read the arguments:** `activeSlicePath`; `knowledge`, as in design; `context`: the project's rules for this stage, which may be missing, such as the sources of its own knowledge beyond the documentation, the order of trust between kinds of sources, how to cite, and what counts as evidence; `researchAgents`: each entry one angle or one kind of source, and its `context` says which; when missing, the stage researches everything itself; `reviewAgents`, as in design. The agent entry format, the "ignore any other key" rule, the documentation paragraph and the per-prompt documentation line, verbatim from design. "Never ask the user anything. What you can't settle becomes an open question in research.md, and a later stage takes it to a person. Never change any file but `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md`."
- **1. Read the slice:**
  - `spec.md`: the questions are its requirements, `R<n>`; the scope names the sources in and out; each acceptance criterion says what a good answer to its question contains; the constraints hold the rules of evidence for this topic. Missing: `NO_SPEC`. An open question with `Blocks design: yes`: `SPEC_NOT_READY`, naming it. Both before anything is written, so the error's `files` is `none`.
  - `input.md`: the request and the decisions recorded with it.
  - `research.md` from an earlier run, when it exists: the rerun rules of D5 and D6, written out in full.
- **2. Prepare the brief**, the three parts of R3: the project's documentation, read only where it bears on the questions, staged pages first; the sources the context names, read where they bear on the questions; the rules of evidence and citation, from the context and from the spec's Constraints, as one list, with the sources the spec rules out. The brief holds the paths of `spec.md` and `input.md`; the questions this run researches (every requirement, or on a later run the new ones and those a note names, with the note); what the project's own knowledge says on each question, each fact with the path it came from; and the rules.
- **3. Run the research agents:** every `fork` entry at once, in parallel, with the Agent tool, with the prompt below; each `inline` entry played by the stage in the same form; without `researchAgents`, the stage answers in the same form. A failed agent, or one that answers without the form, is started once more; after a second failure the stage covers its angle itself and says so in the result. The documentation line follows the prompt, as in design.

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

- **4. Merge:** per question, every claim with a source is evidence, and a claim without one isn't written; one answer, with its confidence as D2 says; where findings disagree, which one the answer follows and why, by the context's order of trust; a question nothing answers gets "not answered: {why}". Then Conclusions: what the answers mean together for the goal in `spec.md`. Options: one per course of action the conclusions allow, each with for and against. Recommendation: one option and why, ending with an empty `Decision:`. Unknowns as in design: from the sources, else an assumption with a reason, else an open question with the recommended answer applied and what it affects; a line under Decisions settles its question. Follow-ups: later work the research shows, each with an empty `Decision:` unless kept from an earlier run. Scope: answer what the spec asks and add nothing. Then the template below, and a self-check: a requirement without its `### R<n>`; an evidence line without `Source:` or a confidence word; a source the spec rules out; a confidence the evidence doesn't justify; an option without for and against; a recommendation that isn't one of the options; a changed line under Decisions or a changed filled `Decision:`; an applied review note left in place; placeholders.
- **5. Review:** as in design, with the prompt below; issues are checked "against the spec, the sources and the draft"; the rest of the handling verbatim.

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

- **6. Save and return:** write `research.md` with the Write tool, leaving out the review notes applied and the Review notes section when it is empty; `WRITE_FAILED` on failure. Append to `design-reviews.md` under `## research, {time}` in design's form, creating the file with `# Design reviews` when missing, the time from `date -u +%Y-%m-%dT%H:%M:%SZ` run on its own; `Review skipped: no review agents configured` for an empty list. The result blocks:

```text
result: ok
message: <one sentence: research.md is saved, with the number of questions answered of those asked, the number of open questions and of follow-ups, and any research agent you had to cover yourself>
files: <activeSlicePath>/research.md, <activeSlicePath>/design-reviews.md
```

```text
result: error
code: <NO_SPEC | SPEC_NOT_READY | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```

The `research.md` template, in R4's order. The `slice:` line is left out without an id; every section that would be empty is left out, except Questions, Conclusions and Recommendation; Decisions appears only as kept from an earlier run; Review notes only with notes left.

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

What `results-review` writes, and the stage keeps: `Decision: {the decision in the person's words}` or `Decision: none: {why}` under Recommendation; `Decision: file` or `Decision: no issue` on a follow-up's line; `- {question}: {answer}` under Decisions; `- {question or section}: {request}` under Review notes.

### The design skill's parts the contract calls "verbatim from design" or "as in design"

From `plugins/slice/skills/design/SKILL.md`, which the worker reads in full: the `activeSlicePath`, `knowledge` and `reviewAgents` bullets of section 0; the "Each agent entry has:" list; the "Ignore any other key. The context is rules for you to follow. Never copy it into a file." paragraph; the whole "The project's documentation: …" paragraph with the per-prompt documentation line; section 1's `input.md` bullet; the opening paragraph of section 5 ("This step is required unless `reviewAgents` is an empty list…") and its "Then handle what the reviewers report" list with Issues, Recommendations, Contradictions and Failures, and its last sentence about having no tool for starting subagents; section 6's record paragraph with the `date` command and the record block with its Status, Issue and Recommendation lines, and its "Review skipped" sentence. The open question in `spec.md` that blocks is the one whose `Blocks design` line says `yes`, the form `plugins/slice/skills/clarify/SKILL.md` writes.

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- the skill folder `plugins/slice/skills/research/` with `SKILL.md`, frontmatter `name: research`, a description, `user-invocable: false`: the stage `slice:research` → used by T04 (`.slicewright/research.json`'s stage `research` has `"skill": "slice:research"`, and the `configs` check and the runner require the folder), T07 (README)
- the stage's params: `activeSlicePath`, `knowledge`, `context`, `researchAgents`, `reviewAgents`; agent entries with `executionMode`, `skill` or `agent`, `context`, optional `name` → T04, T07
- the error codes `NO_SPEC`, `SPEC_NOT_READY`, `WRITE_FAILED` → T04 (the `results-review` context names the first two)
- the review record in `<activeSlicePath>/design-reviews.md` under `## research, <time>` → T04 (`results-review` summarizes research's latest entry)
- the `research.md` shapes T04's contexts write or read: the Recommendation section ends with a line `Decision:` (a person writes `Decision: <decision>` or `Decision: none: <why>`); `## Decisions` lines `- <question>: <answer>` (a person creates the section after Recommendation); each follow-up `- **F<n>** <title>: <what, and why it matters>` followed by an indented line `Decision:` (a person writes `Decision: file` or `Decision: no issue`; the title is the text between the id and the first colon); `## Review notes` lines `- <question or section>: <request>` (a person writes them; the stage removes the ones it applied and the section when empty); open questions as `- **Q<n>** …` with Options, Recommended and Affects lines and no Blocks line → T04

**Uses:** what this task relies on, exactly as written, without changing it:

- `plugins/slice/skills/design/SKILL.md`: the model, from the existing code
- `plugins/slice/skills/clarify/SKILL.md`: the open-question form with `Blocks design: {yes | no}`, from the existing code
- `plugins/slice/skills/run/SKILL.md`, section 4.3: the result block, from the existing code
- `tests/static/skill.awk` and the `skills` check of `tests/static.sh`: `name` equals the folder, `description` not empty, `user-invocable: false` between the `---` lines, from the existing code

## Changes

- `plugins/slice/skills/research/SKILL.md` (new). Build it on `plugins/slice/skills/design/SKILL.md`: same section numbers and names, same prose where the contract says "as in design" or "verbatim", and the contract's own text where it differs.
  - **Frontmatter:** line 1 is `---`, then `name: research`, the `description:` line from Contract 1, `user-invocable: false`, then `---`. Nothing else between the dashes: `skill.awk` reads from line 1 to the next `---`.
  - **Title and intro:** `# Research`, one paragraph in the design intro's shape (the Intro bullet of Contract 1), then `Arguments: $ARGUMENTS`.
  - **`## 0. Read the arguments`:** "The arguments are a JSON object. This stage uses:" then five bullets: `activeSlicePath` and `knowledge` verbatim from design; `context` as Contract 1 says; `researchAgents`: the agents that answer the questions; each entry is one angle or one kind of source, and its `context` says which; when missing, you research everything yourself; `reviewAgents` verbatim from design. Then, verbatim from design: the "Each agent entry has:" list, the "Ignore any other key…" paragraph, and the whole "The project's documentation: …" paragraph with the per-prompt line. Then the closing paragraph with `research.md` in place of `design.md`, plus the file rule: "Never ask the user anything. What you can't settle becomes an open question in research.md, and a later stage takes it to a person. Never change any file but `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md`."
  - **`## 1. Read the slice`:** three bullets in design's shape. `spec.md`: the questions are its requirements, `R<n>`; the scope names the sources in and out; each acceptance criterion says what a good answer to its question contains; the constraints hold the rules of evidence for this topic; if it doesn't exist, return `NO_SPEC`; if it still has an open question with `Blocks design: yes`, return `SPEC_NOT_READY`, naming the question; both before anything is written. `input.md`: verbatim from design. `research.md`, when it exists from an earlier run: the rerun rules written out in full (D5, D6): match questions and follow-ups by their text, not their number; keep `## Decisions` as it is and treat each line as settled, never asked again and never an open question; keep every filled `Decision:` line as it is, the recommendation's and each follow-up's; keep the answer, evidence and disagreements of each question whose text the current spec still asks, unless a note under Review notes names it; rework what each note asks, then remove the note; drop the questions the spec no longer asks; research the new questions and the ones the notes name; when this run recommends a different option and the `Decision:` line is filled, say so in the Recommendation text right above that line, and leave the line as it is.
  - **`## 2. Prepare the brief`:** "Gather what every research agent needs, once, so they don't each repeat it:" then exactly the three parts of R3 as bullets: the project's documentation (start where each source's `context` says, read only the pages that bear on the questions, a staged page in `<activeSlicePath>/docs/` instead of the published one, deprecated or out-of-date pages unreliable and become assumptions, skipped when no `knowledge` was given); the sources the context names, such as the code or the records of earlier slices, read where they bear on the questions; the rules of evidence and citation, from the context and from the spec's Constraints, as one list, with the sources the spec rules out. Then what the brief holds: the paths of `spec.md` and `input.md`; the questions this run researches (every requirement, or on a later run the new ones and those a note names, with the note's text); what the project's own knowledge says on each question, each fact with the path it came from; and the rules. No fourth part: AC3 counts three.
  - **`## 3. Run the research agents`:** "Start every `fork` entry at once, in parallel, with your tool for starting subagents (Agent), using this prompt:", with no "applies unless" filter, then the research agent prompt verbatim from Contract 1. The four confidence levels are defined only there (D2). After the block: the documentation line from section 0 follows the prompt unless `knowledge` is missing; take the role of each `inline` entry yourself, answering in the same form; without `researchAgents`, answer every question yourself in the same form; if a research agent fails, or answers without the form, start it once more; if it fails again, cover its angle yourself, and say so in the result.
  - **`## 4. Merge`:** a numbered list in design's shape with Contract 1's rules: evidence; one answer per question with its confidence as D2 says, "not answered: {why}" when nothing answers; disagreements by the context's order of trust, with a reason of your own when the context gives none; Conclusions, Options, Recommendation ending with an empty `Decision:`; unknowns in design's three-step order, a line under Decisions settling its question; follow-ups with an empty `Decision:` unless kept; scope. Then "Fill in this template:" and the template verbatim from Contract 1, then the keep/leave-out rule (always keep Questions, Conclusions and Recommendation; leave out the `slice:` line without an id and any other empty section; Decisions only as kept from an earlier run; Review notes only with notes not yet applied), then "Then check your draft and fix it in place:" with Contract 1's self-check list.
  - **`## 5. Review`:** design's opening paragraph verbatim with `{SPEC}` and `{RESEARCH}`, the review prompt verbatim from Contract 1, design's "Then handle what the reviewers report:" list with two edits (issues checked "against the spec, the sources and the draft"; recommendations that "clearly improve the research without widening it"), and design's last sentence verbatim.
  - **`## 6. Save and return`:** design's text with `research.md`: write it with the Write tool, replacing the earlier version; leave out the review notes you applied, and the Review notes section when it is empty; `WRITE_FAILED` on failure. The record paragraph verbatim from design, the record block verbatim except its heading `## research, {time}`, the "Review skipped: no review agents configured" sentence verbatim, "End with the result, with nothing after it.", then the two result blocks verbatim from Contract 1. Last, the sentence about what `results-review` writes and the stage keeps.
  - Throughout: plain English, short sentences; no `&&`, `;`, pipes or `cd` as commands; no version control named; the only command is the `date` line; no example sources, citation forms, trust orders or limits.

## Verify

Run from the repo root.

- `sh tests/static.sh`: exit 0; `PASS skills` among its lines, no `FAIL skills:` line, last line `static: passed`. While other wave-1 workers write `tests/static.sh` and the `run` and `configure` skills in the same folder, a transient `FAIL` on their files isn't this task's; rerun when they have finished. Proves AC1.
- `claude plugin validate plugins/slice`: exit 0.
- `awk -v file=plugins/slice/skills/research/SKILL.md -v folder=research -v internal=1 -f tests/static/skill.awk plugins/slice/skills/research/SKILL.md`: prints nothing. Proves AC1's three frontmatter facts on the one file.
- `head -5 plugins/slice/skills/research/SKILL.md`: `---`, `name: research`, the description line, `user-invocable: false`, `---`.
- `grep -n "^## [0-6]\. " plugins/slice/skills/research/SKILL.md`: exactly seven lines, `## 0. Read the arguments`, `## 1. Read the slice`, `## 2. Prepare the brief`, `## 3. Run the research agents`, `## 4. Merge`, `## 5. Review`, `## 6. Save and return`, in that order (D1). The pattern leaves out the `## ` headings inside the template's and the record's code blocks, which a plain `^## ` would also match, as it does in the design skill.
- `grep -nw git plugins/slice/skills/research/SKILL.md`: nothing. `grep -n "&&" plugins/slice/skills/research/SKILL.md`: nothing. `grep -nw cd plugins/slice/skills/research/SKILL.md`: nothing (R1's conventions).
- `grep -c "Confidence: {low | medium | high | sure}" plugins/slice/skills/research/SKILL.md`: `2` (the answer form and the template).
- `grep -n "Review skipped: no review agents configured" plugins/slice/skills/research/SKILL.md`: one line, in section 6.
- `grep -n "date -u +%Y-%m-%dT%H:%M:%SZ" plugins/slice/skills/research/SKILL.md`: one line, in section 6.
- `git status --short`: `?? plugins/slice/skills/research/` among the lines, and no change of this task's under `plugins/slice/defaults.json`, `.slicewright/` or `tests/`.
- AC2: section 1's first bullet returns `NO_SPEC` when `spec.md` is missing and `SPEC_NOT_READY` "naming the question" on `Blocks design: yes`, before section 6 writes anything; the error block's `files: <files this run changed, or none>` therefore reads `none`.
- AC3: section 2's three bullets are the documentation, the sources the context names, and the rules of evidence and citation; the prompt in section 3 carries `{the entry's context…}`, `{paths of spec.md and input.md}`, `{the brief}` and the "Answer in this form" block with Claim, Source, Confidence and Disagreements per `R<n>`; the four `low`, `medium`, `high`, `sure` lines in that prompt match R3 word for word; the sentence after the prompt says "start it once more … cover its angle yourself, and say so in the result"; the opening sentence says "Start every `fork` entry at once, in parallel". The transcript part of AC3 belongs to the hand run of AC11 (Q1).
- AC4: the template's sections run header, Questions, Conclusions, Options, Recommendation, Decisions, Assumptions, Open questions, Follow-ups, Review notes; each `### R<n>` has Answer, Evidence (`Source:` and `Confidence:` on every line) and Disagreements; Recommendation ends with `Decision:`; each follow-up has its indented `Decision:`; the rule after the template says Decisions appears only as kept from an earlier run and Review notes only with notes left; the self-check lists "an applied review note left in place".
- AC5: section 1's third bullet keeps `## Decisions` as settled and never asked again, keeps every filled `Decision:` line, reworks a question a note names and removes the note; section 6 says to leave out applied notes and the empty section.
- AC6: the section 5 prompt carries only the entry's context, `{SPEC}`, `{RESEARCH}` and the answer form; the Issues handling says fixed or rejected with a reason, and the record form has `→ {fixed: how | rejected: why}`; section 6 says `Review skipped: no review agents configured` for an empty list, and section 5's first sentence says the step is required "unless `reviewAgents` is an empty list".
- AC7: section 6 names both files, takes the time from `date -u +%Y-%m-%dT%H:%M:%SZ` run on its own, heads the record `## research, {time}`, and the ok block's message asks for the number of questions answered, open questions and follow-ups, with `files:` naming both paths.

## Boundaries

Leave alone: every other skill (`run`'s `allowed-tools` and `configure`'s option are T02's); `plugins/slice/defaults.json` (the research stage isn't in the default pipeline); `.slicewright/config.json`; everything under `.slicewright/stable/`; `.slicewright/research.json`, `.claude/settings.json` and `start-slice.sh` (T04); `tests/` (T03, T05); `slice/docs/` (T06); `README.md` and `AGENTS.md` (T07). No new top-level configuration key: the stage's settings are the five params. No example values, limits, sources, citation forms or trust orders in the skill: those stay in the stage's `context`. The skill changes no file but the two it names, and never the project's documentation.
