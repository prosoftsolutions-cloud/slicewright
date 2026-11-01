---
id: T03
title: The configs static check
type: test
depends: []
covers: [R12, AC13]
---

# T03 The configs static check

## Goal

Add the fifth check, `configs`, to `tests/static.sh`, and give `tests/static/defaults.jq` an optional base it merges its input onto with the runner's rule, so that every project configuration of the repo is checked with the same rules as `defaults.json`.

## Context

### Requirement (the part of R12 for this task)

- **R12** `tests/static.sh` gets a fifth check, `configs`, after `defaults`, of the project's configurations: every `.slicewright/<name>.json` of the repo that `static.sh` belongs to, except `*.local.json`, merged onto the given plugin folder's `defaults.json` with the runner's rule (objects key by key, any other value replaced), checked with the same rules as `defaults`, against the given plugin folder's skills. Each problem is one `FAIL configs: <file>: stage <name>: <problem>` line, naming the configuration file and the stage. When the repo has no such file, the check passes. `sh tests/static.sh` and `sh tests/selftest.sh` pass on the working copy at the end of this slice, and `sh tests/smoke.sh` still passes, because the default pipeline is unchanged. (The self-test case of R12 is T05's.)

### Acceptance criterion (the parts for this task)

- **AC13** (R12) Given the working copy at the end of this slice, when `sh tests/static.sh` runs, then it prints `PASS` for five checks, `PASS configs` among them, and exits 0 within 60 seconds. Given a copy with no `.slicewright/` folder, when `static.sh` runs on it, then it prints `PASS configs`. When `sh tests/smoke.sh` runs, then every check passes. (The self-test clauses are T05's.)

### Constraints

- The scripts keep the rules in `doc/architecture/concepts.md`: POSIX `sh` only, `dash -n` clean, exit 0, 1 or 2, one source per value, and a `FAIL` line that names its subject.
- `tests/smoke.sh` and `tests/smoke/` are untouched. Nothing under `.slicewright/stable/` changes.
- Facts the design measured with jq 1.7.1: jq's `*` keeps a `null` value instead of removing the key; `$ARGS.named` holds a `--slurpfile` value, so one jq program can take an optional base; `config.json` merged onto `defaults.json` and checked by `defaults.jq` prints nothing.

### Design decisions

- **D13 `defaults.jq` takes an optional base instead of a second jq program.** `defaults.jq` gains a `merge` def and a first expression that merges the input onto `$ARGS.named.base[0]` when `--slurpfile base` was given, else uses the input as it is. The `configs` check calls it with `--slurpfile base "$plugin/defaults.json"` on each configuration file. The `defaults` check's call is unchanged. jq can't `include` `defaults.jq`, because it is one program with a main expression, so a wrapper would need the rules moved into a library and two more files; one file holds every rule, as the testing page says, and each configuration is one call.
- **D14 The merge removes a key on `null`, as the runner does.** Objects merge key by key at any depth, any other value is replaced, and `null` removes the key. jq's `*` isn't used, because it keeps the `null`: a project that drops a key with `null` must not get a false `FAIL`.

### Contract 7, the code for this task

`tests/static/defaults.jq`: the header comment says it checks a configuration object, a plugin's `defaults.json` or a project configuration merged onto it, with the two usages. Before `obj as $root`:

```jq
# The runner's merge: objects merge key by key at any depth, any other value from $over replaces
# the one in $base, and a null in $over removes the key.
def merge($base; $over):
  if ($base | type) == "object" and ($over | type) == "object" then
    reduce ($over | keys_unsorted[]) as $key ($base;
      if $over[$key] == null then del(.[$key]) else .[$key] = merge(.[$key]; $over[$key]) end)
  else $over end;

(if $ARGS.named | has("base") then merge($ARGS.named.base[0]; .) else . end)
| obj as $root
```

`tests/static.sh`: the header comment names five checks. Between the `defaults` and `skills` checks:

```sh
# configs: every project configuration of this repo, .slicewright/<name>.json except *.local.json,
# merged onto the plugin folder's defaults.json the way the runner merges them, checked with the same
# rules as defaults. With no such file, the check passes.
start=$problems
for file in "$repo"/.slicewright/*.json; do
    case $file in
        *.local.json) continue ;;
    esac
    if [ -f "$file" ]; then
        output=$(jq -r --argjson skills "$skills" --slurpfile base "$plugin/defaults.json" -f "$repo/tests/static/defaults.jq" "$file" 2>/dev/null)
        if [ "$?" -eq 0 ]; then
            fail_lines "configs: $file: " "$output"
        else
            fail "configs: $file: does not parse"
        fi
    fi
done
pass_unless_failed configs "$start"
```

`$skills` is the list the `defaults` check built. Output lines: `FAIL configs: <file>: stage <name>: <problem>`, `FAIL configs: <file>: sharedParams: <problem>`, `FAIL configs: <file>: pipeline: missing or empty`, `FAIL configs: <file>: does not parse`; the problems are the ones the testing page lists for `defaults`. `PASS configs` when no line was added, including when the glob matches nothing. `$repo` is the absolute path of the repo the script belongs to, so `<file>` is absolute; `$plugin` is the plugin folder given as the argument (default `plugins/slice`), so the skills and the defaults come from that folder while the configurations come from the script's own repo.

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- the `configs` check, fifth of five (`validate`, `json`, `defaults`, `configs`, `skills`), printing `PASS configs` or `FAIL configs: <absolute path of the .json file>: stage <name>: <problem>` (also `: sharedParams: <problem>`, `: pipeline: missing or empty`, `: does not parse`), the problems worded exactly as `defaults.jq` already words them for the `defaults` check; for a bad skill, `stage <name>: skill "<value>" names no skill folder` → used by T04 (its Verify runs `sh tests/static.sh` and expects `PASS configs` on `.slicewright/research.json`), T05 (the self-test case expects a `FAIL` line containing `research.json: stage research: `, and `static/checker` expects `PASS configs` from a copy with no `.slicewright/`), T06 (the testing page), T07 (AGENTS.md)
- `tests/static/defaults.jq` with an optional base: `jq -r --argjson skills '<JSON list of skill folder names>' --slurpfile base <plugin>/defaults.json -f tests/static/defaults.jq <configuration file>`; without `--slurpfile base` it behaves as today → T06 (the testing page)

**Uses:** what this task relies on, exactly as written, without changing it:

- the `$skills` JSON list the `defaults` check builds, and the helpers `fail`, `fail_lines`, `pass_unless_failed`, and the variables `$repo` and `$plugin`: from `tests/static.sh` in the existing code
- `def obj`, `def names_a_stage($names)` and the rules from `obj as $root` on: from `tests/static/defaults.jq` in the existing code

## Changes

- `tests/static/defaults.jq` (changed)
  - Header comment, lines 1 to 2: say that it checks a configuration object, a plugin's `defaults.json` or a project configuration merged onto it, and prints one `<subject>: <problem>` line per problem; then the two usages: `jq -r --argjson skills '<JSON list of skill folder names>' -f tests/static/defaults.jq <plugin>/defaults.json`, and `jq -r --argjson skills '<JSON list of skill folder names>' --slurpfile base <plugin>/defaults.json -f tests/static/defaults.jq <configuration file>`, which merges the file onto the base with the runner's rule first. Keep line 3, "It never raises an error on a JSON value…".
  - `def merge($base; $over)`, with its two-line comment, inserted after `def names_a_stage($names): …;` and before `obj as $root`, exactly as Contract 7 gives it.
  - The first expression: `obj as $root` becomes `(if $ARGS.named | has("base") then merge($ARGS.named.base[0]; .) else . end)` followed by `| obj as $root`. Everything from `| ($root.sharedParams | obj) as $shared` on is unchanged. Without `--slurpfile base`, `$ARGS.named` has no `base` key, so the `defaults` check's call behaves as today.
- `tests/static.sh` (changed)
  - Header comment, lines 2 to 4: name five checks: `claude plugin validate` on the repo and the plugin folder, every JSON file parses, the pipeline in `defaults.json`, every project configuration of the repo (`.slicewright/<name>.json`, except `*.local.json`) merged onto `defaults.json`, and each skill's frontmatter. The Usage and Exit status lines stay.
  - The `configs` check, inserted between `pass_unless_failed defaults "$start"` and the `# skills:` comment, verbatim from Contract 7. It reuses `$skills`, `$repo`, `$plugin`, `fail`, `fail_lines` and `pass_unless_failed`, all unchanged. An unmatched glob leaves the literal pattern, `[ -f ]` is false, and `PASS configs` prints.
  - Nothing else: no new file under `tests/static/`, no change to the `validate`, `json`, `defaults` or `skills` checks.

## Verify

Run from the repo root. `<S>` is the worker's scratchpad folder. `<SKILLS>` is the literal `'["clarify","configure","consolidate","deploy","design","diagnose","human","implement","intake","new","plan","resume","review","route","run","test","tracking"]'`, the 17 folders that hold a `SKILL.md` before this slice; none of these checks needs the `research` folder T01 adds in the same wave. Scratch files, written with the Write tool first:

- `<S>/bad.json`: `{"pipeline":[{"name":"research","skill":"slice:no-such-skill","executionMode":"fork"}]}`
- `<S>/nullpath.json`: `{"sharedParams":{"activeSlicePath":null},"pipeline":[{"name":"intake","skill":"slice:intake","executionMode":"fork"}]}`
- `<S>/pipeline-only.json`: `{"pipeline":[{"name":"intake","skill":"slice:intake","executionMode":"fork"}]}`
- `<S>/base.json`: `{"sharedParams":{"activeSlicePath":"./slice","agent":{"skill":"slice:plan"}},"pipeline":[{"name":"intake","skill":"slice:intake","executionMode":"fork"}]}`
- `<S>/nullskill.json`: `{"sharedParams":{"agent":{"skill":null}}}`

- `dash -n tests/static.sh`: no output, exit 0.
- `jq -r --argjson skills <SKILLS> -f tests/static/defaults.jq plugins/slice/defaults.json`: prints nothing; the `defaults` call, without a base, is unchanged.
- `jq -r --argjson skills <SKILLS> --slurpfile base plugins/slice/defaults.json -f tests/static/defaults.jq .slicewright/config.json`: prints nothing.
- `jq -r --argjson skills <SKILLS> --slurpfile base plugins/slice/defaults.json -f tests/static/defaults.jq <S>/bad.json`: prints exactly `stage research: skill "slice:no-such-skill" names no skill folder`.
- `jq -r --argjson skills <SKILLS> --slurpfile base plugins/slice/defaults.json -f tests/static/defaults.jq <S>/nullpath.json`: prints exactly `sharedParams: activeSlicePath is missing or empty`; the `null` removed the key the base had.
- `jq -r --argjson skills <SKILLS> --slurpfile base plugins/slice/defaults.json -f tests/static/defaults.jq <S>/pipeline-only.json`: prints nothing, because the base supplied `sharedParams`. Then `jq -r --argjson skills <SKILLS> -f tests/static/defaults.jq <S>/pipeline-only.json`: prints `sharedParams: activeSlicePath is missing or empty`; the no-base path is as today.
- `jq -r --argjson skills <SKILLS> --slurpfile base <S>/base.json -f tests/static/defaults.jq <S>/nullskill.json`: prints nothing. This proves D14: with jq's `*` the key would stay as `null` and the output would be `sharedParams: skill null names no skill folder`.
- `sh tests/static.sh`: lines `PASS validate`, `PASS json`, `PASS defaults`, `PASS configs`, `PASS skills`, then `static: passed`; exit 0; within 60 seconds. Proves AC13's five-checks clause. While other wave-1 workers write `plugins/slice/skills/research/SKILL.md`, `run/SKILL.md` and `configure/SKILL.md` in the same folder, a transient `FAIL skills:` or `FAIL validate:` from a half-written file isn't this task's; this task's evidence is the `configs` lines; rerun when they have finished.
- `sh tests/selftest.sh`: 15 `ok …` or `caught …` lines, `caught static/checker: FAIL skills: …/skills/plan/SKILL.md: …` among them, no `MISSED` line, last line `selftest: passed, 15 cases`, exit 0. The `static/…` cases now also run `configs` on the repo's `config.json` against the copy's skills; none of their breaks changes a skill folder name, so their verdicts hold. The self-test is the project's test of the static checks, so it is this task's own test.
- AC13's no-`.slicewright/` clause, a copy as `static/checker` makes: `mkdir -p <S>/norepo/tests`; `cp -R .claude-plugin <S>/norepo/.claude-plugin`; `cp -R plugins <S>/norepo/plugins`; `cp tests/static.sh <S>/norepo/tests/static.sh`; `cp -R tests/static <S>/norepo/tests/static`; then `sh <S>/norepo/tests/static.sh`: prints `PASS configs` and `static: passed`, exit 0.
- R12's line format and the `*.local.json` exclusion, in the same copy: `mkdir -p <S>/norepo/.slicewright`; `cp <S>/bad.json <S>/norepo/.slicewright/bad.json`; `sh <S>/norepo/tests/static.sh`: prints `FAIL configs: <S>/norepo/.slicewright/bad.json: stage research: skill "slice:no-such-skill" names no skill folder` and `static: failed, 1 problems`, exit 1. Then `mv <S>/norepo/.slicewright/bad.json <S>/norepo/.slicewright/bad.local.json`; `sh <S>/norepo/tests/static.sh`: prints `PASS configs`, exit 0.
- AC13's "smoke.sh still passes" isn't run here: it is too slow for a task, and this task leaves `tests/smoke.sh` and `tests/smoke/` untouched; the test stage runs it.

## Boundaries

Leave alone: `tests/selftest.sh` (T05); `tests/smoke.sh`, `tests/smoke/`, `tests/fixtures/` and `tests/sample/`; `tests/static/skill.awk`; `plugins/slice/` (T01, T02), `plugins/slice/defaults.json`; `.slicewright/config.json`; anything under `.slicewright/stable/` and `.slicewright/slices/`; never create `.slicewright/research.json` (T04); `doc/`, `slice/docs/` (T06); `README.md` and `AGENTS.md` (T07). One jq program, no new file under `tests/static/` (D13). The `defaults` check's call, its output lines and the `skills` check stay as they are; `$skills` is still built once, by the `defaults` check. Exit statuses stay 0, 1 or 2; `PASS <check>` and `FAIL <check>: <subject>: <problem>` only; POSIX sh, `dash -n` clean; no `cd`, no chaining. The check reads only files directly in `$repo/.slicewright/` matching `*.json`, skipping `*.local.json`, and never the `stable/` or `slices/` folders.
