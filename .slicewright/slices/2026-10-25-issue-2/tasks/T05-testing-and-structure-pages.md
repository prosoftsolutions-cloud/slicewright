---
id: T05
title: Testing page and structure page
type: documentation
depends: [T04]
covers: [R9, AC12, AC13]
questions: [Q1, Q2]
---

# T05 Testing page and structure page

## Goal

Stage two pages: the new `overview/testing.md`, which describes the static level, the self-test and the smoke level, and the changed `overview/structure.md`, which lists `tests/`.

## Context

From spec.md:

- **R9** The documentation describes the tests. Item 3, the AGENTS.md section, is T06's.
  1. A new page, `overview/testing.md`, says:
     - what each level checks and why;
     - its command;
     - which stages of the pipeline run it;
     - what a run costs and how long it takes, as measured on the first passing smoke run.

     It names the static command and the self-test command as the project's tests that need no headless Claude run, and the smoke command as a test that needs one. It also says:
     - where the sample and its acceptance check are;
     - how a run copies the sample;
     - the test configuration's overrides, with their reasons;
     - how to add a static check, with its self-test case;
     - that tests load the plugin only from `plugins/slice`, and change only copies.
  2. `overview/structure.md` lists the `tests/` folder.
- **AC12** (this task's part) Given the slice's staged documentation, when a reviewer reads it, then `overview/testing.md` covers every item R9 lists, and `overview/structure.md` lists `tests/`.
- **AC13** Given the testing page, when an implement quality gate follows its context, "Run the project's tests that need no headless Claude run, when the documentation describes any", then the page names exactly the static command and the self-test command as those tests.
- The documentation is the OKF bundle in `./doc`:
  - Markdown pages with YAML frontmatter that has at least a `type`;
  - an `index.md` in every folder that lists its pages;
  - `overview/` describes the product, its technology and how the code is organized.

  Consolidate's `index` agent adds the new page to `overview/index.md` later.

From design.md:

- **D16 (Q1)** The page says where each run records its cost and duration, which is `run.txt` and `checks.txt`. It leaves out the line with the duration and cost of the first passing run.
  - Only the person adds that line, from a passing report, after a run by hand and before consolidate. No task or worker writes it.
  - Write no number from a run, no estimate, no placeholder and no TODO. The one-turn probe in spec.md, which cost about $0.01, is not a smoke run.
- **D9 (Q2)** Check 2 doesn't count Claude Code's built-in plugins, those with `"path": "builtin"`.
  - They come with Claude Code, appear in every session, and can't be turned off from the project.
  - What remains must be exactly `slice` at the absolute `plugins/slice` path, and `mcp_servers` must be empty.
  - The page says that built-in plugins aren't counted.
- **D5** There is one override, intake's `context`. It keeps the clean-tree check, and drops the check against a remote and the "ask user" step.
  - The default intake context asks for the "latest sources", which needs a remote that the copy doesn't have.
  - It also says to "ask user", which no one can answer headless.
- **D6** There is no `taskTypes` override.
  - The sample's `AGENTS.md` maps `greet.sh` and `test.sh` to backend code, and doc pages to `documentation`, so the run keeps testing the defaults' task types.
  - A `cli` task type is the fallback if a run ever returns `NO_TASK_TYPE`. It would be a second override, listed on the page.
- **D17** This task lands after the scripts work, because implement's quality gates read the staged pages and run the tests they name. So every script the page names exists when you start. Take each name, command, output line and constant from the scripts as built.
- **The bullet to add to `overview/structure.md`**, word for word:

  ```markdown
  - `tests/`: the plugin's tests, outside the plugin folder because an installed plugin is a copy of its folder. `static.sh` and `selftest.sh` need no model. `smoke.sh` runs the pipeline headless on a copy of the sample project in `tests/sample/`. `tests/fixtures/` holds what a finished run leaves, for the self-test. [Testing](testing.md) describes them.
  ```

- **The sections of `overview/testing.md`** (`type: overview`):
  1. **Levels.** For the static level, the self-test and the smoke level: what each checks and why, its command and options, and its exit statuses and output.
  2. **Where they run.**
     - The project's tests that need no headless Claude run are exactly `sh tests/static.sh` and `sh tests/selftest.sh`. They run in the quality gates of implement, review-fix and bug-fix, and by hand.
     - The smoke test, `sh tests/smoke.sh`, needs a headless Claude run. It runs in the test stage's `smoke` suite, with `start` and then `wait`, or by hand. It never runs in a task's Verify or a quality gate.
  3. **Cost and time.**
     - The static level and the self-test finish within 60 seconds.
     - The smoke level has a 90-minute limit, set as `LIMIT_MINUTES` in `smoke.sh`, and `--minutes` overrides it for one run.
     - There is no cost ceiling, and the cost is billed to the developer's Claude Code sign-in.
     - Each run's `run.txt` and `checks.txt` keep its cost and duration.
     - The duration and cost of the first passing run go here later (D16, Q1).
  4. **The sample.** Where the project, the request and the acceptance check are, and that the acceptance check is never copied.
  5. **How a run copies the sample.** The `prepare` steps, the run folder outside the repo and how `TMPDIR` moves it, and the run folder's layout.
  6. **The test configuration.**
     - It is generated from `plugins/slice/defaults.json` at run time: seven stages, chained with `next`, with no `onError` and no gates.
     - It has one override, intake's context, for the reason in D5.
     - There is no `taskTypes` override, for the reason in D6.
  7. **Isolation and permissions.**
     - The plugin loads only from `plugins/slice`, never from `.slicewright/stable/`.
     - The developer's user settings, plugins, skills, hooks and MCP servers are left out. The calling session's variables are unset.
     - The allow list is `tests/smoke/allowed-tools` plus the generated rules, and every prompt is denied.
     - The command refuses to start when `~/.slicewright/smoke.json` exists.
     - Tests change only copies, in new folders outside the repo.
  8. **The eight smoke checks.** For each: its number, its name and what it reads, including that check 2 doesn't count Claude Code's built-in plugins (D9). Also how `check` evaluates a kept run again.
  9. **Adding a static check.**
     - Add it to `static.sh`, `static/defaults.jq` or `static/skill.awk`, with a `FAIL` line that names its subject.
     - Add a case to `selftest.sh` that breaks that one thing in a copy and expects the subject.
     - Run `sh tests/selftest.sh`.

## Interfaces

**Provides:**

- `doc/overview/testing.md`, staged as `slice/docs/overview/testing.md` → used by T06, whose AGENTS.md section links to `doc/overview/testing.md`, and by implement's quality gates, which read the staged page

**Uses:**

These are all as built, in the repo when this task starts:

- from T01: `sh tests/static.sh [<plugin folder>]`, `tests/static/defaults.jq` and `tests/static/skill.awk`
- from T02: `tests/sample/project/`, `tests/sample/request.md`, `sh tests/sample/accept.sh <project folder>`, and `sh test.sh`, which is the sample's own test command
- from T03:
  - `sh tests/smoke.sh [--minutes <n>]`, `start [--minutes <n>]`, `wait <run folder>`, `check <run folder>`, `prepare <source folder> <run folder>`, and the internal `_finish`;
  - the report, the run folder layout and the constants at the top of `tests/smoke.sh`;
  - `tests/smoke/pipeline.json`, `tests/smoke/config.jq` and `tests/smoke/allowed-tools`;
  - the `smoke` entry in the `test` stage's `testAgents` of `.slicewright/config.json`.
- from T04: `sh tests/selftest.sh` and `tests/fixtures/finished-run/`
- from the existing code:
  - `doc/overview/structure.md`;
  - the `build and tests` quality gates of `implement`, `review-fix` and `bug-fix` in `.slicewright/config.json`;
  - the conventions in `doc/index.md` and `doc/overview/index.md`.

## Changes

- `slice/docs/overview/testing.md` (new): write it with the Write tool.
  - **Frontmatter:** only `type: overview`, like `doc/overview/structure.md`.
  - **Top:** the title `# Testing`, then a one-sentence intro, such as how the plugin in `plugins/slice` is tested before a new version is merged to `master`.
  - **Headings.** These nine `##` headings, in this order:
    1. `## Levels`, with three subsections, `### Static level`, `### Self-test` and `### Smoke level`
    2. `## Where they run`
    3. `## Cost and time`
    4. `## The sample`
    5. `## How a run copies the sample`
    6. `## The test configuration`
    7. `## Isolation and permissions`
    8. `## The eight smoke checks`
    9. `## Adding a static check`
  - **Style:**
    - Plain English in short sentences.
    - Paths in backticks, relative to the repo root.
    - No links to files outside `doc/`. A link to `structure.md` is fine.
    - Where content already lives in one file, name the file instead of copying it. That applies to the override text in `tests/smoke/pipeline.json`, the Bash allow rules in `tests/smoke/allowed-tools`, the defaults' params, and the full list of unset variables in `tests/smoke.sh`. Name two of the variables, such as `CLAUDECODE` and `CLAUDE_CODE_SESSION_ID`.
  - **When the page and a script disagree,** follow the script, and report the difference under Deviations.
  - What each section says:
    1. **Levels.** The tools needed are the `claude` CLI, `jq`, `git` and a POSIX `sh`. Each command runs from the repo root as `sh tests/<name>.sh`.
       - **Static level:** `sh tests/static.sh [<plugin folder>]`.
         - The folder defaults to `plugins/slice`, and a relative path resolves against the current folder.
         - **The four checks, in order:**
           - `validate`: both `claude plugin validate` runs. Only the exit status counts, so warnings pass.
           - `json`: every `*.json` file under the plugin folder and under `.claude-plugin/` holds exactly one JSON value.
           - `defaults`: the pipeline in `defaults.json`, checked by `tests/static/defaults.jq`.
           - `skills`: each `SKILL.md`'s frontmatter, checked by `tests/static/skill.awk`. The `name` equals the folder, the `description` isn't empty, and every skill except `new`, `resume` and `configure` has `user-invocable: false`.
         - **Why:** it catches a broken stage, a dangling `next`, `onError` or choice, and frontmatter that `claude plugin validate` misses. It needs no model, so it is cheap enough for every quality gate.
         - **Output:**
           - `PASS <check>`, or one `FAIL <check>: <subject>: <problem>` line per problem.
           - A failed validation is followed by the validator's output, indented.
           - The last line is `static: passed` or `static: failed, <n> problems`.
         - **Exit status:** 0 when every check passes, 1 when any fails, and 2 when the folder, `claude` or `jq` is missing.
       - **Self-test:** `sh tests/selftest.sh`.
         - **Why:** it proves, with no Claude session, that each check catches what it is meant to.
         - **Its work folder:** `mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX"`. It is removed only when every case passes. Otherwise the self-test prints `kept: <folder>`.
         - **The 14 cases:** a table, with each case's break in a few words.
           - The `static/…` cases break a copy of `plugins/slice` and run `static.sh` on it.
           - The `smoke/…` cases break a copy of the fixture and run `sh tests/smoke.sh check` on it.
           - Every broken case must fail and name its subject or check.
           - `static/unbroken` must exit 0.
           - `smoke/unbroken` must fail checks 1 and 2, which need a real session, and pass checks 3 to 8.
           - A break that changed nothing is `MISSED`.
         - **Output:** `ok <case>`, `caught <case>: <the matching line>`, or `MISSED <case>: <why>`, with the case's output indented. The last line is `selftest: passed, 14 cases` or `selftest: failed, <k> of 14 cases`. The exit status is 0, 1, or 2 when a tool is missing.
         - **The fixture:** `tests/fixtures/finished-run/` is an overlay on `tests/sample/project/`.
           - It holds only what a passing run adds or changes.
           - It has no `.gitignore` and no `.slicewright/smoke.json`, because `prepare` writes both.
           - The self-test copies the sample, lays the overlay on top, and runs `prepare` on the result.
           - Its `slice/` folder is committed in this repo, because the repo's `/slice/` rule matches only the root.
       - **Smoke level:**
         - It runs `/slice:new` headless with the sample's request, on a copy of the sample, through seven stages. Then it evaluates eight checks on what the run left.
         - **Why:** it shows that the working copy's pipeline still delivers a working feature, before the merge. Pass or fail rests only on checks a command evaluates on files, so a failure can be reproduced, and checking a run again costs nothing.
         - **A command table:** `sh tests/smoke.sh [--minutes <n>]`, `start [--minutes <n>]`, `wait <run folder>` (exits 3 while the run is going), `check <run folder>`, `prepare <source folder> <run folder>`, and `_finish` (internal, started by `start`).
         - The exit statuses, and what status 2 means.
         - **The output lines:** those of the foreground run and `start`; those of `wait` while the run is going and when `smoke_pid` is gone. Every command whose run folder exists ends with `run: <folder>`.
         - The report format, and the headless command, each as a `text` block, as built.
    2. **Where they run.**
       - **One sentence for AC13.** It appears once on the page, here, and contains the phrase "the project's tests that need no headless Claude run". It names exactly `sh tests/static.sh` and `sh tests/selftest.sh`, and no other command. For example: "The project's tests that need no headless Claude run are exactly `sh tests/static.sh` and `sh tests/selftest.sh`."
       - They run in the "build and tests" quality gates of the `implement`, `review-fix` and `bug-fix` stages in `.slicewright/config.json`, and by hand.
       - A sentence: "`sh tests/smoke.sh` needs a headless Claude run."
       - **The smoke test runs in the `test` stage's `smoke` suite.** The suite runs `start`, then `wait <folder>` again while it exits 3. It reports each check as one test by its name, and the run folder as the artifacts.
       - It also runs by hand. It never runs in a task's Verify or a quality gate, because it is too slow and costly.
       - **Wording elsewhere on the page:** describe `check` as "starts no session". Don't write "needs no headless Claude run" for any other command.
    3. **Cost and time.**
       - The static level and the self-test each finish within 60 seconds.
       - **The smoke level's limit** is 90 minutes. It is set once, as `LIMIT_MINUTES=90` at the top of `tests/smoke.sh`, and `--minutes <n>`, a positive whole number, overrides it for one run.
       - **The watchdog** checks the session every 5 seconds. At the limit it writes `<run>/timed-out`, sends TERM, and sends KILL 30 seconds later.
       - A foreground run that gets INT or TERM records `interrupted: yes`, still evaluates the checks, and prints the report.
       - **Cost:**
         - There is no cost ceiling, and no `--max-budget-usd`.
         - The cost is billed to the developer's own Claude Code sign-in.
         - Only the time limit bounds what a run spends.
         - Each run's `run.txt`, with `cost_usd` and `duration_ms`, and its `checks.txt` keep its cost and duration, or `unknown` for each.
       - The section ends there, with no measured numbers (D16).
    4. **The sample.**
       - `tests/sample/project/` (`greet.sh`, `test.sh`, `AGENTS.md`, `doc/`) is a small POSIX sh program.
         - Its own tests are `sh test.sh`, run inside the sample's folder, as its `AGENTS.md` names them. Say clearly that they are the sample's tests, not this repo's.
         - Its `doc/` is at the default `knowledge` path, `./doc`.
         - It needs no install and no network.
         - Its `AGENTS.md` instructs the pipeline inside a run. It is not this repo's instructions.
       - `tests/sample/request.md` asks for the `--shout` option, with every choice stated, so that clarify has no open question.
       - `tests/sample/accept.sh <project folder>` is the acceptance check.
         - It sits outside `project/`, and is never copied into a run, so the pipeline never sees or changes it.
         - It never writes to the folder. Its exit statuses are 0, 1 and 2.
         - It fails on the unchanged sample.
    5. **How a run copies the sample.**
       - **The run folder** is `${TMPDIR:-/tmp}/slicewright-smoke/<YYYYMMDDTHHMMSSZ>-<pid>`.
         - The command refuses a folder inside the repo, with exit 2.
         - Setting `TMPDIR` for one command moves the runs. The OS may clear old files there.
         - No command deletes a run folder.
       - **The `prepare` steps:**
         - `cp -R`;
         - the generated `.slicewright/smoke.json`;
         - `/slice/` appended to `.gitignore`;
         - `git init` with the local identity;
         - one commit of everything.

         Its rules: the run folder must not exist, its parent must exist, and it must be outside the repo.
       - **The run folder's layout**, as a `text` block, with the `run.txt` keys. When a key repeats, the last value counts.
    6. **The test configuration.**
       - **How it's made:** `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq <repo>/plugins/slice/defaults.json` generates it at run time.
         - The session uses it through `/slice:new --config smoke.json`, so the run's `status.md` shows `config: smoke.json`.
         - A stray override, or a stage that isn't in the defaults exactly once, makes `prepare` exit 2.
       - **The stages:**
         - The seven stages come from `stages` in `pipeline.json`.
         - Each is the whole default stage, without `next` and `onError`, with its `params` deep-merged with its override.
         - Each stage's `next` is the one after it, and `consolidate` has none.
         - The file holds only `pipeline`, so `sharedParams` come from the defaults.
         - Nothing under `tests/` copies the defaults' params.
         - There are no gates and no `onError`, so any error ends the run.
       - **Overrides:** exactly one, intake's `params.context`. Its text is in `pipeline.json`. The reason is D5's.
       - **No `taskTypes` override.** The reason is D6's, with the `cli` fallback.
       - **The rule:** every override in `pipeline.json` is listed on this page with its reason.
    7. **Isolation and permissions.**
       - **The plugin** loads only from `plugins/slice`, through `--plugin-dir`, and never from `.slicewright/stable/`.
       - **The developer's own setup** is left out. `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence` exclude the developer's user settings, plugins, skills, hooks and MCP servers.
       - **The calling session's variables** are unset. `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*` are kept, so the sign-in stays.
       - **A user override stops the run.** The command refuses to start, with exit 2, when `~/.slicewright/smoke.json` exists, because the runner would merge it in.
       - **Permissions** are `--permission-mode acceptEdits --permission-prompts none --allowedTools`, so every prompt is denied. The allow list is:
         - the rules in `tests/smoke/allowed-tools`;
         - `Skill(slice:run)`, `Skill(slice:tracking)`, and `Skill(<skill>)` for each skill in the generated configuration;
         - `Read(` on the absolute plugin folder, and `Read(~/.slicewright/**)`.

         The list is recorded as `allowed_tools` in `run.txt`. Denials appear in `permission_denials` in `session.jsonl`, and a denial doesn't hang the run.
       - **Tests change only copies**, in new folders outside the repo. The self-test removes only its own `mktemp -d` folder, and checks 5 and 6 remove only their own scratch copies.
    8. **The eight smoke checks.**
       - A numbered list, each item starting with the check's name in backticks, such as `` 1. `session`: ``. The order is `session`, `isolation`, `status`, `records`, `tests`, `acceptance`, `clean-tree` and `index`.
       - Each item says what the check reads, as built.
       - **Check 2:**
         - It doesn't count Claude Code's built-in plugins, those with `"path": "builtin"`.
         - They come with Claude Code, appear in every session, and can't be turned off from the project.
         - What remains must be exactly `slice` at the absolute `plugins/slice` path, and `mcp_servers` must be empty.
       - **Checks 5 and 6** run in a scratch copy, limited to `CHECK_SECONDS`, so the order of the checks doesn't matter.
       - **Checking a kept run again:** `sh tests/smoke.sh check <run folder>` evaluates it again. It starts no session and writes nothing in the run folder.
    9. **Adding a static check.** These steps:
       1. Add the check to `tests/static.sh`, `tests/static/defaults.jq` or `tests/static/skill.awk`, with a `FAIL` line that names its subject.
       2. Add a case to `tests/selftest.sh` that breaks that one thing in a copy and expects the subject. Add the case to this page's table.
       3. Run `sh tests/selftest.sh`, and check that `sh tests/static.sh` still passes on `plugins/slice`.
- `slice/docs/overview/structure.md` (new in the staging folder, a changed page of the documentation):
  - Copy `doc/overview/structure.md` exactly, all 12 lines, ending in a newline.
  - Add the bullet in Context, word for word, as a new last line.

## Verify

Run each command from the repo root.

**The pages:**

- `head -n 7 slice/docs/overview/testing.md`: `---`, `type: overview`, `---`, then `# Testing` and the intro.
- `grep -n "^##" slice/docs/overview/testing.md`: the nine `##` headings and the three `###` headings, in the order above.
- **R9.2, AC12.** `diff doc/overview/structure.md slice/docs/overview/structure.md`: exit 1, showing only `12a13` and the bullet above, word for word.

**AC13:**

- `grep -n -i "tests that need no headless Claude run" slice/docs/overview/testing.md`: exactly one line, under "Where they run". It names `sh tests/static.sh` and `sh tests/selftest.sh`, and no other command.
- `grep -n "needs a headless Claude run" slice/docs/overview/testing.md`: a line that names `sh tests/smoke.sh`.
- `grep -n -o -E "sh tests/[a-z/]+\.sh" slice/docs/overview/testing.md`: only `sh tests/static.sh`, `sh tests/selftest.sh`, `sh tests/smoke.sh` and `sh tests/sample/accept.sh`.

**The config the page describes:**

- `jq -r '.pipeline[] | select(.params.qualityGateAgents) | .name + ": " + .params.qualityGateAgents[0].context' .slicewright/config.json`: `implement`, `review-fix` and `bug-fix`, each with "Run the project's tests that need no headless Claude run". These are the stages the page names.
- `jq -r '.pipeline[] | select(.name == "test") | .params.testAgents[] | .name + ": " + .context' .slicewright/config.json`: `smoke`, which runs `start` and then `wait`, as the page says.

**Paths, constants and flags against the code:**

- `ls -d tests/static.sh tests/static/defaults.jq tests/static/skill.awk tests/smoke.sh tests/smoke/pipeline.json tests/smoke/config.jq tests/smoke/allowed-tools tests/selftest.sh tests/sample/project/greet.sh tests/sample/project/test.sh tests/sample/project/AGENTS.md tests/sample/project/doc tests/sample/request.md tests/sample/accept.sh tests/fixtures/finished-run`: every path, with no error.
- `grep -n -o -E "tests/[A-Za-z0-9_./-]+" slice/docs/overview/testing.md`: every path the page names is in the list above, or under a path in it.
- `grep -n -E "^(LIMIT_MINUTES|WAIT_SECONDS|CHECK_SECONDS|CONFIG_NAME|SLICE_DIR|RECORDS|TEST_COMMAND|RECORDS_INDEX)=" tests/smoke.sh`: eight lines. Every value the page states matches them.
- `grep -n -F -e "--setting-sources" -e "--strict-mcp-config" -e "--no-session-persistence" -e "--plugin-dir" -e "--permission-mode" -e "--permission-prompts" -e "--allowedTools" -e "--output-format" -e "--verbose" tests/smoke.sh slice/docs/overview/testing.md`: the same flags, with the same values, in both files.
- `grep -n -E "unset|\.slicewright/smoke\.json|builtin|mcp_servers" tests/smoke.sh`: each variable the page names is in the unset, along with the refusal for `~/.slicewright/smoke.json` and check 2's `builtin` filter.

**Check names, output lines and cases:**

- `grep -n -w -F -e session -e isolation -e status -e records -e tests -e acceptance -e clean-tree -e index tests/smoke.sh`: where each of the eight checks is named. Their numbers match the page.
- `grep -n -E '^[1-8]\. `[a-z-]+`' slice/docs/overview/testing.md`: exactly eight lines, from 1 `session` to 8 `index`.
- `grep -n -F -e "PASS" -e "FAIL" -e "static: passed" -e "static: failed" tests/static.sh`: the output format the page gives.
- `grep -n -F -e "caught " -e "MISSED " -e "kept: " -e "selftest: passed" -e "selftest: failed" tests/selftest.sh`: the same.
- `grep -n -F -e "prepared: " -e "session: started" -e "running: the session has not ended yet" -e "ended: the background run stopped without finishing" -e "time limit: the session was stopped after" -e "result: " -e "run: " tests/smoke.sh`: each output line the page quotes.
- ``grep -n -o -E '`(static|smoke)/[a-z-]+`' slice/docs/overview/testing.md``: the 14 case names, each in backticks. Paths such as `tests/static/defaults.jq` aren't in backticks on their own like this, so they don't match.
- `grep -n -o -E '(static|smoke)/[a-z-]+' tests/selftest.sh`: the same 14 case names. Ignore a match that is part of a path, such as `tests/static/`.

**The test configuration and the fixture:**

- `jq -c '{stages, overrides: (.overrides | map_values(keys))}' tests/smoke/pipeline.json`: the seven stages, in the page's order, and `{"intake":["context"]}`.
- `jq -r '.pipeline[] | select(.name == "intake") | .params.context' plugins/slice/defaults.json`: shows "latest sources" and "ask user", the reason D5 gives.
- `grep -n -x -F "/slice/" .gitignore`: `1:/slice/`.
- `git log --oneline -1 -- tests/fixtures/finished-run/slice/status.md`: one commit, so the fixture's `slice/` is tracked.

**D16, and no published page:**

- `grep -n -E '\$[0-9]' slice/docs/overview/testing.md`: no output. The page states no dollar amount.
- `grep -c -F "Bash(" slice/docs/overview/testing.md`: `0`. The allow list isn't copied.
- `git status --porcelain doc`: no output. No published page changed.

**AC12, this task's part.** Go through R9.1 item by item:

| R9.1 item | Section |
|---|---|
| What each level checks and why, and its command | Levels |
| Which stages run it | Where they run |
| The tests that need no headless run, and the smoke test that needs one | Where they run |
| Cost and time | Cost and time: where each run records them. The measured line is the person's (Q1), and the dollar check above shows none was invented. |
| Where the sample and the acceptance check are | The sample |
| How a run copies the sample | How a run copies the sample |
| The overrides and their reasons | The test configuration |
| How to add a static check, with its self-test case | Adding a static check |
| The plugin only from `plugins/slice`, and only copies change | Isolation and permissions |

## Boundaries

- Write only `slice/docs/overview/testing.md` and `slice/docs/overview/structure.md`.
- Leave alone:
  - everything under `doc/`, including `doc/overview/index.md`, to which consolidate's `index` agent adds the page;
  - `AGENTS.md`, which T06 owns;
  - everything under `tests/`, which T01 to T04 own;
  - `.slicewright/config.json`, `plugins/slice/`, `.slicewright/stable/`, `README.md` and `.claude/settings.json`.
- Never run `sh tests/smoke.sh` with no subcommand, or `start`, `_finish` or `prepare`. The first three start a headless session that costs money and may run for up to 90 minutes. `prepare` writes a run folder this task doesn't need.
- Never change a script. When the page and a script disagree, the page follows the script, and the difference goes under Deviations.
- The measured cost and duration stay out of the page, with no placeholder (D16).
