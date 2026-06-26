---
id: US-363
title: "Accessible Discovery Item Labels"
slug: accessible-discovery-item-labels
personas: [P-006]
epic: "Discovery Engine"
priority: must-have
complexity: low
tags: [discovery, accessibility]
---

# US-363: Accessible Discovery Item Labels

## User Story

**As a** Quiet Consumer
**I want to** have discovery item labels that are readable by assistive technologies
**So that** screen reader users receive the same surfacing context as sighted users

## Acceptance Criteria

- **Given** a discovery item is rendered in the feed
  **When** a screen reader focuses on the discovery badge
  **Then** it announces both "Discovery" and the surfacing reason in natural language

- **Given** the discovery badge uses an icon or color coding to indicate its type
  **When** a user relies solely on assistive technology
  **Then** all information conveyed by icon or color is also conveyed through text or ARIA attributes

## Notes
Labels must meet WCAG 2.1 AA at minimum.
