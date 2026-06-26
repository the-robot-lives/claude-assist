---
id: US-441
title: "Show upload progress for media attachments"
slug: upload-progress-indicator
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: low
tags: [upload, progress, media, ux]
---

# US-441: Show Upload Progress for Media Attachments

## User Story

**As a** Creator
**I want to** see a real-time progress indicator while my media is uploading
**So that** I know the upload is proceeding and can estimate how long it will take

## Acceptance Criteria

- **Given** I have attached a media file and started composing
  **When** the upload is in progress
  **Then** a progress bar or percentage counter is shown on the attachment thumbnail

- **Given** upload reaches 100%
  **When** processing (transcoding) begins
  **Then** the indicator transitions to "Processing…" until the media is ready

## Notes
Publish button is disabled until all attachments reach "Ready" state.
