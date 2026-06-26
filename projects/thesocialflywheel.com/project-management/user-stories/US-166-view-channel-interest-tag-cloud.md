---
id: US-166
title: "View Channel Interest Tag Cloud"
slug: view-channel-interest-tag-cloud
personas: [P-002]
epic: "Interest Channels"
priority: could-have
complexity: low
tags: [channels, interest-tags, discovery, browse]
---

# US-166: View Channel Interest Tag Cloud

## User Story

**As a** Niche Enthusiast
**I want to** see an interest tag cloud representing the most popular tags across all channels I belong to
**So that** I can visualize my interest landscape and spot gaps or clusters I haven't explored

## Acceptance Criteria

- **Given** I navigate to the Channels overview or my profile's interest section
  **When** the tag cloud is rendered
  **Then** tags are sized proportionally to how many of my joined channels share that tag, and tapping a tag filters my channel list to those sharing it

- **Given** I have joined fewer than 3 channels
  **When** the tag cloud is shown
  **Then** a prompt encourages me to join more channels to make the tag cloud meaningful

## Notes
Tag cloud should be visually distinct from a flat list — weight-based sizing, not alphabetical sorting. Color coding by interest category is a stretch goal.
