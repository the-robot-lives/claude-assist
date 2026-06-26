---
id: US-974
title: "Cross-Post to External Platforms"
slug: cross-post-to-external-platforms
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: high
tags: [integrations, cross-posting, social-media]
---

# US-974: Cross-Post to External Platforms

## User Story

**As a** Creator
**I want to** connect my Mastodon or Bluesky account and optionally auto-share my Flywheel posts there
**So that** I can grow my audience across platforms without manually duplicating content.

## Acceptance Criteria

- **Given** the Integrations settings page
  **When** I connect my Mastodon or Bluesky account via OAuth
  **Then** my connection is confirmed and I can toggle per-post or automatic cross-posting.

- **Given** auto cross-posting enabled
  **When** I publish a public post on Flywheel
  **Then** the same text (and first image if present) is posted to the connected external account within 2 minutes.

- **Given** a cross-post failure (external API error)
  **When** the error occurs
  **Then** I receive an in-app notification with the reason and an option to retry manually.

## Notes

Cross-posting is opt-in per account and can be toggled per post at publish time. Only public Flywheel posts are eligible; followers-only posts are never cross-posted.
