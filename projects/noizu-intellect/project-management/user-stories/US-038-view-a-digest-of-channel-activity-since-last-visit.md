---
id: US-038
title: "View a digest of channel activity since last visit"
slug: view-a-digest-of-channel-activity-since-last-visit
personas: [P-003, P-008]
epic: "Channels & Messaging"
priority: should-have
complexity: medium
tags: [digest, summary, unread, accessibility]
---

# US-038: View a Digest of Channel Activity Since Last Visit

## User Story

**As a** team lead returning to a busy channel (and, as a blind developer using a screen reader, someone who can't quickly skim a long scrollback)
**I want to** open a channel and get a summarized digest of what happened since my last visit
**So that** I can catch up in seconds instead of reading every intermediate agent Plan/Reply/Reflect message

## Acceptance Criteria

- **Given** I open a channel with unread activity since my last visit
  **When** the digest is generated
  **Then** it summarizes key events — new decisions/picks, direct mentions of me, path-run completions, and a condensed synopsis of other conversation — grouped and ordered by significance, not strictly chronological

- **Given** the digest is presented to a screen-reader user (P-008)
  **When** they navigate it
  **Then** it is exposed as a semantic, headed structure (not a single unbroken block) so they can jump between sections via standard heading navigation rather than reading linearly

- **Given** I read the digest
  **When** I want more detail on a summarized item
  **Then** I can expand it to jump directly to the underlying message(s) in the full channel history

- **Given** the digest synopsis is itself agent-generated
  **When** it is produced
  **Then** it is generated via a cheap/fast model tier by default (configurable) so digest generation doesn't consume significant budget, per the product's per-branch model selection mechanic

## Notes
Digest is complementary to live streaming (US-031) — streaming is for actively-watched channels, digest is for catch-up after absence. Digest generation should respect [[set-decisions-only-notification-preference]] by defaulting to decision-weighted summaries for P-003.
