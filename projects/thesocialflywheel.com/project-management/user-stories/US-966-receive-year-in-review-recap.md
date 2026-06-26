---
id: US-966
title: "Receive Year-in-Review Recap"
slug: receive-year-in-review-recap
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [analytics, recap, year-in-review, milestones]
---

# US-966: Receive Year-in-Review Recap

## User Story

**As a** Creator
**I want to** receive a personalized Year-in-Review summary of my top posts, total reach, new mutuals, and most active interest channels
**So that** I can celebrate milestones and share my journey with others

## Acceptance Criteria

- **Given** an account active for at least 3 months during the year
  **When** December arrives or I request my recap
  **Then** I see a shareable recap card showing: top 3 posts by reach, total unique reach, mutuals gained, and top 3 interest channels by engagement

- **Given** my Year-in-Review card
  **When** I tap the Share button
  **Then** a privacy-safe image of the card is generated for sharing outside Flywheel, containing only aggregate stats (no other user data)

- **Given** an account with less than 3 months of activity
  **When** I open the recap
  **Then** I see a partial recap with available data and a note that more data will appear after 3 months of activity

## Notes
Recap is generated annually; users may opt out via privacy settings. Cards use the platform's accessible color palette.
