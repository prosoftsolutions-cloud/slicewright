---
type: decision
status: accepted
date: 2026-10-27
---

# 0021 The `static/configs` case copies only `research.json` of `.slicewright/`, and `static/checker` also asserts `PASS configs`

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D15 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- The spec asks for one self-test case: a copy of `research.json` with a stage's `skill` set to a skill with no folder, in a copy of the repo's parts the check needs, expecting a `FAIL` line that names the file and the stage. It also asks that a copy with no `.slicewright/` folder prints `PASS configs`.
- The `configs` check reads the configurations from `static.sh`'s own repo ([0020](0020-the-configs-check-is-defaults-jq-with-an-optional-base.md)), so a case can't break a copy of the plugin alone: the copy has to be a repo. `static/checker` shows how: it copies the manifests, `plugins`, `tests/static.sh` and `tests/static`, and runs the copy's `static.sh`.
- The repo's `.slicewright/` also holds `stable/`, a git worktree, `slices/`, the records archive, and `config.json`.

## Decision

- `static/configs` copies `.claude-plugin`, `plugins`, `tests/static.sh`, `tests/static` and `.slicewright/research.json` into its copy, sets the `research` stage's `skill` to `slice:no-such-skill` with jq, runs the copy's `static.sh`, and expects a `FAIL` line that contains `research.json: stage research: `.
- `static/checker` gains one line, `need_line "PASS configs"`: its copy has no `.slicewright/`, so it proves the no-folder path.
- The self-test has 16 cases, ten `static/…` and six `smoke/…`.

## Alternatives

- **Copying the whole `.slicewright/`.** Rejected: it brings `stable/`, a worktree, and `slices/`.
- **A second case for the no-folder path.** Rejected: the spec asks for one case, and one line in an existing case proves the path.
- **Checking the no-folder path by hand only.** Rejected: one line makes it repeatable.

## Consequences

- The self-test proves the check by the subject it names, and the no-folder path at no extra case. [Testing](../../overview/testing.md) lists the case, and [Runtime](../runtime.md) says what each case copies.
- The case breaks the stage named `research` in `research.json`. If that stage is renamed, the case's edit no longer breaks anything, and the case has to follow.
- `config.json` isn't in the copy, so no case shows that `config.json` is checked. The repo's own `sh tests/static.sh` run shows it, at every quality gate.
- The `*.local.json` exclusion has no case: deleting that line of `static.sh` leaves both commands passing. The code review proposed copying the broken file to `research.local.json` in the same case too, and rated it a suggestion; no fix was decided. [Plugin tests](../../product/spec/plugin-tests.md) lists it as a limitation.
