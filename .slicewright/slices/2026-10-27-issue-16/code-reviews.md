# Code reviews

## Round 1, 2026-10-27T16:56:29Z

- Scope: the whole slice, revisions 5f6923ec03eb6740ec6c7ff76609b1f293b6de57 to acec9ebef241abe8dec15bae4f79a8902d7d1f38, 13 files changed
- Blast radius: 23 files
- Bar: `slice/spec.md`, `slice/design.md`, `AGENTS.md`, `doc/architecture/concepts.md`
- Reviewers: spec: findings; code: findings; tests: findings; docs: findings
- Open blocking: 0 · Advisory: 7

### Advisory

- **R1-F1** README names the `more-research` choice as "more research" · suggestion · spec, docs · the design's Contract 8 gives the same words, so the bar reads both ways, and both reviewers rate it a suggestion: `README.md:152` the Recipes list says "accept, more research, re-scope or drop", while the choice the person types at the gate, and the key in `.slicewright/research.json`, is `more-research`; the other three match. Fix: write `more-research` in `README.md`.
- **R1-F2** README says `<name>.json` is loaded "from the same four places" · suggestion · tests, docs · outside the bar, and the design's Contract 8 wrote the sentence: `README.md:147` the runner always reads the plugin's `defaults.json` first and substitutes `<name>` only in places 2 to 4, so "from the same four places instead of `config.json`" reads as four `<name>.json` files and sits oddly with "so the file repeats what it needs from `config.json`", which holds only because the defaults still come first. Fix: say that `<name>.json` and `<name>.local.json` take `config.json`'s place in the three places that hold it, on top of the plugin's `defaults.json`, in `README.md`.
- **R1-F3** README still says `defaults.json` shows every stage's params · suggestion · docs · outside the bar: `README.md:83` with the new paragraph saying the plugin also ships `slice:research`, "[`defaults.json`] shows every stage's params" is no longer true: `researchAgents` appears in no default stage, only in the Concepts list, the skill and `.slicewright/research.json`. Fix: say "every default stage's params", or point to `.slicewright/research.json` and the research skill for the research stage's, in `README.md`.
- **R1-F4** The research skill names this repo's decision words · suggestion · docs · the design's Contract 1 gives the paragraph verbatim and the spec's R10 names the same words for the pipeline, so the bar reads both ways; a suggestion: `plugins/slice/skills/research/SKILL.md:259` the closing paragraph names `Decision: file`, `Decision: no issue` and `Decision: none: {why}`, which are what `.slicewright/research.json`'s `results-review` context writes, a choice another project could make differently; the skill's own rule, keep every filled `Decision:` line as it is, doesn't depend on the values. Fix: say that a later stage fills the `Decision:` lines, the Decisions section and the Review notes, and leave the values to the configuration, in `plugins/slice/skills/research/SKILL.md`.
- **R1-F5** Pages outside the slice's scope still describe four checks and fourteen or fifteen cases · suggestion · code, tests, docs · outside the bar: R13 names only the two staged pages, and the design's Context records `building-blocks.md` and `runtime.md` as already stale: `doc/product/spec/plugin-tests.md:22-32,96` lists the static level's checks as exactly `validate`, `json`, `defaults` and `skills` and says each static case breaks a copy of `plugins/slice`; `doc/architecture/building-blocks.md:39,41` says "Four checks" and "Fourteen cases"; `doc/architecture/runtime.md:76` says "runs its four checks"; after this slice the scripts have five checks and 16 cases, one of which breaks a copy of `.slicewright/research.json`. Fix: stage the three pages in `slice/docs/` with the `configs` check, the 16 cases and the repo-parts copy, or leave them to consolidate's `spec` and `architecture` knowledge agents and say so in the slice's records.
- **R1-F6** The `*.local.json` exclusion of the `configs` check has no self-test case · suggestion · tests · no proof, and outside the bar: R12 asks for one case and D15 keeps it at one; the "inputs a rule leaves alone" rule in `concepts.md` is stated for acceptance checks: `tests/static.sh:117-119`, `tests/selftest.sh:279-299` no case writes or expects a `.slicewright/<name>.local.json`, so deleting the `*.local.json) continue ;;` line leaves both `sh tests/static.sh` and `sh tests/selftest.sh` passing. Fix: in the existing `static/configs` case, also copy the broken `research.json` to `$COPY/.slicewright/research.local.json` and require that no `FAIL` line names `research.local.json`; the count stays 16; add the file to the case's row in `slice/docs/overview/testing.md`. Files: `tests/selftest.sh`, `slice/docs/overview/testing.md`.
- **R1-F7** Intake's fix message in the research pipeline restarts without `--config` · suggestion · tests · outside the bar: R10.1 and AC10 require the context byte-equal to `config.json`'s, which it is: `.slicewright/research.json:8` on `CHECK_FAILED` the verbatim context tells the person to "quit, and run `sh start-slice.sh` in the project folder"; intake is the first stage and `status.md` exists only after its `ok`, so the runner's new Continue switch can't recover the configuration, and following the message starts `/slice:new` with `config.json` for a research topic. Fix: make the sentence configuration-neutral in both `.slicewright/config.json` and `.slicewright/research.json`, such as "run `sh start-slice.sh` again, with the options you used", so the two contexts stay equal; or loosen R10.1 and AC10 in `slice/spec.md` to let that one sentence differ.

### Blast radius

Changed files:

- `.claude/settings.json`
- `.slicewright/research.json`
- `AGENTS.md`
- `README.md`
- `plugins/slice/skills/configure/SKILL.md`
- `plugins/slice/skills/research/SKILL.md`
- `plugins/slice/skills/run/SKILL.md`
- `start-slice.sh`
- `tests/selftest.sh`
- `tests/static.sh`
- `tests/static/defaults.jq`
- `slice/docs/overview/structure.md` (staged)
- `slice/docs/overview/testing.md` (staged)

Files that use what changed:

- `plugins/slice/skills/new/SKILL.md` and `plugins/slice/skills/resume/SKILL.md`: call the runner
- `.slicewright/config.json`: the source of the contexts `research.json` repeats, and its quality gates run `static.sh` and `selftest.sh`
- `plugins/slice/defaults.json`: the base the `configs` check merges every configuration onto
- `doc/overview/structure.md` and `doc/overview/testing.md`: the published pages the staged ones replace
- `doc/overview/index.md`: lists both pages
- `doc/product/spec/plugin-tests.md`, `doc/architecture/building-blocks.md`, `doc/architecture/runtime.md`: describe the static level and the self-test
