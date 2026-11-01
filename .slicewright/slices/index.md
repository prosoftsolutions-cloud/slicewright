# Slices

## 2026-10-27 issue-16: Research flow: a slice:research stage and a research pipeline

- Areas: plugins/slice/skills/research/SKILL.md, plugins/slice/skills/run/SKILL.md, plugins/slice/skills/configure/SKILL.md, tests/static.sh, tests/static/defaults.jq, tests/selftest.sh, .slicewright/research.json, .claude/settings.json, start-slice.sh, README.md, AGENTS.md
- Pages: doc/log.md, doc/overview/index.md, doc/overview/product.md, doc/overview/structure.md, doc/overview/testing.md, doc/product/spec/index.md, doc/product/spec/plugin-tests.md, doc/product/spec/research-stage.md, doc/product/spec/research-pipeline.md, doc/product/spec/named-configurations.md, doc/architecture/index.md, doc/architecture/context.md, doc/architecture/building-blocks.md, doc/architecture/runtime.md, doc/architecture/concepts.md, doc/architecture/risks.md, doc/architecture/decisions/index.md, doc/architecture/decisions/0011 to 0022
- Decisions: 0011 The research skill has the shape of the design skill; 0012 The confidence scale is defined once, in the research agent's prompt; 0013 Evidence lines carry `Source:` and `Confidence:`, and a follow-up has a title and its own `Decision:` line; 0014 A later research run keeps what a person wrote, and matches by text; 0015 The runner switches to the slice's configuration in the Continue choice; 0016 `research.json` holds only `pipeline`; 0017 `file-issues` finds an existing issue by exact title; 0018 The research page is named from the slice's title; 0019 The research pipeline's `adr` agent writes at most one record; 0020 The `configs` check is `defaults.jq` with an optional base; 0021 The `static/configs` case copies only `research.json`; 0022 `/slice:configure --config <name>` creates nothing for another name
- Accepted: none (round 1 had seven advisory findings, R1-F1 to R1-F7, and no blocking one, so the review decision was skipped; the smoke suite passed 8 of 8)
- Root causes: none
- Records: 2026-10-27-issue-16/

## 2026-10-25 issue-2: Tests

- Areas: AGENTS.md, .slicewright/config.json, tests/static.sh, tests/static/defaults.jq, tests/static/skill.awk, tests/smoke.sh, tests/smoke/pipeline.json, tests/smoke/config.jq, tests/smoke/allowed-tools, tests/selftest.sh, tests/sample/accept.sh, tests/sample/request.md, tests/sample/project/ (AGENTS.md, greet.sh, test.sh, doc/), tests/fixtures/finished-run/ (greet.sh, doc/, slice/, .slicewright/slices/index.md)
- Pages: doc/index.md, doc/log.md, doc/overview/index.md, doc/overview/structure.md, doc/overview/tech.md, doc/overview/testing.md, doc/product/spec/index.md, doc/product/spec/plugin-tests.md, doc/architecture/index.md, doc/architecture/context.md, doc/architecture/building-blocks.md, doc/architecture/runtime.md, doc/architecture/deployment.md, doc/architecture/concepts.md, doc/architecture/risks.md, doc/architecture/decisions/index.md, doc/architecture/decisions/0001 to 0010
- Decisions: 0001 Plugin tests are POSIX sh scripts; 0002 One smoke command with subcommands; 0003 The test stage waits for a smoke run in steps; 0004 The smoke test's configuration is generated from the defaults; 0005 The smoke configuration overrides only intake's context; 0006 The smoke session is isolated from the developer's own setup; 0007 The smoke session runs with an explicit allow list; 0008 The isolation check leaves out built-in plugins; 0009 The smoke time limit is a watchdog inside smoke.sh; 0010 The finished-run fixture is an overlay on the sample
- Accepted: R1-F3 no real smoke run yet: no measured cost or duration, and the criteria that need a real run are unproven (accepted)
- Root causes: none
- Records: 2026-10-25-issue-2/
