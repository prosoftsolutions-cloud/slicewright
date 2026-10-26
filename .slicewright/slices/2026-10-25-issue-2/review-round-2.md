---
slice: issue-2
tasks: 2
waves: 2
---

# Plan: Tests for new plugin versions, fixes for round 2 of code-reviews.md

## Scope

Findings to fix, from round 2 of `code-reviews.md`:

- **R2-F1** `wait` writes `1` to `ended` and exits 1 even when the report it saves passes · decision: fix
- **R2-F2** The acceptance check misses the request's rule that only a to z become upper case · decision: fix
- **R2-F3** The acceptance check misses the request's "without the option, nothing changes" · decision: fix

Not in this plan: the advisory findings R2-F4, R2-F5 and R2-F6, which have no fix decision.

Estimated blast radius of all the fixes together:

- Changed: `tests/smoke.sh` (`cmd_wait`'s branch for a recorded `smoke_pid` whose process is gone), `tests/sample/accept.sh` (five new cases and the locale for the last one), and the staged `slice/docs/overview/testing.md` (one bullet under "Output lines").
- Users of what changes:
  - `.slicewright/config.json`: the `smoke` entry runs `wait` and reads its status. It already says that 0 means every check passed and 1 that a check failed, which the fix makes true for this branch, so the entry stays as it is.
  - `plugins/slice/skills/test/SKILL.md`: runs the `smoke` entry. Unchanged.
  - `tests/selftest.sh`: runs `smoke.sh prepare` and `smoke.sh check`, whose check 6 runs `accept.sh`. `check` doesn't change, and the fixture passes the new cases.
  - `tests/fixtures/finished-run/greet.sh`: must pass all fifteen acceptance cases, and already does.
  - `tests/sample/project/greet.sh`: must still fail the acceptance check (AC4), now with `7 passed, 8 failed`.

## Tasks

- [x] [R2-T01 wait exits as its report says when it records a stopped run](tasks/R2-T01-wait-exits-as-its-report-says.md) · test · after: none · covers: R2-F1
- [x] [R2-T02 Acceptance check covers letters outside a to z, and greet.sh without the option](tasks/R2-T02-acceptance-check-letters-and-no-option.md) · test · after: R2-T01 · covers: R2-F2, R2-F3

## Waves

1. R2-T01
2. R2-T02

## Final check

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for each attempt. `<repo>` is the repo root's absolute path, as `pwd -P` prints it there. `350e8cf` is the revision that round 2 reviewed, and `d96f140` the one the slice started from.

- `claude plugin validate .`: passes.
- `claude plugin validate plugins/slice`: passes.
- `sh tests/static.sh`: `PASS validate`, `PASS json`, `PASS defaults`, `PASS skills` and `static: passed`; exit 0, within 60 seconds.
- `sh tests/selftest.sh`: `ok static/unbroken`, seven `caught static/…` lines, `ok smoke/unbroken` and five `caught smoke/…` lines; no `MISSED` or `kept:` line; last line `selftest: passed, 14 cases`; exit 0, within 60 seconds. The fixture still passes check 6 with the fifteen acceptance cases.
- `dash tests/selftest.sh`: the same output, exit 0.
- `sh tests/sample/project/test.sh`: `6 passed, 0 failed`, exit 0.
- **R2-F2, R2-F3, AC4.** `sh tests/sample/accept.sh tests/sample/project`: `7 passed, 8 failed`, exit 1.
- **R2-F2, R2-F3, R6.6.** `sh tests/sample/accept.sh tests/fixtures/finished-run`: `15 passed, 0 failed`, exit 0. `env LC_ALL=C sh tests/sample/accept.sh tests/fixtures/finished-run`: the same.
- `file tests/sample/accept.sh`: `ASCII text`.
- `pwd -P`: prints `<repo>`.
- `mktemp -d`: prints `<tmp>`.
- `sh tests/smoke.sh prepare tests/sample/project <tmp>/run`: exit 0, last line `run: <tmp>/run`.
- `sh tests/smoke.sh check <tmp>/run`: exit 1; `PASS 5 tests` and `PASS 7 clean-tree`, the other six `FAIL`; `result: failed, 6 of 8 checks failed`; last line `run: <tmp>/run`.
- `ls -A <tmp>/run`: only `project`. `check` still writes nothing.
- **R1-F1 kept.** `kill -0 999999` fails. Write `<tmp>/run/run.txt` with the Write tool, holding `plugin_dir: <repo>/plugins/slice`, `limit_minutes: 90` and `smoke_pid: 999999`. Then `sh tests/smoke.sh wait <tmp>/run`: exit 1, the `ended:` line, the report with `result: failed, 6 of 8 checks failed`, and `run: <tmp>/run`. Then `cat <tmp>/run/ended`: `1`.
- **R2-F1.** `cp -R tests/sample/project <tmp>/src`, then `cp -R tests/fixtures/finished-run/. <tmp>/src`, then `sh tests/smoke.sh prepare <tmp>/src <tmp>/late`. Write `<tmp>/late/run.txt` and `<tmp>/late/session.jsonl` with the Write tool, exactly as R2-T01's Verify gives them. Then `sh tests/smoke.sh wait <tmp>/late`: exit 0, the `ended:` line, `PASS 1 session` to `PASS 8 index`, `result: passed`, and `run: <tmp>/late`. Then `cat <tmp>/late/ended`: `0`. Then `sh tests/smoke.sh wait <tmp>/late` again: exit 0, the saved report.
- **R2-F1, the page.** `grep -n -F "exits as the report says: 0 when every check passed, 1 otherwise" slice/docs/overview/testing.md`: one line. `grep -n -F 'writes `1` to `ended`' slice/docs/overview/testing.md`: no output.
- `git diff --name-only 350e8cf`: exactly `tests/sample/accept.sh` and `tests/smoke.sh`.
- **AC1.** `git diff --name-only d96f140 -- plugins`: no output. `git -C .slicewright/stable status --porcelain`: no output.
- **AC10.** `git diff --name-only 350e8cf -- .slicewright/config.json`: no output.

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R2-F1 | R2-T01 |
| R2-F2 | R2-T02 |
| R2-F3 | R2-T02 |

## Plan decisions

- **I filled in both tasks myself.** Each changes a few named lines in files I had read in full while drafting: `cmd_wait`, `session_part`, `load_result`, `record` and `report` in `tests/smoke.sh`; `run` and the case list in `tests/sample/accept.sh`; and the "Output lines" bullet, the `wait` row and the `ended` line of `slice/docs/overview/testing.md`. The `test` type names no skill. I also ran R2-F1's passing folder through `sh tests/smoke.sh check` in a scratch folder (all eight checks pass), and the locale cases of R2-F2 by hand, to make sure the Verify steps hold. → R2-T01, R2-T02
- **The tasks are chained,** one per wave, because the stage runs them one after another. → all
- **R2-F1 takes the finding's first option: the code changes.** The testing page's `wait` row and `ended` line, the `smoke` entry's context, and the design's `wait` row ("0 or 1 once ended, from the recorded result") all say that an ended run exits as its report says. Once this branch records the run as ended, it follows them, and the design's older output line for this branch, "exits 1", no longer applies to a recorded run. `slice/design.md` isn't edited: it is the slice's design record, and the testing page is where consolidate publishes the behavior. → R2-T01
- **A folder with no `smoke_pid` keeps exit 1 and stays write-free.** The finding concerns only a run that was recorded as started. The new bullet now says "exits 1" for that folder in so many words, because its first sentence no longer gives one status for both. → R2-T01
- **The double record of cost and duration stays.** If `session_part` died after it recorded `cost_usd` and `duration_ms`, `wait` adds them again. The last value counts, and both come from the same `session.jsonl`. No finding asks to change this. → R2-T01
- **R2-F2 and R2-F3 are one task.** Both are gaps in the same code, the case list of `tests/sample/accept.sh`, against the same request. → R2-T02
- **The locale is `C.UTF-8`, exported just before the last `greet.sh` case.** It exists on this machine and on common Linux systems, and under it `tr '[:lower:]' '[:upper:]'` changes `ë` in `sh` and in `dash`, while the fixture's `tr` doesn't. The case goes last among the `greet.sh` cases, right after `--shout ada-lovelace_42`, so the other cases keep the caller's locale and only the doc case runs after it. On a machine without `C.UTF-8`, the case falls back to the C locale: a correct `greet.sh` still passes, but a locale-aware one isn't caught. → R2-T02
- **The new cases without the option go next to the existing ones,** named `greet.sh <args>` as the others are, with the expectations of `tests/sample/project/test.sh`. The case name `greet.sh --shout zoë` shows the real letter; the file stays ASCII through `printf` octal escapes. → R2-T02
- **The counts change.** The fixture gives `15 passed, 0 failed`. The unchanged sample passes the four new cases without the option and `greet.sh Ada --shout`, `greet.sh Ada` and `greet.sh -x`, and fails the rest: `7 passed, 8 failed`. The testing page gives no counts, so it doesn't change for R2-F2 or R2-F3. → R2-T02
- **No new self-test cases.** Each finding's repro is in its task's Verify, on a `mktemp -d` folder. Self-test cases for `wait` are R2-F6, which wasn't chosen. → R2-T01, R2-T02
- **Permission rules.** As in the earlier plans, the Verify and Final check commands, such as `sh tests/…`, `dash`, `env LC_ALL=…`, `file`, `grep`, `cp`, `mktemp`, `kill -0`, `pwd -P` and `git -C`, may have no allow rule yet. Add any that are needed by hand to `.claude/settings.local.json`, not with `/slice:configure --permissions`. No task adds the rules. → all
