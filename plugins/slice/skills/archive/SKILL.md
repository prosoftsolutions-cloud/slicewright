---
name: archive
description: Internal Slicewright archive stage. Brings what a finished slice changed and learned into the project's documentation with the configured knowledge agents, such as the living spec, decision records, known issues and lessons, copies the slice's records to the archive folder, and commits both. Running it again updates what it wrote before. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Archive

Close the slice: bring what it changed and learned into the project's documentation, and keep its records. Never change the project's code or tests here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `docPath`: the project's documentation folder
- `archivePath`: the folder that keeps finished slices' records. Each slice gets its own folder in it, `<archivePath>/<date>-<name>`. When it is missing or empty, records aren't kept.
- `knowledgeAgents`: the agents that update the documentation, in the order they run. When missing, use one `general-purpose` agent that updates the documentation with what the slice changed and learned. When it is an empty list, the documentation isn't updated. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you do its work yourself
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: which documents it writes and what goes into them
  - `name`: a label for the result, which may be missing
- `context`: the project's rules for this stage, which may be missing

Ignore any other key. The contexts are rules for you and the agents to follow. Never copy them into a file.

Never ask the user anything. Never change the project's code, tests or the slice's records.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Never change the shell's folder with `cd`. Start every subagent in the foreground, never in the background, and never end your turn while one is running.

## 1. Read the slice

Read `<activeSlicePath>/status.md`. If it doesn't exist, return `NO_SLICE`. Take the slice's title, its id when it has one, and the date part of `created`.

The slice's archive folder is `<archivePath>/<that date>-<name>`, where the name is the id, or else the title in lowercase words joined with `-`. It depends only on the slice, so archiving the same slice again uses the same folder. When that folder exists, this slice was archived before.

List the files in `<activeSlicePath>`, including those in its subfolders.

## 2. Update the documentation

Run the knowledge agents one at a time, in list order, because documents link to each other and share indexes. Start each `fork` agent with your tool for starting subagents (Agent), with this prompt. Do the work of each `inline` entry yourself, following the same prompt.

````text
You are bringing what one finished feature slice changed and learned into the
project's documentation.
{for an entry with a skill: Invoke the {skill} skill, and write with it.}

{the entry's context; when it is empty: Update the project's documentation with what
this slice changed and learned.}

The slice's records, in {activeSlicePath}: {the files}. Read the ones your
instructions need.
The documentation folder: {docPath}. Follow the project's documentation rules and the
structure already there. When a document you need doesn't exist yet, create it in the
same style.
{archived before: This slice was archived before, so your earlier changes are already
there: update them instead of adding them again. | otherwise: This slice wasn't
archived before.}

Write only the documents your instructions are about, and only in {docPath}. Never
change code, tests or the slice's records. Run each command on its own from this
folder: never use cd, and never chain commands with &&, ;, pipes or loops. Never ask
the user anything.

End with:
Files: {each file you created or changed, or none}
Status: DONE | NOTHING: why | FAILED: why
````

If an agent fails, or answers without the form, start it once more. If it fails again, stop and return `KNOWLEDGE_FAILED`: what the earlier agents wrote stays, and running archive again updates it.

## 3. Keep the records

When `archivePath` is set, copy every file and folder in `<activeSlicePath>` into the slice's archive folder, creating it when needed and replacing the files already there. The copied `status.md` is a snapshot: the pipeline keeps writing to the one in `<activeSlicePath>`, which the next `/slice:new` clears.

## 4. Commit

With the project's version control, the one the context or the project instructions name, or else the one the project folder uses, commit with its own commands exactly the files the agents changed and the slice's archive folder, named one by one, never everything that changed at once. The message is `Archive slice: <title>`. When nothing changed, for example when archiving again found nothing new, make no commit. When the version control ignores the archive folder, commit the rest and say so.

Without version control, leave the changes as they are.

## 5. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the documents updated by each agent, where the records went, and the commit, or why there is none>
files: <each document changed, and the slice's archive folder>
```

When `knowledgeAgents` is an empty list and `archivePath` is empty, nothing is configured:

```text
result: skipped
message: no knowledge agents and no archive folder are configured
files: none
```

On failure, end with this instead:

```text
result: error
code: <NO_SLICE | KNOWLEDGE_FAILED | WRITE_FAILED | COMMIT_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
