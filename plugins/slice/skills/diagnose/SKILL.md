---
name: diagnose
description: Internal Slicewright bug analysis stage. Finds the root causes of the tests a person chose to fix, with the configured instruments run in priority order, such as test output, logs, traces or reproducing locally, and records each cause with its evidence and confidence in bug-analyses.md for the fix plan. It never fixes anything. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Diagnose

Find why the tests a person chose to fix fail. Instruments look for causes; you merge what they find, check it, and record the causes the fix plan works from. Never fix anything here: fixing is a later stage's job.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `knowledge`: the project's documentation, which may be missing: `sources`, each with a `name`, a `path` when it is a folder in the project or a `skill` that reaches it, and a `context` saying what is there and how to read it; and `publishTo`, the name of the source the slice's documentation changes go to
- `record`: the analysis record in `activeSlicePath`; `bug-analyses.md` when missing
- `tests`: the test record in `activeSlicePath`; `test-reports.md` when missing
- `instrumentAgents`: the instruments. When missing, use one read-only `general-purpose` instrument that reads the failed tests' output and artifacts and the code they exercise. When it is an empty list, return `skipped`. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you investigate yourself, following its context
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: what the instrument looks at and how, such as which logs to query or how to run the application locally
  - `name`: a label for the record, which may be missing
  - `priority`: a number; lower runs first, and instruments with the same number form one step. When missing, 1.
  - `readOnly`: `true`, the default, means it only reads: files, logs, traces, data. `false` means it may change code and run things on this machine, such as reproducing a failure or trying a change.
- `confidence`: the level at which a test's cause counts as found, so later steps no longer investigate that test: `low`, `medium`, `high` or `sure`; `high` when missing
- `isolation`: where instruments with `readOnly: false` work. `none`, the default, is the project folder, restored after each of them; `worktree` gives each its own copy of the code, from your tool for starting subagents (Agent) with its worktree isolation.
- `context`: the project's rules for this stage, which may be missing

Ignore any other key. The contexts are rules for you and the instruments to follow. Never copy them into a file.

The project's documentation: read each source in `knowledge.sources` as its `context` describes, and only the parts your work needs. When a source can't be reached, say so in your result, treat what you needed from it as an assumption, and go on. Pages this slice has already changed in the source that `knowledge.publishTo` names are staged in `<activeSlicePath>/docs/`, at their paths in that source: read a staged page instead of the published one, and a `<path>.delete` file there means that page is being removed. Every prompt you give an agent carries this line after its instructions, unless `knowledge` is missing: `The project's documentation: {each source: its name, its path or its skill, and its context} Pages this slice has changed are staged in {activeSlicePath}/docs/ at the same paths: read those instead of the published ones.`

Never ask the user anything, and never change any file except the record, apart from what instruments with `readOnly: false` change and you restore. Nobody changes the deployment in this stage: no deploying, restarting or reconfiguring it, and no changing its data except by running the project's tests against it.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Never change the shell's folder with `cd`. Start every subagent in the foreground, never in the background, and never end your turn while one is running.

## 1. Gather

1. **The tests to fix:** the latest run in `<activeSlicePath>/<tests>`, and in it every test whose decision is `fix`: a failed test's Decision line, or ` · Decision: fix` on a flaky or disabled test. Keep each test's id, name, file, output and the person's note after `fix: `. If there are none, return `NO_TESTS_TO_FIX`.
2. **The run:** its revision, window, deployment and each suite's artifacts.
3. **The deployment:** the latest entry in `<activeSlicePath>/deployments.md`, when it exists. When it is newer than the run, the deployment changed after the tests ran, and its logs and data may no longer match them: note that for the record.
4. **The bar**, what the code must meet: `<activeSlicePath>/spec.md`, `<activeSlicePath>/design.md`, and the project instructions (`CLAUDE.md`, `AGENTS.md`).
5. **Earlier rounds** in `<activeSlicePath>/<record>`, when it exists. The round number is one more than the last round, or 1. For each cause of the previous round decided `fix`, find its tests in the latest run: they pass now, or still fail.
6. **The current revision**, with the project's version control: the one the context or the project instructions name, or else the one the project folder uses, with its own commands.

## 2. Run the instruments

This step is required, and investigating yourself doesn't replace it. Your own part is to start the instruments, merge what they report, check their proofs and settle the tests; never investigate in an instrument's place, and never give a cause a level the instruments didn't show.

Every test starts open, and stays open until a cause that explains it reaches `confidence`. Run the steps in priority order, each with the tests still open. Before each step, if no test is open, the remaining steps are not needed: skip them. Never skip an instrument for any other reason than that it can't undo its changes, as below.

In a step, start every read-only `fork` instrument at once, in parallel, with your tool for starting subagents (Agent). Then run the step's instruments with `readOnly: false` one at a time, because they share this machine: its ports, local databases and containers. Each gets everything found so far, including the step's read-only results. Take the role of each `inline` entry yourself, at its place in that order.

An instrument with `readOnly: false` needs a way to undo what it changes:

- With `isolation: none`, the project folder must have no uncommitted changes before it starts; otherwise return `DIRTY_TREE`. Note the new files the version control lists before it starts. After it finishes, restore every changed file to the current revision with the version control's own commands, delete each new file it added, one by one, and check that the version control lists nothing changed and no new file beyond the ones noted. Never delete files the version control ignores, such as the slice's records, and never run a command that cleans the folder as a whole. Without version control, nothing can be undone: don't run it, and record why.
- With `isolation: worktree`, start it with worktree isolation and remove its copy when it is done. Without git and without a `WorktreeCreate` hook, don't run it, and record why.

Give each instrument this prompt, with only the open tests:

````text
You are investigating why tests of a feature slice fail, with one instrument. Find
the root causes; never fix anything for real.
{for an entry with a skill: Invoke the {skill} skill, and investigate with it.}

{the entry's context; when it is empty: Investigate with whatever this project
offers for the tests below.}

The tests to investigate:
{each open test: its id, name and file, its output, and the person's note, or "no note"}
A person's note is a lead to check, not evidence; but when it says what the right
behavior is, it is part of the bar for that test.

The test run: revision {revision}, from {start} to {end}. Artifacts: {each suite's
artifacts, or "none recorded"}.
The deployment: {target and endpoint, or "none recorded"}{, and a warning when it
changed after the run}.
The bar, which the code must meet: {the paths of spec.md, design.md and the project
instructions}.

Causes found so far, which may explain these tests too:
{each cause: its title, where, the tests it explains and its level; or "none"}
Hypotheses that disagree, to tell apart:
{for each test with causes that can't all be true: the causes, and what each claims;
or "none"}

{readOnly true: Never change any file, and only run commands that change nothing.
readOnly false: {isolation none: You work in the project folder, which is restored
to the current revision after you, | isolation worktree: You work in your own copy
of the code, which is removed after you,} so you may change code, add logging,
write tests and start the application on this machine. Stop everything you started
before you answer.}
Never change the deployment: don't deploy, restart or reconfigure it, and change its
data only by running the project's tests against it. Run each command on its own
from this folder: never use cd, and never chain commands with &&, ;, pipes or loops.
Never ask the user anything.

A root cause is where the wrong behavior starts, not where it shows: a crash site is
a cause only when the wrong behavior starts there. A test is wrong only when it
contradicts the bar: name the requirement, criterion, decision or contract it
contradicts. When the bar doesn't say what the right behavior is, report a gap in
the spec. For a flaky test, run it many times, alone and in a different order, and
compare the runs that pass with the runs that fail.

Report each cause in this form:
- Title: {short}
  Explains: {the test ids}
  Kind: code | configuration | test | environment | spec
  Where: {file:line, or the place outside the code}
  Chain: {how the cause leads to each failure}
  Level: low | medium | high | sure
    low: from reading the code
    medium: data from this instrument points at the cause, such as a log line or a trace
    high: you made the failure happen from the cause
    sure: a test fails because of the cause, and a change at the cause makes it pass
      while the other tests still pass
    An instrument that only reads reports at most medium: high and sure need an
    experiment.
  Evidence: {what you saw: the least output, log lines or trace that shows it}
  Proof: {a command that shows the cause and changes nothing, with its output; or
    the failing test you wrote, in full, with where it goes and its output; or none}
  Fix: {what removes the cause, and the files it changes. Never a change that only
    hides the failure, such as a retry, a longer timeout, an ignored error, a
    skipped test, a looser assertion or a special case for the test's data.}
For each test you couldn't explain: what you tried, and what data would explain it.

End with:
Status: Found | Partial | Nothing found
````

If an instrument fails, or answers without the form, start it once more. If it fails again, it didn't run.

After each step:

1. **Merge** causes that name the same problem in the same place, keeping the highest level, every instrument's evidence and the best Proof.
2. **Check** each Proof that is a command changing nothing: run it yourself, as written. A cause reported only by read-only instruments is at most `medium`, whatever they claimed: `high` and `sure` need an experiment. When its output doesn't show the cause, the cause drops to the level the rest of its evidence supports, at most `low`. A failing test written in a private copy can't be run here: the fix plan runs it first, before any change.
3. **Settle** the tests. A test's cause is found when a cause explaining it is at or above `confidence`, and no other cause of the test at the same or a higher level contradicts it. A contradicting cause at a lower level is rejected, with why. A test whose causes contradict each other at the same level stays open, with the causes as hypotheses to tell apart.

## 3. Decide what is fixed

After the last step, every cause that nothing contradicts is fixed, whatever its level: the level only decided how long the instruments kept looking, and the fix plan proves each cause again with a failing test first. Give each cause a decision:

- **`fix`**: a cause of kind `code` or `configuration`, and of kind `test` or `spec` when it names what in the bar makes the test wrong. A person's note that says what the right behavior is counts as part of the bar for its test.
- **`open`**, for a person, with why:
  - kind `spec`, or kind `test` without a part of the bar that makes the test wrong: the bar doesn't say what is right
  - kind `environment`: the cause is outside the project
  - causes of a test that still contradict each other after the last step

For each test that no cause explains, add a cause of kind `diagnostics`, decided `fix`: what data was missing, and where to capture it, such as logging at a place in the code. The fix adds that and nothing else, and the next test run collects the data.

For each cause decided `fix`, estimate the blast radius of its fix: the files its Fix changes, and the files that use what they change. The round's blast radius is all of them together.

## 4. Record the round

Append the round to `<activeSlicePath>/<record>`, creating the file with the heading `# Bug analyses` when it is missing. Write it with the Write or Edit tool, and never change earlier rounds:

```markdown
## Round {n}, {time}

- Tests: {the ids} from run {m} of {tests}{, with the notes}
- Deployment: {target and endpoint}{; changed after the run, so logs and data may not match}
- Instruments: {each instrument (priority {p}): ran | not needed: every test's cause was found | did not run: why}
- Causes: {count} · fix {count} · open {count} · diagnostics {count}
- Earlier fixes: {each cause of round {n-1} decided fix: its tests pass now | still fail}
- Fix blast radius: {count} files{; round {n-1}: {count}}

### Causes

#### B{n}-C1 {title}

- Explains: {test ids} · Kind: {kind} · Level: {level} · Found by: {instruments, with the step where the test's cause was found}
- Where: `{file}:{line}`
- Chain: {how it leads to each failure}
- Evidence: {for each instrument: what it showed}
- Proof: `{command}` → {output} | the failing test for `{file}`: {its full text} → {its output} | none
- Fix: {what removes the cause} · Blast radius: {the files}
- Decision: {fix | open: why a person is needed}

### Rejected

- **{title}** for {test ids}, from {instrument}: {why it was rejected}

### Blast radius

{the files the fixes change, then the files that use what they change}
```

Number the causes `B<round>-C1`, `B<round>-C2` and so on. Leave out sections that would be empty. A person may change a Decision line later, and the fix plan takes only the causes decided `fix`.

## 5. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: round n, the tests analyzed, the causes to fix and how many are diagnostics, the causes left open for a person, and the blast radius against the previous round's>
files: <activeSlicePath>/<record>
```

When `instrumentAgents` is an empty list:

```text
result: skipped
message: no instruments are configured
files: none
```

On failure, end with this instead. When no cause is decided `fix`, the round is still recorded, and the error is `NOTHING_TO_FIX`.

```text
result: error
code: <NO_TESTS_TO_FIX | NOTHING_TO_FIX | DIRTY_TREE | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <activeSlicePath>/<record>, or none
```
