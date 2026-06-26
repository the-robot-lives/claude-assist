---
id: US-977
title: "Embed a Post on External Sites"
slug: embed-a-post-on-external-sites
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: medium
tags: [integrations, embed, oembed, sharing]
---

# US-977: Embed a Post on External Sites

## User Story

**As a** Creator
**I want to** generate an embeddable snippet for any of my public posts
**So that** I can display my Flywheel content on my personal blog or website to drive traffic back to the platform.

## Acceptance Criteria

- **Given** a public post
  **When** I click the "Embed" option in the post menu
  **Then** I receive an HTML iframe snippet and an oEmbed URL that I can paste into any website.

- **Given** an embedded post on an external site
  **When** a visitor views it
  **Then** they see the post text and first image (if any), plus a "View on Flywheel" link, but no Flywheel account UI.

## Notes

Embeds are read-only; viewers cannot react or reply from the embed. Embed rendering respects the post author's content settings (e.g., content warnings are preserved).
