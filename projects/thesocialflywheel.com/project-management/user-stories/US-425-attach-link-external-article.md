---
id: US-425
title: "Attach a link to an external article"
slug: attach-link-external-article
personas: [P-002]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [link, external, article, preview]
---

# US-425: Attach a Link to an External Article

## User Story

**As a** Niche Enthusiast
**I want to** share a link to an external article alongside my commentary
**So that** my mutuals have context and can read the source material I am discussing

## Acceptance Criteria

- **Given** I paste a URL from a news or blog site
  **When** the composer fetches Open Graph data
  **Then** a preview card with headline, source domain, and thumbnail is shown

- **Given** the preview card is shown
  **When** I publish
  **Then** recipients can tap the card to open the external URL in a browser

## Notes
Deduplicates with US-404; this story focuses on editorial article use-case and niche community context.
