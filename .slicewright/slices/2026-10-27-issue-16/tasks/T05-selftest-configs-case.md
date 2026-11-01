---
id: T05
title: Self-test case for the configs check
type: test
depends: [T03, T04]
covers: [R12, AC13]
---

# T05 Self-test case for the configs check

## Goal

Add the self-test case `static/configs` to `tests/selftest.sh`, make `static/checker` also assert `PASS configs`, and update the script's header comment, so the self-test proves the `configs` check and runs 16 cases.

## Context

### Requirement (the part of R12 for this task)

- **R12** […] `tests/selftest.sh` gets one case that breaks a copy of `research.json`, a stage's `skill` set to a skill with no folder, in a copy of the repo's parts the check needs, and expects a `FAIL` line naming the file and the stage; the self-test's count and table on the testing page change with it. `sh tests/static.sh` and `sh tests/selftest.sh` pass on the working copy at the end of this slice, and `sh tests/smoke.sh` still passes, because the default pipeline is unchanged. (The `static.sh` and `defaults.jq` part of R12 is T03's, already in the code when this task runs.)

### Acceptance criterion (the parts for this task)

- **AC13** (R12) […] Given a copy of the repo's parts the check needs in which `research.json`'s `research` stage has `skill: "slice:no-such-skill"`, when that copy's `static.sh` runs, then it exits 1 with a `FAIL configs:` line that contains `research.json` and `stage research`. Given a copy with no `.slicewright/` folder, when `static.sh` runs on it, then it prints `PASS configs`. When `sh tests/selftest.sh` runs, then it lists the new case as caught and exits 0 within 60 seconds.

### Constraints

- The scripts keep the rules in `doc/architecture/concepts.md`: POSIX `sh` only, `dash -n` clean, exit 0, 1 or 2, one source per value, and a `FAIL` line that names its subject.
- `tests/smoke.sh` and `tests/smoke/` are untouched. Nothing under `.slicewright/stable/` changes.

### Design decision

- **D15 The `static/configs` case copies only `research.json` of `.slicewright/`, and `static/checker` also asserts `PASS configs`.** The new case copies `.claude-plugin`, `plugins`, `tests/static.sh`, `tests/static` and `.slicewright/research.json` into its copy, sets the `research` stage's `skill` to `slice:no-such-skill` with jq, runs the copy's `static.sh`, and expects a `FAIL` line containing `research.json: stage research: `. The `static/checker` case gains one line, `need_line "PASS configs"`, because its copy has no `.slicewright/`: that turns AC13's "no `.slicewright/` folder" clause into a repeatable check without adding a case, so R12's "one case" still holds. Copying the whole `.slicewright/` would bring `stable/`, a worktree, and `slices/`.

### Contract 7, the code for this task

`tests/selftest.sh`: the header comment says a static case breaks a copy of `plugins/slice`, or of the repo's parts a check needs. `static/checker` gains `need_line "PASS configs"` right before its `static_fails` line. After it:

```sh
# static/configs: a project configuration whose stage names no skill folder. The
# configs check reads the configurations from static.sh's own repo, so the case
# copies the manifests, the plugin, the static checks and .slicewright/research.json
# into COPY, breaks the copy's research.json, and runs the copy's static.sh.
begin static/configs
COPY="$W/$SLUG"
step "make the repo copy's tests folder" mkdir -p "$COPY/tests"
step "make the repo copy's .slicewright folder" mkdir -p "$COPY/.slicewright"
step "copy .claude-plugin" cp -R "$REPO/.claude-plugin" "$COPY/.claude-plugin"
step "copy plugins" cp -R "$REPO/plugins" "$COPY/plugins"
step "copy static.sh" cp "$REPO/tests/static.sh" "$COPY/tests/static.sh"
step "copy tests/static" cp -R "$REPO/tests/static" "$COPY/tests/static"
step "copy research.json" cp "$REPO/.slicewright/research.json" "$COPY/.slicewright/research.json"
edit jq '(.pipeline[] | select(.name == "research") | .skill) = "slice:no-such-skill"' "$COPY/.slicewright/research.json" "$REPO/.slicewright/research.json"
if [ -z "$WHY" ]; then
  OUT="$W/$SLUG.out"
  sh "$COPY/tests/static.sh" </dev/null >"$OUT" 2>&1
  STATUS=$?
fi
static_fails 'research.json: stage research: '
report_case
```

16 cases; the last line `selftest: passed, 16 cases`. The script passes `dash -n`. The existing `static/…` cases, which run the repo's `static.sh` on a copy of the plugin, now also check the repo's own `.slicewright/*.json` against the copy's skills; none of their breaks touches a skill folder's name, so their verdicts don't change.

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- the self-test case `static/configs`: its break is stage `research`'s `skill` set to `slice:no-such-skill` in `.slicewright/research.json`, in a copy of the repo's manifests, plugin, static checks and `research.json`, whose own `static.sh` runs; it must show `research.json: stage research`; the `static/checker` case's "Must show" gains `PASS configs`; the count is 16, the last line `selftest: passed, 16 cases` or `selftest: failed, <k> of 16 cases` → used by T06 (the testing page's table and count)

**Uses:** what this task relies on, exactly as written, without changing it:

- `.slicewright/research.json`: a stage named `research` with `"skill": "slice:research"`; the only file of `.slicewright/` the case copies: from T04
- the `configs` check: `tests/static.sh` reads every `.slicewright/*.json` except `*.local.json` of its own repo (`$repo`, the parent of the script's folder) and prints `FAIL configs: <absolute file>: stage <name>: skill "<value>" names no skill folder` for a bad skill, and `PASS configs` when the glob matches nothing: from T03
- the helpers `begin`, `step`, `edit`, `broke`, `differ`, `need_line`, `line_of`, `static_fails`, `report_case`, and the variables `W`, `SLUG`, `REPO`, `COPY`, `OUT`, `STATUS`, `WHY`: from `tests/selftest.sh` in the existing code

## Changes

- `tests/selftest.sh` (changed). Edit it in place with the Edit tool, so its executable bit stays. No new helper, no change to any existing helper, case, break or marker. Three edits:
  - The header comment: the sentence `A static case breaks a copy of plugins/slice.` becomes `A static case breaks a copy of plugins/slice, or of the repo's parts a check needs.`; the next sentence about a smoke case stays; reflow the comment lines. Leave the section banner `# --- Static level: static.sh on a broken copy of plugins/slice ---` as it is.
  - The `static/checker` block: insert the line `need_line "PASS configs"` between the `fi` that closes its `if [ -z "$WHY" ]; then … STATUS=$?` block and `static_fails '/skills/plan/SKILL.md: '`. `static/checker`'s copy has no `.slicewright/`, so the copy's `static.sh` prints `PASS configs` before the `skills` check fails on the broken `skill.awk`; `need_line` is guarded by `[ -z "$WHY" ]` and reads `$OUT`, which that `if` block sets.
  - The new case, after `static/checker`'s `report_case` and before the `# --- Smoke level: … ---` banner: one blank line, then exactly the block from Contract 7. `begin` sets `SLUG=static-configs`, so the copy is `$W/static-configs`; `edit` is the four-argument helper (not `static_edit`, whose original is under `$PLUGIN`): it writes jq's output over the copy's file and `broke differ` checks that it differs from `$REPO/.slicewright/research.json`; the copy's `static.sh` runs with no argument, so its `$repo` is `$COPY`, its plugin `$COPY/plugins/slice`, and its `configs` check reads `$COPY/.slicewright/research.json`; `static_fails` needs `STATUS` 1 and a `FAIL ` line containing the marker, stores it in `LINE`, and `report_case` prints `caught static/configs: <that line>`. `TOTAL` becomes 16, and the end-of-script block already derives the last line from `TOTAL`.

## Verify

Run from the repo root. Preconditions, since the self-test reads the real repo: `grep -n 'pass_unless_failed configs' tests/static.sh` prints one line (T03 is in), and `jq -r '.pipeline[] | select(.name == "research") | .skill' .slicewright/research.json` prints `slice:research` (T04 is in). Until both are, the self-test prints `MISSED static/configs: couldn't copy research.json` and `MISSED static/checker: no line starting with 'PASS configs'`; that tells a missing dependency apart from a wrong edit.

- `dash -n tests/selftest.sh`: prints nothing, exit 0.
- `grep -c '^report_case$' tests/selftest.sh`: `16`.
- `grep -n -B1 "static_fails '/skills/plan/SKILL.md: '" tests/selftest.sh`: two matches, in `static/name` and in `static/checker`; the line before the second one is `need_line "PASS configs"`, and the line before the first is still `static_run`.
- `/usr/bin/time sh tests/selftest.sh`: exit 0, and the `real` figure under 60 seconds. Its output must show, and this proves AC13's self-test clauses:
  - `caught static/configs: FAIL configs: <W>/static-configs/.slicewright/research.json: stage research: skill "slice:no-such-skill" names no skill folder`: the copy's `static.sh` exited 1 with a `FAIL configs:` line containing `research.json` and `stage research`.
  - `caught static/checker: FAIL skills: <W>/static-checker/plugins/slice/skills/plan/SKILL.md: tests/static/skill.awk failed on it` and no `MISSED static/checker` line: the copy with no `.slicewright/` printed `PASS configs`, because `need_line "PASS configs"` would otherwise have marked the case `MISSED`. (`static/checker` reports `caught`, not `ok`, because it ends with `static_fails`; only `static/unbroken` and `smoke/unbroken` print `ok`.)
  - `ok static/unbroken` and `ok smoke/unbroken`, every other case `caught`, no `MISSED` line, no `kept:` line, last line `selftest: passed, 16 cases`.
- Never run `sh tests/smoke.sh` here: it is too slow for a task, and this task leaves it untouched.

## Boundaries

Change only `tests/selftest.sh`. Leave alone: `tests/static.sh`, `tests/static/defaults.jq`, `tests/static/skill.awk` (T03); `.slicewright/research.json`, `.claude/settings.json`, `start-slice.sh` (T04); `README.md`, `AGENTS.md` (T07, in the same wave, in the same folder); `doc/overview/testing.md` and anything under `slice/docs/` (T06: the table row, the `static/checker` row's "Must show" and the count 16 are theirs); `tests/smoke.sh`, `tests/smoke/`, `tests/fixtures/`, `tests/sample/`; everything under `plugins/slice` and `.slicewright/stable/`. No new helper functions and no change to the existing ones or to the end-of-script block; the 15 existing cases keep their names, breaks, markers and verdicts. Keep the script's rules: POSIX sh only, `dash -n` clean, exit 0, 1 or 2, every copy inside `$W`, the work folder removed only when every case passes. One source per value: the case copies `research.json` from `$REPO/.slicewright/`, never a copy kept under `tests/`, and only that one file of `.slicewright/`, never the folder. The case name and slug (`static/configs`, `static-configs`), the marker `research.json: stage research: `, the `PASS configs` line in `static/checker` and the count 16 are interfaces T06 documents: keep them exactly. Keep the file executable.
