---
id: US-294
title: "Preview Incoming Interest Sender Posts"
slug: preview-incoming-interest-sender-posts
personas: [P-001]
epic: "Swipe-to-Match"
priority: must-have
complexity: medium
tags: [inbox, post-preview, one-way, evaluation]
---

# US-294: Preview Incoming Interest Sender Posts

## User Story

**As a** Bridge-Builder (P-001)
**I want to** read recent posts from someone who has expressed interest in me before deciding to accept
**So that** I can make an informed choice rather than connecting blindly

## Acceptance Criteria

- **Given** I open an interest card in my inbox
  **When** the card expands
  **Then** I can scroll through up to 10 of the sender's most recent public posts without accepting the interest

- **Given** I am previewing a sender's posts
  **When** I navigate to a post that links to an external site
  **Then** the link is shown as plain text — it is not rendered as a clickable anchor until we become mutuals

## Notes
Post preview access is read-only and does not notify the sender.
