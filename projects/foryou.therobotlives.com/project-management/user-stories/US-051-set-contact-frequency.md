---
id: US-051
title: "Set my contact frequency"
slug: set-contact-frequency
personas: [P-001]
epic: "Contact Preferences"
priority: must-have
complexity: low
tags: [preferences, frequency, delivery]
---

# US-051: Set my contact frequency

## User Story

**As a** subscriber
**I want to** choose how often I'm contacted (immediate/daily/weekly/monthly)
**So that** I control the volume of messages I receive

## Acceptance Criteria

- **Given** I manage a subscription's preferences
  **When** I select a frequency
  **Then** my choice is stored and honored for future sends
- **Given** the List has a default frequency
  **When** I don't set one
  **Then** the list default applies
- **Given** I change frequency
  **When** I save
  **Then** the new setting takes effect immediately

## Notes
Frequency is stored now; scheduled delivery honoring it is built with the senders.
