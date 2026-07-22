---
id: US-029
title: "Declare a date attribute"
slug: declare-date-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: should-have
complexity: low
tags: [attribute, date, no-migration]
---

# US-029: Declare a date attribute

## User Story

**As a** Service editor
**I want to** add a date attribute to a List
**So that** I can collect calendar dates (e.g. availability, event date)

## Acceptance Criteria

- **Given** I am editing a List's attributes
  **When** I add an attribute of type `date`
  **Then** it renders with a date picker and date validation
- **Given** a signup enters an invalid date
  **When** the form is validated
  **Then** the submission is rejected with a field-level error
- **Given** the attribute is optional
  **When** a signup leaves it blank
  **Then** the submission succeeds

## Notes
