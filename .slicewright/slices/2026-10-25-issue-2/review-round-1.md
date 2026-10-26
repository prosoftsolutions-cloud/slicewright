---
slice: issue-2
tasks: 3
waves: 3
---

# Plan: Tests for new plugin versions, fixes for round 1 of code-reviews.md

## Scope

Findings to fix, from round 1 of `code-reviews.md`:

- **R1-F1** `wait` keeps no record when the background run stopped without finishing · decision: fix
- **R1-F2** The acceptance check misses three outcomes the request states · decision: fix
- **R1-F8** The testing page says `--no-session-persistence` keeps out the developer's setup · decision: fix
- **R1-F9** The testing page says the calling session's variables are unset, but one stays set · decision: fix

Not in this plan: R1-F3, accepted under D16, and the advisory findings R1-F4 to R1-F7, R1-F10 and R1-F11, which have no fix decision.

Estimated blast radius of all the fixes together:

- Changed: `tests/smoke.sh` (`cmd_wait` only), `tests/sample/accept.sh` (three new cases), and the staged `slice/docs/overview/testing.md` (four lines).
- Users of what changes:
  - `.slicewright/config.json`: the `smoke` entry runs `wait`. Its exit statuses don't change, so the entry stays as it is.
  - `tests/selftest.sh`: runs `smoke.sh prepare` and `smoke.sh check`, whose check 6 runs `accept.sh`. `check` doesn't change.
  - `tests/fixtures/finished-run/greet.sh`: must pass the new acceptance cases, and already does.
  - `tests/sample/project/greet.sh`: must still fail the acceptance check (AC4).

## Tasks

- [x] [R1-T01 wait records a run that stopped without finishing](tasks/R1-T01-wait-records-a-stopped-run.md) · test · after: none · covers: R1-F1
- [x] [R1-T02 Acceptance check covers the three missing outcomes](tasks/R1-T02-acceptance-check-cases.md) · test · after: R1-T01 · covers: R1-F2
- [x] [R1-T03 Testing page says what the isolation flags and the unset variables do](tasks/R1-T03-testing-page-isolation-wording.md) · documentation · after: R1-T02 · covers: R1-F8, R1-F9

## Waves

1. R1-T01
2. R1-T02
3. R1-T03

## Final check

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for each attempt. `6d2e219` is the revision that round 1 reviewed, and `d96f140` the one the slice started from.

- `claude plugin validate .`: passes.
- `claude plugin validate plugins/slice`: passes.
- `sh tests/static.sh`: `PASS validate`, `PASS json`, `PASS defaults`, `PASS skills` and `static: passed`; exit 0, within 60 seconds.
- `sh tests/selftest.sh`: `ok static/unbroken`, seven `caught static/…` lines, `ok smoke/unbroken` and five `caught smoke/…` lines; no `MISSED` or `kept:` line; last line `selftest: passed, 14 cases`; exit 0, within 60 seconds. The fixture still passes check 6 with the new acceptance cases.
- `dash tests/selftest.sh`: the same output, exit 0.
- `sh tests/sample/project/test.sh`: `6 passed, 0 failed`, exit 0.
- **R1-F2, AC4.** `sh tests/sample/accept.sh tests/sample/project`: `3 passed, 7 failed`, exit 1.
- **R1-F2.** `sh tests/sample/accept.sh tests/fixtures/finished-run`: `10 passed, 0 failed`, exit 0.
- `mktemp -d`: prints `<tmp>`.
- `sh tests/smoke.sh prepare tests/sample/project <tmp>/run`: exit 0, last line `run: <tmp>/run`.
- `sh tests/smoke.sh check <tmp>/run`: exit 1; `PASS 5 tests` and `PASS 7 clean-tree`, the other six `FAIL`; `result: failed, 6 of 8 checks failed`; last line `run: <tmp>/run`.
- `ls -A <tmp>/run`: only `project`. `check` still writes nothing.
- **R1-F1.** Write `<tmp>/run/run.txt` with the Write tool, with `plugin_dir: <repo>/plugins/slice`, `limit_minutes: 90` and `smoke_pid: 999999`, after `kill -0 999999` has failed. Then `sh tests/smoke.sh wait <tmp>/run`: exit 1, the `ended:` line, the report and `run: <tmp>/run`. Then `ls -A <tmp>/run`: `checks.txt`, `ended`, `project` and `run.txt`; and `cat <tmp>/run/run.txt` ends with `cost_usd: unknown` and `duration_ms: unknown`.
- **R1-F8, R1-F9.** `grep -n -i -F "the calling session's variables are unset" slice/docs/overview/testing.md` and `grep -n -F 'persistence` exclude' slice/docs/overview/testing.md`: no output from either.
- `git diff --name-only 6d2e219`: exactly `tests/sample/accept.sh` and `tests/smoke.sh`.
- **AC1.** `git diff --name-only d96f140 -- plugins`: no output. `git -C .slicewright/stable status --porcelain`: no output.
- **AC10.** `git diff --name-only 6d2e219 -- .slicewright/config.json`: no output.

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R1-F1 | R1-T01 |
| R1-F2 | R1-T02 |
| R1-F8 | R1-T03 |
| R1-F9 | R1-T03 |

## Plan decisions

- **I filled in all three tasks myself.** Each changes a few named lines in one or two files that I had read in full while drafting: `cmd_wait`, `load_result`, `record`, `report` and `session_part` in `tests/smoke.sh`; `run` and the case list in `tests/sample/accept.sh`; and the four lines of `slice/docs/overview/testing.md`. Neither the `test` type nor the `documentation` type names a skill. → R1-T01, R1-T02, R1-T03
- **The tasks are chained,** one per wave, because the stage runs them one after another. → all
- **A folder with no `smoke_pid` stays write-free.** The earlier plan decided that `wait` on a folder whose run never started, such as one that only `prepare` made, writes nothing, as `check` does. The finding concerns a run that did start. So only a recorded `smoke_pid` whose process is gone makes `wait` write the record. The new `wait` line on the testing page says so. → R1-T01
- **`wait` records only `cost_usd` and `duration_ms`,** as the finding asks, and no `exit_code`: the exit status of a process that is gone can't be known. It writes `1` to `ended` and exits 1, as the finding and the design's `wait` contract say. → R1-T01
- **R1-F1's change to the testing page is part of R1-T01,** a `test` task, because each finding belongs to exactly one task. It replaces only the `wait` bullet under "Output lines". → R1-T01
- **The new acceptance cases go in the request's order,** and the empty-name case is named `greet.sh --shout ''`, following the `greet.sh <args>` names. On the unchanged sample, `greet.sh Ada --shout` already passes, so the counts become `3 passed, 7 failed`. → R1-T02
- **R1-F9 is fixed on the page, not in the code.** The script unsets exactly design D7's list, and the finding offers the rewording as a fix. The headless command's lead-in makes the same claim, so it changes too. → R1-T03
- **No new self-test cases.** Each finding's repro is in its task's Verify, on a `mktemp -d` folder. Self-test cases for `wait` and the other checks are R1-F4 to R1-F7, which weren't chosen. → R1-T01, R1-T02
- **Permission rules.** As in `plan.md`, the Verify and Final check commands, such as `sh tests/…`, `dash`, `grep`, `cp`, `mktemp`, `kill -0` and `git -C`, may have no allow rule yet. Add any that are needed by hand to `.claude/settings.local.json`, not with `/slice:configure --permissions`. No task adds the rules. → all
