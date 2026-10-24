---
name: review
description: Internal Slicewright review stage. Starts the configured review agents on the slice's code, keeps only findings proven by a command, records a review round with its blast radius in code-reviews.md for a person to decide on, and in later rounds reviews only the fixes and their blast radius. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Review

Review the slice's code before it moves on. Review agents look for problems; you keep the ones that hold, measure how far the changes reach, and record a round that a person decides on. Never change the project's code here: fixing is a later stage's job.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `record`: the review record in `activeSlicePath`; `code-reviews.md` when missing
- `reviewAgents`: the agents that review the code. When missing, use one general-purpose reviewer. When it is an empty list, skip the review. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you review yourself, following its context
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: its review instructions: what to look for and how, and the standard it checks against, such as security rules or a performance budget, which then counts as its part of the bar. When empty, the reviewer looks for anything that breaks the bar.
  - `name`: a label for the record, which may be missing
- `context`: the project's rules for this stage, which may be missing, such as which rules files the code must meet

Ignore any other key. The contexts are rules for you and the agents to follow. Never copy them into a file.

Never ask the user anything, and never change any file except the record.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Start every subagent in the foreground, never in the background, and never end your turn while one is running.

## 1. Read the slice

1. **The bar**, what the code must meet: `<activeSlicePath>/spec.md` (requirements and acceptance criteria), `<activeSlicePath>/design.md` (decisions and contracts), the project instructions (`CLAUDE.md`, `AGENTS.md`) and the rules files the context names. A reviewer whose context names a standard adds it to the bar for its own findings. Only a finding that breaks the bar can block. The bar never grows from round to round: a later round judges against the same files and standards.
2. `<activeSlicePath>/implement.md`: what was implemented and from which revision. If it doesn't exist, return `NOTHING_TO_REVIEW`.
3. `<activeSlicePath>/<record>`, when it exists: the earlier rounds, the decisions a person made on their findings, and the revision each round reviewed up to.

The round number is one more than the last round in the record, or 1.

## 2. Find the scope

- **Round 1** reviews the whole slice: from the start revision of implement.md's first run to the current revision.
- **A later round** reviews only what changed since the previous round: from the revision the previous round reviewed up to, to the current revision. If nothing changed, the scope is empty: skip to step 4, then record the round.

Use the project's version control, the one the context or the project instructions name, or else the one the project folder uses, with its own commands. List the files changed between the two revisions. Without version control, take the files that implement.md lists for the runs in the scope.

**Blast radius.** For every changed file, find what it provides that other code uses: functions, classes, routes, tables, config keys. Search the code for their users. The blast radius is the changed files, the files that use what changed, and the tests of both. Its size is the number of files in it. A later round reviews the whole blast radius, not only the changed files, because a fix can break what calls it.

## 3. Run the review agents

This step is required unless `reviewAgents` is an empty list or the scope is empty. Start every `fork` review agent at once, in parallel, with your tool for starting subagents (Agent), with this prompt. Take the role of each `inline` entry yourself. The prompt carries only what this stage relies on: the scope, the earlier decisions, the rules and the answer form. What to review comes from each entry's context, or from its skill.

````text
You are reviewing the code of one feature slice. You haven't seen how it was
produced: judge only the code.
{for an entry with a skill: Invoke the {skill} skill, and review with it.}

{the entry's context; when it is empty: Review the change for anything that
breaks the bar.}

The bar, which the code must meet: {the paths of spec.md, design.md, the project
instructions and the rules files}, and any standard your instructions name. Read
them first. A finding that breaks none of them can't block.

The scope: {round 1: the whole slice | a later round: the fixes of the previous
round, and the code that uses what they changed}. Revisions {from} to {to}.
Changed files: {list}
Files in the blast radius: {list}
Read each change with the project's version control, comparing those two revisions;
without version control, read the changed files whole.

Already decided, never report again:
{each earlier finding that a person accepted or deferred, or that is being fixed,
with its id and title; or "none"}

Never change any file, not even for a moment: other reviewers read the same files
at the same time. You may run commands that change nothing, such as the tests or a
one-line call into the code, to prove a defect. Run each command on its own from
this folder: never use cd, and never chain commands with &&, ;, pipes or loops.
Never ask the user anything.

Report each finding in this form, and nothing about what is fine:
- Title: {short}
  Where: {file:line}
  Bar: {the requirement, criterion, decision, contract, rule or standard it
    breaks, or none}
  Severity: critical | warning | suggestion
  Problem: {what is wrong in this code now}
  Proof: {the command you ran and the output that shows the defect, or none}
  Fix: {what would fix it, and the files that changes}

End with:
Status: Approved | Findings
````

If a review agent fails, or answers without the form, start it once more. If it fails again, its review didn't run.

## 4. Check the earlier fixes

In a later round, take every finding of the previous round that a person decided to fix, and run its Proof command again yourself. When it no longer shows the defect, the finding is fixed. When it still does, the finding stays open: carry it into this round as blocking, under its own id. A finding without a Proof, such as an advisory one a person picked, is recorded as fixed but not re-proven, unless a reviewer of this round reports it again.

## 5. Grade the findings

Merge findings that name the same problem in the same place, keeping the higher severity and every reviewer's name. Drop any finding that is already decided. Number the rest `R<round>-F1`, `R<round>-F2` and so on.

Then grade each one:

- **Blocking**: it breaks the bar, the shared one or the standard the reporting reviewer's context names, and it is proven. Run its Proof command yourself, as written. It is proven only when the output shows the defect. Never decide a finding by reasoning about it instead of running its proof, and never ask another agent to judge it.
- **Advisory**: everything else, with the reason: no proof, the proof didn't show the defect, outside the bar, about a future that doesn't exist yet (speculative), or a preference in architecture, type design or style. An advisory finding is recorded in full, needs no decision, and is fixed only when a person picks it.

For each blocking finding, estimate the blast radius of its fix: the files its Fix changes, and the files that use what they change.

## 6. Record the round

Append the round to `<activeSlicePath>/<record>`, creating the file with the heading `# Code reviews` when it is missing. Write it with the Write or Edit tool, and never change earlier rounds:

```markdown
## Round {n}, {time}

- Scope: {the whole slice | the fixes of round {n-1}}, revisions {from} to {to}, {count} files changed
- Blast radius: {count} files{; round {n-1}: {count}}
- Bar: {the files of the bar}{; for each reviewer that names a standard: <reviewer>: <standard>}
- Reviewers: {each reviewer: approved | findings | did not run: why}
- Open blocking: {count} · Advisory: {count}

### Earlier fixes

- **R{n-1}-F1** {title}: {fixed | still open, carried as blocking}

### Blocking

#### R{n}-F1 {title}

- Severity: {critical | warning} · Found by: {reviewers}
- Where: `{file}:{line}`
- Bar: {what it breaks}
- Problem: {what is wrong}
- Proof: `{command}` → {the output that shows it}
- Fix: {the suggested fix} · Blast radius: {the files}
- Decision: open

### Advisory

- **R{n}-F4** {title} · {severity} · {reviewers} · {why advisory}: `{file}:{line}` {the problem}

### Blast radius

{the changed files, then the files that use what changed}
```

Leave out sections that would be empty. A person writes the Decision lines later: `fix`, `accepted: <why>`, or `deferred: <why>, <owner>, <date>`. An advisory finding has no Decision line; when a person picks one to fix, ` · Decision: fix` is added to the end of its line. When `reviewAgents` is an empty list, write the round with `Review skipped: no review agents configured` instead of the reviewers, and return `skipped`.

## 7. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: round n, the open blocking findings and how many are critical, the advisory findings, and the blast radius against the previous round's>
files: <activeSlicePath>/<record>
```

When the review was skipped:

```text
result: skipped
message: <why>
files: <activeSlicePath>/<record>
```

On failure, end with this instead:

```text
result: error
code: <NOTHING_TO_REVIEW | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
