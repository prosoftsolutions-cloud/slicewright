---
type: spec
---

# Plugin tests

These tests check a new version of the plugin in `plugins/slice` before it is merged to `master` and becomes the stable version. They are for the developers of Slicewright. [Testing](../../overview/testing.md) gives the commands, their output, the run folder and the self-test's cases.

## Requirements

### Where the tests live

- Every test, fixture and sample project lives under `tests/` at the repo root, outside `plugins/slice/`, because an installed plugin is a copy of its folder.
- The tests need only the `claude` CLI, `jq`, `git` and a POSIX `sh`.
- Each command runs from the repo root as one command, with no `&&`, `;` or pipes, so a stage's agent can run it in one call.
- Tests load the plugin only from the working copy, `plugins/slice`, never from `.slicewright/stable/`. They change nothing under either folder. They change only copies of the sample and the fixture, in new folders outside the repo.

### Static level

`sh tests/static.sh [<plugin folder>]` checks a plugin folder. With no folder given, it checks `plugins/slice`. It starts no Claude session, makes no model call, and finishes within 60 seconds. It prints each problem with the file, stage or skill folder it concerns. It exits 1 when any check fails, 0 when all pass, and 2 when it can't run.

Its checks:

1. `validate`: `claude plugin validate .` and `claude plugin validate <plugin folder>` both pass. Warnings don't fail it.
2. `json`: every `.json` file under the plugin folder and under `.claude-plugin/` holds exactly one JSON value.
3. `defaults`: in `<plugin folder>/defaults.json`:
   - `sharedParams.activeSlicePath` is a non-empty text, and `pipeline` is a non-empty list.
   - Every stage has a `name`, and no two stages share one. Every `executionMode` is `inline` or `fork`. Every stage has a `skill` or a non-empty `params.context`.
   - Every `next` and `onError` that isn't `null` names a stage. Every value in a stage's `params.choices` names a stage or is `null`.
   - Every stage's `skill`, and every `skill` key at any depth in `sharedParams` and in the stages' `params`, is `TBD` or `slice:<name>`, where `<plugin folder>/skills/<name>/SKILL.md` exists.
   - No stage's `params` sets `activeSlicePath`.
4. `skills`: every folder under `<plugin folder>/skills/` has a `SKILL.md`. Its frontmatter has a `name` equal to the folder's name and a non-empty `description`. Every skill except `new`, `resume` and `configure` has `user-invocable: false`.

### The sample

- The sample project, `tests/sample/project/`, is a small program with its own tests. One command, named in the sample's own `AGENTS.md`, runs them. Its documentation is at the path the default `knowledge` names, `./doc`. It builds and tests with no install and no network.
- `tests/sample/request.md` asks for one small feature, with every choice stated, so that clarify has no open question.
- `tests/sample/accept.sh <project folder>` is the acceptance check for that request.
  - It sits outside the sample's files and is never copied into a run, so the pipeline never sees or changes it.
  - It never writes to the folder it checks.
  - It covers every outcome the request states, including what stays the same without the option, and which letters become upper case.
  - It fails on the unchanged sample.

### Smoke level

`sh tests/smoke.sh` runs the pipeline headless on a copy of the sample. It then evaluates checks on what the run left.

- It copies the sample into a new run folder outside the repo, under `${TMPDIR:-/tmp}/slicewright-smoke/`. It refuses a folder inside the repo.
- It writes a test configuration into the copy. It generates the configuration when the command runs, from the working copy's `plugins/slice/defaults.json`:
  - The pipeline is `intake`, `clarify`, `design`, `plan`, `implement`, `review` and `consolidate`, in that order, with no gates.
  - Each stage is the default stage of the same name. Its `next` is the stage after it, and it has no `onError`, so any error ends the run.
  - The only overrides are those the sample needs, and the testing page lists each one with its reason. There is one today: intake's context, because the default one needs a remote and asks a person.
  - Nothing under `tests/` holds a copy of the defaults' params.
- It puts the copy under version control, in one commit that holds all of it, the test configuration included. The `slice/` folder is ignored, so the run starts from a clean tree.
- It runs `/slice:new` with the sample's request in the copy, headless, with `claude -p`.
  - It loads the plugin only from `plugins/slice`, with `--plugin-dir`, and the test configuration with `--config`.
  - The session uses the developer's own sign-in. It loads none of the developer's user-level plugins, skills, hooks or MCP servers.
  - The command refuses to start when a user-level override of the test configuration, `~/.slicewright/smoke.json`, exists.
- It grants up front exactly what the stages need, with an explicit allow list. Every other prompt is denied. It never bypasses permission checks.
- The run needs no person, no deployment and no GitHub. It needs no network beyond the model API.
- `start` does the same work in the background and returns at once.
- `wait <run folder>` blocks for less time than one shell command may last, and exits 3 while the run is still going. So a caller whose shell commands time out can still wait for a run of any length.
- `check <run folder>` evaluates the checks again on a kept run. It starts no session and writes nothing in the run folder.

### Time limit and cost

- A smoke run stops at a time limit of 90 minutes. Reaching it fails the run, and the command says that the time limit stopped it.
- The limit is set in one place, `LIMIT_MINUTES` at the top of `tests/smoke.sh`. `--minutes <n>` overrides it for one run.
- There is no cost ceiling. The cost is billed to the developer's own Claude Code sign-in. Only the time limit bounds what a run spends.

### Smoke checks

After the headless run ends, the command evaluates eight checks, each with its own name. It prints each one as passed or failed. It exits 0 only when all of them pass.

1. `session`: the headless session ended without an error, within the time limit and without an interrupt.
2. `isolation`: the session's own report of what it loaded shows the `slice` plugin from `plugins/slice`, and no other plugin and no MCP server. Claude Code's built-in plugins aren't counted. They come with Claude Code, appear in every session, and can't be turned off from the project.
3. `status`: the copy's `slice/status.md` has `status: done` and an empty `next`. Its Stages table has exactly one `done` row for each stage of the test configuration.
4. `records`: the copy's `slice/` folder holds `input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`. None of them is empty.
5. `tests`: the sample's own tests pass in a copy of the project.
6. `acceptance`: the acceptance check passes against a copy of the project.
7. `clean-tree`: the copy's version control shows no uncommitted change outside `slice/`.
8. `index`: the copy's `.slicewright/slices/index.md` has an entry for the slice, dated with the day the slice was created.

Checks 5 and 6 run in scratch copies. So the kept copy doesn't change, and the order of the checks doesn't matter.

### Run record

- Each smoke run, finished or stopped, keeps four things in one folder: its copy, the headless session's output, its cost and duration, and the check results. When the session stopped before it reported its cost or duration, the record says that each one is unknown.
- When a background run stopped without finishing, `wait` says so and evaluates the checks. It then records the run as ended, like any other run: the cost and duration, or unknown for each, and the report. It exits as the report says: 0 when every check passed, and 1 otherwise. A later `wait` prints the saved report and exits the same way.
- No command deletes a run folder. The last line of output names it.

### Self-test

`sh tests/selftest.sh` checks the tests' own checks. It starts no Claude session and finishes within 60 seconds.

- Each static case breaks one thing in a copy of `plugins/slice` and runs the static command on it. The command must fail and name the broken stage, skill or file.
- Each smoke case breaks one thing in a copy of the finished-run fixture, `tests/fixtures/finished-run/`, and evaluates the smoke checks on it. The copy is built with the same `prepare` step a real run uses. The broken case must fail its own check and pass every other check from 3 to 8.
- The unbroken plugin must pass. The unbroken fixture must pass every check except 1 and 2, which need a real session.
- A break that changes nothing counts as missed.
- It exits 0 only when every case passes. It removes its work folder only then. Otherwise it keeps the folder and names it.

### Where the tests run

- The project's tests that need no headless Claude run are exactly `sh tests/static.sh` and `sh tests/selftest.sh`. They run in the "build and tests" quality gates of the `implement`, `review-fix` and `bug-fix` stages, and by hand.
- `sh tests/smoke.sh` needs a headless Claude run. It runs in the `smoke` suite, in the `test` stage's `testAgents` in `.slicewright/config.json`, and by hand. It never runs in a task's Verify or in a quality gate, because it is too slow and costly.
- The `smoke` suite runs `start`. It then runs `wait <folder>` again and again while `wait` exits 3. It reports each check as one test, by its name, and the folder from the last line as the artifacts. A status 2 from either command means the suite didn't start.

### Documentation

- `overview/testing.md` covers these points:
  - what each level checks and why, its command, and which stages run it
  - what a run costs and how long it takes, as measured on the first passing smoke run
  - the static command and the self-test command, named as the project's tests that need no headless Claude run, and the smoke command, named as a test that needs one
  - where the sample and its acceptance check are, and how a run copies the sample
  - the test configuration's overrides, with their reasons
  - how to add a static check with its self-test case
  - that tests load the plugin only from `plugins/slice` and change only copies
- `overview/structure.md` lists the `tests/` folder.
- The "Checking a change" section of `AGENTS.md` names the static, self-test and smoke commands, and points to the testing page.

## Acceptance criteria

- Given the repo, when the files of the tests, fixtures and sample are listed, then each one is under `tests/`, and none is under `plugins/slice/` or `.slicewright/stable/`.
- Given the working copy, when the static command runs from the repo root, then it exits 0 within 60 seconds, and its code starts no Claude session.
- Given a copy of `plugins/slice` with exactly one of these broken:
  - a stage's `next` that names no stage
  - a `choices` value that names no stage
  - two stages with the same name
  - a stage's `skill` that names no skill folder
  - a `SKILL.md` whose `name` differs from its folder
  - an internal skill without `user-invocable: false`
  - a JSON file that doesn't parse

  When the static command runs on that copy, then it exits non-zero, and its output names the broken stage, skill or file. This holds for each case on its own.
- Given a fresh copy of the sample, when its own test command runs, then its tests pass without installing anything. When the acceptance check runs against that unchanged copy, then it fails, because the requested feature doesn't exist yet.
- Given a copy of the project that breaks any one outcome the request states, such as what stays the same without the option, or which letters become upper case under a UTF-8 locale, when the acceptance check runs against it, then it fails and names that case.
- Given the working copy, when the smoke command runs, then the headless run goes through the seven stages, and every check passes within 90 minutes.
- Given a finished run's kept copy, when its test configuration is compared with the working copy's `plugins/slice/defaults.json`, then each of the seven stages has the same `skill`, `executionMode` and `params` as the stage of the same name there, except for the overrides the testing page lists. Nothing under `tests/` holds a copy of those params.
- Given a copy of the finished-run fixture with exactly one of these broken:
  - a stage row set to `failed` in `status.md`
  - a record removed from `slice/`
  - a change that breaks the acceptance check
  - an uncommitted file outside `slice/`
  - the records index entry removed

  When the smoke checks are evaluated on that copy, then the command exits non-zero and names that check, without starting a headless run. This holds for each case on its own.
- Given the time limit overridden to one minute for one run, when the smoke command runs, then the run stops. The command exits non-zero and says that the time limit stopped it.
- Given any smoke run, finished or stopped, when it ends, then its last line of output names a folder that still exists afterwards. The folder holds the copy, the session output, the cost and duration or "unknown" for each, and the check results.
- Given a run folder whose background run stopped without finishing, when `wait` runs on it, then it records the cost and duration, or "unknown" for each, and the report. It exits 0 when every check passed and 1 otherwise. A later `wait` prints the saved report and exits the same way.
- Given the repo's `.slicewright/config.json`, when its `test` stage is read, then its `testAgents` has a `smoke` entry whose context does four things: it runs the smoke command, reports each check as one test by its name, reports the folder from the last line as the artifacts, and waits for a run longer than one shell command may last.
- Given a slice whose test stage runs with that entry, when the smoke run takes longer than 10 minutes, then the suite still reports `RAN`, with one test per check and the folder as its artifacts.
- Given the documentation and `AGENTS.md`, when a reviewer reads them, then:
  - `overview/testing.md` covers every point under Documentation above
  - `overview/structure.md` lists `tests/`
  - the "Checking a change" section names the three commands and points to the testing page
- Given the testing page, when an implement quality gate follows its context, "Run the project's tests that need no headless Claude run, when the documentation describes any", then the page names exactly the static command and the self-test command as those tests.
- Given the working copy, when the self-test command runs from the repo root, then it exits 0 within 60 seconds and starts no Claude session. It lists each broken static case and each broken smoke case as caught.
- Given the developer's user-level settings enable other plugins, hooks or MCP servers, when the smoke command runs, then the kept session output shows only the `slice` plugin, loaded from `plugins/slice`, and no MCP server. Claude Code's built-in plugins aren't counted. The `isolation` check passes.

## Limitations

- No smoke run has been made yet. So the testing page gives no measured cost or duration of a run. A real run also hasn't yet shown four things:
  - the seven-stage run passing every check
  - a one-minute time limit stopping a run
  - the `test` stage's suite waiting for, and reporting, a run longer than 10 minutes
  - the `isolation` check passing when the developer's own plugins, hooks and MCP servers are enabled

  Reason: a person accepted building the tests without a smoke run. A smoke run can't start before the tests are committed. A task's Verify and a quality gate may not run one. The test stage of the slice that built the tests loaded its configuration before the `smoke` suite existed. A follow-up slice runs the smoke test, proves these, and adds the measured numbers to the testing page.
