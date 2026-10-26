---
type: decision
status: accepted
date: 2026-10-25
---

# 0006 The smoke session is isolated from the developer's own setup

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D7 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md).

## Context

- A smoke run uses the developer's own Claude Code sign-in, and its cost is billed there.
- Without care, the headless session would also load the developer's user-level settings, plugins, skills, hooks and MCP servers, including the claude.ai connectors. On the machine where this was decided, the user settings enabled six other plugins and defined hooks.
- Pass or fail must depend only on the working copy and the sample. The run must need no network beyond the model API.
- A run started from a stage's agent inherits the calling session's environment variables, such as its effort and its messaging socket.
- The runner merges `~/.slicewright/<name>` into the configuration it is given.
- A probe with Claude Code 2.1.310, run with `--setting-sources project,local --strict-mcp-config --plugin-dir <repo>/plugins/slice`, listed in its init event only `slice` at that path, plus Claude Code's built-in plugins. It listed no MCP server and none of the developer's synced skills, and the sign-in still worked.

## Decision

- The session runs with `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence`, and with `--plugin-dir <repo>/plugins/slice` as the only plugin source.
- Before it starts `claude`, `tests/smoke.sh` unsets these variables of the calling session: `CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SESSION_ATTENDED`, `CLAUDE_CODE_MESSAGING_SOCKET`, `CLAUDE_CODE_MESSAGING_TOKEN`, `CLAUDE_PID`, `CLAUDE_EFFORT` and `AI_AGENT`.
- It keeps `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`, so the sign-in stays.
- It refuses to start, with exit 2, when `~/.slicewright/smoke.json` exists.
- Check 2, `isolation`, verifies the result from the session's own init event ([0008](0008-the-isolation-check-leaves-out-built-in-plugins.md)).

## Alternatives

- **`--bare`.** Rejected: it authenticates only with an API key, never with the developer's sign-in.
- **`--safe-mode`.** Rejected: it also drops `CLAUDE.md` and the project's instructions, which the pipeline reads.
- **Inheriting the calling session's variables.** Rejected: cost and behavior would then depend on the caller.

## Consequences

- A run from a stage's agent behaves like a run from a terminal.
- The first two flags keep out the developer's setup. `--no-session-persistence` only keeps the session from being saved to disk. A review corrected the testing page on this.
- The unset list is explicit, so other variables of a calling session stay set, such as `CLAUDE_CODE_EXECPATH`. A variable that a later Claude Code adds, and that changes the session, has to be added to the list.
- That user-level skills stay out was seen only for synced skills: the machine had no other user-level skills to test with.
- The flags and the init event are as measured with Claude Code 2.1.310. If a later version changes them, check 2 fails and shows what it found.
- [Testing](../../overview/testing.md) and [Deployment](../deployment.md) describe the session's setup.
