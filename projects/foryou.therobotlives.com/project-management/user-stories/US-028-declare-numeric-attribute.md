---
id: US-028
title: "Declare numeric attributes"
slug: declare-numeric-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: should-have
complexity: low
tags: [attribute, int, float, numeric, no-migration]
---

# US-028: Declare numeric attributes

## User Story

**As a** Service editor
**I want to** add integer and decimal (int/float) attributes to a List
**So that** I can collect quantities or measures

## Acceptance Criteria

- **Given** I am editing a List's attributes
  **When** I add an attribute of type `int` or `float`
  **Then** it renders as a numeric input with type-appropriate validation
- **Given** a signup enters a non-numeric or out-of-range value
  **When** the form is validated
  **Then** the submission is rejected with a field-level error
- **Given** I set min/max bounds
  **When** a value violates them
  **Then** validation fails clearly

## Notes
