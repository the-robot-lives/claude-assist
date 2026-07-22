---
id: US-006
title: "Manage active sessions across devices"
slug: manage-active-sessions-across-devices
personas: [P-006]
epic: "Onboarding & Identity"
priority: should-have
complexity: medium
tags: [sessions, security, devices, admin]
---

# US-006: Manage Active Sessions Across Devices

## User Story

**As a** self-hosting admin/SRE
**I want to** see every active login session tied to my account (device, IP, last-seen, auth method) and revoke any of them individually
**So that** I can confirm no stale or unauthorized session is holding access to an instance I'm responsible for securing

## Acceptance Criteria

- **Given** I have logged in from more than one device or browser (e.g. laptop via OAuth, phone via password session)
  **When** I open account settings → sessions
  **Then** I see a list of active sessions each showing device/browser fingerprint, approximate location from IP, auth method used, created-at, and last-active-at, with the current session clearly marked

- **Given** I select a non-current session
  **When** I click "revoke"
  **Then** that session's token is invalidated server-side immediately, and any live PubSub connection tied to it is disconnected within the same request cycle, not on next poll

- **Given** I click "revoke all other sessions"
  **When** the action completes
  **Then** every session except the current one is invalidated in one batch operation, and I remain logged in on the device I took the action from

- **Given** a session has been idle beyond the instance's configured session-timeout (admin-set quota, per [[P-006]]'s ops scope)
  **When** that session's owner next makes a request
  **Then** it is auto-expired and the user is redirected to re-authenticate rather than silently continuing

## Notes
Session revocation should also terminate any direct agent-to-agent side-channel subscriptions opened on behalf of that session's UI client. This is a personal security-hygiene story, distinct from org-level quota/spend admin covered elsewhere.
