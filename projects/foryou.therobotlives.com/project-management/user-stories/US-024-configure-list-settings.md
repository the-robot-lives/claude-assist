---
id: US-024
title: "Configure a List's settings"
slug: configure-list-settings
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: medium
tags: [list, settings, double-opt-in, preferences]
---

# US-024: Configure a List's settings

## User Story

**As a** Service editor
**I want to** configure a List's name, slug, description, opt-in mode, and preference defaults
**So that** it behaves correctly for its purpose (waitlist vs newsletter)

## Acceptance Criteria

- **Given** I edit a List
  **When** I update its name, slug, or description and save
  **Then** the changes persist and public forms reflect them
- **Given** I choose an opt-in mode
  **When** I set double opt-in (newsletter) or single opt-in (waitlist/contact)
  **Then** new signups follow that confirmation behavior
- **Given** I set per-list contact-preference defaults
  **When** a subscriber signs up
  **Then** those defaults apply until the subscriber overrides them (see US-054)

## Notes
Double-opt-in default per list is a compliance decision confirmed in the PRD.
