---
name: intake
description: Internal Slicewright stage that starts a slice. It runs the project's pre-start checks, resolves the input, writes input.md, and returns a result block. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Start a slice

Arguments: $ARGUMENTS

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `context`: the project's rules for this stage, which may be missing. They hold the checks to run before a slice starts and the rules for resolving the input. The project decides what an input means, such as which ticket system or URLs to use and how to name the slice; this skill doesn't.
- `input`: the user's request exactly as given

Ignore any other key.

Never ask the user anything, even when running in the main conversation. When something is wrong, return an error result and let the caller deal with it. Change files outside `<activeSlicePath>` only when the context tells you to.

## 1. Check

1. If `<activeSlicePath>/input.md` or `<activeSlicePath>/status.md` exists, return `SLICE_IN_PROGRESS`. Never overwrite either file.
2. If the input is empty and the context has no rule for that case, return `EMPTY_INPUT`.
3. Run every check the context asks for. If one fails, return `CHECK_FAILED`, naming the check, what is wrong and how to fix it. A tool that only some kinds of input need, such as a ticket CLI, matters only when this input needs it.

## 2. Resolve the input

Apply the context's rules for the input. If no rule applies, use the input as given.

If a rule can't be carried out, return `INPUT_UNRESOLVED` and say what you tried. For example: a reference that doesn't exist, a tool that's missing, or access that's denied.

From the result, take:

- `title`: the title the source gives, such as a ticket title, or else a summary of the input in at most eight words
- `id` and `source`: only when the context's rules produce them

## 3. Save

Write `<activeSlicePath>/input.md` with the Write tool, not with a shell command:

```markdown
---
title: <title>
id: <id; leave this line out when there is none>
source: <source; leave this line out when there is none>
---

# <title>

<resolved input>
```

If the write fails, return `WRITE_FAILED`.

## 4. Return the result

Your last message is the result, in exactly one of the forms below, with nothing after it. Leave out any line that has no value.

On success:

```text
result: ok
message: Slice "<title>" started
title: <title>
id: <id>
source: <source>
files: <activeSlicePath>/input.md
```

On failure:

```text
result: error
code: <SLICE_IN_PROGRESS | EMPTY_INPUT | CHECK_FAILED | INPUT_UNRESOLVED | WRITE_FAILED>
message: <one sentence saying what is wrong>
fix: <what the user should do>
files: <files this run left behind, or none>
```
