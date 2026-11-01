---
type: spec
---

# Named configurations

A project's pipeline lives in `.slicewright/config.json`. A project can keep other pipelines beside it, one per file, and run one by name: `--config <name>` on `/slice:new`, `/slice:resume` and `/slice:configure`, and on `sh start-slice.sh` in this repo. A slice remembers its configuration, so a slice started with one is continued with it. This repo's [research pipeline](research-pipeline.md) is such a configuration, and the smoke test's `smoke.json` is another ([Plugin tests](plugin-tests.md)).

## Requirements

### The name

- `<name>` is a plain file name, with `.json` added when it doesn't end in it: `research` and `research.json` name the same file. A name that holds `/` or `..` is an error, and the command stops before anything runs.
- Without `--config`, the name is `config.json`.
- The local variant of a name replaces its ending `.json` with `.local.json`.

### Loading

The runner, invoked by `/slice:new` and `/slice:resume`, reads these files in order and skips any that don't exist: the plugin's `defaults.json`, `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>`. So a named configuration takes `config.json`'s place in the three places that hold it, on top of the plugin's defaults. It isn't merged with `config.json`: a pipeline that needs something from `config.json` repeats it.

- With a name other than `config.json`, at least one of the three files must exist. Otherwise the runner stops and says which files it looked for.
- The files merge the same way for any name: objects key by key at any depth, any other value from a later file replaces the earlier one, and `null` removes the key. A named configuration with only `pipeline` gets the defaults' `sharedParams`.
- The runner says which files it loaded, and checks the pipeline as it checks any other.

### The slice remembers its configuration

- When the first stage of a new slice succeeds, the runner records `config: <file name>` in `status.md`, when the file name isn't `config.json`.
- `/slice:resume` without `--config` loads `config.json` first; when `status.md` records another configuration, it loads that one instead and says so. With `--config`, the given configuration is used.
- `/slice:new` without `--config`, when a slice is in progress and the person chooses **Continue**, loads the configuration `status.md` records when it is another than the one loaded, checks its pipeline, says so, and continues the slice with it as `resume` does. It says that the request typed with `/slice:new` isn't used. With `--config` given, the given configuration is kept. **Start new** is unchanged: it deletes the slice folder and starts the typed request with the configuration loaded.
- When the stage to start with isn't in the loaded pipeline, because the configuration changed, the runner says so and stops.

### `/slice:configure --config <name>`

- The command takes `--config <name>` and `--permissions`, in either order. Its usage line is `/slice:configure [--config <name>] [--permissions]`, and any other argument, or a name with `/` or `..`, shows the usage and changes nothing.
- Without `--config`, the name is `config.json`, and the command behaves as it always did: it creates `.slicewright/config.json` from the plugin's defaults when it is missing, sets up the documentation, and proposes the permission rules.
- With another name, the command creates no file: at least one of `~/.slicewright/<file name>`, `.slicewright/<file name>` and `.slicewright/<local variant>` must exist, as the runner requires. Otherwise the command stops, names the three files it looked for, and changes nothing. Its documentation step writes a mapping into `.slicewright/<file name>` only when that file exists.
- Its documentation step and its permissions step load the configuration from the plugin's defaults and those three files, in that order, with the runner's merge rule, so that the rules it proposes are the ones the named pipeline needs: `Skill(<name>)` for every stage's skill, the runner's own rules, and the commands the stages' contexts name, as for `config.json`.
- Its `allowed-tools` covers `~/.slicewright/<file name>` for any name.

### `sh start-slice.sh --config <name>`

- The script takes `sh start-slice.sh [--config <name>] [<issue number>]`. A name that holds `/` or `..`, or is empty, any other option, a second number, or a word that isn't a number is a usage error: exit 2 with the usage line, before anything runs.
- The file is `.slicewright/<name>.json`, with `.json` added when the name doesn't end in it. After the working copy and the stable plugin are prepared, and before Claude starts, the script checks that the file exists, and fails with exit 1 and a message naming it when it doesn't. It checks only the project's file, not `~/.slicewright/`: a pipeline the script starts is the project's.
- With `--config`, the session starts with `/slice:new --config <name> <issue number>`, or `/slice:new --config <name>` without a number, so that the runner asks for the request. Without `--config`, the script behaves as before: `/slice:new <issue number>`, or a session with no command.
- The note about a leftover slice names its configuration from the `config:` line of `slice/status.md`, or `config.json` when the line is absent.
- The script is for the person: an agent never runs it, because it switches branches and starts a session.

### Checking the configurations

The static command's `configs` check covers every `.slicewright/<name>.json` of the repo, except `*.local.json`, merged onto the plugin's defaults with the runner's rule and checked with the rules of the defaults. [Plugin tests](plugin-tests.md) has the rules.

## Acceptance criteria

- Given `plugins/slice/skills/run/SKILL.md`, when its frontmatter is read, then `allowed-tools` has a `Skill(slice:<name>)` rule for every stage skill the plugin ships, `slice:research` among them.
- Given `slice/status.md` with `config: research.json` and a session in this repo, when `/slice:new some text` runs and the person chooses **Continue**, then the runner says it loads `research.json`, says that the typed request isn't used, and runs the stage `status.md` names next from the research pipeline.
- Given the same `status.md`, when `/slice:new --config config some text` runs and the person chooses **Continue**, then the runner keeps `config.json`.
- Given `plugins/slice/skills/configure/SKILL.md`, when its frontmatter is read, then its `argument-hint` is `[--config <name>] [--permissions]`.
- Given `.slicewright/research.json` in this repo, when `/slice:configure --config research --permissions` runs, then the rules it proposes are the research pipeline's, and `.slicewright/config.json` is unchanged.
- Given this repo, when `/slice:configure --permissions` runs, then it proposes the rules it proposed before `--config` existed.
- Given `/slice:configure --config a/b`, when it runs, then it shows the usage line and changes nothing. Given `/slice:configure --config missing`, when it runs, then it stops, names the three files it looked for, and changes nothing.
- Given a clean working copy, when `sh start-slice.sh --config research 17` runs, then Claude starts with `/slice:new --config research 17`; when `sh start-slice.sh --config research` runs, then Claude starts with `/slice:new --config research`.
- Given `sh start-slice.sh --config a/b`, `sh start-slice.sh --config ..` or `sh start-slice.sh --bogus`, when it runs, then it exits 2 with the usage line and runs no other step.
- Given `sh start-slice.sh --config missing`, when it runs, then it exits 1 with a message naming `.slicewright/missing.json`, after the working copy was prepared, and Claude doesn't start.
- Given `sh start-slice.sh 17`, when it runs, then it behaves as before `--config` existed.
- Given `slice/status.md` with `config: research.json`, when the script runs, then its note names `research.json`; given one without a `config:` line, then its note names `config.json`.

## Limitations

- The **Continue** switch, the configure command's option and the script's option have been checked by reading their text, not by a run. The smoke test exercises only the runner's loading of a name, `--config smoke.json`; the session and command runs above are hand checks, and the test stage of the slice that added the options ran only the smoke suite. Reason: `start-slice.sh` is never run by an agent, and `/slice:configure` and **Continue** talk to a person, so no automated check covers them; the hand checks were left to the first use after the merge.
- The README says `--config <name>` loads `<name>.json` "from the same four places instead of `config.json`". The plugin's `defaults.json` is always read first, and the name takes `config.json`'s place only in the three other places, so the sentence reads as four `<name>.json` files. Reason: the code review rated it a suggestion, outside what the slice set out to change, and the slice shipped it unchanged: the round had no blocking finding, so no review decision was taken.
