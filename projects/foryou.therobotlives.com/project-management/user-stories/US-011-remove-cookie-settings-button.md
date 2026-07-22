---
id: US-011
title: "Remove the cookie-settings button from the navbar"
slug: remove-cookie-settings-button
personas: [P-001, P-007]
epic: "Onboarding & Auth"
priority: must-have
complexity: low
tags: [navbar, cookies, quick-win, cleanup]
---

# US-011: Remove the cookie-settings button from the navbar

## User Story

**As a** visitor
**I want to** see an uncluttered navbar without a redundant cookie-settings button
**So that** navigation is cleaner while consent is still available via the banner

## Acceptance Criteria

- **Given** any page renders the navbar
  **When** the navbar loads
  **Then** the cookie-settings button is no longer present
- **Given** the button is removed
  **When** I need to change cookie choices
  **Then** the cookie consent banner and provider still function normally
- **Given** the change is made
  **When** the app builds
  **Then** the unused import/component reference is also removed with no build errors

## Notes
MANDATORY quick win — plan item 1 / Chunk A. Remove `<CookieSettingsButton />`
from `src/components/navbar.tsx` and its import; keep banner + provider.
