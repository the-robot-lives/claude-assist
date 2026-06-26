---
id: US-406
title: "Choose post audience by degree"
slug: choose-post-audience-by-degree
personas: [P-009]
epic: "Posting & Content Creation"
priority: must-have
complexity: medium
tags: [visibility, audience, degrees, privacy]
---

# US-406: Choose Post Audience by Degree

## User Story

**As a** Creator
**I want to** restrict or expand my post audience by mutual-graph degree
**So that** I control how widely my content propagates through the network

## Acceptance Criteria

- **Given** I am composing a post
  **When** I open the Audience selector
  **Then** I can choose: Only Me, 1st Degree, Up to 2nd, Up to 3rd, Up to 4th, or Public Channel

- **Given** I select "1st Degree only"
  **When** the post is published
  **Then** only my direct mutuals see it; no propagation to outer degrees occurs

## Notes
Default audience is "Up to 2nd Degree." Channel posts override degree limits for channel subscribers.
