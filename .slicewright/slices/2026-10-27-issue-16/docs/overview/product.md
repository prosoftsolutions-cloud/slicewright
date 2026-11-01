---
type: overview
---

# Product

What Slicewright is, and what it does for the people who use it.

## What it is

- Slicewright is a Claude Code marketplace with one plugin, `slice`, which Claude Code installs from the marketplace. It is version 0.1.0, experimental: the skills and the defaults still change between versions.
- It is for a developer, or a team, who has an AI agent write features and wants the result to be trustworthy: the spec written down, the design checked, the code reviewed and tested against a deployment, and the documentation kept current.
- It runs one feature at a time, a slice, through a pipeline of stages, and a person decides at each gate. Every stage leaves a record, and at the end the slice's spec and design go into the project's documentation, so the documentation builds up slice by slice.
- The pipeline is configuration, not code: a list of stages, each a skill with rules in plain language. The plugin ships the mechanisms, and the project configures them. [README](../../README.md) says how to install it and gives recipes for the common changes.

## Commands

- `/slice:configure [--config <name>] [--permissions]` sets a project up: it creates `.slicewright/config.json` from the plugin's defaults, sets up the project's documentation, and proposes the permission rules the pipeline needs, so that the stages don't stop at prompts.
- `/slice:new [--config <name>] <feature request>` starts a slice in `./slice` and runs the pipeline. At each gate it asks the person in the conversation.
- `/slice:resume [--config <name>]` continues the slice in progress from where it stopped: after an error, a pause or a closed session.
- `--config <name>` runs another pipeline of the project, kept in `.slicewright/<name>.json` beside `config.json`. A slice remembers its configuration, so it is continued with the one it started with. [Named configurations](../product/spec/named-configurations.md) has the rules.

## What a slice goes through

The default pipeline, which `/slice:configure` copies into the project for the team to change. A gate, where a person decides, is run by `slice:human`, and its `choices` say where the pipeline goes next.

1. Start: `intake` resolves the request, `clarify` writes the spec, and the `spec-review` gate puts it to the person.
2. Design: `design` and `plan` write the design and the tasks, then the `design-review` gate: approve, re-plan or re-design.
3. Build: `implement` works through the tasks one by one, with quality gates that build and test. When it stops, the `implement-decision` gate.
4. Review: `review` runs the reviewers, then the `review-decision` gate: fix, ship, re-plan or re-design. Fixes go through `review-fix-plan`, `review-fix` and the `review-fix-decision` gate.
5. Verify: `deploy` and `test`, then the `test-decision` gate: fix, finish, retry or redeploy.
6. Fix bugs: `bug-analysis` finds the root causes with the configured instruments, `bug-fix-plan` and `bug-fix` fix them, then the `bug-fix-decision` gate shows each iteration's results.
7. Finish: `consolidate` publishes the documentation and keeps the slice's records. `release` stands in until the project configures its own release steps.

Every stage ends with `ok`, `skipped` or `error`, and the runner picks the next stage from it; `status.md` in the slice folder records each one. Stages hand parts of their work to configured agents, each with a `context`: reviewers, quality gates, test agents, the instruments that investigate failures, knowledge agents that update the documentation, design agents and research agents.

The plugin also ships `slice:research`, a stage that answers the questions in a spec from sources, with cited evidence and a confidence, and writes `research.md` with conclusions, options, a recommendation and follow-ups for a person to decide on. It isn't in the default pipeline: a project runs it in a pipeline of its own ([Research stage](../product/spec/research-stage.md)).

## Configuration

Four files are merged in order: the plugin's `defaults.json`, `~/.slicewright/config.json` for the person across projects, `.slicewright/config.json` for the project, committed, and `.slicewright/config.local.json` for the person in this project, not committed. Objects merge key by key, any other value replaces the earlier one, and `null` removes a key, so a project's `pipeline` replaces the default one whole. The top level has only `sharedParams`, which every stage receives, and `pipeline`, the stages in order; a new setting is a param. `--config <name>` puts `<name>.json` in `config.json`'s place in the last three files, on top of the defaults, so a named pipeline repeats what it needs from `config.json`.

## Documentation

Every stage reads the project's documentation, and the pipeline keeps it current. `sharedParams.knowledge` lists the sources, each a folder in the project or a skill that reaches one elsewhere, and names the one a slice publishes to. By default the documentation is an OKF bundle in `./doc`, with the architecture in arc42, and this documentation is one. While a slice runs, its documentation changes are staged in `./slice/docs/`; `consolidate` publishes them and keeps the slice's records in `.slicewright/slices/`, so a later slice starts from what the earlier ones left.

## This repo

Slicewright develops itself with the plugin. `.slicewright/config.json` runs a feature. `.slicewright/research.json` runs a research topic through the research stage: it agrees the questions with a person, researches them from sources, agrees the results, files the follow-ups the person chose as issues, and publishes a research page and, when a decision was taken, a decision record ([Research pipeline](../product/spec/research-pipeline.md)). `sh start-slice.sh [--config <name>] [<issue number>]` prepares the working copy and starts a session with the stable plugin. [Structure](structure.md) says where each part lives, [Technology](tech.md) what it is made of, and [Testing](testing.md) how the plugin is tested before a version becomes stable.

## Limitations

- One slice at a time per working copy, because the slice lives in `./slice`. Slices in parallel need a working copy or a worktree each.
- A headless run can't answer permission prompts: what the stages need is allowed up front.
- The reviewers and the quality gates are agents too. The gates where a person decides are what makes the result trustworthy.
- The defaults assume a project that builds and tests from the command line. Other setups need their own contexts.
