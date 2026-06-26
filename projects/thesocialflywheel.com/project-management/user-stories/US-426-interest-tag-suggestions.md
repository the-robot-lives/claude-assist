---
id: US-426
title: "Receive interest-tag suggestions while composing"
slug: interest-tag-suggestions
personas: [P-002]
epic: "Posting & Content Creation"
priority: should-have
complexity: medium
tags: [interests, suggestions, ml, tagging]
---

# US-426: Receive Interest-Tag Suggestions While Composing

## User Story

**As a** Niche Enthusiast
**I want to** see suggested interest tags based on my post's text as I type
**So that** I can quickly tag content accurately without manually browsing all channels

## Acceptance Criteria

- **Given** I have typed at least 20 characters in the composer
  **When** the suggestion engine analyzes the text
  **Then** up to five interest-tag suggestions appear above the tag picker

- **Given** suggestions are shown
  **When** I tap a suggestion
  **Then** the tag is added to my post exactly as if I had selected it manually

## Notes
Suggestions are generated client-side or via a lightweight endpoint; they do not block compose flow.
