# Fleet Roster — {feature-slug}

> One row per active agent. Assignment rationale is mandatory — "it was available"
> is a smell. Cross-check against `references/provider-strengths.md`.

## Roster

| Agent handle | Harness | Provider / model | Class | Persona | Track(s) | Rationale |
|--------------|---------|------------------|-------|---------|----------|-----------|
| | claude-code / codex / opencode / grok / noizu-intellect | | frontier / fast / bulk / local / specialized | | | |

## Assignment sanity checks

- ☐ Contract design (C-series) is on frontier-class only
- ☐ No frontier-class agent is doing mechanical passes (lint, format, bulk rename)
- ☐ Fast-inference agents cover triage/summarization/room-monitoring duties
- ☐ Private or unlimited-volume work is on local models
- ☐ Every track has exactly one owner; every agent knows its ticket IDs
- ☐ A fallback is named for any provider with availability risk

## Standing duties (non-track)

| Duty | Agent | Cadence |
|------|-------|---------|
| Coordinator (gate arbitration, CONTRACT-RFC decisions) | | continuous |
| Room summarizer (STATUS digest) | {fast-inference agent} | on demand |
| Integration verifier | | at each gate |

## Persona attachments

| Persona | Source (npl-persona / project personas) | Attached to | Notes |
|---------|-----------------------------------------|-------------|-------|
| | | | |
