# FAQ — Question Index

Companion to [PROJ-FAQ.md](PROJ-FAQ.md). Questions only, grouped by category —
use this as a cheap relevance check before reading the full file.

## Motivation
- Why would I run agents in a container instead of just passing `--dangerously-skip-permissions` on my real checkout?
- Why would I use the wizard instead of hand-writing a `docker run` command per project?
- Why keep the legacy `bin/dangerously-safe` bash script around at all?

## Fit
- When is this the wrong tool for running an agent?
- When would I use `agent-sandbox preview` instead of the real wizard?
- When should I reach for compose mode instead of the default `docker run` launch?

## Comparison
- How is this different from VS Code Dev Containers / devcontainer.json?
- How is this different from running `docker-compose` by hand for my project?
- How does image reuse here differ from just tagging images by project?
- How does saving a config as a template differ from sharing config across parent directories?

## Capability
- Can it stop the agent reaching the internet entirely?
- Can it tell me what an agent is sending to its LLM provider without blocking it?
- Can it suggest a branch name for me, and does that leak my code?

## Caveats
- Is this actually secure, or just convenient?
- How well-tested is this before I trust it with real work?
- Which config knobs round-trip but don't do anything yet?

## Trust
- Does this touch my main git checkout or branch?
- Are my secrets/API keys handled specially, or is it plain YAML?
- Does the mitmproxy logging option keep captured traffic around after the container exits?
