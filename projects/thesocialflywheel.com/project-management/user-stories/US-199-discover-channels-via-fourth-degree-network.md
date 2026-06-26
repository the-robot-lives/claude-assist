---
id: US-199
title: "Discover Channels via 4th-Degree Mutual Network"
slug: discover-channels-via-fourth-degree-network
personas: [P-001]
epic: "Interest Channels"
priority: should-have
complexity: high
tags: [channels, discovery, network, mutuals, degrees]
---

# US-199: Discover Channels via 4th-Degree Mutual Network

## User Story

**As a** Bridge-Builder
**I want to** discover channels that people within my extended 4th-degree mutual network have joined, even if those channels don't match my existing interest tags
**So that** I can find unexpected communities through social proximity rather than only through keyword and tag matching

## Acceptance Criteria

- **Given** I am on the Discover tab
  **When** the "From Your Network" section is displayed
  **Then** I see channels joined by members within my ≤4th-degree mutual graph, sorted by how many network members are in each channel (most network members first)

- **Given** a channel is surfaced via my network
  **When** its card is displayed
  **Then** it shows "X people in your network are members" with the degree of the closest member noted (e.g., "Including 2 of your 1st-degree mutuals")

- **Given** I have fewer than 5 confirmed mutuals total
  **When** the "From Your Network" section would render
  **Then** it is replaced with an invitation to connect with more mutuals to unlock network-based discovery

## Notes
Network traversal for this feature uses the same ≤4th-degree symmetric mutuals graph as the rest of the platform. Channels excluded via "Not Interested" (US-191) or channels the user has left do not surface here.
