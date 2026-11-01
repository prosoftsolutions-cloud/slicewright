---
id: T04
title: Research pipeline, permissions and start script
type: infrastructure
depends: [T01, T03]
covers: [R9, R10, R11, AC9, AC10, AC11, AC12]
questions: [Q1]
---

# T04 Research pipeline, permissions and start script

## Goal

Add the research pipeline `.slicewright/research.json` exactly as the design's Contract 2 gives it, append the four permission rules to `.claude/settings.json`, and give `start-slice.sh` the `--config <name>` option, the configuration file check and the leftover note's configuration.

## Context

### Requirements

- **R9** `.claude/settings.json` allows `Skill(slice:research)`, and the `gh issue` commands the research pipeline runs, in `file-issues` and in intake: `Bash(gh issue create:*)`, `Bash(gh issue list:*)` and `Bash(gh issue view:*)`. Nothing else in the file changes.
- **R10** `.slicewright/research.json` holds the research pipeline, loaded with `/slice:new --config research`. It has `pipeline` and, only where it must differ from the defaults, `sharedParams`; `activeSlicePath` stays `./slice`. It passes the runner's own check (its section 2). Its stages, in order:
  1. `intake`: `slice:intake`, `fork`, with the same context as `config.json`'s intake stage.
  2. `clarify`: `slice:clarify`, `fork`. Its context says how a research topic fills the spec template: the requirements are the research questions, one each, concrete enough that an answer can be judged; each acceptance criterion says what a good answer to its question contains, the evidence it needs, and when it is good enough; the scope lists the areas the topic covers, and the sources in and out; the constraints hold the rules of evidence for this topic; follow-up slices are later research. Its one review agent checks the questions: each has what a good answer contains, the scope covers them, none is answered by the project's documentation or code already, none is two questions, and every open question has a recommended answer.
  3. `questions-review`: `slice:human`, `inline`, `files: ["spec.md", "input.md"]`, no `choices`. Its context presents the questions, the scope, the sources and what a good answer contains, with a summary of clarify's latest entry in `design-reviews.md`; walks the person through the open questions and the assumptions; applies the answers to `spec.md`, keeping its format and removing answered questions; the person decides whether to approve; on approval it appends a `## Session summary` to `input.md`, as `config.json`'s spec-review does.
  4. `research`: `slice:research`, `fork`, `onError: results-review`. Its context names the sources of the project's own knowledge beyond the documentation (the code, and the slice records in `.slicewright/slices/`), the order of trust between kinds of sources, how to cite (a link for a page, with the date read; a path for a file in the project), and what counts as evidence. Its `researchAgents`: `web`, a `general-purpose` agent that searches the web and reads primary sources; and `claude-code`, a `claude-code-guide` agent for anything about Claude Code, its plugins, skills, agents and the Claude API. Its one review agent checks `research.md` for: an answer without evidence, or a claim whose cited source doesn't say it (the reviewer opens the source); a source the spec rules out, or a question of the spec with no answer; evidence that disagrees without the disagreement noted; a confidence the evidence doesn't justify; an option without trade-offs; a recommendation that doesn't follow from the conclusions; an open question without a recommended answer.
  5. `results-review`: `slice:human`, `inline`, `files: ["research.md", "input.md"]`, `choices: {"accept": "file-issues", "more-research": "research", "re-scope": "clarify", "drop": null}`. Its context: when `research.md` is missing because research failed, present the failure recorded in `status.md`, say that accept needs a finished research, and say that a failure in the spec itself, `NO_SPEC` or `SPEC_NOT_READY`, is fixed through `re-scope`, not `more-research`. Otherwise present `research.md` in its own words: each answer with its confidence, the conclusions, the options, the recommendation, the follow-ups, and a summary of research's latest entry in `design-reviews.md`. Walk the person through the open questions; for each answered one, apply the answer in `research.md`, keeping its format, remove the question from Open questions, and add its question and answer as one line under `## Decisions`. Ask for the decision on the recommendation and write it on its `Decision:` line, as the decision in the person's words, or `none: <why>`. For each follow-up, ask on its own whether to file it as an issue, and write `Decision: file` or `Decision: no issue`. Then the choices: `accept`, only when the recommendation and every follow-up have a decision; `more-research`, after writing each of the person's requests as a note under `## Review notes` in `research.md`, naming the question or section it concerns; `re-scope`, after appending a `## Re-scope` section to `input.md` with the person's reasons and the new direction, never changing the text above it; `drop` ends the run.
  6. `file-issues`: `slice:deploy`, `fork`. Its context: for each follow-up in `research.md` with `Decision: file`, look for an open or closed issue of this repository with the same title with `gh issue list`, and when there is none create one with `gh issue create`: the follow-up's title, and a body with its text, why it matters, and where it comes from (the slice's title and, when `input.md` has one, its source issue). The target is this repository on GitHub, the endpoint is the list of issue URLs, created or found, each with its follow-up's id, and the check is `gh issue view` on each. With no follow-up marked `file`, the stage records that there was nothing to file and returns `ok`.
  7. `consolidate`: `slice:consolidate`, `fork`, `archivePath: "./.slicewright/slices"`, with three knowledge agents: `research` writes the research page `architecture/research/<name>.md`, where `<name>` is the slice's title from `status.md` in lowercase words joined with `-`, the way consolidate names a records folder when the slice has no id, so that a later consolidation finds the same page; its frontmatter has `type: research`, the date and the source issue when there is one; it holds the questions with their answers, evidence and confidence, the disagreements, the conclusions, the options, the recommendation with the decision taken, the decisions from the reviews, the open questions, and the follow-ups each with its issue from `deployments.md` or "not filed", and the agent updates the page when it exists from an earlier consolidation; `adr` writes one decision record in `architecture/decisions/` when the recommendation's `Decision:` line is neither empty nor `none`, numbered after the last, with the context from the conclusions, the decision, the other options as the alternatives with why each lost, the consequences, and a link to the research page, and marks a record the decision replaces as superseded; `index`, with `config.json`'s `index` context plus one rule, that a folder whose `index.md` is new is listed under Contents in its parent folder's `index.md`, so that `architecture/research/index.md` lists the page, `architecture/index.md` lists the folder, and `log.md` gets the slice's entry.
  8. `release`: `slice:deploy`, `fork`, with the same context as `config.json`'s release stage: push the branch and open or update the pull request.
- **R11** `start-slice.sh` takes `sh start-slice.sh [--config <name>] [<issue number>]`. A name that holds `/` or `..`, or is empty, and any other option, is a usage error, reported before anything runs, with the usage line. The name may end in `.json` or not, as the runner allows; the file is `.slicewright/<name>.json`, with `.json` added when the name doesn't end in it. After the working copy and the stable plugin are prepared, and before Claude starts, the script checks that the file exists, and fails with a message naming it when it doesn't. With `--config`, the session starts with `/slice:new --config <name> <issue number>`, or `/slice:new --config <name>` without an issue number, so the runner asks for the request. Without `--config`, the script behaves as today. The note about a leftover slice names the configuration from the `config:` line of `slice/status.md`, or `config.json` when the line is absent.

### Acceptance criteria

- **AC9** (R9) Given `.claude/settings.json` at the end of this slice, when it is compared with the version before, then the only change is that `permissions.allow` gained `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)` and `Bash(gh issue view:*)`.
- **AC10** (R10) Given `.slicewright/research.json`, when `/slice:new --config research` starts in this repo, then the runner reports no pipeline problem and names no stage whose skill is `TBD`; and when the file is read, then its stages are exactly the eight of R10 in that order, each with the skill, mode, `next`, `onError`, `files`, `choices` and agents R10 gives, `intake`'s context equals `config.json`'s, and `release`'s context equals `config.json`'s.
- **AC11** (R10) Given a research topic filed as an issue of this repository, when `sh start-slice.sh --config research <issue>` runs and the person answers each gate, then the run passes through every stage of R10 in order, `slice/status.md` ends with `status: done` and an empty `next`, the research page exists under `doc/architecture/research/` and is listed in that folder's `index.md`, in `architecture/index.md` and in `log.md`, a decision record exists exactly when the person wrote a decision other than `none`, one issue exists for each follow-up marked `file` and none for the others, the slice's records are in `.slicewright/slices/` with an index entry, and the branch has a pull request. Per Q1 (below), this run happens in the first research slice after the merge, not in this slice.
- **AC12** (R11) Given a clean working copy, when `sh start-slice.sh --config research 17` runs, then Claude starts with `/slice:new --config research 17`; when `sh start-slice.sh --config research` runs, then Claude starts with `/slice:new --config research`; when `sh start-slice.sh --config a/b` or `sh start-slice.sh --config ..` or `sh start-slice.sh --bogus` runs, then it exits 2 with the usage line and runs no other step; when `sh start-slice.sh --config missing` runs, then it exits 1 with a message naming `.slicewright/missing.json` after the working copy was prepared, and Claude doesn't start; when `sh start-slice.sh 17` runs, then it behaves as before this slice. Given `slice/status.md` with `config: research.json`, when the script runs, then its note names `research.json`; given one without a `config:` line, then its note names `config.json`.

### Constraints

- `start-slice.sh` never runs from an agent: it switches branches and starts a session. Its new option is checked by hand by the person. This task's Verify of the script is `dash -n start-slice.sh` and a read-through against the contract, never a run.
- The scripts keep the rules in `doc/architecture/concepts.md`: POSIX `sh` only (no `local`, arrays, `[[ ]]`, `sed -i`), `dash -n` clean, exit 0, 1 or 2, one source per value.
- `.slicewright/research.json` is loaded instead of `config.json`, not on top of it, so it repeats what it needs from `config.json`: intake's and release's contexts, byte for byte.
- Nothing under `.slicewright/stable/` changes. `plugins/slice/defaults.json` and `.slicewright/config.json` don't change. The research pipeline always has a person at its gates, so it never runs headless.
- The open question **Q1** of the design: AC11's hand run can't happen inside this slice, because `start-slice.sh` starts the stable plugin at `origin/master`, which has no research skill until this slice is merged. The design applies answer A: the first research slice after the merge is the first real run, and this slice's test stage runs the smoke test only. Nothing in this task changes with the other answer.

### Design decisions

- **D8 `research.json` holds only `pipeline`.** No `sharedParams`: the defaults give `activeSlicePath` `./slice` and a `knowledge` identical to `config.json`'s; the defaults' `taskTypes` come along unused.
- **D9 `file-issues` finds an existing issue with a title search and an exact match.** `gh issue list --repo prosoftsolutions-cloud/slicewright --state all --search "<title> in:title" --json number,title,url`, keeping only an issue whose title equals the follow-up's title; `gh issue create` otherwise; `gh issue view <number> --repo …` on each as the check. GitHub's search is fuzzy, so the exact compare prevents a false match.
- **D10 The research page's name is the slice's title as a slug, with the slug rule spelled out.** `<name>` is the title from `status.md` in lowercase, where words are runs of letters and digits and everything else separates them, joined with `-`, the way consolidate names a records folder for a slice without an id.
- **D11 The `adr` agent writes at most one record, and only on a decision.** One new record when the `Decision:` line under Recommendation in `research.md` is filled and doesn't start with `none`; it links to the research page this slice staged under `architecture/research/`; a replaced record is marked superseded; nothing otherwise. `results-review` writes `Decision: none: <why>` when no decision was taken, so "starts with `none`" is the one rule the writer, the `adr` agent and the `research` page agent share.
- **D12 `start-slice.sh` parses its options in one loop and builds the request string.** A `while`/`case` loop over the arguments right after `cd "$repo"`, where `--config` takes the next argument, any other option is a usage error, and a second number is a usage error; then the name rule; the file check after the stable plugin validates; then `request=/slice:new`, extended with ` --config <name>` and ` <number>` when given, and one `exec` with the request, or the bare `exec` without one. No `getopts`, no `--config=<name>` form.
- Contract 2's rule for the verbatim texts: the two contexts marked verbatim are copied from `config.json`, read with `jq -r '.pipeline[] | select(.name=="intake") | .params.context' .slicewright/config.json` and the same for `release`, so that AC10's equality holds byte for byte. The `index` context is `config.json`'s index context verbatim, with one sentence added at its end. Flow: `intake` → `clarify` → `questions-review` → `research` (`onError` → `results-review`) → `results-review` (`accept` → `file-issues`, `more-research` → `research`, `re-scope` → `clarify`, `drop` ends) → `file-issues` → `consolidate` → `release` → end. The runner's section 2 passes: every `skill` is a folder, every `onError` and choice names a stage, no stage sets `activeSlicePath`, no unknown key (the runner warns about any key outside `name`, `skill`, `executionMode`, `agent`, `args`, `next`, `onError`, `params`).
- Contract 6: append to the end of `permissions.allow`, in this order: `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)`, `Bash(gh issue view:*)`. Nothing else changes.

### Contract 2, `.slicewright/research.json`

Three string values are marked with placeholders and must be `config.json`'s text byte for byte: intake's `context`, release's `context`, and the start of the `index` knowledge agent's `context` (followed by one space and the added sentence). None of the three texts holds a double quote or a backslash, so each is pasted into the JSON string as it is.

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

### Contract 5, `start-slice.sh`

The header comment: usage `sh start-slice.sh [--config <name>] [<issue number>]`; "With `--config <name>`, the session starts with `/slice:new --config <name>`, and `.slicewright/<name>.json` must exist." The argument parsing, in place of the current lines after `cd "$repo"`:

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

Behavior, per AC12: `--config research 17` → `/slice:new --config research 17`; `--config research` → `/slice:new --config research`; `--config a/b`, `--config ..`, `--bogus` and `--config ''` → exit 2 with the usage line, before the tool checks; `--config missing` → exit 1 naming `.slicewright/missing.json`, after the stable plugin validated; `17` and no arguments → as today. `dash -n start-slice.sh` passes.

### Contract 6, `.claude/settings.json`

Append to the end of `permissions.allow`, in this order: `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)`, `Bash(gh issue view:*)`. Nothing else changes: `jq -S` of the two versions differs only in these four entries.

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- `.slicewright/research.json`: top level `pipeline` only; eight stages in this order with these names: `intake`, `clarify`, `questions-review`, `research`, `results-review`, `file-issues`, `consolidate`, `release`; the `research` stage has `"skill": "slice:research"` and `"onError": "results-review"`; `results-review` has `choices` `accept`, `more-research`, `re-scope`, `drop`; intake's and release's contexts equal `config.json`'s → used by T05 (the self-test case copies this file and sets the `research` stage's `skill` to `slice:no-such-skill` with `jq '(.pipeline[] | select(.name == "research") | .skill) = "slice:no-such-skill"'`), T06 and T07 (the documentation names the stages, the choices and the repeated contexts)
- `start-slice.sh`: the usage line `usage: sh start-slice.sh [--config <name>] [<issue number>]` and the header comment `# Usage: sh start-slice.sh [--config <name>] [<issue number>]`; `--config <name>` starts Claude with `/slice:new --config <name>` plus the issue number when given, after checking that `.slicewright/<name>.json` exists → T06, T07
- `.claude/settings.json`: `permissions.allow` ends with the four rules in Contract 6's order → nobody; AC9

**Uses:** what this task relies on, exactly as written, without changing it:

- the skill folder `plugins/slice/skills/research/SKILL.md` with `name: research`, so that `"skill": "slice:research"` passes the static check and the runner: from T01
- the `configs` check of `tests/static.sh`: `sh tests/static.sh` prints `PASS configs` when `.slicewright/research.json` merged onto `plugins/slice/defaults.json` passes, else `FAIL configs: <file>: stage <name>: <problem>`: from T03
- the `research.md` shapes the research skill writes, which this task's contexts read and write: the Recommendation section ends with a line `Decision:` (`results-review` writes `Decision: <the decision in the user's words>` or `Decision: none: <why>`); `## Decisions` lines `- <question>: <answer>` (`results-review` creates the section after Recommendation when missing); each follow-up `- **F<n>** <title>: <what, and why it matters>` followed by an indented line `Decision:` (`results-review` writes `Decision: file` or `Decision: no issue`; `file-issues` reads the title as the text between the id and the first colon); `## Review notes` lines `- <question or section>: <request>` (`results-review` writes them); the stage's error codes `NO_SPEC`, `SPEC_NOT_READY`, `WRITE_FAILED`; its review record under `## research, <time>` in `design-reviews.md`: from T01
- `.slicewright/config.json`'s `intake`, `release` and `index` contexts, read with jq: from the existing code
- `slice/status.md`'s header line `config: <file name>`, present only for a configuration other than `config.json`: from `plugins/slice/skills/tracking/SKILL.md` in the existing code
- the runner's name rule and its section 2 checks (`plugins/slice/skills/run/SKILL.md`); `slice:human`'s `files` and `choices` rules (`skills/human/SKILL.md`); `slice:deploy`'s steps and its `deployments.md` record with Revision, Target, Endpoint, Steps, Check and Outcome (`skills/deploy/SKILL.md`); `slice:consolidate`'s `archivePath`, `knowledgeAgents`, run one at a time in list order, and its records-folder naming (`skills/consolidate/SKILL.md`): from the existing code
- `gh` 2.101.0: `gh issue list` has `--repo`, `--state all`, `--search`, `--json number,title,url`; `gh issue create` has `--repo`, `--title`, `--body`; `gh issue view <number> --repo` exists; the `claude-code-guide` agent type exists in this session's agent list: from the tools on this machine

## Changes

- `.slicewright/research.json` (new). Top level `pipeline` only, no `sharedParams`. Eight stages in the order and with exactly the keys of Contract 2, 2-space indentation like `config.json`, a newline at the end. Write it with the Write tool from Contract 2's JSON, with the three placeholders replaced by `config.json`'s text byte for byte:
  - intake's `context`: the output of `jq -r '.pipeline[] | select(.name=="intake") | .params.context' .slicewright/config.json`
  - release's `context`: the output of `jq -r '.pipeline[] | select(.name=="release") | .params.context' .slicewright/config.json`
  - the `index` knowledge agent's `context`: the output of `jq -r '.pipeline[] | select(.name=="consolidate") | .params.knowledgeAgents[] | select(.name=="index") | .context' .slicewright/config.json`, then one space, then the sentence `A folder whose `index.md` is new is listed under Contents in its parent folder's `index.md`, with a one-line description.`

  A deterministic alternative: write the JSON with the placeholders as they are, save the jq program below in the scratchpad as `splice.jq`, run `jq --slurpfile cfg .slicewright/config.json -f <scratchpad>/splice.jq .slicewright/research.json` with its output written to `<scratchpad>/research.json` (through the shell tool's own redirection, or by writing the printed result with the Write tool), then `cp <scratchpad>/research.json .slicewright/research.json`. The equality checks in Verify prove the result; if one prints `false`, replace that value with the Edit tool.

  ```jq
  def ctx($stage): $cfg[0].pipeline[] | select(.name == $stage) | .params.context;
  def index_ctx: $cfg[0].pipeline[] | select(.name == "consolidate") | .params.knowledgeAgents[] | select(.name == "index") | .context;
  (.pipeline[] | select(.name == "intake") | .params.context) = ctx("intake")
  | (.pipeline[] | select(.name == "release") | .params.context) = ctx("release")
  | (.pipeline[] | select(.name == "consolidate") | .params.knowledgeAgents[] | select(.name == "index") | .context)
    |= sub("^<config.json's index context, verbatim>"; index_ctx)
  ```

- `.claude/settings.json` (changed). `permissions.allow` has 29 entries today, the last `"Bash(gh pr edit:*)"`. Append the four rules after it, in this order, with the same 6-space indentation, so the array ends: `"Bash(gh pr edit:*)",` `"Skill(slice:research)",` `"Bash(gh issue create:*)",` `"Bash(gh issue list:*)",` `"Bash(gh issue view:*)"`. Nothing else changes: not `deny`, not the order of the existing rules, not the formatting.
- `start-slice.sh` (changed). Five edits, by the existing text; everything else (the constants, `cannot_run`, `fail`, `say`, the tool checks, the working-copy and worktree steps, the validation, the `input.md` note branch) stays.
  - The header comment, lines 2 to 7: keep the first four lines' sense (prepares the working copy, checks the tools, switches to `master`, the worktree, validates, "With an issue number, the session starts with /slice:new <number>."), add "With --config <name>, the session starts with /slice:new --config <name>, and .slicewright/<name>.json must exist.", and make the usage line `# Usage: sh start-slice.sh [--config <name>] [<issue number>]`. The Exit status line stays.
  - The argument parsing, right after `cd "$repo" || cannot_run "cannot open $repo"`: replace the lines from `if [ "$#" -gt 1 ]; then` through the `case $issue in` … `esac` block with Contract 5's block, as written. The `for tool in git gh claude; do` loop stays right after it, so every usage error comes before any step runs.
  - The file check: right after `say "the stable plugin validates"` and before the comment `# A slice left in the slice folder:`, insert Contract 5's `if [ -n "$config_given" ] && [ ! -f "$config_file" ]; then … fi`.
  - The note: in the `if [ -f "$SLICE/status.md" ]; then` branch, after the `status=$(…)` line, add `cfg=$(sed -n 's/^config: *//p' "$SLICE/status.md" | sed -n 1p)` and `if [ -z "$cfg" ]; then cfg=config.json; fi` (on its own lines), and change the `say "note: …"` line to `say "note: ./$SLICE/ holds a slice: \"$title\", at $stage ($status), with $cfg. /slice:new will ask whether to continue it or start over"`.
  - The end: replace the lines from `if [ -n "$issue" ]; then` through the final `exec claude --plugin-dir "$plugin"` with Contract 5's request block.

## Verify

Run from the repo root. The static check needs T01's `plugins/slice/skills/research/SKILL.md` and T03's `configs` check in the working copy, which the waves guarantee.

- `sh tests/static.sh`: `PASS validate`, `PASS json`, `PASS defaults`, `PASS configs`, `PASS skills`, then `static: passed`; exit 0. Proves AC10's "the runner reports no pipeline problem": the `configs` check applies the runner's section 2 rules to `research.json` merged onto the defaults, and a `TBD` skill would be the only `skill` value it accepts that the runner stops at, which `research.json` doesn't use.
- AC10, the structure:
  - `jq -c 'keys' .slicewright/research.json`: `["pipeline"]`
  - `jq -e 'has("sharedParams") | not' .slicewright/research.json`: `true`, exit 0
  - `jq -c '[.pipeline[].name]' .slicewright/research.json`: `["intake","clarify","questions-review","research","results-review","file-issues","consolidate","release"]`
  - `jq -c '[.pipeline[] | [.name, .skill, .executionMode, .onError]]' .slicewright/research.json`: `[["intake","slice:intake","fork",null],["clarify","slice:clarify","fork",null],["questions-review","slice:human","inline",null],["research","slice:research","fork","results-review"],["results-review","slice:human","inline",null],["file-issues","slice:deploy","fork",null],["consolidate","slice:consolidate","fork",null],["release","slice:deploy","fork",null]]`
  - `jq -e '[.pipeline[] | keys[]] | unique | all(IN("name","skill","executionMode","next","onError","params"))' .slicewright/research.json`: `true` (no key the runner would warn about)
  - `jq -c '[.pipeline[] | [.name, (.params | keys)]]' .slicewright/research.json`: `[["intake",["context"]],["clarify",["context","reviewAgents"]],["questions-review",["context","files"]],["research",["context","researchAgents","reviewAgents"]],["results-review",["choices","context","files"]],["file-issues",["context"]],["consolidate",["archivePath","knowledgeAgents"]],["release",["context"]]]` (no stage sets `activeSlicePath`)
  - `jq -c '.pipeline[] | select(.name=="results-review") | .params | [.files, .choices]' .slicewright/research.json`: `[["research.md","input.md"],{"accept":"file-issues","more-research":"research","re-scope":"clarify","drop":null}]`
  - `jq -c '.pipeline[] | select(.name=="questions-review") | .params | [.files, has("choices")]' .slicewright/research.json`: `[["spec.md","input.md"],false]`
  - `jq -c '.pipeline[] | select(.name=="consolidate") | .params | [.archivePath, [.knowledgeAgents[] | [.name, .agent, .executionMode]]]' .slicewright/research.json`: `["./.slicewright/slices",[["research","general-purpose","fork"],["adr","general-purpose","fork"],["index","general-purpose","fork"]]]`
  - `jq -c '.pipeline[] | select(.name=="research") | .params.researchAgents | map([.name, .agent, .executionMode])' .slicewright/research.json`: `[["web","general-purpose","fork"],["claude-code","claude-code-guide","fork"]]`
  - `jq -c '[.pipeline[] | select(.params.reviewAgents) | [.name, (.params.reviewAgents | length), (.params.reviewAgents | map(.agent))]]' .slicewright/research.json`: `[["clarify",1,["general-purpose"]],["research",1,["general-purpose"]]]`
  - `jq -e '.pipeline[] | select(.name=="file-issues") | .params.context | contains("gh issue list --repo prosoftsolutions-cloud/slicewright --state all --search") and contains("gh issue create --repo prosoftsolutions-cloud/slicewright --title") and contains("gh issue view <number> --repo prosoftsolutions-cloud/slicewright")' .slicewright/research.json`: `true`
- AC10, the verbatim contexts:
  - `jq -n --slurpfile a .slicewright/config.json --slurpfile b .slicewright/research.json '($a[0].pipeline[] | select(.name=="intake") | .params.context) == ($b[0].pipeline[] | select(.name=="intake") | .params.context)'`: `true`
  - `jq -n --slurpfile a .slicewright/config.json --slurpfile b .slicewright/research.json '($a[0].pipeline[] | select(.name=="release") | .params.context) == ($b[0].pipeline[] | select(.name=="release") | .params.context)'`: `true`
  - `jq -rn --slurpfile a .slicewright/config.json --slurpfile b .slicewright/research.json '($a[0].pipeline[] | select(.name=="consolidate") | .params.knowledgeAgents[] | select(.name=="index") | .context) as $base | ($b[0].pipeline[] | select(.name=="consolidate") | .params.knowledgeAgents[] | select(.name=="index") | .context) | if startswith($base) then "REMAINDER:" + ltrimstr($base) else "DOES NOT START WITH THE CONFIG INDEX CONTEXT" end'`: exactly `REMAINDER: A folder whose `index.md` is new is listed under Contents in its parent folder's `index.md`, with a one-line description.` (with the space after the colon)
- AC9, the permissions:
  - `git diff master -- .claude/settings.json`: one hunk; one removed line `-      "Bash(gh pr edit:*)"` and five added lines, `+      "Bash(gh pr edit:*)",` (the comma), `+      "Skill(slice:research)",`, `+      "Bash(gh issue create:*)",`, `+      "Bash(gh issue list:*)",`, `+      "Bash(gh issue view:*)"`; nothing else. As JSON content, the only change is the four new entries.
  - `jq -e '(keys == ["permissions"]) and ((.permissions | keys) == ["allow","deny"]) and .permissions.deny == ["Edit(/.slicewright/stable/**)"] and (.permissions.allow | length) == 33 and .permissions.allow[28] == "Bash(gh pr edit:*)" and .permissions.allow[29:] == ["Skill(slice:research)","Bash(gh issue create:*)","Bash(gh issue list:*)","Bash(gh issue view:*)"]' .claude/settings.json`: `true`
- AC12 and the script rules (the runs themselves are the person's hand check; an agent never runs `start-slice.sh`):
  - `dash -n start-slice.sh`: prints nothing, exit 0.
  - `grep -n "^# Usage:" start-slice.sh`: `# Usage: sh start-slice.sh [--config <name>] [<issue number>]`.
  - `grep -c "exec claude" start-slice.sh`: `2`, the one with `"$request"` and the bare one.
  - Read-through against the contract, each AC12 input to its branch of the loop: `--config research 17`: `--config)` sets `config=research`, `*)` sets `issue=17`; the name rule passes; `config_file=.slicewright/research.json` exists; request `/slice:new --config research 17`; `exec claude --plugin-dir "$plugin" "/slice:new --config research 17"`. `--config research`: as above without the issue; `exec … "/slice:new --config research"`. `--config research.json 17`: `*.json)` keeps the name; the runner accepts it. `--config a/b` → `*/*)`, `--config ..` → `*..*)`, `--config ''` → `''`: `cannot_run "not a configuration name: …"`, exit 2 with the usage line; `--bogus` → `-*)`: `cannot_run "unknown option --bogus; usage: …"`, exit 2; `--config` alone: `cannot_run "--config needs a name; …"`, exit 2; all before `for tool in git gh claude`, so no other step runs. `--config missing`: parsing passes; after `say "the stable plugin validates"` the file check runs `fail "the configuration .slicewright/missing.json doesn't exist: …"`, exit 1, and Claude doesn't start. `17`, `#17`, no arguments: request `/slice:new 17` or the bare `exec`, as before; `17 18`: "too many arguments", exit 2, as before; `abc`: "not an issue number", exit 2, as before (`-1` now reads "unknown option" instead of "not an issue number"; exit 2 either way). The note: `cfg` from the first `config:` line of `slice/status.md`, so `config: research.json` gives `… at <stage> (<status>), with research.json.` and a `status.md` without the line gives `… with config.json.`
- `git status --short`: before the commit, this task's changes are `?? .slicewright/research.json`, ` M .claude/settings.json` and ` M start-slice.sh`, and nothing under `.slicewright/config.json`, `.slicewright/stable/` or `plugins/`.
- AC11: per Q1's answer A, the hand run happens in the first research slice after the merge; nothing in this task runs it, and its Verify doesn't prove it.

## Boundaries

Never touch `.slicewright/config.json`, anything under `.slicewright/stable/` or `.slicewright/slices/`, `plugins/slice/` (including `defaults.json` and every skill: T01, T02), `tests/` (T03, T05), `README.md`, `AGENTS.md` (T07), `.gitignore`, or `slice/docs/` (T06). `.claude/settings.json`: only the four appended rules; `deny`, the existing rules, their order and the formatting stay. `start-slice.sh`: the tool checks, the working-copy steps, the worktree handling, `claude plugin validate`, the `input.md` note, the exit codes (0, 1, 2) and the `exec` form stay; no bash-only syntax; `#<number>` still accepted; no `getopts`, no `--config=<name>` form. `research.json`: no `sharedParams`, no stage key outside `name`, `skill`, `executionMode`, `onError`, `params`, no `activeSlicePath` in any `params`, no `next`. Never run `start-slice.sh`, `tests/selftest.sh` or `tests/smoke.sh`; never run `gh issue` commands against the repository.
