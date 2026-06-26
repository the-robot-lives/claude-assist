---
id: US-171
title: "Receive Suggested Channels"
slug: suggested-channels
personas: [P-002]
epic: "Interest Channels"
priority: must-have
complexity: high
tags: [channels, suggestions, discovery, algorithm]
---

# US-171: Receive Suggested Channels

## User Story

**As a** Niche Enthusiast
**I want to** receive personalized channel suggestions based on my interest tags and what channels my mutuals have joined
**So that** I can continuously discover niche communities I didn't know existed without actively searching

## Acceptance Criteria

- **Given** I have set up my profile with at least 3 interest tags
  **When** I open the Discover tab
  **Then** I see a "Suggested for You" section with channels ranked by relevance (tag overlap and mutual membership proximity)

- **Given** a suggested channel shares members with my 1st or 2nd-degree mutual network
  **When** that suggestion is displayed
  **Then** it shows a snippet like "3 of your mutuals are members" to contextualize the recommendation

- **Given** I dismiss a suggested channel
  **When** I tap "Not Interested"
  **Then** that channel does not reappear in suggestions and my preference is saved for future ranking

## Notes
Suggestions should refresh at least daily. Channels the user has explicitly dismissed or previously left should never resurface in the default suggestion feed.
