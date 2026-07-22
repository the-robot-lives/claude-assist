---
id: US-087
title: "Launcher-vs-Template Version Mismatch Is Detected With Guided Resolution"
slug: launcher-template-version-mismatch
personas: [P-006, P-008]
epic: "Resilience & Errors"
priority: must-have
complexity: medium
tags: [versioning, upgrade, resilience, error-handling]
---

# US-087: Launcher-vs-Template Version Mismatch Is Detected With Guided Resolution

## User Story

**As a** OSS tinkerer who upgrades robot-learns and its bootstrapped templates independently
**I want to** be told clearly when my launcher version and the template/schema version in ~/.config/the-robot-learns-kb/ don't match
**So that** I can resolve the mismatch deliberately instead of hitting confusing downstream errors

## Acceptance Criteria

- **Given** the installed launcher's expected schema version differs from the version recorded in my KB's config
  **When** I run any robot-learns command
  **Then** I get an upfront version-mismatch notice before any KB read/write is attempted, stating both versions and whether it's the launcher or the templates that's behind

- **Given** the mismatch is backward-compatible (older templates, newer launcher)
  **When** robot-learns detects it
  **Then** it offers an automatic, reversible migration with a preview of what will change before applying it

- **Given** the mismatch is not safely auto-resolvable
  **When** robot-learns detects it
  **Then** it refuses to proceed with normal operation and instead points to specific guided steps (e.g., pin launcher version, or run migration manually) rather than failing deep in an unrelated command

- **Given** I am offline/air-gapped and can't fetch a newer template set
  **When** a mismatch is detected
  **Then** the guidance still works entirely from locally available versions/backups, with no assumption of network access

## Notes
Fourth criterion matters directly for P-008's air-gapped constraint — resolution guidance must never assume connectivity.
