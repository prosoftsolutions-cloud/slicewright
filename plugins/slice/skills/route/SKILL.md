---
name: route
description: Internal Slicewright stage that picks the pipeline's next stage. It computes the metrics its params define, checks its rules in order, records the check in its history, and returns the next stage of the first rule that matches. Run by the Slicewright pipeline, never on its own.
user-invocable: false
allowed-tools: Bash(date:*)
---

# Route

Pick the stage the pipeline goes to next. Every metric, condition and target comes from the params; apply them exactly as written, without adding conditions of your own.

Arguments: $ARGUMENTS

Never ask the user anything. Never change any file except the history file.

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `metrics`: the values to compute. Each key is a metric's name; each value says how to compute it, from files or commands.
- `rules`: a list checked in order. Each rule has `when`, a condition over the metrics, and `next`, the stage to go to, or `null` to end the run there. A rule without `when` always matches.
- `history`: a file, relative to `activeSlicePath`, that records every check. Without it, nothing is recorded, and `round` and `previous` aren't available.
- `context`: anything else to follow, which may be missing

Ignore any other key. If `rules` is missing or empty, return an error with code `NO_RULES`.

## 1. Read the history

If the history file exists, read it. Two values come from it, and conditions can use them like metrics:

- `round`: the number of this check, the checks already recorded plus one
- `previous <metric>`: the metric's value at the last recorded check

## 2. Compute the metrics

Compute each metric as its description says. Read files and run commands that only read; change nothing. For each metric, keep its value and where it came from. If a metric can't be computed, return `METRIC_UNAVAILABLE`, naming it and saying what failed, and record nothing.

## 3. Check the rules

Check the rules in order and take the first one whose condition holds. A condition that needs a value that doesn't exist, such as `previous <metric>` at the first check, doesn't hold. If no rule matches, return `NO_RULE_MATCHED` with the metric values.

## 4. Record the check

When `history` is given, append this to the file, creating it when needed, with the time from `date -u +%Y-%m-%dT%H:%M:%SZ`:

```markdown
## Round <round>, <time>

- <metric>: <value> (<where it came from>)
- Rule <its number>: <its condition, or "always">
- Next: <the stage, or "end of run">
```

## 5. Return the result

End with exactly one of these blocks, with nothing after it.

When the rule names a stage:

```text
result: ok
message: <round, the rule that matched, and the values that decided it>
next: <the rule's stage>
files: <the history file, or none>
```

When the rule's `next` is `null`, or something went wrong:

```text
result: error
code: <ENDED | NO_RULES | METRIC_UNAVAILABLE | NO_RULE_MATCHED>
message: <one sentence; for ENDED, the rule that matched and the values that decided it>
fix: <what the user should do; /slice:resume runs this check again>
files: <the history file, or none>
```
