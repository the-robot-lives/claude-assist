---
id: US-131
title: "Link verification badge for external URLs"
slug: link-verification-badge
personas: [P-009]
epic: "Profile & Identity"
priority: could-have
complexity: medium
tags: [profile, identity, creator, verification]
---

# US-131: Link Verification Badge For External URLs

## User Story

**As a** creator
**I want to** verify ownership of the external URLs listed on my profile
**So that** my audience can trust that my links point to my real accounts and not impersonators

## Acceptance Criteria

- **Given** I have added an external URL to my profile
  **When** I complete the verification challenge (meta-tag or callback link)
  **Then** a verified badge appears next to that URL on my public profile

- **Given** a URL was previously verified
  **When** the verification can no longer be confirmed on a re-check
  **Then** the badge is removed and I am notified to re-verify

## Notes
Verification method should support both an HTML meta-tag and a reciprocal-link check so creators on platforms without head access can still verify.
