---
name: configure
description: Set up Slicewright in this project. Creates the project config from the plugin defaults and allows the pipeline's skills to run without permission prompts.
argument-hint: "[--permissions]"
disable-model-invocation: true
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/config.json) Bash(git rev-parse:*)
---

# Configure the project

Arguments: $ARGUMENTS

With `--permissions`, skip step 2 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--permissions]`.

## 1. Find the project root

Run `git rev-parse --show-toplevel`. Outside a git repository, use the current folder. Every path below is relative to it.

## 2. Create the config

If `.slicewright/config.json` doesn't exist, read `${CLAUDE_PLUGIN_ROOT}/defaults.json` and write its exact content there with the Write tool, not a shell copy. If it exists, leave it unchanged.

## 3. Update the permissions

1. Load the configuration: read these JSON files in order, each with the Read tool rather than a shell command, and skip any that don't exist. Objects merge key by key, at any depth, and any other value from a later file, such as an array or text, replaces the earlier one.
   1. `${CLAUDE_PLUGIN_ROOT}/defaults.json`
   2. `~/.slicewright/config.json`
   3. `.slicewright/config.json`
   4. `.slicewright/config.local.json`
2. List the rules the pipeline needs:
   - `Skill(<name>)` for every `skill` in `pipeline`, in its stages and in the entries of their `params.availableSkills`, except `TBD`
   - `Skill(slice:run)`, `Skill(slice:tracking)` and `Bash(date:*)`, which the pipeline runner uses

   Leave out the tools a stage's context mentions, such as git or a ticket CLI: the user approves those when they are first used. Leave out reads of the plugin's own files: their path changes when the plugin updates.
3. Choose the settings file. If `.claude/settings.json` or `.claude/settings.local.json` already allows `Skill(slice:run)`, use that file. Otherwise ask the user which one to use, and wait for the answer:
   - `.claude/settings.json`: shared with the team and committed, like `.slicewright/config.json`
   - `.claude/settings.local.json`: only for this user, not committed
4. Add each missing rule to `permissions.allow` in that file, creating the file or the key when needed. Never remove, reorder or change anything else in it.

## 4. Report

- the config file, and whether you created it or left it as it was
- the settings file, the rules you added, and the rules that were already there
- any `Skill(...)` rule in that file that the pipeline no longer uses: list it, and leave it in place
