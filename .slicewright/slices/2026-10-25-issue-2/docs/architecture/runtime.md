---
type: architecture
---

# Runtime

The system's key flows.

## A smoke run in the test stage

A smoke run takes longer than one shell command may last, so the `test` stage's `smoke` suite doesn't wait for it in one call. `start` returns at once, and the session goes on in the background. `wait` blocks for at most `WAIT_SECONDS`, 540 seconds, and the suite runs it again while it exits 3. [Testing](../overview/testing.md) gives each command's output.

```mermaid
sequenceDiagram
  participant Suite as test stage, smoke suite
  participant Start as smoke.sh start
  participant Finish as smoke.sh _finish, in the background
  participant Session as claude -p, headless
  participant Watchdog as watchdog
  participant Run as run folder
  participant Wait as smoke.sh wait

  Suite->>Start: sh tests/smoke.sh start
  Start->>Run: prepare: copy the sample, write smoke.json and .gitignore, git init, one commit
  Start->>Run: request.md, and run.txt with plugin_dir, limit_minutes, allowed_tools, smoke_pid
  Start->>Finish: nohup
  Start-->>Suite: exit 0, last line run: <folder>
  Finish->>Session: /slice:new --config smoke.json <request>, in <run>/project
  Finish->>Watchdog: watch the session, limit LIMIT_MINUTES
  loop while wait exits 3
    Suite->>Wait: sh tests/smoke.sh wait <folder>
    Wait->>Run: is ended there? every 5 seconds, for at most 540 seconds
    Wait-->>Suite: running, exit 3
  end
  Session->>Run: session.jsonl and session.err, and the stages' work in the copy
  Session-->>Finish: exit status
  Finish->>Run: run.txt: ended, exit_code, time_limit_reached, interrupted, cost_usd, duration_ms
  Finish->>Run: the eight checks, saved as checks.txt
  Finish->>Run: ended, written last
  Suite->>Wait: sh tests/smoke.sh wait <folder>
  Wait->>Run: read checks.txt and ended
  Wait-->>Suite: the report, exit 0 or 1
  Suite->>Suite: one test for each PASS or FAIL line, the folder as the artifacts
```

- The foreground run, `sh tests/smoke.sh`, does the same work in one process: it runs the session part itself instead of starting `_finish`, and prints the report when the session ends.
- `start` and the foreground run refuse to start, with exit 2, when `~/.slicewright/smoke.json` exists, or when the run folder would be inside the repo.
- Before the session starts, the session part unsets some variables of the calling session, which `tests/smoke.sh` lists. A run from a stage's agent then doesn't inherit that session's effort or messaging socket.

## The time limit and an interrupt

- A watchdog checks the session every 5 seconds. At the limit, it writes `<run>/timed-out`, sends TERM, and sends KILL 30 seconds later if the session is still alive.
- The session part then records `time_limit_reached: yes`. Check 1 fails, and the report says that the time limit stopped the session.
- A foreground run that gets INT or TERM records `interrupted: yes`, and stops the session the same way: TERM now, and KILL 30 seconds later. It still evaluates the checks and prints the report.

## A background run that stopped without finishing

When `ended` is missing and the process recorded as `smoke_pid` is gone, the background part died before it finished.

1. `wait` says so, and evaluates the checks now.
2. It records the run as ended, as the session part does: it adds `cost_usd` and `duration_ms` to `run.txt`, each `unknown` when the session didn't report it, and saves the report as `checks.txt`.
3. It writes `ended` last, and exits as the report says: 0 when every check passed, 1 otherwise.

A later `wait` finds `ended`, prints the saved report, and exits the same way. A folder with no `smoke_pid`, such as one that only `prepare` made, gets the report and exit 1, and `wait` writes nothing in it.

## Evaluating the checks

- The eight checks run in order on the files the run left. Each prints one `PASS` or `FAIL` line.
- Checks 5 and 6 each run in a scratch copy of the project, made with `mktemp -d`. The same watchdog limits each to `CHECK_SECONDS`, 120 seconds. The scratch copy is removed afterwards. So the kept copy doesn't change, and the order of the checks doesn't matter.
- `sh tests/smoke.sh check <run folder>` evaluates the checks again on a kept run. It starts no session and writes nothing in the run folder.

## The static level and the self-test in a quality gate

The "build and tests" quality gates of `implement`, `review-fix` and `bug-fix` read the testing page, and run the two tests it names as needing no headless Claude run.

1. `sh tests/static.sh` runs its four checks on `plugins/slice`. Its only `claude` calls are the two local validations.
2. `sh tests/selftest.sh` makes one work folder with `mktemp -d`. For each case, it:
   1. makes a copy: of `plugins/slice` for a `static/…` case, or, for a `smoke/…` case, of the sample with the fixture laid on top, through `smoke.sh prepare`;
   2. breaks one thing in the copy, and checks that the break changed something, or reports the case as `MISSED`;
   3. runs `static.sh`, or `smoke.sh check`, on the copy;
   4. looks for the line that names what broke.

   It removes its work folder only when every case passes. Otherwise it keeps the folder and prints `kept: <folder>`.

Neither starts a Claude session, and each finishes within 60 seconds. The smoke test never runs in a quality gate or a task's Verify.
