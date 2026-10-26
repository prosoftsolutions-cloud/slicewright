---
type: decision
status: accepted
date: 2026-10-25
---

# 0007 The smoke session runs with `acceptEdits`, every prompt denied, and an explicit allow list

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D8 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- A headless run can't answer a permission prompt. In a new, untrusted folder, it ignores that folder's `.claude/settings.json` allow rules.
- The smoke command must grant up front exactly what the stages need, and never bypass permission checks.
- A probe showed that `Bash(sh test.sh:*)` matched `sh test.sh`, and that under `acceptEdits`, `touch` and `mkdir` inside the working folder were allowed. A command or read with no rule was denied at once, recorded in `permission_denials`, and didn't hang the run.

## Decision

- The session runs with `--permission-mode acceptEdits --permission-prompts none --allowedTools "<rules>"`. The rules are joined with commas into one argument.
- The rules are:
  - the Bash rules in `tests/smoke/allowed-tools`, one per line: `date`, the git commands the stages use, `sh test.sh` and `sh greet.sh`;
  - `Skill(slice:run)`, `Skill(slice:tracking)`, and `Skill(<skill>)` for every `skill` in the generated configuration;
  - `Read(/<absolute plugin folder>/**)` and `Read(~/.slicewright/**)`, because the runner reads both outside the copy.
- Edits, and file commands inside the copy, come from `acceptEdits`.
- The list is recorded as `allowed_tools` in the run's `run.txt`.

## Alternatives

- **`bypassPermissions` or `--dangerously-skip-permissions`.** Rejected: the constraints forbid both.
- **Rules for `cp` or `mkdir`.** Rejected: they would also allow those commands outside the copy.

## Consequences

- A missing rule shows up as a denial in `permission_denials` in `session.jsonl`, never as a hang. It can still derail a stage, and the fix is a line in `tests/smoke/allowed-tools`.
- The `Skill` rules follow the generated configuration, so a stage's new skill is allowed with no change under `tests/`.
- It assumes that `acceptEdits` allows `cp` inside the copy, which the probe showed only for `touch` and `mkdir`. If `cp` is denied, consolidate's agent can copy the records with the Write tool.
- [Testing](../../overview/testing.md) lists the allow list.
