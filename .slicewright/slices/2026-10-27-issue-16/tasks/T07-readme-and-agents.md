---
id: T07
title: README and AGENTS.md
type: plugin
depends: [T01, T02, T03, T04]
covers: [R13, AC14]
---

# T07 README and AGENTS.md

## Goal

Describe the research stage, the research pipeline, the `--config` option of `/slice:configure` and the script, and the widened static check, in `README.md` and `AGENTS.md`, in place.

## Context

### Requirement (the items of R13 for this task)

- **R13** The documentation describes the change: 1. `README.md`: `slice:research` among the stages, with `researchAgents` in the list of agents under Concepts; `/slice:configure` named with `/slice:new` and `/slice:resume` as a command that takes `--config <name>`; and the research pipeline as the example of `--config` in the Recipes, in place of the hotfix example: what it is for, its stages in order, that it lives in this repo's `.slicewright/research.json`, how it starts, and that `/slice:configure --config research --permissions` proposes its permission rules. […] 4. `AGENTS.md`: the script's usage line, and the "Checking a change" line for `static.sh`, which now names the project's configurations. (Items 2 and 3, the staged pages, are T06's.)

### Acceptance criterion

- **AC14** (R13) Given the staged documentation, `README.md` and `AGENTS.md`, when a reviewer reads them, then each item of R13 is covered, every stage name, choice, path and command in them matches `research.json`, the skill and the script, and the testing page's self-test count equals the number of cases `selftest.sh` runs.

### Constraints

- `README.md` and `AGENTS.md` aren't part of the documentation bundle: they change in place, not staged. The `<!-- slicewright:knowledge -->` block in `AGENTS.md` stays as it is.
- The README's description of agents stays true: `researchAgents` entries use the agent entry format of every other stage.
- `.slicewright/research.json` is loaded instead of `config.json`, not on top of it, so it repeats what it needs from `config.json`; the README says so.
- Plain English, short sentences.

### Contract 8, the parts for this task

- `README.md`: Quick start: "`/slice:new`, `/slice:resume` and `/slice:configure` take `--config <name>` to use another configuration." Concepts, the agents list: "research agents that answer questions from sources (`researchAgents`)". Default pipeline, a closing paragraph: the plugin also ships `slice:research`, a stage that answers the questions in a spec from sources, with cited evidence and a confidence, and writes `research.md` for a person to decide on; it isn't in the default pipeline, and the research pipeline below runs it. Recipes, in place of "Another pipeline": `--config <name>` loads `<name>.json` from the same four places instead of `config.json`, so the file repeats what it needs from `config.json`; this repo runs research topics with its research pipeline, `.slicewright/research.json`: `intake`; `clarify` writes the questions; **questions-review** agrees them with you; `research` answers them from sources with cited evidence; **results-review** puts the answers, the recommendation and the follow-ups to you, with accept, more research, re-scope or drop; `file-issues` files the follow-ups you chose as issues; `consolidate` publishes a research page and, when you took a decision, a decision record; `release` opens the pull request. `sh start-slice.sh --config research <issue number>` starts it with `/slice:new --config research <issue number>`, and `/slice:configure --config research --permissions` proposes its permission rules.
- `AGENTS.md`: the script line becomes `sh start-slice.sh [--config <name>] [<issue number>]` prepares the working copy for a new slice and starts Claude Code with the stable plugin; `--config research` runs the research pipeline in `.slicewright/research.json`; the rest as today. "Checking a change": `sh tests/static.sh` checks the plugin and the project's configurations without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, every `.slicewright/<name>.json` merged onto it, and each skill's frontmatter.

## Interfaces

**Uses:** what this task relies on, exactly as written, without changing it:

- the stage `slice:research` (`plugins/slice/skills/research/SKILL.md`) with its params `activeSlicePath`, `knowledge`, `context`, `researchAgents`, `reviewAgents`, which answers the questions in `spec.md` from sources with cited evidence and a confidence and writes `research.md`: from T01
- `plugins/slice/skills/configure/SKILL.md`'s `argument-hint: "[--config <name>] [--permissions]"` and usage `/slice:configure [--config <name>] [--permissions]`: from T02
- the `configs` check of `tests/static.sh`: every `.slicewright/<name>.json` of the repo except `*.local.json`, merged onto the plugin folder's `defaults.json`, checked with the same rules as `defaults`: from T03
- `.slicewright/research.json`: `pipeline` only; stages in order `intake`, `clarify`, `questions-review`, `research`, `results-review`, `file-issues`, `consolidate`, `release`; `results-review` choices `accept`, `more-research`, `re-scope`, `drop`; intake's and release's contexts repeated from `config.json`; `start-slice.sh` usage `sh start-slice.sh [--config <name>] [<issue number>]`, which with `--config <name>` starts Claude with `/slice:new --config <name>` plus the issue number when given: from T04
- `README.md` and `AGENTS.md` as they are: from the existing code

## Changes

- `README.md` (changed)
  - Quick start: the line `/slice:new` and `/slice:resume` take `--config <name>` to use another configuration.` becomes `/slice:new`, `/slice:resume` and `/slice:configure` take `--config <name>` to use another configuration.`
  - Concepts, the **Agents** list: add the bullet `- research agents that answer questions from sources (`researchAgents`)` after `- design agents (`designAgents`)`.
  - Default pipeline: after item 7 (**Finish**), a closing paragraph: the plugin also ships `slice:research`, a stage that answers the questions in a spec from sources, with cited evidence and a confidence, and writes `research.md` for a person to decide on. It isn't in the default pipeline; the research pipeline under Recipes runs it.
  - Recipes: the paragraph `**Another pipeline.** `--config hotfix` loads `hotfix.json` …` is replaced by the research pipeline example: `**Another pipeline.**` `--config <name>` loads `<name>.json` from the same four places instead of `config.json`, so the file repeats what it needs from `config.json`. This repo runs research topics with its research pipeline, `.slicewright/research.json`, whose stages are, in order: `intake`; `clarify` writes the questions; **questions-review** agrees them with you; `research` answers them from sources with cited evidence; **results-review** puts the answers, the recommendation and the follow-ups to you, with accept, more research, re-scope or drop; `file-issues` files the follow-ups you chose as issues; `consolidate` publishes a research page and, when you took a decision, a decision record; `release` opens the pull request. `sh start-slice.sh --config research <issue number>` starts it with `/slice:new --config research <issue number>`, and `/slice:configure --config research --permissions` proposes its permission rules. Keep the README's recipe style: a bold lead-in, then prose; a numbered or bulleted list for the stages is fine.
  - Nothing else: the Configuration section's four files and merge rule, the other recipes, Documentation, Limitations and License stay.
- `AGENTS.md` (changed)
  - Layout: the line `sh start-slice.sh [<issue number>]` prepares the working copy for a new slice and starts Claude Code with the stable plugin. It is for the person: …` becomes `sh start-slice.sh [--config <name>] [<issue number>]` prepares the working copy for a new slice and starts Claude Code with the stable plugin; `--config research` runs the research pipeline in `.slicewright/research.json`. It is for the person: an agent never runs it, because it switches branches and starts a session.`
  - Checking a change: the line `- `sh tests/static.sh` checks the plugin without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, and each skill's frontmatter.` becomes `- `sh tests/static.sh` checks the plugin and the project's configurations without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, every `.slicewright/<name>.json` merged onto it, and each skill's frontmatter.`
  - Nothing else: the Design rules, the Skill conventions, the other "Checking a change" lines and the knowledge block stay.

## Verify

Run from the repo root.

- `git diff --stat -- README.md AGENTS.md`: both files changed; `git diff -- AGENTS.md` shows exactly two changed lines, the script line and the `static.sh` line, and nothing inside the `<!-- slicewright:knowledge -->` block.
- `grep -n "slice:research" README.md`: the Default pipeline's closing paragraph and the Recipes paragraph; `grep -n "researchAgents" README.md`: the Concepts bullet; `grep -n "/slice:configure" README.md`: among its lines (the Quick start step 1, the Default pipeline and Configuration sections name the command already), the Quick start line with `--config <name>` and the recipe's `/slice:configure --config research --permissions`; `grep -n hotfix README.md`: nothing.
- `grep -n "start-slice.sh" README.md AGENTS.md`: the recipe's `sh start-slice.sh --config research <issue number>` and AGENTS.md's `sh start-slice.sh [--config <name>] [<issue number>]`; `sed -n '/^# Usage:/p' start-slice.sh` prints the same usage, `# Usage: sh start-slice.sh [--config <name>] [<issue number>]`.
- `grep -n "research.json" README.md AGENTS.md`: the recipe and the AGENTS.md script line; `grep -n "configurations" AGENTS.md`: the `static.sh` line; `grep -n 'pass_unless_failed configs' tests/static.sh`: one line, the check the AGENTS.md line describes.
- AC14, stage names and choices: `jq -r '[.pipeline[].name] | join(", ")' .slicewright/research.json` prints `intake, clarify, questions-review, research, results-review, file-issues, consolidate, release`, the names the recipe lists in that order; `jq -r '.pipeline[] | select(.name=="results-review") | .params.choices | keys_unsorted | join(", ")' .slicewright/research.json` prints `accept, more-research, re-scope, drop`, the four choices the recipe names.
- AC14, the commands: `grep -n "argument-hint" plugins/slice/skills/configure/SKILL.md` prints `argument-hint: "[--config <name>] [--permissions]"`, so `/slice:configure --config research --permissions` is a valid call; `grep -n "argument-hint" plugins/slice/skills/new/SKILL.md plugins/slice/skills/resume/SKILL.md` prints `[--config <name>] <feature request>` and `[--config <name>]`, so the Quick start line holds for all three.
- AC14, the stage: `sed -n '1,4p' plugins/slice/skills/research/SKILL.md` shows `name: research` and `user-invocable: false`; `grep -n "researchAgents" plugins/slice/skills/research/SKILL.md` shows the param the Concepts bullet names.
- `sh tests/static.sh`: exit 0 (`claude plugin validate .` reads the marketplace, not the README, so this only confirms the tree still validates).

## Boundaries

Change only `README.md` and `AGENTS.md`, in place. Leave alone: the `<!-- slicewright:knowledge -->` block and every other line of `AGENTS.md`; the README's Configuration section, the other recipes, Install, Documentation, Limitations and License; `doc/` and `slice/docs/` (T06, which changes `overview/structure.md` and `overview/testing.md`, in the next wave); `tests/selftest.sh` (T05, in the same wave, in the same folder); every skill, `plugins/slice/defaults.json`, `.slicewright/`, `.claude/settings.json` and `start-slice.sh`. Don't describe the self-test's new case or count in the README or AGENTS.md: that is the testing page's (T06).
