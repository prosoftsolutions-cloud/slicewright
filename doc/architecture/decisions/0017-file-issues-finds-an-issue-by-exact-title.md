---
type: decision
status: accepted
date: 2026-10-27
---

# 0017 `file-issues` finds an existing issue with a title search and an exact match

Accepted on 2026-10-27 in the slice "Research flow: a slice:research stage and a research pipeline" (issue #16), as D9 of its [design](../../../.slicewright/slices/2026-10-27-issue-16/design.md).

## Context

- `file-issues` is `slice:deploy` with a context: for each follow-up in `research.md` whose `Decision:` is `file`, look for an issue of this repository with the same title, open or closed, and create one when there is none. It must not file an issue twice: a stage can run again, and an earlier slice may have filed the same follow-up.
- The deploy skill runs one command per call, without pipes, so a command's output can't be filtered through another.
- GitHub's issue search is fuzzy. `gh issue list` has `--state all`, `--search`, `--json` and a result limit; `gh issue create` has `--title` and `--body`; `gh issue view` shows one issue.
- A follow-up's title is the text between its id and the first colon ([0013](0013-evidence-and-follow-up-lines-carry-labels.md)).

## Decision

- For each follow-up marked `file`: `gh issue list --repo prosoftsolutions-cloud/slicewright --state all --search "<title> in:title" --json number,title,url`, keeping only an issue whose title equals the follow-up's title. When there is none, `gh issue create --repo prosoftsolutions-cloud/slicewright --title "<title>" --body "<its text, why it matters, and where it comes from: the slice's title and, when input.md has one, its source issue>"`. The check is `gh issue view <number> --repo prosoftsolutions-cloud/slicewright` on each.
- The endpoint recorded in `deployments.md` is the list of issue URLs, created or found, each with its follow-up's id. With no follow-up marked `file`, the stage records that there was nothing to file, with no endpoint, and returns `ok`.
- `.claude/settings.json` allows `gh issue create`, `gh issue list` and `gh issue view`. Intake runs `gh issue view` too, in both pipelines.

## Alternatives

- **Listing every issue once and comparing titles.** Rejected: fine today, fails past the list's limit.
- **The search alone.** Rejected: a fuzzy match would skip a follow-up that only resembles an old issue.

## Consequences

- Filing is repeatable: a rerun, or a follow-up another slice already filed, finds the issue and files nothing. `deployments.md` lists every URL with its follow-up's id, and the research page shows them.
- The match depends on the title staying the same ([0013](0013-evidence-and-follow-up-lines-carry-labels.md), [0014](0014-a-later-research-run-keeps-what-a-person-wrote.md)). A follow-up whose title a person changed by hand after filing is filed again.
- The issue's body names the slice and its source issue, not the research page, because the page isn't merged when the issues are filed. `file-issues` runs before `consolidate`, so the page carries the issue links.
- Unproven in a run: only the commands and their flags were checked to exist. [Context](../context.md) shows GitHub as the run's neighbor, and [Research pipeline](../../product/spec/research-pipeline.md) gives the context in full.
