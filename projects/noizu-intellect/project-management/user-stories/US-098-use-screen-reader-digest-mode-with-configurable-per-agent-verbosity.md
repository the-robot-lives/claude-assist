---
id: US-098
title: "Use screen-reader digest mode with configurable per-agent verbosity"
slug: use-screen-reader-digest-mode-with-configurable-per-agent-verbosity
personas: [P-008]
epic: "Edge Cases, Errors, Performance & Accessibility"
priority: must-have
complexity: high
tags: [accessibility, screen-reader, nvda, streaming, verbosity]
---

# US-098: Use Screen-Reader Digest Mode With Configurable Per-Agent Verbosity

## User Story

**As a** blind developer using NVDA (Alex Marsh)
**I want to** switch a streaming channel into a digest mode that announces complete, sentence-level chunks per agent instead of raw token-by-token stream events, with verbosity independently configurable per agent
**So that** I can follow multi-agent conversations by ear without a wall of unintelligible fragment announcements

## Acceptance Criteria

- **Given** digest mode is enabled for a channel
  **When** an agent streams a reply
  **Then** the screen reader receives ARIA live-region updates batched at sentence or paragraph boundaries, not per-token, so each announcement is a complete, grammatically coherent unit

- **Given** multiple agents replying concurrently in the same channel
  **When** digest mode is active
  **Then** each agent's stream is announced as a distinct, clearly-labeled live region (agent handle prefixed) so interleaved output doesn't merge into one confusing announcement stream

- **Given** the digest verbosity setting
  **When** I set an agent to "summary" verbosity versus "full" verbosity
  **Then** the summary setting announces only the final reply (or a short synthesized summary) while full announces the complete streamed content, and this setting is stored per agent per user

- **Given** a channel with high message volume
  **When** navigating in digest mode
  **Then** the user can move between individual agent turns using standard screen-reader navigation landmarks (headings or regions) without needing to listen to the entire stream sequentially

## Notes
Shares coalescing infrastructure with [[US-097]] but the batching unit is linguistic (sentence/paragraph) rather than purely time/size-based. Should be built and tested with actual NVDA output, not just ARIA markup review — see keyboard navigation companion story [[US-099]].
