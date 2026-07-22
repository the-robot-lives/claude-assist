---
id: US-042
title: "Tag a conversation checkpoint"
slug: tag-a-conversation-checkpoint
personas: [P-001]
epic: "Parallel-Path Execution"
priority: should-have
complexity: low
tags: [tag, checkpoint, git-style, versioned-content]
---

# US-042: Tag a Conversation Checkpoint

## User Story

**As a** solo staff engineer
**I want to** mark a specific point in a channel or thread's history with a named tag
**So that** I have a stable, referenceable checkpoint I can fork paths from or check out later, independent of where the conversation moves next

## Acceptance Criteria

- **Given** a thread has accumulated messages, memories, and cognition state up to a point in time
  **When** I create a tag with a name (e.g. `pre-refactor-plan`) at the current message
  **Then** the tag is persisted as an immutable pointer to that exact message/state boundary, and appears in the thread's tag list

- **Given** I attempt to create a tag with a name that already exists in the same thread
  **When** I submit it
  **Then** creation is rejected with a uniqueness error, and I'm offered the option to view the existing tag instead of overwriting it

- **Given** a tag exists
  **When** I view the thread timeline
  **Then** the tag is rendered inline as a labeled marker at its message position, distinguishable from ordinary messages

- **Given** a tag has been created
  **When** later messages are posted to the thread
  **Then** the tag continues to point at the same fixed message boundary regardless of subsequent activity

## Notes
Tags are the git-style checkpoint primitive underpinning both manual checkout (US-043) and automated path forking (US-044) — a path launch is functionally "auto-tag current state, then checkout N times." Tag names should be scoped per-thread to avoid cross-thread collisions.
