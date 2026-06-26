---
id: US-619
title: "Remove an Interest Exclusion"
slug: remove-an-interest-exclusion
personas: [P-001]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: low
tags: [safety, exclusions, unblock]
---

# US-619: Remove an Interest Exclusion

## User Story

**As a** bridge-builder
**I want to** remove an interest or belief tag from my exclusion list
**So that** content on that topic can once again reach me through Discovery and Opposing-Views

## Acceptance Criteria

- **Given** tag #Veganism is on my exclusion list
  **When** I click "Remove exclusion" next to it and confirm
  **Then** #Veganism is removed from the list and posts with that tag are eligible to surface again

- **Given** the exclusion is removed
  **When** the other party (who was mutually excluded) refreshes their feed
  **Then** my tagged posts with #Veganism become visible to them again

## Notes
Removal of an exclusion lifts the mutual suppression (US-603/604) symmetrically.
