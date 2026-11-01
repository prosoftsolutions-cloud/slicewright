---
type: log
---

# Log

The consolidated slices, newest first.

## 2026-11-01: Research flow: a slice:research stage and a research pipeline

- [overview/product.md](overview/product.md) (new): what Slicewright is and does, its commands, the default pipeline's stages and gates, the configuration, the documentation, this repo and its limitations
- [overview/structure.md](overview/structure.md) (changed): adds the `research` skill, `.slicewright/config.json` and `.slicewright/research.json`, `.claude/settings.json`, and `start-slice.sh --config <name>`
- [overview/testing.md](overview/testing.md) (changed): the fifth static check, `configs`, the `static/configs` self-test case, 16 cases, and that a rule in `defaults.jq` applies to every configuration
- [product/spec/plugin-tests.md](product/spec/plugin-tests.md) (changed): the static level also checks this repo's pipeline configurations, with the `configs` check, its self-test case and its acceptance criteria; the limitations after the first smoke run, and the untested `*.local.json` rule
- [product/spec/research-stage.md](product/spec/research-stage.md) (new): what `slice:research` reads, the brief, its research agents, the research document, later runs, the review and the result, with acceptance criteria and limitations
- [product/spec/research-pipeline.md](product/spec/research-pipeline.md) (new): the eight stages of `.slicewright/research.json`, its permissions, how it is started and continued, and what a run leaves, with acceptance criteria and limitations
- [product/spec/named-configurations.md](product/spec/named-configurations.md) (new): `--config <name>` on `/slice:new`, `/slice:resume`, `/slice:configure` and `start-slice.sh`: the name, loading, how a slice remembers its configuration, and how the configurations are checked
- [architecture/context.md](architecture/context.md) (changed): the tests also check the configurations; adds a research run and its neighbors
- [architecture/building-blocks.md](architecture/building-blocks.md) (changed): the `configs` check in the static level; adds the research stage, the research pipeline, the permission rules and named configurations, with `research.md` as their interface
- [architecture/runtime.md](architecture/runtime.md) (changed): the five static checks, and the two self-test cases that copy the repo's parts, in a quality gate; adds a slice with a named configuration, and a research topic through the research pipeline
- [architecture/concepts.md](architecture/concepts.md) (changed): options are parsed by hand; a rule has one source, restated whole when code can't read it there, and a copy that can't be avoided is documented
- [architecture/risks.md](architecture/risks.md) (changed): the smoke test's risk narrowed by the first passing run: the cost is unmeasured and the one-minute limit unproven
- [architecture/decisions/0011-the-research-skill-has-the-design-skills-shape.md](architecture/decisions/0011-the-research-skill-has-the-design-skills-shape.md) (new)
- [architecture/decisions/0012-the-confidence-scale-is-defined-in-the-agent-prompt.md](architecture/decisions/0012-the-confidence-scale-is-defined-in-the-agent-prompt.md) (new)
- [architecture/decisions/0013-evidence-and-follow-up-lines-carry-labels.md](architecture/decisions/0013-evidence-and-follow-up-lines-carry-labels.md) (new)
- [architecture/decisions/0014-a-later-research-run-keeps-what-a-person-wrote.md](architecture/decisions/0014-a-later-research-run-keeps-what-a-person-wrote.md) (new)
- [architecture/decisions/0015-the-runner-switches-configuration-in-the-continue-choice.md](architecture/decisions/0015-the-runner-switches-configuration-in-the-continue-choice.md) (new)
- [architecture/decisions/0016-the-research-pipeline-holds-only-pipeline.md](architecture/decisions/0016-the-research-pipeline-holds-only-pipeline.md) (new)
- [architecture/decisions/0017-file-issues-finds-an-issue-by-exact-title.md](architecture/decisions/0017-file-issues-finds-an-issue-by-exact-title.md) (new)
- [architecture/decisions/0018-the-research-page-is-named-from-the-slices-title.md](architecture/decisions/0018-the-research-page-is-named-from-the-slices-title.md) (new)
- [architecture/decisions/0019-the-adr-agent-writes-one-record-only-on-a-decision.md](architecture/decisions/0019-the-adr-agent-writes-one-record-only-on-a-decision.md) (new)
- [architecture/decisions/0020-the-configs-check-is-defaults-jq-with-an-optional-base.md](architecture/decisions/0020-the-configs-check-is-defaults-jq-with-an-optional-base.md) (new)
- [architecture/decisions/0021-the-configs-self-test-case-copies-only-research-json.md](architecture/decisions/0021-the-configs-self-test-case-copies-only-research-json.md) (new)
- [architecture/decisions/0022-configure-with-a-name-creates-no-file.md](architecture/decisions/0022-configure-with-a-name-creates-no-file.md) (new)
- [overview/index.md](overview/index.md) (changed): lists the new page
- [product/spec/index.md](product/spec/index.md) (changed): lists the new pages
- [architecture/index.md](architecture/index.md) (changed): describes `context.md`, `building-blocks.md` and `runtime.md` with the sections they gained
- [architecture/decisions/index.md](architecture/decisions/index.md) (changed): lists the new records
- Records: [.slicewright/slices/2026-10-27-issue-16](../.slicewright/slices/2026-10-27-issue-16/), from [issue #16](https://github.com/prosoftsolutions-cloud/slicewright/issues/16)

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
