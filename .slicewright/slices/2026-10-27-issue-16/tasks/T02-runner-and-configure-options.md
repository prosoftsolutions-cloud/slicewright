---
id: T02
title: Runner and configure options
type: plugin
depends: []
covers: [R8, R14, AC8, AC15]
---

# T02 Runner and configure options

## Goal

Let the runner continue a slice in progress with the configuration its `status.md` records, and allow `Skill(slice:research)` in its tools; give `/slice:configure` the `--config <name>` option so that it proposes another pipeline's permission rules without creating a file.

## Context

### Requirements

- **R8** The runner, `plugins/slice/skills/run/SKILL.md`: `Skill(slice:research)` joins its `allowed-tools`. In `new` mode, when `/slice:new` was run without `--config` and the person chooses **Continue** for the slice in progress, the runner loads the configuration that `status.md` records, when it records one, checks its pipeline as in its section 2, says so, and continues the slice with it, as `resume` does. With `--config` given, the given configuration is used, as today. **Start new** is unchanged.
- **R14** `/slice:configure` takes `--config <name>`, with or without `--permissions`, in either order; its `argument-hint` and its usage line become `/slice:configure [--config <name>] [--permissions]`, and any other argument is still a usage error. The name follows the runner's rule: a plain file name, with `.json` added when it doesn't end in it, whose local variant replaces the ending `.json` with `.local.json`; a name with `/` or `..` is a usage error. Without `--config`, the name is `config.json` and the command behaves as today. With another name, the command creates no file: at least one of `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>` must exist, as the runner requires, and otherwise the command stops, says which files it looked for, and changes nothing. Its documentation step and its permissions step load the configuration from those three files, in that order, in place of the `config.json` files, with the same merge rule, so that the rules it proposes are the ones the named pipeline needs. Its `allowed-tools` covers `~/.slicewright/<file name>` for any name.

### Acceptance criteria

- **AC8** (R8) Given `plugins/slice/skills/run/SKILL.md`, when its frontmatter is read, then `allowed-tools` has `Skill(slice:research)`. Given `slice/status.md` with `config: research.json` and a session in this repo, when `/slice:new some text` runs and the person chooses Continue, then the runner says it loads `research.json`, says that the typed request is not used, and runs the stage `status.md` names next from the research pipeline; and when `/slice:new --config config some text` runs with the same `status.md` and the person chooses Continue, then the runner keeps `config.json`.
- **AC15** (R14) Given `plugins/slice/skills/configure/SKILL.md`, when its frontmatter is read, then its `argument-hint` is `[--config <name>] [--permissions]`. Given `.slicewright/research.json` in this repo, when `/slice:configure --config research --permissions` runs, then the rules it proposes include `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)` and `Bash(gh issue view:*)`, include no `Skill(...)` rule for a skill the research pipeline doesn't use, and `.slicewright/config.json` is unchanged; when `/slice:configure --permissions` runs, then it proposes the rules it proposed before this slice; when `/slice:configure --config a/b` runs, then it shows the usage line and changes nothing; when `/slice:configure --config missing` runs, then it stops, names the three files it looked for, and changes nothing.

### Constraints

- `AGENTS.md`'s design rules and skill conventions: the smallest change that works, each rule in one place; plain English, short sentences; never name a version control in skill text.
- Nothing under `.slicewright/stable/` changes. `plugins/slice/defaults.json` doesn't change.

### Design decisions

- **D7 The runner switches configuration in the Continue bullet, not in section 1.** Section 1 keeps its "when resuming" sentence. The **Continue** bullet of section 3, `new`, step 1, gains: when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file loaded, load that configuration as in section 1, check it as in section 2, and say so; then go on as in `resume`. In `new` mode the person chooses after sections 1 and 2 have run, so the switch can only happen there; one bullet is the smallest change; with `--config` given the condition fails, so the given configuration stays. Reading `status.md` in section 1 would switch before the person has chosen, and **Start new** would then run the wrong pipeline.
- **D16 `/slice:configure --config <name>` checks the three files in step 4.1 and creates nothing for another name.** The arguments paragraph defines `<file name>` and `<local variant>` with the runner's rule; step 2 applies only to `config.json`; step 4.1 lists the three files of the name and stops, naming them, when none exists; step 3 keeps loading "as in step 4.1", so the stop happens there too; step 3.1 writes the mapping into `.slicewright/<file name>` only when that file exists, and otherwise says where the mapping belongs and changes nothing. One loading rule serves both steps, as today; the stop comes before anything is written; with `--permissions`, steps 2 and 3 are skipped, so the check must live in 4.1; and "creates no file" must hold in step 3.1 too, for a configuration that exists only in `~/.slicewright/`.

### Contract 3, the runner `plugins/slice/skills/run/SKILL.md`

- `allowed-tools`: `Skill(slice:research)` added after `Skill(slice:consolidate)`.
- The **Continue** bullet of section 3, `new`, step 1, becomes:

  > **Continue:** when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file you loaded, load that configuration as in section 1, check it as in section 2, and say so. Then go on as in `resume` below. Say that the request typed with `/slice:new` is not used.

  Section 1 and **Start new** are unchanged. With `--config` given, the condition fails and the given configuration stays.

### Contract 4, `plugins/slice/skills/configure/SKILL.md`

- Frontmatter: `argument-hint: "[--config <name>] [--permissions]"`; `allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/**)`.
- The arguments paragraph:

  > The arguments may hold `--config <name>` and `--permissions`, in either order. With `--permissions`, skip steps 2 and 3 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--config <name>] [--permissions]`.
  >
  > The configuration's file name is `<name>` from `--config`, with `.json` added when it doesn't end in it. Without `--config`, it is `config.json`. A name must be a plain file name: if it contains `/` or `..`, that is a usage error too. Its local variant replaces the ending `.json` with `.local.json`. Below, `<file name>` and `<local variant>` mean these.

- Step 2: only for `config.json`: as today. With another name, create no file: the configuration must already exist where step 4.1 reads it.
- Step 3.1, the mapping: "write it into `.slicewright/<file name>` when that file exists; otherwise say that the mapping belongs in the file that holds the configuration, and change nothing", so that a configuration that exists only in `~/.slicewright/` never makes the command create a project file.
- Step 4.1: the four files become `${CLAUDE_PLUGIN_ROOT}/defaults.json`, `~/.slicewright/<file name>`, `.slicewright/<file name>`, `.slicewright/<local variant>`, followed by: "With a name other than `config.json`, at least one of files 2 to 4 must exist. Otherwise stop, say which three files you looked for, and change nothing."
- Step 5: "the configuration: its file name, and whether you created `.slicewright/config.json`, changed it or left it as it was".
- Step 4.2 is unchanged: it already yields `Skill(slice:research)` from the stage's skill and the `gh issue` rules from file-issues' context, because for a `slice:deploy` stage it proposes "the commands its context names".

## Interfaces

**Provides:** what this task creates that other tasks rely on, built exactly as written:

- `plugins/slice/skills/run/SKILL.md` frontmatter: `allowed-tools` contains `Skill(slice:research)` → used by T07 (README names `slice:research` as a shipped stage)
- `plugins/slice/skills/configure/SKILL.md` frontmatter `argument-hint: "[--config <name>] [--permissions]"` and the usage line `/slice:configure [--config <name>] [--permissions]` → used by T07 (README says `/slice:configure` takes `--config <name>`, and names `/slice:configure --config research --permissions`)

**Uses:** what this task relies on, exactly as written, without changing it:

- the `config: <file name>` header line of `<activeSlicePath>/status.md`, present only for a configuration other than `config.json`: from `plugins/slice/skills/tracking/SKILL.md` and the runner's section 4.6 in the existing code
- the runner's section 1 (the name rule, the four files, the merge) and section 2 (the pipeline check): from `plugins/slice/skills/run/SKILL.md` in the existing code

## Changes

- `plugins/slice/skills/run/SKILL.md` (changed)
  - Line 5, `allowed-tools:`: insert ` Skill(slice:research)` right after `Skill(slice:consolidate)`, before `Skill(slice:human)`.
  - Section `## 3. Find the first stage to run`, `### new`, step 1, the bullet that now reads `- **Continue:** go on as in `resume` below. Say that the request typed with `/slice:new` is not used.`: replace it with Contract 3's bullet, word for word. Change nothing else: section 1's "When resuming without `--config`…" sentence, **Start new**, **Cancel** and section 2 stay as they are.
- `plugins/slice/skills/configure/SKILL.md` (changed)
  - Frontmatter line 4: `argument-hint: "[--config <name>] [--permissions]"`. Line 6: `allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/**)`.
  - The paragraph after `Arguments: $ARGUMENTS` that now reads `With `--permissions`, skip steps 2 and 3 and only update the permissions. Any other argument is an error: stop and show the usage, `/slice:configure [--permissions]`.`: replace it with Contract 4's two paragraphs.
  - `## 2. Create the config`: keep the sentence as it is and add that it applies only when the file name is `config.json`; with another name, create no file: the configuration must already exist where step 4.1 reads it.
  - `## 3. Set up the documentation`, item 1, third bullet: the sentence `Then write it into `.slicewright/config.json`: change the paths…` becomes: write it into `.slicewright/<file name>` when that file exists, changing the paths in the source's `context` and in the knowledge agents' contexts to the existing ones and keeping everything else as it was; otherwise say that the mapping belongs in the file that holds the configuration, and change nothing. The rest of the bullet stays.
  - `## 4. Update the permissions`, item 1: the numbered files 2 to 4 become `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>`; after the list add the sentence from Contract 4: "With a name other than `config.json`, at least one of files 2 to 4 must exist. Otherwise stop, say which three files you looked for, and change nothing." Item 2 (the rules), item 3 (the settings file) and item 4 stay as they are.
  - `## 5. Report`, first bullet: `- the configuration: its file name, and whether you created `.slicewright/config.json`, changed it or left it as it was`.

## Verify

Run from the repo root.

- `sh tests/static.sh`: exit 0, `PASS skills` and `PASS validate` among its lines (the two skills' frontmatter still parse). While other wave-1 workers write `tests/static.sh` and the `research` skill in the same folder, a transient `FAIL` on their files isn't this task's; rerun when they have finished.
- `claude plugin validate plugins/slice`: exit 0.
- `grep -n "Skill(slice:research)" plugins/slice/skills/run/SKILL.md`: one line, line 5, the `allowed-tools` line, with `Skill(slice:consolidate) Skill(slice:research) Skill(slice:human)` in that order. Proves AC8's frontmatter clause.
- `grep -n "Continue:" plugins/slice/skills/run/SKILL.md`: one line, holding "when `/slice:new` ran without `--config` and `status.md` records a `config` other than the file you loaded, load that configuration as in section 1, check it as in section 2, and say so", "go on as in `resume` below" and "the request typed with `/slice:new` is not used".
- `grep -c "Start new:" plugins/slice/skills/run/SKILL.md`: `1`, and `git diff -- plugins/slice/skills/run/SKILL.md` shows exactly two changed lines: line 5 and the Continue bullet.
- `grep -n "argument-hint" plugins/slice/skills/configure/SKILL.md`: `argument-hint: "[--config <name>] [--permissions]"`. Proves AC15's frontmatter clause.
- `grep -n "allowed-tools" plugins/slice/skills/configure/SKILL.md`: `Read(/${CLAUDE_PLUGIN_ROOT}/defaults.json) Read(~/.slicewright/**)`.
- `grep -n "<file name>" plugins/slice/skills/configure/SKILL.md`: lines in the arguments paragraph, in step 3.1 and in step 4.1's files 2 and 3; `grep -n "<local variant>" plugins/slice/skills/configure/SKILL.md`: the arguments paragraph and step 4.1's file 4.
- `grep -n "/slice:configure \[--config <name>\] \[--permissions\]" plugins/slice/skills/configure/SKILL.md`: the usage line in the arguments paragraph.
- `grep -n "which three files" plugins/slice/skills/configure/SKILL.md`: one line, in step 4.1.
- AC8, the session clauses: read the Continue bullet: without `--config`, a `status.md` with `config: research.json` differs from the loaded `config.json`, so the runner loads `research.json` as in section 1 (and says which files it loaded), checks it as in section 2, says so, says the typed request is not used, and goes on as in `resume`, which starts the stage `status.md` names; with `--config config`, the condition "ran without `--config`" fails, so `config.json` stays. The session run itself is the person's hand check, after T04 has added `.slicewright/research.json`.
- AC15, the command clauses: read the arguments paragraph: `a/b` contains `/`, so it is a usage error that shows the usage line before any step; `missing` gives `missing.json`, which step 4.1 looks for as `~/.slicewright/missing.json`, `.slicewright/missing.json` and `.slicewright/missing.local.json` and, finding none, stops naming the three and changes nothing; `--config research --permissions` skips steps 2 and 3, loads files 1 to 4 with `research.json`, and step 4.2, unchanged, proposes `Skill(<skill>)` for each of the pipeline's stage skills and for every `skill` key in its params (so `Skill(slice:research)`, and none for `design`, `plan`, `implement`, `review`, `test` or `diagnose`, which the research pipeline has no stage for) and, for the `slice:deploy` stages, the commands their contexts name (`gh issue list`, `gh issue create`, `gh issue view`, `gh pr create`); step 2 doesn't run and step 3.1 writes only into an existing file, so `.slicewright/config.json` is untouched; without `--config` the file name is `config.json` and every step reads as before. The command runs themselves are the person's hand check, after T04 has added `.slicewright/research.json`.

## Boundaries

Leave alone: section 1, section 2, **Start new**, **Cancel**, `### resume` and sections 4 and 5 of the runner; step 4.2, 4.3 and 4.4 of configure, and its steps 3.2 and 3.3; every other skill, including the new `research` skill (T01); `plugins/slice/defaults.json`; `.slicewright/config.json`; everything under `.slicewright/stable/`; `.slicewright/research.json`, `.claude/settings.json` and `start-slice.sh` (T04); `tests/` (T03, T05); `slice/docs/` (T06); `README.md` and `AGENTS.md` (T07). Never add a rule to `.claude/settings.json` from this task: T04 adds the four rules.
