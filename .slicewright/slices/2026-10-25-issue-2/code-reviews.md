# Code reviews

## Round 1, 2026-10-25T20:01:37Z

- Scope: the whole slice, revisions d96f1405dc683b296834ebc1376317b8b203b693 to 6d2e219a92502f0750be1656fa3c38f576dcc922, 33 files changed (31 committed, 2 staged documentation pages)
- Blast radius: 37 files
- Bar: slice/spec.md, slice/design.md, AGENTS.md (there is no CLAUDE.md, and doc/architecture/concepts.md doesn't exist); spec: every requirement, criterion, decision and contract delivered as written; code: the design rules and skill conventions in AGENTS.md; tests: each test asserts the behavior it names, changed behavior is tested, nothing weakened or needing a deployment; docs: every page the change touches, and README.md, match the code and defaults.json
- Reviewers: spec: findings · code: findings · tests: findings · docs: findings
- Open blocking: 3 · Advisory: 8

### Blocking

#### R1-F1 `wait` keeps no record when the background run stopped without finishing

- Severity: warning · Found by: spec, code
- Where: `tests/smoke.sh:789`
- Bar: R7 (each run, finished or stopped, keeps its cost and duration, or "unknown" for each, and the check results in its folder) and AC9; design Risks, "The detached run is killed with the shell call that started it", which relies on this branch
- Problem: when `ended` is missing and the process recorded as `smoke_pid` is gone, `cmd_wait` evaluates the checks and prints the report, but writes nothing. The run folder gets no `checks.txt` and no `ended`, and `run.txt` gets no `exit_code`, `cost_usd` or `duration_ms` line. So a run whose background part died keeps no check results and no cost or duration record, and every later `wait` evaluates the checks again.
- Proof: `sh tests/smoke.sh prepare tests/sample/project <scratch>/run`, then a `run.txt` with `plugin_dir`, `limit_minutes: 90` and `smoke_pid: 999999`, then `sh tests/smoke.sh wait <scratch>/run` → `ended: the background run stopped without finishing; checks evaluated now`, the report with `cost_usd: unknown` and `duration_ms: unknown`, exit 1; then `ls -A <scratch>/run` → only `project` and `run.txt`, and `run.txt` unchanged.
- Fix: in that branch of `cmd_wait`, do what `session_part` does after the session ends: record `cost_usd` and `duration_ms` from `load_result` (`unknown` when missing), write the report to `checks.txt`, write `1` to `ended`, then print `checks.txt` and exit 1. `check` stays write-free. Update the `wait` line under "Output lines" in `slice/docs/overview/testing.md`. · Blast radius: `tests/smoke.sh`, `slice/docs/overview/testing.md`; users of `wait`: `.slicewright/config.json` (the `smoke` entry's context), `tests/selftest.sh`
- Decision: fix

#### R1-F2 The acceptance check misses three outcomes the request states

- Severity: warning · Found by: tests
- Where: `tests/sample/accept.sh:55`
- Bar: R3 ("an acceptance check for that request") and R6.6; the outcomes are in `tests/sample/request.md:4-6`, and the design's description of the request includes `Ada --shout`
- Problem: `accept.sh` never runs `greet.sh Ada --shout` (must print `greet: too many arguments` and exit 2), `greet.sh --shout -x` (must print `greet: unknown option: -x` and exit 2) or `greet.sh --shout ''` (must print `HELLO, WORLD!`). A run whose `greet.sh` takes `--shout` in either position, or shouts a name that starts with `-`, passes check 6, so the smoke test would report a working feature that breaks the request.
- Proof: `sh tests/sample/accept.sh <folder>`, on a folder whose `greet.sh` takes `--shout` in either position and skips the unknown-option rule after it → `7 passed, 0 failed`; yet `sh <folder>/greet.sh Ada --shout` → `HELLO, ADA!`, and `sh <folder>/greet.sh --shout -x` → `HELLO, -X!`.
- Fix: add the three cases as `run` calls in `tests/sample/accept.sh`. The fixture's `greet.sh` already gives the expected output for all three (checked: exit 2 `greet: too many arguments`, exit 2 `greet: unknown option: -x`, and `HELLO, WORLD!`), so the self-test still passes. · Blast radius: `tests/sample/accept.sh`; its users: `tests/smoke.sh` (check 6), `tests/selftest.sh`, `tests/fixtures/finished-run/greet.sh`
- Decision: fix

#### R1-F3 The testing page has no measured cost or duration, and the criteria that need a real run are unproven

- Severity: warning · Found by: spec
- Where: `slice/docs/overview/testing.md:138`
- Bar: R9.1 ("what a run costs and how long it takes, as measured on the first passing smoke run") and AC12; AC5, AC8, AC11 and AC15, and AC9 in part, are unproven. Design D16 defers all of them, and says a review finding about them is settled by accepting it at review-decision, not by a fix task.
- Problem: "Cost and time" gives only the limits and where each run records its cost and duration. No smoke run happened in this slice, so there are no measured numbers. Nothing has shown the seven-stage run passing (AC5), the one-minute limit stopping a run (AC8), the test stage's suite (AC11), or check 2 on a real session (AC15).
- Proof: `grep -n -i -E "measured|first passing|\$[0-9]" slice/docs/overview/testing.md` → no output.
- Fix: no fix task in this slice (D16): accept it at review-decision with D16's reason. A follow-up slice runs `sh tests/smoke.sh` and `sh tests/smoke.sh --minutes 1`, runs the test stage's `smoke` suite, and adds the measured numbers to `doc/overview/testing.md`. · Blast radius: none in this slice; in the follow-up, `doc/overview/testing.md`
- Decision: accepted: no smoke run happens in this slice (D16, Q1: B); the measured numbers and the criteria that need a real run come with a follow-up slice

### Advisory

- **R1-F4** The smoke self-test cases can't show that a failing check 3 to 8 fails the command · warning · tests · outside the bar: R10 and AC7 are met as written, and R10 itself has checks 1 and 2 fail without a session; the gap is a future regression in the exit count going unnoticed (speculative): `tests/selftest.sh:303` checks 1 and 2 fail in every smoke case, so `smoke_exits_1` holds whatever the broken check does. Proven: a copy of the repo where `result()` in `tests/smoke.sh:266` counts only checks 1 and 2 still gives `selftest: passed, 14 cases`, exit 0. The reviewer's fix: give each smoke case a synthetic `run.txt` and `session.jsonl` so checks 1 and 2 pass, require each broken case to fail only its own check, and add a case where all eight pass.
- **R1-F5** Most static rules have no self-test case, and the testing page says each check is proven · suggestion · tests · outside the bar: R10 requires only the AC3 cases: `tests/selftest.sh:199` and `slice/docs/overview/testing.md:36` 14 rules (in `defaults.jq`: `activeSlicePath`, `sharedParams` skill, empty pipeline, missing name, `executionMode`, skill-or-context, `params` skill, `params` sets `activeSlicePath`, `onError`; in `skill.awk`: description, missing frontmatter; in `static.sh`: no `SKILL.md`, `validate`, not exactly one JSON value) can each be switched off with the self-test still passing, while the page says the self-test proves "that each check catches what it is meant to". The rules work today. Fix: add `static/…` cases, or reword the page to say the self-test proves the cases in its table.
- **R1-F6** Parts of smoke checks 1 to 5 have no failing case · suggestion · tests · outside the bar: AC7 lists only the five breaks covered: `tests/smoke.sh:297` check 3 ignoring frontmatter `status`, `next` or an extra row such as `review #2`, check 4 ignoring an empty record, check 5 always passing, check 1 ignoring `is_error` or `subtype`, and check 2 accepting any plugin or MCP server each survive the self-test. The logic is correct today. Fix: add `smoke/…` cases for them, listed on the testing page.
- **R1-F7** `start`, `wait`, the watchdog and `--minutes` have no test that runs without a model · suggestion · tests · outside the bar: no requirement asks for them, and D16 defers the criteria that need a real run: `tests/smoke.sh:688` the self-test calls only `prepare` and `check` (`grep -n "tests/smoke.sh" tests/selftest.sh` matches lines 278 and 297 and a comment), so `wait` on an ended run, `wait` with a dead `smoke_pid` (where R1-F1 is), exit 3 while running, bad `--minutes` values, and `prepare` into the repo are untested. Fix: add self-test cases on hand-made run folders; none starts a session.
- **R1-F8** The testing page says `--no-session-persistence` keeps out the developer's setup · suggestion · docs · outside the bar: the page and `tests/smoke.sh` pass the same flags; only the page's account of what one Claude Code flag does is wrong: `slice/docs/overview/testing.md:216` says the three flags exclude the developer's settings, plugins, skills, hooks and MCP servers, but `claude --help` says `--no-session-persistence` only keeps the session from being saved to disk. Fix: say that the first two flags exclude the developer's setup, and that `--no-session-persistence` keeps the run out of the saved sessions. · Decision: fix
- **R1-F9** The testing page says the calling session's variables are unset, but one stays set · suggestion · docs · outside the bar: the code unsets exactly design D7's list, and the page points to `tests/smoke.sh` for it: `slice/docs/overview/testing.md:217` a calling session also exports `CLAUDE_CODE_EXECPATH` (`printenv CLAUDE_CODE_EXECPATH` prints a path), and `tests/smoke.sh:639-641` doesn't unset it. Fix: word the page as "these variables of the calling session are unset", or add it to the `unset` lines and to D7. · Decision: fix
- **R1-F10** The README says review fixes go through review-fix-decision · suggestion · docs · outside the bar: README.md is out of the spec's scope, and the text predates this slice: `README.md:64` in the defaults, `review-fix` goes back to `review`, and reaches `review-fix-decision` only on an error. Fix in a later slice.
- **R1-F11** The README says implement works through the tasks one by one · suggestion · docs · outside the bar: README.md is out of the spec's scope, and the text predates this slice: `README.md:63` the default `maxParallel` is 0, no limit, and implement starts a wave's fork workers in parallel. Fix in a later slice.

### Blast radius

Changed:

- `.slicewright/config.json`
- `AGENTS.md`
- `tests/fixtures/finished-run/.slicewright/slices/index.md`
- `tests/fixtures/finished-run/doc/product/spec/greeting.md`
- `tests/fixtures/finished-run/greet.sh`
- `tests/fixtures/finished-run/slice/code-reviews.md`
- `tests/fixtures/finished-run/slice/design.md`
- `tests/fixtures/finished-run/slice/implement.md`
- `tests/fixtures/finished-run/slice/input.md`
- `tests/fixtures/finished-run/slice/plan.md`
- `tests/fixtures/finished-run/slice/spec.md`
- `tests/fixtures/finished-run/slice/status.md`
- `tests/sample/accept.sh`
- `tests/sample/project/AGENTS.md`
- `tests/sample/project/doc/index.md`
- `tests/sample/project/doc/overview/index.md`
- `tests/sample/project/doc/overview/product.md`
- `tests/sample/project/doc/product/index.md`
- `tests/sample/project/doc/product/spec/greeting.md`
- `tests/sample/project/doc/product/spec/index.md`
- `tests/sample/project/greet.sh`
- `tests/sample/project/test.sh`
- `tests/sample/request.md`
- `tests/selftest.sh`
- `tests/smoke.sh`
- `tests/smoke/allowed-tools`
- `tests/smoke/config.jq`
- `tests/smoke/pipeline.json`
- `tests/static.sh`
- `tests/static/defaults.jq`
- `tests/static/skill.awk`
- `slice/docs/overview/structure.md` (staged)
- `slice/docs/overview/testing.md` (staged, new)

Users of what changed:

- `plugins/slice/skills/test/SKILL.md`: runs the new `smoke` entry in `testAgents`
- `plugins/slice/skills/run/SKILL.md`: loads `.slicewright/config.json`
- `plugins/slice/skills/configure/SKILL.md`: proposes permissions for the `testAgents` commands
- `doc/overview/index.md`: lists the overview pages, where consolidate adds the testing page

## Round 2, 2026-10-25T20:46:24Z

- Scope: the fixes of round 1, revisions 6d2e219a92502f0750be1656fa3c38f576dcc922 to 350e8cf0ffd949246935a627daec7a604e744305, 3 files changed (2 committed, 1 staged documentation page)
- Blast radius: 10 files; round 1: 37
- Bar: slice/spec.md, slice/design.md, AGENTS.md (there is no CLAUDE.md, and doc/architecture/concepts.md doesn't exist); spec: every requirement, criterion, decision and contract delivered as written; code: the design rules and skill conventions in AGENTS.md; tests: each test asserts the behavior it names, changed behavior is tested, nothing weakened or needing a deployment; docs: every page the change touches, and README.md, match the code and defaults.json
- Reviewers: spec: findings · code: findings · tests: findings · docs: findings
- Open blocking: 3 · Advisory: 3

### Earlier fixes

- **R1-F1** `wait` keeps no record when the background run stopped without finishing: fixed. Its proof, run again, now leaves `checks.txt`, `ended` (`1`), `project` and `run.txt`, and `run.txt` ends with `cost_usd: unknown` and `duration_ms: unknown`.
- **R1-F2** The acceptance check misses three outcomes the request states: fixed. Its proof, run again on a `greet.sh` that takes `--shout` in either position and skips the unknown-option rule after it, now gives `7 passed, 3 failed`, with `not ok` for `greet.sh --shout ''`, `greet.sh Ada --shout` and `greet.sh --shout -x`.
- **R1-F8** The testing page says `--no-session-persistence` keeps out the developer's setup: fixed, not re-proven (advisory, no proof).
- **R1-F9** The testing page says the calling session's variables are unset, but one stays set: fixed, not re-proven (advisory, no proof). Its new wording has a gap of its own, R2-F4.

### Blocking

#### R2-F1 `wait` writes `1` to `ended` and exits 1 even when the report it saves passes

- Severity: suggestion · Found by: spec, code, docs
- Where: `tests/smoke.sh:806`
- Bar: the testing page, `slice/docs/overview/testing.md:86` ("0 or 1 once the run has ended, as its report says") and `:193` ("`<run>/ended` written last: 0 when every check passed, 1 otherwise"); the `smoke` entry's context in `.slicewright/config.json` ("Status 0 means every check passed, and 1 that a check failed"); design's `wait` row, "0 or 1 once ended, from the recorded result". The design's output line for this branch does say "exits 1".
- Problem: R1-F1's new branch always writes `1` to `ended` and exits 1. `session_part` records `exit_code`, `cost_usd` and the other keys before it runs the report, and no longer traps INT and TERM by then. If the background part dies while the report runs, `wait` evaluates all eight checks as passing and saves `result: passed` in `checks.txt`, but writes `1` to `ended`. This `wait` and every later one exit 1, which the test stage's suite reads as a failed check, and `ended` disagrees with `checks.txt`. The window is the time the report takes, up to a few minutes with checks 5 and 6.
- Proof: `sh tests/smoke.sh prepare <sample with the fixture on top> <scratch>/late`, then a `run.txt` as `session_part` leaves it before `ended` (`plugin_dir`, `limit_minutes: 90`, `smoke_pid: 999999` after `kill -0 999999` failed, `exit_code: 0`, `time_limit_reached: no`, `interrupted: no`, `cost_usd: 4.2`, `duration_ms: 3600000`) and a `session.jsonl` with an init event (only `slice`, at `plugins/slice`, no MCP server) and a `success` result event; then `sh tests/smoke.sh wait <scratch>/late` → `ended: the background run stopped without finishing; checks evaluated now`, `PASS 1 session` to `PASS 8 index`, `result: passed`, exit 1; and `cat <scratch>/late/ended` → `1`.
- Fix: in `cmd_wait`'s branch, keep the status of `report >"$RUN/checks.txt"`, 1 for any non-zero status as `session_part` does, write it to `ended` and exit with it; then change the `wait` bullet at `slice/docs/overview/testing.md:99` to say it exits as the report says. Or keep the code, and reword `testing.md:86` and `:193`, and the `smoke` context, to name this exception. · Blast radius: `tests/smoke.sh`, `slice/docs/overview/testing.md`, or `.slicewright/config.json` for the second option; users: `plugins/slice/skills/test/SKILL.md` (runs the `smoke` entry and reads `wait`'s status), `tests/selftest.sh`
- Decision: fix

#### R2-F2 The acceptance check misses the request's rule that only a to z become upper case

- Severity: warning · Found by: spec, tests
- Where: `tests/sample/accept.sh:63`
- Bar: R3 ("an acceptance check for that request") and R6.6; the outcome is in `tests/sample/request.md:7`: "Only the letters a to z become A to Z. Every other character stays as it is"
- Problem: the one case for this rule, `greet.sh --shout ada-lovelace_42`, has only ASCII characters, so it shows that `-`, `_` and digits stay, but not that other letters do. A `greet.sh` that uses `tr '[:lower:]' '[:upper:]'` passes all ten cases, yet under this machine's UTF-8 locale it turns `ë` into `Ë`. Check 6 would then report a working feature that breaks the request.
- Proof: a copy of `tests/fixtures/finished-run` whose `greet.sh` uses `tr '[:lower:]' '[:upper:]'`; `sh tests/sample/accept.sh <scratch>/locale` → `10 passed, 0 failed`; `sh <scratch>/locale/greet.sh --shout zoë` → `HELLO, ZOË!`; `sh tests/fixtures/finished-run/greet.sh --shout zoë` → `HELLO, ZOë!`.
- Fix: add a `run` case to `tests/sample/accept.sh` with a letter outside a to z, such as `--shout zoë` → `HELLO, ZOë!`, exit 0, built with `printf` octal escapes to keep the file ASCII, and run under a UTF-8 locale so that a locale-aware upper-caser can fail it. The fixture already passes it; the unchanged sample's count becomes `3 passed, 8 failed`. · Blast radius: `tests/sample/accept.sh`; its users: `tests/smoke.sh` (check 6), `tests/selftest.sh`, `tests/fixtures/finished-run/greet.sh`, `tests/sample/project/greet.sh` (AC4)
- Decision: fix

#### R2-F3 The acceptance check misses the request's "without the option, nothing changes"

- Severity: suggestion · Found by: tests, code, docs
- Where: `tests/sample/accept.sh:61`
- Bar: R3 ("an acceptance check for that request") and R6.6; the outcome is in `tests/sample/request.md:8`: "Without the option, nothing changes"
- Problem: without `--shout`, only `greet.sh Ada` and `greet.sh -x` are checked. No case runs `greet.sh` with no name, with an empty name, with `Ada Bob` or with `-x Ada`. Those are left to the copy's own `test.sh` (check 5), which the pipeline is asked to change, while R3 keeps the acceptance check out of its reach. A run that changes the default greeting passes check 6.
- Proof: a copy of `tests/fixtures/finished-run` whose `greet.sh` has `name=World` in place of `name=world`; `sh tests/sample/accept.sh <scratch>/noopt` → `10 passed, 0 failed`; `sh <scratch>/noopt/greet.sh` → `Hello, World!`, while `sh tests/sample/project/greet.sh` → `Hello, world!`.
- Fix: add `run` cases to `tests/sample/accept.sh` for `greet.sh` (`Hello, world!`, 0), `greet.sh ''` (`Hello, world!`, 0), `greet.sh Ada Bob` (`greet: too many arguments`, 2) and `greet.sh -x Ada` (`greet: unknown option: -x`, 2), with the expectations of `tests/sample/project/test.sh`. The sample and the fixture already pass all four, so AC4 and the self-test still hold. · Blast radius: `tests/sample/accept.sh`; its users: `tests/smoke.sh` (check 6), `tests/selftest.sh`, `tests/fixtures/finished-run/greet.sh`, `tests/sample/project/greet.sh` (AC4)
- Decision: fix

### Advisory

- **R2-F4** The testing page says every other variable is kept, but `CDPATH` is also unset · suggestion · code, docs · outside the bar, as R1-F9 was: the code unsets exactly design D7's list before it starts the session, and the bullet's point, that the sign-in stays, holds: `slice/docs/overview/testing.md:217` says "Every other variable is kept", but `tests/smoke.sh:14` runs `unset CDPATH` for the whole script, so the session doesn't get it either (`grep -n -E "^ *unset " tests/smoke.sh` → line 14, then 639 to 641). Fix: say "`CLAUDE_CONFIG_DIR` and `ANTHROPIC_*` are kept", or name `CDPATH` too.
- **R2-F5** The testing page suggests that a folder `prepare` made has a `run.txt` · suggestion · code · a preference in wording: what the sentence says `wait` prints and writes is right: `slice/docs/overview/testing.md:99` says "A folder whose `run.txt` has no `smoke_pid`, such as one that only `prepare` made", but `prepare` writes no `run.txt` (`sh tests/smoke.sh prepare tests/sample/project <scratch>/bare`, then `ls -A <scratch>/bare` → only `project`). Fix: say "A folder with no `smoke_pid` in its `run.txt`, or no `run.txt`, such as one that only `prepare` made".
- **R2-F6** R1-F1's change to `wait` has no test · suggestion · tests · outside the bar, as R1-F7 was, which named this same path and got no fix decision; no requirement asks for a `wait` test: `tests/smoke.sh:795-808` the new branch, and the write-free folder with no `smoke_pid`, are run by no test. The reviewer's proof: a copy of revision 350e8cf with `tests/smoke.sh` from 6d2e219 still gives `selftest: passed, 14 cases`. Fix: add two self-test cases that start no session, a prepared folder whose `run.txt` names a process that has already ended and one with no `smoke_pid`, and list them on the testing page.

### Blast radius

Changed:

- `tests/smoke.sh`
- `tests/sample/accept.sh`
- `slice/docs/overview/testing.md` (staged)

Users of what changed:

- `.slicewright/config.json`: the `smoke` entry runs `wait` and reads its exit status
- `tests/selftest.sh`: runs `smoke.sh prepare` and `smoke.sh check`, whose check 6 runs `accept.sh`
- `tests/fixtures/finished-run/greet.sh`: must pass the acceptance check
- `tests/sample/project/greet.sh`: must fail the acceptance check (AC4)
- `AGENTS.md`: names `sh tests/smoke.sh` and links the testing page
- `slice/docs/overview/structure.md` (staged): links the testing page
- `plugins/slice/skills/test/SKILL.md`: runs the `smoke` entry in `testAgents`

## Round 3, 2026-10-26T07:58:05Z

- Scope: the fixes of round 2, revisions 350e8cf0ffd949246935a627daec7a604e744305 to 35a8350514217f80283b4612e93d649e233469c0, 3 files changed (2 committed, 1 staged documentation page)
- Blast radius: 10 files; round 2: 10
- Bar: slice/spec.md, slice/design.md, AGENTS.md (there is no CLAUDE.md, and doc/architecture/concepts.md doesn't exist); spec: every requirement, criterion, decision and contract delivered as written; code: the design rules and skill conventions in AGENTS.md; tests: each test asserts the behavior it names, changed behavior is tested, nothing weakened or needing a deployment; docs: every page the change touches, and README.md, match the code and defaults.json
- Reviewers: spec: approved · code: approved · tests: findings · docs: approved
- Open blocking: 0 · Advisory: 1

### Earlier fixes

- **R2-F1** `wait` writes `1` to `ended` and exits 1 even when the report it saves passes: fixed. Its proof, run again on a prepared folder with the fixture on top, a `run.txt` with `smoke_pid: 999999` and the keys `session_part` records, and a `session.jsonl` with an init and a `success` result event, now gives the `ended:` line, `PASS 1 session` to `PASS 8 index`, `result: passed`, exit 0, and `cat <scratch>/late/ended` → `0`.
- **R2-F2** The acceptance check misses the request's rule that only a to z become upper case: fixed. Its proof, run again on a copy of the fixture whose `greet.sh` uses `tr '[:lower:]' '[:upper:]'`, now gives `14 passed, 1 failed`, with `not ok - greet.sh --shout zoë` (expected `HELLO, ZOë!`, got `HELLO, ZOË!`).
- **R2-F3** The acceptance check misses the request's "without the option, nothing changes": fixed. Its proof, run again on a copy of the fixture whose `greet.sh` has `name=World`, now gives `13 passed, 2 failed`, with `not ok` for `greet.sh` and `greet.sh ''`.

### Advisory

- **R3-F1** R2-F1's change to `wait` has no test · suggestion · tests · outside the bar, as R1-F7 and R2-F6 were, which named this same branch of `cmd_wait` and got no fix decision; no requirement asks for a `wait` test. Proven: a copy of revision 35a8350 with `tests/smoke.sh` and `tests/sample/accept.sh` from 350e8cf (so `wait` writes `1` to `ended` again) still gives `selftest: passed, 14 cases`, exit 0: `tests/smoke.sh:805-812` the status that `wait` writes to `ended` and exits with, now 0 when the saved report passes, is run by no test; `tests/selftest.sh` calls only `smoke.sh prepare` and `smoke.sh check` (lines 278 and 297). The reviewer's fix: add two self-test cases that start no session, on a folder `prepare` made from the sample with the fixture on top, with a `run.txt` whose `smoke_pid` has ended and a `session.jsonl` with an init and a `success` result event: one where `wait` must exit 0, write `0` to `ended` and save `result: passed` in `checks.txt`, and one with a broken check where it must exit 1 and write `1`; list them in the self-test table and case count of `slice/docs/overview/testing.md`.

### Blast radius

Changed:

- `tests/smoke.sh`
- `tests/sample/accept.sh`
- `slice/docs/overview/testing.md` (staged)

Users of what changed:

- `.slicewright/config.json`: the `smoke` entry runs `wait` and reads its exit status
- `tests/selftest.sh`: runs `smoke.sh prepare` and `smoke.sh check`, whose check 6 runs `accept.sh`
- `tests/fixtures/finished-run/greet.sh`: must pass the acceptance check, now `15 passed, 0 failed`
- `tests/sample/project/greet.sh`: must fail the acceptance check (AC4), now `7 passed, 8 failed`
- `AGENTS.md`: names `sh tests/smoke.sh` and links the testing page
- `slice/docs/overview/structure.md` (staged): links the testing page
- `plugins/slice/skills/test/SKILL.md`: runs the `smoke` entry in `testAgents`
