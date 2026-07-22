---
id: US-031
title: "Declare a select attribute with options"
slug: declare-select-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: medium
tags: [attribute, select, options, no-migration]
---

# US-031: Declare a select attribute with options

## User Story

**As a** Service editor
**I want to** add a single-choice (select) attribute with a fixed set of options
**So that** signups pick one value from a controlled list

## Acceptance Criteria

- **Given** I add an attribute of type `select`
  **When** I define its option set and save
  **Then** the public form renders a single-choice control with those options
- **Given** a signup submits a value not in the option set
  **When** the form is validated
  **Then** the submission is rejected
- **Given** I edit the options later
  **When** I remove an option still used by existing signups
  **Then** I am warned and existing values are preserved

## Notes
Options are part of the attribute declaration; no migration to change them.
