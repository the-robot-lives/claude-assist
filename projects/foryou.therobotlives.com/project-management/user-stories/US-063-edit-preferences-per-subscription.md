---
id: US-063
title: "Edit contact preferences per subscription"
slug: edit-preferences-per-subscription
personas: [P-001]
epic: "Preference Center"
priority: should-have
complexity: medium
tags: [preference-center, preferences, subscriptions]
---

# US-063: Edit contact preferences per subscription

## User Story

**As a** signed-in subscriber
**I want to** adjust frequency, channels, and quiet periods per subscription
**So that** each list contacts me the way I want

## Acceptance Criteria

- **Given** a subscription in my dashboard
  **When** I open its preferences
  **Then** I can edit frequency, channels, and quiet periods (US-051–US-053)
- **Given** I save changes
  **When** the update applies
  **Then** the subscription reflects the new preferences immediately
- **Given** a list restricts channels
  **When** I edit
  **Then** only offered channels are shown

## Notes
Reuses the contact-preference controls from Epic 5.
