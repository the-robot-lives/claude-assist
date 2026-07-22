---
id: US-027
title: "Declare a text attribute"
slug: declare-string-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: low
tags: [attribute, string, text, no-migration]
---

# US-027: Declare a text attribute

## User Story

**As a** Service editor
**I want to** add a free-text (string) attribute to a List
**So that** I can collect names, justifications, or other open input

## Acceptance Criteria

- **Given** I am editing a List's attributes
  **When** I add an attribute of type `string`
  **Then** it renders as a text input on the public form, no migration required
- **Given** I set a max length
  **When** a signup exceeds it
  **Then** the submission is rejected with a field-level error
- **Given** the attribute is saved
  **When** signups submit values
  **Then** the values are stored as jsonb on the signup

## Notes
Example: `name`, `justification` on a Beta Access list.
