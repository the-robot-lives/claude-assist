---
id: US-095
title: "Recover gracefully from LLM provider errors mid-turn"
slug: recover-gracefully-from-llm-provider-errors-mid-turn
personas: [P-006, P-001]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: must-have
complexity: high
tags: [error-handling, providers, retry, fallback, resilience]
---

# US-095: Recover Gracefully From LLM Provider Errors Mid-Turn

## User Story

**As a** self-hosting admin/SRE (Nadia Volkov)
**I want to** have the system automatically retry and fall back to an alternate model/provider when an LLM call fails or times out mid-turn, with the failure surfaced as visible status rather than hidden
**So that** transient provider outages don't silently stall runs or corrupt turn state, and I can see when degraded routing is happening

## Acceptance Criteria

- **Given** an in-flight LLM call during any pass of the Plan → Reply → Reflect pipeline that returns a provider error (5xx, rate limit) or times out
  **When** the failure occurs
  **Then** the system retries with backoff up to a configured limit before escalating, without duplicating or losing the partial turn state already recorded

- **Given** retries are exhausted for the configured primary model/provider
  **When** a fallback provider or model is configured for that agent/branch
  **Then** the turn automatically re-routes to the fallback, and the resulting message/turn record is annotated to show a fallback was used

- **Given** a provider failure during a turn
  **When** viewed from the channel or run UI
  **Then** the affected agent/path shows a visible "retrying" or "degraded" status rather than appearing frozen or silently dropping the turn

- **Given** all configured retries and fallbacks are exhausted
  **When** the turn ultimately fails
  **Then** the path/turn is marked failed with a captured error reason (not left in an ambiguous pending state), and the failure is queryable via [[US-086]]'s run status filter

## Notes
Ties into per-branch dynamic model selection and fallback config from the model-management mechanics. Distinguish transient provider errors (retry-worthy) from content policy/refusal errors (not retry-worthy) in the classification logic.
