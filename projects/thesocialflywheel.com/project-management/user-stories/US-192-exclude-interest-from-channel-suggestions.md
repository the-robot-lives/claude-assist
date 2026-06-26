---
id: US-192
title: "Exclude Interest Tag from Channel Suggestions"
slug: exclude-interest-from-channel-suggestions
personas: [P-002]
epic: "Interest Channels"
priority: should-have
complexity: low
tags: [channels, interest-tags, discovery, safety, preferences]
---

# US-192: Exclude Interest Tag from Channel Suggestions

## User Story

**As a** Niche Enthusiast
**I want to** exclude specific interest tags from driving channel suggestions to me
**So that** I can prevent channels around topics I find unpleasant or irrelevant from surfacing in my discovery feed

## Acceptance Criteria

- **Given** I am in Discovery Preferences settings
  **When** I add an interest tag to my "Exclude from Suggestions" list
  **Then** channels whose primary tags include that excluded tag no longer appear in my suggestions or "Related Interests" sections

- **Given** I have excluded an interest tag
  **When** I directly search the directory for channels with that tag
  **Then** they still appear in search results, as exclusion applies only to passive recommendation surfaces

## Notes
This is complementary to the interests/beliefs exclusion in the Safety epic. Excluded tags should be removable from the preferences list at any time. Exclusion does not affect channels the user has already joined.
