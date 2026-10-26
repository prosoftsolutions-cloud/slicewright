---
id: R1-T01
title: wait records a run that stopped without finishing
type: test
depends: []
covers: [R1-F1]
---

# R1-T01 wait records a run that stopped without finishing

## Goal

When `sh tests/smoke.sh wait <folder>` finds that a background run's process is gone before it wrote `ended`, it records the run as ended: cost and duration in `run.txt`, the report in `checks.txt`, and `1` in `ended`. The testing page says so.

## Context

**The finding, R1-F1: `wait` keeps no record when the background run stopped without finishing.**

- Where: `tests/smoke.sh:789`, in `cmd_wait`.
- Bar: R7 and AC9 below. The design's Risks rely on this branch: "The detached run is killed with the shell call that started it. → If it doesn't [survive], `wait` finds `smoke_pid` gone, evaluates the checks, and exits 1 instead of waiting forever."
- Problem: when `ended` is missing and the process recorded as `smoke_pid` is gone, `cmd_wait` evaluates the checks and prints the report, but writes nothing. The run folder gets no `checks.txt` and no `ended`, and `run.txt` gets no `cost_usd` or `duration_ms` line. So a run whose background part died keeps no check results and no cost or duration record, and every later `wait` evaluates the checks again.
- Proof: `sh tests/smoke.sh prepare tests/sample/project <scratch>/run`, then a `run.txt` with `plugin_dir`, `limit_minutes: 90` and `smoke_pid: 999999`, then `sh tests/smoke.sh wait <scratch>/run` → `ended: the background run stopped without finishing; checks evaluated now`, the report with `cost_usd: unknown` and `duration_ms: unknown`, exit 1. Then `ls -A <scratch>/run` → only `project` and `run.txt`, and `run.txt` unchanged.
- Suggested fix: in that branch of `cmd_wait`, do what `session_part` does after the session ends: record `cost_usd` and `duration_ms` from `load_result` (`unknown` when missing), write the report to `checks.txt`, write `1` to `ended`, then print `checks.txt` and exit 1. `check` stays write-free. Update the `wait` line under "Output lines" in `slice/docs/overview/testing.md`.
- Decision: fix.

**The requirements it must keep meeting:**

- **R7** Each smoke run, finished or stopped, keeps its copy, the headless session's output, its cost and duration, and the check results in one folder. When the session was stopped before it reported its cost or duration, the record says that each one is unknown. The command never deletes that folder, and its last line of output names it.
- **AC9** (R7) Given any smoke run, finished or stopped, when it ends, then its last line of output names a folder that still exists afterwards and holds the copy, the session output, the cost and duration or "unknown" for each, and the check results.
- The design's contract for `wait`: it waits at most `WAIT_SECONDS` for `<run>/ended`; it exits 0 or 1 once ended, from the recorded result, 3 while running, and 2 when the folder isn't a run folder. "If `ended` is missing and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report, and exits 1." `check <run folder>` "evaluates the eight checks again and prints the report; writes nothing in the run folder". In the run folder, `ended` is written last, after `checks.txt`.

**A folder whose run never started stays write-free.** The earlier plan decided that `wait` on a folder with no `smoke_pid` in `run.txt`, such as one that only `prepare` made, returns at once with exit 1 and the "stopped without finishing" report, and writes nothing, as `check` does. The finding concerns a run that did start, with a `smoke_pid` recorded. So only the branch where `smoke_pid` is set and `kill -0` fails for it writes the record. A folder with no `smoke_pid` keeps today's behavior.

## Interfaces

**Uses:** existing code in `tests/smoke.sh`, as it is:

- `load_result`: sets `RESULT`, and `COST` and `DURATION` to the numbers from the last `result` event in `$RUN/session.jsonl`, or `unknown` for each.
- `record <key> <value>`: appends `<key>: <value>` to `$RUN/run.txt`.
- `report`: evaluates the eight checks, prints the report ending with `run: $RUN`, and returns 0 only when every check passes. It writes nothing in the run folder.
- `run_value <key>`: the last value of a key in `$RUN/run.txt`, empty when missing.

## Changes

- `tests/smoke.sh` (changed)
  - `cmd_wait`: in the branch `if [ -z "$wt_pid" ] || ! kill -0 "$wt_pid" 2>/dev/null` (lines 790 to 797), keep the re-check of `ended` and the `ended: the background run stopped without finishing; checks evaluated now` line as they are. Then:
    - When `wt_pid` is empty, no run started: run `report` and exit 1, as today, writing nothing.
    - Otherwise the recorded process is gone: run `load_result`; `record cost_usd "$COST"`; `record duration_ms "$DURATION"`; write the output of `report` to `$RUN/checks.txt`; write `1` and a newline to `$RUN/ended`, after `checks.txt`, as `session_part` does; print `$RUN/checks.txt`; exit 1. The `ended:` line goes to the output only, not into `checks.txt`.
  - Nothing else changes: `cmd_check`, `report`, `session_part`, `launch`, the checks, the report's lines, the constants and every exit status stay as they are.
- `slice/docs/overview/testing.md` (changed; the staged page)
  - Under "Output lines", replace the bullet that starts "When the run hasn't ended and the process recorded as `smoke_pid` is gone" with this one, word for word:

    ```markdown
    - When the run hasn't ended and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report, and exits 1. It also records the run as ended: it adds `cost_usd` and `duration_ms` to `run.txt`, each `unknown` when the session didn't report it, saves the report as `checks.txt`, and writes `1` to `ended`. A later `wait` prints that saved report. A folder whose `run.txt` has no `smoke_pid`, such as one that only `prepare` made, gets the same output, but `wait` writes nothing in it.
    ```

  - Change nothing else on the page.

## Verify

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for every attempt, because a folder's run can be recorded only once.

- `dash -n tests/smoke.sh`: no output, exit 0.
- `mktemp -d`: prints `<tmp>`.
- `sh tests/smoke.sh prepare tests/sample/project <tmp>/run`: exit 0, last line `run: <tmp>/run`.
- Write `<tmp>/run/run.txt` with the Write tool, holding exactly these three lines, with the repo's absolute path: `plugin_dir: <repo>/plugins/slice`, `limit_minutes: 90` and `smoke_pid: 999999`.
- `kill -0 999999`: fails, so no process has that ID. If it succeeds, use another ID that fails it, here and in `run.txt`.
- **R1-F1 repro, before the change:** `sh tests/smoke.sh wait <tmp>/run` exits 1 with the `ended:` line and the report, and then `ls -A <tmp>/run` shows only `project` and `run.txt`. This is the failure. After the change, start again from `mktemp -d` with a new `<tmp>`.
- **R1-F1, after the change:** `sh tests/smoke.sh wait <tmp>/run`, within a few seconds:
  - exit 1;
  - first line `ended: the background run stopped without finishing; checks evaluated now`;
  - then `FAIL 1 session`, `FAIL 2 isolation`, `FAIL 3 status`, `FAIL 4 records`, `PASS 5 tests`, `FAIL 6 acceptance`, `PASS 7 clean-tree` and `FAIL 8 index`, in that order;
  - then `cost_usd: unknown`, `duration_ms: unknown` and `result: failed, 6 of 8 checks failed`;
  - last line `run: <tmp>/run`.
- `ls -A <tmp>/run`: exactly `checks.txt`, `ended`, `project` and `run.txt`.
- `cat <tmp>/run/ended`: `1`.
- `cat <tmp>/run/run.txt`: the three lines written above, then `cost_usd: unknown` and `duration_ms: unknown`, and nothing else.
- `cat <tmp>/run/checks.txt`: the report printed above, from the `FAIL 1 session` line to `run: <tmp>/run`, without the `ended:` line.
- `sh tests/smoke.sh wait <tmp>/run`, a second time: exit 1 at once, and its output is exactly that `checks.txt`, with no `ended:` line. Then `cat <tmp>/run/run.txt`: still the same five lines, so the checks weren't evaluated or recorded again.
- **R7, AC9 in part:** the four steps above show that the folder of a run that stopped without finishing keeps the check results, and its cost and duration as `unknown`, and that its last line names it.
- **A run that never started stays write-free:** `sh tests/smoke.sh prepare tests/sample/project <tmp>/fresh`, then `sh tests/smoke.sh wait <tmp>/fresh`: exit 1, with the `ended:` line and the same report, last line `run: <tmp>/fresh`. Then `ls -A <tmp>/fresh`: only `project`.
- **`check` stays write-free:** `sh tests/smoke.sh check <tmp>/fresh`: exit 1, the report, last line `run: <tmp>/fresh`. Then `ls -A <tmp>/fresh`: only `project`.
- `grep -n -F "records the run as ended" slice/docs/overview/testing.md`: one line, the new bullet under "Output lines".
- `grep -n -F "writes nothing in it" slice/docs/overview/testing.md`: the same line, and no other.
- `git status --porcelain`: `tests/smoke.sh` is the only changed path. The staged page is under the ignored `slice/`.

## Boundaries

- `cmd_check` and `report` write nothing in the run folder, and stay that way.
- `session_part`, `launch`, `do_prepare`, the eight checks, the report's format, the constants and the exit statuses don't change.
- `.slicewright/config.json` doesn't change: its `smoke` context already says that status 1 from `wait` means a check failed.
- `tests/selftest.sh` gets no new case. Self-test cases for `wait` are R1-F7, which wasn't chosen for a fix.
- `tests/sample/accept.sh` belongs to R1-T02. The "Isolation and permissions" section and the headless command's lead-in on the testing page belong to R1-T03.
- Nothing under `plugins/slice/` or `.slicewright/stable/` changes.
