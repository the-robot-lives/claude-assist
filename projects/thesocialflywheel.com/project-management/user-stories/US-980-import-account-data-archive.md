---
id: US-980
title: "Import Account Data Archive"
slug: import-account-data-archive
personas: [P-010]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: high
tags: [data-portability, import, onboarding, migration]
---

# US-980: Import Account Data Archive

## User Story

**As a** Skeptical Switcher
**I want to** upload a data archive from another social platform to pre-populate my Flywheel profile, bio, and interest subscriptions
**So that** I can migrate without starting from scratch.

## Acceptance Criteria

- **Given** the onboarding flow
  **When** I upload a supported platform archive (Mastodon ActivityPub export or Twitter data ZIP)
  **Then** Flywheel extracts my bio, display name, and topic interests and pre-fills my profile for review before saving.

- **Given** the pre-filled profile
  **When** I review and confirm
  **Then** only the data I explicitly approved is saved; all other archive content is discarded and deleted.

## Notes

Post history from other platforms is not imported to prevent spam. Only profile metadata and inferred interests are carried over. Supported formats are documented in the Help Center.
