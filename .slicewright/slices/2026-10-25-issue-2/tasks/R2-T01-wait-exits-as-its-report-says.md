---
id: R2-T01
title: wait exits as its report says when it records a stopped run
type: test
depends: []
covers: [R2-F1]
---

# R2-T01 wait exits as its report says when it records a stopped run

## Goal

When `sh tests/smoke.sh wait <folder>` records a run whose background process is gone, it writes the report's own status to `ended` and exits with it: 0 when every check passed, 1 otherwise. The testing page says so.

## Context

**The finding, R2-F1: `wait` writes `1` to `ended` and exits 1 even when the report it saves passes.**

- Where: `tests/smoke.sh:806`, in `cmd_wait`.
- Bar: the testing page, `slice/docs/overview/testing.md:86` ("0 or 1 once the run has ended, as its report says") and `:193` ("`<run>/ended` written last: 0 when every check passed, 1 otherwise"); the `smoke` entry's context in `.slicewright/config.json` ("Status 0 means every check passed, and 1 that a check failed"); the design's `wait` row, "0 or 1 once ended, from the recorded result". The design's output line for this branch does say "exits 1".
- Problem: R1-F1's new branch always writes `1` to `ended` and exits 1. `session_part` records `exit_code`, `cost_usd` and the other keys before it runs the report, and no longer traps INT and TERM by then. If the background part dies while the report runs, `wait` evaluates all eight checks as passing and saves `result: passed` in `checks.txt`, but writes `1` to `ended`. This `wait` and every later one exit 1, which the test stage's suite reads as a failed check, and `ended` disagrees with `checks.txt`. The window is the time the report takes, up to a few minutes with checks 5 and 6.
- Proof: `sh tests/smoke.sh prepare <sample with the fixture on top> <scratch>/late`, then a `run.txt` as `session_part` leaves it before `ended` (`plugin_dir`, `limit_minutes: 90`, `smoke_pid: 999999` after `kill -0 999999` failed, `exit_code: 0`, `time_limit_reached: no`, `interrupted: no`, `cost_usd: 4.2`, `duration_ms: 3600000`) and a `session.jsonl` with an init event (only `slice`, at `plugins/slice`, no MCP server) and a `success` result event; then `sh tests/smoke.sh wait <scratch>/late` → `ended: the background run stopped without finishing; checks evaluated now`, `PASS 1 session` to `PASS 8 index`, `result: passed`, exit 1; and `cat <scratch>/late/ended` → `1`.
- Suggested fix, the first of the two the finding offers, which this plan takes: in `cmd_wait`'s branch, keep the status of `report >"$RUN/checks.txt"`, 1 for any non-zero status as `session_part` does, write it to `ended` and exit with it; then change the `wait` bullet at `slice/docs/overview/testing.md:99` to say it exits as the report says.
- Decision: fix.

**The requirements and contracts it must keep meeting:**

- **R7** Each smoke run, finished or stopped, keeps its copy, the headless session's output, its cost and duration, and the check results in one folder. When the session was stopped before it reported its cost or duration, the record says that each one is unknown. The command never deletes that folder, and its last line of output names it.
- **AC9** (R7) Given any smoke run, finished or stopped, when it ends, then its last line of output names a folder that still exists afterwards and holds the copy, the session output, the cost and duration or "unknown" for each, and the check results.
- The design's contract for `wait <run folder>`: it waits at most `WAIT_SECONDS` for `<run>/ended`, and exits 0 or 1 once ended, from the recorded result, 3 while still running, and 2 when the folder isn't a run folder. In the run folder, `ended` is written last, after `checks.txt`, and holds 0 or 1. `check <run folder>` evaluates the eight checks again, prints the report, and writes nothing in the run folder.
- R1-F1's fix, already in the code: when `ended` is missing and the process recorded as `smoke_pid` is gone, `wait` prints the `ended:` line, adds `cost_usd` and `duration_ms` to `run.txt` from `load_result`, saves the report as `checks.txt`, writes `ended` last, prints `checks.txt`. A later `wait` finds `ended` and prints the saved `checks.txt`. A folder with no `smoke_pid` in `run.txt`, such as one that only `prepare` made, gets the `ended:` line and the report, exits 1, and has nothing written in it.

## Interfaces

**Uses:** existing code in `tests/smoke.sh`, as it is:

- `load_result`: sets `RESULT`, and `COST` and `DURATION` to the numbers from the last `result` event in `$RUN/session.jsonl`, or `unknown` for each.
- `record <key> <value>`: appends `<key>: <value>` to `$RUN/run.txt`.
- `report`: evaluates the eight checks, prints the report ending with `run: $RUN`, and returns 0 only when every check passes. It writes nothing in the run folder.
- `session_part`: the model to follow. After `report >"$RUN/checks.txt"` it keeps `sp_rc=$?`, sets it to 1 when it isn't 0, writes it to `$RUN/ended`, prints `checks.txt`, and returns it.

## Changes

- `tests/smoke.sh` (changed)
  - `cmd_wait`: in the branch for a recorded `smoke_pid` whose process is gone (today lines 800 to 808), keep `load_result`, the two `record` calls and `report >"$RUN/checks.txt"` as they are. Right after the report, keep its status in `wt_rc`, following the `wt_` prefix of `cmd_wait`'s other variables, and set it to 1 when it isn't 0. Write `wt_rc` and a newline to `$RUN/ended`, still after `checks.txt`. Print `$RUN/checks.txt` and `exit "$wt_rc"`. The branch then reads:

    ```sh
          load_result
          record cost_usd "$COST"
          record duration_ms "$DURATION"
          report >"$RUN/checks.txt"
          wt_rc=$?
          if [ "$wt_rc" -ne 0 ]; then
            wt_rc=1
          fi
          printf '%s\n' "$wt_rc" >"$RUN/ended"
          cat "$RUN/checks.txt"
          exit "$wt_rc"
    ```

  - Nothing else changes: the `ended:` line, the branch for an empty `smoke_pid` (`report`, then `exit 1`, writing nothing), the loop that finds `ended` and prints `checks.txt`, `cmd_check`, `report`, `session_part`, `launch`, the checks, the report's lines, the constants and the other exit statuses.
- `slice/docs/overview/testing.md` (changed; the staged page)
  - Under "Output lines", replace the bullet that starts "When the run hasn't ended and the process recorded as `smoke_pid` is gone" with this one, word for word:

    ```markdown
    - When the run hasn't ended and the process recorded as `smoke_pid` is gone, `wait` prints `ended: the background run stopped without finishing; checks evaluated now`, then the report. It also records the run as ended: it adds `cost_usd` and `duration_ms` to `run.txt`, each `unknown` when the session didn't report it, and saves the report as `checks.txt`. Then, as for any ended run, it writes `ended` and exits as the report says: 0 when every check passed, 1 otherwise. A later `wait` prints that saved report and exits the same way. A folder whose `run.txt` has no `smoke_pid`, such as one that only `prepare` made, gets the same output and exits 1, but `wait` writes nothing in it.
    ```

  - Change nothing else on the page. Line 86 (the `wait` row) and line 193 (`<run>/ended`) already say what the code now does.

## Verify

Run each command from the repo root. `<tmp>` is the folder that `mktemp -d` prints; use a new one for every attempt, because a run folder can be recorded as ended only once. `<repo>` is the repo root's absolute path, as `pwd -P` prints it there.

- `dash -n tests/smoke.sh`: no output, exit 0.
- `pwd -P`: prints `<repo>`.
- `mktemp -d`: prints `<tmp>`.
- `cp -R tests/sample/project <tmp>/src`: exit 0.
- `cp -R tests/fixtures/finished-run/. <tmp>/src`: exit 0. The source is the sample with the fixture on top, as `tests/selftest.sh` builds it.
- `sh tests/smoke.sh prepare <tmp>/src <tmp>/late`: exit 0, last line `run: <tmp>/late`.
- `kill -0 999999`: fails, so no process has that ID. If it succeeds, use another ID that fails it, here and in `run.txt`.
- Write `<tmp>/late/run.txt` with the Write tool, holding exactly these eight lines, as `session_part` leaves it before `ended`:

  ```text
  plugin_dir: <repo>/plugins/slice
  limit_minutes: 90
  smoke_pid: 999999
  exit_code: 0
  time_limit_reached: no
  interrupted: no
  cost_usd: 4.2
  duration_ms: 3600000
  ```

- Write `<tmp>/late/session.jsonl` with the Write tool, holding exactly these two lines:

  ```text
  {"type":"system","subtype":"init","plugins":[{"name":"slice","path":"<repo>/plugins/slice"}],"mcp_servers":[]}
  {"type":"result","subtype":"success","is_error":false,"total_cost_usd":4.2,"duration_ms":3600000}
  ```

- `sh tests/smoke.sh check <tmp>/late`: `PASS 1 session` to `PASS 8 index`, `cost_usd: 4.2`, `duration_ms: 3600000`, `result: passed`, last line `run: <tmp>/late`, exit 0. Then `ls -A <tmp>/late`: only `project`, `run.txt` and `session.jsonl`. The folder is a passing run that hasn't been recorded as ended.
- **R2-F1 repro, before the change:** `sh tests/smoke.sh wait <tmp>/late` prints the `ended:` line, `PASS 1 session` to `PASS 8 index` and `result: passed`, and exits 1; `cat <tmp>/late/ended` prints `1`. This is the failure. After the change, build the folder again from `mktemp -d`, with a new `<tmp>`, through the `check` step above.
- **R2-F1, after the change:** `sh tests/smoke.sh wait <tmp>/late`, within a few minutes:
  - exit 0;
  - first line `ended: the background run stopped without finishing; checks evaluated now`;
  - then `PASS 1 session` to `PASS 8 index`, in order;
  - then `cost_usd: 4.2`, `duration_ms: 3600000` and `result: passed`;
  - last line `run: <tmp>/late`.
- `cat <tmp>/late/ended`: `0`.
- `ls -A <tmp>/late`: exactly `checks.txt`, `ended`, `project`, `run.txt` and `session.jsonl`.
- `cat <tmp>/late/checks.txt`: the report printed above, from `PASS 1 session` to `run: <tmp>/late`, with `result: passed` and without the `ended:` line.
- `cat <tmp>/late/run.txt`: the eight lines written above, then `cost_usd: 4.2` and `duration_ms: 3600000`, and nothing else.
- `sh tests/smoke.sh wait <tmp>/late`, a second time: exit 0 at once, and its output is exactly that `checks.txt`, with no `ended:` line.
- **A failing report still gives 1 (R1-F1 kept):** `sh tests/smoke.sh prepare tests/sample/project <tmp>/run`: exit 0. Write `<tmp>/run/run.txt` with the Write tool, holding exactly `plugin_dir: <repo>/plugins/slice`, `limit_minutes: 90` and `smoke_pid: 999999`, one per line. Then `sh tests/smoke.sh wait <tmp>/run`:
  - exit 1;
  - the `ended:` line, then `FAIL 1 session`, `FAIL 2 isolation`, `FAIL 3 status`, `FAIL 4 records`, `PASS 5 tests`, `FAIL 6 acceptance`, `PASS 7 clean-tree` and `FAIL 8 index`;
  - `cost_usd: unknown`, `duration_ms: unknown` and `result: failed, 6 of 8 checks failed`;
  - last line `run: <tmp>/run`.
  
  Then `cat <tmp>/run/ended`: `1`. Then `ls -A <tmp>/run`: exactly `checks.txt`, `ended`, `project` and `run.txt`.
- **R7, AC9 in part:** the steps above show that the folder of a run that stopped without finishing keeps the check results, and its cost and duration, or `unknown` for each, and that its last line names it.
- **A run that never started stays write-free:** `sh tests/smoke.sh prepare tests/sample/project <tmp>/fresh`, then `sh tests/smoke.sh wait <tmp>/fresh`: exit 1, the `ended:` line and the report, last line `run: <tmp>/fresh`. Then `ls -A <tmp>/fresh`: only `project`.
- **`check` stays write-free:** `sh tests/smoke.sh check <tmp>/fresh`: exit 1, the report, last line `run: <tmp>/fresh`. Then `ls -A <tmp>/fresh`: only `project`.
- `grep -n -F "exits as the report says: 0 when every check passed, 1 otherwise" slice/docs/overview/testing.md`: one line, the new bullet under "Output lines".
- `grep -n -F "gets the same output and exits 1, but" slice/docs/overview/testing.md`: the same line, and no other.
- `grep -n -F 'writes `1` to `ended`' slice/docs/overview/testing.md`: no output.
- `git status --porcelain`: `tests/smoke.sh` is the only changed path. The staged page is under the ignored `slice/`.

## Boundaries

- The branch for an empty `smoke_pid` keeps `report` and `exit 1`, and writes nothing. `cmd_check` and `report` write nothing in the run folder.
- `session_part`, `launch`, `do_prepare`, the eight checks, the report's format, the constants and the other exit statuses don't change.
- `wait` still adds `cost_usd` and `duration_ms` in this branch even when `session_part` had recorded them before it died. The last value counts, and both come from the same `session.jsonl`. Leave this as it is.
- `.slicewright/config.json` doesn't change: its `smoke` context already says that status 0 from `wait` means every check passed and 1 that a check failed.
- `slice/design.md` doesn't change. Its output line for this branch says "exits 1"; the plan follows its `wait` row instead (see the plan's decisions).
- `tests/selftest.sh` gets no new case. Self-test cases for `wait` are R2-F6, which wasn't chosen for a fix.
- On the testing page, only the one bullet changes. Its wording "A folder whose `run.txt` has no `smoke_pid`, such as one that only `prepare` made" is R2-F5, which wasn't chosen for a fix, and the "Isolation and permissions" section is R2-F4: leave both.
- `tests/sample/accept.sh` belongs to R2-T02.
- Nothing under `plugins/slice/` or `.slicewright/stable/` changes.
