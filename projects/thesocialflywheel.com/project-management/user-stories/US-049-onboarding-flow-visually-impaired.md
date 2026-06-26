---
id: US-049
title: "Onboarding Flow for Visually Impaired Users"
slug: onboarding-flow-visually-impaired
personas: [P-008, P-004]
epic: "Onboarding & Account Setup"
priority: must-have
complexity: medium
tags: [accessibility, visual-impairment, a11y, onboarding]
---

# US-049: Onboarding Flow for Visually Impaired Users

## User Story

**As a** visually impaired user
**I want to** the onboarding flow to work fully without relying on colour or images alone
**So that** I can complete setup independently

## Acceptance Criteria

- **Given** I have colour-blindness settings active
  **When** I view interest tile selections
  **Then** selected state is communicated through border/shape change and a text label, not colour alone.

- **Given** an onboarding screen contains a chart or infographic (e.g. the degrees diagram)
  **When** viewed with assistive technology
  **Then** an equivalent text description is available.

## Notes
WCAG 2.1 AA for colour contrast (minimum 4.5:1 for normal text, 3:1 for large text). All informational images have meaningful alt text. Avoid red/green alone for success/error states.
