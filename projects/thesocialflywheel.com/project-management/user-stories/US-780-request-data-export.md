---
id: US-780
title: "Request Data Export"
slug: request-data-export
personas: [P-010]
epic: "Settings & Preferences"
priority: must-have
complexity: medium
tags: [data-export, privacy, gdpr, account]
---

# US-780: Request Data Export

## User Story

**As a** skeptical switcher
**I want to** request a full export of my account data
**So that** I can review what Flywheel Social holds about me and migrate to another platform if I choose

## Acceptance Criteria

- **Given** I open Account Settings > Data Export
  **When** I click "Request Export"
  **Then** the system begins preparing a ZIP archive and sends me an email with a download link within 24 hours.

- **Given** the export is ready
  **When** I click the download link in the email
  **Then** I receive a ZIP file containing my profile, posts, mutual connections list, interests, and settings in machine-readable JSON.

## Notes
