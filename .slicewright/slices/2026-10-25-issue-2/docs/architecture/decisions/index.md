---
type: index
---

# Decisions

The numbered decision records, `NNNN-<title>.md`, each with its context, the decision, the alternatives considered and its consequences.

## Pages

- [0001](0001-plugin-tests-are-posix-sh-scripts.md): plugin tests are POSIX sh scripts, run as `sh tests/<name>.sh`
- [0002](0002-one-smoke-command-with-subcommands.md): one smoke command with subcommands
- [0003](0003-the-test-stage-waits-for-a-smoke-run-in-steps.md): the test stage waits for a smoke run in steps, `start`, then `wait` again and again
- [0004](0004-the-smoke-test-configuration-is-generated-from-the-defaults.md): the smoke test's configuration is generated at run time from the working copy's defaults
- [0005](0005-the-smoke-configuration-overrides-only-intakes-context.md): the smoke configuration overrides only intake's context
- [0006](0006-the-smoke-session-is-isolated-from-the-developers-setup.md): the smoke session is isolated from the developer's own setup
- [0007](0007-the-smoke-session-runs-with-an-explicit-allow-list.md): the smoke session runs with `acceptEdits`, every prompt denied, and an explicit allow list
- [0008](0008-the-isolation-check-leaves-out-built-in-plugins.md): the isolation check leaves out Claude Code's built-in plugins
- [0009](0009-the-smoke-time-limit-is-a-watchdog-in-the-script.md): the smoke time limit is a watchdog inside `smoke.sh`
- [0010](0010-the-finished-run-fixture-is-an-overlay-on-the-sample.md): the finished-run fixture is an overlay on the sample
