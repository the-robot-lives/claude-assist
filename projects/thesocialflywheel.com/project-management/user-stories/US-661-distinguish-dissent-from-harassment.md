---
id: US-661
title: "Distinguish Dissent from Harassment"
slug: distinguish-dissent-from-harassment
personas: [P-007, P-005]
epic: "Moderation & Reporting"
priority: must-have
complexity: high
tags: [moderation, opposing-views, policy]
---

# US-661: Distinguish Dissent from Harassment

## User Story

**As a** channel moderator reviewing a report in the Opposing-Views lane
**I want to** see a content-type classification and policy guidance alongside the reported content
**So that** I can apply consistent standards and avoid incorrectly silencing legitimate dissenting opinion

## Acceptance Criteria

- **Given** a report is filed against a post in the Opposing-Views lane
  **When** I open the report card
  **Then** I see a "Content Type" badge — auto-classified as "Dissenting Opinion", "Targeted Attack", or "Needs Review" — along with a collapsible policy tooltip with examples of each

- **Given** I am about to remove a post classified as "Dissenting Opinion"
  **When** I click "Remove"
  **Then** I am shown a confirmation dialog asking me to confirm the removal overrides the dissent classification and to select a specific policy reason

- **Given** I dismiss a report against a "Dissenting Opinion" post
  **When** the decision is logged
  **Then** the audit record captures the classification, my decision, and the reason so platform T&S can audit consistency

## Notes
The Opposing-Views lane intentionally surfaces disagreement; over-moderation here undermines the product's core value proposition.
