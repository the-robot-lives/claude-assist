---
id: US-069
title: "Ask 'What Do I Know About X' for a Synthesized Summary"
slug: ask-what-do-i-know-about-x
personas: [P-001, P-003]
epic: "Search & Discovery"
priority: must-have
complexity: high
tags: [query, synthesis, summary]
---

# US-069: Ask "What Do I Know About X" for a Synthesized Summary

## User Story

**As a** staff backend engineer who wants visibility into my own knowledge
**I want to** ask "what do I know about X" and get a synthesized summary drawn from across my KB
**So that** I get the substance of what I've learned without manually reading every related article

## Acceptance Criteria

- **Given** several articles, flashcards, and session logs touch on topic X from different angles
  **When** I ask what I know about X
  **Then** I get a single synthesized summary that draws on all of them, not just a list of matching files

- **Given** the synthesized summary is generated
  **When** I review it
  **Then** each claim is traceable back to the source article(s) it came from, so I can verify or dig deeper

- **Given** I'm an SRE checking my coverage of a specific tool or practice across my KB
  **When** I ask about that topic
  **Then** the summary reflects depth of coverage (e.g., notes there are gaps or only shallow notes exist) rather than overstating what's known

- **Given** I ask about a topic with no matching KB content
  **When** the query runs
  **Then** I'm told plainly that nothing is known yet on that topic, instead of a fabricated answer

## Notes
This is the flagship `/query` capability referenced in the product brief; distinct from full-text search ([[US-066]]) in that it synthesizes rather than just retrieves.
