---
type: index
---

# Spec

What the system does now, one page per capability, each with its known limitations.

## Pages

- [Plugin tests](plugin-tests.md): the tests that check a new version of the plugin, and this repo's pipeline configurations with it, before it is merged, with their requirements, acceptance criteria and limitations
- [Research stage](research-stage.md): `slice:research`, the stage that answers a spec's questions from sources with cited evidence and a confidence, and writes `research.md` for a person to decide on: its params, what it reads, the brief, its agents, the document, later runs and the review
- [Research pipeline](research-pipeline.md): this repo's `.slicewright/research.json`: a research topic through eight stages, from the questions to the results, the filed issues, a research page and a decision record, with its permissions and how it is started and continued
- [Named configurations](named-configurations.md): `--config <name>`, a pipeline kept beside `config.json`: the name, how it is loaded, how a slice remembers it, `/slice:configure --config <name>` and `sh start-slice.sh --config <name>`
