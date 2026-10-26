---
slice: issue-2
tasks: 6
waves: 3
---

# Plan: Tests for new plugin versions

## Tasks

- [x] [T01 Static level](tasks/T01-static-level.md) · test · after: none · covers: R1, R2, AC2, AC3
- [x] [T02 Sample project](tasks/T02-sample-project.md) · test · after: none · covers: R1, R3, AC4
- [x] [T03 Smoke level and its test-stage entry](tasks/T03-smoke-level.md) · test · after: none · covers: R1, R4, R5, R6, R7, R8, AC6, AC10
- [x] [T04 Finished-run fixture and self-test](tasks/T04-fixture-and-selftest.md) · test · after: T01, T02, T03 · covers: R1, R10, AC3, AC7, AC14
- [x] [T05 Testing page and structure page](tasks/T05-testing-and-structure-pages.md) · documentation · after: T04 · covers: R9, AC12, AC13
- [x] [T06 AGENTS.md "Checking a change"](tasks/T06-agents-checking-a-change.md) · plugin · after: T04 · covers: R9, AC12

## Waves

1. T01, T02, T03
2. T04
3. T05, T06

## Final check

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for each attempt. `d96f140` is the commit the slice started from.

- `claude plugin validate .`: passes.
- `claude plugin validate plugins/slice`: passes.
- **AC2.** `sh tests/static.sh`:
  - exactly `PASS validate`, `PASS json`, `PASS defaults`, `PASS skills` and `static: passed`;
  - exit 0, well within 60 seconds.
- **AC3, AC7, AC14, R10.** `sh tests/selftest.sh`:
  - `ok static/unbroken`, seven `caught static/…` lines, `ok smoke/unbroken` and five `caught smoke/…` lines, in the case table's order;
  - no `MISSED` or `kept:` line;
  - last line `selftest: passed, 14 cases`;
  - exit 0, within 60 seconds.
- `dash tests/selftest.sh`: the same output and exit 0. The scripts are POSIX sh.
- **AC4.** `sh tests/sample/project/test.sh`: `6 passed, 0 failed`, exit 0.
- **AC4.** `sh tests/sample/accept.sh tests/sample/project`: `not ok` for the `--shout` cases and the doc case, `2 passed, 5 failed`, exit 1.
- `mktemp -d`: prints `<tmp>`.
- `sh tests/smoke.sh prepare tests/sample/project <tmp>/run`: exit 0, last line `run: <tmp>/run`.
- **AC6.** The comparison prints `true`:

  ```text
  jq -n -e --slurpfile gen <tmp>/run/project/.slicewright/smoke.json --slurpfile def plugins/slice/defaults.json --slurpfile smoke tests/smoke/pipeline.json '$smoke[0] as $s | $gen[0] as $g | $def[0].pipeline as $d | (($s.overrides | keys) == ["intake"]) and (($g | keys) == ["pipeline"]) and ([$g.pipeline[].name] == ["intake","clarify","design","plan","implement","review","consolidate"]) and ([$g.pipeline[] | has("onError")] | any | not) and ([$g.pipeline[].next] == ($s.stages[1:] + [null])) and all($g.pipeline[]; . as $st | ($s.overrides[$st.name] // {}) as $o | [$d[] | select(.name == $st.name)] as $m | ($m | length) == 1 and ($st | del(.params, .next)) == ($m[0] | del(.params, .next, .onError)) and ($st.params | del(.[$o | keys[]])) == ($m[0].params | del(.[$o | keys[]])) and all($o | to_entries[]; . as $e | $st.params[$e.key] == $e.value))'
  ```

  It compares the configuration generated from the real sample with the working copy's defaults.
- **R6, AC9 in part.** `sh tests/smoke.sh check <tmp>/run`:
  - exit 1, within a few seconds;
  - `FAIL 1 session`, `FAIL 2 isolation`, `FAIL 3 status`, `FAIL 4 records`, `PASS 5 tests`, `FAIL 6 acceptance`, `PASS 7 clean-tree` and `FAIL 8 index`;
  - `cost_usd: unknown`, `duration_ms: unknown` and `result: failed, 6 of 8 checks failed`;
  - last line `run: <tmp>/run`.

  This is `prepare` and `check` on the unchanged sample.
- `ls -A <tmp>/run`: only `project`. `check` wrote nothing.
- **AC6.** `grep -rlF -e reviewAgents -e qualityGateAgents -e knowledgeAgents -e designAgents -e archivePath -e "Find out used repository" tests`: no output. Nothing under `tests/` holds a copy of the defaults' params.
- **AC1.** `git diff --name-only d96f140 -- plugins`: no output.
- **AC1.** `git -C .slicewright/stable status --porcelain`: no output.
- **AC1.** `git diff --name-only d96f140`: only paths under `tests/`, plus `.slicewright/config.json` and `AGENTS.md`.
- **AC10.** `git diff -U0 d96f140 -- .slicewright/config.json`: one hunk. Its only removed line is `"testAgents": []`, and every added line belongs to the one `smoke` entry.

## Deployed checks

This needs a real headless Claude run, not a deployment. It costs money and takes up to 90 minutes, so no Verify or quality gate runs it. The two runs a person makes by hand, the foreground run and `--minutes 1`, are under Q1 in Assumed answers. They aren't listed here, because the test stage hands every entry here to its suites.

- the `test` stage's `smoke` suite, exactly as its context in `.slicewright/config.json` runs it: one `sh tests/smoke.sh start`, then `sh tests/smoke.sh wait <folder>` until it ends. It proves AC5, AC9, AC11 and AC15 · written by T03
  - It runs only in a run that starts after implement has committed `.slicewright/config.json`, such as after `/slice:resume`.
  - `slice/test-reports.md` shows the suite `RAN`, with eight tests named `session` to `index`, each passed (AC5, AC11, and AC15 through `isolation`), and the run folder as its artifacts.
  - That folder holds `project/`, `request.md`, `run.txt`, `session.jsonl`, `session.err`, `checks.txt` and `ended` (AC9).

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R1 | T01, T02, T03, T04 |
| R2 | T01 |
| R3 | T02 |
| R4 | T03 |
| R5 | T03 |
| R6 | T03, T04 |
| R7 | T03 |
| R8 | T03 |
| R9 | T05, T06 |
| R10 | T04 |
| AC1 | T01, T02, T03, T04 (Final check) |
| AC2 | T01 |
| AC3 | T01, T04 |
| AC4 | T02 |
| AC5 | T03 (Deployed checks; the run by hand in Q1) |
| AC6 | T03 |
| AC7 | T04 |
| AC8 | T03 (the run by hand with `--minutes 1` in Q1) |
| AC9 | T03 (in part in the Final check; fully in Deployed checks and Q1) |
| AC10 | T03 |
| AC11 | T03 (Deployed checks) |
| AC12 | T05, T06 |
| AC13 | T05 |
| AC14 | T04 |
| AC15 | T03 (Deployed checks; the run by hand in Q1) |

## Plan decisions

- **T03 runs in wave 1, next to the sample, and doesn't depend on T02.** It needs only the sample's shape. Its Verify runs `prepare` and `check` on `tests/smoke` as a stand-in source, in a fresh `mktemp -d` folder. T04's self-test and the Final check run them on the real sample. → T03
- **The `testAgents` entry is part of T03,** with the smoke command it runs. The `plugin` type's context forbids editing `.slicewright/config.json`, and the design gives the entry to a `test` task. → T03
- **The fixture is part of T04, the self-test task.** It is built on the sample, and the self-test is its only user and its only proof. → T04
- **T05 and T06 wait for T04 (D17).** T06's Verify needs only `AGENTS.md`. But implement's quality gates read `AGENTS.md` and the staged pages and run the tests they name, so the two may land only once the scripts work. → T05, T06
- **I filled in T06 myself.** It changes one section of `AGENTS.md`, whose new text the design gives word for word. I had read the file, and the `plugin` type names no skill. → T06
- **A Verify step that needs a new folder takes it from `mktemp -d`,** because implement runs each Verify several times. → T03, Final check
- **AC1 and AC10 compare against `d96f140`,** the commit the slice branch started from. → T03, Final check
- **The request states two choices more than the design lists,** so that clarify has nothing to ask:
  - an empty name after `--shout` is the same as no name;
  - after `--shout`, an argument starting with `-` is an unknown option.

  `greet.sh` checks for an unknown option before too many arguments, and the fixture's `greet.sh` follows the same order. → T02, T04
- **The sample's `AGENTS.md` names its documentation in the `slicewright:knowledge` block,** the form that consolidate's `instructions` agent keeps. So a run's consolidate replaces the block rather than adding a second one. → T02
- **`check` must return within a few seconds.** The self-test runs it six times within 60 seconds, so checks 5 and 6 stop their watchdog as soon as their command ends, and never wait out its 5-second poll. → T03, T04
- **The smoke command's refusals come in a fixed order, and nothing is created until all of them pass:**
  1. the arguments and `--minutes`;
  2. `~/.slicewright/smoke.json`;
  3. the tools;
  4. the sample;
  5. the run folder's place.

  The Verify then proves each refusal with `claude` off the `PATH`, so no session can start by mistake. It first checks that `claude` really is off that `PATH`. → T03
- **`wait` on a folder whose run never started** returns at once with exit 1 and the "stopped without finishing" report, and writes nothing, as `check` does. `wait` and `check` end with `run: <folder>` only for a run folder. → T03
- **Details the static contract leaves open:**
  - a missing `executionMode` fails as `null`, as in the runner's check;
  - `stage number <n>` counts from 1;
  - a duplicate name is reported once, on the first stage that has it;
  - a missing `skills/` folder passes;
  - a broken copy must make `static.sh` exit exactly 1 in the self-test, because 2 means it couldn't run.

  → T01, T04
- **The fixture's index entry has the Records line `2026-01-01-add-a-shout-option/`,** the folder that consolidate creates. Check 8 reads only the heading. → T04
- **Permission rules.** The Verify and Final check commands, such as `sh tests/…`, `dash`, `grep`, `find`, `mktemp`, `env` and `git -C`, have no allow rule in `.claude/settings.json` yet.
  - In an interactive run, Claude Code asks for each one.
  - Before wave 3 lands, the person may want to allow `Bash(sh tests/static.sh:*)` and `Bash(sh tests/selftest.sh:*)`. The final quality gate runs those two commands once the testing page names them.
  - Add them by hand to `.claude/settings.local.json`, which is git-ignored. Don't use `/slice:configure --permissions` during this slice. It writes `.claude/settings.json`, which this repo tracks and the spec puts out of scope. An uncommitted change there fails the final gate's clean-tree check and the Final check's AC1 step.

  No task adds the rules. → T05, T06

## Assumed answers

- **Q1:** The person stops the run once implement is done, at any point before consolidate starts. Then, from a terminal in the repo root:
  1. **`sh tests/smoke.sh`, by hand, until it passes.** It proves AC5, AC9 and AC15.
     - AC5: exit 0 within 90 minutes, all eight checks `PASS`, and last line `run: <folder>`.
     - AC9: the folder holds `project/`, `request.md`, `run.txt`, `session.jsonl`, `session.err`, `checks.txt` and `ended`, and `run.txt` has `cost_usd` and `duration_ms`.
     - AC15: `PASS 2 isolation` on this machine, whose user settings enable other plugins and hooks.
  2. **`sh tests/smoke.sh --minutes 1`, once.** It proves AC8 and AC9.
     - Exit 1, with `FAIL 1 session: the time limit of 1 minutes stopped the session` and `time limit: the session was stopped after 1 minutes`.
     - The run folder holds `timed-out`, and `run.txt` holds `cost_usd` and `duration_ms`, or `unknown` for each.
  3. **Add the measured duration and cost** from step 1's passing report to `slice/docs/overview/testing.md`, under "Cost and time".
  4. **Run `/slice:resume`.** Its test stage then runs the `smoke` suite in Deployed checks (AC11).

  No task writes those numbers, and T05 leaves that line out. → affects T05, T03
- **Q2:** Check 2 leaves out Claude Code's built-in plugins, those with `"path": "builtin"`, and the testing page says so. → affects T03, T05
