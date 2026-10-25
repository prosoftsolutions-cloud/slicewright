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
