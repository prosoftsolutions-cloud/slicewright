---
slice: issue-16
tasks: 7
waves: 4
---

# Plan: Research flow: a slice:research stage and a research pipeline

## Tasks

- [x] [T01 Research skill](tasks/T01-research-skill.md) · plugin · after: none · covers: R1, R2, R3, R4, R5, R6, R7, AC1, AC2, AC3, AC4, AC5, AC6, AC7
- [x] [T02 Runner and configure options](tasks/T02-runner-and-configure-options.md) · plugin · after: none · covers: R8, R14, AC8, AC15
- [x] [T03 The configs static check](tasks/T03-configs-static-check.md) · test · after: none · covers: R12, AC13
- [x] [T04 Research pipeline, permissions and start script](tasks/T04-research-pipeline-permissions-and-start-script.md) · infrastructure · after: T01, T03 · covers: R9, R10, R11, AC9, AC10, AC11, AC12
- [x] [T05 Self-test case for the configs check](tasks/T05-selftest-configs-case.md) · test · after: T03, T04 · covers: R12, AC13
- [x] [T06 Staged documentation pages](tasks/T06-staged-documentation-pages.md) · documentation · after: T01, T03, T04, T05 · covers: R13, AC14
- [x] [T07 README and AGENTS.md](tasks/T07-readme-and-agents.md) · plugin · after: T01, T02, T03, T04 · covers: R13, AC14

## Waves

1. T01, T02, T03
2. T04
3. T05, T07
4. T06

## Final check

Run from the repo root, after the last wave. Nothing is deployed and no session is started.

- `claude plugin validate .`: exit 0.
- `claude plugin validate plugins/slice`: exit 0.
- `sh tests/static.sh`: lines `PASS validate`, `PASS json`, `PASS defaults`, `PASS configs`, `PASS skills`, last line `static: passed`, exit 0, within 60 seconds (AC1, AC13).
- `sh tests/selftest.sh`: a `caught static/configs: FAIL configs: …/.slicewright/research.json: stage research: skill "slice:no-such-skill" names no skill folder` line, no `MISSED` line, last line `selftest: passed, 16 cases`, exit 0, within 60 seconds (AC13).
- `dash -n start-slice.sh`: prints nothing, exit 0 (R11).
- `dash -n tests/static.sh`: prints nothing, exit 0.
- `dash -n tests/selftest.sh`: prints nothing, exit 0.
- `awk -v file=plugins/slice/skills/research/SKILL.md -v folder=research -v internal=1 -f tests/static/skill.awk plugins/slice/skills/research/SKILL.md`: prints nothing (AC1).
- `jq -r '[.pipeline[].name] | join(", ")' .slicewright/research.json`: `intake, clarify, questions-review, research, results-review, file-issues, consolidate, release` (AC10).
- `jq -n --slurpfile a .slicewright/config.json --slurpfile b .slicewright/research.json '[("intake","release") as $s | ($a[0].pipeline[] | select(.name==$s) | .params.context) == ($b[0].pipeline[] | select(.name==$s) | .params.context)] | all'`: `true` (AC10: intake's and release's contexts equal `config.json`'s).
- `jq -e 'has("sharedParams") | not' .slicewright/research.json`: `true`, exit 0 (D8).
- `git diff master -- .claude/settings.json`: one hunk that adds the four rules `Skill(slice:research)`, `Bash(gh issue create:*)`, `Bash(gh issue list:*)`, `Bash(gh issue view:*)` at the end of `permissions.allow`; the only other textual change is the comma after the previous last rule, `"Bash(gh pr edit:*)"` (AC9).
- `git diff --stat master -- plugins/slice/defaults.json .slicewright/config.json tests/smoke.sh tests/smoke tests/sample tests/fixtures`: prints nothing (the constraints: the defaults, the default pipeline and the smoke test are unchanged).
- `git -C .slicewright/stable status --porcelain`: prints nothing (nothing under `.slicewright/stable/` changed).
- `grep -n "Skill(slice:research)" plugins/slice/skills/run/SKILL.md`: the `allowed-tools` line (AC8).
- `grep -n "argument-hint" plugins/slice/skills/configure/SKILL.md`: `argument-hint: "[--config <name>] [--permissions]"` (AC15).
- `diff doc/overview/structure.md slice/docs/overview/structure.md`: one hunk, the skills bullet, the new `.slicewright/research.json` bullet and the script bullet (AC14).
- `diff doc/overview/testing.md slice/docs/overview/testing.md`: only the hunks T06 lists: five checks, the `configs` bullet, the self-test bullet, `The 16 cases`, the `static/checker` and `static/configs` rows, the Output line, and step 1 of "Adding a static check" (AC14).
- `grep -c "16 cases" slice/docs/overview/testing.md`: `2`, the count the self-test printed above (AC14).
- `grep -n "hotfix" README.md`: nothing; `grep -n "slice:research\|researchAgents\|/slice:configure" README.md`: among its lines, the Quick start line with `--config <name>`, the Concepts bullet, the Default pipeline's closing paragraph and the Recipes paragraph (AC14).
- `grep -n "start-slice.sh\|static.sh" AGENTS.md`: the script line with `[--config <name>] [<issue number>]` and the `static.sh` line naming the project's configurations (AC14).

Checks that need a Claude session or the person's shell, and so are the person's, by hand, after the final check: AC8's Continue behavior (`/slice:new some text` with `config: research.json` in `slice/status.md`, then Continue; and with `--config config`), AC12's runs of `sh start-slice.sh` (`--config research 17`, `--config research`, `--config a/b`, `--config ..`, `--bogus`, `--config missing`, `17`, and the leftover note with and without a `config:` line), AC15's runs of `/slice:configure` (`--config research --permissions`, `--permissions`, `--config a/b`, `--config missing`), and AC10's start of `/slice:new --config research` with no pipeline problem reported. AC11's hand run is outside this slice (Q1).

## Deployed checks

- `sh tests/smoke.sh`: AC13's last clause and the constraint that the default pipeline is unchanged; every check passes · existing test, written by no task; the test stage's `smoke` suite runs it

## Coverage

| Requirement or criterion | Tasks |
|---|---|
| R1 | T01 |
| R2 | T01 |
| R3 | T01 |
| R4 | T01 |
| R5 | T01 |
| R6 | T01 |
| R7 | T01 |
| R8 | T02 |
| R9 | T04 |
| R10 | T04 |
| R11 | T04 |
| R12 | T03, T05 |
| R13 | T06, T07 |
| R14 | T02 |
| AC1 | T01, T03 |
| AC2 | T01 |
| AC3 | T01 |
| AC4 | T01 |
| AC5 | T01 |
| AC6 | T01 |
| AC7 | T01 |
| AC8 | T02 |
| AC9 | T04 |
| AC10 | T04 |
| AC11 | T04 (Q1: the first research slice after the merge) |
| AC12 | T04 |
| AC13 | T03, T05 |
| AC14 | T06, T07 |
| AC15 | T02 |

## Plan decisions

- `.slicewright/research.json`, `.claude/settings.json` and `start-slice.sh` go to the `infrastructure` task type, as the design assumes: its description covers pipelines and environment configuration, and its context checks a change offline with the tool's own validation (`sh tests/static.sh`, `jq`, `dash -n`); no other type's description covers these files → T04
- The `test` type is split in two tasks: the `configs` check lands in wave 1, because T04's Verify runs it on `research.json`; the self-test case lands after T04, because it copies `.slicewright/research.json`, which exists only then. One test task would need `research.json` before and after itself → T03, T05
- The `plugin` type is split in three: the research skill is a whole new file the size of the design skill; the runner and configure edits have their own criteria (AC8, AC15) and run beside it in wave 1; `README.md` and `AGENTS.md` land after what they describe works, as the design's order of work says → T01, T02, T07
- The staged pages land in the last wave, after the self-test case, so their count and case row are checked against the code as built, as the design's order of work says; `README.md` and `AGENTS.md` don't describe the self-test, so they land a wave earlier → T06, T07
- T02 and T07 were filled in by the plan stage itself, not by a task agent: their skeletons name every file and every line they change, the stage had read all of that code while drafting, and the `plugin` type has no skill → T02, T07
- AC8's Continue behavior, AC12's runs of the script and AC15's command runs need a Claude session or the person's shell, and the spec says the script is checked by hand and never run by an agent; the tasks prove them by reading the text against the contracts, with the frontmatter and syntax checked by command, and the person runs them by hand after the final check → T02, T04
- `static/checker` is reported as `caught`, not `ok`, by the self-test, because it ends with `static_fails`; the new `need_line "PASS configs"` shows only as the absence of a `MISSED static/checker` line → T05, T06
- T03's Verify proves D14 with a `null` under a key the base has (`sharedParams.agent.skill`), where jq's `*` and the runner's merge give different verdicts; the `null` on `activeSlicePath` alone wouldn't tell them apart → T03
- The review agent reads the spec, the design and the task files from their paths rather than from a copy in its prompt, because the design alone is 65 KB; it carries nothing else about how the plan was made → the review

## Assumed answers

- **Q1** A: AC11's hand run, `sh start-slice.sh --config research <issue>` through every stage, happens in the first research slice after this slice is merged, because the script starts the stable plugin at `origin/master`, which has no research skill until then; this slice's test stage runs the smoke test only → affects T04 (AC11 is listed there and not proved by its Verify)
