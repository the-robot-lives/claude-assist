---
id: US-073
title: "Serendipity Mode: Resurface a Random Old Article"
slug: serendipity-mode-random-article
personas: [P-001, P-005]
epic: "Search & Discovery"
priority: could-have
complexity: low
tags: [serendipity, review, spaced-repetition]
---

# US-073: Serendipity Mode: Resurface a Random Old Article

## User Story

**As a** staff backend engineer who wants to reinforce old learning
**I want to** have `robot-learns` occasionally resurface a random older article for review
**So that** things I learned a while back don't fade from memory just because I've moved on to newer topics

## Acceptance Criteria

- **Given** I invoke serendipity mode
  **When** an article is chosen
  **Then** it's weighted toward older/less-recently-viewed articles rather than being a pure uniform-random pick

- **Given** the surfaced article is shown
  **When** I finish reviewing it
  **Then** I can mark it as still relevant, stale, or worth updating, feeding back into KB maintenance signals

- **Given** I'm a career-switcher junior dev building foundational knowledge
  **When** I use serendipity mode repeatedly
  **Then** it avoids resurfacing the same article again too soon, cycling through the KB over time

- **Given** my KB is very new with only a handful of articles
  **When** serendipity mode runs
  **Then** it still returns a reasonable pick rather than requiring a minimum article count to function

## Notes
A "stale" review outcome can feed into the pruning workflow in [[US-059]].
