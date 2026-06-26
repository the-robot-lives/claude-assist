---
id: US-236
title: "Import Contacts Find Mutuals"
slug: import-contacts-find-mutuals
personas: [P-003]
epic: "Mutuals Graph & Degrees"
priority: could-have
complexity: high
tags: [discovery, graph, onboarding]
---

# US-236: Import Contacts Find Mutuals

## User Story

**As a** Social Connector (P-003)
**I want to** import my phone or email contacts to find people I already know who are on Flywheel Social
**So that** I can seed my mutual web with real-world relationships from day one

## Acceptance Criteria

- **Given** I tap "Find contacts" in the onboarding flow or the Discover section
  **When** I grant contacts permission
  **Then** the app hashes contact details client-side, matches against registered accounts, and shows a list of matching users

- **Given** matches are found among my contacts
  **When** the results display
  **Then** I can select individual contacts or "Add all as mutuals" with a single tap

- **Given** I import contacts
  **When** the process completes
  **Then** raw contact data is never stored server-side; only the match result is retained, and I am informed of this in the permission dialog

## Notes
Contact hashing and privacy disclosure are non-negotiable requirements for any contacts-import feature. Legal review required before shipping.
