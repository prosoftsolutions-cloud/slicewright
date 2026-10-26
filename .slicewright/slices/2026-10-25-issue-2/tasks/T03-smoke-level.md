---
id: T03
title: Smoke level and its test-stage entry
type: test
depends: []
covers: [R1, R4, R5, R6, R7, R8, AC6, AC10]
questions: [Q2]
---

# T03 Smoke level and its test-stage entry

## Goal

Add `sh tests/smoke.sh` and its subcommands, with three data files.

- It runs the pipeline headless on a copy of the sample, within a time limit.
- It evaluates eight named checks on what the run leaves.
- It keeps everything in one run folder.

Then add the one `smoke` entry in the `test` stage's `testAgents` that runs it.

## Context

From spec.md:

- **R1** Every test lives under `tests/`. No file under `plugins/slice/` or `.slicewright/stable/` changes.
- **R4** The smoke level is one command, run from the repo root. It:
  1. copies the sample into a new folder outside the repo;
  2. writes a test configuration into the copy:
     - Its pipeline is `intake`, `clarify`, `design`, `plan`, `implement`, `review` and `consolidate`, in that order. Each stage has `next` set to the one after it, and none has an `onError`, so any error ends the run.
     - Each stage's `skill`, `executionMode` and `params` come from the stage of the same name in the working copy's `plugins/slice/defaults.json`, read when the command runs.
     - The only overrides are those the sample needs, such as a stage's context that would otherwise wait for a person or need a remote, like intake's check for the latest sources. The testing page lists each override with its reason.
  3. puts the copy under version control with one commit that holds all of it, the test configuration included, with the `slice/` folder ignored, so the run starts from a clean tree;
  4. runs `/slice:new` with the sample's request in the copy:
     - headless, with `claude -p`;
     - loading the plugin only from the working copy's `plugins/slice`, with `--plugin-dir`, and the test configuration with `--config`;
     - with the developer's own sign-in, and none of the developer's user-level plugins, skills, hooks or MCP servers.
- **R5** The smoke run stops when it reaches a time limit of 90 minutes.
  - Reaching it fails the run, and the command says that the time limit stopped it.
  - The limit is set in one place under `tests/`, and can be overridden for a single run.
  - The run has no cost ceiling.
- **R6** After the headless run ends, the smoke command evaluates these checks. Each has its own name, and each is printed as passed or failed. The command exits zero only when all of them pass. The checks can be evaluated again on a kept copy without a new headless run.
  1. The headless session ended without an error, within the time limit.
  2. The session's own report of what it loaded, in its kept output, shows the `slice` plugin from the working copy's `plugins/slice`, and no other plugin and no MCP server.
  3. The copy's `slice/status.md` has `status: done` and an empty `next`. Its Stages table has exactly one row for each of the seven stages, each `done`.
  4. The copy's `slice/` folder holds `input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`.
  5. The sample's own test command passes in the copy.
  6. The acceptance check passes against the copy.
  7. The copy's version control shows no uncommitted change outside the `slice/` folder.
  8. The copy's `.slicewright/slices/index.md` has an entry for the slice.
- **R7** Each smoke run, finished or stopped, keeps four things in one folder: its copy, the headless session's output, its cost and duration, and the check results. When the session was stopped before it reported its cost or duration, the record says that each one is unknown. The command never deletes that folder, and its last line of output names it.
- **R8** The `test` stage in the repo's `.slicewright/config.json` gets one `testAgents` entry that runs the smoke command.
  - Its context says to report each smoke check as one test, by its name, and the folder from the command's last line as the artifacts.
  - The suite waits for the run to end, and reports it even when the run takes longer than one shell command of the suite's agent may last.
  - Nothing else in the file changes.
- **AC6** Given a finished run's kept copy, when its test configuration is compared with the working copy's `plugins/slice/defaults.json`, then each of the seven stages has the same `skill`, `executionMode` and `params` as the stage of the same name there, except for the overrides the testing page lists. And nothing under `tests/` holds a copy of those params.
- **AC10** Given the repo's `.slicewright/config.json` at the end of this slice, when it is compared with the version before the slice, then the only change is one entry in the `test` stage's `testAgents`. Its context runs the smoke command, reports each check as one test by its name, reports the folder from the last line as the artifacts, and waits for a run longer than one shell command may last.
- **Criteria a real run proves.** These need a real headless run. A person runs them by hand, as the plan's Q1 describes, and the test stage's `smoke` suite runs them, as the plan's Deployed checks say. This task's Verify proves what it can of them without a session.
  - **AC5:** the smoke command runs the seven stages, and every check passes within 90 minutes.
  - **AC8:** with the limit overridden to one minute, the run stops, and the command exits non-zero and says that the time limit stopped it.
  - **AC9:** the last line names a folder that still exists and holds the copy, the session output, the cost and duration or "unknown", and the check results.
  - **AC11:** the test stage's suite reports `RAN` for a run longer than 10 minutes, with one test per check and the folder as its artifacts.
  - **AC15:** with the developer's other plugins, hooks and MCP servers enabled, the kept output shows only `slice`, loaded from `plugins/slice`, and no MCP server, and check 2 passes.
- **Constraints:**
  - A headless run can't answer permission prompts, and in a new, untrusted folder it ignores that folder's `.claude/settings.json` allow rules. So the command grants up front exactly what the stages need, and never bypasses permission checks.
  - A shell command run by a stage's agent times out after at most 10 minutes.
  - The smoke run needs no person, no deployment, no GitHub and no network beyond the model API.

From design.md:

- **Facts measured with Claude Code 2.1.310:**
  - There is no `timeout` command on macOS, and `/bin/sh` is bash in POSIX mode. `/bin/dash` exists.
  - With `--setting-sources project,local --strict-mcp-config --plugin-dir <repo>/plugins/slice` and the OAuth sign-in:
    - The `system`/`init` event in the stream-json listed `slice` at the given path, plus three built-in plugins with `"path": "builtin"`. It listed no MCP server.
    - The last event, `type: result`, carried `is_error`, `subtype`, `total_cost_usd` and `duration_ms`.
  - `Bash(sh test.sh:*)` matched `sh test.sh`. Under `acceptEdits`, `touch` and `mkdir` inside the working folder were allowed. A command with no rule was denied at once and recorded in `permission_denials`. It didn't hang.
  - A process started with `nohup … &` from a script outlived the shell call that started it, and that call returned at once.
  - A multi-line request with backticks, quotes and `$` reached `$ARGUMENTS` intact.
  - The runner takes `/slice:new --config <name> <request>`, where `<name>` is a plain file name. It merges `defaults.json`, then `~/.slicewright/<name>`, then `.slicewright/<name>`, then `.slicewright/<name>.local.json`. A later `pipeline` replaces the earlier one whole. `sharedParams` merge key by key.
- **D1** POSIX sh only: no `local`, arrays, `[[ ]]`, `sed -i` or `grep -r`. Run as `sh tests/smoke.sh`, with no executable bit. The tools are `claude`, `jq`, `git` and the POSIX utilities.
- **D2** One smoke script with subcommands: `start`, `wait`, `check` and `prepare`, plus the internal `_finish`. The self-test (T04) builds its fixture with `prepare` and evaluates it with `check`.
- **D3** `start` prepares the copy, starts the session part with `nohup`, and returns at once. `wait <folder>` blocks inside the script for at most 540 seconds. It exits 3 while the run is going, and prints the recorded report once the run has ended.
- **D4** The configuration is generated at run time: `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq <repo>/plugins/slice/defaults.json`, written to `<copy>/.slicewright/smoke.json`. The session starts with `/slice:new --config smoke.json`.
  - Each stage is the whole default stage of that name, without `next` and `onError`.
  - Its `params` are deep-merged with the override.
  - `next` is set to the following stage, and consolidate has none.
  - The file holds only `pipeline`.
- **D5** There is exactly one override, intake's `context`. It keeps the clean-tree check and drops the check against a remote and the "ask user" step.
- **D7** Isolation:
  - The flags are `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence`, with `--plugin-dir <repo>/plugins/slice` as the only plugin source.
  - Before `exec claude`, unset `CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SESSION_ATTENDED`, `CLAUDE_CODE_MESSAGING_SOCKET`, `CLAUDE_CODE_MESSAGING_TOKEN`, `CLAUDE_PID`, `CLAUDE_EFFORT` and `AI_AGENT`.
  - Keep `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`.
  - Refuse with exit 2 when `~/.slicewright/smoke.json` exists, because the runner would merge it in.
  - Never `--bare` or `--safe-mode`.
- **D8** Permissions are `--permission-mode acceptEdits --permission-prompts none --allowedTools "<rules joined with commas>"`. The rules are:
  - the Bash rules in `tests/smoke/allowed-tools`;
  - `Skill(slice:run)`, `Skill(slice:tracking)`, and `Skill(<skill>)` for every `skill` in the generated configuration;
  - `Read(/<absolute plugin folder>/**)`, which reads `Read(//Users/…)`, and `Read(~/.slicewright/**)`.

  Never use `bypassPermissions` or `--dangerously-skip-permissions`.
- **D9 (Q2)** Check 2 leaves out the plugins with `"path": "builtin"`. What remains must be exactly the `slice` plugin at the absolute `plugins/slice` path, and `mcp_servers` must be empty. The design applies the recommended answer to Q2, so build it this way.
- **D10** The time limit is a watchdog inside `smoke.sh`.
  - `LIMIT_MINUTES=90` at the top is the one place it is set. `--minutes <n>` sets a positive whole number for one run.
  - A watchdog subshell checks the session's process every 5 seconds. At the limit it writes `<run>/timed-out`, sends TERM, and sends KILL after 30 seconds.
  - A foreground run traps INT and TERM: it stops the session, records `interrupted: yes`, still evaluates the checks, and prints the report.
- **D11** Checks 5 and 6 run in a `mktemp -d` copy of the project.
  - Each is limited to 120 seconds by the same watchdog, with stdin from `/dev/null`.
  - The scratch copy is removed afterwards, but only when it is the non-empty path `mktemp -d` returned, outside the run folder.
- **D12** Check 3 takes the expected stage names from the copy's own `.slicewright/smoke.json`. Check 8 looks for a line starting with `## <first ten characters of created in status.md> `.
- **D13** The run folder is `${TMPDIR:-/tmp}/slicewright-smoke/<UTC time as YYYYMMDDTHHMMSSZ>-<pid>`. A folder inside the repo is refused with exit 2.
- **D15** `prepare` appends `/slice/` to `<copy>/.gitignore` before the one commit.
- **Contract: the commands**

  | Command | What it does | Exit status |
  |---|---|---|
  | `sh tests/smoke.sh [--minutes <n>]` | in the foreground: prepare, session, checks, report | 0 all checks pass · 1 a check failed · 2 couldn't run |
  | `sh tests/smoke.sh start [--minutes <n>]` | prepares, starts the session part in the background, and returns | 0 started · 2 couldn't run |
  | `sh tests/smoke.sh wait <run folder>` | waits at most `WAIT_SECONDS` for `<run>/ended` | 0 or 1 once ended, from the recorded result · 3 still running · 2 not a run folder |
  | `sh tests/smoke.sh check <run folder>` | evaluates the eight checks again and prints the report; writes nothing in the run folder | 0 · 1 · 2 not a run folder |
  | `sh tests/smoke.sh prepare <source folder> <run folder>` | the copy, the configuration and the commit. The run folder must not exist, its parent must exist, and it must be outside the repo. | 0 · 2 |
  | `sh tests/smoke.sh _finish <run folder>` | internal: the session part, which `start` starts with `nohup` | — |

  - **Status 2** means the command couldn't run. That covers wrong usage, a missing tool, an existing `~/.slicewright/smoke.json`, a run folder inside the repo, a failed `prepare`, or a folder that isn't a run folder because it has no `project/`.
  - **Constants** at the top of `smoke.sh`: `LIMIT_MINUTES=90`, `WAIT_SECONDS=540`, `CHECK_SECONDS=120`, `CONFIG_NAME=smoke.json`, `SLICE_DIR=slice`, `RECORDS="input.md spec.md design.md plan.md implement.md code-reviews.md"`, `TEST_COMMAND="sh test.sh"`, `RECORDS_INDEX=.slicewright/slices/index.md`.
- **Contract: the output lines**
  - The foreground run prints `run: <folder>`, `prepared: <folder>/project` and `session: started, time limit <n> minutes`, then the report.
  - `start` prints `prepared: <folder>/project`, `session: started in the background, time limit <n> minutes`, `next: sh tests/smoke.sh wait <folder>` and `run: <folder>`.
  - `wait`, while the run is going, prints `running: the session has not ended yet`, then `run: <folder>`.
  - If `ended` is missing and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report, and exits 1.
  - Whatever its exit status, every command whose run folder exists ends with `run: <folder>`. That includes exit 2 after `prepare` fails. An error message comes before that line.
- **Contract: the report**, which the foreground run, `wait` and `check` print, and which a run saves as `checks.txt`:

  ```text
  PASS|FAIL <n> <name>: <detail>        one line for each check, n = 1 to 8, in order
  cost_usd: <number>|unknown
  duration_ms: <number>|unknown
  time limit: the session was stopped after <n> minutes     only when the limit stopped it
  result: passed | result: failed, <k> of 8 checks failed
  run: <absolute run folder>
  ```

- **Contract: the run folder**

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

- **Contract: the headless command.** It runs in `<run>/project`, with stdin from `/dev/null`, after the variables in D7 are unset. There is no `--max-budget-usd`, because R5 sets no cost ceiling, and no `--model`.

  ```text
  claude -p "/slice:new --config smoke.json <content of tests/sample/request.md>" \
    --output-format stream-json --verbose \
    --setting-sources project,local --strict-mcp-config \
    --plugin-dir <repo>/plugins/slice \
    --permission-mode acceptEdits --permission-prompts none \
    --no-session-persistence --allowedTools "<rules joined with commas>"
  ```

- **Contract: the eight checks**
  1. **`session`.** It reads `run.txt` and the last `result` event in `session.jsonl`, using `jq -n -R '[inputs | fromjson? | select(.type=="result")] | last'`, so that a cut-off last line is skipped. It fails when:
     - there is no session output;
     - `time_limit_reached: yes`, with the detail `the time limit of <n> minutes stopped the session`;
     - `interrupted: yes`;
     - `exit_code` isn't 0;
     - there is no result event;
     - `is_error` is true, or `subtype` isn't `success`.
  2. **`isolation`.** It reads the first event with `type: system` and `subtype: init`.
     - `[.plugins[] | select(.path != "builtin") | {name, path}]` must equal `[{"name": "slice", "path": <plugin_dir>}]`.
     - `.mcp_servers` must be empty.
     - A failure lists what it found.
  3. **`status`.** In `project/slice/status.md`:
     - The frontmatter must have `status: done` and an empty `next`.
     - Take the rows of the `## Stages` table, without its header and its `|---` line. The first cell is the stage and the second is its status.
     - The rows must have exactly the names from `jq -r '.pipeline[].name' project/.slicewright/smoke.json`, once each, each with the status `done`, and no other row, such as `review #2`.
  4. **`records`.** Each file in `RECORDS` exists in `project/slice/` and isn't empty.
  5. **`tests`.** `sh test.sh` exits 0 in a scratch copy within `CHECK_SECONDS`. A failure shows its last 5 lines.
  6. **`acceptance`.** `sh <repo>/tests/sample/accept.sh <scratch copy>` exits 0 within `CHECK_SECONDS`. A failure shows its `not ok` lines.
  7. **`clean-tree`.** `git -C project status --porcelain --untracked-files=all` shows nothing outside `slice/`. A missing `.git` fails.
  8. **`index`.** `project/.slicewright/slices/index.md` has a line that starts with `## <first 10 characters of created in status.md> `.
- **Contract: `prepare <source> <run>`**, in order:
  1. `cp -R <source> <run>/project`
  2. Write `<run>/project/.slicewright/smoke.json` with the jq above.
  3. Append `/slice/` to `<run>/project/.gitignore`.
  4. `git init -q`, with a local identity: `user.name "Slicewright smoke test"`, `user.email smoke-test@slicewright.invalid` and `commit.gpgsign false`.
  5. `git add -A`, then `git commit -q -m "Sample project for a smoke run"`.

  A stage named in `overrides` that isn't in `stages`, or a stage that `defaults.json` doesn't have exactly once, is an error, and `prepare` then exits 2.
- **Time budget for `check`.** T04's self-test runs `check` six times and `prepare` six times, and must finish within 60 seconds with its static cases. So checks 5 and 6 return as soon as their command ends. They never wait out the watchdog's poll interval or its `sleep` after the command has ended. `check` on a prepared folder takes a few seconds, not a multiple of 5.

## Interfaces

**Provides:**

- `sh tests/smoke.sh [--minutes <n>]`: as in the commands table → used by T05, T06
- `sh tests/smoke.sh start [--minutes <n>]`: as in the commands table → used by the `smoke` entry below, T05
- `sh tests/smoke.sh wait <run folder>`: as in the commands table → used by the `smoke` entry below, T05
- `sh tests/smoke.sh check <run folder>`: as in the commands table. It writes nothing in the run folder → used by T04, T05
- `sh tests/smoke.sh prepare <source folder> <run folder>`: the steps above. It prints `prepared: <run>/project`, then `run: <run>`, and exits 0 or 2 → used by T04
- **The report**, as in the contract. Its check names are 1 `session`, 2 `isolation`, 3 `status`, 4 `records`, 5 `tests`, 6 `acceptance`, 7 `clean-tree` and 8 `index`, and its last line is `run: <folder>` → used by T04, T05
- **A run folder** is a folder with a `project/` subfolder. Its layout is as in the contract → used by T04, T05
- **The constants** at the top of `tests/smoke.sh` → used by T05
- `tests/smoke/pipeline.json`, `tests/smoke/config.jq` and `tests/smoke/allowed-tools` → used by T05
- **The `smoke` entry** in the `test` stage's `testAgents` of `.slicewright/config.json` → used by T05

**Uses:**

- `tests/sample/project/`: the sample folder. The foreground run and `start` pass it to `prepare` as the source. It has no `.gitignore` and no `.slicewright/` → from T02
- `tests/sample/request.md`: the request text, with no frontmatter, sent as is → from T02
- `sh <repo>/tests/sample/accept.sh <folder>`: prints `ok - <case>` and `not ok - <case>: …` lines, then `<p> passed, <f> failed`. It exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing → from T02
- `sh test.sh`, run in the project folder: exits 0 only when all its tests pass → from T02
- `plugins/slice/defaults.json`: its `pipeline` has one stage each named intake, clarify, design, plan, implement, review and consolidate → from the existing code
- `.slicewright/config.json`: the `test` stage has `"testAgents": []` → from the existing code
- The status.md format and the records index entry `## {date} {name}: {title}` → from the existing `plugins/slice/skills/tracking/SKILL.md` and `plugins/slice/skills/consolidate/SKILL.md`

T02 writes the sample at the same time as this task, so this task's Verify doesn't rely on the sample's files. It uses `tests/smoke` as a stand-in source folder.

## Changes

- `tests/smoke/pipeline.json` (new): exactly this.

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

- `tests/smoke/config.jq` (new): exactly this. It runs as `jq --slurpfile smoke <repo>/tests/smoke/pipeline.json -f <repo>/tests/smoke/config.jq <repo>/plugins/slice/defaults.json`. Both error branches make jq exit non-zero, and then `prepare` exits 2.

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

- `tests/smoke/allowed-tools` (new): one rule per line, exactly this. The script skips blank lines and lines starting with `#`.

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

- `tests/smoke.sh` (new): POSIX sh.
  - **Syntax:** it must pass `dash -n` and run correctly under `dash`. No `local`, arrays, `[[ ]]`, `sed -i`, `grep -r`, `echo -e` or `$RANDOM`.
  - **Tools:** only `claude`, `jq`, `git` and the standard utilities: `awk`, `sed`, `grep`, `find`, `cp`, `mv`, `mkdir`, `mktemp`, `date`, `sleep`, `kill`, `nohup`, `tail` and `cat`.
  - **Constants:** exactly the eight in Context, at the top. No other line holds the number 90.
  - **Paths:**
    - `REPO` is the physical parent of the script's own folder, found with `cd -P` and `pwd -P` in a command substitution.
    - `PLUGIN_DIR="$REPO/plugins/slice"`. That exact string goes to `--plugin-dir`, is recorded as `plugin_dir`, and is compared by check 2.
    - The sample is `$REPO/tests/sample/project`, the request is `$REPO/tests/sample/request.md`, and the acceptance check is `$REPO/tests/sample/accept.sh`.
    - A folder argument resolves against the current folder.
    - A printed run folder is absolute and doesn't resolve symbolic links: a relative path is joined to `$PWD`, and an absolute path is kept as given. So `run: <tmp>/run` prints exactly the `<tmp>` that `mktemp -d` returned.
    - The "inside the repo" refusal compares physical paths: the run folder's parent made physical, plus its last name. It refuses when that equals `$REPO` or starts with `$REPO/`.
    - `${TMPDIR:-/tmp}` loses any trailing `/` before use.
  - **Usage:** any other first word, or a missing or extra argument, prints a usage text and exits 2.
  - **The last line.** It is `run: <folder>` whenever the command's run folder exists. That holds for `prepare`, `start` and the foreground run, including after `prepare` fails. It holds for `wait` and `check` whenever the folder they were given is a run folder. An error message comes first.
  - **Refusals for the foreground run and `start`.** Check these in this order, and create nothing until all pass:
    1. The arguments and `--minutes`. The error names `--minutes`.
    2. `$HOME/.slicewright/$CONFIG_NAME` exists. The error names that path.
    3. `command -v` for `claude`, `jq` and `git`. The error names each missing tool.
    4. `tests/sample/project/` and `tests/sample/request.md` exist.
    5. `${TMPDIR:-/tmp}/slicewright-smoke` is outside the repo.

    Only then run `mkdir -p` on that folder and pick the run folder `${TMPDIR:-/tmp}/slicewright-smoke/<date -u +%Y%m%dT%H%M%SZ>-<$$>`. `prepare`, `check` and `wait` need only `jq` and `git`.
  - **`prepare <source> <run>`:**
    - It refuses with exit 2 when the source isn't an existing folder (checked first, before anything is created), when the run folder exists, when its parent doesn't exist, or when it is inside the repo.
    - Then, in order:
      1. `mkdir <run>`, then `cp -R <source> <run>/project`.
      2. `mkdir -p <run>/project/.slicewright`, then write `.slicewright/smoke.json` from the jq command. When jq fails, print its message and exit 2.
      3. Append `/slice/` as its own line to `<run>/project/.gitignore`. When an existing `.gitignore` doesn't end in a newline, add one first.
      4. `git -C <run>/project init -q`, then set the local `user.name`, `user.email` and `commit.gpgsign` as in the contract.
      5. `git -C <run>/project add -A`, then `git -C <run>/project commit -q -m "Sample project for a smoke run"`.
    - It prints `prepared: <run>/project`, then `run: <run>`. When `start` or the foreground run calls it, they print their own lines instead.
  - **The foreground run:**
    1. Run the refusals, then print `run: <folder>`.
    2. Run `prepare <repo>/tests/sample/project <folder>`, and print `prepared: <folder>/project`.
    3. Copy `tests/sample/request.md` to `<folder>/request.md`.
    4. Write the first `run.txt` keys, with `smoke_pid` set to its own `$$`.
    5. Print `session: started, time limit <n> minutes`.
    6. Run the session part in the foreground.
    7. Print the report, and exit 0 or 1 as the report says.
  - **`start`:**
    - It does the same steps up to `run.txt`.
    - Then it launches `nohup sh "$REPO/tests/smoke.sh" _finish "<folder>" </dev/null >"<folder>/smoke.log" 2>&1 &`. All three streams are redirected, so the caller's shell call returns at once and no `nohup.out` appears.
    - It appends `smoke_pid: $!` to `run.txt`.
    - It prints its four lines, and exits 0.
  - **`_finish <run>`:** the same session part as the foreground run. It reads its values from `run.txt`, and refuses a folder that isn't a run folder with exit 2.
  - **The session part:**
    - **Allow list.** Build it after `prepare`, from the copy's `smoke.json`. Join the rules with commas into one argument, and record it as `allowed_tools`. The rules are:
      - every rule in `tests/smoke/allowed-tools`;
      - `Skill(slice:run)` and `Skill(slice:tracking)`;
      - `Skill(<value>)` for every distinct `skill` value at any depth in the generated `smoke.json`, skipping `TBD`, such as `[.. | objects | .skill? // empty | strings] | unique`;
      - `Read(/$PLUGIN_DIR/**)` and `Read(~/.slicewright/**)`.
    - **Environment.** In the subshell that runs `claude`, unset the ten variables in D7. Keep `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`.
    - **The headless command.** It runs in a background subshell whose folder is `<run>/project`, as `exec claude …` so that `$!` is claude's PID.
      - stdin comes from `/dev/null`, stdout goes to `<run>/session.jsonl`, and stderr to `<run>/session.err`.
      - Keep the argument order of the contract. `--allowedTools` takes a variable number of values, so it stays last, and the prompt comes right after `-p`.
      - No `--max-budget-usd` and no `--model`.
    - **The watchdog.** One helper serves the session and checks 5 and 6. It takes a PID, a limit in seconds and an optional marker file.
      - A subshell, with its output sent to `/dev/null`, checks the PID every 5 seconds. At the limit it writes the marker, if one was given, and sends TERM, then KILL 30 seconds later if the process is still alive.
      - The caller kills the watchdog as soon as the command ends, and never waits for it or for its `sleep`. A command that ends quickly returns at once.
      - For the session, the limit is `limit_minutes * 60` and the marker is `<run>/timed-out`.
    - **The trap.** INT and TERM are trapped.
      - The handler records `interrupted: yes` and sends TERM to the session, keeping the 30-second KILL fallback.
      - Then the part waits for the session again to get its real status, and still records, evaluates and writes the report.
      - A background job ignores SIGINT in a non-interactive shell, which is why the handler sends TERM.
    - **The record.** Append to `run.txt`:
      - `ended: <date -u +%Y-%m-%dT%H:%M:%SZ>`
      - `exit_code: <status>`
      - `time_limit_reached: yes|no`, which is `yes` when `<run>/timed-out` exists
      - `interrupted: yes|no`
      - `cost_usd` and `duration_ms`, from `.total_cost_usd` and `.duration_ms` of the last result event, or `unknown`

      Then write the report to `<run>/checks.txt`, and last write `<run>/ended` with `0` or `1`.
  - **`run.txt`:** `key: value` lines, where the last value of a repeated key counts. Read a value as the whole rest of the line after `key: `, because `allowed_tools` holds colons and commas. The keys:
    - written after `prepare`: `plugin_dir`, `limit_minutes`, `allowed_tools` and `started`;
    - then `smoke_pid`;
    - written after the session: `ended`, `exit_code`, `time_limit_reached`, `interrupted`, `cost_usd` and `duration_ms`.
  - **`wait <run>`:**
    - A folder that isn't a run folder exits 2 with an error message.
    - Otherwise it loops for at most `WAIT_SECONDS`, polling every few seconds:
      - When `<run>/ended` exists, it prints `<run>/checks.txt` and exits with the value in `ended`. Anything but `0` counts as 1. When `checks.txt` is missing, it evaluates now.
      - Otherwise, when `smoke_pid` is missing from `run.txt` or `kill -0` fails for it, it looks for `ended` once more, to cover a race. Then it prints `ended: the background run stopped without finishing; checks evaluated now`, then the report evaluated now, and exits 1. On this path it writes nothing in the run folder, so a prepared folder whose run never started returns at once with exit 1.
    - When time runs out, it prints `running: the session has not ended yet` and `run: <run>`, and exits 3.
  - **`check <run>`:** it evaluates and prints the report, and exits 0, 1, or 2 for a folder that isn't a run folder. It writes nothing in the run folder.
  - **The report:** as in the contract.
    - `cost_usd` and `duration_ms` come from the last result event in `session.jsonl`, or `unknown` when there is none.
    - A detail is one short line of what the check found.
    - The exit status is 0 only when all eight pass, and 1 otherwise.
  - **The eight checks.** Paths are relative to `<run>`.
    1. `session`: as in the contract, failing on the first of its cases that applies. A missing or empty `session.jsonl` is "no session output", and a missing `exit_code` fails.
    2. `isolation`: as in the contract. It fails when there is no init event or no `plugin_dir`. A failure lists the plugins that aren't built in and the MCP servers it found.
    3. `status`:
       - The frontmatter is the lines between the first `---` line and the next `---`. It must have `status: done`, and `next:` with nothing after it once trimmed.
       - The table rows are the `|` lines after `## Stages`, leaving out the header row (the first one) and the `|---` line. The first and second cells are trimmed.
       - A failure lists what is wrong. A missing `status.md` fails.
    4. `records`: a failure lists the missing or empty records.
    5. `tests`:
       - `cp -R project/. <scratch>` into a fresh `mktemp -d`.
       - Run `$TEST_COMMAND` with that folder as its working folder, stdin from `/dev/null`, under the watchdog for `CHECK_SECONDS`, with no marker in the run folder.
       - A failure shows the last 5 lines of its output.
       - Then `rm -rf` the scratch folder, but only when it is the non-empty path `mktemp -d` returned, is an existing folder, and is outside the run folder.
    6. `acceptance`: the same, in another scratch copy, with `sh "$REPO/tests/sample/accept.sh" <scratch>`.
       - A failure shows its `not ok` lines, or, when there are none, its exit status and last lines.
       - A missing `accept.sh` is a FAIL, not status 2.
    7. `clean-tree`:
       - A missing `project/.git` fails. Test that folder directly, so that a parent repository never counts.
       - Otherwise, `git -C project status --porcelain --untracked-files=all` must list no path outside `$SLICE_DIR/`. A failure lists the paths it found.
    8. `index`: as in the contract. It fails when `status.md`, or a `created` in `YYYY-MM-DD…` form, is missing.
  - **Deleting:** the script never deletes a run folder. The only removals are the guarded scratch folders of checks 5 and 6.
- `.slicewright/config.json` (changed): in the `test` stage, replace `"testAgents": []`, and nothing else, with a list holding this one entry. Use the Edit tool and the file's two-space indentation, nested like the `qualityGateAgents` lists in the same file. The entry:

  ```json
  {
    "name": "smoke",
    "agent": "general-purpose",
    "executionMode": "fork",
    "context": "The smoke test of the plugin in plugins/slice, which the documentation's overview/testing.md describes. It runs the pipeline headless on a copy of a sample project and takes longer than one shell command may last, so run it in steps. 1. Run `sh tests/smoke.sh start`. It returns at once, and its last line, `run: <folder>`, names the run's folder. When it exits with status 2, the suite didn't start: report NOT_STARTED with its output. 2. Run `sh tests/smoke.sh wait <folder>` with the longest timeout your shell tool allows. It returns before one shell command's time runs out; if the shell tool stops it first, run the same command again. While it exits with status 3, the run is still going: run the same command again. Status 0 means every check passed, and 1 that a check failed. Status 2 means the folder isn't a run folder: report NOT_STARTED with its output. 3. Report each line of the final output that starts with PASS or FAIL as one test: its name is the check's name, the word after its number, such as `session`; its file is `tests/smoke.sh`; it passed or failed as the line says, and the text after the colon is its output. Give the folder from the last line as the artifacts. To run a failed check once more, run `sh tests/smoke.sh check <folder>`: it evaluates the checks again on the files the run left, without a new run."
  }
  ```

## Verify

Run every command from the repo root. Each step below is one command.

- Never run `sh tests/smoke.sh` with no subcommand, `start` or `_finish`, except where a step says so. Those steps are refused before a session can start.
- Never run `claude -p`.
- `<tmp>` is the folder that `mktemp -d` prints. Use a new one each time you run these steps.

1. `dash -n tests/smoke.sh`: no output, exit 0.
2. `sh -n tests/smoke.sh`: no output, exit 0.
3. `jq -e . tests/smoke/pipeline.json`: exit 0, and the JSON above.
4. `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq plugins/slice/defaults.json`: exit 0, and `{"pipeline": [...]}` with the stages intake to consolidate.
5. `jq --argjson smoke '[{"stages":["intake"],"overrides":{"design":{}}}]' -f tests/smoke/config.jq plugins/slice/defaults.json`: exit 5, and `overrides name stages outside the smoke pipeline: design`.
6. `jq --argjson smoke '[{"stages":["no-such-stage"],"overrides":{}}]' -f tests/smoke/config.jq plugins/slice/defaults.json`: exit 5, and `defaults.json has 0 stages named no-such-stage`.
7. `mktemp -d`: prints `<tmp>`.
8. `sh tests/smoke.sh prepare tests/smoke <tmp>/run`: exit 0, `prepared: <tmp>/run/project`, and last `run: <tmp>/run`.
9. **AC6, R4.2.** This prints `true` and exits 0:

   ```text
   jq -n -e --slurpfile gen <tmp>/run/project/.slicewright/smoke.json --slurpfile def plugins/slice/defaults.json --slurpfile smoke tests/smoke/pipeline.json '$smoke[0] as $s | $gen[0] as $g | $def[0].pipeline as $d | (($s.overrides | keys) == ["intake"]) and (($s.overrides.intake | keys) == ["context"]) and (($g | keys) == ["pipeline"]) and ([$g.pipeline[].name] == ["intake","clarify","design","plan","implement","review","consolidate"]) and ([$g.pipeline[].name] == $s.stages) and ([$g.pipeline[] | has("onError")] | any | not) and ([$g.pipeline[].next] == ($s.stages[1:] + [null])) and all($g.pipeline[]; . as $st | ($s.overrides[$st.name] // {}) as $o | [$d[] | select(.name == $st.name)] as $m | ($m | length) == 1 and ($st | del(.params, .next)) == ($m[0] | del(.params, .next, .onError)) and ($st.params | del(.[$o | keys[]])) == ($m[0].params | del(.[$o | keys[]])) and all($o | to_entries[]; . as $e | $st.params[$e.key] == $e.value))'
   ```

10. **AC6, no copied params.** `grep -rlF -e reviewAgents -e qualityGateAgents -e knowledgeAgents -e designAgents -e archivePath -e "Find out used repository" tests/smoke tests/smoke.sh`: no output, exit 1.
11. **R4.3.** `git -C <tmp>/run/project log --format=%s`: exactly one line, `Sample project for a smoke run`.
12. `git -C <tmp>/run/project ls-files`: `.gitignore`, `.slicewright/smoke.json`, `allowed-tools`, `config.jq` and `pipeline.json`.
13. `git -C <tmp>/run/project config --local --list`: includes `user.name=Slicewright smoke test`, `user.email=smoke-test@slicewright.invalid` and `commit.gpgsign=false`.
14. `cat <tmp>/run/project/.gitignore`: `/slice/`.
15. **R6.** `sh tests/smoke.sh check <tmp>/run`: exit 1, within a few seconds, with this output in order:
    - `FAIL 1 session:`, `FAIL 2 isolation:`, `FAIL 3 status:`, `FAIL 4 records:`, `FAIL 5 tests:`, `FAIL 6 acceptance:`, `PASS 7 clean-tree:` and `FAIL 8 index:`, each with a detail;
    - then `cost_usd: unknown`, `duration_ms: unknown` and `result: failed, 7 of 8 checks failed`;
    - and last `run: <tmp>/run`.
16. `dash tests/smoke.sh check <tmp>/run`: the same output, exit 1.
17. `/usr/bin/time -p sh tests/smoke.sh check <tmp>/run`: the same output, and `real` below 5. Checks 5 and 6 don't wait out the watchdog.
18. `sh tests/smoke.sh wait <tmp>/run`: within seconds, exit 1. The first line is `ended: the background run stopped without finishing; checks evaluated now`, then the same report.
19. **The report writes nothing.** `ls -A <tmp>/run`: only `project`.
20. `git -C <tmp>/run/project status --porcelain --untracked-files=all`: no output. Checks 5 and 6 left the copy unchanged.
21. `sh tests/smoke.sh prepare tests/smoke <tmp>/run`: exit 2. The error says the run folder exists, and the last line is `run: <tmp>/run`.
22. `sh tests/smoke.sh prepare tests/smoke <tmp>/missing/run`: exit 2, because the parent is missing.
23. `sh tests/smoke.sh prepare tests/smoke tests/smoke/inside-run`: exit 2, because the folder is inside the repo.
24. `ls -A tests/smoke`: only `allowed-tools`, `config.jq` and `pipeline.json`.
25. `sh tests/smoke.sh prepare <tmp>/no-such-source <tmp>/run2`: exit 2.
26. `ls -A <tmp>`: only `run`.
27. `sh tests/smoke.sh check <tmp>`: exit 2, not a run folder.
28. `sh tests/smoke.sh wait <tmp>`: exit 2, not a run folder.
29. `env PATH=/usr/bin:/bin which claude`: no output, exit 1. Steps 30 to 36 rely on this, so run them only when it holds.
30. `env PATH=/usr/bin:/bin sh tests/smoke.sh bogus`: exit 2, and the usage.
31. **R5, `--minutes`.** `env PATH=/usr/bin:/bin sh tests/smoke.sh start --minutes 0`: exit 2, and the message names `--minutes`.
32. `mkdir -p <tmp>/home/.slicewright`
33. `touch <tmp>/home/.slicewright/smoke.json`
34. **D7.** `env HOME=<tmp>/home TMPDIR=<tmp> PATH=/usr/bin:/bin sh tests/smoke.sh start`: exit 2, and the message names `.slicewright/smoke.json`.
35. `env HOME=<tmp>/home TMPDIR=<tmp> PATH=/usr/bin:/bin sh tests/smoke.sh`: exit 2, and the same message.
36. `env TMPDIR=<tmp> PATH=/usr/bin:/bin sh tests/smoke.sh start`: exit 2, and the message names `claude` as missing.
37. `ls -A <tmp>`: only `home` and `run`. No refused command made a `slicewright-smoke` folder.
38. **Constants.** `grep -n -e '^LIMIT_MINUTES=90$' -e '^WAIT_SECONDS=540$' -e '^CHECK_SECONDS=120$' -e '^CONFIG_NAME=smoke.json$' -e '^SLICE_DIR=slice$' -e '^RECORDS=' -e '^TEST_COMMAND=' -e '^RECORDS_INDEX=' tests/smoke.sh`: 8 lines near the top.
39. **R5: one place, no ceiling.**
    - `grep -n -w 90 tests/smoke.sh`: one line, `LIMIT_MINUTES=90`.
    - `grep -n -e max-budget -e bypassPermissions -e dangerously -e '--bare' -e '--safe-mode' tests/smoke.sh`: no output.
40. **R4.4.** `grep -n -e '--setting-sources project,local' -e '--strict-mcp-config' -e '--no-session-persistence' -e '--permission-prompts none' -e '--permission-mode acceptEdits' -e '--plugin-dir' -e 'stream-json' -e 'CLAUDE_CODE_MESSAGING_TOKEN' -e 'AI_AGENT' tests/smoke.sh`: each pattern is found.
41. **R1.** `git diff --name-only d96f140 -- plugins`: no output. `d96f140` is the commit the slice started from.
42. **AC10, R8.** `git diff -U0 d96f140 -- .slicewright/config.json`: one hunk. Its only removed line is `"testAgents": []`, and every added line belongs to the one `smoke` entry.
43. `jq -e '[.pipeline[] | select(.name == "test") | .params.testAgents[] | {name, agent, executionMode}] == [{"name": "smoke", "agent": "general-purpose", "executionMode": "fork"}]' .slicewright/config.json`: `true`.
44. `jq -r '.pipeline[] | select(.name == "test") | .params.testAgents[0].context' .slicewright/config.json`: exactly the context above.
45. `jq -e '.pipeline[] | select(.name == "test") | del(.params.testAgents) == {"name": "test", "skill": "slice:test", "executionMode": "fork", "onError": "test-decision", "params": {"context": "", "record": "test-reports.md"}}' .slicewright/config.json`: `true`.

**Coverage:**

- R1: steps 23, 24 and 41.
- R4: steps 4, 8, 9, 11 to 14, and 40.
- R5: steps 31, 38 and 39.
- R6: steps 15 to 20. T04's self-test proves the PASS paths of checks 3 to 8.
- R7, in part: steps 15, 18 and 21 show the last line, and 19 shows that nothing is written or deleted.
- R8 and AC10: steps 42 to 45.
- AC6: steps 9 and 10.
- AC5, AC8, AC9, AC11 and AC15: the runs by hand in the plan's Q1, and its Deployed checks.

## Boundaries

- Change only `tests/smoke.sh`, `tests/smoke/pipeline.json`, `tests/smoke/config.jq`, `tests/smoke/allowed-tools`, and the `test` stage's `testAgents` in `.slicewright/config.json`. Leave every other byte of that file alone.
- Never touch anything under `plugins/slice/` or `.slicewright/stable/`.
- Never touch `README.md`, `AGENTS.md`, `.claude/settings.json`, `doc/` or `slice/docs/`. Add no permission rules.
- Other tasks own:
  - `tests/static.sh` and `tests/static/` (T01);
  - `tests/sample/` (T02): never create or change the sample, its request or `accept.sh`;
  - `tests/selftest.sh` and `tests/fixtures/` (T04).
- Add no `.gitignore` under `tests/`.
- Copy no default stage's params under `tests/`: the configuration is generated at run time.
- Never start a headless session in the Verify, and never delete a run folder. The only removals are the guarded scratch folders of checks 5 and 6.
