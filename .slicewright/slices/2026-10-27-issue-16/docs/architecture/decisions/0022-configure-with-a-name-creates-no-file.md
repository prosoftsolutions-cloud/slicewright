---
type: decision
status: accepted
date: 2026-10-27
---

# 0022 `/slice:configure --config <name>` checks the three files in its loading step, and creates nothing for another name

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D16 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md). The rule for its documentation mapping was added at the slice's design review.

## Context

- The spec asks that `/slice:configure` takes `--config <name>`, so that the command sets up another pipeline's permission rules. With a name other than `config.json`, the command creates no file: at least one of `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>` must exist, as the runner requires. Otherwise the command stops, says which files it looked for, and changes nothing.
- Before this slice the command took only `--permissions`. Its step 2 creates `.slicewright/config.json` from the defaults when it is missing. Step 3, the documentation, loads the configuration "as in step 4.1", and its step 3.1 writes a documentation mapping into `.slicewright/config.json`. Step 4.1 reads the four `config.json` files, and step 4.2 proposes a rule for every stage's skill and for the commands a `slice:deploy` context names. With `--permissions`, steps 2 and 3 are skipped. `allowed-tools` covered `Read(~/.slicewright/config.json)` only.
- The design review found that step 3.1 would create `.slicewright/<file name>` when the configuration exists only in `~/.slicewright/`, against "creates no file".

## Decision

- The arguments paragraph defines `<file name>` and `<local variant>` with the runner's rule: `.json` added when the name doesn't end in it, `.local.json` for the local variant, and a name with `/` or `..` a usage error. The usage is `/slice:configure [--config <name>] [--permissions]`.
- Step 2 applies only to `config.json`. With another name, the command creates no file.
- Step 4.1 reads `defaults.json`, then the three files of the name. With a name other than `config.json`, it stops when none of the three exists, naming them, and changes nothing. Step 3 keeps loading "as in step 4.1", so the stop happens there too.
- Step 3.1 writes the mapping into `.slicewright/<file name>` only when that file exists. Otherwise it says that the mapping belongs in the file that holds the configuration, and changes nothing.
- `allowed-tools` covers `Read(~/.slicewright/**)`. Step 4.2 is unchanged: for the research pipeline it yields `Skill(slice:research)` from the stage's skill and the `gh issue` rules from the `file-issues` context. Step 5 reports the file name, and whether `.slicewright/config.json` was created, changed or left as it was.

## Alternatives

- **A separate check step after step 1.** Rejected: a second place that names the files. One loading rule serves steps 3 and 4, as before, and with `--permissions` steps 2 and 3 are skipped, so the check has to live in step 4.1 anyway.

## Consequences

- A pipeline added later gets its permission rules from the command, and no rule for a skill it doesn't use. `/slice:configure --config research --permissions` proposes the four rules this slice added by hand to `.claude/settings.json`, so that the first research run doesn't stop at a prompt; the two agree today. [Named configurations](../../product/spec/named-configurations.md) gives the rules.
- The stop comes before anything is written, so "changes nothing" holds on every path, including a configuration that exists only in `~/.slicewright/`.
- The command proposes only skills and the commands the contexts name. It doesn't propose the web tools the research agents use, so a research run may ask the person for `WebFetch` or `WebSearch`. The pipeline always has a person at the session, and a denied fetch becomes a source not reached, not a failure.
- The command's `allowed-tools` now covers every file under `~/.slicewright/`, not one.
- The runs have been checked by reading the text: the command talks to a person, so no automated check covers it, and the hand checks were left to the first use after the merge.
