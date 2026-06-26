---
id: US-138
title: "Bio character limit enforcement and counter"
slug: bio-character-limit
personas: [P-003]
epic: "Profile & Identity"
priority: must-have
complexity: low
tags: [profile, identity, validation]
---

# US-138: Bio Character Limit Enforcement And Counter

## User Story

**As a** social connector
**I want to** see a live character counter while editing my bio
**So that** I can write a concise bio without hitting an error on save

## Acceptance Criteria

- **Given** I am editing my bio
  **When** I type characters
  **Then** a live counter shows remaining characters and warns as I approach the limit

- **Given** I have reached the character limit
  **When** I attempt to type more
  **Then** further input is prevented and the bio saves cleanly within the limit

## Notes
Enforce the same limit server-side to prevent oversized bios from bypassing the client counter.
