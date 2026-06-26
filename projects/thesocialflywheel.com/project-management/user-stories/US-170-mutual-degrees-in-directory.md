---
id: US-170
title: "See Mutual Degree Badges in Channel Directory"
slug: mutual-degrees-in-directory
personas: [P-001]
epic: "Interest Channels"
priority: should-have
complexity: medium
tags: [channels, member-directory, mutuals, degrees, network]
---

# US-170: See Mutual Degree Badges in Channel Directory

## User Story

**As a** Bridge-Builder
**I want to** see the degree of mutual connection next to each channel member in the directory
**So that** I can prioritize outreach to closer connections and understand who is within my 1st-degree trust circle versus a more distant discovery

## Acceptance Criteria

- **Given** I am viewing the channel member directory
  **When** a member is a 1st-degree mutual
  **Then** a "1st" badge appears on their avatar in a distinct color from 2nd, 3rd, and 4th degree badges

- **Given** I am viewing the channel member directory
  **When** I hover or long-press a degree badge
  **Then** a tooltip explains what that degree means in plain language (e.g., "You and this person are direct mutuals")

## Notes
Degree is computed at display time from the live graph. Badges use a consistent color scale: 1st = green, 2nd = blue, 3rd = yellow, 4th = grey, no connection = none. Accessibility: color alone must not be the sole differentiator.
