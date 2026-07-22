---
id: US-084
title: "Clear, Actionable Error When Claude Code Is Unavailable"
slug: clear-error-claude-code-unavailable
personas: [P-003, P-001, P-007]
epic: "Resilience & Errors"
priority: must-have
complexity: low
tags: [error-handling, auth, availability, accessibility]
---

# US-084: Clear, Actionable Error When Claude Code Is Unavailable or Auth Has Expired

## User Story

**As a** developer relying on Claude Code as robot-learns' backend
**I want to** get a clear, actionable error when Claude Code is unreachable or my auth has expired
**So that** I know exactly what to do instead of staring at a cryptic failure

## Acceptance Criteria

- **Given** Claude Code auth has expired
  **When** I run any robot-learns command that needs it
  **Then** I get a plain-text message stating auth expired and the exact command to re-authenticate, with no stack trace

- **Given** Claude Code is unreachable due to a flaky network
  **When** a request times out
  **Then** robot-learns distinguishes "network unreachable" from "auth expired" from "service error" in the message, since the fix differs for each

- **Given** the error message is read via screen reader
  **When** it's printed
  **Then** it's plain sequential text with no reliance on color, icons, or spatial layout to convey meaning

- **Given** the failure happens mid-operation (e.g., mid-quiz grading)
  **When** robot-learns reports the error
  **Then** it also states what happened to my in-progress work (saved/queued/lost) rather than leaving me to guess

## Notes
P-003's flaky on-call networks and P-007's screen-reader use both depend on this being plain, unambiguous text rather than decorated terminal output.
