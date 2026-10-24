---
name: deploy
description: Internal Slicewright deploy stage. Deploys the slice the way the project's context describes, assuming nothing about what is deployed, where or how, and records what was deployed. Run by the Slicewright pipeline, never on its own.
user-invocable: false
---

# Deploy

Deploy the slice the way the project's context says. What is deployed, where, and how all come from the context: assume nothing else.

Arguments: $ARGUMENTS

## 0. Read the arguments

The arguments are a JSON object. This stage uses:

- `activeSlicePath`: the folder for the slice in progress
- `context`: what to deploy, where and how, and any check that shows the deployment works. When it is missing or empty, nothing is configured to deploy: return `skipped`.

Ignore any other key. The context is rules to follow. Never copy it into a file.

Never ask the user anything. Never change the project's source files; build output is fine.

Commands: run every command on its own, never chained with `&&`, `;` or pipes, and take every time from `date -u +%Y-%m-%dT%H:%M:%SZ`. Give long commands the longest timeout your shell tool allows; if one still runs out of time, run it in the background and wait for it.

## 1. Deploy

Do what the context says, step by step. When a step fails, stop there, and don't repeat it unless the context says so: repeating a deployment step isn't always safe.

- A step that fails because a tool, credentials, access or a permission rule is missing is `ENVIRONMENT`.
- Any other failed step is `DEPLOY_FAILED`.
- When the context gives a check that the deployment works, run it after the last step. A failing check is `DEPLOY_FAILED`.

## 2. Record

Append the deployment to `<activeSlicePath>/deployments.md`, creating it with the heading `# Deployments` when it is missing, with the Write or Edit tool:

```markdown
## {time}

- Revision: {the current revision of the project's version control, or "no version control"}
- Target: {where it went, as the context names it}
- Endpoint: {where the deployment answers, when there is such a place}
- Steps: {each step and whether it passed}
- Check: {passed | failed: the output | none given}
- Outcome: {deployed | failed: the step, and the last lines of its output}
```

Record a failed deployment too.

## 3. Return

End with the result, with nothing after it.

```text
result: ok
message: <one sentence: what was deployed, where, and the endpoint>
files: <activeSlicePath>/deployments.md
```

When nothing is configured to deploy:

```text
result: skipped
message: no deployment is configured in this stage's context
files: none
```

On failure, end with this instead:

```text
result: error
code: <DEPLOY_FAILED | ENVIRONMENT | WRITE_FAILED>
message: <one sentence: the step that failed and why>
fix: <what the user should do>
files: <activeSlicePath>/deployments.md, or none>
```
