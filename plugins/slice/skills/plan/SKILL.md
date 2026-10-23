---
name: plan
description: Internal Slicewright plan stage. Breaks spec.md and design.md into tasks, one file per task for one worker each, plus a plan.md index with the order, dependencies and coverage. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Plan

Break the design into tasks. Each task goes to a separate worker that reads only its own task file and the code, so every task file must hold everything its worker needs. Never write code here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `taskTypes`: the kinds of task the project's implement stage can carry out, as an object mapping each type's name to what it covers. It may be missing.
- `context`: the project's rules for this stage, which may be missing, such as how to build and test, and how to size tasks
- `reviewAgents`: the agents that review the plan. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you review yourself, following its context
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: its focus; empty means the general review
  - `name`: a label for the record, which may be missing

Ignore any other key. The context is rules for you to follow. Never copy it into a file.

Never ask the user anything.

## 1. Read the slice

- `<activeSlicePath>/spec.md`: what to build. If it doesn't exist, return `NO_SPEC`.
- `<activeSlicePath>/design.md`: how to build it. If it doesn't exist, return `NO_DESIGN`. It may still have open questions: plan for the recommended answer the design applies, and name the question in each task that depends on it. Follow the review notes in it that concern the plan.
- The project instructions (`CLAUDE.md`, `AGENTS.md`) and the code in the design's affected areas, enough to name exact files, existing tests, and the commands that build and test them.

## 2. Break the work into tasks

1. **One worker each.** A task must be something one worker can finish and verify in one session, with nothing else to read but its task file and the code. Don't make tasks so small that they only make sense together.
2. **One type each.** With `taskTypes`, give every task exactly one of those types. When some work fits none of them, return `NO_TASK_TYPE`, naming the work. Without `taskTypes`, leave the type out.
3. **Tests go with the code.** A task delivers the tests for its own changes. Never collect tests in a later task.
4. **Order by dependency.** A task depends on every task whose output it needs. No cycles.
5. **Safe in parallel.** Tasks with no dependency between them may run at the same time, so they must not change the same file. When several tasks build on a shared shape, such as an interface, a schema or a contract from the design, put that shape in its own earlier task, so the others can run in parallel against it.
6. **Full coverage, nothing extra.** Every requirement and acceptance criterion in the spec is covered by at least one task. No task does work that the spec and design don't call for.

## 3. Write the files

Replace any task files in `<activeSlicePath>/tasks/` from an earlier run: a new plan supersedes the old one. Write each file with the Write tool. If a write fails, return `WRITE_FAILED`.

Write one file per task, `<activeSlicePath>/tasks/T01-<short-kebab-title>.md`, numbering the tasks in order:

```markdown
---
id: T01
title: {short title}
type: {one of taskTypes; leave this line out without taskTypes}
depends: [{task ids, or empty}]
covers: [{requirement and acceptance criterion ids, such as R1, AC2}]
questions: [{open questions in design.md this task depends on; leave this line out when none}]
---

# T01 {title}

## Goal

{What this task delivers, in one or two sentences.}

## Context

{Everything the worker needs from spec.md and design.md, copied in rather than referenced: the requirements and acceptance criteria it covers, the decisions it must follow, the contracts it implements or uses. Only what this task needs.}

## Changes

- `{path}`: {what changes there}

## Verify

- {a command or check that proves the task is done, and what it must show}

## Boundaries

{The files and behavior this task must leave alone, because other tasks or later stages own them.}
```

Then write `<activeSlicePath>/plan.md`, the index of the tasks:

```markdown
---
slice: {id from input.md; leave this line out when it has none}
tasks: {number of tasks}
---

# Plan: {feature name}

## Tasks

- [ ] [T01 {title}](tasks/T01-{slug}.md) · {type} · after: {task ids, or "none"} · covers: {ids}

## Order

{The waves that can run in parallel, in order. Example: 1. T01 · 2. T02, T03 · 3. T04}

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R1 | T01, T03 |
| AC1 | T01 |

## Assumed answers

- **Q1** {the answer the plan assumes} → affects {task ids}
```

Leave out Assumed answers when the design has no open questions.

Then check the plan and fix it in place:

- a requirement or acceptance criterion that no task covers
- a task a worker couldn't finish from its own file, because it relies on another task's file or on the spec or design without copying what it needs
- tasks in the same wave that change the same file
- a dependency missing, pointing forward, or forming a cycle
- a task whose Verify section doesn't prove it's done
- a task for work the spec and design don't call for

## 4. Review

This step is required unless `reviewAgents` is an empty list, and checking the plan yourself doesn't replace it. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent). Give each the prompt below, with the full spec, the design, `plan.md` and every task file where it says `{SPEC}`, `{DESIGN}` and `{PLAN}`, and its context where it says `{FOCUS}`. Leave out the Focus line when its context is empty. Take the role of each `inline` entry yourself.

````text
You are reviewing an implementation plan. Each task will go to a separate worker
that reads only its own task file and the code. You haven't seen how the plan was
produced, and that is the point: judge only what is written.

Focus: {FOCUS}. Review with this focus first, and also report any other serious
problem you notice.

Spec:

{SPEC}

Design:

{DESIGN}

Plan and task files:

{PLAN}

Check:
- Coverage: a requirement or acceptance criterion no task covers
- Self-containment: a task a worker couldn't finish from its own file, because it
  relies on another task's file or on the spec or design without copying what it
  needs
- Conflicts: tasks that can run at the same time but change the same file
- Dependencies: a task that needs another's output without depending on it, or a
  cycle
- Verification: a task whose Verify section doesn't prove it's done
- Scope: a task for work the spec and design don't call for
- Size: a task too big for one worker session, or tasks so small they only make
  sense together

Flag only what would make a worker fail or the result wrong. Wording and style are
not issues. Approve unless something serious is missing.

Answer in this form:
Status: Approved | Issues found
Issues:
- [task or section] the issue, and why a worker would fail or the result be wrong
````

Then handle what the reviewers report:

- **Issues:** check each one against the spec, the design, the code and the files. When it holds, fix the files. When it doesn't, leave them as they are and note why. Never apply an issue without checking it, and never drop one without a reason.
- **Contradictions:** when reviewers disagree, decide with a reason.
- **Failures:** if a review agent fails, or answers without the form, start it once more. If it fails again, its review didn't run.

Only when you have no tool for starting subagents, check the plan against the same list yourself, and record that the reviews didn't run.

## 5. Record the review and return

Append the review record to `<activeSlicePath>/design-reviews.md`, creating it with the heading `# Design reviews` when it is missing. Run `date -u +%Y-%m-%dT%H:%M:%SZ` as a command on its own for the time, then write the file with the Write or Edit tool, not a shell command:

```markdown
## plan, {time}

### {the reviewer's name, or else "Reviewer <n>" with its skill or agent}

- Status: {Approved | Issues found | Did not run: <why>}
- Issue [{task or section}]: {the issue} → {fixed: how | rejected: why}
```

When the review was skipped because `reviewAgents` is an empty list, write `Review skipped: no review agents configured` under the heading instead.

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the number of tasks and waves, and any tasks that depend on open questions>
files: <activeSlicePath>/plan.md, <activeSlicePath>/tasks/, <activeSlicePath>/design-reviews.md
```

On failure, end with this instead:

```text
result: error
code: <NO_SPEC | NO_DESIGN | NO_TASK_TYPE | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
