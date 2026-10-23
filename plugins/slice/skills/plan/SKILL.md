---
name: plan
description: Internal Slicewright plan stage. Coordinates task agents to break spec.md and design.md into tasks that separate workers can carry out in parallel, one file per task with the exact interfaces between them, plus a plan.md index with the waves, coverage and final check. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Plan

Break the design into tasks. Each task goes to a separate worker that reads only its own task file and the code, and workers run at the same time wherever the plan allows. So every task file must hold everything its worker needs, and the pieces must fit together when they are merged. You coordinate: you divide the work and fix the interfaces between the tasks, a task agent fills in each task from the code in its area, and review agents check the plan. Never write code here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `taskTypes`: the kinds of task the project's workers carry out, as an object mapping each type's name to an entry. It may be missing. Each entry has:
  - `description`: what work belongs to this type
  - `executionMode`: `fork` runs the type's agent as a subagent; `inline` means you take that role yourself
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: the expertise for this type: how this kind of work is done in the project
- `context`: the project's rules for this stage, which may be missing, such as how to divide the work and size tasks
- `reviewAgents`: the agents that review the plan. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you review yourself, following its context
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: its focus; empty means the general review
  - `name`: a label for the record, which may be missing

Ignore any other key. The contexts are rules for you and the agents to follow. Never copy them into a file.

Never ask the user anything.

## 1. Read the slice

- `<activeSlicePath>/spec.md`: what to build. If it doesn't exist, return `NO_SPEC`.
- `<activeSlicePath>/design.md`: how to build it. If it doesn't exist, return `NO_DESIGN`. It may still have open questions: plan for the recommended answer the design applies, and name the question in each task that depends on it. Follow the review notes in it that concern the plan.
- The project instructions (`CLAUDE.md`, `AGENTS.md`) and the code in the design's affected areas: enough to divide the work, to know which files and modules exist, and to find the commands that build and test each area. The task agents read the details.

## 2. Draft the skeleton

Divide the work and fix how the pieces connect. The skeleton holds what every task must agree on; the task agents fill in the rest.

1. **Divide by type.** With `taskTypes`, give each type the design touches one task, and split a type into more tasks only when its work is too big for one worker. Give every task exactly one type. When some work fits none of the types, return `NO_TASK_TYPE`, naming the work. Without `taskTypes`, divide by the design's affected areas, and leave the type out. Rules in the context on how to divide the work come first.
2. **One worker each.** A task must be something one worker can finish and verify in one session, with nothing else to read but its task file and the code. Don't make tasks so small that they only make sense together.
3. **Tests go with the code.** A task delivers the tests for its own changes. Only tests that exercise the output of several tasks together get a task of their own, which depends on those tasks.
4. **Interfaces.** Wherever one task's output meets another task's, fix the exact shape once: signatures, types, routes with their requests and responses, tables and columns, events, config keys, file locations. Take the shapes the design's contracts define. Each shape is provided by exactly one task, or by existing code. Choose new public names here, once.
5. **Depend on code, not on shapes.** A task depends on another only when it needs that task's code to build or to pass its Verify. When it needs only a shape, the shape is in its Interfaces, and it doesn't depend. When the build needs a shape as code, such as a shared type, an interface, a generated client or a new library in a shared dependency file, put that code in a small task of its own early on, so the larger tasks don't wait for each other.
6. **No shared files at the same time.** Tasks that may run at the same time never change the same file. A file that several tasks would change, such as a route table, a registration of services or a dependency file, belongs to one task; the others say in their Interfaces what they expect to find there.
7. **Full coverage, nothing extra.** Every requirement is covered by a task, and every acceptance criterion is proved by the Verify section of at least one task: a command or check that shows it holds. No task does work that the spec and design don't call for.

Then group the tasks into waves: wave 1 holds the tasks with no dependencies, and each later wave the tasks whose dependencies are all in earlier waves. Fewer waves are better.

For each task, the skeleton holds its id, title, type, dependencies, the requirements and criteria it covers, the open questions it depends on, its goal, the files it creates or changes, and its Interfaces.

## 3. Fill in the tasks

A task agent fills in each task: the agent of its type in `taskTypes`, or, for a task without a type, a `general-purpose` subagent with no expertise. Start every `fork` agent at once, in parallel, one per task, with your tool for starting subagents (Agent), using this prompt:

````text
You are filling in one task of an implementation plan. A separate worker will carry
the task out, reading only its task file and the code, while other workers carry
out the other tasks at the same time.
{the type's context; leave this line out when it is empty}

Spec and design: {paths}

Your task:
{the task's skeleton, with the text of the requirements and acceptance criteria it
covers and of the design decisions it follows}

The whole plan, so you know what the other tasks own:
{every task's id, title, files and Interfaces}

Read the code your task touches: the files, the classes and functions involved,
the patterns nearby, the existing tests, and the commands that build and test it.
Check external libraries and APIs against their documentation, not from memory.
You may run commands that only read, such as a tool's version or help, to confirm
the commands you name. Never change any file, never run a build or the tests, and
never ask the user anything. Keep to the Interfaces as written.

Answer with these sections:
Changes: each file to create or change, and in it each class, function or method
  to add or change, with its signature when other code or a test calls it, and
  what it must do. Name existing code exactly as it is in the code. Leave private
  details to the worker.
Verify: the exact commands that build and test the task's changes, and what each
  must show; for each acceptance criterion the task covers, the check that proves it.
Boundaries: the files and behavior the task must leave alone.
Conflicts: each place where the skeleton doesn't fit the code: an interface that
  can't be provided or used as written, a file that is missing or elsewhere, a
  dependency the task needs but doesn't have, or work that belongs to another task.
  Say what you would change. Write "none" when there are none.
````

Fill in the tasks of each `inline` type yourself, following its context, in the same sections. If a task agent fails, or answers without these sections, start it once more. If it fails again, fill in the task yourself, and say so in the result.

## 4. Integrate

Resolve each conflict the agents report. Check it against the code. When it holds, change the skeleton, whether an interface, a file or a dependency, and apply the change to every task it affects, including their Changes and Verify. When it doesn't hold, keep the skeleton as it is.

Note every choice you or the agents made that the spec and design leave open, such as an edge case's behavior or an extra file. They go under Plan decisions in plan.md, so the person who reviews the plan sees them.

Then check that the pieces fit, and fix the plan in place:

- a requirement no task covers, or an acceptance criterion no Verify section proves
- a Uses entry that no dependency's Provides and no existing code matches exactly: name, parameters, types, route, fields
- a shape that two tasks both provide
- an existing file, class or method a task names that isn't in the code
- a task a worker couldn't finish from its own file, because it relies on another task's file or on the spec or design without copying what it needs
- tasks in the same wave that change the same file
- a dependency missing, pointing forward, forming a cycle, or needing only a shape
- a task whose Verify section doesn't prove it's done
- a task for work the spec and design don't call for

## 5. Write the files

Replace any task files in `<activeSlicePath>/tasks/` from an earlier run: a new plan supersedes the old one. Write each file with the Write tool. If a write fails, return `WRITE_FAILED`.

Write one file per task, `<activeSlicePath>/tasks/T01-<short-kebab-title>.md`, numbering the tasks in wave order:

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

{Everything the worker needs from spec.md and design.md, copied in rather than referenced: the requirements and acceptance criteria it covers, and the decisions it must follow. Only what this task needs.}

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- `{signature, route, table, event or config key}`: {what it means} → used by {task ids}

**Uses:** what this task relies on, exactly as written, without changing it:

- `{signature, route, table, event or config key}`: from {`path` in the existing code | task id}

## Changes

- `{path}` ({new | changed})
  - `{class, function or method, with its signature when other code or a test calls it}`: {what it must do}

## Verify

- `{command}`: {what it must show}
- {AC id}: {the check that proves it}

## Boundaries

{The files and behavior this task must leave alone, because other tasks or later stages own them.}
```

Leave out Provides or Uses when it would be empty, and Interfaces when both are.

Then write `<activeSlicePath>/plan.md`, the index of the tasks:

```markdown
---
slice: {id from input.md; leave this line out when it has none}
tasks: {number of tasks}
waves: {number of waves}
---

# Plan: {feature name}

## Tasks

- [ ] [T01 {title}](tasks/T01-{slug}.md) · {type} · after: {task ids, or "none"} · covers: {ids}

## Waves

1. T01
2. T02, T03, T04
3. T05

## Final check

{The commands that prove the merged result of all tasks works, run after the last wave, and what each must show: the full build, the full test suite, and the checks for the acceptance criteria that span several tasks.}

- `{command}`: {what it must show}

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R1 | T01, T03 |
| AC1 | T01 |

## Plan decisions

- {a choice the spec and design leave open, and why} → {task ids}

## Assumed answers

- **Q1** {the answer the plan assumes} → affects {task ids}
```

Leave out Plan decisions when there are none, and Assumed answers when the design has no open questions.

## 6. Review

This step is required unless `reviewAgents` is an empty list, and checking the plan yourself doesn't replace it. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent). Give each the prompt below, with the full spec, the design, `plan.md` and every task file where it says `{SPEC}`, `{DESIGN}` and `{PLAN}`, and its context where it says `{FOCUS}`. Leave out the Focus line when its context is empty. Take the role of each `inline` entry yourself.

````text
You are reviewing an implementation plan. Each task will go to a separate worker
that reads only its own task file and the code, and tasks in the same wave run at
the same time. You haven't seen how the plan was produced, and that is the point:
judge only what is written. You may read the code to check what the tasks name.

Focus: {FOCUS}. Review with this focus first, and also report any other serious
problem you notice.

Spec:

{SPEC}

Design:

{DESIGN}

Plan and task files:

{PLAN}

Check:
- Coverage: a requirement no task covers, or an acceptance criterion no Verify
  section proves
- Integration: a Uses entry that doesn't match the Provides it relies on exactly,
  a name that differs between tasks, or pieces that would build alone but not
  together
- Accuracy: an existing file, class or method a task names wrongly
- Self-containment: a task a worker couldn't finish from its own file, because it
  relies on another task's file or on the spec or design without copying what it
  needs
- Conflicts: tasks in the same wave that change the same file
- Dependencies: a task that needs another's code without depending on it, a
  dependency that needs only a shape and makes a task wait for nothing, or a cycle
- Verification: a task whose Verify section doesn't prove it's done, or a final
  check that doesn't prove the merged result works
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

## 7. Record the review and return

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
message: <one sentence: the number of tasks and waves, any tasks that depend on open questions, and any task you had to fill in yourself>
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
