---
id: US-469
title: "See a helpful empty feed state"
slug: empty-feed-state
personas: [P-004, P-006]
epic: "Feed & Ranking"
priority: must-have
complexity: low
tags: [empty-state, onboarding, feed, new-user]
---

# US-469: See a Helpful Empty Feed State

## User Story

**As a** cautious newcomer (P-004)
**I want to** see clear guidance when my feed has no posts
**So that** I know what steps to take to start seeing content

## Acceptance Criteria

- **Given** I have no mutuals and no channel subscriptions
  **When** I open the home feed
  **Then** an illustrated empty state appears with the message "Your feed is empty — connect with people and join channels to get started" and two CTA buttons: "Find people" and "Browse channels"

- **Given** I have mutuals but all are inactive (no posts in 30 days)
  **When** I open the home feed
  **Then** an empty state explains "Your mutuals haven't posted recently" and suggests browsing Discovery

- **Given** I reach the genuine end of available posts (scrolled through all content)
  **When** infinite scroll has no more items
  **Then** an end-of-feed message appears: "You're all caught up! Check back later or explore Discovery."

## Notes
Each empty state variant must be tested separately in QA.
