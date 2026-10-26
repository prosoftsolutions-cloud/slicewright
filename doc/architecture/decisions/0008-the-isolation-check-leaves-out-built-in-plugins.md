---
type: decision
status: accepted
date: 2026-10-25
---

# 0008 The isolation check leaves out Claude Code's built-in plugins

Accepted on 2026-10-25 in the slice "Tests" (issue #2), as D9 of its [design](../../../.slicewright/slices/2026-10-25-issue-2/design.md). The person confirmed it during design.

## Context

- The spec asks that the session's own report of what it loaded show the `slice` plugin from `plugins/slice`, and no other plugin and no MCP server.
- A probe's init event listed `slice` and three built-in plugins with `"path": "builtin"`. They come with Claude Code, appear in every session, and can't be turned off from the project. They aren't the developer's plugins, which the smoke run must leave out ([0006](0006-the-smoke-session-is-isolated-from-the-developers-setup.md)).

## Decision

- Check 2, `isolation`, reads the first event in `session.jsonl` with `type: system` and `subtype: init`.
- It leaves out the plugins with `"path": "builtin"`. What remains must be exactly `[{"name": "slice", "path": <plugin_dir>}]`, where `plugin_dir` is the absolute path recorded in `run.txt`. `mcp_servers` must be empty.
- A failure lists what it found.
- This reads the spec's words more narrowly. The [Testing](../../overview/testing.md) page says that built-in plugins aren't counted.

## Alternatives

- **Requiring an empty list apart from `slice`.** Rejected: built-in plugins appear in every session, so the check could never pass.

## Consequences

- The check fails on any plugin or MCP server that the developer's setup adds, but not on what Claude Code itself ships.
- A built-in plugin can still change what a run does, and the check doesn't flag it.
- The check relies on the init event's shape, and on `"builtin"` as the marker, as measured with Claude Code 2.1.310.
