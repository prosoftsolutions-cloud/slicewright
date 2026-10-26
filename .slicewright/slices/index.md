# Slices

## 2026-10-25 issue-2: Tests

- Areas: AGENTS.md, .slicewright/config.json, tests/static.sh, tests/static/defaults.jq, tests/static/skill.awk, tests/smoke.sh, tests/smoke/pipeline.json, tests/smoke/config.jq, tests/smoke/allowed-tools, tests/selftest.sh, tests/sample/accept.sh, tests/sample/request.md, tests/sample/project/ (AGENTS.md, greet.sh, test.sh, doc/), tests/fixtures/finished-run/ (greet.sh, doc/, slice/, .slicewright/slices/index.md)
- Pages: doc/index.md, doc/log.md, doc/overview/index.md, doc/overview/structure.md, doc/overview/tech.md, doc/overview/testing.md, doc/product/spec/index.md, doc/product/spec/plugin-tests.md, doc/architecture/index.md, doc/architecture/context.md, doc/architecture/building-blocks.md, doc/architecture/runtime.md, doc/architecture/deployment.md, doc/architecture/concepts.md, doc/architecture/risks.md, doc/architecture/decisions/index.md, doc/architecture/decisions/0001 to 0010
- Decisions: 0001 Plugin tests are POSIX sh scripts; 0002 One smoke command with subcommands; 0003 The test stage waits for a smoke run in steps; 0004 The smoke test's configuration is generated from the defaults; 0005 The smoke configuration overrides only intake's context; 0006 The smoke session is isolated from the developer's own setup; 0007 The smoke session runs with an explicit allow list; 0008 The isolation check leaves out built-in plugins; 0009 The smoke time limit is a watchdog inside smoke.sh; 0010 The finished-run fixture is an overlay on the sample
- Accepted: R1-F3 no real smoke run yet: no measured cost or duration, and the criteria that need a real run are unproven (accepted)
- Root causes: none
- Records: 2026-10-25-issue-2/
