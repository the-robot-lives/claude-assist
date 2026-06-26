---
id: US-113
title: "Request optional identity verification"
slug: identity-verification-request
personas: [P-009]
epic: "Profile & Identity"
priority: could-have
complexity: high
tags: [identity, verification, creator]
---

# US-113: Request Optional Identity Verification

## User Story

**As a** creator
**I want to** submit a request to verify my identity
**So that** my audience can trust that my profile is authentic

## Acceptance Criteria

- **Given** I open verification settings
  **When** I start a verification request and submit the required documents
  **Then** my request enters a pending review state

- **Given** my request is approved
  **When** review completes
  **Then** my account is marked verified and I am notified

- **Given** my request is rejected
  **When** review completes
  **Then** I am notified with the reason and may resubmit

## Notes
Verification is optional and never required to use core features.
