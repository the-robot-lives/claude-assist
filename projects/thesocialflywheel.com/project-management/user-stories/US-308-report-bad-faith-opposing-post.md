---
id: US-308
title: "Report a Bad-Faith Opposing Post"
slug: report-bad-faith-opposing-post
personas: [P-007]
epic: "Opposing-Views Lane"
priority: must-have
complexity: medium
tags: [opposing-views, report, moderation, safety]
---

# US-308: Report a Bad-Faith Opposing Post

## User Story

**As a** channel moderator
**I want to** report an opposing-view post that appears to be inflammatory or in bad faith
**So that** the moderation team can review it and prevent it from polluting the lane

## Acceptance Criteria

- **Given** I see an opposing-view post in my lane
  **When** I open its action menu
  **Then** a "Report: bad faith opposing view" option is available alongside standard report categories

- **Given** I submit a bad-faith report
  **When** the report is received
  **Then** I see a confirmation and the post is immediately hidden from my lane pending review

- **Given** the report is reviewed and dismissed
  **When** the moderation decision is made
  **Then** I receive a notification that the post was reviewed and no violation was found
