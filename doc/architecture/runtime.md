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

1. `sh tests/static.sh` runs its five checks: `validate`, `json`, `defaults` and `skills` on `plugins/slice`, and `configs` on every `.slicewright/<name>.json` of the repo except `*.local.json`, each merged onto `plugins/slice/defaults.json` and checked with the rules of `defaults`. Its only `claude` calls are the two local validations.
2. `sh tests/selftest.sh` makes one work folder with `mktemp -d`. For each case, it:
   1. makes a copy: of `plugins/slice` for most `static/…` cases; for `static/checker` and `static/configs`, of the parts of the repo the check reads, the manifests, the plugin, `static.sh` and `tests/static/`, and for `static/configs` also `.slicewright/research.json`; or, for a `smoke/…` case, of the sample with the fixture laid on top, through `smoke.sh prepare`;
   2. breaks one thing in the copy, and checks that the break changed something, or reports the case as `MISSED`;
   3. runs `static.sh`, the copy's own for the two cases that copy the repo's parts, or `smoke.sh check`, on the copy;
   4. looks for the line that names what broke.

   It removes its work folder only when every case passes. Otherwise it keeps the folder and prints `kept: <folder>`.

Neither starts a Claude session, and each finishes within 60 seconds. The smoke test never runs in a quality gate or a task's Verify.

## A slice with a named configuration

A project can keep more than one pipeline, one per `.slicewright/<name>.json`, and a slice remembers the one it runs with: `--config <name>` picks it, and `status.md` carries it to the next session. [Named configurations](../product/spec/named-configurations.md) gives the rules. The smoke run loads its test configuration this way, as `/slice:new --config smoke.json`, and this repo's research pipeline is started this way, as below.

```mermaid
sequenceDiagram
  participant Dev as the person
  participant Start as start-slice.sh
  participant Runner as runner, slice:run
  participant Tracking as slice:tracking
  participant Status as slice/status.md

  Dev->>Start: sh start-slice.sh --config research 17
  Start->>Start: master at origin/master, .slicewright/stable/ there, the stable plugin validates
  Start->>Start: .slicewright/research.json exists, or exit 1
  Start->>Runner: claude --plugin-dir .slicewright/stable/plugins/slice "/slice:new --config research 17"
  Runner->>Runner: load defaults.json, ~/.slicewright/research.json, .slicewright/research.json, .slicewright/research.local.json, and check the pipeline
  Runner->>Runner: intake, ok
  Runner->>Tracking: create ./slice intake config=research.json
  Tracking->>Status: config: research.json
  Note over Dev,Status: a later session
  alt /slice:resume, without --config
    Runner->>Runner: load config.json
    Runner->>Status: read config
    Runner->>Runner: load research.json instead, and say so
  else /slice:new <request>, without --config, and the person chooses Continue
    Runner->>Status: read config
    Runner->>Runner: load research.json, check it, say so, and say that the request is not used
  end
  Runner->>Runner: go on with the stage status.md names
```

- Without `--config`, the name is `config.json`, and nothing is recorded: `status.md` has a `config:` line only for another configuration.
- With `--config` given, on `/slice:resume` or on `/slice:new`, the given configuration is kept, whatever `status.md` records.
- With a name other than `config.json`, at least one of `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>` must exist, or the runner stops and names the three. `start-slice.sh` checks only the project's file, `.slicewright/<name>.json`, before Claude starts.
- **Start new** deletes the slice folder and starts the typed request with the configuration loaded, so `/slice:new` without `--config` then runs `config.json`.
- When the stage to go on with isn't in the loaded pipeline, because the configuration changed, the runner says so and stops.

## A research topic through the research pipeline

The research pipeline, `.slicewright/research.json`, has eight stages and two gates where a person decides. [Research pipeline](../product/spec/research-pipeline.md) gives each stage's context in full; this is the flow.

```mermaid
sequenceDiagram
  participant Dev as the person
  participant Runner as runner, with research.json
  participant Clarify as clarify
  participant Research as research
  participant Deploy as file-issues and release, slice:deploy
  participant Consolidate as consolidate
  participant GitHub

  Runner->>GitHub: intake: gh issue view, then the slice's branch
  Runner->>Clarify: the topic
  Clarify-->>Runner: spec.md: one question per requirement, what a good answer contains, the sources in and out
  Runner->>Dev: questions-review: approve the questions
  loop until accept or drop
    Runner->>Research: the questions, or the ones the review notes name
    Research-->>Runner: research.md: answers with evidence and confidence, conclusions, options, recommendation, follow-ups
    Runner->>Dev: results-review: the open questions, the recommendation's Decision, each follow-up's Decision
    alt more-research
      Dev-->>Runner: requests under Review notes, then research runs again
    else re-scope
      Dev-->>Runner: a Re-scope section in input.md, then clarify and questions-review run again
    else drop
      Dev-->>Runner: the run ends
    else accept
      Dev-->>Runner: every Decision line filled
    end
  end
  Runner->>Deploy: file-issues
  Deploy->>GitHub: gh issue list, gh issue create, gh issue view, for each follow-up marked file
  Deploy-->>Runner: deployments.md: the issue URLs, each with its follow-up's id
  Runner->>Consolidate: the research page, a decision record when one was taken, the indexes, the log, the records archive
  Runner->>Deploy: release
  Deploy->>GitHub: push the branch, gh pr create
```

- `research` has `onError: results-review`, so a failure, `NO_SPEC`, `SPEC_NOT_READY` or `WRITE_FAILED`, is put to the person. `accept` isn't open then, and a failure in the spec itself is fixed through `re-scope`, not `more-research`.
- `more-research` runs `research` again. The person's requests are lines under `## Review notes`; the stage reworks what they name, keeps the rest of the document, and removes the notes.
- `re-scope` runs `clarify` again, with a `## Re-scope` section appended to `input.md`, then `questions-review`. The next research run matches questions by their text, so renumbering loses nothing.
- `drop` ends the run: its choice maps to no stage.
- `file-issues` runs before `consolidate`, so that the research page carries the issue links from `deployments.md`.
- `consolidate`'s three knowledge agents run in order: `research` stages `architecture/research/<name>.md`, and updates it under the same name on a later consolidation; `adr` stages a decision record when the recommendation's `Decision:` is filled and doesn't start with `none`, and links the staged page; `index` updates the indexes, lists a new folder under Contents in its parent's `index.md`, and adds the entry to `log.md`.
