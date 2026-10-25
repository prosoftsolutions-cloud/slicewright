# Slicewright

A Claude Code marketplace with one plugin, `slice`, which runs one feature at a time, a slice, through a configurable pipeline of stages. [README.md](README.md) says how it is used.

## Layout

- `.claude-plugin/marketplace.json`: the marketplace
- `plugins/slice/.claude-plugin/plugin.json`: the plugin manifest
- `plugins/slice/defaults.json`: the default configuration, `sharedParams` and `pipeline`, and the reference for every stage's params
- `plugins/slice/skills/<name>/SKILL.md`: one skill per folder. `new`, `resume` and `configure` are the user's commands. The others are internal, with `user-invocable: false`, and `run`, the pipeline runner, runs them.

## Design rules

- The plugin ships mechanisms, and the project configures them. A choice that a project could make differently belongs in the configuration, not in a skill.
- No hardcoded examples, limits or choices in the skills.
- No new top-level configuration keys: the top level has only `sharedParams` and `pipeline`. A new setting is a param.
- Never rely on git in skill text. Say "the project's version control", and let the project's context or instructions name it.
- A skill holds the protocol, and the content lives in the configured `context`. The prompts a skill gives its agents carry only the protocol.
- Keep it thin: the smallest change that works, with each rule in one place.

## Skill conventions

- Every stage ends with the result block in `skills/run/SKILL.md`, section 4.3. Error codes are in UPPER_SNAKE_CASE.
- Only the runner and `slice:human` talk to the person. Every other stage never asks anything: it returns an error that says what it needs.
- Commands: one per call, never chained with `&&`, `;` or pipes, and never `cd`, because every stage and its subagents run from the project folder. Files are written with the Write or Edit tool, not with shell redirection.
- Plain English, in short sentences.

## Checking a change

- `claude plugin validate .` and `claude plugin validate plugins/slice` must both pass.
- To see a change work, run the pipeline headless on a scratch project outside this repo, with `claude -p "/slice:resume" --plugin-dir <this repo>/plugins/slice --permission-mode acceptEdits --allowedTools "<what the stages need>"`. A headless run can't answer permission prompts, so allow up front the skills and commands its stages use.
- `/slice:configure` copies `defaults.json` into a project, so a change to the defaults doesn't reach a project that already has its own `.slicewright/config.json`.
