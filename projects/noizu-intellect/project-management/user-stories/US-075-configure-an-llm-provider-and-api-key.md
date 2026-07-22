---
id: US-075
title: "Configure an LLM provider and API key"
slug: configure-an-llm-provider-and-api-key
personas: [P-006]
epic: "Admin & Platform Ops"
priority: must-have
complexity: medium
tags: [providers, api-keys, admin]
---

# US-075: Configure an LLM Provider and API Key

## User Story

**As a** self-hosting admin/SRE
**I want to** register an LLM provider (OpenAI, Anthropic, local vLLM, etc.) with its endpoint and API key at the org level
**So that** agents across all projects can draw on that provider without each project owner managing its own credentials

## Acceptance Criteria

- **Given** I am on the provider configuration screen
  **When** I add a provider with a name, endpoint URL, and API key
  **Then** the key is stored encrypted at rest, never displayed again in plaintext, and the provider becomes selectable in model tier configuration

- **Given** a provider is configured
  **When** I run a connectivity test against it
  **Then** the system makes a minimal probe call and reports success/failure with the raw error surfaced on failure

- **Given** I attempt to save a provider with an invalid or empty API key
  **When** I submit the form
  **Then** the save is rejected with a validation error and no provider row is persisted

- **Given** a provider is in use by at least one model tier
  **When** I try to delete it
  **Then** I am blocked with a list of dependent tiers, or offered a reassignment flow before deletion proceeds

## Notes
This is the root of the model management mechanics referenced in CONSOLIDATION.md — per-branch dynamic model selection and fallback (US-076) both depend on at least one healthy provider existing. Key rotation should reuse this same masked-storage path.
