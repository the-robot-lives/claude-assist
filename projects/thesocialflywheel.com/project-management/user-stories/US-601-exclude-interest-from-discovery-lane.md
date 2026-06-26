---
id: US-601
title: "Exclude Interest from Discovery Lane"
slug: exclude-interest-from-discovery-lane
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, exclusions, discovery]
---

# US-601: Exclude Interest from Discovery Lane

## User Story

**As a** cautious newcomer
**I want to** exclude specific interests or topics from my Discovery lane
**So that** I never encounter content tied to subjects I find distressing or unwanted

## Acceptance Criteria

- **Given** I am in Safety Settings
  **When** I add an interest tag to my exclusion list
  **Then** posts tagged with that interest no longer appear in my Discovery lane

- **Given** an interest is on my exclusion list
  **When** a new post carrying that tag is published
  **Then** it is filtered before reaching my feed

## Notes
Exclusion scope for this story is the Discovery lane; Opposing-Views coverage is US-602.
