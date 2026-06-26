---
id: US-529
title: "Link Preview in Chat"
slug: link-preview-in-chat
personas: [P-002]
epic: "Chat & Real-time Messaging"
priority: should-have
complexity: medium
tags: [link-preview, media, og-tags]
---

# US-529: Link Preview in Chat

## User Story

**As a** Niche Enthusiast (P-002)
**I want to** see a rich preview card when a URL is shared in a chat
**So that** I can judge whether to open it without leaving the conversation

## Acceptance Criteria

- **Given** I paste or type a URL in a message and send it
  **When** the message renders in the thread
  **Then** a preview card below the URL shows the page title, description, and thumbnail image sourced from OG/Twitter meta tags

- **Given** a URL is pasted that leads to a site with no OG tags
  **When** the preview is attempted
  **Then** only the URL appears with no card, rather than a broken or empty card

- **Given** I want to send a URL without generating a preview
  **When** I wrap it in angle brackets (e.g., <https://example.com>)
  **Then** no preview card is generated for that URL

## Notes
Link previews are fetched server-side to avoid exposing user IP to third-party sites.
