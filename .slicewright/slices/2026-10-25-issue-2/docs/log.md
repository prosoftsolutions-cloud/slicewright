---
type: log
---

# Log

The consolidated slices, newest first.

## 2026-10-26: Tests

- [overview/tech.md](overview/tech.md) (new): the plugin's technology, and what its tests need
- [overview/structure.md](overview/structure.md) (changed): adds `tests/` and its parts
- [overview/testing.md](overview/testing.md) (new): the three test levels, their commands and output, the sample, the run folder and the smoke checks
- [product/spec/plugin-tests.md](product/spec/plugin-tests.md) (new): what the plugin's tests guarantee, with acceptance criteria and limitations
- [architecture/context.md](architecture/context.md) (new): the plugin's tests and their neighbors
- [architecture/building-blocks.md](architecture/building-blocks.md) (new): the tests' five parts and their interfaces
- [architecture/runtime.md](architecture/runtime.md) (new): a smoke run in the test stage, the time limit, a stopped run and the checks
- [architecture/deployment.md](architecture/deployment.md) (new): where the tests run, and the environments a test makes
- [architecture/concepts.md](architecture/concepts.md) (new): POSIX sh scripts, one source per value, check commands, and acceptance checks that cover every outcome
- [architecture/risks.md](architecture/risks.md) (new): the smoke test that has never run for real
- [architecture/decisions/0001-plugin-tests-are-posix-sh-scripts.md](architecture/decisions/0001-plugin-tests-are-posix-sh-scripts.md) (new)
- [architecture/decisions/0002-one-smoke-command-with-subcommands.md](architecture/decisions/0002-one-smoke-command-with-subcommands.md) (new)
- [architecture/decisions/0003-the-test-stage-waits-for-a-smoke-run-in-steps.md](architecture/decisions/0003-the-test-stage-waits-for-a-smoke-run-in-steps.md) (new)
- [architecture/decisions/0004-the-smoke-test-configuration-is-generated-from-the-defaults.md](architecture/decisions/0004-the-smoke-test-configuration-is-generated-from-the-defaults.md) (new)
- [architecture/decisions/0005-the-smoke-configuration-overrides-only-intakes-context.md](architecture/decisions/0005-the-smoke-configuration-overrides-only-intakes-context.md) (new)
- [architecture/decisions/0006-the-smoke-session-is-isolated-from-the-developers-setup.md](architecture/decisions/0006-the-smoke-session-is-isolated-from-the-developers-setup.md) (new)
- [architecture/decisions/0007-the-smoke-session-runs-with-an-explicit-allow-list.md](architecture/decisions/0007-the-smoke-session-runs-with-an-explicit-allow-list.md) (new)
- [architecture/decisions/0008-the-isolation-check-leaves-out-built-in-plugins.md](architecture/decisions/0008-the-isolation-check-leaves-out-built-in-plugins.md) (new)
- [architecture/decisions/0009-the-smoke-time-limit-is-a-watchdog-in-the-script.md](architecture/decisions/0009-the-smoke-time-limit-is-a-watchdog-in-the-script.md) (new)
- [architecture/decisions/0010-the-finished-run-fixture-is-an-overlay-on-the-sample.md](architecture/decisions/0010-the-finished-run-fixture-is-an-overlay-on-the-sample.md) (new)
- [index.md](index.md) (changed): lists `log.md`
- [overview/index.md](overview/index.md) (changed): lists the new pages
- [product/spec/index.md](product/spec/index.md) (changed): lists the new page
- [architecture/index.md](architecture/index.md) (changed): lists the new pages
- [architecture/decisions/index.md](architecture/decisions/index.md) (changed): lists the new records
- Records: [.slicewright/slices/2026-10-25-issue-2](../.slicewright/slices/2026-10-25-issue-2/), from [issue #2](https://github.com/prosoftsolutions-cloud/slicewright/issues/2)
