---
id: US-047
title: "Theme the embeddable widget to match a site"
slug: widget-theming
personas: [P-006]
epic: "Signups & Subscriptions"
priority: could-have
complexity: medium
tags: [widget, theming, branding, embed]
---

# US-047: Theme the embeddable widget to match a site

## User Story

**As a** developer embedding the widget
**I want to** theme it to match the host site
**So that** the form looks native to each site

## Acceptance Criteria

- **Given** the widget snippet
  **When** I pass theme options (colors, spacing, mode)
  **Then** the rendered widget reflects them
- **Given** no theme options
  **When** the widget renders
  **Then** it uses the Service's branding defaults (US-016)
- **Given** an iframe embed
  **When** the host site styles it
  **Then** the widget remains functional and isolated from host CSS conflicts

## Notes
Script and iframe embed variants both supported.
