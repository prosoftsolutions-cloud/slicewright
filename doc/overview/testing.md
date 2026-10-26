---
type: overview
---

# Testing

How the plugin in `plugins/slice` is tested before a new version is merged to `master` and becomes the stable version.

## Levels

There are three: the static level, the self-test and the smoke level. They need the `claude` CLI, `jq`, `git` and a POSIX `sh` with its standard utilities, and nothing else. Each command runs from the repo root as `sh tests/<name>.sh`. The tests live in `tests/`, outside the plugin folder, as [Structure](structure.md) says.

### Static level

`sh tests/static.sh [<plugin folder>]` checks a plugin folder without a model. The folder defaults to `plugins/slice`, and a relative path resolves against the current folder.

Its four checks, in order:

- `validate`: `claude plugin validate` on the repo and on the plugin folder. Only the exit status counts, so warnings pass.
- `json`: every `*.json` file under the plugin folder and under `.claude-plugin/` holds exactly one JSON value. An empty file fails, and so does a file with several values.
- `defaults`: the pipeline in the folder's `defaults.json`, checked by `tests/static/defaults.jq`, which holds every rule. Among them: each stage has a name of its own and an `executionMode` of `inline` or `fork`, every `skill` value is `TBD` or names a skill folder, and every `next`, `onError` and choice names a stage.
- `skills`: each `SKILL.md`'s frontmatter, checked by `tests/static/skill.awk`. The `name` equals the folder, the `description` isn't empty, and every skill except `new`, `resume` and `configure` has `user-invocable: false`. When `skill.awk` itself fails on a file, the check fails for that file.

Why: it catches a broken stage, a dangling `next`, `onError` or choice, and frontmatter that `claude plugin validate` misses. It needs no model, so it is cheap enough for every quality gate.

Output:

- `PASS <check>` for each check that passes, or one `FAIL <check>: <subject>: <problem>` line for each problem. The subject is the file, stage or folder the problem concerns.
- A failed validation is followed by the validator's output, indented by two spaces.
- The last line is `static: passed` or `static: failed, <n> problems`.

Exit status: 0 when every check passes, and 1 when any fails. It is 2 when the command can't run: the folder, `claude` or `jq` is missing, or it got more than one argument. It then prints `static: cannot run: <reason>` on stderr.

### Self-test

`sh tests/selftest.sh` takes no arguments. It proves, with no Claude session, that each check catches what it is meant to. Each case breaks one thing in a copy, runs the check on the copy, and expects the check to name what broke.

Its work folder is `mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX"`, and every copy goes in it. The folder is removed only when every case passes. Otherwise the self-test keeps it and prints `kept: <folder>`.

- The `static/…` cases break a copy of `plugins/slice` and run `sh tests/static.sh` on it. `static/checker` breaks a checker instead: `static.sh` reads its checkers from its own repo, so the case copies the parts `static.sh` needs and runs the copy's `static.sh`. A broken case must exit 1 with a `FAIL` line that names its subject.
- The `smoke/…` cases break a run folder that `prepare` made from the sample with the fixture on top, and run `sh tests/smoke.sh check` on it. A broken case must fail its own check and pass every other check from 3 to 8.
- `static/unbroken` must exit 0.
- `smoke/unbroken` must fail checks 1 and 2, which need a real session, and pass checks 3 to 8. Checks 1 and 2 fail in every smoke case.
- Each break must change something. A break that changed nothing is `MISSED`.

The 15 cases:

| Case | Break | Must show |
|---|---|---|
| `static/unbroken` | none | exit 0 |
| `static/next` | stage `implement`'s `next` set to `no-such-stage` | a `FAIL` line with `stage implement` |
| `static/choice` | stage `design-review`'s `choices.approve` set to `no-such-stage` | `stage design-review` |
| `static/duplicate` | stage `clarify` renamed to `intake` | `stage intake` |
| `static/skill` | stage `deploy`'s `skill` set to `slice:no-such-skill` | `stage deploy` |
| `static/name` | `name: planner` in `skills/plan/SKILL.md` | `/skills/plan/SKILL.md` |
| `static/user-invocable` | the `user-invocable: false` line removed from `skills/review/SKILL.md` | `/skills/review/SKILL.md` |
| `static/json` | the last line of the plugin's `.claude-plugin/plugin.json` removed, so it doesn't parse | `/.claude-plugin/plugin.json` |
| `static/checker` | `tests/static/skill.awk` made unparsable, in a copy of the repo's manifests, plugin and static checks, whose own `static.sh` runs | `/skills/plan/SKILL.md` |
| `smoke/unbroken` | none | `FAIL` for checks 1 and 2, `PASS` for 3 to 8 |
| `smoke/stage-failed` | the `review` row of `slice/status.md` set to `failed` | `FAIL 3 status`, and 4 to 8 pass |
| `smoke/record-removed` | `slice/plan.md` removed | `FAIL 4 records`, and 3 and 5 to 8 pass |
| `smoke/acceptance` | the sample's own `greet.sh` put back, and committed | `FAIL 6 acceptance`, and 3 to 5, 7 and 8 pass |
| `smoke/uncommitted` | an uncommitted `notes.txt` | `FAIL 7 clean-tree`, and 3 to 6 and 8 pass |
| `smoke/index-entry` | `.slicewright/slices/index.md` cut to `# Slices`, and committed | `FAIL 8 index`, and 3 to 7 pass |

Output: one line for each case, `ok <case>`, `caught <case>: <the matching line>`, or `MISSED <case>: <why>` followed by the case's output, indented. The last line is `selftest: passed, 15 cases` or `selftest: failed, <k> of 15 cases`.

Exit status: 0 when every case passes, and 1 when a case is missed. It is 2 when a tool is missing, or when it got an argument, with `selftest: <reason>` on stderr. Besides `claude`, `jq` and `git`, it needs `mktemp` and `cmp`.

The fixture, `tests/fixtures/finished-run/`, is an overlay on `tests/sample/project/`:

- It holds only what a passing run adds or changes: `greet.sh` with the feature, `doc/product/spec/greeting.md`, which mentions `--shout`, the `slice/` records, and `.slicewright/slices/index.md`.
- It has no `.gitignore` and no `.slicewright/smoke.json`, because `prepare` writes both.
- The self-test copies the sample, lays the overlay on top, and runs `prepare` on the result for each smoke case.
- Its `slice/` folder is committed in this repo, because the repo's `/slice/` rule in `.gitignore` matches only the root.

### Smoke level

It runs `/slice:new` headless, with the sample's request, on a copy of the sample, through seven stages. Then it evaluates eight checks on what the run left.

Why: it shows that the working copy's pipeline still delivers a working feature, before the merge. Pass or fail rests only on checks a command evaluates on files, so a failure can be reproduced, and checking a run again costs nothing.

| Command | What it does | Exit status |
|---|---|---|
| `sh tests/smoke.sh [--minutes <n>]` | the whole run in the foreground: prepare, session, checks and report | 0 every check passed, 1 a check failed, 2 couldn't run |
| `sh tests/smoke.sh start [--minutes <n>]` | prepares the copy, starts the session in the background, and returns at once | 0 started, 2 couldn't run |
| `sh tests/smoke.sh wait <run folder>` | waits up to `WAIT_SECONDS`, 540 seconds, for a background run to end, and prints its report | 0 or 1 once the run has ended, as its report says; 3 while the run is going; 2 couldn't run |
| `sh tests/smoke.sh check <run folder>` | evaluates the eight checks again on what a run left, and prints the report. It starts no session and writes nothing in the run folder. | 0, 1 or 2 |
| `sh tests/smoke.sh prepare <source folder> <run folder>` | copies a source folder, writes the test configuration, and commits | 0 or 2 |
| `sh tests/smoke.sh _finish <run folder>` | internal: the session part of a background run, which `start` starts with `nohup` | as the foreground run |

Status 2 means the command couldn't run: wrong usage, a missing tool, an existing `~/.slicewright/smoke.json`, a run folder inside the repo, a failed `prepare`, or a folder that isn't a run folder because it has no `project/`. Wrong usage prints the usage. Any other reason prints `error: <message>`.

Output lines:

- The foreground run prints `run: <folder>`, `prepared: <folder>/project` and `session: started, time limit <n> minutes`. When the session ends, it prints the report.
- `start` prints `prepared: <folder>/project`, `session: started in the background, time limit <n> minutes`, `next: sh tests/smoke.sh wait <folder>` and `run: <folder>`.
- `prepare` prints `prepared: <folder>/project` and `run: <folder>`.
- `wait` prints the recorded report once the run has ended. While the run is going, it prints `running: the session has not ended yet` and `run: <folder>`, and exits 3.
- When the run hasn't ended and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report. It also records the run as ended: it adds `cost_usd` and `duration_ms` to `run.txt`, each `unknown` when the session didn't report it, and saves the report as `checks.txt`. Then, as for any ended run, it writes `ended` and exits as the report says: 0 when every check passed, 1 otherwise. A later `wait` prints that saved report and exits the same way. A folder whose `run.txt` has no `smoke_pid`, such as one that only `prepare` made, gets the same output and exits 1, but `wait` writes nothing in it.
- Every command whose run folder exists ends with `run: <folder>`, whatever its exit status. An error comes before that line. `wait` and `check` on a folder with no `project/` print only the error.

The report, which the foreground run, `wait` and `check` print, and which a run saves as `checks.txt`:

```text
PASS|FAIL <n> <name>: <detail>     one line for each check, from 1 to 8, in order
cost_usd: <number>|unknown
duration_ms: <number>|unknown
time limit: the session was stopped after <n> minutes     only when the time limit stopped it
result: passed                     or: result: failed, <k> of 8 checks failed
run: <absolute run folder>
```

`cost_usd` and `duration_ms` come from the last `result` event in `session.jsonl`.

The headless command. It runs in `<run>/project`, with stdin from `/dev/null`, after some variables of the calling session are unset, as Isolation and permissions says:

```text
claude -p "/slice:new --config smoke.json <content of <run>/request.md>" \
  --output-format stream-json --verbose \
  --setting-sources project,local --strict-mcp-config \
  --plugin-dir <repo>/plugins/slice \
  --permission-mode acceptEdits --permission-prompts none \
  --no-session-persistence --allowedTools "<the allow list, joined with commas>"
```

`<run>/request.md` is a copy of `tests/sample/request.md`. The output goes to `session.jsonl`, and stderr to `session.err`. There is no `--max-budget-usd` and no `--model`.

## Where they run

The project's tests that need no headless Claude run are exactly `sh tests/static.sh` and `sh tests/selftest.sh`.

They run in the "build and tests" quality gates of the `implement`, `review-fix` and `bug-fix` stages in `.slicewright/config.json`, and by hand.

`sh tests/smoke.sh` needs a headless Claude run. It runs in the `test` stage's `smoke` suite in `.slicewright/config.json`. A run takes longer than one shell command may last, so the suite runs `start`, then `wait <folder>` again while it exits 3. It reports each check as one test, by its name, and the run folder as the artifacts. A status 2 from either command means the suite didn't start.

The smoke test also runs by hand. It never runs in a task's Verify or a quality gate, because it is too slow and costly.

## Cost and time

- The static level and the self-test each finish within 60 seconds.
- The smoke level's time limit is 90 minutes. It is set once, as `LIMIT_MINUTES=90` at the top of `tests/smoke.sh`. `--minutes <n>`, a positive whole number, overrides it for one run.
- A watchdog checks the session every 5 seconds. At the limit it writes `<run>/timed-out`, sends TERM, and sends KILL 30 seconds later if the session is still alive. Check 1 then fails, and the report says `time limit: the session was stopped after <n> minutes`.
- A foreground run that gets INT or TERM stops the session, records `interrupted: yes`, still evaluates the checks, and prints the report.
- There is no cost ceiling, and no `--max-budget-usd`. The cost is billed to the developer's own Claude Code sign-in. Only the time limit bounds what a run spends.
- Each run's `run.txt`, with `cost_usd` and `duration_ms`, and its `checks.txt` keep its cost and duration. Each is `unknown` when the session stopped before it reported them.

## The sample

- `tests/sample/project/` is the sample project, a small POSIX sh program: `greet.sh`, its tests in `test.sh`, an `AGENTS.md` and its documentation in `doc/`.
  - Its tests are `sh test.sh`, run inside the sample's folder, as its `AGENTS.md` names them. They are the sample's tests, not this repo's.
  - Its `doc/` is at the default `knowledge` path, `./doc`.
  - It needs no install and no network.
  - Its `AGENTS.md` instructs the pipeline inside a run. It is not this repo's instructions.
- `tests/sample/request.md` is the request. It asks for a `--shout` option, with every choice stated, so that clarify has no open question.
- `sh tests/sample/accept.sh <project folder>` is the acceptance check.
  - It sits outside `project/`, and is never copied into a run, so the pipeline never sees or changes it. Check 6 runs it from the repo, against a scratch copy of the run's project.
  - Each case compares stdout and stderr byte for byte: the wanted line with its newline, or nothing. An extra blank line fails.
  - Its last case checks that `doc/product/spec/greeting.md`, the page the request names, mentions `--shout`.
  - It never writes to the folder. It exits 0 when every case passes, 1 when any fails, and 2 on wrong usage, or when the folder or its `greet.sh` is missing.
  - It fails on the unchanged sample.

## How a run copies the sample

The run folder is `${TMPDIR:-/tmp}/slicewright-smoke/<YYYYMMDDTHHMMSSZ>-<pid>`, from the UTC time and the command's process ID.

- The command refuses a folder inside the repo, with exit 2.
- Setting `TMPDIR` for one command moves the runs. The OS may clear old files there.
- No command deletes a run folder.

`prepare` makes the copy in these steps:

1. It copies the source folder to `<run>/project` with `cp -R`.
2. It writes the generated test configuration to `<run>/project/.slicewright/smoke.json`.
3. It appends `/slice/` to `<run>/project/.gitignore`, so the pipeline's `slice/` folder is ignored.
4. It runs `git init` in the copy, with a local identity, and with commit signing off.
5. It commits everything in one commit, so the run starts from a clean tree.

Its rules: the source folder must exist, the run folder must not exist, its parent must exist, and it must be outside the repo.

The run folder's layout:

```text
<run>/project/        the copy, under git: the session's working folder
<run>/request.md      the request as sent
<run>/run.txt         "key: value" lines; when a key repeats, the last value counts:
                      plugin_dir, limit_minutes, allowed_tools, started, smoke_pid,
                      ended, exit_code, time_limit_reached (yes|no),
                      interrupted (yes|no), cost_usd (<number>|unknown),
                      duration_ms (<number>|unknown)
<run>/session.jsonl   the session's stream-json output
<run>/session.err     the session's stderr
<run>/timed-out       only when the watchdog stopped the session
<run>/smoke.log       start only: the output of the background part
<run>/checks.txt      the report
<run>/ended           written last: 0 when every check passed, 1 otherwise
```

## The test configuration

- `prepare` generates it at run time with `jq --slurpfile smoke tests/smoke/pipeline.json -f tests/smoke/config.jq <repo>/plugins/slice/defaults.json`.
- The session uses it through `/slice:new --config smoke.json`, so the run's `status.md` shows `config: smoke.json`.
- A stray override, or a stage that isn't in the defaults exactly once, makes `prepare` exit 2.
- The seven stages come from `stages` in `tests/smoke/pipeline.json`: `intake`, `clarify`, `design`, `plan`, `implement`, `review` and `consolidate`.
- Each is the whole default stage of that name, without `next` and `onError`, with its `params` deep-merged with its override.
- Each stage's `next` is the one after it, and `consolidate` has none.
- The file holds only `pipeline`, so `sharedParams` come from the defaults. Nothing under `tests/` copies the defaults' params.
- There are no gates and no `onError`, so any error ends the run.

Overrides. There is exactly one, intake's `params.context`, and its text is in `tests/smoke/pipeline.json`. It keeps the clean-tree check, and drops the check against a remote and the "ask user" step. The reason: the default intake context asks for the "latest sources", which needs a remote that the copy doesn't have. It also says to "ask user", which no one can answer headless.

No `taskTypes` override. The sample's `AGENTS.md` maps `greet.sh` and `test.sh` to `backend` code, and its doc pages to `documentation`, so the run keeps testing the defaults' task types. If a run ever returns `NO_TASK_TYPE`, the fallback is a `cli` task type in the test configuration. It would be a second override, listed here.

The rule: every override in `tests/smoke/pipeline.json` is listed on this page, with its reason.

## Isolation and permissions

- The plugin loads only from `plugins/slice`, through `--plugin-dir`, and never from `.slicewright/stable/`. `plugin_dir` in `run.txt` records its absolute path.
- The developer's own setup is left out. `--setting-sources project,local` and `--strict-mcp-config` exclude the developer's user settings, plugins, skills, hooks and MCP servers. `--no-session-persistence` keeps the run's session from being saved to disk, so it can't be resumed.
- Some variables of the calling session are unset, such as `CLAUDECODE` and `CLAUDE_CODE_SESSION_ID`, and `tests/smoke.sh` lists them. Every other variable is kept, such as `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`, so the sign-in stays.
- A user override stops the run. The command refuses to start, with exit 2, when `~/.slicewright/smoke.json` exists, because the runner would merge it into the test configuration.
- Permissions are `--permission-mode acceptEdits --permission-prompts none --allowedTools <list>`, so every prompt is denied. Edits, and file commands inside the copy, come from `acceptEdits`. The allow list is:
  - the rules in `tests/smoke/allowed-tools`, one per line;
  - `Skill(slice:run)`, `Skill(slice:tracking)`, and `Skill(<skill>)` for each skill in the generated configuration;
  - `Read(/<absolute plugin folder>/**)` and `Read(~/.slicewright/**)`, because the runner reads both outside the copy.

  The list is recorded as `allowed_tools` in `run.txt`. Denials appear in `permission_denials` in `session.jsonl`, and a denial doesn't hang the run.
- Tests change only copies, in new folders outside the repo. The self-test removes only its own `mktemp -d` folder, and checks 5 and 6 remove only their own scratch copies.

## The eight smoke checks

Each check prints one `PASS` or `FAIL` line with its number, its name and a detail.

1. `session`: `run.txt` and the last `result` event in `session.jsonl`, skipping a cut-off last line. The session must have ended with exit status 0, within the time limit and without an interrupt, and its result must have `subtype` `success` and no `is_error`.
2. `isolation`: the first event in `session.jsonl` with `type` `system` and `subtype` `init`. It doesn't count Claude Code's built-in plugins, those with `"path": "builtin"`. They come with Claude Code, appear in every session, and can't be turned off from the project. What remains must be exactly `slice` at the absolute `plugins/slice` path recorded as `plugin_dir`, and `mcp_servers` must be empty. A failure lists what it found.
3. `status`: the copy's `slice/status.md`. Its frontmatter must have `status: done` and an empty `next`. Its Stages table must have one `done` row for each stage in the copy's `.slicewright/smoke.json`, and no other row.
4. `records`: the copy's `slice/` folder must hold `input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`, none of them empty. They are `RECORDS` in `tests/smoke.sh`.
5. `tests`: the sample's own tests, `sh test.sh`, must pass in a scratch copy of the project. A failure shows the last 5 lines of their output.
6. `acceptance`: `tests/sample/accept.sh` must pass against a scratch copy of the project. A failure shows its `not ok` lines.
7. `clean-tree`: `git status` in the copy, untracked files included, must show no uncommitted change outside `slice/`. A copy with no `.git` fails.
8. `index`: the copy's `.slicewright/slices/index.md` must have a line that starts with `## <date> `, where the date is the first ten characters of `created` in `slice/status.md`.

Checks 5 and 6 each run in a scratch copy made with `mktemp -d`, limited to `CHECK_SECONDS`, 120 seconds, by the same watchdog. The kept copy doesn't change, so the order of the checks doesn't matter.

Checking a kept run again: `sh tests/smoke.sh check <run folder>` evaluates the eight checks again on what the run left. It starts no session and writes nothing in the run folder.

## Adding a static check

1. Add the check to `tests/static.sh`, `tests/static/defaults.jq` or `tests/static/skill.awk`, with a `FAIL` line that names its subject: the file, stage or folder it concerns. Each line that `defaults.jq` or `skill.awk` prints becomes a `FAIL` line of its check.
2. Add a case to `tests/selftest.sh` that breaks that one thing in a copy and expects the subject: copy a static case's block, and change its break and its expected subject. Add the case to the self-test's table on this page.
3. Run `sh tests/selftest.sh`, and check that `sh tests/static.sh` still passes on `plugins/slice`.
