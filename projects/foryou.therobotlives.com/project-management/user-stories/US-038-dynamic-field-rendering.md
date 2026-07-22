---
id: US-038
title: "Render signup fields from declared attributes"
slug: dynamic-field-rendering
personas: [P-001, P-006]
epic: "Signups & Subscriptions"
priority: must-have
complexity: medium
tags: [signup, form, attributes, dynamic]
---

# US-038: Render signup fields from declared attributes

## User Story

**As a** visitor
**I want to** see a form whose fields match the List's declared attributes
**So that** I provide exactly the information the list needs

## Acceptance Criteria

- **Given** a List with typed attributes
  **When** its public form loads
  **Then** each attribute renders with the correct control (email/text/number/date/guid/select/multi-select)
- **Given** an attribute is required
  **When** the form renders
  **Then** it is visibly and programmatically marked required
- **Given** attributes change on the List
  **When** the form is reloaded
  **Then** it reflects the current attribute set without a code change

## Notes
Shared rendering logic drives both the hosted form and the embeddable widget.
