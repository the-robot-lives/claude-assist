---
id: US-011
title: "Record Every Q&A Session to a Log"
slug: record-qa-session-to-log
personas: [P-001, P-004]
epic: "Knowledge Base"
priority: must-have
complexity: low
tags: [session-log, audit-trail]
---

# US-011: Record Every Q&A Session to a Log

## User Story

**As a** developer building a learning history
**I want to** have every Q&A session recorded to a session log
**So that** I have a durable record of what I asked and learned over time

## Acceptance Criteria

- **Given** I run one or more `/query` commands in a session
  **When** the session ends
  **Then** a session log entry is written capturing the questions, answers, and timestamps

- **Given** a session log is written
  **When** I inspect it
  **Then** it references the knowledge articles created or updated during that session

- **Given** the session is interrupted unexpectedly
  **When** I next launch `robot-learns`
  **Then** the partial session log is preserved rather than lost

## Notes
Foundation for future team/shared KB curation by team leads (P-004).
