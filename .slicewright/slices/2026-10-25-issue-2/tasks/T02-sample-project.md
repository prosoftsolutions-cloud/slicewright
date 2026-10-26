---
id: T02
title: Sample project
type: test
depends: []
covers: [R1, R3, AC4]
---

# T02 Sample project

## Goal

Add the sample project that the smoke run copies. It is a small POSIX shell program with its own tests and OKF documentation. It comes with a request for one fully specified feature, and an acceptance check for that feature kept outside the sample.

## Context

From spec.md:

- **R1** Every test, fixture and sample project lives under `tests/` at the repo root. No file under `plugins/slice/` or `.slicewright/stable/` changes.
- **R3** One sample project lives under `tests/`. It has:
  - a small program with its own tests, run by one command that the sample's own `AGENTS.md` names;
  - a documentation folder at the path the default `knowledge` names;
  - a request for one small, fully specified feature;
  - an acceptance check for that request.

  The acceptance check is kept outside the sample's files, so the pipeline never sees or changes it. The sample builds and tests with no package install and no network.
- **AC4** Given a fresh copy of the sample, when its own test command runs, then its tests pass without installing anything. And when the acceptance check runs against that unchanged copy, then it fails, because the requested feature doesn't exist yet.

From design.md:

- **D1** POSIX sh only: no `local`, arrays, `[[ ]]`, `sed -i` or `grep -r`. No executable bit: the scripts run as `sh <file>`.
- **D6** The smoke run has no `taskTypes` override. The sample's `AGENTS.md` says that, in the pipeline's task types, `greet.sh` and `test.sh` are backend code: the program and the command-line interface it exposes. Doc pages are `documentation`.
- **D5** The smoke run's intake override says that the version control is git, with no remote, and that "its AGENTS.md names the tools to work with it". So the sample's `AGENTS.md` must say so.
- **D15** The sample has no `.gitignore` of its own. The smoke run's `prepare` step writes one.
- **The default `knowledge`** in `plugins/slice/defaults.json` is the folder `./doc`, an OKF bundle:
  - Markdown pages with YAML frontmatter that has at least a `type`;
  - an `index.md` in every folder;
  - `overview/` first;
  - `product/spec/` with one page per capability and its limitations.
- **Risks:**
  - Agents working on this repo may misread the sample's `AGENTS.md`, so it says first what it is.
  - Bash-only syntax may slip in, because `/bin/sh` is bash on macOS, so the Verify runs `dash -n` and `dash`.
- **Contract: `tests/sample/`**
  - **`project/greet.sh`.** Usage: `sh greet.sh [name]`.
    - It prints `Hello, <name>!`, or `Hello, world!` with no name or an empty one, and exits 0.
    - A first argument that starts with `-` prints `greet: unknown option: <arg>` on stderr and exits 2.
    - More than one argument prints `greet: too many arguments` on stderr and exits 2.
  - **`project/test.sh`.** Run it as `sh test.sh`. It finds `greet.sh` next to itself.
    - It prints `ok - <name>` or `not ok - <name>` for each test, then `<p> passed, <f> failed`.
    - It exits 0 only when none failed.
    - It covers the four behaviors above.
    - Its unknown-option test uses `-x`, never `--shout`, so it still passes once the feature exists, as in the fixture.
  - **`project/AGENTS.md`** says:
    - first, that this is the sample project of Slicewright's smoke test;
    - its layout;
    - the test command, `sh test.sh`, and how to run the program, `sh greet.sh <args>`;
    - that there is no build step, no package to install, and no linter, analyzer or formatter: don't look for any or run any; `sh test.sh` is the whole check, and it needs nothing deployed;
    - POSIX sh only, and errors as `greet: <message>` with status 2;
    - that in the pipeline's task types, `greet.sh` and `test.sh` are backend code: the program and the command-line interface it exposes;
    - that the documentation is the OKF bundle in `doc/`, starting at `doc/index.md`;
    - that the version control is git, with no remote.
  - **`project/doc/`** is at the path the default `knowledge` names, with a `type` on each page:
    - `index.md`, with "How to read" and Contents
    - `overview/index.md`
    - `overview/product.md`
    - `product/index.md`
    - `product/spec/index.md`
    - `product/spec/greeting.md`: usage, the name and its default, errors, exit statuses and Limitations
  - **`request.md`.** It asks to add a `--shout` option to `greet.sh` that prints the greeting in upper case. Every choice is stated:
    - `--shout Ada` prints `HELLO, ADA!` and exits 0.
    - `--shout` alone prints `HELLO, WORLD!` and exits 0.
    - The option counts only as the first argument, followed by at most one name. `--shout Ada Bob` and `Ada --shout` both print `greet: too many arguments` and exit 2.
    - Only the letters a to z become A to Z.
    - Without the option, nothing changes, and other arguments starting with `-` are still unknown options.
    - It asks for tests of each behavior in `test.sh`, and for the option in `doc/product/spec/greeting.md`.
    - It ends: "Nothing else changes. There are no open questions: this request is complete, and each choice above is final."
  - **`accept.sh <project folder>`.** It is never copied into a run. It prints `ok` and `not ok` lines and never writes to the folder.
    - It exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing.
    - Its cases:
      - `--shout Ada` → `HELLO, ADA!`, 0
      - `--shout` → `HELLO, WORLD!`, 0
      - `--shout Ada Bob` → the stderr line, empty stdout, 2
      - `Ada` → `Hello, Ada!`
      - `-x` → `greet: unknown option: -x`, 2
      - `--shout ada-lovelace_42` → `HELLO, ADA-LOVELACE_42!`
      - some `*.md` file under `doc/` mentions `--shout`, found with `find … -exec grep -l -e '--shout' {} +`
    - On the unchanged sample, the `--shout` cases fail (AC4).
- **Plan decisions:**
  - The request also states two choices the design leaves open, so that clarify has no question to ask:
    - an empty name after `--shout` is the same as no name;
    - after `--shout`, an argument starting with `-` is an unknown option.
  - `greet.sh` checks for an unknown option before it checks for too many arguments.
  - The documentation point in the sample's `AGENTS.md` is written as the `slicewright:knowledge` block, in the form consolidate's `instructions` agent keeps.

## Interfaces

**Provides:**

- `tests/sample/project/`: the sample, with no `.gitignore` and no `.slicewright/`. The smoke run copies the whole folder. → used by T03 (the source that its `start` and foreground run pass to `prepare`), T04 (copied, with the fixture laid on top), T05
- `sh test.sh`, run in the project folder:
  - It finds `greet.sh` next to itself.
  - It prints `ok - <name>` or `not ok - <name>` for each test, then `<p> passed, <f> failed`.
  - It exits 0 only when none failed, and writes nothing.

  → used by T03 (`TEST_COMMAND="sh test.sh"`, check 5), T04
- `sh tests/sample/accept.sh <project folder>`:
  - It prints `ok - <case>`, or `not ok - <case>: <expected and got>` on one line.
  - Then it prints `<p> passed, <f> failed`.
  - It never writes to the folder.
  - It exits 0 when all pass, 1 when any fails, and 2 when the folder or its `greet.sh` is missing, or on wrong usage.

  → used by T03 (check 6 runs `sh <repo>/tests/sample/accept.sh <scratch copy>`), T04, T05
- `tests/sample/request.md`: the request text, with no frontmatter and no heading, sent as is after `/slice:new --config smoke.json ` → used by T03
- `tests/sample/project/greet.sh`'s behavior and messages:
  - `Hello, <name>!` and `Hello, world!`;
  - `greet: unknown option: <arg>` and `greet: too many arguments` on stderr, with status 2;
  - the unknown option checked first.

  → used by T04, whose fixture `greet.sh` adds `--shout` and keeps the rest
- `tests/sample/project/doc/product/spec/greeting.md` → used by T04, whose fixture copy adds `--shout`

**Uses:**

- the default `knowledge`, with path `./doc`, and the default task types `backend` and `documentation`: from `plugins/slice/defaults.json`

## Changes

All eleven files are new.

**Rules for all three scripts:**

- POSIX sh only. That means no `local`, `declare` or `typeset`, no arrays, no `[[ ]]`, no `==`, no `<<<`, no `sed -i`, no `grep -r`, no `function` keyword, and no `echo` with options.
- Use `printf '%s'` for argument text, because dash's `echo` reads backslashes.
- No executable bit. A `#!/bin/sh` first line is optional.
- LF line endings, and every file ends with a newline.
- Never `cd`, and never depend on the current folder.

**The files:**

- `tests/sample/project/greet.sh` (new): the program. A comment at the top gives its usage, `sh greet.sh [name]`. It makes these checks, in order:
  1. When the first argument starts with `-` (`case ${1-} in -*)`), it prints `greet: unknown option: <arg>` on stderr, nothing on stdout, and exits 2.
  2. When there is more than one argument, it prints `greet: too many arguments` on stderr and exits 2.
  3. Otherwise it prints `Hello, <name>!`, or `Hello, world!` for no name or an empty one, and exits 0.

  It reads no stdin and writes no file. Its messages are an interface: T04's fixture keeps them.
- `tests/sample/project/test.sh` (new): run as `sh test.sh`, with no arguments.
  - It finds the program with `greet="$(dirname "$0")/greet.sh"`.
  - A helper, such as `check <name> <want stdout> <want stderr> <want status> [greet args…]`, runs each test:
    - It shifts 4 and runs `"$@"`.
    - It captures stdout and the status with `out=$(sh "$greet" "$@" 2>/dev/null </dev/null); status=$?`.
    - It captures stderr with `err=$(sh "$greet" "$@" 2>&1 >/dev/null </dev/null)`.
    - It compares all three exactly.
    - It prints `ok - <name>`, or `not ok - <name>` followed by one line starting with `#` that says what it expected and what it got.
    - The counters are globals, incremented outside any `$( )`.
  - Six tests, none of which uses `--shout`:
    - greets a name: `Ada` gives `Hello, Ada!`, an empty stderr and status 0;
    - greets the world with no name: no arguments give `Hello, world!` and 0;
    - greets the world with an empty name: `''` gives `Hello, world!` and 0;
    - rejects an unknown option: `-x` gives an empty stdout, `greet: unknown option: -x` and 2;
    - rejects too many arguments: `Ada Bob` gives an empty stdout, `greet: too many arguments` and 2;
    - reports an unknown option before too many arguments: `-x Ada` gives `greet: unknown option: -x` and 2.
  - The last line is `<p> passed, <f> failed`. It exits 0 when f is 0, and 1 otherwise.
  - No `set -e`, and it writes nothing.
- `tests/sample/project/AGENTS.md` (new): every point below, in this order. You may reword the draft, but keep every point. It names no command except `sh test.sh`, `sh greet.sh` and git. It never mentions `--shout`, `accept.sh` or `request.md`.

  ```markdown
  # greet

  This is the sample project of Slicewright's smoke test. The smoke test copies this folder to a new folder outside the Slicewright repo, and the Slicewright pipeline develops the copy there. In such a copy, this is the project, and these instructions apply as written. In the Slicewright repo itself, this folder is test data, and the repo's own `AGENTS.md` applies. Paths here are relative to this folder.

  ## Layout
  - `greet.sh`: the program, a POSIX shell script that prints a greeting
  - `test.sh`: its tests, one check per behavior
  - `doc/`: the documentation

  ## Commands
  Run each one from this folder, exactly as written:
  - `sh test.sh` runs the tests. It is the whole check, and it needs nothing deployed and no network.
  - `sh greet.sh <args>` runs the program, such as `sh greet.sh Ada`.

  There is no build step, no package to install, no CI configuration, and no linter, analyzer or formatter. Don't look for any, and don't run any.

  ## Conventions
  - POSIX sh only, in both scripts. They are run with `sh` and need no executable bit.
  - Errors go to stderr as `greet: <message>`, and the program exits with status 2.

  ## Task types
  In the pipeline's task types, `greet.sh` and `test.sh` are `backend` code: the program and the command-line interface it exposes. Pages in `doc/` are `documentation`.

  ## Version control
  The version control is git, with no remote. Commit locally: there is nothing to fetch, pull or push.

  <!-- slicewright:knowledge -->
  ## Project documentation

  - **docs**: the OKF bundle in `./doc`. Start at `doc/index.md`.
  - A slice in progress keeps its unpublished documentation changes in `./slice/docs/`, at the same paths. Read those first. If a source can't be reached, note it as an assumption and keep working.
  <!-- /slicewright:knowledge -->
  ```

- `tests/sample/project/doc/` (new): six pages. Each starts with `---`, `type: <value>`, `---`, like this repo's own `doc/` pages.
  - No page contains the text `--shout`, because `accept.sh` searches for it. Don't hint at upper-case output either.
  - `doc/index.md` (`type: index`) has two sections:
    - `## How to read`: start with `overview/`; `product/spec/` has one page per capability, each with its limitations; `log.md` lists the consolidated slices, newest first; every page has frontmatter with a `type`, and each folder's `index.md` lists its pages.
    - `## Contents`: links to `overview/index.md` and `product/index.md`.
  - `doc/overview/index.md` (`type: index`): a `## Pages` section with a link to `product.md`.
  - `doc/overview/product.md` (`type: overview`): what `greet` is. It is a small command-line program that prints a greeting, written as one POSIX shell script with its tests in `test.sh`, and it needs nothing installed. It links to `../product/spec/greeting.md`.
  - `doc/product/index.md` (`type: index`): a `## Contents` section with a link to `spec/index.md`.
  - `doc/product/spec/index.md` (`type: index`): a `## Pages` section with a link to `greeting.md`.
  - `doc/product/spec/greeting.md` (`type: spec`), with these sections:
    - Usage: `sh greet.sh [name]`.
    - The name and its default: `Hello, <name>!`, and `Hello, world!` for no name or an empty one.
    - Errors: both messages on stderr, nothing on stdout, and an unknown option reported before too many arguments.
    - Exit statuses: 0 and 2.
    - Limitations: there are no options, so every argument that starts with `-` is an unknown option and a name can't start with `-`; and it greets one name at a time.
- `tests/sample/request.md` (new): no frontmatter and no heading, because it is sent as is. Its text:

  ```markdown
  Add a `--shout` option to `greet.sh` that prints the greeting in upper case.

  - `sh greet.sh --shout Ada` prints `HELLO, ADA!` and exits 0.
  - `sh greet.sh --shout` prints `HELLO, WORLD!` and exits 0. An empty name after `--shout` is the same as no name.
  - The option counts only as the first argument, followed by at most one name. `sh greet.sh --shout Ada Bob` and `sh greet.sh Ada --shout` both print `greet: too many arguments` on stderr and exit 2.
  - A name never starts with `-`: after `--shout`, such an argument is an unknown option, so `sh greet.sh --shout -x` prints `greet: unknown option: -x` on stderr and exits 2.
  - Only the letters a to z become A to Z. Every other character stays as it is: `sh greet.sh --shout ada-lovelace_42` prints `HELLO, ADA-LOVELACE_42!`.
  - Without the option, nothing changes, and other arguments starting with `-` are still unknown options.
  - Add tests of each behavior to `test.sh`, and describe the option in `doc/product/spec/greeting.md`.

  Nothing else changes. There are no open questions: this request is complete, and each choice above is final.
  ```

  The last sentence must be exactly that, on the file's last line.
- `tests/sample/accept.sh` (new): run as `sh tests/sample/accept.sh <project folder>`. A relative path resolves against the current folder.
  - **Exit 2**, with a message on stderr, in three cases: no argument or more than one (a usage line), a path that isn't a directory, or a folder with no `greet.sh` file.
  - **How it runs a case:** as `sh "<folder>/greet.sh" <args> </dev/null`. It captures stdout and the status, and stderr separately, as `test.sh` does.
  - **Output:** `ok - <case>`, or `not ok - <case>: <expected …; got status, stdout, stderr>` on one line, because T03's check 6 shows only its `not ok` lines. Then `<p> passed, <f> failed`.
  - **Exit status:** 0 when f is 0, and 1 otherwise.
  - **The seven cases:**
    - `--shout Ada`: stdout `HELLO, ADA!`, status 0
    - `--shout`: stdout `HELLO, WORLD!`, status 0
    - `--shout Ada Bob`: stderr `greet: too many arguments`, empty stdout, status 2
    - `Ada`: stdout `Hello, Ada!`, status 0
    - `-x`: stderr `greet: unknown option: -x`, status 2
    - `--shout ada-lovelace_42`: stdout `HELLO, ADA-LOVELACE_42!`, status 0
    - doc mentions the option: `find "<folder>/doc" -type f -name '*.md' -exec grep -l -e '--shout' {} +`, with stderr to `/dev/null`, gives non-empty output. Judge the output, not find's exit status.
  - It never writes to the folder, and has no `set -e`.

## Verify

Run each command from the repo root.

- `dash -n tests/sample/project/greet.sh`: no output, exit 0.
- `dash -n tests/sample/project/test.sh`: no output, exit 0.
- `dash -n tests/sample/accept.sh`: no output, exit 0.
- `grep -n -E 'local |declare |typeset |\[\[|sed -i|grep -r|function |==|<<<|echo -' tests/sample/project/greet.sh tests/sample/project/test.sh tests/sample/accept.sh`: no output, exit 1.
- **AC4, part 1.** `sh tests/sample/project/test.sh`: six `ok - ` lines, then `6 passed, 0 failed`, and exit 0.
- `dash tests/sample/project/test.sh`: the same output, exit 0.
- **The program:**
  - `dash tests/sample/project/greet.sh Ada`: `Hello, Ada!`, exit 0.
  - `dash tests/sample/project/greet.sh`: `Hello, world!`, exit 0.
  - `dash tests/sample/project/greet.sh -x Ada`: `greet: unknown option: -x`, exit 2.
  - `dash tests/sample/project/greet.sh Ada Bob`: `greet: too many arguments`, exit 2.
  - `dash tests/sample/project/greet.sh --shout Ada`: `greet: unknown option: --shout`, exit 2. The feature is absent.
- **AC4, part 2.** `sh tests/sample/accept.sh tests/sample/project`:
  - `ok` for `Ada` and `-x`;
  - `not ok` for the four `--shout` cases and the doc case;
  - `2 passed, 5 failed`, and exit 1.
- `dash tests/sample/accept.sh tests/sample/project`: the same output, exit 1.
- **Each of these exits 2 with a message:**
  - `sh tests/sample/accept.sh tests/sample`: no `greet.sh` there.
  - `sh tests/sample/accept.sh tests/sample/no-such-folder`
  - `sh tests/sample/accept.sh`: the usage.
- `find tests/sample -type f`: exactly the 11 files. There is no `.gitignore` or `.slicewright/`, and `accept.sh` and `request.md` are outside `project/`.
- `find tests/sample -type f -perm -u+x`: no output.
- `grep -r -l -e '--shout' -e accept.sh -e request.md tests/sample/project`: no output, exit 1. The pipeline can't see the check, and the unchanged pages don't mention the option.
- `grep -c -e '^type: ' tests/sample/project/doc/index.md tests/sample/project/doc/overview/index.md tests/sample/project/doc/overview/product.md tests/sample/project/doc/product/index.md tests/sample/project/doc/product/spec/index.md tests/sample/project/doc/product/spec/greeting.md`: `:1` for each page.
- `head -n 3 tests/sample/project/AGENTS.md`: shows that this is the sample project of Slicewright's smoke test.
- `grep -n -e 'sh test.sh' -e 'sh greet.sh' -e linter -e POSIX -e backend -e documentation -e 'doc/index.md' -e 'no remote' tests/sample/project/AGENTS.md`: each point matches.
- `tail -n 1 tests/sample/request.md`: exactly the final sentence.
- `grep -n -e '>' tests/sample/project/test.sh tests/sample/accept.sh`: only `>/dev/null`, `2>/dev/null`, `>&2` or `2>&1`. The scripts write no file.
- **R1.** `git status --porcelain --untracked-files=all -- tests/sample plugins/slice`: only the 11 `?? tests/sample/…` lines.
- R3 is shown by the checks above: no install, the test command named in `AGENTS.md`, `doc/` with a `type` on each page, the request, and the acceptance check outside the sample.

## Boundaries

- Create only the 11 files.
- Add no `.gitignore`, `.slicewright/`, `slice/` or `doc/log.md` to the sample. `prepare` writes the first two, and consolidate's `index` agent creates `log.md`.
- Leave alone:
  - everything under `plugins/slice/` and `.slicewright/`;
  - the root `AGENTS.md`, `README.md` and `.claude/`;
  - the repo's own `doc/` and `slice/docs/`;
  - the other tasks' files: `tests/static*`, `tests/smoke*`, `tests/selftest.sh` and `tests/fixtures/`.
- Nothing under `project/` mentions `--shout`, `accept.sh` or `request.md`. `test.sh` never uses `--shout`. `accept.sh` tests only the seven cases above.
- No script writes a file.
