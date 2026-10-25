---
name: consolidate
description: Internal Slicewright consolidate stage. Has the configured knowledge agents stage what a finished slice changed and learned, such as the living spec, decision records, known issues and lessons, publishes every staged documentation page to the project's documentation, keeps the slice's records with an entry in their index, and commits it all. Running it again updates what it published before. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Consolidate

Close the slice: fold what it changed and learned into the project's documentation, and keep its records. Never change the project's code or tests here.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `knowledge`: the project's documentation, which may be missing:
  - `sources`: where it is, one entry per source, each with a `name`, a `path` when it is a folder in the project or a `skill` that reads it and publishes to it when it is somewhere else, such as a wiki, and a `context` saying what is there and how to read and write it
  - `publishTo`: the name of the source the slice's documentation changes go to. Below, "the documentation" means that source.
- `archivePath`: the folder that keeps finished slices' records, outside the documentation. Each slice gets its own folder in it, `<archivePath>/<date>-<name>`, and an entry in `<archivePath>/index.md`. When it is missing or empty, records aren't kept.
- `knowledgeAgents`: the agents that stage the documentation's updates, in the order they run. When missing, use one `general-purpose` agent that updates the documentation with what the slice changed and learned. When it is an empty list, only the pages already staged are published. Each entry has:
  - `executionMode`: `fork` runs it as a subagent; `inline` means you do its work yourself
  - `skill` or `agent`: for `fork`, the skill the subagent invokes, or else the subagent type, `general-purpose` when neither is given
  - `context`: which pages it writes and what goes into them
  - `name`: a label for the result, which may be missing
- `context`: the project's rules for this stage, which may be missing

Ignore any other key. The contexts are rules for you and the agents to follow. Never copy them into a file.

Never ask the user anything. Never change the project's code, tests or the slice's records, except the staged pages in `<activeSlicePath>/docs/`, and the files outside the documentation that a knowledge agent's context names, such as the project instructions, which that agent writes in place.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Never change the shell's folder with `cd`. Start every subagent in the foreground, never in the background, and never end your turn while one is running.

**Staged pages.** `<activeSlicePath>/docs/` holds the slice's changes to the documentation, at their paths in it: each file there is the whole new version of the file at that path, and an empty `<path>.delete` file removes the file at `<path>`. Stages before this one staged the slice's documentation changes there; the knowledge agents add theirs; step 3 publishes them all. Pages are never changed in the documentation itself before that.

## 1. Read the slice

Read `<activeSlicePath>/status.md`. If it doesn't exist, return `NO_SLICE`. Take the slice's title, its id when it has one, and the date part of `created`.

The slice's records folder is `<archivePath>/<that date>-<name>`, where the name is the id, or else the title in lowercase words joined with `-`. It depends only on the slice, so consolidating the same slice again uses the same folder.

List the files in `<activeSlicePath>`, including those in its subfolders, and the staged pages among them.

## 2. Stage the documentation's updates

Run the knowledge agents one at a time, in list order, because pages link to each other and share indexes. Start each `fork` agent with your tool for starting subagents (Agent), with this prompt. Do the work of each `inline` entry yourself, following the same prompt.

````text
You are bringing what one finished feature slice changed and learned into the
project's documentation.
{for an entry with a skill: Invoke the {skill} skill, and write with it.}

{the entry's context; when it is empty: Update the project's documentation with what
this slice changed and learned.}

The project's documentation: {each source: its name, its path or its skill, and its
context; or "not described"}. Your changes go to {the source publishTo names}. Read
the published pages your instructions need, and follow that source's conventions and
structure. When a page you need doesn't exist yet, create it in the same style. When
a source can't be reached, say so, and go on with what you have.

The slice's records, in {activeSlicePath}: {the files}. Read the ones your
instructions need. They will be kept in {the slice's records folder, or "nowhere"}.

Never change the published documentation: stage your changes. Write each page you
create or change, in full, to {activeSlicePath}/docs/<its path in the documentation>,
and for a page to remove, create the empty file {activeSlicePath}/docs/<its path>.delete.
A page already staged there is this slice's newer version: start from it, not from
the published one. Pages you staged when this slice was consolidated before are
there too: update them instead of adding new ones.

Write only the pages your instructions are about. A file outside the documentation
that your instructions name, such as the project instructions, isn't staged: write it
in place, and change only the part your instructions name. Never change code, tests
or the slice's other records. Run each command on its own from this folder: never use cd,
and never chain commands with &&, ;, pipes or loops. Never ask the user anything.

End with:
Files: {each page you staged, with its path in the documentation, marked (new),
  (changed) or (removed), and each file you wrote in place, marked (in place); or none}
Status: DONE | NOTHING: why | FAILED: why
````

If an agent fails, or answers without the form, start it once more. If it fails again, stop and return `KNOWLEDGE_FAILED`: what the earlier agents staged stays, and running this stage again goes on from there.

## 3. Publish

When nothing is staged, skip this step. Otherwise publish every staged page:

- **When the documentation has a `skill`:** invoke that skill with the staging folder, `<activeSlicePath>/docs/`, and the rule above: each file is the whole new version of the file at the same path in the documentation, and each `.delete` file removes its file. It publishes them, including images and other attachments, and reports each page with where it went, as a path or a link, and each page it couldn't publish, with why. A page that changed in the documentation since this slice read it is the skill's to merge or to report. When it reports a page it couldn't publish, return `PUBLISH_FAILED`, naming each one.
- **Else when it has a `path`:** copy each staged file to the same path under that `path`, replacing the file there and creating its folders when needed, and delete the file each `.delete` file names. The documentation is in the project, so its version control catches pages that changed elsewhere when the slice's work is merged.
- **Else**, or when `publishTo` names no source: there is nowhere to publish: return `NO_DOCUMENTATION`.

Publishing the same staged pages again changes nothing, so a rerun after a failure is safe. When the documentation's `context` names a check for it, such as a site build or a link check, run it now; when it fails, return `DOCS_CHECK_FAILED` with its output.

## 4. Keep the records

When `archivePath` is set, copy every file and folder in `<activeSlicePath>` into the slice's records folder, creating it when needed and replacing the files already there. The copied `status.md` is a snapshot: the pipeline keeps writing to the one in `<activeSlicePath>`, which the next `/slice:new` clears.

Then add the slice's entry to `<archivePath>/index.md`, creating it with the heading `# Slices` when it is missing, newest first. When the index already has an entry for this slice's folder, replace it, and never change the other entries. The index is history, for finding earlier slices by the code and the behavior they touched: keep each entry short and searchable.

```markdown
## {date} {name}: {title}

- Areas: {each file the slice's runs in implement.md changed, outside the slice folder}
- Pages: {each documentation page the slice published}
- Decisions: {the decision records it staged, by number and title, or none}
- Accepted: {each review finding and test whose Decision line a person set to accepted or deferred, with its id and a few words, or none; never a finding nobody decided on}
- Root causes: {each cause in bug-analyses.md, with its id, title and where, or none}
- Records: {name}/
```

## 5. Commit

With the project's version control, the one the context or the project instructions name, or else the one the project folder uses, commit with its own commands exactly the files step 3 published or deleted under the documentation's `path`, the files the knowledge agents wrote in place, the slice's records folder and the records index, named one by one, never everything that changed at once. The message is `Consolidate slice: <title>`. When nothing changed, for example when consolidating again found nothing new, make no commit. When the version control ignores the records folder, commit the rest and say so.

Without version control, leave the changes as they are.

## 6. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: the pages each agent staged, where the pages were published, where the records went, and the commit, or why there is none>
files: <each page published, as a path or a link, the slice's records folder and the records index>
```

When `knowledgeAgents` is an empty list, nothing is staged and `archivePath` is empty, there is nothing to do:

```text
result: skipped
message: no knowledge agents, no staged pages and no records folder are configured
files: none
```

On failure, end with this instead:

```text
result: error
code: <NO_SLICE | KNOWLEDGE_FAILED | NO_DOCUMENTATION | PUBLISH_FAILED | DOCS_CHECK_FAILED | WRITE_FAILED | COMMIT_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run changed, or none>
```
