---
type: overview
---

# Technology

The technology the product uses, and what its tests need.

## The plugin

- `slice` is a Claude Code plugin in a Claude Code marketplace. Claude Code installs it from the marketplace and runs it.
- It holds no program code. Its skills are Markdown, one `SKILL.md` each, with YAML frontmatter. Its manifests and its default configuration, `defaults.json`, are JSON.
- It has no runtime, no package manager and no build step.

## The tests

- The tests in `tests/` are POSIX `sh` scripts, run as `sh tests/<name>.sh`, with no test framework. They use `jq` for JSON and `awk` for the skills' frontmatter.
- They need the `claude` CLI, `jq`, `git` and a POSIX `sh` with its standard utilities. Nothing is installed.
- The `claude` CLI does two jobs. `claude plugin validate` checks the plugin with no model call. `claude -p` runs the pipeline headless, with the developer's own Claude Code sign-in.
- `git` puts each copy of the sample project under version control. The sample is a POSIX `sh` program, so it needs nothing more.

[Testing](testing.md) gives the commands. [Concepts](../architecture/concepts.md) gives the rules for the scripts, and [Deployment](../architecture/deployment.md) the versions they were measured with. [Decision 0001](../architecture/decisions/0001-plugin-tests-are-posix-sh-scripts.md) records why they are POSIX `sh`.
