---
id: US-026
title: "Declare an email attribute"
slug: declare-email-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: must-have
complexity: low
tags: [attribute, email, validation, no-migration]
---

# US-026: Declare an email attribute

## User Story

**As a** Service editor
**I want to** add an email attribute to a List
**So that** I collect a validated email address from each signup

## Acceptance Criteria

- **Given** I am editing a List's attributes
  **When** I add an attribute of type `email`
  **Then** it appears on the public form with email validation, no schema migration required
- **Given** a signup submits an invalid email for that attribute
  **When** the form is validated
  **Then** submission is rejected with a field-level error
- **Given** a List needs a primary contact email
  **When** I mark the email attribute as the identity field
  **Then** it is used for reconcile-by-email and unique membership

## Notes
Email attribute typically backs the unique (list_id, lower(email)) constraint.
