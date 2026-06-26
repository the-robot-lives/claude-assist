---
id: US-378
title: "Mutual Path Shown for Discovery Item"
slug: mutual-path-shown-for-discovery-item
personas: [P-001]
epic: "Discovery Engine"
priority: should-have
complexity: medium
tags: [discovery, graph, transparency]
---

# US-378: Mutual Path Shown for Discovery Item

## User Story

**As a** Bridge-Builder
**I want to** see a summarized path of how I am connected to the author of a discovery item
**So that** the content feels grounded in my real social network rather than an opaque algorithm

## Acceptance Criteria

- **Given** a discovery item surfaces content from a 3rd-degree mutual
  **When** I tap the "Why surfaced?" detail on the card
  **Then** I see a path such as "You → [1st-degree mutual] → [2nd-degree mutual] → Author" with usernames obfuscated for intermediate nodes at user's privacy setting

- **Given** the path includes a mutual who has a private account
  **When** the path is rendered
  **Then** the private account node is shown as "A connection" without revealing their username

## Notes
Path rendering respects privacy settings of all intermediate accounts in the chain.
