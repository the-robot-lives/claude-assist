---
id: US-002
title: "Adapt Depth Per Domain"
slug: adapt-depth-per-domain
personas: [P-001, P-002]
epic: "Calibrated Q&A"
priority: must-have
complexity: high
tags: [user-profile, per-domain, calibration]
---

# US-002: Adapt Depth Per Domain

## User Story

**As a** developer with uneven expertise across domains
**I want to** have answer depth adapt per-domain based on my user profile
**So that** I get expert-level brevity where I'm strong and fuller explanations where I'm weak

## Acceptance Criteria

- **Given** my user profile records "expert" for Elixir and "novice" for Rust
  **When** I ask an Elixir question via `/query`
  **Then** the answer omits basic language mechanics and focuses on nuance and tradeoffs

- **Given** the same profile
  **When** I ask a Rust question via `/query`
  **Then** the answer includes foundational context and defines domain-specific terms

- **Given** I ask a question spanning two domains with different expertise levels
  **When** `/query` answers
  **Then** the response calibrates each part of the answer to the relevant domain's level rather than applying a single blended level

- **Given** my expertise level for a domain changes (e.g., updated in my profile)
  **When** I next query that domain
  **Then** the new level is applied immediately without a restart

## Notes
Depends on the per-domain expertise map in the user profile schema.
