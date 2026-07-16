---
id: US-010
title: "Ask a Follow-Up Question with Context"
slug: ask-followup-question-with-context
personas: [P-001, P-002]
epic: "Calibrated Q&A"
priority: must-have
complexity: medium
tags: [session-context, follow-up, conversation]
---

# US-010: Ask a Follow-Up Question with Context

## User Story

**As a** developer working through a problem
**I want to** ask a follow-up question that keeps prior session context
**So that** I don't have to re-explain what I already asked

## Acceptance Criteria

- **Given** I asked a question via `/query`
  **When** I ask a follow-up in the same session
  **Then** the answer accounts for the prior question and answer without me repeating context

- **Given** I start a new session
  **When** I ask a question
  **Then** no stale context from a previous, unrelated session leaks into the answer

- **Given** a follow-up shifts to a clearly different topic
  **When** `/query` answers
  **Then** it does not force irrelevant continuity from the earlier context

## Notes
Session context is distinct from the persisted session log (US-011); this story covers in-flight conversational memory.
