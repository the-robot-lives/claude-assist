---
id: US-649
title: "Export Block List Without Exposing Others"
slug: export-block-list-without-exposing-others
personas: [P-008]
epic: "Safety: Blocking & Exclusions"
priority: could-have
complexity: medium
tags: [safety, privacy, export]
---

# US-649: Export Block List Without Exposing Others

## User Story

**As an** accessibility-first user who relies on organised records
**I want to** export my block list in a format that contains only my own safety data
**So that** the export file does not inadvertently expose personal information about the people I have blocked

## Acceptance Criteria

- **Given** I request a safety data export
  **When** the export file is generated
  **Then** blocked user entries contain only the username and block date — no email addresses, phone numbers, or profile metadata

- **Given** the export file contains usernames
  **When** I open it
  **Then** a header note reminds me that this file contains personal safety data and should be stored securely

## Notes
Ties to US-641 but adds the privacy-of-blocked-party constraint explicitly.
