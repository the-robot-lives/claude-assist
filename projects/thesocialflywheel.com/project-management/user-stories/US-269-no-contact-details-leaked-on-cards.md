---
id: US-269
title: "No Contact Details Leaked on Cards"
slug: no-contact-details-leaked-on-cards
personas: [P-004]
epic: "Swipe-to-Match"
priority: must-have
complexity: low
tags: [privacy, abuse-resistance, safety]
---

# US-269: No Contact Details Leaked on Cards

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** be confident that my email address, phone number, and external links are never shown on my swipe card
**So that** strangers cannot contact or identify me off-platform before I consent to a mutual connection

## Acceptance Criteria

- **Given** my profile has an email and phone number stored
  **When** my card is shown to a potential match
  **Then** neither field is present anywhere in the card's rendered HTML or API response payload

- **Given** my profile bio contains a hyperlink
  **When** my card is shown in the swipe lane
  **Then** the link is stripped and replaced with plain text in the bio excerpt

## Notes
This is a hard privacy requirement enforced at the API serializer level, not just the UI.
