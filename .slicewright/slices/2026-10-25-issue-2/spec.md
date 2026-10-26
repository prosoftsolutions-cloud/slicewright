---
slice: issue-2
source: https://github.com/prosoftsolutions-cloud/slicewright/issues/2
---

# Tests for new plugin versions

## Goal

Slicewright has no tests. Today a new version of the plugin is checked by hand: `claude plugin validate`, then a headless run on a scratch project that someone sets up each time and someone reads. This slice adds two levels of tests for the plugin in the working copy, `plugins/slice`, before it is merged to `master` and becomes the stable version. The static level needs no model and runs in every quality gate. The smoke level runs the pipeline headless on a copy of a sample project, decides pass or fail with checks a command evaluates, and runs in each slice's test stage. Both are described in the project's documentation, where the pipeline's existing contexts already look for them. For the developers of Slicewright, a broken stage, a dangling `next`, or a pipeline that no longer delivers a working feature then shows up before the merge, not after it.

## Scope

**Changes:**

- `tests/` (new): the static checks, the smoke run, their self-test with its fixtures, and one sample project with its request and its acceptance check
- `.slicewright/config.json`: only the `test` stage's `testAgents`
- `AGENTS.md`: only its "Checking a change" section
- the documentation, staged in `slice/docs/`: `overview/testing.md` (new) and `overview/structure.md`. Consolidate's `index` agent adds the new page to `overview/index.md`.

**Out of scope:**

- everything under `plugins/slice/` (skills, `defaults.json`, manifests) and under `.slicewright/stable/`
- `README.md` and `.claude/settings.json`
- smoke scenarios beyond the one in R4, such as gates answered by scripted replies, `onError` routes, `/slice:resume` after an interruption, the review-fix and bug-fix loops, and `/slice:configure`
- checks judged by a model, and repeated runs that measure a pass rate
- running the tests in CI
- checks of the repo's own `.slicewright/config.json`

## Requirements

- **R1** Every test, fixture and sample project lives under `tests/` at the repo root. No file under `plugins/slice/` or `.slicewright/stable/` changes.
- **R2** The static level is one command, run from the repo root. It checks the plugin folder it is given, `plugins/slice` when none is given. It starts no Claude session and makes no model call. It finishes within 60 seconds. It prints each failed check with the file, stage or skill it concerns, and exits non-zero when any check fails and zero otherwise. Its checks:
  1. `claude plugin validate .` and `claude plugin validate <plugin folder>` both pass. Warnings don't fail the check.
  2. Every `.json` file under the plugin folder and under `.claude-plugin/` parses.
  3. In `<plugin folder>/defaults.json`: `sharedParams.activeSlicePath` is a non-empty text; `pipeline` is a non-empty list; every stage has a `name`, and no two stages share one; every `executionMode` is `inline` or `fork`; every stage has a `skill` or a non-empty `params.context`; every `next` and `onError` that a stage sets to a value other than `null` names a stage; every value in a stage's `params.choices` names a stage or is `null`; every stage's `skill`, and every `skill` key at any depth in `sharedParams` and in the stages' `params`, is `TBD` or `slice:<name>` where `<plugin folder>/skills/<name>/SKILL.md` exists; and no stage's `params` sets `activeSlicePath`.
  4. Every folder under `<plugin folder>/skills/` has a `SKILL.md` whose frontmatter has a `name` equal to the folder's name and a non-empty `description`. Every skill except `new`, `resume` and `configure` has `user-invocable: false`.
- **R3** One sample project lives under `tests/`. It has a small program with its own tests, run by one command that the sample's own `AGENTS.md` names; a documentation folder at the path the default `knowledge` names; a request for one small, fully specified feature; and an acceptance check for that request. The acceptance check is kept outside the sample's files, so the pipeline never sees or changes it. The sample builds and tests with no package install and no network.
- **R4** The smoke level is one command, run from the repo root. It:
  1. copies the sample into a new folder outside the repo
  2. writes a test configuration into the copy. Its pipeline is `intake`, `clarify`, `design`, `plan`, `implement`, `review` and `consolidate`, in that order, each with `next` set to the one after it and with no `onError`, so any error ends the run. Each stage's `skill`, `executionMode` and `params` come from the stage of the same name in the working copy's `plugins/slice/defaults.json`, read when the command runs. The only overrides are those the sample needs, such as a stage's context that would otherwise wait for a person or need a remote, like intake's check for the latest sources. The testing page lists each override with its reason.
  3. puts the copy under version control with one commit that holds all of it, the test configuration included, with the `slice/` folder ignored, so the run starts from a clean tree
  4. runs `/slice:new` with the sample's request in the copy, headless with `claude -p`, loading the plugin only from the working copy's `plugins/slice` with `--plugin-dir`, and the test configuration with `--config`. The session uses the developer's own sign-in, and loads none of the developer's user-level plugins, skills, hooks or MCP servers.
- **R5** The smoke run stops when it reaches a time limit of 90 minutes. Reaching it fails the run, and the command says that the time limit stopped it. The limit is set in one place under `tests/`, and can be overridden for a single run. The run has no cost ceiling.
- **R6** After the headless run ends, the smoke command evaluates these checks, each with its own name, and prints each one as passed or failed. It exits zero only when all of them pass. The checks can be evaluated again on a kept copy without a new headless run.
  1. The headless session ended without an error, within the time limit.
  2. The session's own report of what it loaded, in its kept output, shows the `slice` plugin from the working copy's `plugins/slice`, and no other plugin and no MCP server.
  3. The copy's `slice/status.md` has `status: done` and an empty `next`, and its Stages table has exactly one row for each of the seven stages, each `done`.
  4. The copy's `slice/` folder holds `input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`.
  5. The sample's own test command passes in the copy.
  6. The acceptance check passes against the copy.
  7. The copy's version control shows no uncommitted change outside the `slice/` folder.
  8. The copy's `.slicewright/slices/index.md` has an entry for the slice.
- **R7** Each smoke run, finished or stopped, keeps its copy, the headless session's output, its cost and duration, and the check results in one folder. When the session was stopped before it reported its cost or duration, the record says that each one is unknown. The command never deletes that folder, and its last line of output names it.
- **R8** The `test` stage in the repo's `.slicewright/config.json` gets one `testAgents` entry that runs the smoke command. Its context says to report each smoke check as one test, by its name, and the folder from the command's last line as the artifacts. The suite waits for the run to end and reports it even when the run takes longer than one shell command of the suite's agent may last. Nothing else in the file changes.
- **R9** The documentation describes the tests:
  1. A new page, `overview/testing.md`, says: what each level checks and why, its command, which stages of the pipeline run it, and what a run costs and how long it takes, as measured on the first passing smoke run. It names the static command and the self-test command as the project's tests that need no headless Claude run, and the smoke command as a test that needs one. It also says where the sample and its acceptance check are, how a run copies the sample, the test configuration's overrides with their reasons, how to add a static check with its self-test case, and that tests load the plugin only from `plugins/slice` and change only copies.
  2. `overview/structure.md` lists the `tests/` folder.
  3. The "Checking a change" section of `AGENTS.md` names the static, self-test and smoke commands and points to the testing page. It no longer describes the manual headless run, which the testing page now covers.
- **R10** The tests' own checks have a self-test: one command, run from the repo root, that starts no Claude session and finishes within 60 seconds. For each broken case in AC3, it makes a copy of `plugins/slice` with that one thing broken and runs the static command on it. For each broken case in AC7, it makes a copy of a finished-run fixture kept under `tests/`, breaks that one thing, and evaluates the smoke checks on it. It exits zero only when every case fails with its check named, and the unbroken fixture passes every check except 1 and 2, which need a real session.

## Acceptance criteria

- **AC1** (R1) Given the slice's finished changes, when the files it changed are listed, then every test, fixture and sample file is under `tests/`, and no file under `plugins/slice/` or `.slicewright/stable/` changed.
- **AC2** (R2) Given the working copy at the end of this slice, when the static command runs from the repo root, then it exits zero within 60 seconds, and its code starts no Claude session.
- **AC3** (R2, R10) Given a copy of `plugins/slice` with exactly one of these broken: a stage's `next` naming no stage, a `choices` value naming no stage, two stages with the same name, a stage's `skill` naming no skill folder, a `SKILL.md` whose `name` differs from its folder, an internal skill without `user-invocable: false`, or a JSON file that doesn't parse; when the static command runs on that copy, then it exits non-zero and its output names the broken stage, skill or file. This holds for each case on its own.
- **AC4** (R3) Given a fresh copy of the sample, when its own test command runs, then its tests pass without installing anything; and when the acceptance check runs against that unchanged copy, then it fails, because the requested feature doesn't exist yet.
- **AC5** (R4, R5, R6) Given the working copy at the end of this slice, when the smoke command runs, then the headless run goes through the seven stages, and every check passes within 90 minutes.
- **AC6** (R4) Given a finished run's kept copy, when its test configuration is compared with the working copy's `plugins/slice/defaults.json`, then each of the seven stages has the same `skill`, `executionMode` and `params` as the stage of the same name there, except for the overrides the testing page lists; and nothing under `tests/` holds a copy of those params.
- **AC7** (R6, R10) Given a copy of the finished-run fixture with exactly one of these broken: a stage row set to `failed` in `status.md`, a record removed from `slice/`, a change that breaks the acceptance check, an uncommitted file outside `slice/`, or the records index entry removed; when the smoke checks are evaluated on that copy, then the command exits non-zero and names that check, without starting a headless run. This holds for each case on its own.
- **AC8** (R5) Given the time limit overridden to one minute for one run, when the smoke command runs, then the run stops, and the command exits non-zero and says that the time limit stopped it.
- **AC9** (R7) Given any smoke run, finished or stopped, when it ends, then its last line of output names a folder that still exists afterwards and holds the copy, the session output, the cost and duration or "unknown" for each, and the check results.
- **AC10** (R8) Given the repo's `.slicewright/config.json` at the end of this slice, when it is compared with the version before the slice, then the only change is one entry in the `test` stage's `testAgents`, whose context runs the smoke command, reports each check as one test by its name, reports the folder from the last line as the artifacts, and waits for a run longer than one shell command may last.
- **AC11** (R8) Given a slice whose test stage runs with that entry, when the smoke run takes longer than 10 minutes, then the suite still reports `RAN`, with one test per check and the folder as its artifacts.
- **AC12** (R9) Given the slice's staged documentation and `AGENTS.md`, when a reviewer reads them, then `overview/testing.md` covers every item R9 lists; `overview/structure.md` lists `tests/`; and the "Checking a change" section names the three commands, points to the testing page, and no longer describes the manual headless run.
- **AC13** (R2, R9, R10) Given the testing page, when an implement quality gate follows its context, "Run the project's tests that need no headless Claude run, when the documentation describes any", then the page names exactly the static command and the self-test command as those tests.
- **AC14** (R10) Given the working copy at the end of this slice, when the self-test command runs from the repo root, then it exits zero within 60 seconds, starts no Claude session, and lists each case of AC3 and AC7 as caught.
- **AC15** (R4, R6) Given the developer's user-level settings enable other plugins, hooks or MCP servers, as they do on this machine, when the smoke command runs, then the kept session output shows only the `slice` plugin, loaded from `plugins/slice`, and no MCP server, and check 2 passes.

## Constraints

- Tests and their sample projects live outside `plugins/slice/`, as issue #1 decided: an installed plugin is a copy of its folder.
- Tests load the plugin only from the working copy, `plugins/slice`, never from `.slicewright/stable/`, and change only copies of their sample projects and fixtures, in new folders outside the repo.
- The smoke run needs no person, no deployment, no GitHub and no network beyond the model API.
- The smoke run has no gate. So an open question that blocks design, or a stage's context that waits for a person, ends it with an error. The sample's request is fully specified to avoid the first, and R4's overrides cover the second.
- A headless run can't answer permission prompts, and in a new, untrusted folder it ignores that folder's `.claude/settings.json` allow rules. So the smoke command grants up front exactly what the stages need, and never bypasses permission checks.
- Each command starts as one command, with no `&&`, `;` or pipes, so a stage's agent can run it in one call.
- A shell command run by a stage's agent times out after at most 10 minutes, and a smoke run takes longer.
- The smoke run is too slow and costly for a task's Verify section or a quality gate. Within a slice it runs only in the test stage, or by hand.
- The smoke run uses the developer's own Claude Code sign-in, and its cost is billed there. It has no cost ceiling: only the time limit bounds what a run spends, and each run's record keeps its cost.

## Assumptions

- The tests' folder is `tests/` at the repo root: the common name, and issue #1 only says the tests live outside `plugins/slice/`.
- The testing page is `overview/testing.md`: `overview/` covers the technology and how the code is organized, `product/guides/` is for the plugin's users, and the documentation has no section for its developers.
- The tests need only the `claude` CLI, `jq`, `git` and a POSIX shell, with no new runtime or package manager: the repo has none, `jq` is already allowed in `.claude/settings.json`, and all four are on this machine.
- The sample is a small POSIX shell program with its tests in shell, so that it too needs nothing beyond those four tools.
- The copy is put under `git`, the version control this repo uses, because implement and consolidate commit, and R6's check 7 relies on it.
- The smoke run leaves out the developer's user-level plugins, skills, hooks and MCP servers, so that pass or fail depends only on the working copy and the sample. This is a default chosen here: on this machine, the user settings enable six other plugins and define hooks.
- Pass or fail rests only on checks a command evaluates on the files a run leaves: a failure is then reproducible, and re-checking a kept copy costs nothing.
- No sample project is in the repo yet. The one used for the earlier manual runs isn't kept here, so this slice creates a new one.
- The developer's Claude Code has no other copy of the `slice` plugin installed, as issue #1 decided.
- A headless `claude -p` started from a stage agent's shell reaches the model API. This was checked during this stage with a one-turn run, which cost about $0.01. Its JSON output reported the cost and the duration.
- The permission rules for the new commands are added with `/slice:configure --permissions`, not by this slice: a write to `.claude/settings.json` always prompts, and configure already proposes the test stage's commands.
- This slice's own test stage runs the smoke suite only in a run that starts after implement commits the config change, such as after `/slice:resume`, because the runner loads the configuration when a run starts.

## Follow-up slices

- More smoke scenarios: the gates answered by scripted replies, `onError` routes, `/slice:resume` after an interruption, and the review-fix and bug-fix loops.
- Checks judged by a model of what a stage writes, such as the spec or the design, and repeated runs that measure a pass rate.
- Running the static level and the self-test in CI on every push, and the smoke level on demand.
- Checks of the repo's own `.slicewright/config.json` against the stable plugin.
