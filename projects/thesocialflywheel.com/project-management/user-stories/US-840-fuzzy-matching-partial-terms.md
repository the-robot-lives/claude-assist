---
id: US-840
title: "Fuzzy Matching for Partial Search Terms"
slug: fuzzy-matching-partial-terms
personas: [P-002]
epic: "Search & Find"
priority: should-have
complexity: medium
tags: [search, fuzzy, partial, matching]
---

# US-840: Fuzzy Matching for Partial Search Terms

## User Story

**As a** niche enthusiast
**I want to** have search match partial terms and common abbreviations
**So that** I find channels and topics even when I only remember part of the name

## Acceptance Criteria

- **Given** I type "photo" in channel search
  **When** results appear
  **Then** channels with "photography", "photojournalism", and "photoshop" in their name or description all appear

- **Given** I type an acronym (e.g., "AI")
  **When** results load
  **Then** channels matching both the acronym and the full phrase (Artificial Intelligence) appear

## Notes
Partial and acronym matches are ranked below exact matches to keep the most relevant results first.
