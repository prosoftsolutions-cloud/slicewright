---
name: human
description: Internal Slicewright stage that brings a person into the pipeline. It presents what the context names, discusses it, applies the person's answers to the files it may change, and ends with their decision. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Human step

The person decides. You prepare, explain, apply their answers and record the outcome. Run this in the main conversation, because a subagent can't reach the person.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `context`: what to show, what the person decides, what counts as passing, and any rules for the files you change
- `files`: the files you may change, relative to `activeSlicePath`. Without it, change no file.
- `choices`: the answers the person chooses from, each mapped to the stage the pipeline goes to next, or to `null` to end the run there. Without it, the decision is pass or not pass.

Ignore any other key. If `context` is missing or empty, return an error with code `NO_CONTEXT`.

## 1. Skip when the context says so

If the context gives a condition for skipping this step and it holds, ask nothing and return `skipped` with the reason.

## 2. Present

Read what the context names: files, a diff, a pull request, results from earlier stages. Then present it in your own words, not as a dump of the files:

1. what it is, in a few lines
2. what is already settled
3. the open items: questions, defaults to confirm, risks, and the decision to make

For each open item, say why it matters, give lettered options when the answers are a closed set, and give your recommendation with its reason.

## 3. Discuss

- Take the items that block the decision first, in small batches. Ask an item on its own when its answer could change the others.
- Wait for answers. Silence is not agreement: an item the person didn't answer stays open.
- Answer the person's questions, reading whatever you need.
- When an answer changes something, update everything that depends on it.
- Apply the answers to the files you may change as you go, following the context's rules for them, and say what you changed. Never change any other file. When the person asks for a change you may not make, say so and include it in the result.

## 4. Decide

When nothing that blocks the decision is open, ask for the decision the context defines and wait for an explicit answer.

With `choices`, offer exactly those answers, saying what each one leads to, and nothing else. When the answer doesn't clearly match one, ask again.

- **A choice that maps to a stage:** do what the context says for that choice, within the files you may change, and return `ok` with that stage as `next`.
- **A choice that maps to `null`:** do what the context says for that choice, then return `ENDED`, naming the choice and the person's reasons.

Without `choices`:

- **The passing answer the context defines:** do what the context says to do on approval, within the files you may change, and return `ok`.
- **Any other decision:** return `REJECTED` with the person's reasons.

At any point, the person may pause instead of deciding: leave the files as they are now and return `STOPPED`. Its fix says that `/slice:resume` continues this step.

## 5. Return the result

End with exactly one of these blocks, with nothing after it.

```text
result: ok
message: <the decision, in one sentence>
next: <with choices only: the stage the chosen answer maps to>
files: <the files you changed, or none>
```

```text
result: skipped
message: <why the step was skipped>
files: none
```

```text
result: error
code: <NO_CONTEXT | REJECTED | ENDED | STOPPED>
message: <one sentence: the decision or what stopped it, and the person's reasons>
fix: <what happens next, including any changes the person asked for that you couldn't make>
files: <the files you changed, or none>
```
