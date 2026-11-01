---
slice: issue-16
---

# Design: Research flow: a slice:research stage and a research pipeline

## Context

spec.md gives the goal, the requirements and the acceptance criteria. This section gives only what the approach depends on.

- The plugin holds no program code: a stage is a `SKILL.md`, and the pipeline is JSON. The working copy's `plugins/slice` is byte-identical to `.slicewright/stable/plugins/slice` today; only the working copy changes.
- The runner, `plugins/slice/skills/run/SKILL.md`, loads the configuration in its section 1 before it asks anything. Its only switch to the configuration `status.md` records is the sentence "When resuming without `--config`…". In `new` mode the **Continue** choice says "go on as in `resume` below", which refers to section 3's resume steps, not to section 1, so the switch never happens there. `status.md` has a `config:` line only for a configuration other than `config.json` (`skills/tracking/SKILL.md`, and the runner's section 4.6).
- The design skill, `plugins/slice/skills/design/SKILL.md`, is the model for the research skill: sections 0 to 6, the agent entry format, the documentation line every agent prompt carries, the parallel fork agents with one retry, the review prompt that carries only the documents and the answer form, and the record in `design-reviews.md`. `clarify` uses the same review and record form. `diagnose` already uses the words `low`, `medium`, `high` and `sure`.
- `slice:human` changes only the files in `files`, but reads whatever its context names. A choice mapped to `null` ends the run with `ENDED`. `slice:deploy` does what its context says step by step, returns `skipped` on an empty context, and records each run in `deployments.md` with Revision, Target, Endpoint, Steps, Check and Outcome. `slice:consolidate` runs its knowledge agents one at a time, in list order, names a slice's records folder `<date>-<id>`, or `<date>-<title in lowercase words joined with ->` without an id, and updates a page staged in an earlier consolidation instead of adding another.
- `/slice:configure` takes only `--permissions`. Its step 4.1 reads the four `config.json` files and step 3 loads "as in step 4.1". Its `allowed-tools` covers `Read(~/.slicewright/config.json)` only.
- `.slicewright/config.json`: `sharedParams` has `activeSlicePath`, `knowledge` (byte-identical to the defaults' `knowledge`) and `taskTypes` (`plugin`, `documentation`, `test`); 21 stages. Intake's context checks `.slicewright/stable/`, reads an issue with `gh issue view`, and creates the branch; release's context pushes and opens the pull request with `gh pr create`. These two texts are what `research.json` repeats.
- `.claude/settings.json` allows the eleven stage skills, the git commands, `cp`, `jq`, `claude plugin validate` and `gh pr create|view|edit`. It has no `gh issue` rule and no `Skill(slice:research)`.
- `start-slice.sh` is POSIX sh, 110 lines. `cannot_run` exits 2 and `fail` exits 1. It parses its one argument right after `cd "$repo"` and before the tool checks, validates the stable plugin with `claude plugin validate`, prints the leftover-slice note from `title`, `stage` and `status` of `slice/status.md`, and ends with `exec claude --plugin-dir "$plugin" "/slice:new $issue"` or without a request. It starts the stable plugin, at `origin/master`.
- `tests/static.sh` runs four checks. The `defaults` check builds `$skills`, the skill folders with a `SKILL.md`, and runs `jq -r --argjson skills "$skills" -f tests/static/defaults.jq <plugin>/defaults.json`; each output line becomes `FAIL defaults: <line>`. `defaults.jq` is one program with a main expression, so jq can't `include` it. It treats a missing key and `null` alike for `next`, `onError`, `choices` and a stage's `skill`. `tests/selftest.sh` has 15 cases, nine `static/…` and six `smoke/…`; `static/checker` shows how a case copies the repo's parts and runs the copy's `static.sh`. `need_line` and `line_of` are general helpers.
- Facts measured during this stage, with jq 1.7.1, Claude Code 2.1.311 and `/bin/dash` present:
  - jq's `*` keeps a `null` value instead of removing the key. A four-line `merge` def with `del` removes it, replaces `pipeline` whole, and merges objects at any depth (tested on `config.json` onto `defaults.json`: 21 stages, `sharedParams` with its three keys).
  - `$ARGS.named` holds a `--slurpfile` value, so one jq program can take an optional base.
  - `config.json` merged onto `defaults.json` and checked by `defaults.jq` prints nothing. A draft of the eight research stages prints nothing once a `research` skill folder exists, and `stage research: skill "slice:research" names no skill folder` without one.
  - `gh issue list` has `--state all`, `--search`, `--json` and `--limit`; `gh issue create` has `--title`, `--body` and `--repo`; `gh issue view` has `--json`.
  - The `claude-code-guide` subagent type exists on this machine, with Bash, Read, WebFetch and WebSearch. There is no `~/.slicewright/`.
- `doc/architecture/building-blocks.md` and `runtime.md` say "four checks" and "Fourteen cases"; they are already stale and outside this slice's documentation scope.

## Approach

One new skill, and the rest configuration.

**The research skill** has the shape of the design skill. It reads `spec.md`, whose requirements are the questions, builds a brief once from the project's own knowledge and the rules of evidence, fans one prompt out to the research agents, merges their findings into `research.md`, has the review agents check it, and records the review in `design-reviews.md`. The skill holds the protocol: the confidence scale, the answer form, the template, the rerun rules and the result block. The sources, the order of trust, the citation form, what counts as evidence, what is published and whether issues are filed live in `.slicewright/research.json`.

**The research pipeline**, `.slicewright/research.json`, holds only `pipeline`: eight stages. `intake` and `release` repeat `config.json`'s contexts. `clarify` gets a context that turns a topic into questions, and one reviewer that checks them. Two human gates frame the research: `questions-review` approves the questions the way `spec-review` approves a spec, and `results-review` takes the person through the answers, the recommendation and the follow-ups, and chooses `accept`, `more-research`, `re-scope` or `drop`. `file-issues` and `release` are `slice:deploy` with contexts. `consolidate` has three knowledge agents: `research` writes the research page, `adr` writes a decision record when a decision was taken, and `index` keeps the indexes and lists the new folder.

**The runner** reloads the configuration `status.md` names when the person chooses **Continue** in `new` mode without `--config`: one bullet changes, and `Skill(slice:research)` joins `allowed-tools`.

**`/slice:configure`** takes `--config <name>` with the runner's name rule, creates no file for another name, and loads the three files of that name in its documentation and permissions steps.

**`start-slice.sh`** parses `--config <name>` before anything runs, checks `.slicewright/<name>.json` after the stable plugin validates, passes the flag to `/slice:new`, and names the configuration in the leftover note.

**The static level** gets a fifth check, `configs`: `defaults.jq` takes an optional base and merges its input onto it with the runner's rule; `static.sh` calls it once per `.slicewright/<name>.json` of its own repo. The self-test gets `static/configs`, built like `static/checker`.

**Order of work.** The research skill folder lands in an earlier wave than `research.json`, not the same one, because the `configs` check fails on `research.json` while the skill folder is missing, and that check runs both in the quality gates between waves and in the `research.json` task's own Verify, before the other task's work is committed. The staged pages, `README.md` and `AGENTS.md` land last, after what they describe works.

## Affected areas

| Area | Files or modules | Change |
|---|---|---|
| Research skill | `plugins/slice/skills/research/SKILL.md` | new: Contract 1 (R1–R7) |
| Runner | `plugins/slice/skills/run/SKILL.md` | `allowed-tools`, and the Continue bullet of section 3: Contract 3 (R8) |
| Configure | `plugins/slice/skills/configure/SKILL.md` | frontmatter, the arguments paragraph, steps 2, 3.1, 4.1 and 5: Contract 4 (R14) |
| Research pipeline | `.slicewright/research.json` | new: Contract 2 (R10). Not `.slicewright/config.json`, which stays as it is. |
| Permissions | `.claude/settings.json` | four rules appended to `permissions.allow`: Contract 6 (R9) |
| Start script | `start-slice.sh` | option parsing, the file check, the request, the note: Contract 5 (R11) |
| Static level and self-test | `tests/static.sh`, `tests/static/defaults.jq`, `tests/selftest.sh` | the `configs` check, the optional base, the `static/configs` case and one line in `static/checker`: Contract 7 (R12) |
| Documentation | `slice/docs/overview/structure.md`, `slice/docs/overview/testing.md` (staged); `README.md`, `AGENTS.md` (in place) | Contract 8 (R13) |

Nothing changes under `plugins/slice/defaults.json`, `.slicewright/config.json`, `.slicewright/stable/`, `tests/smoke.sh` or `tests/smoke/`. The task types: the skills, `README.md` and `AGENTS.md` are `plugin`; the tests are `test`; the staged pages are `documentation`; `research.json`, `.claude/settings.json` and `start-slice.sh` fit `infrastructure` (see Assumptions).

## Decisions

### D1 The research skill mirrors the design skill section by section

- **Choice:** sections 0 to 6 with the same names, the same agent entry format, the same documentation line, the same retry rule, the same review prompt shape and the same `design-reviews.md` record. Only the brief, the agent prompt and answer form, the merge rules, the template and the rerun rules differ.
- **Why:** the spec names design as the model (R3, R6, R7); the reviewers of this repo know the shape; and a shared shape keeps each rule in one place per skill.
- **Alternatives:** a shorter skill that refers to design's text: a skill must be complete on its own, because the runner's subagent reads only it. A review form of its own: the record in `design-reviews.md` would differ between stages for no reason.

### D2 The confidence scale is defined once, in the agent prompt, and the merge applies it

- **Choice:** the four levels and their definitions (R3) are in the research agent's prompt block in section 3, which is also the form the stage uses when it researches itself. Section 4 gives the answer its confidence: the lowest confidence of the evidence the answer depends on; `high` when two independent sources state the same, as the scale says; `sure` for what the brief found in the project's own code or documentation.
- **Why:** an agent sees only its prompt, so the scale must be there; a second copy in section 4 would drift; and `results-review` presents "each answer with its confidence" (R10.5), so the answer needs one.
- **Alternatives:** the scale in `research.json`'s context: the spec puts it in the skill so every project uses the same words. A "Confidence" section the prompt refers to by name: the agent can't read the skill.

### D3 Evidence lines carry the labels `Source:` and `Confidence:`

- **Choice:** each evidence line is `- {claim}. Source: {cited as the rules say}. Confidence: {low | medium | high | sure}`; the answer line is `- **Answer** ({confidence}): {text}`.
- **Why:** AC4 asks that each evidence line has a source and one of the four confidence words; labels make that checkable by a reviewer and by a person, and the research reviewer's "open the source" rule needs the source to stand out.
- **Alternatives:** a compact `claim (source, level)`: the source is hard to tell from the claim when a citation has commas or parentheses. A table: long citations break tables.

### D4 A follow-up has a title before a colon, and its `Decision:` on a line of its own

- **Choice:** `- **F<n>** {title}: {what, and why it matters}`, then an indented line `Decision:`. The title is the text between the id and the first colon. `results-review` writes `Decision: file` or `Decision: no issue` on that line. The `file-issues` context states the same shape, so the skill that writes it and the context that reads it agree.
- **Why:** `file-issues` needs a title for the issue and for the exact-title search (R10.6), and a `Decision:` line of its own is what AC4 asks for and what a person fills most easily.
- **Alternatives:** `Decision:` at the end of the same line, as the ` · Decision:` suffix of advisory findings in the review record: those suffix a line a person doesn't otherwise edit; here the person fills it. The first sentence as the title: brittle.

### D5 Rerun rules match questions and follow-ups by text, not by number

- **Choice:** on a later run, the stage keeps `## Decisions` verbatim, every filled `Decision:` line, and the answer, evidence and disagreements of each question whose text the current spec still asks, unless a review note names it; it reworks what each note asks and then removes the note; new questions and the questions notes name are researched; dropped questions are removed. The brief lists which questions this run researches, and the agent prompt says to answer those.
- **Why:** `re-scope` sends the slice through clarify again, which may renumber; the text is what survives. Sending only the open questions to the agents is what makes `more-research` cheap.
- **Alternatives:** redo everything on every run: wastes the earlier evidence and ignores R5. Match by number: breaks after a re-scope.

### D6 A filled `Decision:` stays even when the recommendation changes

- **Choice:** as R5 says, a filled line is never changed. When a rerun recommends a different option, the stage says so in the Recommendation text, right above the `Decision:` line, so the person sees it at `results-review`.
- **Why:** a silent change would lose a person's decision; a sentence is the smallest way to show the mismatch.
- **Alternatives:** clear the line when the option changes: contradicts R5 and AC5. Move the old decision under Decisions: a rule for a rare case.

### D7 The runner switches configuration in the Continue bullet, not in section 1

- **Choice:** section 1 keeps its "when resuming" sentence. The **Continue** bullet of section 3, `new`, step 1, gains: when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file loaded, load that configuration as in section 1, check it as in section 2, and say so; then go on as in `resume`.
- **Why:** in `new` mode the person chooses after sections 1 and 2 have run, so the switch can only happen there; one bullet is the smallest change; with `--config` given the condition fails, so the given configuration stays, as R8 asks.
- **Alternatives:** read `status.md` in section 1, before the question: it would switch before the person has chosen, and **Start new** would then run the wrong pipeline. A new section: more text for the same rule.

### D8 `research.json` holds only `pipeline`

- **Choice:** no `sharedParams`: the defaults give `activeSlicePath` `./slice` and a `knowledge` identical to `config.json`'s; the defaults' `taskTypes` come along unused.
- **Why:** R10 wants `sharedParams` only where they must differ, and nothing differs. The smoke configuration follows the same rule.
- **Alternatives:** copy `config.json`'s `sharedParams`: a second copy of `knowledge` and `taskTypes` that drifts, and the task types are unused in this pipeline.

### D9 `file-issues` finds an existing issue with a title search and an exact match

- **Choice:** `gh issue list --repo prosoftsolutions-cloud/slicewright --state all --search "<title> in:title" --json number,title,url`, keeping only an issue whose title equals the follow-up's title; `gh issue create` otherwise; `gh issue view <number> --repo …` on each as the check.
- **Why:** GitHub's search is fuzzy, so the exact compare prevents a false match; the search keeps the list short; each command stands on its own, as the deploy skill requires.
- **Alternatives:** list every issue once and compare: fine today, fails past the list limit. Search only: a fuzzy match would skip a follow-up that only resembles an old issue.

### D10 The research page's name is the slice's title as a slug, with the slug rule spelled out

- **Choice:** the `research` knowledge agent's context says: `<name>` is the title from `status.md` in lowercase, where words are runs of letters and digits and everything else separates them, joined with `-`, the way consolidate names a records folder for a slice without an id. So this slice's title would give `research-flow-a-slice-research-stage-and-a-research-pipeline`, which is also how intake named its branch.
- **Why:** R10.7 wants the same page on a later consolidation, and a stated rule gives two runs the same name.
- **Alternatives:** name the page from the id: the spec names the title, and a title says what the page is about. Leave the rule to the agent: two consolidations could disagree on punctuation.

### D11 The `adr` agent writes at most one record, and only on a decision

- **Choice:** its context says: one new record when the `Decision:` line under Recommendation in `research.md` is filled and doesn't start with `none`; its context from the conclusions, the decision as the person wrote it, the other options as the alternatives with why each lost, the consequences and a link to the research page this slice staged under `architecture/research/`; a replaced record marked superseded; nothing otherwise. `results-review` writes `Decision: none: <why>` when no decision was taken, so "starts with `none`" is the one rule the writer, the `adr` agent and the `research` page agent share.
- **Why:** AC11 wants a record exactly when a decision other than `none` was written, and `none: <why>` is neither empty nor exactly `none`, so the rule must name the prefix. Linking to the staged page saves the `adr` agent from re-deriving the slug: it runs after the `research` agent, so the page is staged when it starts.
- **Alternatives:** reuse `config.json`'s `adr` context, "each significant decision in design.md": there is no `design.md`, and it would invent records.

### D12 `start-slice.sh` parses its options in one loop and builds the request string

- **Choice:** a `while`/`case` loop over the arguments right after `cd "$repo"`, where `--config` takes the next argument, any other option is a usage error, and a second number is a usage error; then the name rule; the file check after the stable plugin validates; then `request=/slice:new`, extended with ` --config <name>` and ` <number>` when given, and one `exec` with the request, or the bare `exec` without one.
- **Why:** POSIX sh has no `getopts` for long options, and the loop is the usual form; the request string replaces four `exec` branches with one; the usage error comes before any step, as R11 asks.
- **Alternatives:** `--config=<name>`: a second form to document and test. `getopts` with a short `-c`: the spec names `--config`.

### D13 `defaults.jq` takes an optional base instead of a second jq program

- **Choice:** `defaults.jq` gains a `merge` def and a first expression that merges the input onto `$ARGS.named.base[0]` when `--slurpfile base` was given, else uses the input as it is. The `configs` check calls it with `--slurpfile base "$plugin/defaults.json"` on each configuration file. The `defaults` check's call is unchanged.
- **Why:** jq can't `include` `defaults.jq`, so a wrapper would need the rules moved into a library and two more files. One file holds every rule, as the testing page says, and each configuration is one call.
- **Alternatives:** a `merge.jq` whose output is fed to `defaults.jq` through a here-document: one more file and two calls per configuration. A library `pipeline.jq` with two two-line wrappers: three files for one rule set.

### D14 The merge removes a key on `null`, as the runner does

- **Choice:** the runner's full rule: objects merge key by key at any depth, any other value is replaced, and `null` removes the key. jq's `*` isn't used, because it keeps the `null`.
- **Why:** the runner's own text includes the removal, and a project that drops a key with `null` must not get a false `FAIL`. Today it changes no verdict: `defaults.jq` treats `null` like a missing key for `next`, `onError`, `choices` and a stage's `skill`; the two would differ only for a `null` under `sharedParams` meant to remove a `skill` or `activeSlicePath`, which `*` would flag wrongly. Neither configuration has a `null` today.
- **Alternatives:** `*`: four lines shorter, and wrong on that case.

### D15 The `static/configs` case copies only `research.json` of `.slicewright/`, and `static/checker` also asserts `PASS configs`

- **Choice:** the new case copies `.claude-plugin`, `plugins`, `tests/static.sh`, `tests/static` and `.slicewright/research.json` into its copy, sets the `research` stage's `skill` to `slice:no-such-skill` with jq, runs the copy's `static.sh`, and expects a `FAIL` line containing `research.json: stage research: `. The `static/checker` case gains one line, `need_line "PASS configs"`, because its copy has no `.slicewright/`.
- **Why:** the check reads the configurations from `static.sh`'s own repo, so, as for `static/checker`, the copy must be a repo. Copying only `research.json` keeps the case about that file. The one line turns AC13's "no `.slicewright/` folder" clause from a hand check into a repeatable one, without adding a case, so R12's "one case" still holds.
- **Alternatives:** copy the whole `.slicewright/`: brings `stable/`, a worktree, and `slices/`. A second case for the no-folder path: the spec asks for one case. The no-folder path checked by hand only: one line proves it.

### D16 `/slice:configure --config <name>` checks the three files in step 4.1 and creates nothing for another name

- **Choice:** the arguments paragraph defines `<file name>` and `<local variant>` with the runner's rule; step 2 applies only to `config.json`; step 4.1 lists the three files of the name and stops, naming them, when none exists; step 3 keeps loading "as in step 4.1", so the stop happens there too; step 3.1 writes the mapping into `.slicewright/<file name>` only when that file exists, and otherwise says where the mapping belongs and changes nothing.
- **Why:** one loading rule serves both steps, as today; the stop comes before anything is written, so "changes nothing" holds; with `--permissions`, steps 2 and 3 are skipped, so the check must live in 4.1; and "creates no file" must hold in step 3.1 too, for a configuration that exists only in `~/.slicewright/`.
- **Alternatives:** a separate check step after step 1: a second place that names the files.

## Contracts

### 1. `plugins/slice/skills/research/SKILL.md`

Frontmatter:

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
  - `spec.md`: the questions are its requirements, `R<n>`; the scope names the sources in and out; each acceptance criterion says what a good answer to its question contains; the constraints hold the rules of evidence for this topic. Missing: `NO_SPEC`. An open question with `Blocks design: yes`: `SPEC_NOT_READY`, naming it.
  - `input.md`: the request and the decisions recorded with it.
  - `research.md` from an earlier run, when it exists: the rerun rules of D5 and D6.
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

### 2. `.slicewright/research.json`

Top level: `pipeline` only (D8). The two contexts marked verbatim are copied from `config.json`, read with `jq -r '.pipeline[] | select(.name=="intake") | .params.context' .slicewright/config.json` and the same for `release`, so that AC10's equality holds byte for byte. The `index` context is `config.json`'s index context verbatim, with one sentence added at its end.

```json
{
  "pipeline": [
    {
      "name": "intake",
      "skill": "slice:intake",
      "executionMode": "fork",
      "params": { "context": "<config.json's intake context, verbatim>" }
    },
    {
      "name": "clarify",
      "skill": "slice:clarify",
      "executionMode": "fork",
      "params": {
        "context": "This slice is a research topic, not a feature, so fill the spec template this way. The requirements are the research questions, one question per requirement, each concrete enough that an answer can be judged right or wrong. Each acceptance criterion says what a good answer to its question contains, the evidence it needs, and when it is good enough. Under Scope, Changes lists the areas the topic covers, and Out of scope what it leaves alone; both say which kinds of sources are in and which are out. The constraints hold the rules of evidence for this topic, such as the versions or dates that matter and the sources that don't count. Follow-up slices are later research. Leave out what a feature spec has and a research topic doesn't, such as the paths that will change.",
        "reviewAgents": [
          {
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "Check the research questions for: a question without what a good answer contains; a scope that doesn't cover every question, or doesn't say which sources are in and out; a question the project's documentation or code already answers; a requirement that holds two questions; an open question without a recommended answer."
          }
        ]
      }
    },
    {
      "name": "questions-review",
      "skill": "slice:human",
      "executionMode": "inline",
      "params": {
        "files": ["spec.md", "input.md"],
        "context": "Present spec.md for approval as the research brief: the questions, the scope with the areas and the sources in and out, and what a good answer to each question contains, with a short summary of clarify's latest entry in design-reviews.md: issues fixed, issues rejected and why, and reviews that didn't run. Walk the user through its open questions, then ask them to confirm the assumptions. Apply each answer to the questions and acceptance criteria it affects, keep the spec's format, remove a question from Open questions once it is answered, and remove that section when it is empty. The user decides whether to approve the questions. When approved, append a '## Session summary' section to input.md, replacing an earlier one and never changing the text above it: the decisions, each question with its answer, the assumptions the user confirmed, anything still open, and a last line 'See spec: spec.md'."
      }
    },
    {
      "name": "research",
      "skill": "slice:research",
      "executionMode": "fork",
      "onError": "results-review",
      "params": {
        "context": "The project's own knowledge beyond the documentation: the plugin's code under plugins/slice, this repo's configurations in .slicewright/config.json and .slicewright/research.json, and the records of earlier slices in .slicewright/slices/, found through .slicewright/slices/index.md. Trust, from most to least: the project's own code and documentation; the primary source for a matter, such as a tool's official documentation, its source code, a standard, or the author's own text; a secondary source that reports it, such as an article or a discussion; a vendor's marketing. A source the spec rules out is not read. Cite a page as its link with the date it was read, `<link> (read <YYYY-MM-DD>)`, and a file in the project as its path, with the line or the section when it helps. Evidence is what the cited source says, as a short quote or a fact taken from it, or what the agent checked itself, with the command or the step and what it showed. A summary from memory, and a claim without a source, are not evidence.",
        "researchAgents": [
          {
            "name": "web",
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "Search the web for each question and read the primary sources you find: official documentation, source code, standards and the authors' own texts. Prefer a primary source over a page that reports it, and read the page itself, never only a search result's summary."
          },
          {
            "name": "claude-code",
            "agent": "claude-code-guide",
            "executionMode": "fork",
            "context": "Answer what concerns Claude Code, its plugins, skills, hooks, subagents and settings, the Claude Agent SDK and the Claude API, from their documentation. For a question outside these, answer nothing found."
          }
        ],
        "reviewAgents": [
          {
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "Check research.md for: an answer without evidence, or a claim whose cited source doesn't say it, opening the source to check; a source the spec rules out, or a question of the spec with no answer; evidence that disagrees without the disagreement noted; a confidence the evidence doesn't justify; an option without trade-offs; a recommendation that doesn't follow from the conclusions; an open question without a recommended answer."
          }
        ]
      }
    },
    {
      "name": "results-review",
      "skill": "slice:human",
      "executionMode": "inline",
      "params": {
        "files": ["research.md", "input.md"],
        "choices": { "accept": "file-issues", "more-research": "research", "re-scope": "clarify", "drop": null },
        "context": "Read status.md first. When its latest research row is failed, say so first, with the reason from its Log, say that accept needs a finished research so only more-research, re-scope and drop apply now, and say that a failure in the spec itself, NO_SPEC or SPEC_NOT_READY, is fixed through re-scope, not more-research. When research.md is missing, present only that failure. Otherwise present research.md in your own words: each answer with its confidence, the conclusions, the options, the recommendation and the follow-ups, with a short summary of research's latest entry in design-reviews.md: issues fixed, issues rejected and why, and reviews that didn't run. Walk the user through the open questions. For each one answered, apply the answer where the question says it affects, keep the format, remove the question from Open questions, remove that section when it is empty, and add one line under '## Decisions', creating that section after Recommendation when it is missing: '- <the question>: <the answer>'. Ask for the decision on the recommendation and write it on its 'Decision:' line, as the decision in the user's words, or 'none: <why>'. For each follow-up, ask on its own whether to file it as an issue, and write 'Decision: file' or 'Decision: no issue' on its Decision line. Then the user chooses: accept, only when the recommendation and every follow-up have a decision; more-research, after writing each of the user's requests as one line under '## Review notes' in research.md, naming the question or the section it concerns, and creating that section at the end when it is missing; re-scope, after appending a '## Re-scope' section to input.md with the user's reasons and the new direction, never changing the text above it; drop to end the run."
      }
    },
    {
      "name": "file-issues",
      "skill": "slice:deploy",
      "executionMode": "fork",
      "params": {
        "context": "File the follow-ups of research.md whose Decision line is 'file' as issues of prosoftsolutions-cloud/slicewright on GitHub. A follow-up is one entry under '## Follow-ups', `- **F<n>** <title>: <what, and why it matters>`, followed by its Decision line; its title is the text between the id and the first colon. For each: look for an issue with the same title, open or closed, with `gh issue list --repo prosoftsolutions-cloud/slicewright --state all --search \"<title> in:title\" --json number,title,url`, and keep only an issue whose title equals the follow-up's title. When there is none, create one with `gh issue create --repo prosoftsolutions-cloud/slicewright --title \"<the follow-up's title>\" --body \"<its text, why it matters, and where it comes from: the slice's title from status.md and, when input.md has one, its source issue>\"`. The target is the repository prosoftsolutions-cloud/slicewright on GitHub. The endpoint is the list of issue URLs, created or found, each with its follow-up's id. The check is `gh issue view <number> --repo prosoftsolutions-cloud/slicewright` on each. With no follow-up marked file, record that there was nothing to file, with no endpoint, and return ok."
      }
    },
    {
      "name": "consolidate",
      "skill": "slice:consolidate",
      "executionMode": "fork",
      "params": {
        "archivePath": "./.slicewright/slices",
        "knowledgeAgents": [
          {
            "name": "research",
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "The research page `architecture/research/<name>.md`, where <name> is the slice's title from status.md in lowercase: words are runs of letters and digits, everything else separates them, and they are joined with `-`, the way a records folder is named for a slice without an id, so that a later consolidation finds the same page. Its frontmatter: `type: research`, `date: <the date part of created in status.md>`, and `source: <the source in input.md>` when there is one. Its content, from research.md: the questions, each with its answer, its evidence with sources and confidence, and its disagreements; the conclusions; the options; the recommendation with the decision taken, where a Decision line that starts with 'none' means no decision was taken, shown with its reason; the decisions from the reviews; the open questions; and the follow-ups, each with the link of its issue from the entry in deployments.md whose endpoint lists issue URLs, the latest such entry when there are several, or 'not filed'. When the page exists from an earlier consolidation, update it under the same name instead of adding another."
          },
          {
            "name": "adr",
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "Decision records in `architecture/decisions/`: when the Decision line under Recommendation in research.md is filled and doesn't start with 'none', one new record, `NNNN-<title>.md`, numbered after the last one, in the form of the records there: its context from the conclusions, the decision as the person wrote it, the other options as the alternatives with why each lost, its consequences, and a link to the research page this slice staged under `architecture/research/`. When the decision replaces an earlier record, mark that record as superseded and link the two. Write nothing otherwise: an empty Decision line, or one that starts with 'none', is no decision."
          },
          {
            "name": "index",
            "agent": "general-purpose",
            "executionMode": "fork",
            "context": "<config.json's index context, verbatim> A folder whose `index.md` is new is listed under Contents in its parent folder's `index.md`, with a one-line description."
          }
        ]
      }
    },
    {
      "name": "release",
      "skill": "slice:deploy",
      "executionMode": "fork",
      "params": { "context": "<config.json's release context, verbatim>" }
    }
  ]
}
```

Flow: `intake` → `clarify` → `questions-review` → `research` (`onError` → `results-review`) → `results-review` (`accept` → `file-issues`, `more-research` → `research`, `re-scope` → `clarify`, `drop` ends) → `file-issues` → `consolidate` → `release` → end. The runner's section 2 passes: every `skill` is a folder, every `onError` and choice names a stage, no stage sets `activeSlicePath`, no unknown key.

The permission rules this pipeline needs, which `/slice:configure --config research --permissions` proposes from its existing rules: `Skill(slice:intake)`, `Skill(slice:clarify)`, `Skill(slice:human)`, `Skill(slice:research)`, `Skill(slice:deploy)`, `Skill(slice:consolidate)`, `Skill(slice:run)`, `Skill(slice:tracking)`, `Bash(date:*)`; from the two `slice:deploy` contexts `Bash(gh issue list:*)`, `Bash(gh issue create:*)`, `Bash(gh issue view:*)`, `Bash(gh pr create:*)` and the push; and from consolidate the copy and version control commands. No `Skill(slice:design)`, `plan`, `implement`, `review`, `test` or `diagnose` (AC15).

### 3. The runner, `plugins/slice/skills/run/SKILL.md`

- `allowed-tools`: `Skill(slice:research)` added after `Skill(slice:consolidate)`.
- The **Continue** bullet of section 3, `new`, step 1, becomes:

  > **Continue:** when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file you loaded, load that configuration as in section 1, check it as in section 2, and say so. Then go on as in `resume` below. Say that the request typed with `/slice:new` is not used.

  Section 1 and **Start new** are unchanged. With `--config` given, the condition fails and the given configuration stays.

### 4. `plugins/slice/skills/configure/SKILL.md`

- Frontmatter: `argument-hint: "[--config <name>] [--permissions]"`; `allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/**)`.
- The arguments paragraph:

  > The arguments may hold `--config <name>` and `--permissions`, in either order. With `--permissions`, skip steps 2 and 3 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--config <name>] [--permissions]`.
  >
  > The configuration's file name is `<name>` from `--config`, with `.json` added when it doesn't end in it. Without `--config`, it is `config.json`. A name must be a plain file name: if it contains `/` or `..`, that is a usage error too. Its local variant replaces the ending `.json` with `.local.json`. Below, `<file name>` and `<local variant>` mean these.

- Step 2: only for `config.json`: as today. With another name, create no file: the configuration must already exist where step 4.1 reads it.
- Step 3.1, the mapping: "write it into `.slicewright/<file name>` when that file exists; otherwise say that the mapping belongs in the file that holds the configuration, and change nothing", so that a configuration that exists only in `~/.slicewright/` never makes the command create a project file.
- Step 4.1: the four files become `${CLAUDE_PLUGIN_ROOT}/defaults.json`, `~/.slicewright/<file name>`, `.slicewright/<file name>`, `.slicewright/<local variant>`, followed by: "With a name other than `config.json`, at least one of files 2 to 4 must exist. Otherwise stop, say which three files you looked for, and change nothing."
- Step 5: "the configuration: its file name, and whether you created `.slicewright/config.json`, changed it or left it as it was".
- Step 4.2 is unchanged: it already yields `Skill(slice:research)` from the stage's skill and the `gh issue` rules from file-issues' context, because for a `slice:deploy` stage it proposes "the commands its context names".

### 5. `start-slice.sh`

The header comment: usage `sh start-slice.sh [--config <name>] [<issue number>]`; "With `--config <name>`, the session starts with `/slice:new --config <name>`, and `.slicewright/<name>.json` must exist." The argument parsing, in place of the current six lines after `cd "$repo"`:

```sh
USAGE='usage: sh start-slice.sh [--config <name>] [<issue number>]'
config=
config_given=
issue=
issue_given=
while [ "$#" -gt 0 ]; do
    case $1 in
        --config)
            if [ "$#" -lt 2 ]; then
                cannot_run "--config needs a name; $USAGE"
            fi
            config=$2
            config_given=yes
            shift 2
            ;;
        -*)
            cannot_run "unknown option $1; $USAGE"
            ;;
        *)
            if [ -n "$issue_given" ]; then
                cannot_run "too many arguments; $USAGE"
            fi
            issue=${1#\#}
            issue_given=yes
            case $issue in
                *[!0-9]*) cannot_run "not an issue number: $1; $USAGE" ;;
            esac
            shift
            ;;
    esac
done
if [ -n "$config_given" ]; then
    case $config in
        ''|*/*|*..*) cannot_run "not a configuration name: '$config'; $USAGE" ;;
    esac
    case $config in
        *.json) config_file=.slicewright/$config ;;
        *) config_file=.slicewright/$config.json ;;
    esac
fi
```

After `say "the stable plugin validates"`:

```sh
if [ -n "$config_given" ] && [ ! -f "$config_file" ]; then
    fail "the configuration $config_file doesn't exist: add it, or run without --config"
fi
```

The note: `cfg=$(sed -n 's/^config: *//p' "$SLICE/status.md" | sed -n 1p)`, then `config.json` when empty, and the note says `holds a slice: "$title", at $stage ($status), with $cfg`. The end, in place of the two `exec` branches:

```sh
request=/slice:new
if [ -n "$config_given" ]; then
    request="$request --config $config"
fi
if [ -n "$issue" ]; then
    request="$request $issue"
fi
if [ "$request" != /slice:new ]; then
    say "starting Claude with the stable plugin and $request"
    exec claude --plugin-dir "$plugin" "$request"
fi
say "starting Claude with the stable plugin"
exec claude --plugin-dir "$plugin"
```

Behavior, per AC12: `--config research 17` → `/slice:new --config research 17`; `--config research` → `/slice:new --config research`; `--config a/b`, `--config ..`, `--bogus` and `--config ''` → exit 2 with the usage line, before the tool checks; `--config missing` → exit 1 naming `.slicewright/missing.json`, after the stable plugin validated; `17` and no arguments → as today. `dash -n start-slice.sh` passes. No agent runs the script: it is checked by hand.

### 6. `.claude/settings.json`

Append to the end of `permissions.allow`, in this order: `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)`, `Bash(gh issue view:*)`. Nothing else changes: `jq -S` of the two versions differs only in these four lines.

### 7. The static level and the self-test

`tests/static/defaults.jq`: the header comment says it checks a configuration object, a plugin's `defaults.json` or a project configuration merged onto it, with the two usages. Before `obj as $root`:

```jq
# The runner's merge: objects merge key by key at any depth, any other value from $over replaces
# the one in $base, and a null in $over removes the key.
def merge($base; $over):
  if ($base | type) == "object" and ($over | type) == "object" then
    reduce ($over | keys_unsorted[]) as $key ($base;
      if $over[$key] == null then del(.[$key]) else .[$key] = merge(.[$key]; $over[$key]) end)
  else $over end;

(if $ARGS.named | has("base") then merge($ARGS.named.base[0]; .) else . end)
| obj as $root
```

`tests/static.sh`: the header comment names five checks. Between the `defaults` and `skills` checks:

```sh
# configs: every project configuration of this repo, .slicewright/<name>.json except *.local.json,
# merged onto the plugin folder's defaults.json the way the runner merges them, checked with the same
# rules as defaults. With no such file, the check passes.
start=$problems
for file in "$repo"/.slicewright/*.json; do
    case $file in
        *.local.json) continue ;;
    esac
    if [ -f "$file" ]; then
        output=$(jq -r --argjson skills "$skills" --slurpfile base "$plugin/defaults.json" -f "$repo/tests/static/defaults.jq" "$file" 2>/dev/null)
        if [ "$?" -eq 0 ]; then
            fail_lines "configs: $file: " "$output"
        else
            fail "configs: $file: does not parse"
        fi
    fi
done
pass_unless_failed configs "$start"
```

`$skills` is the list the `defaults` check built. Output lines: `FAIL configs: <file>: stage <name>: <problem>`, `FAIL configs: <file>: sharedParams: <problem>`, `FAIL configs: <file>: pipeline: missing or empty`, `FAIL configs: <file>: does not parse`; the problems are the ones the testing page lists for `defaults`. `PASS configs` when no line was added, including when the glob matches nothing.

`tests/selftest.sh`: the header comment says a static case breaks a copy of `plugins/slice`, or of the repo's parts a check needs. `static/checker` gains `need_line "PASS configs"` right before its `static_fails` line. After it:

```sh
# static/configs: a project configuration whose stage names no skill folder. The
# configs check reads the configurations from static.sh's own repo, so the case
# copies the manifests, the plugin, the static checks and .slicewright/research.json
# into COPY, breaks the copy's research.json, and runs the copy's static.sh.
begin static/configs
COPY="$W/$SLUG"
step "make the repo copy's tests folder" mkdir -p "$COPY/tests"
step "make the repo copy's .slicewright folder" mkdir -p "$COPY/.slicewright"
step "copy .claude-plugin" cp -R "$REPO/.claude-plugin" "$COPY/.claude-plugin"
step "copy plugins" cp -R "$REPO/plugins" "$COPY/plugins"
step "copy static.sh" cp "$REPO/tests/static.sh" "$COPY/tests/static.sh"
step "copy tests/static" cp -R "$REPO/tests/static" "$COPY/tests/static"
step "copy research.json" cp "$REPO/.slicewright/research.json" "$COPY/.slicewright/research.json"
edit jq '(.pipeline[] | select(.name == "research") | .skill) = "slice:no-such-skill"' "$COPY/.slicewright/research.json" "$REPO/.slicewright/research.json"
if [ -z "$WHY" ]; then
  OUT="$W/$SLUG.out"
  sh "$COPY/tests/static.sh" </dev/null >"$OUT" 2>&1
  STATUS=$?
fi
static_fails 'research.json: stage research: '
report_case
```

16 cases; the last line `selftest: passed, 16 cases`. Both scripts pass `dash -n`. The existing `static/…` cases, which run the repo's `static.sh` on a copy of the plugin, now also check the repo's own `.slicewright/*.json` against the copy's skills; none of their breaks touches a skill folder's name, so their verdicts don't change.

### 8. Documentation, README and AGENTS.md

- `slice/docs/overview/structure.md`: the skills bullet adds that `research`, which answers a spec's questions from sources with cited evidence, isn't in the default pipeline, and that `.slicewright/research.json` runs it. A new bullet: `.slicewright/research.json` is the research pipeline of this repo, loaded with `--config research`; it repeats intake's and release's contexts from `.slicewright/config.json`, because a configuration is loaded instead of `config.json`, not on top of it. The script bullet: `sh start-slice.sh [--config <name>] [<issue number>]` starts the session with `/slice:new`, with `--config <name>` and the issue number when given, after checking that `.slicewright/<name>.json` exists; `--config research` runs the research pipeline.
- `slice/docs/overview/testing.md`: "Its five checks, in order", with `configs` after `defaults`: every `.slicewright/<name>.json` of the repo, except `*.local.json`, merged onto the folder's `defaults.json` the way the runner merges configurations (objects key by key, any other value replaced, `null` removes a key), and checked with the same rules as `defaults`, by `tests/static/defaults.jq` with the defaults as its base; each problem names the file and the stage, `FAIL configs: <file>: stage <name>: <problem>`; with no such file, the check passes. The self-test bullets: `static/configs` breaks a copy of `.slicewright/research.json`; the check reads the configurations from `static.sh`'s own repo, so the case copies the manifests, the plugin, the static checks and `research.json`, and runs the copy's `static.sh`. The `static/checker` row's "Must show" adds `PASS configs`, because its copy has no `.slicewright/`. The new row: `static/configs` | stage `research`'s `skill` set to `slice:no-such-skill` in `.slicewright/research.json`, in a copy of the repo's manifests, plugin, static checks and `research.json`, whose own `static.sh` runs | `research.json: stage research`. "The 16 cases", `selftest: passed, 16 cases` and `failed, <k> of 16 cases`. "Adding a static check", step 1: a rule in `defaults.jq` applies to the defaults and to every project configuration.
- `README.md`: Quick start: "`/slice:new`, `/slice:resume` and `/slice:configure` take `--config <name>` to use another configuration." Concepts, the agents list: "research agents that answer questions from sources (`researchAgents`)". Default pipeline, a closing paragraph: the plugin also ships `slice:research`, a stage that answers the questions in a spec from sources, with cited evidence and a confidence, and writes `research.md` for a person to decide on; it isn't in the default pipeline, and the research pipeline below runs it. Recipes, in place of "Another pipeline": `--config <name>` loads `<name>.json` from the same four places instead of `config.json`, so the file repeats what it needs from `config.json`; this repo runs research topics with its research pipeline, `.slicewright/research.json`: `intake`; `clarify` writes the questions; **questions-review** agrees them with you; `research` answers them from sources with cited evidence; **results-review** puts the answers, the recommendation and the follow-ups to you, with accept, more research, re-scope or drop; `file-issues` files the follow-ups you chose as issues; `consolidate` publishes a research page and, when you took a decision, a decision record; `release` opens the pull request. `sh start-slice.sh --config research <issue number>` starts it with `/slice:new --config research <issue number>`, and `/slice:configure --config research --permissions` proposes its permission rules.
- `AGENTS.md`: the script line becomes `sh start-slice.sh [--config <name>] [<issue number>]` prepares the working copy for a new slice and starts Claude Code with the stable plugin; `--config research` runs the research pipeline in `.slicewright/research.json`; the rest as today. "Checking a change": `sh tests/static.sh` checks the plugin and the project's configurations without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, every `.slicewright/<name>.json` merged onto it, and each skill's frontmatter.

## Risks

- `research.json` lands before the research skill folder → the `configs` check, which the quality gates run between waves and the `research.json` task's own Verify runs, and the runner all report `skill "slice:research" names no skill folder`. The plan puts the skill in an earlier wave than `research.json`.
- The two verbatim contexts drift from `config.json` → the README and `structure.md` say why they are repeated, and AC10 compares them at review. A check that compares them is out of scope.
- `sh tests/static.sh .slicewright/stable/plugins/slice` fails its `configs` check until this slice is merged, because the stable plugin has no `research` skill folder → nothing runs `static.sh` on the stable plugin: `start-slice.sh` and intake use `claude plugin validate`. The testing page says the check is against the given plugin folder.
- The `index` agent misses the new folder → its one added sentence names the rule; AC11 checks the three listings by hand.
- `gh issue list --search` misses or mismatches → the exact title compare after the search; `deployments.md` lists every URL with its follow-up's id, which the research page shows.
- `WebFetch` and `WebSearch` prompt for permission during a research run; R9's four rules don't cover them, and `/slice:configure` doesn't propose them → the research pipeline always has a person at the session, and a denied fetch becomes a "source not reached" assumption, not a failure.
- The `claude-code-guide` agent type is missing on another machine → R3's failure rule: retried once, then the stage covers its angle and says so in the result.
- A research question the project's own documentation already answers wastes a run → clarify's reviewer rule, and the brief carries what the documentation says as `sure` evidence.
- The `static/…` self-test cases now read the real repo's `.slicewright/*.json` → by design, the check is of the repo; `*.local.json` is excluded, so a personal file never fails it.
- An agent's confidence is self-reported → the merge takes the lowest level of the evidence an answer depends on, and the reviewer checks "a confidence the evidence doesn't justify" by opening the source.
- A `defaults.json` that doesn't parse makes the `configs` check name the configuration file → the `defaults` check runs first and names `defaults.json`.
- Bash-only syntax in a script → each task's Verify runs `dash -n` on the changed script, and `sh tests/selftest.sh` runs the self-test.

## Assumptions

- `research.json`, `.claude/settings.json` and `start-slice.sh` fit the `infrastructure` task type: its description is "infrastructure as code, environments, pipelines and deployment configuration", its context checks a change offline with the tool's own validation (`sh tests/static.sh`, `jq`, `dash -n`), and the `plugin` type's description doesn't cover these files. If the plan returns `NO_TASK_TYPE`, the person adds a task type in `.slicewright/config.json`, which this slice doesn't touch.
- `research.md`'s open questions have the four parts R4 lists, why it matters, options, recommended and affects, and no "Blocks" line: `results-review` walks the person through every question, so none is deferred.
- The research reviewer may open web sources: a `general-purpose` agent has `WebFetch`, and R10.4 says the reviewer opens the source.
- `claude plugin validate` accepts a new skill folder with the frontmatter in Contract 1, as it accepts the eleven existing ones.
- AC11's hand run can't happen inside this slice: `start-slice.sh` starts the stable plugin at `origin/master`, which has no research skill until this slice is merged, and intake requires `master` clean at `origin/master`. The person decided at the design review that AC11 is checked by the first research slice after the merge, as the first real run; this slice's test stage runs the smoke test only.

## Requirements coverage

| Requirement | Covered by |
|---|---|
| R1 | Contract 1 (frontmatter, section 0, the file rule); D1 |
| R2 | Contract 1, section 1 |
| R3 | Contract 1, sections 2 and 3, the agent prompt; D2 |
| R4 | Contract 1, section 4 and the template; D3, D4 |
| R5 | Contract 1, section 1; D5, D6 |
| R6 | Contract 1, section 5 |
| R7 | Contract 1, section 6 |
| R8 | Contract 3; D7 |
| R9 | Contract 6 |
| R10 | Contract 2; D8, D9, D10, D11 |
| R11 | Contract 5; D12 |
| R12 | Contract 7; D13, D14, D15 |
| R13 | Contract 8 |
| R14 | Contract 4; D16 |
| AC1 | Contract 1's frontmatter, checked by the `skills` check |
| AC2 | Contract 1, section 1 and the error result |
| AC3 | Contract 1, sections 2 and 3: the brief's three parts, the prompt's four parts, the answer form, the scale, the retry rule |
| AC4 | Contract 1's template; D3, D4 |
| AC5 | Contract 1, section 1; D5, D6 |
| AC6 | Contract 1, section 5 and the review prompt |
| AC7 | Contract 1, section 6 |
| AC8 | Contract 3 |
| AC9 | Contract 6 |
| AC10 | Contract 2: the eight stages, the two verbatim contexts |
| AC11 | Contract 2; checked by the first research slice after the merge, as decided at the design review |
| AC12 | Contract 5 |
| AC13 | Contract 7; D13, D14, D15 |
| AC14 | Contract 8 |
| AC15 | Contract 4; Contract 2's list of rules |
