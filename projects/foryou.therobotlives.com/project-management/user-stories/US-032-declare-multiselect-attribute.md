---
id: US-032
title: "Declare a multi-select attribute"
slug: declare-multiselect-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: should-have
complexity: medium
tags: [attribute, multi-select, options, no-migration]
---

# US-032: Declare a multi-select attribute

## User Story

**As a** Service editor
**I want to** add a multi-select attribute with a fixed set of options
**So that** signups can choose zero or more values

## Acceptance Criteria

- **Given** I add an attribute of type `multi-select`
  **When** I define its options and save
  **Then** the public form renders a multi-choice control
- **Given** a signup selects several valid options
  **When** they submit
  **Then** all selected values are stored on the signup
- **Given** a signup submits a value outside the option set
  **When** validated
  **Then** the submission is rejected

## Notes
Values stored as a jsonb array on the signup.
