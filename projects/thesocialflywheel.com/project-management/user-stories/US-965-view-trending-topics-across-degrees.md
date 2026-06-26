---
id: US-965
title: "View Trending Topics Across Degrees"
slug: view-trending-topics-across-degrees
personas: [P-003]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: medium
tags: [analytics, trends, topics, network]
---

# US-965: View Trending Topics Across Degrees

## User Story

**As a** Social Connector
**I want to** see which specific topics are gaining traction within my 2nd and 3rd degree network
**So that** I can start conversations that resonate with my extended social circle

## Acceptance Criteria

- **Given** my mutuals web
  **When** I open Trending Topics
  **Then** I see the top 20 topic tags by engagement velocity within my 2nd and 3rd degree connections over the past 7 days

- **Given** a trending topic
  **When** I click it
  **Then** I am taken to a filtered Discovery feed showing posts on that topic from my 2nd and 3rd degree connections

## Notes
Topic tags are derived from post hashtags and interest channel labels. Engagement velocity = (reactions + replies) / hours since post, averaged across posts with the tag.
