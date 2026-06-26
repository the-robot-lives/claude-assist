---
id: US-344
title: "Partial Opt-Out Per Interest Rather Than All-or-Nothing"
slug: partial-opt-out-per-interest
personas: [P-004]
epic: "Opposing-Views Lane"
priority: should-have
complexity: medium
tags: [opposing-views, opt-out, partial, granular, interests]
---

# US-344: Partial Opt-Out Per Interest Rather Than All-or-Nothing

## User Story

**As a** cautious newcomer
**I want to** selectively opt out of opposing views on specific interests rather than turning off the entire lane
**So that** I can benefit from the feature on comfortable topics while avoiding it on topics that cause me distress

## Acceptance Criteria

- **Given** I open Opposing-Views Lane preferences
  **When** I disable opposing views for interest I
  **Then** posts triggered solely by interest I no longer appear in my lane, but posts on other interests still appear

- **Given** I have disabled some interests and the lane shows fewer posts
  **When** I view the lane
  **Then** no placeholder or gap appears where the disabled-interest posts would have been

## Notes
This story overlaps with US-336 (per-interest toggle) but focuses on the opt-out pathway specifically, including the UX flow from the lane itself (not just settings).
