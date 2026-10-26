---
slice: issue-2
---

# Design: Tests for new plugin versions

## Context

spec.md gives the goal, the requirements and the acceptance criteria. This section gives only what the approach depends on.

- The repo has no tests, no sample project and no runtime or package manager. The tools are the `claude` CLI, `jq` 1.7, `git` and `/bin/sh`. On macOS, `/bin/sh` is bash in POSIX mode, and `/bin/dash` also exists. There is no `timeout` command, so a time limit must be built into the script.
- The runner (`plugins/slice/skills/run/SKILL.md`) takes `/slice:new --config <name> <request>`. The name must be a plain file name. The runner merges `defaults.json`, then `~/.slicewright/<name>`, then `.slicewright/<name>`, then `.slicewright/<name>.local.json`. A later `pipeline` replaces the earlier one whole, and `sharedParams` merge key by key. With no `onError`, an error ends the run. After the last stage, the run stops.
- The status file, `status.md`, has `status:` and `next:` in its frontmatter and a `## Stages` table. A rerun of a stage gets its own row, `<stage> #2`. Consolidate adds `## {date} {name}: {title}` to `.slicewright/slices/index.md`. The date is the date part of `created` in `status.md`, and the name is the id or a slug of the title. Implement returns `DIRTY_TREE` for any uncommitted change outside `slice/`. Plan returns `NO_TASK_TYPE` for work that fits no task type.
- The fixed suite prompt in `skills/test/SKILL.md` forbids `cd` and chaining with `&&`, `;`, pipes or loops. It says to give long commands the longest timeout the shell tool allows, and one shell command lasts at most 10 minutes.
- The repo's task types matter for the plan. The `plugin` type's context forbids editing `.slicewright/config.json`. So the `testAgents` entry belongs to a `test` task, with the smoke command it runs.
- Facts measured during this stage, with Claude Code 2.1.310:
  - **Validation:** `claude plugin validate` takes about 0.5 s and makes no model call. It exits 0 with warnings and 1 with errors. It doesn't catch a SKILL.md whose `name` differs from its folder, or a missing `user-invocable`.
  - **The one-turn headless probe:** it ran with `--setting-sources project,local --strict-mcp-config --plugin-dir <repo>/plugins/slice` and the developer's OAuth sign-in. The init event in its stream-json listed `slice` at the given path, plus three built-in plugins with `"path": "builtin"`. It listed no MCP server and none of the developer's synced skills. The last event, `type: result`, carried `is_error`, `subtype`, `total_cost_usd` and `duration_ms`.
  - **Permissions:** `Bash(sh test.sh:*)` matched `sh test.sh`. Under `acceptEdits`, `touch` and `mkdir` inside the working folder were allowed. A command or read with no rule was denied at once and recorded in `permission_denials`. It didn't hang.
  - **A detached run:** a process started with `nohup … &` from a script outlived the shell call that started it, and that call returned at once. A `sleep` loop inside a script isn't blocked.
  - **The request text:** a multi-line request with backticks, quotes and `$` reached `$ARGUMENTS` intact.

## Approach

Three POSIX `sh` commands make up the tests. Each is run from the repo root as `sh tests/<name>.sh`.

**Static level.** `sh tests/static.sh [plugin folder]` runs four checks: `validate`, `json`, `defaults` and `skills`. The `defaults` check is a jq program on `defaults.json`. The `skills` check is an awk program on each SKILL.md's frontmatter. The command prints one `FAIL` line per problem, naming its stage, skill or file. Its only `claude` calls are the two local validations, so it needs no model.

**Smoke level.** `sh tests/smoke.sh` works in these steps:

1. It makes a new run folder outside the repo.
2. Its `prepare` step copies `tests/sample/project` into the run folder. It writes `.slicewright/smoke.json` with jq from the working copy's `plugins/slice/defaults.json`: the seven stages, chained with `next`, with intake's context as the one override. It adds `/slice/` to the copy's `.gitignore`. It makes the copy a git repository with one commit of everything.
3. It starts `claude -p "/slice:new --config smoke.json <request>"` in the copy. The session loads only `plugins/slice`, keeps the developer's sign-in, and gets an explicit allow list.
4. A watchdog stops the session at the time limit, 90 minutes unless `--minutes` overrides it.
5. It records the exit status, the cost and the duration, or `unknown` for each.
6. It evaluates eight named checks on the files the run left.
7. It prints them and ends with `run: <folder>`.

The test stage can't hold one shell command for 90 minutes. So `start` does the same work in the background and returns at once. `wait <folder>` blocks for at most 9 minutes and is run again until the run has ended. `check <folder>` evaluates the checks again on a kept run, without a new session.

**Self-test.** `sh tests/selftest.sh` breaks one thing at a time in temporary copies. For AC3, it breaks a copy of `plugins/slice` and runs `static.sh` on it. For AC7, it builds the finished-run fixture with the same `prepare` step a real run uses, breaks a copy, and runs `smoke.sh check` on it. Every case must fail with its check named. The unbroken fixture must pass checks 3 to 8.

**Wiring and documentation.**
- One `smoke` entry in the `test` stage's `testAgents` runs `start`, then `wait`, and reports each check as a test.
- The implement quality gates already run "the project's tests that need no headless Claude run, when the documentation describes any". The new page `overview/testing.md` names exactly `static.sh` and `selftest.sh` as those tests.
- `overview/structure.md` lists `tests/`.
- AGENTS.md's "Checking a change" section names the three commands and points to the testing page.
- Both of them land only once the scripts they name work (D17), because the quality gates between waves read them.

## Affected areas

| Area | Files or modules | Change |
|---|---|---|
| Static level | `tests/static.sh`, `tests/static/defaults.jq`, `tests/static/skill.awk` | new (R2) |
| Smoke level | `tests/smoke.sh`, `tests/smoke/pipeline.json`, `tests/smoke/config.jq`, `tests/smoke/allowed-tools` | new (R4–R7) |
| Sample | `tests/sample/project/` (`greet.sh`, `test.sh`, `AGENTS.md`, `doc/`), `tests/sample/request.md`, `tests/sample/accept.sh` | new (R3) |
| Fixture and self-test | `tests/fixtures/finished-run/`, `tests/selftest.sh` | new (R10) |
| Pipeline wiring | `.slicewright/config.json` | one entry in the `test` stage's `testAgents`, nothing else (R8). This is a `test` task, because the `plugin` type's context forbids editing this file. |
| Project instructions | `AGENTS.md` | only the "Checking a change" section (R9.3) |
| Documentation | `slice/docs/overview/testing.md` (new), `slice/docs/overview/structure.md` | staged pages (R9.1, R9.2). Consolidate's `index` agent adds the page to `overview/index.md`. |

Nothing under `plugins/slice/` or `.slicewright/stable/` changes.

## Decisions

### D1 Three POSIX `sh` scripts, run as `sh tests/<name>.sh`

- **Choice:** `static.sh`, `smoke.sh` and `selftest.sh` at the top of `tests/`. Their jq, awk and data files are in `tests/static/` and `tests/smoke/`. Every script uses POSIX sh only: no `local`, no arrays, no `[[ ]]`, no `sed -i`, no `grep -r`.
- **Why:** they need no executable bit and no runtime beyond the four tools. Each is one command with one permission prefix, such as `Bash(sh tests/smoke.sh:*)`.
- **Alternatives:**
  - `./tests/…` with an executable bit: needs a chmod in version control and a different prefix.
  - Bash: it isn't on every Linux by default, and the spec allows a POSIX shell.
  - A test framework such as bats: a new tool to install.

### D2 One smoke script with subcommands

- **Choice:** `sh tests/smoke.sh [--minutes <n>]` runs in the foreground. `start`, `wait`, `check` and `prepare` are subcommands, and `_finish` is internal, for the detached part.
- **Why:** there is one permission prefix and one place for the checks. The self-test builds its fixture with `prepare` and evaluates it with `check`, which is the code a real run uses.
- **Alternatives:**
  - Separate scripts: more paths and more permission rules.
  - A sourced library: a second interface for the same functions.

### D3 The test stage waits with `start`, then `wait` again and again

- **Choice:** `start` prepares the copy, starts the session part with `nohup`, and returns at once. `wait <folder>` blocks inside the script for at most 540 seconds. It exits 3 while the run is going, and it prints the recorded report once the run has ended.
- **Why:** it needs only the Bash tool. It keeps the suite prompt's rules: one command per call, no loops in the command, and every call under 10 minutes. The probe showed that a detached run outlives the call that started it.
- **Alternatives:**
  - One blocking command: a shell call lasts at most 10 minutes.
  - Bash `run_in_background` or Monitor: their notifications reach a subagent only between turns, and an until-loop in the command breaks the suite prompt.

### D4 The test configuration is generated at run time from the working copy's defaults

- **Choice:** `prepare` runs `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq <repo>/plugins/slice/defaults.json`. It writes the result to `<copy>/.slicewright/smoke.json`, and the session starts with `/slice:new --config smoke.json`.
  - Each of the seven stages is the whole default stage of that name, without its `next` and `onError`.
  - Its `params` are deep-merged with the override.
  - `next` is set to the following stage. The last stage, consolidate, has none.
  - The file holds only `pipeline`, so `sharedParams` come from the defaults.
- **Why:** AC6 then holds by construction, and nothing under `tests/` copies params. A named configuration leaves the copy's `config.json` free.
- **Alternatives:**
  - Picking only `skill`, `executionMode` and `params`: this would drop `agent` or `args` if a default stage gains them.
  - Writing `.slicewright/config.json` in the copy: it hides which configuration the run used, while `config: smoke.json` in `status.md` shows it.
  - A self-test case that compares the generated configuration with the defaults: R10 doesn't list it, and `config.jq` makes AC6 hold by construction. The smoke task's Verify compares them once instead.

### D5 Exactly one override: intake's `context`

- **Choice:** the override is in `tests/smoke/pipeline.json` (Contracts). It keeps the clean-tree check and drops the check against a remote and the "ask user" step.
- **Why:** the default intake context asks for the "latest sources", which needs a remote that the copy doesn't have, and it says to "ask user", which no one can answer headless. No other param of the seven stages needs a person, a remote, GitHub or a deployment.
- **Alternatives:** overriding clarify so it asks no blocking question. That changes what the run tests, and the spec says the fully specified request covers it.

### D6 No `taskTypes` override

- **Choice:** the sample's `AGENTS.md` says that, in the pipeline's task types, `greet.sh` and `test.sh` are backend code: the program and the command-line interface it exposes. Doc pages are `documentation`.
- **Why:** the run keeps testing the defaults' task types, and there is one override fewer.
- **Alternatives:** adding a `cli` type in the test configuration's `sharedParams`. This is the fallback if a run ever returns `NO_TASK_TYPE` (Risks). It would be a second override, listed on the testing page.

### D7 Isolate the headless session from the developer's own setup

- **Choice:**
  - Flags: `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence`, with `--plugin-dir <repo>/plugins/slice` as the only plugin source.
  - Before `exec claude`, it unsets the calling session's variables: `CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SESSION_ATTENDED`, `CLAUDE_CODE_MESSAGING_SOCKET`, `CLAUDE_CODE_MESSAGING_TOKEN`, `CLAUDE_PID`, `CLAUDE_EFFORT` and `AI_AGENT`.
  - It keeps `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`.
  - It refuses to start, with exit 2, when `~/.slicewright/smoke.json` exists, because the runner would merge it in.
- **Why:** pass or fail then depends only on the working copy and the sample. The probe confirmed that user plugins, synced skills, hooks and MCP servers, including the claude.ai connectors, stay out, while the OAuth sign-in stays. A run from a stage agent then behaves like a run from a terminal: it doesn't inherit the caller's effort or messaging socket.
- **Alternatives:**
  - `--bare`: it authenticates only with an API key, never the developer's sign-in.
  - `--safe-mode`: it also drops CLAUDE.md and the project's instructions.
  - Inheriting the variables: cost and behavior would then depend on the caller.

### D8 Permissions: `acceptEdits`, prompts denied, and an explicit allow list

- **Choice:** `--permission-mode acceptEdits --permission-prompts none --allowedTools "<rules>"`. The rules are joined with commas into one argument. They are:
  - the Bash rules in `tests/smoke/allowed-tools` (Contracts);
  - `Skill(slice:run)`, `Skill(slice:tracking)`, and `Skill(<skill>)` for every `skill` in the generated configuration;
  - `Read(/<absolute plugin folder>/**)`, which is written `Read(//Users/…)`, and `Read(~/.slicewright/**)`, because the runner reads both outside the copy.

  Edits, and file commands inside the copy, come from `acceptEdits`.
- **Why:** a headless run in a new folder can't answer a prompt and ignores the folder's allow rules (Constraints). A denied call is recorded in `permission_denials` and doesn't hang.
- **Alternatives:**
  - `bypassPermissions` or `--dangerously-skip-permissions`: the constraints forbid both.
  - Rules for `cp` or `mkdir`: they would also allow those commands outside the copy.

### D9 Check 2 doesn't count Claude Code's built-in plugins

- **Choice:** among the plugins in the init event, those with `"path": "builtin"` are left out. What remains must be exactly the `slice` plugin at the absolute `plugins/slice` path. `mcp_servers` must be empty.
- **Why:** built-in plugins come with Claude Code and appear in every session. They are not the developer's plugins, which R4.4 excludes, so counting them would fail every run. The testing page says that built-in plugins aren't counted. This reads AC15 and R6.2 more narrowly than their words, and the person confirmed it (Q2: A).
- **Alternatives:** requiring an empty list apart from `slice`. That can't pass.

### D10 The time limit is a watchdog inside `smoke.sh`

- **Choice:**
  - `LIMIT_MINUTES=90` at the top of `smoke.sh` is the one place where the limit is set. `--minutes <n>` sets a positive whole number for one run.
  - A watchdog subshell checks the session's process every 5 seconds. At the limit it writes `<run>/timed-out`, sends TERM, and sends KILL after 30 seconds.
  - A foreground run traps INT and TERM. It stops the session, records `interrupted: yes`, still evaluates the checks, and prints the report.
- **Why:** macOS has no `timeout` command, and the tests may use only the four tools.
- **Alternatives:** `timeout` or `gtimeout` from coreutils, which isn't installed. perl's `alarm`, which isn't one of the four tools.

### D11 Checks 5 and 6 run in a scratch copy

- **Choice:** `sh test.sh` and `sh <repo>/tests/sample/accept.sh <scratch>` run in a `mktemp -d` copy of the project. Each is limited to 120 seconds by the same watchdog, with stdin from `/dev/null`. The scratch copy is removed afterwards, but only when it is the non-empty path that `mktemp -d` returned, outside the run folder.
- **Why:** running the tests must not change the kept copy. Otherwise check 7, and a later `check`, would depend on the order of the checks.
- **Alternatives:** running them in place, which makes the order of the checks matter.

### D12 Where the checks take their expected values

- **Choice:**
  - Check 3 takes the expected stage names from the copy's own `.slicewright/smoke.json`.
  - Check 8 looks for a line in the records index that starts with `## <date> `, where the date is the first ten characters of `created` in `status.md`.
  - `slice/`, the records list, `sh test.sh` and `.slicewright/slices/index.md` are constants at the top of `smoke.sh`, as the spec names them.
- **Why:** the stage list then has one source, `pipeline.json`. Consolidate takes the date from `status.md`, but the name and title in the entry are the model's wording, and the sample's request has no id.
- **Alternatives:**
  - A second, hardcoded list of stages.
  - An exact match on `## <date> <slug>: <title>`: it would fail on wording alone.

### D13 The run folder

- **Choice:** `${TMPDIR:-/tmp}/slicewright-smoke/<UTC time as YYYYMMDDTHHMMSSZ>-<pid>`. The command refuses, with exit 2, a folder inside the repo. Setting `TMPDIR` for one command moves the runs elsewhere.
- **Why:** the folder is outside the repo, new for every run, and writable for every user.
- **Alternatives:**
  - A folder under `~/.cache`: it leaves state in the home folder.
  - A separate variable for the runs' folder: `TMPDIR` already does that, and the spec doesn't ask for a new one.

### D14 The finished-run fixture is an overlay on the sample

- **Choice:** `tests/fixtures/finished-run/` holds only what a passing run adds or changes: `greet.sh` with the feature, the spec page that mentions `--shout`, the `slice/` records, and the records index. The self-test copies the sample, lays the overlay on top of it, and runs `smoke.sh prepare` on the result.
- **Why:** there is no second copy of the sample to drift from it. Breaking the acceptance check is then simple: put the sample's own `greet.sh` back and commit. Only check 6 fails.
- **Alternatives:** a full snapshot of a run. It duplicates the sample and its git history.

### D15 `slice/` is ignored by a `.gitignore` that `prepare` writes and commits

- **Choice:** `prepare` appends `/slice/` to `<copy>/.gitignore` before the one commit. The sample and the fixture under `tests/` have no `.gitignore` of their own.
- **Why:** the pipeline sees the rule as part of the project, and no `.gitignore` inside `tests/` can hide the fixture's `slice/` from this repo. The repo's own rule, `/slice/`, is anchored to the root, so `tests/fixtures/finished-run/slice/` is tracked.
- **Alternatives:** `.git/info/exclude`. The pipeline's agents can't see it, so they might treat `slice/` as uncommitted work.

### D16 The testing page ships without the measured cost and time; a follow-up slice adds them

- **Choice:** the documentation task writes all of `overview/testing.md`, including where each run records its cost and duration. It leaves out the numbers from the first passing run, with no placeholder. No task, worker or review-fix writes them. A follow-up slice runs the smoke test, adds the measured duration and cost, and proves the criteria that need a real run. A review finding about the missing numbers, or about those criteria, is settled by accepting it at review-decision with this reason, not by a fix task. The person chose this (Q1: B).
- **Why:** no smoke run happens in this slice. It can't run before implement has committed the tests, a task's Verify or a quality gate may not run one (Constraints), and this run's test stage loaded the configuration before the `testAgents` entry existed. A worker that can't run one could only invent the numbers. This leaves R9.1's measured numbers out of this slice.
- **Alternatives:**
  - A) The person stops the run after implement, runs `sh tests/smoke.sh` and `--minutes 1` by hand, adds the numbers, and resumes so the test stage runs the suite. It meets R9.1 within the slice, but takes manual steps and at least two full runs with no cost ceiling. The person rejected it.
  - C) Run it by hand after release and add the numbers in a separate commit. The pull request then opens before any smoke run has passed, and review never sees the commit.

### D17 The testing page and the AGENTS.md section land after the scripts work

- **Choice:** the documentation task, which stages `overview/testing.md` and `overview/structure.md`, and the task that changes AGENTS.md's "Checking a change" section both depend on the self-test task. The self-test task in turn depends on the static, smoke, sample and fixture work. So the pages land in the same wave as the last script or a later one.
- **Why:** implement runs its quality gates between waves, and the gate agents read the staged pages and AGENTS.md. The repo's gate context runs "the project's tests that need no headless Claude run, when the documentation describes any". If the pages land early, a gate runs `sh tests/static.sh` or `sh tests/selftest.sh` before they work. It then uses up its fix rounds and ends in `CHECK_FAILED`.
- **Alternatives:** documentation tasks in the first wave, since they need only the interfaces. That breaks the gates, as above.

## Contracts

### Static level: `sh tests/static.sh [<plugin folder>]`

- **The folder.** The default is `<repo>/plugins/slice`. A relative path resolves against the current folder. The repo root is the parent of the script's own folder.
- **Checks, in order:**
  - `validate`: `claude plugin validate <repo>` and `claude plugin validate <plugin folder>`. Only the exit status counts, so warnings pass.
  - `json`: `jq -e -s 'length == 1'` on every `*.json` file under the plugin folder and under `<repo>/.claude-plugin`. A file passes only when it holds exactly one JSON value, so an empty file and a file with several values both fail.
  - `defaults`: `jq -r --argjson skills '<JSON list of the folder names under skills/ that hold a SKILL.md>' -f tests/static/defaults.jq <plugin>/defaults.json`.
  - `skills`: `awk -v file=<path> -v folder=<name> -v internal=<1|0> -f tests/static/skill.awk <path>` on each skill folder. `internal` is 0 only for `new`, `resume` and `configure`.
- **Output:** for each check, `PASS <check>`, or one line per problem: `FAIL <check>: <subject>: <problem>`. A failed validation prints `FAIL validate: <folder>: claude plugin validate failed`, then the validator's output indented by two spaces. The last line is `static: passed` or `static: failed, <n> problems`.
- **Exit status:** 0 when every check passes; 1 when any check fails; 2 when the folder is missing, or `claude` or `jq` is missing.
- **Problems in the `defaults` check.** The subjects are `stage <name>` (`stage number <n>` when the stage has no name), `sharedParams` or `pipeline`.
  - `sharedParams: activeSlicePath is missing or empty`
  - `pipeline: missing or empty`
  - `stage number <n>: has no name`
  - `stage <name>: <k> stages have this name`
  - `stage <name>: executionMode <value as JSON> is not inline or fork` (the stage's own `executionMode`)
  - `stage <name>: params is not an object`
  - `stage <name>: has no skill and no params.context`
  - `stage <name>: skill <value as JSON> names no skill folder`
  - `stage <name>: params skill <value as JSON> names no skill folder` (any `skill` key at any depth in the stage's `params`)
  - `sharedParams: skill <value as JSON> names no skill folder` (any depth)
  - `stage <name>: params sets activeSlicePath`
  - `stage <name>: next names no stage: <value as JSON>`, and the same for `onError` (only for values other than `null`)
  - `stage <name>: choice <key> names no stage: <value as JSON>` (values other than `null` in `params.choices`)
  - `<file>: does not parse`, when jq can't read `defaults.json`

  A skill value is valid when it is `TBD`, or `slice:<name>` where `<name>` is in `$skills`. On the current defaults, the program prints nothing.
- **Problems in the `skills` check:**
  - `<folder path>: has no SKILL.md` (static.sh prints it)
  - `<file>: has no frontmatter between --- lines`
  - `<file>: name is missing`, or `<file>: name is "<value>", not "<folder>"`
  - `<file>: description is missing or empty`
  - `<file>: user-invocable is not false, and the skill is internal`

  The frontmatter is the lines between the first line, which must be `---`, and the next `---`. Values are trimmed of spaces and a trailing CR, and one pair of surrounding quotes is removed.
- **Problems in the `json` check:** `FAIL json: <file>: does not parse`, or `FAIL json: <file>: does not hold exactly one JSON value`.

### Smoke level: `sh tests/smoke.sh`

| Command | What it does | Exit status |
|---|---|---|
| `sh tests/smoke.sh [--minutes <n>]` | in the foreground: prepare, session, checks, report | 0 all checks pass · 1 a check failed · 2 couldn't run |
| `sh tests/smoke.sh start [--minutes <n>]` | prepares, starts the session part in the background, and returns | 0 started · 2 couldn't run |
| `sh tests/smoke.sh wait <run folder>` | waits at most `WAIT_SECONDS` for `<run>/ended` | 0 or 1 once ended, from the recorded result · 3 still running · 2 not a run folder |
| `sh tests/smoke.sh check <run folder>` | evaluates the eight checks again and prints the report; writes nothing in the run folder | 0 · 1 · 2 not a run folder |
| `sh tests/smoke.sh prepare <source folder> <run folder>` | the copy, the configuration and the commit. The run folder must not exist, its parent must exist, and it must be outside the repo. | 0 · 2 |
| `sh tests/smoke.sh _finish <run folder>` | internal: the session part, which `start` starts with `nohup` | — |

- **Status 2** means the command couldn't run: wrong usage, a missing tool, `~/.slicewright/smoke.json` exists, the run folder is inside the repo, `prepare` failed, or the folder isn't a run folder because it has no `project/`.
- **Constants** at the top of `smoke.sh`:
  - `LIMIT_MINUTES=90`
  - `WAIT_SECONDS=540`
  - `CHECK_SECONDS=120`
  - `CONFIG_NAME=smoke.json`
  - `SLICE_DIR=slice`
  - `RECORDS="input.md spec.md design.md plan.md implement.md code-reviews.md"`
  - `TEST_COMMAND="sh test.sh"`
  - `RECORDS_INDEX=.slicewright/slices/index.md`
- **Output lines:**
  - The foreground run prints `run: <folder>`, `prepared: <folder>/project`, `session: started, time limit <n> minutes`, then the report.
  - `start` prints `prepared: <folder>/project`, `session: started in the background, time limit <n> minutes`, `next: sh tests/smoke.sh wait <folder>`, `run: <folder>`.
  - `wait`, while the run is going, prints `running: the session has not ended yet`, then `run: <folder>`.
  - If `ended` is missing and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report, and exits 1.
  - Whatever its exit status, every command whose run folder exists ends with `run: <folder>`. This includes exit 2 after `prepare` fails. An error message comes before that line.
- **The report**, which `run`, `wait` and `check` print, and which a run saves as `checks.txt`:

  ```text
  PASS|FAIL <n> <name>: <detail>        one line for each check, n = 1 to 8, in order
  cost_usd: <number>|unknown
  duration_ms: <number>|unknown
  time limit: the session was stopped after <n> minutes     only when the limit stopped it
  result: passed | result: failed, <k> of 8 checks failed
  run: <absolute run folder>
  ```

- **The run folder:**

  ```text
  <run>/project/        the copy, under git; the session's working folder
  <run>/request.md      the request as sent
  <run>/run.txt         "key: value" lines; when a key repeats, the last value counts:
                        plugin_dir, limit_minutes, smoke_pid, allowed_tools, started,
                        ended, exit_code, time_limit_reached (yes|no),
                        interrupted (yes|no), cost_usd (<n>|unknown),
                        duration_ms (<n>|unknown)
  <run>/session.jsonl   the session's stream-json output
  <run>/session.err     the session's stderr
  <run>/timed-out       only when the watchdog stopped the session
  <run>/smoke.log       start only: the output of the background part
  <run>/checks.txt      the report
  <run>/ended           written last: 0 or 1
  ```

- **The headless command.** It runs in `<run>/project`, with stdin from `/dev/null`, after the variables in D7 are unset:

  ```text
  claude -p "/slice:new --config smoke.json <content of tests/sample/request.md>" \
    --output-format stream-json --verbose \
    --setting-sources project,local --strict-mcp-config \
    --plugin-dir <repo>/plugins/slice \
    --permission-mode acceptEdits --permission-prompts none \
    --no-session-persistence --allowedTools "<rules joined with commas>"
  ```

  There is no `--max-budget-usd`, because R5 sets no cost ceiling, and no `--model`.
- **The checks:**
  1. **`session`.** It reads `run.txt` and the last `result` event in `session.jsonl`, using `jq -n -R '[inputs | fromjson? | select(.type=="result")] | last'` so that a cut-off last line is skipped. It fails when:
     - there is no session output;
     - `time_limit_reached: yes`, with the detail `the time limit of <n> minutes stopped the session`;
     - `interrupted: yes`;
     - `exit_code` isn't 0;
     - there is no result event;
     - `is_error` is true, or `subtype` isn't `success`.
  2. **`isolation`.** In the first event with `type: system` and `subtype: init`, `[.plugins[] | select(.path != "builtin") | {name, path}]` must equal `[{"name": "slice", "path": <plugin_dir>}]`, and `.mcp_servers` must be empty. A failure lists what it found.
  3. **`status`.** In `project/slice/status.md`, the frontmatter must have `status: done` and an empty `next`. The rows of the `## Stages` table, without its header and its `|---` line, must have exactly the names from `jq -r '.pipeline[].name' project/.slicewright/smoke.json`, once each, each with the status `done`, and no other row, such as `review #2`. The first cell is the stage and the second is its status.
  4. **`records`.** Each file in `RECORDS` exists in `project/slice/` and isn't empty.
  5. **`tests`.** `sh test.sh` exits 0 in a scratch copy within `CHECK_SECONDS`. A failure shows its last 5 lines.
  6. **`acceptance`.** `sh <repo>/tests/sample/accept.sh <scratch copy>` exits 0 within `CHECK_SECONDS`. A failure shows its `not ok` lines.
  7. **`clean-tree`.** `git -C project status --porcelain --untracked-files=all` shows nothing outside `slice/`. A missing `.git` fails.
  8. **`index`.** `project/.slicewright/slices/index.md` has a line that starts with `## <first 10 characters of created in status.md> `.

### Test configuration

`tests/smoke/pipeline.json`:

```json
{
  "stages": ["intake", "clarify", "design", "plan", "implement", "review", "consolidate"],
  "overrides": {
    "intake": {
      "context": "The project's version control is git, with no remote, and its AGENTS.md names the tools to work with it. Ensure that the working tree is clean, with no uncommitted changes; otherwise fail the check. Don't fetch from a remote or compare with one."
    }
  }
}
```

`tests/smoke/config.jq`. A stage named in `overrides` that isn't in `stages`, or a stage that `defaults.json` doesn't have exactly once, is an error, and `prepare` then exits 2.

```jq
$smoke[0] as $s | .pipeline as $defaults
| ($s.overrides | keys - $s.stages) as $stray
| if ($stray | length) > 0 then error("overrides name stages outside the smoke pipeline: \($stray | join(", "))") else . end
| {pipeline: [range(0; $s.stages | length) as $i | $s.stages[$i] as $name
    | [$defaults[] | select(.name == $name)]
    | if length != 1 then error("defaults.json has \(length) stages named \($name)") else .[0] end
    | del(.next, .onError) | .params = ((.params // {}) * ($s.overrides[$name] // {}))
    | if $i + 1 < ($s.stages | length) then .next = $s.stages[$i + 1] else . end]}
```

`prepare <source> <run>` does these steps, in order:

1. `cp -R <source> <run>/project`
2. It writes `<run>/project/.slicewright/smoke.json` with the jq above.
3. It appends `/slice/` to `<run>/project/.gitignore`.
4. `git init -q`, with a local identity: `user.name "Slicewright smoke test"`, `user.email smoke-test@slicewright.invalid` and `commit.gpgsign false`.
5. `git add -A`, then `git commit -q -m "Sample project for a smoke run"`.

`tests/smoke/allowed-tools` has one rule per line. Blank lines and lines starting with `#` are skipped.

```text
Bash(date:*)
Bash(git --version:*)
Bash(git remote -v:*)
Bash(git branch --show-current:*)
Bash(git status:*)
Bash(git diff:*)
Bash(git log:*)
Bash(git show:*)
Bash(git rev-parse:*)
Bash(git ls-files:*)
Bash(git add:*)
Bash(git commit:*)
Bash(git rm:*)
Bash(git restore:*)
Bash(sh test.sh:*)
Bash(sh greet.sh:*)
```

### Sample: `tests/sample/`

- **`project/greet.sh`.** Usage: `sh greet.sh [name]`.
  - It prints `Hello, <name>!`, or `Hello, world!` with no name or an empty one, and exits 0.
  - A first argument that starts with `-` prints `greet: unknown option: <arg>` on stderr and exits 2.
  - More than one argument prints `greet: too many arguments` on stderr and exits 2.
- **`project/test.sh`.** Run as `sh test.sh`; it finds `greet.sh` next to itself. It prints `ok - <name>` or `not ok - <name>` for each test, then `<p> passed, <f> failed`. It exits 0 only when none failed. It covers the four behaviors above. Its unknown-option test uses `-x`, never `--shout`, so it still passes once the feature exists, as in the fixture.
- **`project/AGENTS.md`** says:
  - first, that this is the sample project of Slicewright's smoke test;
  - its layout;
  - the test command, `sh test.sh`, and how to run the program, `sh greet.sh <args>`;
  - that there is no build step, no package to install, and no linter, analyzer or formatter: don't look for any or run any. `sh test.sh` is the whole check, and it needs nothing deployed;
  - POSIX sh only, and errors as `greet: <message>` with status 2;
  - that in the pipeline's task types, `greet.sh` and `test.sh` are backend code: the program and the command-line interface it exposes;
  - that the documentation is the OKF bundle in `doc/`, starting at `doc/index.md`;
  - that the version control is git, with no remote.
- **`project/doc/`** is at the path the default `knowledge` names, with a `type` on each page:
  - `index.md`, with "How to read" and Contents
  - `overview/index.md`
  - `overview/product.md`
  - `product/index.md`
  - `product/spec/index.md`
  - `product/spec/greeting.md`: usage, the name and its default, errors, exit statuses and Limitations
- **`request.md`.** It asks to add a `--shout` option to `greet.sh` that prints the greeting in upper case. Every choice is stated:
  - `--shout Ada` prints `HELLO, ADA!` and exits 0.
  - `--shout` alone prints `HELLO, WORLD!` and exits 0.
  - The option counts only as the first argument, followed by at most one name. `--shout Ada Bob` and `Ada --shout` both print `greet: too many arguments` and exit 2.
  - Only the letters a to z become A to Z.
  - Without the option, nothing changes, and other arguments starting with `-` are still unknown options.
  - It asks for tests of each behavior in `test.sh`, and for the option in `doc/product/spec/greeting.md`.

  It ends: "Nothing else changes. There are no open questions: this request is complete, and each choice above is final."
- **`accept.sh <project folder>`.** It is never copied into a run. It prints `ok`/`not ok` lines and never writes to the folder. It exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing. Its cases:
  - `--shout Ada` → `HELLO, ADA!`, 0
  - `--shout` → `HELLO, WORLD!`, 0
  - `--shout Ada Bob` → the stderr line, empty stdout, 2
  - `Ada` → `Hello, Ada!`
  - `-x` → `greet: unknown option: -x`, 2
  - `--shout ada-lovelace_42` → `HELLO, ADA-LOVELACE_42!`
  - some `*.md` file under `doc/` mentions `--shout`, found with `find … -exec grep -l -e '--shout' {} +`

  On the unchanged sample, the `--shout` cases fail (AC4).

### Fixture: `tests/fixtures/finished-run/`, an overlay on `tests/sample/project/`

- `greet.sh` with the feature.
- `doc/product/spec/greeting.md`, which mentions `--shout`.
- `slice/status.md`. Its frontmatter has `title: Add a --shout option`, `stage: consolidate`, `status: done`, an empty `next:`, `config: smoke.json` and `created: 2026-01-01T10:00:00Z`. It has seven `done` rows, in pipeline order, and a Log.
- `slice/input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`, each with a heading and one line saying that it stands in for a run's record.
- `.slicewright/slices/index.md`: `# Slices`, then `## 2026-01-01 add-a-shout-option: Add a --shout option` and the entry's lines.
- No `.gitignore` and no `.slicewright/smoke.json`: `prepare` writes both.

### Self-test: `sh tests/selftest.sh`

It takes no arguments. It works in `mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX"`. When every case passes, it removes that folder, and only that one. Otherwise it keeps it and prints `kept: <folder>`. Each break is checked to have changed something; when it hasn't, the case is `MISSED`. Files are edited with jq or sed into a temporary file, then `mv`. Commits use `git -C`.

| Case | Break | Must show |
|---|---|---|
| `static/unbroken` | none | exit 0 |
| `static/next` | stage `implement`: `next` set to `no-such-stage` | exit ≠ 0, and a FAIL line with `stage implement` |
| `static/choice` | `design-review`: `choices.approve` set to `no-such-stage` | `stage design-review` |
| `static/duplicate` | stage `clarify` renamed to `intake` | `stage intake` |
| `static/skill` | `deploy`: `skill` set to `slice:no-such-skill` | `stage deploy` |
| `static/name` | `skills/plan/SKILL.md`: `name: planner` | `skills/plan/SKILL.md` |
| `static/user-invocable` | the `user-invocable: false` line removed from `skills/review/SKILL.md` | `skills/review/SKILL.md` |
| `static/json` | `.claude-plugin/plugin.json` made unparseable | `.claude-plugin/plugin.json` |
| `smoke/unbroken` | none | FAIL 1 and FAIL 2, PASS 3 to 8 |
| `smoke/stage-failed` | the `review` row's status set to `failed` | FAIL 3; checks 4 to 8 pass |
| `smoke/record-removed` | `slice/plan.md` deleted | FAIL 4; 3 and 5 to 8 pass |
| `smoke/acceptance` | the sample's `greet.sh` copied over the fixture's, then committed | FAIL 6; 3 to 5, 7 and 8 pass |
| `smoke/uncommitted` | an untracked `notes.txt` | FAIL 7; 3 to 6 and 8 pass |
| `smoke/index-entry` | `index.md` reduced to `# Slices`, then committed | FAIL 8; 3 to 7 pass |

- **Output:** one line per case: `ok <case>`, `caught <case>: <the matching line>`, or `MISSED <case>: <why>` followed by the case's output, indented. The last line is `selftest: passed, 14 cases` or `selftest: failed, <k> of 14 cases`.
- **Exit status:** 0, 1, or 2 when a tool is missing.

### The entry added to `testAgents` in `.slicewright/config.json`

```json
{
  "name": "smoke",
  "agent": "general-purpose",
  "executionMode": "fork",
  "context": "The smoke test of the plugin in plugins/slice, which the documentation's overview/testing.md describes. It runs the pipeline headless on a copy of a sample project and takes longer than one shell command may last, so run it in steps. 1. Run `sh tests/smoke.sh start`. It returns at once, and its last line, `run: <folder>`, names the run's folder. When it exits with status 2, the suite didn't start: report NOT_STARTED with its output. 2. Run `sh tests/smoke.sh wait <folder>` with the longest timeout your shell tool allows. It returns before one shell command's time runs out; if the shell tool stops it first, run the same command again. While it exits with status 3, the run is still going: run the same command again. Status 0 means every check passed, and 1 that a check failed. Status 2 means the folder isn't a run folder: report NOT_STARTED with its output. 3. Report each line of the final output that starts with PASS or FAIL as one test: its name is the check's name, the word after its number, such as `session`; its file is `tests/smoke.sh`; it passed or failed as the line says, and the text after the colon is its output. Give the folder from the last line as the artifacts. To run a failed check once more, run `sh tests/smoke.sh check <folder>`: it evaluates the checks again on the files the run left, without a new run."
}
```

### `AGENTS.md`: the new "Checking a change" section

```markdown
## Checking a change

- `sh tests/static.sh` checks the plugin without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, and each skill's frontmatter.
- `sh tests/selftest.sh` checks those checks, and the smoke checks, on broken copies.
- `sh tests/smoke.sh` runs the pipeline headless on a copy of the sample project and checks what the run leaves. It is too slow for a task or a quality gate: the test stage runs it, or you do, by hand.
- [doc/overview/testing.md](doc/overview/testing.md) says what each one checks, how to run it, and how to add a check.
- `/slice:configure` copies `defaults.json` into a project, so a change to the defaults doesn't reach a project that already has its own `.slicewright/config.json`.
```

### `slice/docs/overview/structure.md`: the current page, with one bullet added

```markdown
- `tests/`: the plugin's tests, outside the plugin folder because an installed plugin is a copy of its folder. `static.sh` and `selftest.sh` need no model. `smoke.sh` runs the pipeline headless on a copy of the sample project in `tests/sample/`. `tests/fixtures/` holds what a finished run leaves, for the self-test. [Testing](testing.md) describes them.
```

### `slice/docs/overview/testing.md` (`type: overview`): its sections

1. **Levels.** For the static level, the self-test and the smoke level: what each checks and why, its command and options, and its exit statuses and output.
2. **Where they run.** The project's tests that need no headless Claude run are exactly `sh tests/static.sh` and `sh tests/selftest.sh`. They run in the quality gates of implement, review-fix and bug-fix, and by hand. The smoke test, `sh tests/smoke.sh`, needs a headless Claude run. It runs in the test stage's `smoke` suite, with `start` and then `wait`, or by hand, and never in a task's Verify or a quality gate.
3. **Cost and time.** The static level and the self-test finish within 60 seconds. The smoke level has a 90-minute limit, set as `LIMIT_MINUTES` in `smoke.sh`, and `--minutes` overrides it for one run. There is no cost ceiling, and the cost is billed to the developer's Claude Code sign-in. Each run's `run.txt` and `checks.txt` keep its cost and duration. The measured duration and cost of the first passing run are left out, with no placeholder (D16).
4. **The sample.** Where the project, the request and the acceptance check are, and that the acceptance check is never copied.
5. **How a run copies the sample.** The `prepare` steps, the run folder outside the repo and how `TMPDIR` moves it, and the run folder's layout.
6. **The test configuration.** It is generated from `plugins/slice/defaults.json` at run time: seven stages, chained with `next`, with no `onError` and no gates. It has one override, intake's context, for the reason in D5. There is no `taskTypes` override, for the reason in D6.
7. **Isolation and permissions.**
   - The plugin loads only from `plugins/slice`, never from `.slicewright/stable/`.
   - The developer's user settings, plugins, skills, hooks and MCP servers are left out. The calling session's variables are unset.
   - The allow list is `tests/smoke/allowed-tools` plus the generated rules, and every prompt is denied.
   - The command refuses to start when `~/.slicewright/smoke.json` exists.
   - Tests change only copies, in new folders outside the repo.
8. **The eight smoke checks.** For each: its number, its name and what it reads, including that check 2 doesn't count Claude Code's built-in plugins (D9). How `check` evaluates a kept run again.
9. **Adding a static check.**
   - Add it to `static.sh`, `static/defaults.jq` or `static/skill.awk`, with a `FAIL` line that names its subject.
   - Add a case to `selftest.sh` that breaks that one thing in a copy and expects the subject.
   - Run `sh tests/selftest.sh`.

## Risks

- **Nondeterminism can fail a run with nothing broken.** A run can fail on the model's behavior alone: clarify asking a blocking question, plan returning `NO_TASK_TYPE`, or a gate reporting `ENVIRONMENT` after it looks for a linter. → The request states every choice. The sample's `AGENTS.md` maps its code to `backend` and says there is nothing to build or lint. Every run is kept, and `check` evaluates it again at no cost. The `cli` task type in D6 is the fallback for `NO_TASK_TYPE`.
- **A run takes longer than 90 minutes.** Consolidate alone runs eight agents, one after another. → The first passing run measures the time. The limit is one constant, and `--minutes` overrides it for one run.
- **A denied permission derails a stage.** → The allow list is explicit and recorded in `run.txt`. `permission_denials` in `session.jsonl` shows what is missing. A denial never hangs the run.
- **The detached run is killed with the shell call that started it.** → The probe showed that it survives. If it doesn't, `wait` finds `smoke_pid` gone, evaluates the checks, and exits 1 instead of waiting forever.
- **KILL leaves claude's child processes running.** → TERM goes first, with 30 seconds' grace. The sample's commands are short.
- **No cost ceiling.** → Only the time limit bounds a run. It runs only in the test stage or by hand, and each run records its cost.
- **Bash-only syntax slips into the scripts**, because `/bin/sh` is bash on macOS. → Each script's Verify runs `dash -n` on it and runs `dash tests/selftest.sh`.
- **The self-test and checks 5 and 6 delete files.** The self-test removes its temporary folder after a passing run, and checks 5 and 6 remove their scratch copies. → Each removes only a non-empty path that its own `mktemp -d` returned, outside any run folder. The self-test keeps its folder on any failure. Every other command writes only to new folders and never deletes a run folder.
- **The OS clears old files in `TMPDIR`.** → The last line names the folder. Setting `TMPDIR` for one command keeps runs elsewhere.
- **The fixture drifts from what tracking and consolidate really write.** → The self-test tests the checks, and the smoke run tests the real output. A format change shows up as a failing smoke check.
- **Agents working on this repo misread the sample's `AGENTS.md`, or think `tests/fixtures/finished-run/slice/` must not be committed.** → The sample's `AGENTS.md` says first what it is. The fixture task says that its files are committed.
- **The init event or the result event changes shape in a later Claude Code version.** → Checks 1 and 2 name the fields they read. A failure shows what they found.
- **Some acceptance criteria can't be proven by a task's Verify or a quality gate:** AC5, AC8, AC9, AC11 and AC15 need a real headless run. → They stay unproven in this slice (D16). The self-test proves the checks themselves on the fixture, and the Final check proves AC9 in part. The follow-up slice runs the smoke test, with `--minutes 1` for AC8, and its test stage runs the `smoke` suite for AC11.

## Assumptions

- **`claude plugin validate` starts no Claude session and makes no model call.** It is a local check: it was measured at about 0.5 seconds, and it ran with no sign-in prompt.
- **"A POSIX shell" includes the standard utilities** `awk`, `sed`, `grep`, `find`, `cp`, `mv` and `mkdir`. `mktemp` isn't in POSIX, but it is on macOS and every common Linux.
- **Built-in plugins aren't the developer's.** The plugins with `"path": "builtin"` come with Claude Code, appear in every session, and can't be turned off from the project. The person confirmed this (Q2, D9).
- **`acceptEdits` allows the common file commands, such as `cp`, inside the working folder.** The probe confirmed it for `touch` and `mkdir`. When `cp` is denied, consolidate's agent can copy the records with the Write tool instead.
- **`--setting-sources project,local` leaves out the developer's user-level skills.** The synced skills didn't load in the probe. This machine has no other user-level skills to test it with.
- **The event shapes hold as measured with Claude Code 2.1.310:** the `system`/`init` event's `plugins` and `mcp_servers`, and the `result` event's `is_error`, `subtype`, `total_cost_usd` and `duration_ms`.

## Requirements coverage

| Requirement | Covered by |
|---|---|
| R1 | Affected areas; D1; nothing under `plugins/slice/` or `.slicewright/stable/` changes |
| R2 | D1; Contracts: static level (checks 1 to 4, output, exit status) |
| R3 | Contracts: sample (program, `sh test.sh` named in its `AGENTS.md`, `doc/`, `request.md`, `accept.sh` outside `project/`); no install or network |
| R4 | D2, D4, D5, D6, D7, D8, D13, D15; Contracts: smoke level (`prepare`, the headless command), test configuration |
| R5 | D10; `LIMIT_MINUTES`, `--minutes`; check 1's detail and the `time limit:` line; no `--max-budget-usd` |
| R6 | D9, D11, D12; Contracts: the eight checks, the report, `check <folder>` |
| R7 | D13; Contracts: the run folder, `run.txt` with `unknown`, the last line `run: <folder>`; no command deletes a run folder |
| R8 | D3; Contracts: the `testAgents` entry; Affected areas (`test` task) |
| R9 | D16, D17; Contracts: `testing.md`, `structure.md`, `AGENTS.md` |
| R10 | D2, D14; Contracts: fixture, self-test |
| AC1 | Affected areas; R1 |
| AC2 | Contracts: static level; the validation is local (Assumptions) |
| AC3 | Contracts: the static problem lines; self-test cases `static/*` |
| AC4 | Contracts: sample (`test.sh` passes; `accept.sh` fails on the unchanged copy) |
| AC5 | D2 to D12; unproven in this slice, proven in the follow-up (D16) |
| AC6 | D4 (`config.jq` copies each default stage whole, with the override from `pipeline.json` only); the testing page lists the override; the smoke task's Verify compares them once |
| AC7 | Contracts: the eight checks; self-test cases `smoke/*` |
| AC8 | D10; `sh tests/smoke.sh --minutes 1` in the follow-up (D16) |
| AC9 | D13; Contracts: the run folder and the report's last line |
| AC10 | Contracts: the `testAgents` entry; nothing else in the file changes |
| AC11 | D3; the follow-up's test stage (D16) |
| AC12 | Contracts: `testing.md` sections 1 to 9, `structure.md`, `AGENTS.md`; the measured numbers deferred to the follow-up (D16) |
| AC13 | `testing.md` section 2 names exactly `sh tests/static.sh` and `sh tests/selftest.sh`; D17 keeps the gates from running them before they work |
| AC14 | Contracts: self-test (14 cases, `caught` lines, no Claude session) |
| AC15 | D7, D9; check 2; its real run in the follow-up (D16) |
