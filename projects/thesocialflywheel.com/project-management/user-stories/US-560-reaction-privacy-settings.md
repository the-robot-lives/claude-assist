---
id: US-560
title: "Control My Reaction Privacy"
slug: reaction-privacy-settings
personas: [P-006]
epic: "Reactions & Engagement"
priority: should-have
complexity: medium
tags: [privacy, reactions, settings]
---

# US-560: Control My Reaction Privacy

## User Story

**As a** Quiet Consumer
**I want to** control who can see my reactions
**So that** I can engage without broadcasting every interaction to my entire web

## Acceptance Criteria

- **Given** I navigate to Privacy Settings
  **When** I find "Who can see my reactions"
  **Then** I can choose: Everyone in my web / Only 1st-degree mutuals / Only me

- **Given** I set reactions to "Only me"
  **When** I react to a post
  **Then** the post's public reaction count increments but my identity is hidden from all reactor lists

## Notes
Default is "Everyone in my web" (degrees 1–4). Setting applies globally; per-post override is not in scope for v1.
