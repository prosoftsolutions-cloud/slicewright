---
name: configure
description: Set up Slicewright in this project. Creates the project config from the plugin defaults and allows the pipeline's skills to run without permission prompts.
argument-hint: "[--permissions]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/config.json)
---

# Configure the project

Arguments: $ARGUMENTS

With `--permissions`, skip step 2 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--permissions]`.

## 1. Find the project root

The project root is the top folder of the project's version control working copy: find it with that version control's own command. Without version control, use the current folder. Every path below is relative to it.

## 2. Create the config

If `.slicewright/config.json` doesn't exist, read `${CLAUDE_PLUGIN_ROOT}/defaults.json` and write its exact content there with the Write tool, not a shell copy. If it exists, leave it unchanged.

## 3. Update the permissions

1. Load the configuration: read these JSON files in order, each with the Read tool rather than a shell command, and skip any that don't exist. Objects merge key by key, at any depth, any other value from a later file, such as an array or text, replaces the earlier one, and a `null` value removes the key.
   1. `${CLAUDE_PLUGIN_ROOT}/defaults.json`
   2. `~/.slicewright/config.json`
   3. `.slicewright/config.json`
   4. `.slicewright/config.local.json`
2. List the rules the pipeline needs:
   - `Skill(<name>)` for every stage's `skill` except `TBD`, and for every `skill` key at any depth in `sharedParams` or a stage's `params`
   - `Skill(slice:run)`, `Skill(slice:tracking)` and `Bash(date:*)`, which the pipeline runner uses

   Leave out the tools a stage's context mentions, such as a version control or ticket CLI: the user approves those when they are first used. Leave out reads of the plugin's own files: their path changes when the plugin updates.

   When a stage's skill is `slice:implement`, it runs commands on its own for a long time, so also propose rules for them, as `Bash(<command prefix>:*)`:
   - the project's build, test and quality tool commands, taken from the contexts of the stage's `qualityGateAgents`, the CI configuration and the project instructions
   - the project's version control commands it uses: to show changes and the current revision, to commit chosen files, and to restore files; with `isolation: worktree` also the commands that copy files back and remove a copy

   When a stage's skill is `slice:review`, also propose the read-only commands its reviewers run: the project's version control commands that list and show changes between revisions, and the project's test commands.

   When a stage's skill is `slice:deploy` or `slice:test`, also propose the commands its context names, and for `slice:test` the test commands of its `testAgents` and the CI configuration.

   Show these proposed rules and ask the user which to add, and wait for the answer. Add only those.
   With `isolation: worktree`, when copies are git worktrees, because the project uses git and has no `WorktreeCreate` hook, also set `worktree.baseRef` to `"head"` in the settings file, so each worker's copy starts from the slice's latest revision.
3. Choose the settings file. If `.claude/settings.json` or `.claude/settings.local.json` already allows `Skill(slice:run)`, use that file. Otherwise ask the user which one to use, and wait for the answer:
   - `.claude/settings.json`: shared with the team and committed, like `.slicewright/config.json`
   - `.claude/settings.local.json`: only for this user, not committed
4. Add each missing rule to `permissions.allow` in that file, and `worktree.baseRef` when step 2 calls for it, creating the file or the keys when needed. Never remove, reorder or change anything else in it.

## 4. Report

- the config file, and whether you created it or left it as it was
- the settings file, the rules you added, and the rules that were already there
- any `Skill(...)` rule in that file that the pipeline no longer uses: list it, and leave it in place
