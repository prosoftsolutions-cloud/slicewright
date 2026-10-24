---
name: tracking
description: Internal Slicewright step that creates and updates the active slice's status.md. Called by the Slicewright pipeline runner, never on its own.
user-invocable: false
allowed-tools: Bash(date:*)
---

# Slice status

`<activeSlicePath>/status.md` is the state of the slice in progress. It must hold enough to resume the slice in a new session. The file is small: rewrite all of it on every update, with the Write tool, never with a shell command.

Take every timestamp from `date -u +%Y-%m-%dT%H:%M:%SZ`. Never guess a time.

## Format

```markdown
---
id: PAY-123             # leave this line out when the project gives no id
title: Retry failed payment webhooks
stage: spec-review      # the current or last stage
status: done            # running | done | failed
next:                   # the stage to run next; empty when none follows
source: PAY-123         # leave this line out when there is none
config: hotfix.json     # the configuration the slice runs with; leave this line out for config.json
created: 2026-10-22T12:20:05Z
updated: 2026-10-22T12:41:03Z
---

# Retry failed payment webhooks

## Stages

| Stage | Status | Artifact | Started | Finished | Time | Tokens |
|---|---|---|---|---|---|---|
| intake | done | input.md | 2026-10-22T12:20:05Z | 2026-10-22T12:21:40Z | 1m | — |
| clarify | done | spec.md | 2026-10-22T12:22:11Z | 2026-10-22T12:23:30Z | 1m | — |
| spec-review | done | spec.md, input.md | 2026-10-22T12:23:35Z | 2026-10-22T12:41:03Z | 18m | — |

## Log

- 2026-10-22T12:20:05Z intake started
- 2026-10-22T12:21:40Z intake done: input.md → clarify
- 2026-10-22T12:22:11Z clarify started
- 2026-10-22T12:23:30Z clarify done: spec.md → spec-review
- 2026-10-22T12:23:35Z spec-review started
- 2026-10-22T12:41:03Z spec-review done: spec.md, input.md
```

A stage can run more than once in a slice. Each run has its own row: the first is named after the stage, later ones `<stage> #2`, `<stage> #3` and so on.

## Operations

The arguments are `<operation> <activeSlicePath>` followed by the operation's values.

- **`create <path> <stage> [title="<title>"] [id=<id>] [source=<ref>] [config=<file name>] [started=<timestamp>]`:** write the file with the stage's row `in-progress` and `status: running`. `started` is for a stage that began before the file could exist: use it for the row's Started, for `created` and for the first Log line. Without it, use the current time. Fail if the file already exists.
- **`start <path> <stage>`:** set `stage`, `status: running` and an empty `next`. If the stage's latest row is `failed` or `in-progress`, from a failed or interrupted run, replace that row. Otherwise add a new row, numbered when the stage already has rows.
- **`finish <path> <stage> <done|failed|skipped> [artifact] [next=<stage>] [reason="<text>"]`:** fill the stage's latest row: status, artifact, finish time and duration. Fill Tokens only with a measured count you can actually see, such as session statistics; otherwise write `—`. Set `status` to `failed` when the stage failed and to `done` otherwise, and set `next` to the given stage, or empty. Add the reason to the Log line after the artifact, and end the line with `→ <next>` when there is one.

Every operation updates `updated` and adds one line to the Log. Every operation except `create` stops and reports if `status.md` doesn't exist; only `create` makes the file.
