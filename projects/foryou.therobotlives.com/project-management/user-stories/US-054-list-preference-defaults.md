---
id: US-054
title: "Set per-list preference defaults"
slug: list-preference-defaults
personas: [P-004]
epic: "Contact Preferences"
priority: should-have
complexity: medium
tags: [preferences, defaults, list, editor]
---

# US-054: Set per-list preference defaults

## User Story

**As a** Service editor
**I want to** define default contact preferences and available channels for a List
**So that** subscribers start with sensible settings

## Acceptance Criteria

- **Given** I configure a List
  **When** I set default frequency, channels, and quiet periods
  **Then** new signups inherit those defaults
- **Given** I restrict which channels a List offers
  **When** a subscriber manages preferences
  **Then** only offered channels are selectable
- **Given** I change list defaults later
  **When** I save
  **Then** existing subscribers' explicit overrides are preserved

## Notes
Defaults are inherited then overridable (US-055).
