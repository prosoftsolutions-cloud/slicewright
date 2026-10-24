---
name: run
description: Internal Slicewright pipeline runner. Called by /slice:new and /slice:resume, never on its own.
user-invocable: false
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/**) Bash(date:*) Skill(slice:intake) Skill(slice:clarify) Skill(slice:design) Skill(slice:plan) Skill(slice:implement) Skill(slice:review) Skill(slice:deploy) Skill(slice:test) Skill(slice:diagnose) Skill(slice:archive) Skill(slice:human) Skill(slice:route) Skill(slice:tracking)
---

# Run the pipeline

Arguments: $ARGUMENTS

The first word is the mode, `new` or `resume`. It may be followed by `--config <name>`, which picks a configuration other than the default. In `new` mode the rest is the user's request.

## 1. Load the configuration

The configuration's file name is `<name>` from `--config`, with `.json` added when it doesn't end in it. Without `--config`, it is `config.json`. A name must be a plain file name: if it contains `/` or `..`, stop and say so. Its local variant replaces the ending `.json` with `.local.json`.

When resuming without `--config`, load `config.json` first. If `<activeSlicePath>/status.md` records another `config`, load that configuration instead, and say so.

Read these JSON files in order, each with the Read tool rather than a shell command, and skip any that don't exist. Relative paths resolve against the project root.

1. `${CLAUDE_PLUGIN_ROOT}/defaults.json`: defaults shipped with the plugin
2. `~/.slicewright/<file name>`: user overrides
3. `.slicewright/<file name>`: project overrides, committed
4. `.slicewright/<local variant>`: personal overrides, not committed

With a name other than `config.json`, at least one of files 2 to 4 must exist. Otherwise stop, and say which files you looked for.

Say which files you loaded. Merge them: objects merge key by key, at any depth, and any other value from a later file, such as an array or text, replaces the earlier one. A `null` value removes the key. So a project's `sharedParams` adds to the defaults, and drops one of them with `null`, while its `pipeline` replaces the default pipeline as a whole.

The configuration has two keys:

- `sharedParams`: params every stage receives
- `pipeline`: the stages, in order. A stage has `name`, `skill`, `executionMode`, `agent` (the subagent type for `fork`), `args` (the exact argument text for a skill that has its own syntax), `next` (the stage to go to after this one, instead of the following one), `onError` (the stage to go to when this one fails, instead of stopping) and `params` (the stage's own params).

You use only these keys. From the params you use only `activeSlicePath` in `sharedParams`, `context`, and every `skill` key at any depth, which always names a skill that the stage may invoke. Everything else in the params is for the stages. Below, `<activeSlicePath>` means `sharedParams.activeSlicePath`.

## 2. Check the pipeline

Check the whole pipeline before running anything. If any of these is wrong, list every problem at once and stop:

- `pipeline` is missing or empty
- `sharedParams.activeSlicePath` is missing or empty
- `sharedParams` or a stage's `params` is not an object
- a stage has no `name`, or two stages share one
- a stage's `executionMode` is not `inline` or `fork`
- a stage has neither a `skill` nor a `context` in its `params`
- a stage's `args` is not text, or a stage has `args` without a `skill`
- a stage's `params` sets `activeSlicePath`: every stage must use the folder you track
- a stage's `next` or `onError` doesn't name a stage in `pipeline`
- a stage's `skill` is neither `TBD` nor one of the skills you can invoke
- a `skill` key anywhere in `sharedParams` or a stage's `params` doesn't name one of the skills you can invoke

Warn about any other key, at the top level or in a stage: it is probably a typo, or a value that belongs in `params`. Then go on.

A stage whose `skill` is `TBD` isn't built yet, and the run stops when it reaches one. If the pipeline has such stages, name them at the start.

For each skill the run will use, look for `Skill(<name>)` in `permissions.allow` of `.claude/settings.json` and `.claude/settings.local.json`. If any is missing, say that Claude Code will ask to approve it and that `/slice:configure --permissions` adds the rules. Then go on.

## 3. Find the first stage to run

### `new`

1. If `<activeSlicePath>/status.md` or `<activeSlicePath>/input.md` exists, a slice is in progress. Show its title, stage and status from `status.md`, and list the files in `<activeSlicePath>`. Ask the user to choose, and wait for the answer:
   - **Continue:** go on as in `resume` below. Say that the request typed with `/slice:new` is not used.
   - **Start new:** delete `<activeSlicePath>` with everything in it, then go on with step 2. Never delete when `activeSlicePath` is empty, is the project root, or is outside the project; stop and report instead.
   - **Cancel:** stop.
2. If the request is empty, ask the user for a one- or two-sentence description of the feature, and wait.
3. Start at the first stage.

### `resume`

1. If `<activeSlicePath>/status.md` doesn't exist, there is nothing to resume. Say that `/slice:new` starts a slice, and stop. If `input.md` exists without it, add that the slice never finished starting and `/slice:new` will offer to start over.
2. Read `stage`, `status` and `next` from the header of `status.md`:
   - `status` is `failed` and `next` names a stage: the failed stage's `onError` stage hadn't started yet, so start with that stage.
   - `status` is `failed` with an empty `next`, or `running`: that stage failed or was interrupted, so start with it again.
   - `status` is `done` and `next` names a stage: start with that stage.
   - `status` is `done` and `next` is empty: the slice has been through the whole pipeline. Say so and stop.

   If the stage to start with isn't in `pipeline`, because the configuration changed, say so and stop. Otherwise tell the user which stage you start with and why.

## 4. Run the stages

Start with the stage from section 3, and run one stage at a time. Stay in the project folder for the whole run: never change the shell's folder with `cd`, because every stage and the subagents it starts run from that folder. For each stage:

### 4.1 Start

Take the start time from `date -u +%Y-%m-%dT%H:%M:%SZ`. If `status.md` exists, invoke `slice:tracking` with `start <activeSlicePath> <stage>`.

### 4.2 Build the params

Merge these in order, with the same rule as the configuration files, into one JSON object:

1. `sharedParams`
2. the stage's `params`
3. `input`, the user's request, only for the first stage of a new slice

The params are everything a stage receives. Never add your own keys, such as the stage's name, skill or mode. For example, with the default configuration intake receives:

```json
{
  "activeSlicePath": "./slice",
  "docPath": "./doc",
  "taskTypes": { "infrastructure": { … }, "backend": { … }, … },
  "context": "Find out used repository and available tools to work with it. …",
  "input": "Add retry for failed payment webhooks"
}
```

### 4.3 Run it

The result block that every stage must end with:

```text
result: ok | skipped | error
code: <on error only: an UPPER_SNAKE_CASE code>
message: <one sentence saying what happened>
fix: <on error only: what the user should do>
files: <files the stage created or changed in the slice folder>
```

- **`inline` with a `skill`:** invoke the skill here in the conversation, with the params as its arguments. When the stage has `args`, show the params in the conversation first, then invoke the skill with `args` instead.
- **`inline` without a `skill`:** do what `context` in the params says, here in the conversation.
- **`fork`:** start one subagent of the stage's `agent` type, `general-purpose` when it has none, and wait for it to finish. Don't run it in the background. Give it this prompt:

  ```text
  You are running the <stage> stage of a Slicewright slice.
  <with a skill, no args:> Invoke the <skill> skill with this JSON as its arguments:
  <with a skill and args:> Invoke the <skill> skill with these arguments: <args>
                           The stage's params, for reference:
  <without a skill:> Do what `context` in these params says:
  <the params>

  Never ask the user anything. If you need something only the user can give,
  stop and return an error that says what.
  When you're done, end your reply with this block, filled in, and nothing after it.
  If the skill returned its own result block, keep all of its lines, including extra
  ones such as title, id, source or next.
  <the result block>
  ```

### 4.4 Read the result

- **`fork`:** take the result block at the end of the subagent's reply. If it is missing or unreadable, continue the same subagent once and ask only for the block. If it still has none, or you can't continue it, the stage failed with `NO_RESULT`.
- **`inline`:** take the result block the skill ended with. If it ended without one, write the block yourself from what happened. If you can't tell whether the stage did its job, ask the user once; without a clear answer, the stage failed with `NO_RESULT`.

### 4.5 Pick the next stage

After `ok` or `skipped`, the next stage is the first of these that exists:

1. the `next` line of the result
2. the stage's `next` key
3. the stage after it in `pipeline`

After the last stage, with neither `next`, no stage follows. If the result's `next` names a stage that isn't in `pipeline`, the stage failed with `UNKNOWN_STAGE`: say which stage it chose, and that the fix is to correct the configuration and run `/slice:resume`.

### 4.6 Record it

In the Artifact column, write the result's `files` as names relative to `<activeSlicePath>`. Pass `next=<next stage>` when a stage follows.

- **`ok` for the first stage of a new slice**, when `status.md` doesn't exist yet: invoke `slice:tracking` with `create <activeSlicePath> <stage> started=<start time>`, adding `title`, `id` and `source` from the result when it has them, and `config=<file name>` when it isn't `config.json`. Then invoke it with `finish <activeSlicePath> <stage> done <files> next=<next stage>`.
- **`ok` for any other stage:** invoke `slice:tracking` with `finish <activeSlicePath> <stage> done <files> next=<next stage>`.
- **`skipped`:** invoke `slice:tracking` with `finish <activeSlicePath> <stage> skipped next=<next stage>`, and tell the user why the stage was skipped.
- **`error`:** if `status.md` exists, invoke `slice:tracking` with `finish <activeSlicePath> <stage> failed <files> reason="<code>: <message>"`, adding `next=<onError stage>` when the stage has `onError`. Show the code, the message and the fix. Then, when the stage has `onError`, say that the run goes on with that stage and go on with it; otherwise stop.

Then:

- no stage follows: the slice has been through the whole pipeline; stop
- the next stage's `skill` is `TBD`: stop, and say that it isn't built yet
- otherwise go on with the next stage

## 5. Report

When the run stops, report:

- the slice title and folder
- each stage this run ran, in order, with its result, and where it went next when that wasn't the following stage
- where the run stopped and why: finished, the next stage isn't built yet, or an error
- what comes next: the next stage, or the fix followed by `/slice:resume`
