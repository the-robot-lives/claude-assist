---
id: US-976
title: "Import Interests from Another Platform"
slug: import-interests-from-another-platform
personas: [P-003]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: high
tags: [integrations, import, interests, onboarding]
---

# US-976: Import Interests from Another Platform

## User Story

**As a** Social Connector
**I want to** upload a data export from Reddit or Twitter/X to automatically seed my Flywheel interest subscriptions based on communities or topics I was active in
**So that** I can immediately see relevant content without manually searching for channels.

## Acceptance Criteria

- **Given** the Onboarding or Settings > Integrations page
  **When** I upload a Reddit or Twitter data export ZIP
  **Then** Flywheel parses my subreddit/list memberships and suggests matching Flywheel interest channels.

- **Given** the suggested interest channels
  **When** I review the list and click "Subscribe to selected"
  **Then** I am subscribed to the chosen channels and the imported file is deleted.

## Notes

Import parsing happens client-side or in an ephemeral server job; raw export files are not retained. Only interest/community memberships are read — post history and DMs are ignored.
