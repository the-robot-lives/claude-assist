---
id: US-419
title: "Resume an interrupted media upload"
slug: resume-interrupted-upload
personas: [P-009]
epic: "Posting & Content Creation"
priority: should-have
complexity: high
tags: [upload, resilience, media, recovery]
---

# US-419: Resume an Interrupted Media Upload

## User Story

**As a** Creator
**I want to** resume a video upload that was interrupted mid-way
**So that** I don't have to start the entire upload over after a connection drop

## Acceptance Criteria

- **Given** a large video upload has progressed past 20%
  **When** the app is closed or connectivity is lost
  **Then** the upload state is persisted locally

- **Given** the app is reopened after an interrupted upload
  **When** connectivity is available
  **Then** a banner prompts me to resume the upload from where it left off

## Notes
Uses chunked/resumable upload protocol. Partial uploads expire after 48 hours if not resumed.
