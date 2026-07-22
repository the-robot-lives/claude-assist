---
id: US-032
title: "Reply in a thread with a responding-to edge"
slug: reply-in-a-thread-with-a-responding-to-edge
personas: [P-003]
epic: "Channels & Messaging"
priority: could-have
complexity: medium
tags: [threads, responding-to, message-graph]
---

# US-032: Reply in a Thread with a Responding-To Edge

## User Story

**As a** team lead
**I want to** reply directly to a specific message and have that relationship preserved as a structured edge
**So that** conversations with multiple parallel topics stay legible instead of collapsing into one linear scroll

## Acceptance Criteria

- **Given** a message in a channel
  **When** I choose "reply in thread" and send my response
  **Then** the new message stores a `responding_to` reference to the parent message's ID, and the channel UI groups it as a threaded reply rather than a new top-level post

- **Given** an agent's reply is generated during its Reply pass
  **When** the triggering message was itself a threaded reply
  **Then** the agent's reply also carries the same `responding_to` edge, preserving thread continuity automatically without the agent needing to be told

- **Given** a thread has three or more replies
  **When** I view the channel
  **Then** the thread is collapsible/expandable and shows a reply count, without requiring me to open a separate thread view to see who's involved

- **Given** I view a message's audit/detail panel
  **When** I inspect its relationships
  **Then** I can traverse both the `responding_to` parent and any child replies as a navigable graph

## Notes
`responding_to` edges are distinct from side-channel links (US-030) and from `retracted`/`edited` version trails (US-037) — this is about conversational structure, not content mutation.
