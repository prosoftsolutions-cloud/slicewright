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
- [0011](0011-the-research-skill-has-the-design-skills-shape.md): the research skill has the shape of the design skill, section by section
- [0012](0012-the-confidence-scale-is-defined-in-the-agent-prompt.md): the confidence scale is defined once, in the research agent's prompt, and the merge derives an answer's confidence from it
- [0013](0013-evidence-and-follow-up-lines-carry-labels.md): evidence lines carry `Source:` and `Confidence:`, and a follow-up has a title before a colon and a `Decision:` line of its own
- [0014](0014-a-later-research-run-keeps-what-a-person-wrote.md): a later research run keeps what a person wrote, and matches questions and follow-ups by text
- [0015](0015-the-runner-switches-configuration-in-the-continue-choice.md): the runner switches to the slice's configuration in the **Continue** choice, not before the question
- [0016](0016-the-research-pipeline-holds-only-pipeline.md): `research.json` holds only `pipeline`, and repeats intake's and release's contexts
- [0017](0017-file-issues-finds-an-issue-by-exact-title.md): `file-issues` finds an existing issue with a title search and an exact match
- [0018](0018-the-research-page-is-named-from-the-slices-title.md): the research page is named from the slice's title, with the records folder's slug rule spelled out
- [0019](0019-the-adr-agent-writes-one-record-only-on-a-decision.md): the research pipeline's `adr` agent writes at most one record, and only when the decision doesn't start with `none`
- [0020](0020-the-configs-check-is-defaults-jq-with-an-optional-base.md): the `configs` check is `defaults.jq` with an optional base, merged the runner's way
- [0021](0021-the-configs-self-test-case-copies-only-research-json.md): the `static/configs` case copies only `research.json` of `.slicewright/`, and `static/checker` also asserts `PASS configs`
- [0022](0022-configure-with-a-name-creates-no-file.md): `/slice:configure --config <name>` checks the three files in its loading step, and creates nothing for another name
