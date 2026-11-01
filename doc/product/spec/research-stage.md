---
type: spec
---

# Research stage

`slice:research` is an internal stage of the plugin that answers questions from sources, with cited evidence and a confidence, and writes the answers down for a person to decide on. It has the shape of the design stage: research agents fan out, the stage merges one document, `research.md`, and review agents check it. It is for a slice that is a research topic, not a feature. The plugin ships the stage; which pipeline runs it, with which agents, sources and rules, is a project's configuration. In this repo the [research pipeline](research-pipeline.md) runs it, and the default pipeline doesn't. [Structure](../../overview/structure.md) names the skill's folder.

## Requirements

### Params

- The stage's skill is `plugins/slice/skills/research/SKILL.md`, with `name: research`, a description and `user-invocable: false`. The runner invokes it; it is never run on its own.
- Its arguments are a JSON object. It uses `activeSlicePath`, `knowledge`, `context`, `researchAgents` and `reviewAgents`, and ignores any other key. The stage has no params in `defaults.json`, because no default stage runs it; the skill documents them.
- `researchAgents` and `reviewAgents` are lists of agent entries, in the format every other stage uses: `executionMode` (`fork` runs a subagent, `inline` means the stage takes the role itself), `skill` or `agent` (`general-purpose` when neither is given), `context`, and an optional `name` for the record.
- Each `researchAgents` entry is one angle or one kind of source, and its `context` says which. Without `researchAgents`, the stage researches everything itself.
- Without `reviewAgents`, the stage uses one general-purpose reviewer. With an empty list, it skips the review. A reviewer's `context` is its review instructions; empty means a general review.
- `context` holds the project's rules for the stage: the sources of its own knowledge beyond the documentation, the order of trust between kinds of sources, how to cite, and what counts as evidence. The stage follows it and never copies it into a file.
- The stage never asks the person anything: what it can't settle becomes an open question, for a later stage to take to a person. It never writes code, never changes the project's documentation, and changes no file but `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md`.

### What it reads

- `<activeSlicePath>/spec.md` holds the questions: its requirements are the questions, one each; its scope names the sources in and out; each acceptance criterion says what a good answer to its question contains; its constraints hold the rules of evidence for the topic.
- Without `spec.md`, the stage returns `NO_SPEC`. When `spec.md` still has an open question marked `Blocks design: yes`, it returns `SPEC_NOT_READY`, naming the question. Both come before anything is written, so the error's `files` is `none`.
- It reads `<activeSlicePath>/input.md`, the request with the decisions recorded with it, and `<activeSlicePath>/research.md` when one exists from an earlier run.
- It reads the project's documentation as `knowledge` describes it: each source as its `context` says, and only where it bears on the questions. A page staged in `<activeSlicePath>/docs/` is read instead of the published one, and a `<path>.delete` file there means the page is being removed. A source that can't be reached is named in the result, and what was needed from it becomes an assumption.

### The brief

Before any agent starts, the stage gathers what every research agent needs, once, so that they don't each repeat it:

- what the project's documentation says on each question, each fact with the path it came from, treating pages the documentation marks as deprecated or out of date as unreliable
- what the sources the `context` names say, such as the code or the records of earlier slices
- the rules of evidence and citation, from the `context` and from the spec's constraints, as one list, with the sources the scope rules out
- the paths of `spec.md` and `input.md`, and the questions this run researches: every requirement, or on a later run the new ones and the ones a review note names, with the note's text

### Research agents

- Every `fork` entry starts at once, in parallel, with one prompt that carries the entry's context (or, when it is empty, an instruction to research every question from any source the rules allow), the paths of `spec.md` and `input.md`, the brief, the confidence scale and the answer form, followed by the documentation line unless `knowledge` is missing. An entry with a `skill` is told to invoke it. The stage plays each `inline` entry itself, in the same form.
- An agent answers with one block per question, in the spec's order: each claim as one fact with its source cited as the rules say and its confidence; the disagreements between its sources, or none; `nothing found` with why for a question its angle doesn't answer; and the sources it couldn't reach. An agent never changes a file and never asks the person anything.
- Confidence is one of four words, defined in the skill so that every project's findings use the same scale:
  - `low`: inferred, or from a secondary source, or disputed
  - `medium`: stated by one source the agent read
  - `high`: stated by two independent sources, or by the primary source for the matter
  - `sure`: shown by the project's own code or documentation, or checked by the agent itself
- An agent that fails, or answers without the form, is started once more. When it fails again, the stage covers its angle itself and says so in the result.

### The research document

The stage merges the findings into `<activeSlicePath>/research.md`:

- A claim with a source is evidence. A claim without a source isn't, and isn't written.
- Each question gets one answer with its confidence: the lowest confidence of the evidence the answer depends on, `high` when two independent sources state the same, and `sure` for what the project's own code or documentation shows. A question nothing answers gets "not answered" with why.
- Where findings disagree, the document says which one the answer follows and why, by the `context`'s order of trust between kinds of sources, or with a reason of the stage's own when the context gives none.
- Each unknown is settled in this order: answered from the sources; otherwise given a default with a reason and listed under Assumptions; otherwise made an open question, with a recommended answer that the draft applies and what depends on it. A line under Decisions settles its question for good.
- The document answers what the spec asks and adds nothing.

Its sections, in this order:

1. a header with `slice: <id>` from `input.md`, left out when the request has no id, then the title `# Research: <the slice's title, as input.md gives it>`
2. `## Questions`: one `### R<n> <question>` per requirement of the spec, in the spec's order, each with **Answer** and its confidence, or "not answered" with why; **Evidence**, each line a claim with `Source:` and `Confidence:`; and **Disagreements**, or "none"
3. `## Conclusions`: what the answers mean together for the spec's goal
4. `## Options`: one `### O<n> <option>` per course of action the conclusions allow, each with **For** and **Against**
5. `## Recommendation`: one of the options and why, ending with a `Decision:` line left empty for the person
6. `## Decisions`: the answers a person gave at a review, one line each, `- <the question>: <the answer>`. The stage never writes this section itself; it keeps it as it is
7. `## Assumptions`: each with why it holds, such as a source that couldn't be reached
8. `## Open questions`: each `Q<n>` with why it matters, lettered options, the recommended answer the draft applies, and what it affects, as in `spec.md` and `design.md`
9. `## Follow-ups`: one `- **F<n>** <title>: <what, and why it matters>` per piece of later work, each with a `Decision:` line of its own, left empty
10. `## Review notes`: only the notes a person left that this run hasn't applied

Questions, Conclusions and Recommendation are always present. Any other section that would be empty is left out.

Before the review, the stage checks its draft and fixes it in place: a requirement without its `### R<n>`; an evidence line without `Source:` or a confidence word; a source the spec rules out; a confidence the evidence doesn't justify; an option without for and against; a recommendation that isn't one of the options; a changed Decisions line or a changed filled `Decision:` line; an applied review note left in place; placeholders, TODOs or sections that contradict each other.

### Later runs

A later stage takes `research.md` to a person, who writes into it: the recommendation's `Decision:` line, each follow-up's `Decision:` line, lines under `## Decisions`, and requests under `## Review notes`. On a later run the stage keeps what they wrote:

- Questions and follow-ups are matched by their text, not their number.
- Every line under Decisions stays and counts as settled: it is never asked again and never becomes an open question.
- Every filled `Decision:` line stays as it is, the recommendation's and each follow-up's, whatever its words. When this run recommends a different option and the recommendation's line is filled, the recommendation says so right above the line and leaves the line as it is.
- The answer, evidence and disagreements of each question the current spec still asks are kept, unless a review note names the question. What each note asks is reworked, and then the note is removed.
- Questions the spec no longer asks are dropped. New questions, and the ones the notes name, are researched.

This is what makes a "more research" loop work: a person asks for more on one question, and the rest stands.

### Review

- The review is required unless `reviewAgents` is an empty list; the stage's own check of the draft doesn't replace it.
- Every `fork` review agent starts at once, in parallel, with a prompt that carries the entry's context, or a general instruction when it is empty, the full `spec.md`, the full draft, and the answer form: `Status: Approved | Issues found`, `Issues` and `Recommendations`. The reviewer is told nothing about how the draft was made. The stage plays each `inline` entry itself.
- An issue is what would lead the decision wrong: an answer the evidence doesn't support, a source that doesn't say what is claimed, a recommendation the conclusions don't give. Wording, style and uneven detail aren't issues.
- Each issue is checked against the spec, the sources and the draft, then fixed, or left with a reason. A recommendation that clearly improves the research without widening it is applied; the rest become open questions. When reviewers contradict each other, the stage decides with a reason or makes it an open question. A reviewer that fails or answers without the form is started once more, and then counts as not run.
- Only when the stage has no tool for starting subagents does it review the draft itself, following each entry's instructions, and record that the reviews didn't run.

### Saving and the result

- `research.md` is written with the Write tool, replacing the earlier version. A failed write returns `WRITE_FAILED`.
- The review record is appended to `<activeSlicePath>/design-reviews.md`, created with the heading `# Design reviews` when missing, under `## research, <time>`, with the time from `date -u +%Y-%m-%dT%H:%M:%SZ`: one heading per reviewer, by its name or `Reviewer <n>` with its skill or agent, with its status, each issue as fixed with how or rejected with why, and each recommendation as applied or as the open question it became. A skipped review writes `Review skipped: no review agents configured` instead. This is the file clarify and design write to, so one file keeps a slice's document reviews together.
- The stage ends with the runner's result block. On success: `result: ok`, a one-sentence message with the number of questions answered of those asked, the number of open questions and of follow-ups, and any research agent the stage had to cover itself, and `files` naming both files. On failure: `result: error`, `code` one of `NO_SPEC`, `SPEC_NOT_READY` or `WRITE_FAILED`, a message, a fix, and the files the run changed, or `none`.
- The skill follows the skill conventions: one command per call, no `cd`, files written with the Write or Edit tool, no version control named in its text, plain English.

## Acceptance criteria

- Given the working copy, when the static command runs, then its `skills` check accepts `plugins/slice/skills/research/SKILL.md` with `name: research`, a non-empty description and `user-invocable: false`.
- Given a slice folder without `spec.md`, when the stage runs, then it ends with `result: error`, `code: NO_SPEC` and `files: none`.
- Given a `spec.md` whose open question Q1 says `Blocks design: yes`, when the stage runs, then it ends with `code: SPEC_NOT_READY` and a message naming Q1, and writes no `research.md`.
- Given the skill text, when a reviewer reads it, then the brief holds the project's documentation, the sources the context names, and the rules of evidence and citation; the agent prompt carries the entry's context, the two paths, the brief and the answer form; the answer form has the claim, the source, the confidence and the disagreements per question; the four confidence levels are defined as above; and a failed agent is retried once and then covered by the stage with a note in the result.
- Given a run with several `fork` research agents, when its transcript is read, then every one was started at once, and each at most twice.
- Given a `research.md` the stage wrote, when a reviewer reads it, then its sections are in the order above; every requirement of `spec.md` has its `### R<n>` with an Answer, an Evidence list where each line has a source and one of the four confidence words, and a Disagreements line; the Recommendation ends with an empty `Decision:` line; every follow-up has an empty `Decision:` line; there is no Decisions section unless the earlier version had one; and no Review notes section remains from notes the stage applied.
- Given an earlier `research.md` with one line under Decisions, the recommendation's `Decision:` filled, one follow-up's `Decision:` filled, and one note under Review notes asking to look at another source for one question, when the stage runs again, then the Decisions line and both `Decision:` lines are unchanged, no open question asks what the Decisions line answers, that question's evidence has changed, and the Review notes section is gone.
- Given one `fork` review agent, when the stage runs, then the agent's prompt holds the full `spec.md`, the full draft and the answer form, and nothing about how the draft was made; and `design-reviews.md` records each issue as fixed with how or rejected with why.
- Given `reviewAgents: []`, when the stage runs, then the record says `Review skipped: no review agents configured` and no reviewer starts.
- Given a successful run, when it ends, then `<activeSlicePath>/research.md` and `<activeSlicePath>/design-reviews.md` exist, the latter with a `## research, <time>` entry whose time came from `date -u +%Y-%m-%dT%H:%M:%SZ`, and the reply ends with `result: ok`, a message that gives the number of questions answered, of open questions and of follow-ups, and `files` naming both files.

## Limitations

- The stage hasn't run for real yet. Its error codes, the merge, the rerun rules and the review have been checked by reading the skill text against the criteria above, not by a run: the test stage of the slice that built it ran only the smoke suite, which runs the default pipeline, and the default pipeline doesn't include the stage. Reason: a headless test of a pipeline with a person at its gates was left out of scope, so the first research topic after the merge is the stage's first run. The criteria that need a run, the retries, the merged document and the rerun, are shown there.
- The stage's params aren't in `defaults.json`, because no default stage runs it. So the README's line that `defaults.json` shows every stage's params doesn't hold for `researchAgents`: the research stage's params are documented in the skill, in the README's list of agents under Concepts, and in this repo's `.slicewright/research.json`. Reason: the code review rated the README line a suggestion, outside what the slice set out to change, and the slice shipped it unchanged: the round had no blocking finding, so no review decision was taken.
- The skill's last paragraph names the words this repo's research pipeline writes into `research.md`: `Decision: file`, `Decision: no issue` and `Decision: none: <why>`. They are a project's choice, made in the pipeline's `results-review` context, not the plugin's. The stage's own rule, keep every filled `Decision:` line as it is, doesn't depend on the words, so a project that writes other words loses nothing. Reason: the code review rated the paragraph a suggestion, because the design gave it verbatim, and the slice shipped it unchanged: the round had no blocking finding, so no review decision was taken.
