---
id: US-788
title: "Revoke OAuth App Access"
slug: revoke-oauth-app-access
personas: [P-010]
epic: "Settings & Preferences"
priority: should-have
complexity: low
tags: [security, oauth, connected-apps, revoke]
---

# US-788: Revoke OAuth App Access

## User Story

**As a** skeptical switcher
**I want to** revoke a connected third-party app's OAuth access
**So that** it can no longer read or write data on my behalf

## Acceptance Criteria

- **Given** I am viewing my connected apps list
  **When** I tap "Revoke Access" on an app and confirm
  **Then** the app's OAuth token is invalidated and a confirmation toast is displayed.

## Notes
