---
id: R1-T03
title: Testing page says what the isolation flags and the unset variables do
type: documentation
depends: [R1-T02]
covers: [R1-F8, R1-F9]
---

# R1-T03 Testing page says what the isolation flags and the unset variables do

## Goal

The staged testing page says that `--setting-sources project,local` and `--strict-mcp-config` keep out the developer's setup, that `--no-session-persistence` only keeps the session from being saved, and that some, not all, of the calling session's variables are unset.

## Context

Both findings are in the same place: the page's account of how the headless session is isolated, in `slice/docs/overview/testing.md`. Each claims more than the code does. The code and the flags stay as they are.

**R1-F8: the testing page says `--no-session-persistence` keeps out the developer's setup.**

- Where: `slice/docs/overview/testing.md:216`.
- Problem: the page says the three flags `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence` exclude the developer's user settings, plugins, skills, hooks and MCP servers. But `claude --help` says `--no-session-persistence` only keeps the session from being saved to disk: "Disable session persistence - sessions will not be saved to disk and cannot be resumed (only works with --print)". The page and `tests/smoke.sh` pass the same flags; only the page's account of what one flag does is wrong.
- Suggested fix: say that the first two flags exclude the developer's setup, and that `--no-session-persistence` keeps the run out of the saved sessions.
- Decision: fix.

**R1-F9: the testing page says the calling session's variables are unset, but one stays set.**

- Where: `slice/docs/overview/testing.md:217`.
- Problem: a calling session also exports `CLAUDE_CODE_EXECPATH` (`printenv CLAUDE_CODE_EXECPATH` prints a path), and `tests/smoke.sh:639-641` doesn't unset it. The code unsets exactly design D7's list, and the page points to `tests/smoke.sh` for it.
- Suggested fix: word the page as "these variables of the calling session are unset", or add the variable to the `unset` lines and to D7. This task takes the first: the code already follows D7.
- Decision: fix.
- The headless command's lead-in, at line 115, makes the same claim: "after the calling session's variables are unset". It changes too, so that the page doesn't still say it.

**What the design says about isolation (D7):** the flags are `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence`, with `--plugin-dir <repo>/plugins/slice` as the only plugin source. Before `exec claude`, the script unsets the calling session's variables `CLAUDECODE`, `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SESSION_ATTENDED`, `CLAUDE_CODE_MESSAGING_SOCKET`, `CLAUDE_CODE_MESSAGING_TOKEN`, `CLAUDE_PID`, `CLAUDE_EFFORT` and `AI_AGENT`. It keeps `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`, so the sign-in stays.

**The requirement it must keep meeting:** R9.1, the testing page says how the tests isolate the run: "tests load the plugin only from `plugins/slice` and change only copies". AC12: the page covers every item R9 lists.

## Changes

- `slice/docs/overview/testing.md` (changed; the staged page). Replace three lines, word for word, and change nothing else:
  - The headless command's lead-in, under "Smoke level". Replace

    ```markdown
    The headless command. It runs in `<run>/project`, with stdin from `/dev/null`, after the calling session's variables are unset:
    ```

    with

    ```markdown
    The headless command. It runs in `<run>/project`, with stdin from `/dev/null`, after some variables of the calling session are unset, as Isolation and permissions says:
    ```

  - The second bullet under "Isolation and permissions". Replace

    ```markdown
    - The developer's own setup is left out. `--setting-sources project,local`, `--strict-mcp-config` and `--no-session-persistence` exclude the developer's user settings, plugins, skills, hooks and MCP servers.
    ```

    with

    ```markdown
    - The developer's own setup is left out. `--setting-sources project,local` and `--strict-mcp-config` exclude the developer's user settings, plugins, skills, hooks and MCP servers. `--no-session-persistence` keeps the run's session from being saved to disk, so it can't be resumed.
    ```

  - The third bullet under "Isolation and permissions". Replace

    ```markdown
    - The calling session's variables are unset, such as `CLAUDECODE` and `CLAUDE_CODE_SESSION_ID`. `tests/smoke.sh` has the full list. `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*` are kept, so the sign-in stays.
    ```

    with

    ```markdown
    - Some variables of the calling session are unset, such as `CLAUDECODE` and `CLAUDE_CODE_SESSION_ID`, and `tests/smoke.sh` lists them. Every other variable is kept, such as `CLAUDE_CONFIG_DIR` and `ANTHROPIC_*`, so the sign-in stays.
    ```

## Verify

Run each command from the repo root.

- **R1-F8 repro, before the change:** `grep -n -F 'persistence` exclude' slice/docs/overview/testing.md` prints the bullet under "Isolation and permissions". This is the failure.
- **R1-F9 repro, before the change:** `grep -n -i -F "the calling session's variables are unset" slice/docs/overview/testing.md` prints two lines: the headless command's lead-in and the bullet under "Isolation and permissions". This is the failure.
- **R1-F8, after the change:** `grep -n -F 'persistence` exclude' slice/docs/overview/testing.md`: no output, exit 1.
- `grep -n -F "keeps the run's session from being saved to disk" slice/docs/overview/testing.md`: one line, the bullet under "Isolation and permissions".
- `claude --help`: `--no-session-persistence` says that sessions are not saved to disk and can't be resumed; `--setting-sources` loads the setting sources it lists; `--strict-mcp-config` uses only the MCP servers from `--mcp-config`. The page's new bullet says the same.
- **R1-F9, after the change:** `grep -n -i -F "the calling session's variables are unset" slice/docs/overview/testing.md`: no output, exit 1.
- `grep -n -F "Some variables of the calling session are unset" slice/docs/overview/testing.md`: one line, the bullet under "Isolation and permissions".
- `grep -n -F "after some variables of the calling session are unset" slice/docs/overview/testing.md`: one line, the headless command's lead-in.
- `grep -n "^    unset " tests/smoke.sh`: three lines, whose names include `CLAUDECODE` and `CLAUDE_CODE_SESSION_ID`, and not `CLAUDE_CONFIG_DIR`, `ANTHROPIC_` or `CLAUDE_CODE_EXECPATH`. The page's examples are among the unset names, and the kept ones aren't.
- `printenv CLAUDE_CODE_EXECPATH`: in a Claude Code session, it prints a path. That variable is kept, as the page now allows.
- `grep -n -F "Isolation and permissions" slice/docs/overview/testing.md`: the heading `## Isolation and permissions` and the headless command's lead-in.
- `git status --porcelain`: no output. The page is under the ignored `slice/`, and no other file changes.

## Boundaries

- `tests/smoke.sh` doesn't change: the flags and the `unset` lines stay as design D7 has them.
- Only the three lines above change on the page. The "Output lines" bullet about `wait` belongs to R1-T01, and the rest of the page stays as it is.
- No published page under `doc/` changes: consolidate publishes the staged page.
