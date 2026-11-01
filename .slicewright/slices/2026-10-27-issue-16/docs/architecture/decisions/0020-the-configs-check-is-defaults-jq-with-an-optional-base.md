---
type: decision
status: accepted
date: 2026-10-27
---

# 0020 The `configs` check is `defaults.jq` with an optional base, merged the runner's way

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D13 and D14 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- The spec asks for a fifth static check, `configs`: every `.slicewright/<name>.json` of the repo except `*.local.json`, merged onto the given plugin folder's `defaults.json` with the runner's rule and checked with the same rules as `defaults`, against that folder's skills, each problem naming the file and the stage.
- `tests/static/defaults.jq` is one jq program with a main expression. jq's `include` loads only files of definitions, so another program can't include it. `$ARGS.named` holds a `--slurpfile` value, so one program can take an optional base.
- The runner's merge: objects merge key by key at any depth, any other value is replaced, and `null` removes the key. jq's `*` merges objects recursively but keeps a `null` value instead of removing the key.
- `defaults.jq` treats a missing key and `null` alike for `next`, `onError`, `choices` and a stage's `skill`. The two merges differ only for a `null` under `sharedParams` meant to remove a `skill` or `activeSlicePath`, which `*` would flag wrongly. Neither configuration has a `null` today.
- [Concepts](../concepts.md): a rule has one source, and code that can't read it there restates the whole rule rather than using a built-in that is nearly the same. The testing page says the rules of the defaults live in one file.

## Decision

- `defaults.jq` gains a `merge($base; $over)` definition, the runner's rule with `del` on `null`, and a first expression that merges the input onto `$ARGS.named.base[0]` when `--slurpfile base` was given, and uses the input as it is otherwise. Its header comment gives both usages and says the merge is the runner's.
- The `configs` check in `static.sh`, between `defaults` and `skills`, runs `jq -r --argjson skills "$skills" --slurpfile base "$plugin/defaults.json" -f tests/static/defaults.jq <file>` once per `.slicewright/*.json` of the repo `static.sh` belongs to, skipping `*.local.json`. `$skills` is the list the `defaults` check built from the given plugin folder. Each output line becomes `FAIL configs: <file>: <subject>: <problem>`, a file that doesn't parse gives `FAIL configs: <file>: does not parse`, and `PASS configs` means no line was added, also when no file matches.
- The `defaults` check's call is unchanged.

## Alternatives

- **A `merge.jq` whose output is fed to `defaults.jq`.** Rejected: one more file, and two calls per configuration.
- **A library `pipeline.jq` of definitions with two short wrappers.** Rejected: three files for one rule set.
- **jq's `*` for the merge.** Rejected: four lines shorter, and wrong for a configuration that drops a key with `null`, which the runner accepts. A project that does so must not get a false `FAIL`.

## Consequences

- Every rule holds for the defaults and for every configuration alike, `config.json`, `research.json` and any added later, and a rule is added in one place. A configuration that names a stage skill the plugin folder lacks, or a `next`, `onError` or choice that names no stage, fails the static level offline. [Testing](../../overview/testing.md) and [Plugin tests](../../product/spec/plugin-tests.md) describe the check.
- The configurations come from the repo whatever plugin folder is given. `sh tests/static.sh .slicewright/stable/plugins/slice` fails its `configs` check while a configuration uses a skill the stable plugin doesn't have yet, as `research.json` did until this slice was merged. Nothing runs `static.sh` on the stable plugin: `start-slice.sh` and intake use `claude plugin validate`.
- The `static/…` self-test cases, which run the repo's `static.sh` on a copy of the plugin, now also check the repo's own `.slicewright/*.json` against the copy's skills. None of their breaks touches a skill folder's name, so their verdicts don't change.
- The merge restates a rule written in a skill's text. If the runner's merge changes, `defaults.jq`'s follows, and its comment says where it comes from.
- `*.local.json` is left out so that a personal file never fails the check. That exclusion has no self-test case ([0021](0021-the-configs-self-test-case-copies-only-research-json.md)).
