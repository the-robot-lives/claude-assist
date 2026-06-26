---
id: US-149
title: "Shareable profile link and QR code"
slug: shareable-profile-link-qr
personas: [P-003]
epic: "Profile & Identity"
priority: could-have
complexity: low
tags: [profile, identity, sharing]
---

# US-149: Shareable Profile Link and QR Code

## User Story

**As a** social connector
**I want to** generate a shareable link and QR code for my profile
**So that** I can quickly connect with people I meet online or in person

## Acceptance Criteria

- **Given** I open the share option on my profile
  **When** I request a shareable link
  **Then** I receive a copyable URL and a scannable QR code that resolve to my profile

- **Given** my profile visibility settings restrict who can view me
  **When** someone opens my shared link
  **Then** they see only the content permitted by my visibility settings

## Notes
QR and link respect the same lane and degree-based visibility rules as in-app discovery.
