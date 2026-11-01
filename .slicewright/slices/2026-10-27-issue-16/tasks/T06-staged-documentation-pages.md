---
id: T06
title: Staged documentation pages
type: documentation
depends: [T01, T03, T04, T05]
covers: [R13, AC14]
---

# T06 Staged documentation pages

## Goal

Stage the two changed documentation pages, `overview/structure.md` and `overview/testing.md`, as whole new pages under `slice/docs/overview/`, describing the research skill, the research pipeline, the script's `--config` option, the static level's fifth check and the self-test's new case.

## Context

### Requirement (the items of R13 for this task)

- **R13** The documentation describes the change: […] 2. `overview/structure.md`, staged: the script's usage with `--config`, `.slicewright/research.json` as the research pipeline, and the research skill among the internal skills. 3. `overview/testing.md`, staged: the static level's five checks, the new self-test case in the table with the new count, and the self-test's description of the case's copy. (Items 1 and 4, `README.md` and `AGENTS.md`, are T07's.)

### Acceptance criterion

- **AC14** (R13) Given the staged documentation, `README.md` and `AGENTS.md`, when a reviewer reads them, then each item of R13 is covered, every stage name, choice, path and command in them matches `research.json`, the skill and the script, and the testing page's self-test count equals the number of cases `selftest.sh` runs.

### Constraints

- A task that changes a page of the project's documentation never changes it in place: it writes the whole new page to `slice/docs/<its path in the documentation>`, and the consolidate stage publishes it. Everything else on each page stays as it is in `doc/overview/`.
- `doc/architecture/building-blocks.md` and `runtime.md` say "four checks" and "Fourteen cases"; they are already stale and outside this slice's scope: leave them alone.

### Contract 8, the staged pages

- `slice/docs/overview/structure.md`: the skills bullet adds that `research`, which answers a spec's questions from sources with cited evidence, isn't in the default pipeline, and that `.slicewright/research.json` runs it. A new bullet: `.slicewright/research.json` is the research pipeline of this repo, loaded with `--config research`; it repeats intake's and release's contexts from `.slicewright/config.json`, because a configuration is loaded instead of `config.json`, not on top of it. The script bullet: `sh start-slice.sh [--config <name>] [<issue number>]` starts the session with `/slice:new`, with `--config <name>` and the issue number when given, after checking that `.slicewright/<name>.json` exists; `--config research` runs the research pipeline.
- `slice/docs/overview/testing.md`: "Its five checks, in order", with `configs` after `defaults`: every `.slicewright/<name>.json` of the repo, except `*.local.json`, merged onto the folder's `defaults.json` the way the runner merges configurations (objects key by key, any other value replaced, `null` removes a key), and checked with the same rules as `defaults`, by `tests/static/defaults.jq` with the defaults as its base; each problem names the file and the stage, `FAIL configs: <file>: stage <name>: <problem>`; with no such file, the check passes. The self-test bullets: `static/configs` breaks a copy of `.slicewright/research.json`; the check reads the configurations from `static.sh`'s own repo, so the case copies the manifests, the plugin, the static checks and `research.json`, and runs the copy's `static.sh`. The `static/checker` row's "Must show" adds `PASS configs`, because its copy has no `.slicewright/`. The new row: `static/configs` | stage `research`'s `skill` set to `slice:no-such-skill` in `.slicewright/research.json`, in a copy of the repo's manifests, plugin, static checks and `research.json`, whose own `static.sh` runs | `research.json: stage research`. "The 16 cases", `selftest: passed, 16 cases` and `failed, <k> of 16 cases`. "Adding a static check", step 1: a rule in `defaults.jq` applies to the defaults and to every project configuration.

## Interfaces

**Uses:** what this task relies on, exactly as written, without changing it:

- the skill folder `plugins/slice/skills/research/SKILL.md`, an internal skill with `name: research` and `user-invocable: false`; the stage `slice:research` answers the questions of a spec from sources with cited evidence and a confidence, and writes `research.md`: from T01
- the static level's five checks in order, `validate`, `json`, `defaults`, `configs`, `skills`; the `configs` check reads every `.slicewright/<name>.json` of the repo that `static.sh` belongs to, except `*.local.json`, merged onto the given plugin folder's `defaults.json` by `tests/static/defaults.jq` called with `--slurpfile base <plugin>/defaults.json` (objects key by key at any depth, any other value replaced, `null` removes a key), checked with the same rules as `defaults`; lines `PASS configs` and `FAIL configs: <file>: stage <name>: <problem>` (also `: sharedParams: <problem>`, `: pipeline: missing or empty`, `: does not parse`); with no such file the check passes: from T03
- `.slicewright/research.json`, the research pipeline of this repo, `pipeline` only, stages `intake`, `clarify`, `questions-review`, `research`, `results-review`, `file-issues`, `consolidate`, `release`, loaded with `/slice:new --config research`, with intake's and release's contexts equal to `config.json`'s; `start-slice.sh` usage `sh start-slice.sh [--config <name>] [<issue number>]`, which with `--config <name>` checks that `.slicewright/<name>.json` exists after the stable plugin validates and starts Claude with `/slice:new --config <name>` plus the issue number when given: from T04
- the self-test case `static/configs` (break: stage `research`'s `skill` set to `slice:no-such-skill` in `.slicewright/research.json`, in a copy of the repo's manifests, plugin, static checks and `research.json`, whose own `static.sh` runs; must show `research.json: stage research`); `static/checker` must also show `PASS configs`; 16 cases; last line `selftest: passed, 16 cases` or `selftest: failed, <k> of 16 cases`: from T05
- the published pages `doc/overview/structure.md` and `doc/overview/testing.md`, and their conventions (frontmatter `type: overview`, bullets, the cases table, the "Adding a static check" steps): from the existing documentation

## Changes

Both files are new, under `slice/docs/overview/` (create the folder). Each is the whole published page from `doc/overview/`, copied byte for byte (frontmatter `---`, `type: overview`, `---`, same trailing newline), with only the changes below. Write them with the Write tool.

- `slice/docs/overview/structure.md` (new; three bullets touched)
  - The skills bullet, `- `plugins/slice/skills/<name>/SKILL.md`: …`, keeps its text and gets one more sentence at the end: `research`, which answers a spec's questions from sources with cited evidence, isn't in the default pipeline: `.slicewright/research.json` runs it.
  - A new bullet right after it, before the `start-slice.sh` bullet: `.slicewright/research.json`: the research pipeline of this repo, loaded with `--config research`. It repeats intake's and release's contexts from `.slicewright/config.json`, because a configuration is loaded instead of `config.json`, not on top of it.
  - The script bullet: its first two sentences stay (prepares the working copy, switches to `master`, fast-forwards, the `.slicewright/stable/` worktree, validates the plugin there). Its last sentence, "`sh start-slice.sh <issue number>` starts the session with `/slice:new <issue number>`", becomes: `sh start-slice.sh [--config <name>] [<issue number>]` starts the session with `/slice:new`, with `--config <name>` and the issue number when given, after checking that `.slicewright/<name>.json` exists. `--config research` runs the research pipeline.
  - Everything else unchanged: the first three bullets, the whole `tests/` bullet and its sub-bullets.
- `slice/docs/overview/testing.md` (new; eight places touched)
  - `Its four checks, in order:` becomes `Its five checks, in order:`.
  - After the `defaults` bullet and before `skills`, a new bullet: `configs`: every `.slicewright/<name>.json` of the repo, except `*.local.json`, merged onto the folder's `defaults.json` the way the runner merges configurations: objects key by key, any other value replaced, and `null` removes a key. The result is checked with the same rules as `defaults`, by `tests/static/defaults.jq` with the defaults as its base. Each problem names the file and the stage, `FAIL configs: <file>: stage <name>: <problem>`. With no such file, the check passes.
  - The self-test bullet on the `static/…` cases: between the `static/checker` sentence and "A broken case must exit 1 …", add: `static/configs` breaks a copy of `.slicewright/research.json`: the `configs` check reads the configurations from `static.sh`'s own repo, so the case copies the manifests, the plugin, the static checks and `research.json`, and runs the copy's `static.sh`.
  - `The 15 cases:` becomes `The 16 cases:`.
  - The `static/checker` row: its "Must show" cell becomes `/skills/plan/SKILL.md`, and `PASS configs`, because its copy has no `.slicewright/`. The Case and Break cells stay.
  - A new row right after it, before `smoke/unbroken`: `| `static/configs` | stage `research`'s `skill` set to `slice:no-such-skill` in `.slicewright/research.json`, in a copy of the repo's manifests, plugin, static checks and `research.json`, whose own `static.sh` runs | `research.json: stage research` |`.
  - The Output line: `selftest: passed, 15 cases` becomes `16 cases`, and `failed, <k> of 15 cases` becomes `of 16 cases`.
  - "Adding a static check", step 1: append one sentence after "Each line that `defaults.jq` or `skill.awk` prints becomes a `FAIL` line of its check.": A rule in `defaults.jq` applies to the defaults and to every project configuration.
  - Everything else unchanged: the static level's intro sentence and its Why, Output and Exit paragraphs, the `validate`, `json`, `defaults` and `skills` bullets, the smoke bullet, the other 14 rows, the fixture, the smoke level, "Where they run", cost, the sample, the run copy, the test configuration, isolation, the eight checks, steps 2 and 3.

## Verify

Run from the repo root. The two test runs need T03, T04 and T05 in the working copy, which the dependencies guarantee.

- `sed -n '1,3p' slice/docs/overview/structure.md` and `sed -n '1,3p' slice/docs/overview/testing.md`: each shows `---`, `type: overview`, `---`.
- `diff doc/overview/structure.md slice/docs/overview/structure.md`: exit 1 with exactly one hunk, `12,13c12,14`: the two `<` lines are the published skills and script bullets, the three `>` lines are the new skills bullet, the `.slicewright/research.json` bullet and the new script bullet; no `\ No newline at end of file`.
- `diff doc/overview/testing.md slice/docs/overview/testing.md`: exit 1 with only these hunks, in order: `17c17` (five checks), `21a22` (the `configs` bullet), `40c41` (the static cases bullet), `46c47` (16 cases), `58c59,60` (the `static/checker` row and the new `static/configs` row), `66c68` (the Output line), and one hunk on step 1 under "Adding a static check". Nothing else.
- AC14, the five checks: `sh tests/static.sh` prints `PASS validate`, `PASS json`, `PASS defaults`, `PASS configs`, `PASS skills`, in that order, then `static: passed`, exit 0. `grep -n -E '^- `(validate|json|defaults|configs|skills)`' slice/docs/overview/testing.md` prints five lines in the same order. `grep -n 'five checks' slice/docs/overview/testing.md` prints line 17; `grep -c 'four checks' slice/docs/overview/testing.md` prints `0`.
- AC14, the `configs` bullet matches the code: `grep -n 'slurpfile base' tests/static.sh` shows the `configs` call with `--slurpfile base "$plugin/defaults.json"`; `grep -n 'null' tests/static/defaults.jq` shows the merge removing a key on `null`; `grep -n 'local.json' tests/static.sh` shows the `*.local.json` exclusion; `grep -n '"configs: ' tests/static.sh` shows the `FAIL configs: <file>: ` prefix.
- AC14, the self-test count and case: `sh tests/selftest.sh` prints a `caught static/configs: FAIL configs: …/.slicewright/research.json: stage research: …` line and ends with `selftest: passed, 16 cases`, exit 0. `grep -c 'report_case$' tests/selftest.sh` prints `16`. `grep -n '16 cases' slice/docs/overview/testing.md` prints two lines (`The 16 cases:` and the Output line); `grep -c '15 cases' slice/docs/overview/testing.md` prints `0`.
- AC14, the new row and the checker row: `grep -n 'static/configs' slice/docs/overview/testing.md` prints two lines (the bullet and the row), the row holding `slice:no-such-skill`, `.slicewright/research.json` and `research.json: stage research`. `grep -n "static_fails 'research.json: stage research: '" tests/selftest.sh` prints one line (the marker the row names). `grep -n 'PASS configs' slice/docs/overview/testing.md` prints the `static/checker` row, and `grep -n 'need_line "PASS configs"' tests/selftest.sh` prints one line in that case. `grep -n 'copy research.json' tests/selftest.sh` prints the copy step the bullet describes.
- AC14, stage names: `jq -r '[.pipeline[].name] | join(", ")' .slicewright/research.json` prints `intake, clarify, questions-review, research, results-review, file-issues, consolidate, release`; the only stage names the pages use, `intake`, `release` and `research`, are in it. `jq -r '.pipeline[] | select(.name == "intake" or .name == "release") | .params.context' .slicewright/research.json` and the same command on `.slicewright/config.json` print the same two texts (the "repeats intake's and release's contexts" sentence).
- AC14, the skill: `sed -n '1,4p' plugins/slice/skills/research/SKILL.md` shows `name: research` and `user-invocable: false`; `grep -n 'research' slice/docs/overview/structure.md` prints the three bullets that name it.
- AC14, the script: `sed -n '/^# Usage:/p' start-slice.sh` prints `# Usage: sh start-slice.sh [--config <name>] [<issue number>]`; `grep -n 'sh start-slice.sh' slice/docs/overview/structure.md` prints the script bullet with the same usage; `grep -c 'sh start-slice.sh <issue number>' slice/docs/overview/structure.md` prints `0`. `grep -n 'config_file=' start-slice.sh` shows the `.slicewright/<name>.json` file the bullet says is checked.
- Nothing in place: `git status --short doc README.md AGENTS.md` prints nothing.

## Boundaries

Never change `doc/` in place: not `overview/structure.md`, `overview/testing.md`, `overview/index.md` (the pages aren't new, so the index needs nothing), `index.md` or `log.md`; the consolidate stage publishes the staged pages. `doc/architecture/building-blocks.md` and `doc/architecture/runtime.md` are already stale and stay out of scope: no staged copy of them. `README.md` and `AGENTS.md` belong to T07. No other file under `slice/docs/`, and no `.delete` file. No change to `tests/`, `start-slice.sh`, `.slicewright/`, `.claude/settings.json` or `plugins/`: this task writes only the two staged pages. On each page, only the listed lines change; the static level's intro sentence ("checks a plugin folder without a model"), its Why paragraph and the `defaults` bullet stay as published; the pages don't list the research pipeline's eight stages or its choices (the README does, T07) and name only `intake`, `release` and `research`. Frontmatter stays `type: overview` with no other key.
