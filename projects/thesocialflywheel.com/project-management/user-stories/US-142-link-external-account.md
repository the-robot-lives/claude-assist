---
id: US-142
title: "Link external account"
slug: link-external-account
personas: [P-010]
epic: "Profile & Identity"
priority: could-have
complexity: high
tags: [profile, identity, verification]
---

# US-142: Link External Account

## User Story

**As a** skeptical switcher
**I want to** link and verify an external account from another platform
**So that** my reputation carries over and others can trust I am who I claim to be

## Acceptance Criteria

- **Given** I am on my profile settings
  **When** I start linking an external account
  **Then** I am taken through an OAuth or token-based verification flow for that platform

- **Given** I complete verification for an external account
  **When** the link succeeds
  **Then** a verified badge for that platform appears on my profile

- **Given** I have a linked external account
  **When** I choose to unlink it
  **Then** the badge is removed and no further data is synced from that platform

## Notes
Linking is verification-only; it does not import contacts or content unless separately consented to.
