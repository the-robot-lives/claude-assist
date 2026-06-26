---
id: US-137
title: "Display mutual count on profile"
slug: display-mutual-count
personas: [P-003]
epic: "Profile & Identity"
priority: should-have
complexity: low
tags: [profile, identity, mutuals]
---

# US-137: Display Mutual Count On Profile

## User Story

**As a** social connector
**I want to** see the count of mutuals (moots) I share with a profile
**So that** I can gauge how connected we already are before reaching out

## Acceptance Criteria

- **Given** I view another user's profile
  **When** the page loads
  **Then** I see the number of shared 1st-degree mutuals between us

- **Given** I have privacy settings restricting mutual visibility
  **When** another user views my profile
  **Then** the shared mutual count respects my visibility preference

## Notes
Only the shared/overlapping mutual count is shown, not the full mutuals list, to balance discovery with privacy.
