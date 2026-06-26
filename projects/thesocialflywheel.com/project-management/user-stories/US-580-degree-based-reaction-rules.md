---
id: US-580
title: "Enforce Degree-Based Reaction Rules"
slug: degree-based-reaction-rules
personas: [P-004]
epic: "Reactions & Engagement"
priority: must-have
complexity: high
tags: [social-graph, degrees, reactions, rules]
---

# US-580: Enforce Degree-Based Reaction Rules

## User Story

**As a** Cautious Newcomer
**I want to** the platform to enforce degree-based engagement rules transparently
**So that** I understand why I can or cannot react to certain posts

## Acceptance Criteria

- **Given** I try to react to a post from a connection beyond 4th degree
  **Then** the reaction button is disabled with a tooltip explaining the degree limit and how to expand my web

- **Given** I expand my web by mutually connecting with someone
  **When** I revisit a previously locked post that is now within degree 4
  **Then** the reaction button becomes enabled without requiring a page reload

## Notes
Platform enforces degrees 1–4 for full engagement; degree 5+ is read-only. Degree calculation is symmetric (both parties must confirm mutual).
