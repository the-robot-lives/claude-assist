---
id: US-139
title: "Profile appearance in search result cards"
slug: profile-in-search-cards
personas: [P-001]
epic: "Profile & Identity"
priority: should-have
complexity: medium
tags: [profile, identity, search, discovery]
---

# US-139: Profile Appearance In Search Result Cards

## User Story

**As a** bridge-builder
**I want to** my profile to render a clear, informative card in search results
**So that** people discovering me across interests can quickly understand who I am and why to connect

## Acceptance Criteria

- **Given** my profile appears in a search result
  **When** the result card renders
  **Then** it shows my avatar, display name, top interest tags, and shared mutual context if any

- **Given** my profile is incomplete
  **When** my card renders in search
  **Then** the card degrades gracefully with sensible placeholders instead of broken or empty fields

## Notes
Card content should reflect interest-tag priority (see US-132) so the most defining tags surface first.
