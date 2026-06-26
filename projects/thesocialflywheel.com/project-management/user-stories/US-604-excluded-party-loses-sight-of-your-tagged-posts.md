---
id: US-604
title: "Excluded Party Loses Sight of Your Tagged Posts"
slug: excluded-party-loses-sight-of-your-tagged-posts
personas: [P-004]
epic: "Safety: Blocking & Exclusions"
priority: must-have
complexity: medium
tags: [safety, exclusions, tagged-content]
---

# US-604: Excluded Party Loses Sight of Your Tagged Posts

## User Story

**As a** cautious newcomer
**I want to** know that when I exclude an interest the users affiliated with that interest can no longer see my posts carrying that tag
**So that** I am not unknowingly broadcasting to an audience I have chosen to exclude

## Acceptance Criteria

- **Given** I exclude interest tag #MentalHealth
  **When** a user whose profile is tagged #MentalHealth loads their Discovery lane
  **Then** my posts tagged #MentalHealth are absent from their view

- **Given** the exclusion is active
  **When** I publish a new post tagged #MentalHealth
  **Then** that post is also withheld from the excluded audience at publish time

## Notes
Covers the outbound side of the mutual exclusion described in US-603.
