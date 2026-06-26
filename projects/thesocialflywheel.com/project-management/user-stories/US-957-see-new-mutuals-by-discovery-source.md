---
id: US-957
title: "See New Mutuals by Discovery Source"
slug: see-new-mutuals-by-discovery-source
personas: [P-003]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: low
tags: [analytics, mutuals, discovery]
---

# US-957: See New Mutuals by Discovery Source

## User Story

**As a** Social Connector
**I want to** see which discovery source (Swipe-to-Match, Discovery lane, organic mutual acceptance) each new mutual came from
**So that** I know which features are growing my network.

## Acceptance Criteria

- **Given** new mutuals added in the past 30 days
  **When** I view the Mutual Sources breakdown
  **Then** I see a pie chart with slices for Swipe-to-Match, Discovery lane, and Organic.

- **Given** a source with zero new mutuals
  **When** viewing the breakdown
  **Then** that source slice is omitted from the chart.

## Notes
Source is recorded at the moment the mutual relationship is established.
