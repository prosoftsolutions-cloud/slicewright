---
type: overview
---

# Structure

How the code is organized.

- `.claude-plugin/marketplace.json`: the marketplace
- `plugins/slice/.claude-plugin/plugin.json`: the plugin manifest
- `plugins/slice/defaults.json`: the default configuration, `sharedParams` and `pipeline`, and the reference for every stage's params
- `plugins/slice/skills/<name>/SKILL.md`: one skill per folder. `new`, `resume` and `configure` are the user's commands. The others are internal, with `user-invocable: false`, and `run`, the pipeline runner, runs them.
