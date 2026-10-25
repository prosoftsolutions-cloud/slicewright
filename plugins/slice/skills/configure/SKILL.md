---
name: configure
description: Set up Slicewright in this project. Creates the project config from the plugin defaults and allows the pipeline's skills to run without permission prompts.
argument-hint: "[--permissions]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/config.json)
---

# Configure the project

Arguments: $ARGUMENTS

With `--permissions`, skip steps 2 and 3 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--permissions]`.

## 1. Find the project root

The project root is the top folder of the project's version control working copy: find it with that version control's own command. Without version control, use the current folder. Every path below is relative to it.

## 2. Create the config

If `.slicewright/config.json` doesn't exist, read `${CLAUDE_PLUGIN_ROOT}/defaults.json` and write its exact content there with the Write tool, not a shell copy. If it exists, leave it unchanged.

## 3. Set up the documentation

Load the configuration as in step 4.1, and take `sharedParams.knowledge` and the `knowledgeAgents` of the stage whose skill is `slice:consolidate`. Together they describe the documentation: its sources, the one slices publish to (`publishTo`), its structure, and the pages each agent keeps. Skip this step when `knowledge` is missing.

1. **The source slices publish to.**
   - **With a `skill`**, it is outside the project, and that skill manages it: change nothing there. Say which skill it is.
   - **With a `path`, when the folder doesn't exist or has no pages:** show the structure the configuration describes: its folders, and the index pages its conventions call for, with the root index's short "How to read" part. Ask the user whether to create it, and wait for the answer. When they agree, create those folders and index pages, each following the documentation's conventions, and nothing else.
   - **With a `path`, when the folder already has documentation:** compare its structure with the one the configuration describes. For each place the configuration names, such as a folder for decision records, find the existing folder or page that serves it, or say there is none. Show the user this mapping, ask them to confirm or correct it, and wait for the answer. Then write it into `.slicewright/config.json`: change the paths in the source's `context` and in the knowledge agents' contexts to the existing ones, and keep everything else as it was. Never move or rename the project's existing documentation.
2. **The project instructions block.** Every agent and every session reads the root `AGENTS.md`, so it carries a short pointer to the documentation: a block between `<!-- slicewright:knowledge -->` and `<!-- /slicewright:knowledge -->`, written the way the `instructions` knowledge agent's context says, when there is one. Show the block, ask whether to add it, and wait for the answer. When they agree, replace only what is between the markers; when there are none, add the block at the end of `AGENTS.md`, and when there is no `AGENTS.md`, create it with only the block. Never change `CLAUDE.md`.
3. **What `AGENTS.md` already says.** Read the rest of the root `AGENTS.md`, when it exists, and look for two kinds of overlap with the documentation:
   - a section that repeats what the documentation holds, or should hold, such as a description of the architecture: propose moving its content into the documentation, at the page where it belongs, and leaving a one-line pointer in its place
   - a pointer to the documentation outside the block: propose removing it, so that there is one pointer

   Show each proposal on its own, and wait for the user's answer to each. Apply only the ones they approve: write a moved section to the documentation the way consolidate publishes, under the source's `path`, or with its `skill`, then change `AGENTS.md`. Leave everything they reject, and everything else in the file, as it is.

## 4. Update the permissions

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

   When a stage's skill is `slice:diagnose`, also propose the read-only commands its `instrumentAgents` contexts name, such as queries of logs, traces or a database, and for instruments with `readOnly: false` the project's build, test and run commands, and the version control commands that show the current revision and restore files.

   When a stage's skill is `slice:consolidate`, also propose the command that copies a folder, and the version control commands that stage files and commit them.

   Show these proposed rules and ask the user which to add, and wait for the answer. Add only those.
   With `isolation: worktree`, when copies are git worktrees, because the project uses git and has no `WorktreeCreate` hook, also set `worktree.baseRef` to `"head"` in the settings file, so each worker's copy starts from the slice's latest revision.
3. Choose the settings file. If `.claude/settings.json` or `.claude/settings.local.json` already allows `Skill(slice:run)`, use that file. Otherwise ask the user which one to use, and wait for the answer:
   - `.claude/settings.json`: shared with the team and committed, like `.slicewright/config.json`
   - `.claude/settings.local.json`: only for this user, not committed
4. Add each missing rule to `permissions.allow` in that file, and `worktree.baseRef` when step 2 calls for it, creating the file or the keys when needed. Never remove, reorder or change anything else in it.

## 5. Report

- the config file, and whether you created it, changed it or left it as it was
- the documentation: what you created or mapped, whether you added the `AGENTS.md` block, and each `AGENTS.md` proposal with the user's answer
- the settings file, the rules you added, and the rules that were already there
- any `Skill(...)` rule in that file that the pipeline no longer uses: list it, and leave it in place
