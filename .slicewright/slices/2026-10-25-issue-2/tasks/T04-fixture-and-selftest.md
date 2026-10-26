---
id: T04
title: Finished-run fixture and self-test
type: test
depends: [T01, T02, T03]
covers: [R1, R10, AC3, AC7, AC14]
---

# T04 Finished-run fixture and self-test

## Goal

This task adds two things:

- the finished-run fixture, an overlay on the sample that stands for what a passing smoke run leaves;
- `sh tests/selftest.sh`, which breaks one thing at a time in temporary copies, and shows that the static checks and the smoke checks catch each case without a Claude session.

## Context

From spec.md:

- **R1** Every test, fixture and sample project lives under `tests/` at the repo root. No file under `plugins/slice/` or `.slicewright/stable/` changes.
- **R10** The tests' own checks have a self-test: one command, run from the repo root, that starts no Claude session and finishes within 60 seconds.
  - For each broken case in AC3, it makes a copy of `plugins/slice` with that one thing broken and runs the static command on it.
  - For each broken case in AC7, it makes a copy of a finished-run fixture kept under `tests/`, breaks that one thing, and evaluates the smoke checks on it.
  - It exits zero only when every case fails with its check named, and the unbroken fixture passes every check except 1 and 2, which need a real session.
- **AC3** Given a copy of `plugins/slice` with exactly one thing broken, when the static command runs on that copy, then it exits non-zero and its output names the broken stage, skill or file. This holds for each of these cases on its own:
  - a stage's `next` naming no stage
  - a `choices` value naming no stage
  - two stages with the same name
  - a stage's `skill` naming no skill folder
  - a `SKILL.md` whose `name` differs from its folder
  - an internal skill without `user-invocable: false`
  - a JSON file that doesn't parse
- **AC7** Given a copy of the finished-run fixture with exactly one thing broken, when the smoke checks are evaluated on that copy, then the command exits non-zero and names that check, without starting a headless run. This holds for each of these cases on its own:
  - a stage row set to `failed` in `status.md`
  - a record removed from `slice/`
  - a change that breaks the acceptance check
  - an uncommitted file outside `slice/`
  - the records index entry removed
- **AC14** Given the working copy at the end of this slice, when the self-test command runs from the repo root, then it exits zero within 60 seconds, starts no Claude session, and lists each case of AC3 and AC7 as caught.

From design.md:

- **D1** POSIX sh only: no `local`, arrays, `[[ ]]`, `sed -i` or `grep -r`. Run as `sh tests/selftest.sh`, with no executable bit.
- **D2** The self-test builds its fixture with `smoke.sh prepare` and evaluates it with `smoke.sh check`, the code a real run uses.
- **D14** The fixture is an overlay on the sample. It holds only what a passing run adds or changes. The self-test copies the sample, lays the overlay on top, and runs `smoke.sh prepare` on the result. Breaking the acceptance check is then simple: put the sample's own `greet.sh` back and commit. Only check 6 fails.
- **D15** The fixture has no `.gitignore` and no `.slicewright/smoke.json`, because `prepare` writes both. The repo's own ignore rule, `/slice/`, is anchored to the root. So `tests/fixtures/finished-run/slice/` is tracked, and it is committed with this task like any other file.
- **Risks:**
  - The self-test deletes files, so it removes only the non-empty path that its own `mktemp -d` returned, and keeps the folder on any failure.
  - Bash-only syntax may slip in, so run `dash -n` and `dash tests/selftest.sh`.
  - The fixture may drift from what tracking and consolidate really write. So follow their formats in `plugins/slice/skills/tracking/SKILL.md` and in section 4 of `plugins/slice/skills/consolidate/SKILL.md`.
- **Contract: the fixture `tests/fixtures/finished-run/`**, an overlay on `tests/sample/project/`:
  - `greet.sh` with the feature.
  - `doc/product/spec/greeting.md`, which mentions `--shout`.
  - `slice/status.md`, whose frontmatter has `title: Add a --shout option`, `stage: consolidate`, `status: done`, an empty `next:`, `config: smoke.json` and `created: 2026-01-01T10:00:00Z`. It has seven `done` rows, in pipeline order, and a Log.
  - `slice/input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md`, each with a heading and one line saying that it stands in for a run's record.
  - `.slicewright/slices/index.md`: `# Slices`, then `## 2026-01-01 add-a-shout-option: Add a --shout option` and the entry's lines.
  - No `.gitignore` and no `.slicewright/smoke.json`.
- **The request the fixture's `greet.sh` carries out** (`tests/sample/request.md`, written by T02):
  - `--shout Ada` prints `HELLO, ADA!` and exits 0.
  - `--shout` alone, or with an empty name, prints `HELLO, WORLD!` and exits 0.
  - The option counts only as the first argument, followed by at most one name. `--shout Ada Bob` and `Ada --shout` both print `greet: too many arguments` on stderr and exit 2.
  - After `--shout`, an argument starting with `-` is an unknown option: `--shout -x` prints `greet: unknown option: -x` and exits 2.
  - Only the letters a to z become A to Z: `--shout ada-lovelace_42` prints `HELLO, ADA-LOVELACE_42!`.
  - Without the option, nothing changes, and other arguments starting with `-` are still unknown options.
- **Contract: the self-test `sh tests/selftest.sh`**
  - It takes no arguments.
  - It works in `mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX"`. When every case passes, it removes that folder, and only that one. Otherwise it keeps it and prints `kept: <folder>`.
  - Each break is checked to have changed something; when it hasn't, the case is `MISSED`.
  - Files are edited with jq or sed into a temporary file, then `mv`.
  - Commits use `git -C`.

  | Case | Break | Must show |
  |---|---|---|
  | `static/unbroken` | none | exit 0 |
  | `static/next` | stage `implement`: `next` set to `no-such-stage` | exit ≠ 0, and a FAIL line with `stage implement` |
  | `static/choice` | `design-review`: `choices.approve` set to `no-such-stage` | `stage design-review` |
  | `static/duplicate` | stage `clarify` renamed to `intake` | `stage intake` |
  | `static/skill` | `deploy`: `skill` set to `slice:no-such-skill` | `stage deploy` |
  | `static/name` | `skills/plan/SKILL.md`: `name: planner` | `skills/plan/SKILL.md` |
  | `static/user-invocable` | the `user-invocable: false` line removed from `skills/review/SKILL.md` | `skills/review/SKILL.md` |
  | `static/json` | `.claude-plugin/plugin.json` made unparseable | `.claude-plugin/plugin.json` |
  | `smoke/unbroken` | none | FAIL 1 and FAIL 2, PASS 3 to 8 |
  | `smoke/stage-failed` | the `review` row's status set to `failed` | FAIL 3; checks 4 to 8 pass |
  | `smoke/record-removed` | `slice/plan.md` deleted | FAIL 4; 3 and 5 to 8 pass |
  | `smoke/acceptance` | the sample's `greet.sh` copied over the fixture's, then committed | FAIL 6; 3 to 5, 7 and 8 pass |
  | `smoke/uncommitted` | an untracked `notes.txt` | FAIL 7; 3 to 6 and 8 pass |
  | `smoke/index-entry` | `index.md` reduced to `# Slices`, then committed | FAIL 8; 3 to 7 pass |

  - **Output:** one line per case: `ok <case>`, `caught <case>: <the matching line>`, or `MISSED <case>: <why>` followed by the case's output, indented. The last line is `selftest: passed, 14 cases` or `selftest: failed, <k> of 14 cases`.
  - **Exit status:** 0, 1, or 2 when a tool is missing.
- **Plan decisions:**
  - A broken static case requires exit 1, which is stricter than "≠ 0", because exit 2 means `static.sh` couldn't run.
  - The index entry's Records line names the folder that consolidate creates, `2026-01-01-add-a-shout-option/`. Check 8 reads only the heading line.

## Interfaces

**Provides:**

- `sh tests/selftest.sh`: it takes no arguments and starts no Claude session. → used by T05, T06
  - It prints one line per case: `ok <case>`, `caught <case>: <the matching line>` or `MISSED <case>: <why>`.
  - The last line is `selftest: passed, 14 cases` or `selftest: failed, <k> of 14 cases`.
  - Exit 0 when every case passes, 1 when any is missed, 2 when a tool is missing.
- `tests/fixtures/finished-run/`: the overlay on `tests/sample/project/` → used by T05

**Uses:**

- `sh tests/static.sh [<plugin folder>]`: from T01.
  - It prints `PASS <check>`, or one `FAIL <check>: <subject>: <problem>` line per problem, and the last line is `static: passed` or `static: failed, <n> problems`.
  - The subjects are `stage <name>`, `sharedParams`, `pipeline`, or an absolute file path under the given folder, such as `<folder>/skills/plan/SKILL.md` or `<folder>/.claude-plugin/plugin.json`.
  - A failed validation adds lines indented by two spaces.
  - Exit 0 all pass, 1 any fails, 2 when the folder, `claude` or `jq` is missing.
  - It always validates the real repo, the parent of its own folder, as well as the given folder. A copy of `plugins/slice` outside any git repo validates with only a warning.
- `tests/sample/project/`: from T02. It has no `.gitignore` and no `.slicewright/`, and holds:
  - `greet.sh`, with usage `sh greet.sh [name]`:
    - It prints `Hello, <name>!`, or `Hello, world!` with no name or an empty one, and exits 0.
    - A first argument starting with `-` prints `greet: unknown option: <arg>` on stderr and exits 2. This is checked first.
    - More than one argument prints `greet: too many arguments` on stderr and exits 2.
  - `test.sh`, run as `sh test.sh` in the project folder. Its tests never use `--shout`; the unknown-option test uses `-x`.
  - `doc/product/spec/greeting.md`, with `type: spec` frontmatter, and sections Usage, the name and its default, Errors, Exit statuses and Limitations. It doesn't mention `--shout`.
- `sh tests/sample/accept.sh <project folder>`: from T02.
  - Its cases:
    - `--shout Ada` → `HELLO, ADA!`, 0
    - `--shout` → `HELLO, WORLD!`, 0
    - `--shout Ada Bob` → `greet: too many arguments`, empty stdout, 2
    - `Ada` → `Hello, Ada!`
    - `-x` → `greet: unknown option: -x`, 2
    - `--shout ada-lovelace_42` → `HELLO, ADA-LOVELACE_42!`
    - some `*.md` under `doc/` mentions `--shout`
  - Exit 0 all pass, 1 any fails, 2 when the folder or its `greet.sh` is missing.
- `sh tests/smoke.sh prepare <source folder> <run folder>`: from T03.
  - It copies the source to `<run>/project` and writes `<run>/project/.slicewright/smoke.json`, with the seven stages intake, clarify, design, plan, implement, review and consolidate generated from `plugins/slice/defaults.json`.
  - It appends `/slice/` to `<run>/project/.gitignore`, then makes the copy a git repository with a local identity and one commit of everything.
  - The run folder must not exist, its parent must exist, and it must be outside the repo.
  - It prints `prepared: <run>/project` and `run: <run>`, and exits 0 or 2.
- `sh tests/smoke.sh check <run folder>`: from T03.
  - It evaluates the eight checks on the files in `<run>`, and writes nothing there.
  - It prints `PASS|FAIL <n> <name>: <detail>` for n = 1 to 8, with the names `session`, `isolation`, `status`, `records`, `tests`, `acceptance`, `clean-tree` and `index`. Then it prints `cost_usd:`, `duration_ms:`, `result: passed` or `result: failed, <k> of 8 checks failed`, and last `run: <run>`.
  - Exit 0, 1, or 2 when the folder has no `project/`.
  - Without a session, checks 1 and 2 always fail, so `check` exits 1 on every fixture case.
  - What checks 3 to 8 read:
    - Check 3 takes the stage names from `project/.slicewright/smoke.json`. Each must be a row of the `## Stages` table in `project/slice/status.md`, once, with the status `done`, and no other row may appear. It also needs `status: done` and an empty `next:`. The first cell of a row is the stage and the second its status.
    - Check 4: each of `input.md spec.md design.md plan.md implement.md code-reviews.md` exists in `project/slice/` and isn't empty.
    - Check 5: `sh test.sh` passes in a scratch copy.
    - Check 6: `sh <repo>/tests/sample/accept.sh <scratch copy>` passes.
    - Check 7: `git -C project status --porcelain --untracked-files=all` shows nothing outside `slice/`.
    - Check 8: `project/.slicewright/slices/index.md` has a line starting with `## <first 10 characters of created in status.md> `.

## Changes

- `tests/selftest.sh` (new): POSIX sh, run as `sh tests/selftest.sh` with no arguments.
  - **Layout.** Keep each case's break and its expected result in one block, because the testing page tells readers how to add a case.
  - **Repo root.** The parent of the script's own folder, as in `static.sh`.
  - **Tool check.** Use `command -v` for `claude`, `jq`, `git`, `mktemp` and `cmp`. When one is missing, print `selftest: <tool> is missing` on stderr and exit 2. When `mktemp -d` fails or returns an empty path, exit 2 too.
  - **Work folder.** `W=$(mktemp -d "${TMPDIR:-/tmp}/slicewright-selftest.XXXXXX")`. Every copy, temporary file and run folder goes inside `$W`.
  - **Editing.**
    - Edit with jq or sed into a temporary file in `$W`, then `mv`.
    - Never use `sed -i`, `local`, arrays, `[[ ]]` or `grep -r`.
    - No `set -e`: the script reads every exit status itself. Pipes and redirections inside the script are fine.
  - **Static cases.** For each case:
    1. `cp -R "$REPO/plugins/slice" "$W/<new folder>"`.
    2. Apply the one break.
    3. Check that the break changed something with `cmp -s` against the same file in `$REPO/plugins/slice`. `jq .` rewrites `defaults.json` byte for byte, so a jq edit that matched nothing compares equal. When nothing changed, the case is `MISSED <case>: the break changed nothing`.
    4. Run `sh "$REPO/tests/static.sh" <copy> </dev/null`, and capture stdout, stderr and the exit status.
    5. Judge it:
       - `static/unbroken` needs exit 0.
       - A broken case needs exit 1, and a line that starts with `FAIL ` and contains its marker. Exit 2 means `static.sh` couldn't run: the case is `MISSED`.
       - Match the end of a path, never the whole path, because `static.sh` may print the folder resolved another way.

    The breaks and their markers:
    - `static/next`: `jq '(.pipeline[] | select(.name == "implement") | .next) = "no-such-stage"'` on `defaults.json`. Marker `: stage implement: `. The trailing colon keeps it from matching `stage implement-decision`.
    - `static/choice`: `jq '(.pipeline[] | select(.name == "design-review") | .params.choices.approve) = "no-such-stage"'`. Marker `: stage design-review: `.
    - `static/duplicate`: `jq '(.pipeline[] | select(.name == "clarify") | .name) = "intake"'`. Marker `: stage intake: `. No `next`, `onError` or `choices` names `clarify`, so the duplicate is the only problem.
    - `static/skill`: `jq '(.pipeline[] | select(.name == "deploy") | .skill) = "slice:no-such-skill"'`. Marker `: stage deploy: `.
    - `static/name`: `sed 's/^name: plan$/name: planner/'` on `skills/plan/SKILL.md`, where line 2 is the only match. Marker `/skills/plan/SKILL.md: `.
    - `static/user-invocable`: `sed '/^user-invocable: false$/d'` on `skills/review/SKILL.md`, where line 4 is the only match. Marker `/skills/review/SKILL.md: `.
    - `static/json`: `sed '$d'` on `.claude-plugin/plugin.json`, which drops its closing `}`. Marker `/.claude-plugin/plugin.json: `.
      - The validation fails too, and adds a `FAIL validate:` line.
      - The case matches the `FAIL json:` line by its path. The validator's indented lines never start with `FAIL`.
  - **Smoke source.** Build it once:
    - `cp -R "$REPO/tests/sample/project" "$W/source"`.
    - Then `cp -R "$REPO/tests/fixtures/finished-run/." "$W/source"`. The `/.` form merges into `doc/` and brings the hidden `.slicewright/`. A `*` glob would miss it.
    - When either copy fails, every smoke case is `MISSED`, with the reason.
  - **Smoke cases.** For each case:
    1. Run `sh "$REPO/tests/smoke.sh" prepare "$W/source" "$W/<new run folder>"`, with a new run folder for each case. When it doesn't exit 0, the case is `MISSED`, with prepare's output.
    2. Apply the break in `<run>/project`, and check that it changed something.
    3. Run `sh "$REPO/tests/smoke.sh" check <run> </dev/null`.
    4. Judge it. The exit must be 1; 2 means "not a run folder", which is `MISSED`. The expected `FAIL <n> <name>:` line must be there, with a `PASS <n> <name>:` line for each other check from 3 to 8.

    The breaks:
    - `smoke/unbroken`: no break. It needs `FAIL 1 session:`, `FAIL 2 isolation:` and PASS for 3 to 8, and prints `ok`.
    - `smoke/stage-failed`: `sed 's/^| review | done |/| review | failed |/'` on `slice/status.md`. A bare `|` is a literal in a basic regex. Check the change with `cmp -s` against the fixture's file. No commit is needed, because `slice/` is ignored. Expect FAIL 3.
    - `smoke/record-removed`: `rm` `slice/plan.md`, then check that it is gone with `[ ! -e ]`. Expect FAIL 4.
    - `smoke/acceptance`:
      - First check with `cmp -s` that the fixture's `greet.sh` differs from the sample's.
      - Copy `$REPO/tests/sample/project/greet.sh` over the project's `greet.sh`.
      - Run `git -C <project> add greet.sh`, then `git -C <project> commit -q -m "<message>"`. The commit uses the local identity that `prepare` set.
      - Expect FAIL 6.
    - `smoke/uncommitted`: write `notes.txt` in the project root, and check that it exists. Expect FAIL 7.
    - `smoke/index-entry`:
      - Write `# Slices` to a temporary file in `$W`, and `mv` it over `.slicewright/slices/index.md`.
      - Check with `cmp -s` that it changed.
      - Then `git -C` add and commit.
      - Expect FAIL 8.
  - **Output.** One line per case, in table order: `ok <case>`, `caught <case>: <the matching FAIL line>`, or `MISSED <case>: <why>` followed by the case's captured output, indented by two spaces.
  - **The end:**
    - When any case was missed, print `kept: <W>`, then `selftest: failed, <k> of 14 cases`, and exit 1.
    - Otherwise, `rm -rf "$W"`, but only after checking that it is non-empty, is the value `mktemp` returned, and matches `*/slicewright-selftest.*`. Then print `selftest: passed, 14 cases`, and exit 0.
  - **No session.** It never calls `claude` except in the tool check, and never runs `smoke.sh` with any subcommand but `prepare` and `check`.
- `tests/fixtures/finished-run/greet.sh` (new): start from `tests/sample/project/greet.sh` and add only the option.
  - When the first argument is exactly `--shout`, drop it and remember that it was there.
  - Apply the sample's own rules, unchanged and in the same order, to the remaining arguments.
  - With the option, print the greeting through `tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'`.

  This gives every behavior of the request in Context. The file must still pass the sample's `test.sh`, and must differ from the sample's `greet.sh`.
- `tests/fixtures/finished-run/doc/product/spec/greeting.md` (new): the sample's page, with its `type: spec` frontmatter, plus `--shout`:
  - the usage `sh greet.sh [--shout] [name]`;
  - "first argument only, with at most one name after it";
  - "only a to z become A to Z" under Limitations.
- `tests/fixtures/finished-run/slice/status.md` (new): in the tracking format. It has no `id` or `source` line, because the request has neither. The Artifact cell is relative to `slice/`. `next:` has nothing after it. Write this text, with one `started` line and one `done` line for each stage in the Log:

  ```markdown
  ---
  title: Add a --shout option
  stage: consolidate
  status: done
  next:
  config: smoke.json
  created: 2026-01-01T10:00:00Z
  updated: 2026-01-01T11:10:30Z
  ---

  # Add a --shout option

  ## Stages

  | Stage | Status | Artifact | Started | Finished | Time | Tokens |
  |---|---|---|---|---|---|---|
  | intake | done | input.md | 2026-01-01T10:00:00Z | 2026-01-01T10:01:00Z | 1m | — |
  | clarify | done | spec.md | 2026-01-01T10:01:05Z | 2026-01-01T10:06:05Z | 5m | — |
  | design | done | design.md | 2026-01-01T10:06:10Z | 2026-01-01T10:16:10Z | 10m | — |
  | plan | done | plan.md | 2026-01-01T10:16:15Z | 2026-01-01T10:26:15Z | 10m | — |
  | implement | done | implement.md | 2026-01-01T10:26:20Z | 2026-01-01T10:46:20Z | 20m | — |
  | review | done | code-reviews.md | 2026-01-01T10:46:25Z | 2026-01-01T10:56:25Z | 10m | — |
  | consolidate | done | ../.slicewright/slices/index.md | 2026-01-01T10:56:30Z | 2026-01-01T11:10:30Z | 14m | — |

  ## Log

  - 2026-01-01T10:00:00Z intake started
  - 2026-01-01T10:01:00Z intake done: input.md → clarify
  - …
  - 2026-01-01T11:10:30Z consolidate done: ../.slicewright/slices/index.md
  ```

  Each stage's `done` line ends with `→ <next stage>`, except consolidate's, because no stage follows it.
- `tests/fixtures/finished-run/slice/input.md`, `spec.md`, `design.md`, `plan.md`, `implement.md` and `code-reviews.md` (new): each has its heading (`# Input`, `# Spec`, `# Design`, `# Plan`, `# Implement`, `# Code reviews`), a blank line, and one line: `Stands in for the <file> that a finished smoke run leaves in slice/, for tests/selftest.sh.`
- `tests/fixtures/finished-run/.slicewright/slices/index.md` (new):

  ```markdown
  # Slices

  ## 2026-01-01 add-a-shout-option: Add a --shout option

  - Areas: greet.sh
  - Pages: doc/product/spec/greeting.md
  - Decisions: none
  - Accepted: none
  - Root causes: none
  - Records: 2026-01-01-add-a-shout-option/
  ```

## Verify

Run each command from the repo root.

- `dash -n tests/selftest.sh`: no output, exit 0.
- `dash -n tests/fixtures/finished-run/greet.sh`: no output, exit 0.
- `sh tests/sample/accept.sh tests/fixtures/finished-run`: only `ok` lines, and exit 0. The overlay alone holds the `greet.sh` and the `doc/` page that `accept.sh` reads.
- `sh tests/fixtures/finished-run/greet.sh --shout -x`: `greet: unknown option: -x`, exit 2.
- `sh tests/fixtures/finished-run/greet.sh Ada --shout`: `greet: too many arguments`, exit 2.
- **AC3, AC7, AC14, R10.** `sh tests/selftest.sh`: exit 0. There are 14 lines in table order, and no `MISSED` or `kept:` line. Then the last line, `selftest: passed, 14 cases`. The 14 lines:
  - `ok static/unbroken`;
  - seven `caught static/…` lines, whose FAIL lines name `stage implement`, `stage design-review`, `stage intake`, `stage deploy`, `…/skills/plan/SKILL.md`, `…/skills/review/SKILL.md` and `…/.claude-plugin/plugin.json`;
  - `ok smoke/unbroken`, which shows that checks 3 to 8 pass on the unbroken fixture;
  - five `caught smoke/…` lines, with `FAIL 3 status:`, `FAIL 4 records:`, `FAIL 6 acceptance:`, `FAIL 7 clean-tree:` and `FAIL 8 index:`.
- `dash tests/selftest.sh`: the same output.
- **AC14's time limit.** `/usr/bin/time -p sh tests/selftest.sh`: `real` below 60.
- `grep -n -E 'claude( |$)' tests/selftest.sh`: only the tool check's `command -v claude`, and any comment or message. There is no `claude -p` and no other `claude` call. The pattern leaves out the `.claude-plugin` paths of the `static/json` case.
- `grep -n 'smoke\.sh' tests/selftest.sh`: every call of `smoke.sh` has `prepare` or `check`, never `start`, `wait`, `_finish` or no subcommand.

  So no Claude session and no headless run start (AC7, AC14).
- `find tests/fixtures/finished-run -type f`: exactly the ten files. No `.gitignore`, no `.slicewright/smoke.json` and no `test.sh`.
- **D15.** `git check-ignore -v --no-index tests/fixtures/finished-run/slice/status.md tests/fixtures/finished-run/.slicewright/slices/index.md`: no output, exit 1.
- **R1.** `git status --porcelain --untracked-files=all`: only this task's eleven new files. Nothing under `plugins/`, `.slicewright/` or `tests/sample/`.

## Boundaries

- Change nothing in:
  - `plugins/slice/` or `.slicewright/`, including `stable/` and `config.json`;
  - `tests/static.sh`, `tests/static/`, `tests/smoke.sh`, `tests/smoke/` or `tests/sample/`;
  - `AGENTS.md`, `doc/` or `slice/docs/`.
- When a static or smoke script misbehaves, report it against T01, T02 or T03 as BLOCKED. Don't patch it here.
- The fixture gets no `.gitignore`, no `.slicewright/smoke.json`, no `test.sh` and no records folder.
- The self-test:
  - never starts a session or a headless run;
  - never edits the repo's fixture or sample in place, only copies in `$W`;
  - never removes anything but its own `$W`;
  - doesn't run cases in parallel to save time.
