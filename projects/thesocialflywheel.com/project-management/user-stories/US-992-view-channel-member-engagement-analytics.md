---
id: US-992
title: "View Channel Member Engagement Analytics"
slug: view-channel-member-engagement-analytics
personas: [P-007]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: high
tags: [analytics, moderation, channel, members]
---

# US-992: View Channel Member Engagement Analytics

## User Story

**As a** Channel Moderator
**I want to** see a breakdown of active versus lurking members, top contributors by post volume, and a 90-day retention curve for my channel
**So that** I can identify engagement gaps and recognize active contributors

## Acceptance Criteria

- **Given** a channel I moderate
  **When** I open Member Engagement Analytics
  **Then** I see: % active members (posted or reacted in past 30 days), % lurkers, and a bar chart of top 10 contributors by post count — displaying usernames only if users have opted in to moderator visibility

- **Given** the retention curve view
  **When** I select a member cohort (e.g., joined in January)
  **Then** I see what percentage of that cohort was still active at 30, 60, and 90 days

## Notes
Member identities in the top contributor list are only shown if the user has enabled "visible to channel moderators" in their privacy settings. Otherwise slots show "Anonymous Member."
