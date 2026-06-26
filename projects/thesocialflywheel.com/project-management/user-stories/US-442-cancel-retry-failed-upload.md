---
id: US-442
title: "Cancel or retry a failed media upload"
slug: cancel-retry-failed-upload
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [upload, error, retry, media]
---

# US-442: Cancel or Retry a Failed Media Upload

## User Story

**As a** Creator
**I want to** retry or cancel a media upload that has failed
**So that** I am not stuck in a broken state and can choose how to proceed

## Acceptance Criteria

- **Given** a media upload has failed (network error, server error)
  **When** the failure is detected
  **Then** the attachment thumbnail shows an error state with "Retry" and "Remove" buttons

- **Given** I tap Retry
  **When** the upload resumes
  **Then** the progress indicator resets and the upload restarts (or resumes from a checkpoint)

## Notes
"Remove" discards the attachment entirely so the user can publish without that media.
