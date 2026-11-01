# Design reviews

## clarify, 2026-10-27T09:12:49Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [R9, AC9 vs R10.6]: `file-issues` checks each issue with `gh issue view`, which `.claude/settings.json` doesn't allow, so a design that follows R9 literally stops at a prompt, and one that adds the rule fails AC9 → fixed: `Bash(gh issue view:*)` added to R9 and AC9; intake runs the same command in both pipelines
- Recommendation: say what a person's answer to an open question looks like in `research.md`, so R5, AC5 and `results-review` agree → applied: `research.md` gets a `## Decisions` section that `results-review` writes, one line per answered question, which the stage keeps and treats as settled (R4, R5, AC4, AC5, R10.5)
- Recommendation: AC3 counts four parts of the brief where R3 lists three → applied: AC3 names the three parts
- Recommendation: define "topic", so the title and the research page's name come from one place and a later consolidation finds the same page → applied: the title is the slice's title from `input.md`, and the page's name is the slice's title from `status.md` in lowercase words joined with `-`, the way consolidate names a records folder without an id (R4, R10.7)
- Recommendation: say which `index` context the consolidate stage uses, and that it lists a new folder in its parent's index → applied: `config.json`'s `index` context plus that one rule (R10.7)
- Recommendation: name the fifth static check → applied: `configs` (R12, AC13)
- Recommendation: after a research failure in the spec itself, `more-research` loops into the same failure → applied: `results-review`'s context points a `NO_SPEC` or `SPEC_NOT_READY` failure to `re-scope` (R10.5)
- Recommendation: R12, the static check, is the natural cut if the slice is too large → applied as a note in the one-slice assumption; the slice stays whole

## design, 2026-10-27T11:01:59Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [Contracts 2, consolidate's `adr` and `research` agents]: `results-review` writes `Decision: none: <why>`, which is neither empty nor exactly `none`, so the `adr` agent could write a record where no decision was taken → fixed: one rule in D11 and in both agents' contexts: a `Decision:` line that is empty or starts with `none` is no decision
- Issue [Contracts 2, `file-issues`]: the context dedupes by exact title but never says where a follow-up's title is, so two runs could pick different titles and file a duplicate → fixed: the context states the follow-up's shape and that the title is the text between the id and the first colon, the same as D4
- Recommendation: state R1's file rule in the skill's section 0, since a skill must be complete on its own → applied
- Recommendation: let the `adr` agent link to the page the `research` agent staged instead of re-deriving the slug → applied, in D11 and the `adr` context
- Recommendation: after a failed research, an older `research.md` with filled Decision lines could be accepted; allow only more-research, re-scope and drop then → applied, in the `results-review` context
- Recommendation: configure's step 3.1 would create `.slicewright/<file name>` when the configuration exists only in `~/.slicewright/`, against "creates no file" → applied, in D16 and Contract 4: write into the project file only when it exists
- Recommendation: put the skill folder in an earlier wave than `research.json`, because the `research.json` task's own Verify runs `static.sh` before the other task's work is committed → applied, in the Approach and the Risks

## plan, 2026-10-27T12:09:23Z

### Reviewer 1 (general-purpose)

- Status: Issues found
- Issue [T01, Verify]: the check `grep -n "^## "` expecting exactly seven lines can't pass on a correct skill, because the `research.md` template inside its code block and the record heading `## research, {time}` also start with `## `; the design skill shows 18 such lines, 7 of them numbered sections → fixed: the check is now `grep -n "^## [0-6]\. "`, with a sentence saying why the plain pattern would also match the code blocks
- Note [T05, Verify]: `grep -n -B1 "static_fails '/skills/plan/SKILL.md: '"` matches twice, in `static/name` and `static/checker` → applied: the check names both matches and which one `need_line "PASS configs"` precedes
- Note [T07, Verify; plan Final check]: `grep -n "/slice:configure" README.md` also hits three existing lines → applied: both checks say "among its lines"
- Note [Coverage]: AC11 and AC3's transcript clause are proven by no Verify, by the assumed answer A to Q1 → kept as it is: Q1 is the design's open question, recorded under Assumed answers for the person at the gate
