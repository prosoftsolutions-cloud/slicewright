---
id: T01
title: Static level
type: test
depends: []
covers: [R1, R2, AC2, AC3]
---

# T01 Static level

## Goal

Add `sh tests/static.sh [<plugin folder>]`. It checks a plugin folder without a model: both `claude plugin validate` runs, every JSON file, the pipeline in `defaults.json`, and each skill's frontmatter. It prints one named `FAIL` line for each problem.

## Context

From spec.md:

- **R1** Every test, fixture and sample project lives under `tests/` at the repo root. No file under `plugins/slice/` or `.slicewright/stable/` changes.
- **R2** The static level is one command, run from the repo root. It checks the plugin folder it is given, or `plugins/slice` when none is given. It starts no Claude session and makes no model call. It finishes within 60 seconds. It prints each failed check with the file, stage or skill it concerns. It exits non-zero when any check fails, and zero otherwise. Its checks:
  1. `claude plugin validate .` and `claude plugin validate <plugin folder>` both pass. Warnings don't fail the check.
  2. Every `.json` file under the plugin folder and under `.claude-plugin/` parses.
  3. In `<plugin folder>/defaults.json`:
     - `sharedParams.activeSlicePath` is a non-empty text.
     - `pipeline` is a non-empty list.
     - Every stage has a `name`, and no two stages share one.
     - Every `executionMode` is `inline` or `fork`.
     - Every stage has a `skill` or a non-empty `params.context`.
     - Every `next` and `onError` that a stage sets to a value other than `null` names a stage.
     - Every value in a stage's `params.choices` names a stage or is `null`.
     - Every stage's `skill`, and every `skill` key at any depth in `sharedParams` and in the stages' `params`, is `TBD` or `slice:<name>`, where `<plugin folder>/skills/<name>/SKILL.md` exists.
     - No stage's `params` sets `activeSlicePath`.
  4. Every folder under `<plugin folder>/skills/` has a `SKILL.md`. Its frontmatter has a `name` equal to the folder's name and a non-empty `description`. Every skill except `new`, `resume` and `configure` has `user-invocable: false`.
- **AC2** Given the working copy at the end of this slice, when the static command runs from the repo root, then it exits zero within 60 seconds, and its code starts no Claude session.
- **AC3** Given a copy of `plugins/slice` with exactly one thing broken, when the static command runs on that copy, then it exits non-zero and its output names the broken stage, skill or file. This holds for each of these cases on its own:
  - a stage's `next` naming no stage
  - a `choices` value naming no stage
  - two stages with the same name
  - a stage's `skill` naming no skill folder
  - a `SKILL.md` whose `name` differs from its folder
  - an internal skill without `user-invocable: false`
  - a JSON file that doesn't parse

  T04's self-test runs these cases on broken copies. This task's own Verify proves the parts it can on the real files.

From design.md:

- **D1** There are three POSIX `sh` scripts at the top of `tests/`, run as `sh tests/<name>.sh`. Their jq and awk files are in `tests/static/` and `tests/smoke/`.
  - POSIX sh only: no `local`, no arrays, no `[[ ]]`, no `sed -i`, no `grep -r`.
  - No executable bit.
  - The tools are the `claude` CLI, `jq` 1.7, `git` and the POSIX utilities.
- **Measured** with Claude Code 2.1.310:
  - `claude plugin validate` takes about 0.5 s and makes no model call. It exits 0 with warnings and 1 with errors. It also exits 0 on a copy of the plugin outside any git repo, with only a README warning. It exits 1 when `plugin.json` doesn't parse, and on a folder with no manifest.
  - It doesn't catch a SKILL.md whose `name` differs from its folder, or a missing `user-invocable`.
  - `jq -e -s 'length == 1'` exits 1 for an empty file, 2 for a missing file and 5 for a parse error.
- **Risk:** Bash-only syntax slips in, because `/bin/sh` is bash on macOS. So the Verify runs `dash -n` and runs the script with `dash`. `/bin/dash` exists here.
- **Contract: `sh tests/static.sh [<plugin folder>]`**
  - **The folder.** The default is `<repo>/plugins/slice`. A relative path resolves against the current folder. The repo root is the parent of the script's own folder.
  - **Checks, in order:**
    - `validate`: `claude plugin validate <repo>` and `claude plugin validate <plugin folder>`. Only the exit status counts, so warnings pass.
    - `json`: `jq -e -s 'length == 1'` on every `*.json` file under the plugin folder and under `<repo>/.claude-plugin`. A file passes only when it holds exactly one JSON value, so an empty file and a file with several values both fail.
    - `defaults`: `jq -r --argjson skills '<JSON list of the folder names under skills/ that hold a SKILL.md>' -f tests/static/defaults.jq <plugin>/defaults.json`.
    - `skills`: `awk -v file=<path> -v folder=<name> -v internal=<1|0> -f tests/static/skill.awk <path>` on each skill folder. `internal` is 0 only for `new`, `resume` and `configure`.
  - **Output:** for each check, either `PASS <check>`, or one line per problem: `FAIL <check>: <subject>: <problem>`.
    - A failed validation prints `FAIL validate: <folder>: claude plugin validate failed`, then the validator's output, indented by two spaces.
    - The last line is `static: passed` or `static: failed, <n> problems`.
  - **Exit status:** 0 when every check passes; 1 when any check fails; 2 when the folder is missing, or `claude` or `jq` is missing.
  - **Problems in the `defaults` check.** The subjects are `stage <name>` (`stage number <n>` when the stage has no name), `sharedParams` or `pipeline`.
    - `sharedParams: activeSlicePath is missing or empty`
    - `pipeline: missing or empty`
    - `stage number <n>: has no name`
    - `stage <name>: <k> stages have this name`
    - `stage <name>: executionMode <value as JSON> is not inline or fork` (the stage's own `executionMode`)
    - `stage <name>: params is not an object`
    - `stage <name>: has no skill and no params.context`
    - `stage <name>: skill <value as JSON> names no skill folder`
    - `stage <name>: params skill <value as JSON> names no skill folder` (any `skill` key at any depth in the stage's `params`)
    - `sharedParams: skill <value as JSON> names no skill folder` (any depth)
    - `stage <name>: params sets activeSlicePath`
    - `stage <name>: next names no stage: <value as JSON>`, and the same for `onError` (only for values other than `null`)
    - `stage <name>: choice <key> names no stage: <value as JSON>` (values other than `null` in `params.choices`)
    - `<file>: does not parse`, when jq can't read `defaults.json`

    A skill value is valid when it is `TBD`, or `slice:<name>` where `<name>` is in `$skills`. On the current defaults, the program prints nothing.
  - **Problems in the `skills` check:**
    - `<folder path>: has no SKILL.md` (static.sh prints it)
    - `<file>: has no frontmatter between --- lines`
    - `<file>: name is missing`, or `<file>: name is "<value>", not "<folder>"`
    - `<file>: description is missing or empty`
    - `<file>: user-invocable is not false, and the skill is internal`

    The frontmatter is the lines between the first line, which must be `---`, and the next `---`. Values are trimmed of spaces and a trailing CR, and one pair of surrounding quotes is removed.
  - **Problems in the `json` check:** `FAIL json: <file>: does not parse`, or `FAIL json: <file>: does not hold exactly one JSON value`.

## Interfaces

**Provides:**

- `sh tests/static.sh [<plugin folder>]`: the contract above. → used by T04, T05, T06
  - The subjects are file paths under the given folder, made absolute, such as `<folder>/skills/plan/SKILL.md` and `<folder>/.claude-plugin/plugin.json`, or `stage <name>`.
  - T04's self-test looks for these substrings in `FAIL` lines: `: stage implement: `, `: stage design-review: `, `: stage intake: `, `: stage deploy: `, `/skills/plan/SKILL.md: `, `/skills/review/SKILL.md: ` and `/.claude-plugin/plugin.json: `.
  - It expects exit 1 for a broken copy.
- `jq -r --argjson skills '<list>' -f tests/static/defaults.jq <plugin>/defaults.json`: prints one `<subject>: <problem>` line per problem, and nothing on the current defaults → used by T05, which names the file on the testing page
- `awk -v file=<path> -v folder=<name> -v internal=<1|0> -f tests/static/skill.awk <path>`: prints one `<file>: <problem>` line per problem → used by T05

**Uses:**

- `plugins/slice/defaults.json`, `plugins/slice/skills/*/SKILL.md`, `plugins/slice/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`: from the existing code
- `claude plugin validate <path>` (Claude Code 2.1.310) and `jq` 1.7.1: from the environment

## Changes

- `tests/static.sh` (new): POSIX sh, with no executable bit.
  - **Top of the file:** a short comment saying what it checks, then one constant for the skills that may be user-invocable: `new resume configure`.
  - **Paths:**
    - The script's folder comes from `dirname "$0"`, and the repo root is its parent. Make both absolute with `cd … && pwd` in a command substitution, with `CDPATH=` set, so `cd` prints nothing.
    - The plugin folder is `$1`, or `<repo>/plugins/slice` when it's missing, made absolute the same way. Every subject printed uses this absolute path.
    - Call the jq and awk files by absolute path, `<repo>/tests/static/…`.
  - **Exit 2, before any check**, with one line on stderr, `static: cannot run: <reason>`, when:
    - there is more than one argument (print the usage);
    - the folder isn't a directory;
    - `command -v claude` fails;
    - `command -v jq` fails.
  - **The four checks, in this order.** Each prints `PASS <check>` when it finds no problem, or one `FAIL <check>: <subject>: <problem>` line per problem.
    1. `validate`: run `claude plugin validate <repo>`, then `claude plugin validate <plugin folder>`.
       - Run each with stdin from `/dev/null`, and capture stdout and stderr together. Only the exit status counts.
       - A non-zero status prints `FAIL validate: <path>: claude plugin validate failed`, then the captured output with each line indented by two spaces.
       - Each failed run is one problem. The indented lines don't count.
    2. `json`: every regular `*.json` file under the plugin folder, and under `<repo>/.claude-plugin` when it exists. Find them with `find`, sorted for stable output.
       - Run `jq -e -s 'length == 1' <file>` on each. Exit 0 passes.
       - Exit 1 prints `FAIL json: <file>: does not hold exactly one JSON value`.
       - Any other non-zero status prints `FAIL json: <file>: does not parse`.
    3. `defaults`:
       - Build the JSON list of the folder names under `<folder>/skills/` that hold a regular `SKILL.md`, for example with `jq -n -c '$ARGS.positional' --args <names>`. Use `[]` when there are none or `skills/` is missing.
       - Run `jq -r --argjson skills "<list>" -f <repo>/tests/static/defaults.jq <folder>/defaults.json`, and capture its output and status.
       - On status 0, print `FAIL defaults: <line>` for each non-empty line.
       - On a non-zero status, which includes a missing file, print only `FAIL defaults: <folder>/defaults.json: does not parse`, as one problem.
    4. `skills`: each folder under `<folder>/skills/`, from `*/`, skipping plain files.
       - With no `SKILL.md`, print `FAIL skills: <folder>/skills/<name>: has no SKILL.md`.
       - Otherwise run `awk -v file=<folder>/skills/<name>/SKILL.md -v folder=<name> -v internal=<0 for a name in the constant, else 1> -f <repo>/tests/static/skill.awk <that file>`, and print `FAIL skills: <line>` for each line it prints.
       - A missing `skills/` folder passes.
  - **Last line:** `static: passed`, or `static: failed, <n> problems`, where `<n>` is the number of `FAIL` lines.
    - Keep the word `problems` even when `<n>` is 1.
    - Exit 0 with no problems, else 1.
  - **Pitfalls:**
    - Count problems in the main shell. A `… | while read` loop runs in a subshell and loses the count, so use a here-document or a counting function.
    - No `set -e`.
    - Use `printf`, not `echo -e`.
    - Quote every path.
    - None of `local`, arrays, `[[ ]]`, `sed -i`, `grep -r`, `<<<`, `$'…'`, `function`, `source`, `pipefail`, or `==` inside `[ ]`. Pipes inside the script are fine.
    - The script writes no file and no temporary file, runs no git, and calls `claude` only for `plugin validate`.
- `tests/static/defaults.jq` (new): called as `jq -r --argjson skills '<list>' -f tests/static/defaults.jq <plugin>/defaults.json`.
  - **Output:** one raw string per problem, `<subject>: <problem>`, with exactly the problem texts in Context. It prints nothing on the current defaults.
  - **It never raises a runtime error on any JSON value**, because static.sh reads a non-zero exit as "does not parse". A top level, `sharedParams`, stage or `params` that isn't an object counts as `{}`. A `pipeline` that isn't an array counts as missing.
  - **Definitions:**
    - The subject is `stage <name>` when `name` is a non-empty string, and otherwise `stage number <n>`, counted from 1.
    - The names are the non-empty string names of all stages.
    - A value names a stage when it is a string among the names.
    - A skill value is valid when it is the string `TBD`, or `slice:<x>` with `<x>` in `$skills`.
    - `<json>` is the value through `tojson`.
  - **Output order:**
    1. `sharedParams: activeSlicePath is missing or empty`, unless it is a non-empty string.
    2. `sharedParams: skill <json> names no skill folder`, for each invalid `skill` key at any depth in `sharedParams` (`.. | objects | select(has("skill"))`).
    3. `pipeline: missing or empty`, unless it is a non-empty array. When it is missing or empty, stop there.
    4. For each stage, in order:
       - `has no name`
       - `<k> stages have this name`, once per shared name, on the first stage that has it
       - `executionMode <json> is not inline or fork`; a missing value shows as `null` and fails, as the runner's check does
       - `params is not an object`, only when `params` is present, not `null` and not an object
       - `has no skill and no params.context`; a skill is a `skill` that is present and not `null`, and a context is a non-empty string `params.context`
       - `skill <json> names no skill folder`, when `skill` is present, not `null` and invalid
       - `params skill <json> names no skill folder`, for each invalid `skill` key at any depth in `params`, the top of `params` included
       - `params sets activeSlicePath`, for a top-level key of `params`
       - `next names no stage: <json>`, then `onError names no stage: <json>`, only for values that are present and not `null`
       - `choice <key> names no stage: <json>`, for each entry of `params.choices` when it is an object, in key order, skipping `null` values
- `tests/static/skill.awk` (new): called as `awk -v file=<path> -v folder=<name> -v internal=<1|0> -f tests/static/skill.awk <path>`.
  - **Portability:** POSIX awk only, because it must run on macOS awk 20200816 and on mawk or gawk. Use no `gensub`, no `IGNORECASE`, no `length(array)` and no regex intervals.
  - **Output and exit:** one `<file>: <problem>` line per problem, with `file` as given. Always exit 0.
  - **Frontmatter:** it runs from line 1, which must be `---` once a trailing CR is removed, to the next such line. With no `---` on line 1, no closing line or an empty file, print only `<file>: has no frontmatter between --- lines`.
  - **Keys** are the lines that start at column 1 with `name:`, `description:` or `user-invocable:`. The first one of each counts.
  - **Values:** remove a trailing CR, trim spaces and tabs at both ends, then remove one pair of matching surrounding `"` or `'`.
  - **Problems, reported in `END` in this order:**
    1. `name is missing`, or `name is "<value>", not "<folder>"`.
    2. `description is missing or empty`.
    3. `user-invocable is not false, and the skill is internal`, only when `internal` is 1 and the value isn't exactly `false`, a missing key included.

## Verify

Run each command from the repo root. `<repo>` is the repo root's absolute path. None of these change a file.

- `dash -n tests/static.sh`: no output, exit 0.
- `sh tests/static.sh`: exactly `PASS validate`, `PASS json`, `PASS defaults`, `PASS skills` and `static: passed`, and exit 0. This is AC2.
- `dash tests/static.sh`: the same five lines, exit 0.
- `/usr/bin/time -p sh tests/static.sh`: the same five lines, and `real` below 60. This is AC2's time limit.
- `sh tests/static.sh plugins/slice`: the same five lines, exit 0. A relative path resolves.
- `sh tests/static.sh no-such-folder`: exit 2, one `static: cannot run:` line naming the folder, and no PASS or FAIL lines.
- `sh tests/static.sh plugins`: exit 1, with these lines in order:
  - `FAIL validate: <repo>/plugins: claude plugin validate failed`, then the validator's output, indented
  - `PASS json`
  - `FAIL defaults: <repo>/plugins/defaults.json: does not parse`
  - `PASS skills`
  - `static: failed, 2 problems`
- `jq -r --argjson skills '["clarify","configure","consolidate","deploy","design","diagnose","human","implement","intake","new","plan","resume","review","route","run","test","tracking"]' -f tests/static/defaults.jq plugins/slice/defaults.json`: no output, exit 0.
- The same command with `"deploy",` removed from the list: exactly `stage deploy: skill "slice:deploy" names no skill folder`. This is AC3's case of a skill naming no skill folder.
- `jq -n -r --argjson skills '[]' -f tests/static/defaults.jq`: exactly `sharedParams: activeSlicePath is missing or empty`, then `pipeline: missing or empty`, and exit 0. The program doesn't fail on a value that isn't an object.
- `awk -v file=plugins/slice/skills/plan/SKILL.md -v folder=plan -v internal=1 -f tests/static/skill.awk plugins/slice/skills/plan/SKILL.md`: no output.
- The same command with `-v folder=planner`: exactly `plugins/slice/skills/plan/SKILL.md: name is "plan", not "planner"`. This is AC3's case of a name that differs from its folder.
- `awk -v file=plugins/slice/skills/new/SKILL.md -v folder=new -v internal=1 -f tests/static/skill.awk plugins/slice/skills/new/SKILL.md`: exactly `plugins/slice/skills/new/SKILL.md: user-invocable is not false, and the skill is internal`. This is AC3's case of an internal skill without `user-invocable: false`.
- `awk -v file=doc/overview/structure.md -v folder=structure -v internal=1 -f tests/static/skill.awk doc/overview/structure.md`: exactly these three lines, in order:
  - `doc/overview/structure.md: name is missing`
  - `doc/overview/structure.md: description is missing or empty`
  - `doc/overview/structure.md: user-invocable is not false, and the skill is internal`
- `awk -v file=plugins/slice/defaults.json -v folder=x -v internal=0 -f tests/static/skill.awk plugins/slice/defaults.json`: exactly `plugins/slice/defaults.json: has no frontmatter between --- lines`.
- `grep -n -E 'claude( |$)' tests/static.sh`: every line shown is a `claude plugin validate` call, `command -v claude`, a comment or a message. None is `claude -p`, `claude --print` or `claude` with a prompt. The pattern leaves out the `.claude-plugin` paths. This is AC2's "starts no Claude session".
- `git status --porcelain -- plugins/slice`: no output (R1).

AC3's cases of a `next`, a `choices` value, a duplicate name and unparseable JSON need broken copies of `plugins/slice`. T04's self-test proves them. While you develop, try each `defaults` and `json` problem line on scratch copies outside the repo.

## Boundaries

- Create only these three files. `tests/smoke.sh`, `tests/smoke/`, `tests/sample/`, `tests/selftest.sh` and `tests/fixtures/` belong to T02, T03 and T04.
- Leave alone everything under `plugins/slice/` and `.slicewright/`, including `config.json`, which T03 changes. Also leave alone `AGENTS.md`, `README.md`, `.claude/settings.json`, `doc/` and `slice/docs/`.
- Add no permission rules. `sh tests/static.sh`, `dash` and `awk` may ask for permission while you verify.
- Keep the output lines, subjects, exit statuses, and jq and awk invocations exactly as written, because T04 matches them and T05 documents them.
- Add no checks beyond R2's list: no `args` or `agent` checks, and no check of the repo's `.slicewright/config.json`.
- The script makes no model call, calls `claude` only for `plugin validate`, runs no git, writes no file, and runs no `chmod`.
