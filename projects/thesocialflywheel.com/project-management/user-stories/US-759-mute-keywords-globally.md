---
id: US-759
title: "Mute Keywords Globally"
slug: mute-keywords-globally
personas: [P-004]
epic: "Settings & Preferences"
priority: should-have
complexity: medium
tags: [content-preferences, mute, keywords, safety]
---

# US-759: Mute Keywords Globally

## User Story

**As a** cautious newcomer
**I want to** mute specific keywords across all lanes
**So that** I can avoid topics that stress me out regardless of who posts them.

## Acceptance Criteria

- **Given** I am on Content Preferences > Muted Keywords
  **When** I add a keyword and save
  **Then** posts containing that keyword are hidden in all lanes including Mutuals and Discovery.

- **Given** I have muted a keyword
  **When** I view the muted list
  **Then** I can remove any keyword and hidden posts containing it become visible again immediately.

## Notes
Keyword matching is case-insensitive and whole-word by default; users can enable partial matching per keyword.
