---
title: "Research flow: a slice:research stage and a research pipeline"
id: issue-16
source: https://github.com/prosoftsolutions-cloud/slicewright/issues/16
---

# Research flow: a slice:research stage and a research pipeline

Supersedes #15.

## Goal

Run a research topic through Slicewright the way a feature runs through it: agree the questions with a person, research them from sources with evidence, agree the results, and publish them to the documentation and to issues.

The three needs:

1. run research on a given topic
2. summarize the results
3. update the documentation and issues from them

Need 3 is `slice:consolidate` plus a filing step. Needs 1 and 2 have no stage today, and none of the existing stages fits: `clarify` never talks to the person and writes no plan; `plan` needs `design.md` and gives every task tests; `implement` is built around quality gates, Verify commands and commits; `design` is the closest in shape, but its template is code (Affected areas, Contracts, Data and migration, Requirements coverage) and its agents explore the code. So this slice adds one stage, and the rest is configuration.

## The new stage: `slice:research`

A stage that answers questions from sources with evidence. It has the shape of the `design` stage: agents fan out, the stage merges one document, review agents check it.

- **Params:** `activeSlicePath`, `knowledge`, `context`, `researchAgents` (each entry one angle or one kind of source, with its `context`), `reviewAgents`. Agent entries have the same format as in every other stage: `executionMode`, `skill` or `agent`, `context`, `name`.
- **Reads:** `spec.md`, which holds the research questions, the scope, the sources in and out, and what a good answer contains. Returns `NO_SPEC` without it.
- **Protocol:** read the project's own knowledge first (documentation, code, the slice archive); start every `fork` research agent at once; each returns findings per question, every finding with its source and a confidence; merge them into `research.md`: for each question its answer, the evidence and the disagreements between sources, then conclusions, options with their trade-offs, a recommendation, open questions and follow-ups; run the review agents (for example: every claim has a source, and the source supports it); handle issues and recommendations the way clarify and design do; save `research.md` and record the review.
- **Rerun:** like design, it keeps a person's answers and review notes from an earlier `research.md`, and reworks only what the notes ask for. This is what makes the "more research" loop work.
- **Result block** as in `skills/run/SKILL.md`, section 4.3. Never asks the person anything.

What stays in configuration: the sources and tools, what counts as evidence, how to cite, the output conventions, which documents are published, and whether issues are filed.

The stage isn't bound to the research pipeline: the default pipeline could use it as a spike between clarify and design when a spec has a question that only investigation answers. That is out of scope here.

## The research pipeline: `.slicewright/research.json`

Started with `sh start-slice.sh --config research [<issue number>]`, which runs `/slice:new --config research`. It replaces the default pipeline as a whole.

| Stage | Skill | Notes |
|---|---|---|
| intake | `slice:intake` | the same stage as in `config.json` |
| clarify | `slice:clarify` | context: turn the topic into research questions, scope, sources in and out, and what a good answer contains |
| questions-review | `slice:human` | agree the questions, the scope and the sources |
| research | `slice:research` | `onError` → results-review |
| results-review | `slice:human` | `files: [research.md]`; choices: accept → consolidate, more research → research, re-scope → clarify, drop → end. For each follow-up, ask whether to file it as an issue, and mark the answer in `research.md` |
| consolidate | `slice:consolidate` | knowledge agents: a research page, `adr` reading `research.md`, `index` |
| file-issues | `slice:deploy` | context: create one issue for each follow-up marked for filing, and record their numbers |

## Decisions already taken

- **Where findings land:** a research page, for example `architecture/research/<topic>.md`, holds the full findings; an ADR holds a decision when the research reaches one. Both are consolidate configuration.
- **Issues:** results-review asks for each follow-up on its own whether to file it. file-issues files only those.
- **Scope of the configuration:** `research.json` is this repo's. The plugin ships the skill; the README documents the research pipeline as its example of `--config`.
- `activeSlicePath` stays `./slice`, so there is one slice at a time across both pipelines, and `start-slice.sh` keeps working.

## Also in this slice

- **`run`:** the **Continue** choice of `/slice:new` must also switch to the configuration named in `status.md`, as `resume` does. Today the switch happens only when resuming, so a research slice continued with a plain `/slice:new` runs `config.json`'s stages, which share names with it.
- **`run`:** add `Skill(slice:research)` to its `allowed-tools`, and `/slice:configure` proposes the permission rule like every other skill's. Add the rule to `.claude/settings.json`.
- **`start-slice.sh`:** `sh start-slice.sh [--config <name>] [<issue number>]`. Reject a name with `/` or `..`, and check that `.slicewright/<name>.json` exists, before Claude starts. Pass the flag with and without an issue number. Show the leftover slice's `config` in its note.
- **`tests/static.sh`:** check the pipeline in `.slicewright/research.json` the way it checks the one in `defaults.json`: stage names, `next` and `onError` targets, skills.
- **Documentation:** README (the research pipeline), `doc/overview/structure.md` (the new skill, the script's usage).

## Out of scope

- shipping `research.json` with the plugin
- a research stage in the default pipeline
- a smoke test of the research pipeline

## How to check

- `sh tests/static.sh` and `sh tests/selftest.sh` pass.
- `sh tests/smoke.sh` still passes: the default pipeline is unchanged.
- A hand run: `sh start-slice.sh --config research <issue>` on a real research topic goes through every stage, ends with a research page, an ADR when there is a decision, and the agreed issues. The smoke test covers only the default pipeline, so this is the only check of the stage itself.

## Session summary

Spec approved on 2026-10-27.

### Decisions

- The research pipeline ends with a `release` stage, the same `slice:deploy` stage as `config.json`'s, after `consolidate`.
- `file-issues` runs before `consolidate`, so the research page and the archived records carry the issue numbers.
- `/slice:configure` takes `--config <name>`, defaulting to `config.json`, so that it proposes the permission rules of another pipeline (R14, AC15). With another name the command creates no file: the configuration must already exist where the runner reads it.
- The new static check, `configs`, covers every `.slicewright/<name>.json` except `*.local.json`.

### Questions and answers

- Q1 Does the research pipeline end with a `release` stage? A: yes, add `release` after `consolidate`.
- Q2 Does `file-issues` run before or after `consolidate`? A: before.
- Q3 Should `/slice:configure` take `--config <name>`? A: yes, with `config.json` as the default.
- Q4 Does the static check cover every project configuration or only `research.json`? A: every one.

### Assumptions confirmed

- One slice, not several; R12, the static check, is the natural cut if it proves too large.
- The research page lives at `architecture/research/<topic>.md`, named from the slice's title; the documentation source's context is unchanged.
- The research review is recorded in `design-reviews.md`.
- The confidence scale is defined in the skill; what counts as a credible source stays in the configuration.
- A blocking open question left in the spec stops the research stage with `SPEC_NOT_READY`.
- The two research agents, `web` and `claude-code`, are this repo's choice.
- `start-slice.sh` checks only the project's `.slicewright/<name>.json`.
- The permission rules of R9 are added to `.claude/settings.json` in this slice; `/slice:configure --config research --permissions` proposes the same rules.
- The three `gh issue` rules go beyond the issue's ask; they are the commands the pipeline runs.
- The hand run's topic and cost are the person's choice.

### Still open

- Nothing.

See spec: spec.md
