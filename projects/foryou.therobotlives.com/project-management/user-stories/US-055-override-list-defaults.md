---
id: US-055
title: "Override list defaults for my subscription"
slug: override-list-defaults
personas: [P-001]
epic: "Contact Preferences"
priority: should-have
complexity: low
tags: [preferences, override, inheritance]
---

# US-055: Override list defaults for my subscription

## User Story

**As a** subscriber
**I want to** override a list's default preferences for my own subscription
**So that** my settings reflect my personal choices

## Acceptance Criteria

- **Given** a subscription inheriting list defaults
  **When** I change a preference
  **Then** my override is stored and takes precedence over the default
- **Given** I have overrides
  **When** the list default later changes
  **Then** my explicit overrides are not silently reset
- **Given** I want to revert
  **When** I choose "reset to list default"
  **Then** my override is cleared and the default applies again

## Notes
