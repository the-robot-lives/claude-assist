---
id: US-987
title: "Accessible Analytics Dashboard"
slug: accessible-analytics-dashboard
personas: [P-008]
epic: "Insights, Analytics & Integrations"
priority: must-have
complexity: high
tags: [accessibility, analytics, wcag, keyboard]
---

# US-987: Accessible Analytics Dashboard

## User Story

**As an** Accessibility-First user
**I want to** all analytics charts and data visualizations to have text alternatives, keyboard navigation, and proper ARIA labels
**So that** I can access and understand my analytics data using a screen reader or keyboard-only navigation.

## Acceptance Criteria

- **Given** any chart in the analytics dashboard
  **When** I navigate to it with a keyboard
  **Then** I can access a data table view of the same information via a visually accessible "View as table" toggle.

- **Given** a chart with an ARIA role of "img"
  **When** a screen reader focuses it
  **Then** it announces a meaningful text summary of the chart's key insight (e.g., "Bar chart: Post reach peaked on Tuesday with 1,240 impressions").

- **Given** the full analytics dashboard
  **When** navigated with keyboard only
  **Then** all interactive controls (date pickers, filters, export buttons) are reachable and operable without a mouse.

## Notes
All analytics UI must meet WCAG 2.1 AA. Charts are built with accessible libraries (e.g., Highcharts with accessibility module or equivalent). Automated accessibility tests run in CI.
