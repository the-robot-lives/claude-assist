---
id: US-092
title: "Run a scripted experiment with pinned models and prompts"
slug: run-a-scripted-experiment-with-pinned-models-and-prompts
personas: [P-005]
epic: "Integration & API"
priority: must-have
complexity: high
tags: [experiments, provenance, reproducibility, api]
---

# US-092: Run a Scripted Experiment With Pinned Models and Prompts

## User Story

**As a** researcher
**I want to** submit a run via the API that pins exact model ids (not tier constraints) and exact prompt version numbers for each agent involved, and get back a provenance record of what actually ran
**So that** I can repeat the experiment later and know the results are attributable to a controlled change, not silent drift in defaults

## Acceptance Criteria

- **Given** I submit a run request with explicit `model: {provider, model_id}` overrides per agent and explicit prompt version pins (e.g. agent X's identity prompt at version 7)
  **When** the run executes
  **Then** every turn in every path uses exactly the pinned model and prompt versions, bypassing tier-based dynamic selection and the agent's currently-active version

- **Given** a pinned prompt version does not exist or has been deleted
  **When** the run is submitted
  **Then** the API rejects the request with a 4xx identifying the missing version, rather than silently falling back to the current version

- **Given** a pinned experiment run completes
  **When** I fetch its provenance record
  **Then** it lists, for every turn: provider, model id, model response metadata (e.g. finish reason), and the exact prompt version content hash used, sufficient to reproduce the run byte-for-byte given the same inputs

- **Given** I want to re-run the same experiment
  **When** I resubmit using the provenance record's pinned values
  **Then** the new run uses identical model/prompt configuration, letting me isolate variance to model non-determinism rather than configuration drift

## Notes
This is the story that most distinguishes Elias's (P-005) needs from a typical chat user — reproducibility requires bypassing the tier/fallback convenience of [[US-076]] entirely. Provenance records should be exportable via [[US-093]] for offline analysis.
