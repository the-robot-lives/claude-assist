---
id: US-096
title: "Passkey Management"
slug: passkey-management
personas: [P-008]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [passkey, webauthn, security-settings, accessibility]
---

# US-096: Passkey Management

## User Story

**As an** accessibility-first user
**I want to** add, rename, and remove passkeys from my account
**So that** I can maintain a current and organized set of authentication devices

## Acceptance Criteria

- **Given** I navigate to Security Settings
  **When** I click "Add passkey" and complete the device prompt
  **Then** the passkey is saved with a default name (e.g., "Chrome on MacBook") that I can rename

- **Given** I want to remove an old passkey
  **When** I click "Remove" and confirm with another authentication method
  **Then** the passkey is deleted and can no longer be used to log in
