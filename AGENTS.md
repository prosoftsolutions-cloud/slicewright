# Slicewright

A Claude Code marketplace with one plugin, `slice`, which runs one feature at a time, a slice, through a configurable pipeline of stages. [README.md](README.md) says how it is used.

## Layout

The layout is in [doc/overview/structure.md](doc/overview/structure.md).

`sh start-slice.sh [<issue number>]` prepares the working copy for a new slice and starts Claude Code with the stable plugin. It is for the person: an agent never runs it, because it switches branches and starts a session.

## Design rules

- The plugin ships mechanisms, and the project configures them. A choice that a project could make differently belongs in the configuration, not in a skill.
- No hardcoded examples, limits or choices in the skills.
- No new top-level configuration keys: the top level has only `sharedParams` and `pipeline`. A new setting is a param.
- Never rely on git in skill text. Say "the project's version control", and let the project's context or instructions name it.
- A skill holds the protocol, and the content lives in the configured `context`. The prompts a skill gives its agents carry only the protocol.
- Keep it thin: the smallest change that works, with each rule in one place.

## Skill conventions

- Every stage ends with the result block in `skills/run/SKILL.md`, section 4.3. Error codes are in UPPER_SNAKE_CASE.
- Only the runner and `slice:human` talk to the person. Every other stage never asks anything: it returns an error that says what it needs.
- Commands: one per call, never chained with `&&`, `;` or pipes, and never `cd`, because every stage and its subagents run from the project folder. Files are written with the Write or Edit tool, not with shell redirection.
- Plain English, in short sentences.

## Checking a change

- `sh tests/static.sh` checks the plugin without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, and each skill's frontmatter.
- `sh tests/selftest.sh` checks those checks, and the smoke checks, on broken copies.
- `sh tests/smoke.sh` runs the pipeline headless on a copy of the sample project and checks what the run leaves. It is too slow for a task or a quality gate: the test stage runs it, or you do, by hand.
- [doc/overview/testing.md](doc/overview/testing.md) says what each one checks, how to run it, and how to add a check.
- `/slice:configure` copies `defaults.json` into a project, so a change to the defaults doesn't reach a project that already has its own `.slicewright/config.json`.

<!-- slicewright:knowledge -->
## Project documentation

- **docs**: the OKF bundle in `./doc`. Start at `doc/index.md`.
- A slice in progress keeps its unpublished documentation changes in `./slice/docs/`, at the same paths. Read those first. If a source can't be reached, note it as an assumption and keep working.
<!-- /slicewright:knowledge -->
