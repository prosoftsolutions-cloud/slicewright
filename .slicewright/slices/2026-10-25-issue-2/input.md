---
title: Tests
id: issue-2
source: https://github.com/prosoftsolutions-cloud/slicewright/issues/2
---

# Tests

How to test new versions?
 - ensure that "everything works"
 - reasonable tests scope/complexity/implementation timeline
 - how to inject into the process?
 - what are best practices?

## Session summary

**Decisions**

- The slice builds two levels of tests and a self-test, under `tests/` at the repo root: a static level with no model call that runs in every quality gate, and a smoke level that runs the pipeline headless on a copy of a sample project and runs in the test stage.
- The smoke run goes through intake, clarify, design, plan, implement, review and consolidate, with the defaults' params and no gates.
- The slice adds one `testAgents` entry to the repo's `.slicewright/config.json`, and changes nothing else there.
- Tests stay outside `plugins/slice/`.
- A smoke run is bounded by a 90-minute time limit only, with no cost ceiling.

**Questions and answers**

- Q1 What does this slice build? Both levels, with one smoke scenario and the self-test, wired into the pipeline and documented.
- Q2 Which stages does the smoke run go through? The seven stages above, with the defaults' params and no gates.
- Q3 May this slice add the smoke suite to the repo's own `.slicewright/config.json`? Yes, one entry in the `test` stage's `testAgents` only.
- Q4 May tests live inside `plugins/slice/` when a tool needs it? No: they stay outside, as issue #1 decided.
- Q5 What cost ceiling and time limit should a smoke run have? A 90-minute time limit only, with no cost ceiling.

**Assumptions confirmed**

- Tests are in `tests/` at the repo root, and the testing page is `overview/testing.md`.
- The tests need only the `claude` CLI, `jq`, `git` and a POSIX shell, and the sample is a small POSIX shell program.
- The copy is put under `git`.
- The smoke run leaves out the developer's user-level plugins, skills, hooks and MCP servers.
- Pass or fail rests only on checks a command evaluates.
- No sample project exists yet, and the slice creates one. No other copy of the `slice` plugin is installed.
- A headless `claude -p` started from a stage agent's shell reaches the model API.
- Permission rules for the new commands come from `/slice:configure --permissions`, not from this slice.
- This slice's own test stage runs the smoke suite only in a run that starts after implement commits the config change, such as after `/slice:resume`.

**Still open**

- Nothing.

See spec: spec.md
