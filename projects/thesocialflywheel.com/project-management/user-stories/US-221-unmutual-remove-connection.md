---
id: US-221
title: "Unmutual Remove Connection"
slug: unmutual-remove-connection
personas: [P-001]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: medium
tags: [graph, requests, removal]
---

# US-221: Unmutual Remove Connection

## User Story

**As a** Bridge-Builder (P-001)
**I want to** remove someone from my mutuals (unmutual them) from their profile
**So that** I can manage my network and stop seeing their full unfiltered posts in my feed

## Acceptance Criteria

- **Given** I am viewing the profile of a 1st-degree mutual
  **When** I tap "Remove Mutual" and confirm the action
  **Then** the connection is severed: they move to outside-or-distant-degree status and their posts become subject to interest filtering or disappear from my feed

- **Given** I unmutual someone
  **When** the action completes
  **Then** neither party is notified (silent removal), and the removed person can re-send a mutual request after the standard cooldown

- **Given** I unmutual someone
  **When** the action completes
  **Then** their degree in my web is recalculated and may update to a 2nd–4th degree path if one exists through other mutuals
