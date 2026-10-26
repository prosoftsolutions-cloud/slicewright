---
type: index
---

# Slicewright documentation

## How to read

- Start with `overview/`: what the product is, its technology, and how the code is organized.
- `product/spec/` is what the system does now, one page per capability, each with its known limitations.
- `product/guides/` is the documentation for users: tutorials, how-to guides, reference and explanation.
- `architecture/` follows arc42: `context.md` the system and its neighbors, `building-blocks.md` its parts and interfaces, `runtime.md` its key flows, `deployment.md` its environments, `concepts.md` the rules that apply across the code, `decisions/` the numbered decision records, `risks.md` the risks and technical debt, `glossary.md` the terms.
- `log.md` lists the consolidated slices, newest first.
- Every page has YAML frontmatter with at least a `type`, and every folder's `index.md` lists its pages. Read only the pages your work needs. Prefer pages marked `verified: true`. A page with `status: deprecated`, or with a `stale_after` date in the past, is unreliable.

## Contents

- [Overview](overview/index.md): the product, its technology and how the code is organized
- [Product](product/index.md): what the system does, and the documentation for users
- [Architecture](architecture/index.md): the arc42 views, cross-cutting rules, decisions and risks

## Pages

- [Log](log.md): the consolidated slices, newest first, each with the pages it changed and where its records are kept
