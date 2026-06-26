---
id: US-433
title: "Attach multiple link previews to a post"
slug: multiple-link-previews
personas: [P-009]
epic: "Posting & Content Creation"
priority: could-have
complexity: medium
tags: [link, preview, media, multiple]
---

# US-433: Attach Multiple Link Previews to a Post

## User Story

**As a** Creator
**I want to** include previews for multiple URLs in a single post
**So that** I can curate a reading list or compare sources inline

## Acceptance Criteria

- **Given** I paste two or more URLs into the composer
  **When** Open Graph data is fetched for each
  **Then** up to three preview cards are stacked below the post text

- **Given** more than three URLs are detected
  **When** the composer renders
  **Then** only the first three generate preview cards; the rest appear as plain hyperlinks

## Notes
Each preview card can be individually dismissed if the user wants plain text for some links.
