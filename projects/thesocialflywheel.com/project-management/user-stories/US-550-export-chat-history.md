---
id: US-550
title: "Export Chat History"
slug: export-chat-history
personas: [P-006]
epic: "Chat & Real-time Messaging"
priority: could-have
complexity: high
tags: [export, data-portability, chat-history, gdpr]
---

# US-550: Export Chat History

## User Story

**As a** Quiet Consumer (P-006)
**I want to** download an export of my DM and group chat history
**So that** I can keep a personal archive and exercise my data portability rights

## Acceptance Criteria

- **Given** I navigate to Settings > Privacy > Download My Data
  **When** I select "Chat history" and choose a date range and format (JSON or plain text)
  **Then** a background job is queued and I receive an in-app and email notification when the export is ready (within 24 hours for up to 2 years of history)

- **Given** the export is ready
  **When** I download it
  **Then** the file contains all my sent and received messages with sender names, timestamps, and attachment metadata (files not included inline but listed with original filenames)

- **Given** an export includes messages in a thread with a user I have blocked
  **When** the file is generated
  **Then** those messages are included with the sender anonymized to "[Blocked User]"

## Notes
Exports are generated server-side, encrypted at rest, and available for 7 days before the download link expires. Only one export can be in-flight per account.
