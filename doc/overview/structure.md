---
type: overview
---

# Structure

How the code is organized.

- `.claude-plugin/marketplace.json`: the marketplace
- `plugins/slice/.claude-plugin/plugin.json`: the plugin manifest
- `plugins/slice/defaults.json`: the default configuration, `sharedParams` and `pipeline`, and the reference for every stage's params
- `plugins/slice/skills/<name>/SKILL.md`: one skill per folder. `new`, `resume` and `configure` are the user's commands. The others are internal, with `user-invocable: false`, and `run`, the pipeline runner, runs them.
- `tests/`: the plugin's tests, outside the plugin folder because an installed plugin is a copy of its folder. [Testing](testing.md) describes them.
  - `static.sh`, `selftest.sh` and `smoke.sh`: the three commands. `static.sh` and `selftest.sh` need no model. `smoke.sh` runs the pipeline headless on a copy of the sample project.
  - `static/` and `smoke/`: the jq and awk programs, and the data files, that `static.sh` and `smoke.sh` use.
  - `sample/`: the sample project in `project/`, its request in `request.md`, and its acceptance check, `accept.sh`, which is never copied into a run.
  - `fixtures/finished-run/`: what a passing run adds to the sample, for the self-test.
