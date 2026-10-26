# Design reviews

## clarify, 2026-10-25T16:19:55Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [Requirements R4, R6]: the copy was committed before the test configuration was written into it. That left an uncommitted file, which fails check 6, the default intake's clean-sources check, and implement's DIRTY_TREE check → fixed: R4 now writes the configuration first, then makes one commit that holds all of the copy, the configuration included, with `slice/` ignored.
- Issue [Requirements R4.3, Constraints]: the headless run would load the developer's user-level plugins, hooks and MCP servers, which clashes with "no network beyond the model API" and with pass or fail reflecting the plugin → fixed: R4.4 says the session loads none of them and keeps only the developer's sign-in. New check R6.2 and AC15 verify it from the session's own report. Assumptions give the reason.
- Recommendation: R2.3 should say "every non-null `next` and `onError`" → applied
- Recommendation: a blocking question, or intake's check for the latest sources with no remote, can fail a gateless run with nothing broken; say whether overrides may cover these → applied: R4.2 allows overrides for contexts that wait for a person or need a remote, and Constraints say how the run avoids a blocking question
- Recommendation: a $10 ceiling may fail AC5 on budget alone → applied: Q5 now recommends $20 and 90 minutes until runs are measured, and R9.1 records the measured cost
- Recommendation: say what R7 records when the time limit kills the run → applied: cost and duration are recorded as unknown when the session didn't report them
- Recommendation: say whether AC3's and AC7's broken copies are fixtures or are made by hand → applied: new R10 self-test with a finished-run fixture, AC14, and AC13 names the self-test as a test with no headless run
- Recommendation: add `doc/overview/index.md` to the scope → applied: Scope says consolidate's `index` agent adds the page there
- Recommendation: verify that `claude -p` works from a stage agent's shell before design → applied: checked with a one-turn headless run that cost $0.01, and the assumption now says so
- Recommendation: say whether the four tools cover the sample's own program → applied: the sample is a POSIX shell program (Assumptions)
- Recommendation: weigh option C of Q1 (static level only) more seriously, since the unverified parts are on the smoke side → Q1: still recommends A, now that the nested run is shown to work, and names C as the fallback

## design, 2026-10-25T17:56:01Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [Approach, Affected areas]: nothing said when the testing page and the AGENTS.md section land. The quality gates between waves read them and run the tests they name, so docs in an early wave would make a gate run scripts that don't work yet, ending in CHECK_FAILED → fixed: new D17, under which the documentation and AGENTS.md tasks depend on the self-test task, which depends on the other scripts. The Approach and the coverage of R9 and AC13 point to it.
- Recommendation: check 2 leaving out built-in plugins reads AC15 and R6.2 narrowly; ask the person, and say so on the testing page → applied: Q2, recommending D9; D9 and testing.md section 8 say so
- Recommendation: say that only the person adds the measured numbers, that review-fix doesn't settle a finding about them, and that stopping works any time before consolidate → applied: D16 and Q1 option A
- Recommendation: the testAgents context should tell the agent to give `wait` the longest timeout, and to run it again if the shell tool stops it first → applied
- Recommendation: test.sh's unknown-option test must not use `--shout`, or the fixture fails check 5 → applied: it uses `-x`
- Recommendation: intake's override invites git commands the allow list lacks → applied: the override names git and the sample's AGENTS.md, and the allow list adds `git --version`, `git remote -v` and `git branch --show-current`
- Recommendation: `jq empty` passes an empty file and several JSON values → applied: `jq -e -s 'length == 1'`, with its own problem line
- Recommendation: guard the removal of the scratch copies for checks 5 and 6 → applied: D11 and Risks
- Recommendation: say what the last line is when a command exits 2 after the run folder exists → applied: every command whose run folder exists ends with `run: <folder>`

## plan, 2026-10-25T18:36:23Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [plan.md, Deployed checks]: the test stage passes every `## Deployed checks` entry to its suites. So the `smoke` suite would also get the two runs meant for a person, the foreground `sh tests/smoke.sh` and `--minutes 1`. It would run them past one shell call's 10-minute limit, and report the expected `--minutes 1` failure as a failed test, so AC11's result would no longer hold → fixed: Deployed checks now lists only the `smoke` suite, run as its context says. The two runs by hand, with their expected output for AC5, AC8, AC9 and AC15, moved to Q1 under Assumed answers. The Coverage table and T03 point there.
- Issue [plan.md, Plan decisions, permission rules]: `/slice:configure --permissions` writes `.claude/settings.json`, because it already allows `Skill(slice:run)`. This repo tracks that file and the spec puts it out of scope. An uncommitted change there fails implement's final clean-tree check and the Final check's AC1 step → fixed: the interim rules go by hand into `.claude/settings.local.json`, which is git-ignored, and the plan says not to run configure during the slice.
- Issue [T01, T04, T05 Verify]: three grep expectations can't hold as written. The `claude` pattern also matches the `.claude-plugin` paths in `static.sh` and `selftest.sh`. The case-name pattern also matches paths such as `tests/static/defaults.jq` on the testing page → fixed: T01 and T04 use `claude( |$)`, and T04 checks the `smoke.sh` calls with their own grep. T05 matches the case names in backticks on the page, and ignores path matches in `selftest.sh`.
- Note: the reviewer read the spec, the design, the plan and the task files from their files in the slice folder, rather than from text pasted into its prompt, because of their size.

## plan, 2026-10-25T20:17:10Z

Review skipped: no review agents configured

## plan, 2026-10-26T07:34:39Z

Review skipped: no review agents configured
