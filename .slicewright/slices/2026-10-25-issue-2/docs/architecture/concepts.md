---
type: architecture
---

# Concepts

The rules that apply across the code, each with its reason. The rules for writing skills are in the project's instructions, [AGENTS.md](../../AGENTS.md). [Testing](../overview/testing.md) describes the tests that most of these rules shape.

## Shell scripts are POSIX sh

- Every script runs as `sh <path>`, and needs no executable bit.
- It uses POSIX sh only: no `local`, no arrays, no `[[ ]]`, no `sed -i` and no `grep -r`.
- It needs only the `claude` CLI, `jq`, `git` and the standard utilities of a POSIX system, plus `mktemp`, which macOS and every common Linux have.
- It passes `dash -n`.

Why: the repo has no runtime and no package manager, so nothing has to be installed. `sh <path>` needs no executable bit in version control, and gives each command one permission prefix, such as `Bash(sh tests/smoke.sh:*)`. On macOS, `/bin/sh` is bash in POSIX mode, which accepts bash-only syntax, so only `dash` shows it.

## Every value has one source

A value is kept in one place. Code that needs it elsewhere reads it from there, or generates from it, and never keeps a copy. For example:

- The smoke test's configuration is generated from `plugins/slice/defaults.json` when a run starts, and check 3 takes its stage names from that generated file.
- The finished-run fixture holds only what a run adds to the sample, and is laid on a copy of the sample.
- The smoke test's time limit is set once, as `LIMIT_MINUTES` in `tests/smoke.sh`.

Why: a copy drifts. A test that compares with its own copy keeps passing after the source has changed. With one source, a change to the defaults or the sample reaches the tests with no change under `tests/`.

## Check commands

- A command that runs checks exits 0 when every check passed, 1 when one failed, and 2 when it couldn't check anything, such as on wrong usage or a missing tool. Any other status says something that isn't a result, such as 3 from `sh tests/smoke.sh wait` while the run is still going.
- Each failure names its subject: the check, file, stage, skill or case it concerns.
- Every path that ends a command ends it the same way. It records what the usual end records, and takes its exit status from the report it prints.

Why: the quality gates and the test stage's suites read only the exit status and the lines a command prints. Status 2 tells them that nothing was checked, so a suite reports it as not started, not as a failed test. The self-test proves each check by the subject it names. A path that ends a command on its own, such as one for a run that stopped without finishing, drifts from the usual end: it records less, or exits with a status its report doesn't give.

## Acceptance checks cover every stated outcome

An acceptance check has one case for each outcome its request states. That includes what must stay as it was, and the inputs a rule leaves alone, under the conditions that would change them: for a rule that only a to z become upper case, a letter outside a to z, under a UTF-8 locale.

Why: the acceptance check is the one check of a feature that the pipeline can't change. A feature that breaks an outcome with no case passes it, and the smoke test then reports a working feature.
