---
name: implement
description: Internal Slicewright implement stage. Carries out plan.md wave by wave, one worker per task using the task type's agent, verifies and commits every task itself, and runs the stage's quality gate agents before the first wave, between waves, and as a final gate after the last change. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Implement

Carry out the plan. Workers write the code; you check everything they claim, commit what holds, and stop when something doesn't. A task is done only when you have run its checks yourself and seen them pass, and the slice is done only when the final gate passes on its last commit.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `taskTypes`: the kinds of task, as an object mapping each type's name to an entry with `description`, `executionMode` (`fork` runs the type's agent as a subagent; `inline` means you do the task yourself), `skill` or `agent` (for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given) and `context` (the expertise for this type). It may be missing.
- `qualityGateAgents`: the gates that decide whether the project is workable, in the order they run. When missing, use one `general-purpose` gate that builds the project and runs its tests as the CI configuration and the project instructions describe. An empty list means no gate.
- `reviewAgents`: agents that review a task's change before it is committed. Missing or empty means no task review.
- `isolation`: `none`, the default, runs every worker in the project folder; `worktree` gives each worker its own copy of the code
- `maxParallel`: how many workers run at the same time; `0` or missing means no limit
- `fixRounds`: how many times you may send a failing check back for a fix before a person decides; missing means `0`
- `context`: the project's rules for this stage, such as how to commit, how to prepare a copy of the code, and how to remove one

Each agent entry in `qualityGateAgents` and `reviewAgents` has `executionMode` (`fork` runs it as a subagent; `inline` means you take that role yourself), `skill` or `agent` (for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given), `context` (what it checks, and for a reviewer which tasks it applies to, such as task types) and `name` (a label for the record, which may be missing).

Ignore any other key. The contexts are rules to follow. Never copy them into a file.

Never ask the user anything. When a person must decide, stop with an error that says what.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Give long commands, such as a release build or a full test run, the longest timeout your shell tool allows; if one still runs out of time, run it in the background and wait for it.

Subagents: start every subagent, whether worker, gate, reviewer or fixer, in the foreground, never in the background, so that its answer comes back to you in this same turn. A background subagent can't ask for any permission, and your turn would end before the work is done. Never end your turn while a subagent is running, and never wait with `sleep`.

Your own part: you coordinate and check. Never change the project's code yourself, however small the change, except in a task of an `inline` type: workers and fixers change code. Never run a `fork` gate's checks in its place: start the gate.

## 1. Read the slice and the project

1. `<activeSlicePath>/plan.md`: the tasks, their waves and the final check. If it doesn't exist, return `NO_PLAN`. A ticked task is done; the unticked ones are still to do.
2. `<activeSlicePath>/tasks/`: one file per task. Read the files of the unticked tasks.
3. `<activeSlicePath>/implement.md`, when it exists: the record of earlier runs.
4. **Version control.** Use what the context says; otherwise check for git with `git rev-parse --show-toplevel`. Note the current commit. Without version control, you make no commits and can't restore files, so say so in the record and the result.

With `isolation: worktree`, the copies come from your tool for starting subagents (Agent) with its worktree isolation: git worktrees, or whatever the project's `WorktreeCreate` hook makes. Without git and without such a hook, return `ISOLATION_SETUP`.

## 2. Running the quality gates

"Run the quality gates" means this, wherever the steps below say it. Run the gates one at a time, in list order, in the project folder, because builds in one folder can't always run at once. When a gate fails, don't run the ones after it. Start each `fork` gate with your tool for starting subagents (Agent), with this prompt, and take the role of each `inline` gate yourself, following the same prompt:

````text
You are a quality gate. Check that the project in this folder, as it is now, passes
what follows. Never change the project's source files; build output and caches are
fine. Never ask the user anything.

{the gate's context}

Find the exact commands in the CI configuration first, then in the project's
instructions. Run only commands that need nothing deployed and no external
environment. Run each command on its own from this folder: never use cd, and never
chain commands with &&, ;, pipes or loops. Give long commands the longest timeout
your shell tool allows.

End with this report and nothing after it:
Status: PASSED | FAILED | ENVIRONMENT
Commands: each command you ran, and whether it passed
Failures: for each failure, the command, the last lines of its output, and the files
  and tests involved; or none
Environment: what is missing, when a command failed because a tool, a runtime or a
  dependency is missing, or the permission rules denied it; or none
````

If a gate answers without the report, continue it once and ask only for the report. If it still has none, the gate failed with no report. The run passes when every gate reports `PASSED`. A gate that reports `ENVIRONMENT` makes you return `ENVIRONMENT`, saying what is missing.

## 3. Start from a clean background

1. **Leftovers.** An unticked task may have left changes behind, from an interrupted run or a failed one that a person may have finished by hand: changed files of its own in the project folder, or, with `worktree`, a kept copy that implement.md names. Run the task's Verify commands against them, in the copy when there is one. When they pass, the leftovers are the task's result: check them as in step 5 and commit them. Otherwise discard them: with version control, restore only that task's files and delete the new files it added; delete a kept copy as in step 6. Without version control, you can't discard: return `LEFTOVERS`, naming the task and its files.
2. **Clean tree.** With version control, any uncommitted change outside `<activeSlicePath>` that isn't a task's leftover means someone else's work is in the tree: return `DIRTY_TREE`, listing the files.
3. **Baseline**, only while no task of the plan is ticked. Run the quality gates. If one fails, return `BASELINE_FAILED` with its failures: the slice must start from a project that passes. Once a task is ticked, the tree holds the slice's own commits, so a failure is the slice's to fix: the wave checks and the final gate cover it.

Start this run's entry in implement.md, as in step 9. When every task is already ticked, go straight to step 8.

## 4. Run the waves

Take the waves from plan.md in order, and in each the unticked tasks. Before starting a wave, write its tasks in implement.md as started.

Start a worker for every task of the wave, in groups of at most `maxParallel`: the agent of the task's type in `taskTypes`, or, for a task without a type or a type without an entry, a `general-purpose` subagent. Start the `fork` workers of a group at once, in parallel, with your tool for starting subagents (Agent), using worktree isolation when `isolation` is `worktree`. Do the tasks of `inline` types yourself after the subagents of the wave have finished, one at a time, following the same rules. Give each worker this prompt:

````text
You are a worker carrying out one task of a feature slice. Other workers carry out
other tasks at the same time, {isolation none: in this same folder, on other files |
isolation worktree: in other copies of the code}.
{the type's context; leave this line out when it is empty}

Your task:

{the full content of the task file}

After your wave, these quality gates check the whole project, so write your change to
pass them:
{each gate's context, one per line; leave this part out when there are no gates}

Rules:
- Change only the files the task lists, and build its Interfaces exactly as written.
  If the task can't be done as written, for example because an interface doesn't fit
  the code or a file it relies on is missing, stop and report BLOCKED with what you
  found. Don't work around it.
- Write tests that need nothing deployed and no external environment.
- Never weaken, skip or delete a test, add suppressions, or loosen any tool's
  settings to make a check pass.
- Run every command in the Verify section and fix your code until each shows what it
  must. Run only this task's own tests: other tasks' files may be half-written.
- Edit files with your file tools. Run each command on its own from the folder you
  start in: never use cd, and never chain commands with &&, ;, pipes or loops, or the
  permission rules refuse them.
- If a command fails because the environment lacks a tool, a runtime or a dependency
  that you can't set up the way the project's instructions say, or because the
  permission rules deny a command the task needs, stop and report ENVIRONMENT,
  naming the command.
- Before you report, compare your change with the task: every interface as written,
  nothing outside its files, tests that assert the behavior.
- Don't commit. Never ask the user anything.

End with this report and nothing after it:
Status: DONE | BLOCKED | FAILED | ENVIRONMENT
Files: each file you created, changed or deleted, one per line, marked (new), (changed) or (deleted)
Verify: each command you ran, and the last lines of its output
Deviations: what you did differently from the task, and why; or none
Not verified: what the commands couldn't prove; or none
Reason: for any status but DONE, what stopped you
````

If a worker fails, or answers without the report, continue it once and ask only for the report. If it still has none, the task failed with no report.

## 5. Check each task

When every worker of the wave has finished, check each task that reports `DONE`, in its copy with `worktree`, or else in the project folder:

1. **Base**, for git worktrees only. The copy must start at the commit the project folder is on: compare `git -C <copy> rev-parse HEAD` with `git rev-parse HEAD`, run before the wave started. A copy that starts elsewhere misses the earlier waves: remove every copy of the wave and return `ISOLATION_SETUP`, saying that `worktree.baseRef` must be `"head"` in the Claude Code settings, which `/slice:configure` adds.
2. **Files.** List the files the task actually changed: with version control, from its status, which leaves out ignored files such as build output; without it, from the report. Every one must be a file the task lists. A lock file or other dependency file counts unless the task lists it. Files in `<activeSlicePath>` don't count.
3. **Verify.** Run every command in the task's Verify section yourself, and compare what each shows with what the task says it must show. The worker's report is not proof.
4. **Review**, when a review agent applies to the task. Start every review agent that applies at once, in parallel, with this prompt:

   ````text
   You are reviewing one task's change before it is committed. Each task of the plan
   goes to a separate worker, so judge the change only against its own task.

   Focus: {the entry's context; leave this line out when it is empty}

   The task:

   {the full content of the task file}

   The change: {the diff of the task's files, or their full content for new files}

   Check:
   - Interfaces: anything the task provides or uses that differs from what it says
   - Scope: a change outside the task's files, or work the task doesn't call for
   - Tests: a test that doesn't assert the behavior it names, or that needs something
     deployed; a test weakened, skipped or deleted; a suppression or a loosened setting
   - Correctness: a bug, a missed case the task names, an error that is swallowed
   - Conventions: code that ignores a pattern the task or the nearby code sets

   Flag only what would make the result wrong or break another task. Style is not an
   issue. Approve unless something serious is wrong.

   Answer in this form:
   Status: Approved | Issues found
   Issues:
   - [file] the issue, and why it matters
   ````

   Check each issue against the task and the code. When it holds, it is a failed check. When it doesn't, reject it and note why.

A failed check goes back to the worker: continue the same subagent with what failed and the output that shows it. If it can't be continued, then with `none` start the type's agent again with the task, its earlier report and what failed; with `worktree` the task fails. Each time counts as one fix round, and a task gets at most `fixRounds` of them. After the fix, check the task again from the start. When the rounds are used up, the task failed.

A task reported `BLOCKED` or `ENVIRONMENT` gets no fix rounds.

## 6. Bring the wave together

1. **Bring back** (`worktree` only). For each checked task, copy its changed files from its copy into the same paths in the project folder, and delete the files it deleted. Then remove the copy: for a git worktree, run `git worktree remove --force <path>` and `git branch -D <branch>`; for a copy made by the project's hook, do what the context says, or leave it and name it in the record. Keep the copy of a task that failed or was blocked, and record where it is.
2. **Wave check.** In the project folder, run every checked task's Verify commands again, then run the quality gates, except after the last wave, where the final gate of step 8 runs them. When something fails, fix it as in step 7, then run the whole wave check again from its start.
3. **Commit** each checked task: stage exactly its files by name, including deletions, never with `git add -A`, `git add .` or `git commit -a`, and commit them with the message `<task id> <title>`, unless the context gives another format. Never commit files in `<activeSlicePath>`. Without version control, skip this.
4. **Tick** each committed task in plan.md, and record the wave in implement.md.

When a task of the wave failed, was blocked, or hit the environment: still check, bring back and commit the tasks that passed, then stop. Skip the quality gates, because the failed task's work may be in the tree. Leave the failed task's files and copy as they are for a person, and return `TASK_BLOCKED`, `ENVIRONMENT` or `TASK_FAILED`, in that order of precedence.

## 7. Fix a failing check

A failing wave check or final gate is fixed by its cause:

- **Environment:** a command fails because a tool, runtime or dependency is missing. Don't fix it: return `ENVIRONMENT`.
- **Formatting and lint:** when the failing tool has its own fixer, such as a formatter's write mode, run it first.
- **One task's:** the failure is in files or tests that belong to one task. Reopen it: send the failure to that task's worker, or start its type's agent again with the task, its report and the failure.
- **Across tasks:** the failure is where tasks meet, such as one task's code calling another's. Start one `general-purpose` subagent with the failure and the files of every task involved. It may change only those files and must keep every interface as plan.md's tasks write it. If an interface must change, it reports `BLOCKED`, and you return `TASK_BLOCKED`.
- **Outside every task:** fixing it needs a file no task lists. Don't fix it: return `CHECK_FAILED`, naming the file and the failure, so a person decides.

Give every fixer the failure, the gates' contexts and the worker rules. Every fix follows the worker rules: never weaken, skip or delete a test, add suppressions, or loosen a tool's settings. When a fixer reports that a test is wrong rather than the code, don't change the test: stop with `CHECK_FAILED`, so a person decides.

After each fix, check the touched tasks as in step 5, then run the failing check again from its start, in full: the whole wave check, or the whole final gate. A check gets at most `fixRounds` rounds of fixes. When they are used up, return `CHECK_FAILED` with the failures and the fixes tried. A fix to a task that is already committed gets its own commit, `<task id> fix: <what>`.

## 8. Final gate

After the last wave is committed, the slice must pass one complete run on its final state:

1. With version control, check that nothing outside `<activeSlicePath>` is uncommitted.
2. Run every command in plan.md's Final check yourself, and compare what each shows with what plan.md says it must show.
3. Run the quality gates.

When anything fails, fix it as in step 7, commit the fixes, and start this step again from 1. A fix is never the last word: the slice is implemented only when one complete final gate run passes after the last change. Each attempt runs everything again, every Final check command and every gate, even those a fix couldn't have touched: never carry a result over from an earlier attempt, and record for each attempt only what it ran. Record the commit the passing attempt ran on.

## 9. The record

Keep `<activeSlicePath>/implement.md` with the Write or Edit tool, adding one entry per run and never changing earlier entries:

```markdown
# Implement

## Run {n}, {time}

- Isolation: {none | worktree}. Start commit: {commit, or "no version control"}
- Baseline: {passed | failed: each gate's failures}
- Leftovers: {none, or each task: kept as its result | discarded}

### Wave {n}

- Started: {task ids}
- **T01** {title}: {done | failed | blocked | environment}
  - Commit: {commit, or "not committed"}
  - Files: {files}
  - Verify: {each command: passed | failed}
  - Review: {each reviewer: approved | issue → fixed | rejected: why}
  - Fixes: {each round: what failed → what changed}
  - Deviations: {from the worker's report, or none}
  - Not verified: {from the worker's report, or none}
  - Copy kept at: {path; only for a failed or blocked task with worktree isolation}
- Wave check: {passed | failed: gate or command → cause → fix}

### Final gate

- Attempt {n}: {passed on commit <commit> | failed: gate or command → cause → fix, commit}
  - Final check: {each command: passed | failed}
  - {gate name}: {passed | failed}

### Outcome

{done, or why the run stopped and what a person must decide}
```

Leave out lines and sections that would be empty.

## 10. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the tasks done in how many waves, the fixes made, and the commit the final gate passed on>
files: <activeSlicePath>/implement.md, <activeSlicePath>/plan.md
```

On failure, end with this instead:

```text
result: error
code: <NO_PLAN | ISOLATION_SETUP | LEFTOVERS | DIRTY_TREE | BASELINE_FAILED | ENVIRONMENT | TASK_BLOCKED | TASK_FAILED | CHECK_FAILED | WRITE_FAILED>
message: <one sentence saying what is wrong, naming the tasks, gates or commands>
fix: <what the person should do, such as fixing the environment, finishing a task by hand, re-planning or re-designing>
files: <activeSlicePath>/implement.md, <activeSlicePath>/plan.md, or none
```
