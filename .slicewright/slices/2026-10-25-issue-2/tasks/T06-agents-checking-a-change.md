---
id: T06
title: AGENTS.md "Checking a change"
type: plugin
depends: [T04]
covers: [R9, AC12]
---

# T06 AGENTS.md "Checking a change"

## Goal

Replace the "Checking a change" section of the repo's root `AGENTS.md` with one that names the static, self-test and smoke commands and points to the testing page, in place of the manual headless run it describes now.

## Context

From spec.md:

- **R9.3** The "Checking a change" section of `AGENTS.md` names the static, self-test and smoke commands and points to the testing page. It no longer describes the manual headless run, which the testing page now covers.
- **AC12** (this task's part) Given `AGENTS.md`, when a reviewer reads it, then the "Checking a change" section names the three commands, points to the testing page, and no longer describes the manual headless run.
- Scope: `AGENTS.md` changes only in its "Checking a change" section. `README.md` is out of scope.

From design.md:

- **D17** This task lands only after the self-test task, T04, which comes after the static, sample and smoke tasks. Implement's quality gates read `AGENTS.md` and run "the project's tests that need no headless Claude run". If this section named the commands before the scripts worked, a gate would run them and fail. So the scripts exist and work when you start.
- The testing page is staged at `slice/docs/overview/testing.md` until consolidate publishes it at `doc/overview/testing.md`. The link points to its published path, `doc/overview/testing.md`.
- The new section, word for word:

```markdown
## Checking a change

- `sh tests/static.sh` checks the plugin without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, and each skill's frontmatter.
- `sh tests/selftest.sh` checks those checks, and the smoke checks, on broken copies.
- `sh tests/smoke.sh` runs the pipeline headless on a copy of the sample project and checks what the run leaves. It is too slow for a task or a quality gate: the test stage runs it, or you do, by hand.
- [doc/overview/testing.md](doc/overview/testing.md) says what each one checks, how to run it, and how to add a check.
- `/slice:configure` copies `defaults.json` into a project, so a change to the defaults doesn't reach a project that already has its own `.slicewright/config.json`.
```

The section it replaces is now:

```markdown
## Checking a change

- `claude plugin validate .` and `claude plugin validate plugins/slice` must both pass.
- To see a change work, run the pipeline headless on a scratch project outside this repo, with `claude -p "/slice:resume" --plugin-dir <this repo>/plugins/slice --permission-mode acceptEdits --allowedTools "<what the stages need>"`. A headless run can't answer permission prompts, so allow up front the skills and commands its stages use.
- `/slice:configure` copies `defaults.json` into a project, so a change to the defaults doesn't reach a project that already has its own `.slicewright/config.json`.
```

## Interfaces

**Uses:**

- `sh tests/static.sh`: from T01
- `sh tests/smoke.sh`: from T03
- `sh tests/selftest.sh`: from T04
- `doc/overview/testing.md`: the testing page's published path, staged by T05 at `slice/docs/overview/testing.md`

## Changes

- `AGENTS.md` (changed)
  - `## Checking a change`: replace its three bullets with the five bullets above, word for word. Keep the heading, and keep the blank lines between this section and the ones around it.

## Verify

- `grep -n "sh tests/static.sh" AGENTS.md`: one line, the first bullet of "Checking a change"
- `grep -n "sh tests/selftest.sh" AGENTS.md`: one line, the second bullet
- `grep -n "sh tests/smoke.sh" AGENTS.md`: one line, the third bullet
- `grep -n "(doc/overview/testing.md)" AGENTS.md`: one line, the link in the fourth bullet
- `grep -c "claude -p" AGENTS.md`: prints `0`, because the manual headless run is gone
- `git diff -- AGENTS.md`: a single hunk inside "## Checking a change", which removes the `claude plugin validate` bullet and the `claude -p` bullet and adds the four new bullets before the `/slice:configure` bullet. Nothing changes in "Layout", "Design rules", "Skill conventions" or the block between `<!-- slicewright:knowledge -->` and `<!-- /slicewright:knowledge -->`.
- AC12 (this task's part): the section, read on its own, names `sh tests/static.sh`, `sh tests/selftest.sh` and `sh tests/smoke.sh`, links to `doc/overview/testing.md`, and has no `claude -p` command.

## Boundaries

- Change nothing else in `AGENTS.md`. The block between `<!-- slicewright:knowledge -->` and `<!-- /slicewright:knowledge -->` belongs to consolidate's `instructions` agent.
- Don't touch `README.md`, `.claude/settings.json`, anything under `plugins/slice/` or `.slicewright/`, the scripts under `tests/`, or the staged pages in `slice/docs/`, which T05 owns.
