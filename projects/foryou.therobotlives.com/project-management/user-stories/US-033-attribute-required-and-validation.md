---
id: US-033
title: "Mark attributes required and set validation"
slug: attribute-required-and-validation
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: medium
tags: [attribute, validation, required, rules]
---

# US-033: Mark attributes required and set validation

## User Story

**As a** Service editor
**I want to** mark attributes required or optional and set validation rules
**So that** I collect complete, well-formed data

## Acceptance Criteria

- **Given** I mark an attribute required
  **When** a signup omits it
  **Then** the submission is rejected with a field-level error
- **Given** I set validation rules (pattern, min/max, length)
  **When** a value violates a rule
  **Then** validation fails with a clear message
- **Given** an optional attribute
  **When** a signup leaves it blank
  **Then** the submission succeeds

## Notes
Validation applies on both client and server (US-039).
