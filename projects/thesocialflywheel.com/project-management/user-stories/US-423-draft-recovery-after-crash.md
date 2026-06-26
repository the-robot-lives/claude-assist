---
id: US-423
title: "Recover draft after app crash"
slug: draft-recovery-after-crash
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [drafts, recovery, resilience, auto-save]
---

# US-423: Recover Draft After App Crash

## User Story

**As a** Creator
**I want to** have my in-progress post automatically recovered after the app crashes
**So that** I never lose content due to unexpected app termination

## Acceptance Criteria

- **Given** I have typed at least one character in the composer
  **When** the app crashes or is force-quit
  **Then** a local auto-save captures the current composer state every 10 seconds

- **Given** I reopen the app after a crash
  **When** the composer auto-save exists
  **Then** a "Recover unsaved post?" banner appears with options to restore or discard

## Notes
Recovery applies to text, tags, and audience settings. Partially-uploaded media must be re-attached.
