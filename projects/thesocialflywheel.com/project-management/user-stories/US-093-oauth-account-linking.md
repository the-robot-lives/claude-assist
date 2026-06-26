---
id: US-093
title: "Link Social OAuth Account"
slug: oauth-account-linking
personas: [P-010]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [oauth, account-linking, social-auth]
---

# US-093: Link Social OAuth Account

## User Story

**As a** skeptical switcher
**I want to** link a social OAuth provider to my existing email account
**So that** I can log in with Google, Apple, or GitHub in addition to my password

## Acceptance Criteria

- **Given** I navigate to Security Settings
  **When** I click "Connect Google" and complete the OAuth flow
  **Then** Google is added as a login method and future logins can use it

- **Given** the OAuth provider email matches a different existing Flywheel account
  **When** I try to link it
  **Then** I see an error explaining the conflict and am not allowed to link it
