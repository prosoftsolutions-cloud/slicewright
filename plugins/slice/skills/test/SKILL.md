---
name: test
description: Internal Slicewright test stage. Runs the configured test suites, such as end-to-end or integration tests against a deployment, and records the results for a person to decide on; failed, flaky and disabled tests go into the report. It doesn't analyze failures. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Test

Run the tests and report what happened. Never analyze, reproduce or fix a failure here: a later stage does that.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `record`: the test report in `activeSlicePath`; `test-reports.md` when missing
- `testAgents`: the suites, in the order they run. When missing, use one `general-purpose` suite that runs the project's tests that need a deployed environment, as the CI configuration and the project instructions describe. When it is an empty list, return `skipped`. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you run the suite yourself
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: what the suite runs and how
  - `name`: a label for the report, which may be missing
- `context`: the project's rules for this stage, which may be missing

Ignore any other key. The contexts are rules to follow. Never copy them into a file.

Never ask the user anything. Never change the project's source files; test output such as reports and screenshots is fine.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Start every subagent in the foreground, never in the background, and never end your turn while one is running.

## 1. Gather

- **The deployment:** the latest entry in `<activeSlicePath>/deployments.md`, when it exists, gives the target and the endpoint the suites run against.
- **The slice's deployed checks:** every Markdown file in `<activeSlicePath>` with a `## Deployed checks` section lists tests this slice wrote that need a deployment.
- **Earlier decisions:** the earlier runs in `<activeSlicePath>/<record>`, when it exists, and the decisions a person made on their failed tests.

## 2. Run the suites

Run the suites one at a time, in list order, because suites that share an environment can disturb each other. Start each `fork` suite with your tool for starting subagents (Agent), with this prompt. Run each `inline` suite yourself, following the same prompt.

````text
You are running one test suite of a feature slice and reporting its results. Don't
analyze, reproduce or fix any failure, and never change the project's source files;
test output such as reports and screenshots is fine. Never ask the user anything.
{for an entry with a skill: Invoke the {skill} skill, and run the suite with it.}

{the entry's context}

The deployment to test: {the target and endpoint from deployments.md, or "none
recorded"}
Tests this slice wrote that need a deployment; run those that belong to this suite:
{the list, or "none"}

Find the exact commands in the suite's instructions above, then in the CI
configuration, then in the project's instructions. Run each command on its own from
this folder: never use cd, and never chain commands with &&, ;, pipes or loops. Give
long commands the longest timeout your shell tool allows.

Run the whole suite. Run each test that fails once more on its own, unless the
suite's runner already retried it: a test that passes on the second run is flaky.

If the suite can't start, because its command or a tool is missing, the environment
doesn't answer, or no test runs at all, report NOT_STARTED and stop.

End with this report and nothing after it:
Status: RAN | NOT_STARTED
Commands: each command you ran
Counts: passed {n}, failed {n}, flaky {n}, disabled {n}
Failed: each failed test, with its name, its file and the last lines of its output; or none
Flaky: each flaky test, with its name and file; or none
Disabled: each skipped or disabled test, with its name, its file and the reason given; or none
Reason: for NOT_STARTED, what stopped the suite
````

If a suite answers without the report, continue it once and ask only for the report. If it still has none, the suite counts as not started, with no report. When a suite doesn't start, still run the ones after it, so the report is complete.

## 3. Record

Append the run to `<activeSlicePath>/<record>`, creating it with the heading `# Test reports` when it is missing, with the Write or Edit tool, and never change earlier runs. The run number is one more than the last one in the record, or 1.

```markdown
## Run {n}, {time}

- Revision: {the current revision of the project's version control, or "no version control"}
- Deployment: {the target and endpoint tested, or "none recorded"}
- Suites: {each suite: ran | not started: why}
- Totals: passed {n} · failed {n} · flaky {n} · disabled {n}

### {suite name}

- Commands: {each command}
- Passed {n} · Failed {n} · Flaky {n} · Disabled {n}

#### Failed

- **TR{n}-{k}** {test name} `{file}`: {the last lines of its output}
  - Decision: open

#### Flaky

- **TR{n}-{k}** {test name} `{file}`

#### Disabled

- **TR{n}-{k}** {test name} `{file}`: {the reason given, or "no reason given"}
```

Leave out sections that would be empty. Number the failed, flaky and disabled tests of the run `TR{n}-1`, `TR{n}-2` and so on, in the order they appear, so a person can name them.

A person writes the Decision lines later: `fix`, `accepted: <why>`, or `deferred: <why>, <owner>, <date>`. When a person accepted or deferred the same test, by name and file, in an earlier run, write that decision instead of `open`, followed by the id it was decided under, such as `accepted: <why> (TR1-2)`. Never carry a `fix` decision over: a test still failing after its fix is open again. A flaky or disabled test has no Decision line; when a person picks one to fix, ` · Decision: fix` is added to the end of its line.

## 4. Return

Failed, flaky and disabled tests are results, not errors: return `ok` with them in the report. Only a suite that didn't start is an error.

```text
result: ok
message: <one sentence: the suites run, the totals passed, failed, flaky and disabled, and how many failed tests are open for a decision>
files: <activeSlicePath>/<record>
```

When `testAgents` is an empty list:

```text
result: skipped
message: no test suites are configured
files: none
```

On failure, end with this instead:

```text
result: error
code: <SUITE_NOT_STARTED | WRITE_FAILED>
message: <one sentence: the suites that didn't start and why, and the totals of those that ran>
fix: <what the user should do, such as bringing the environment up or redeploying>
files: <activeSlicePath>/<record>, or none
```
