---
id: US-036
title: "Provision a List via the management API / Terraform provider"
slug: provision-list-via-terraform
personas: [P-003]
epic: "Lists & Attributes"
priority: should-have
complexity: medium
tags: [list, api, terraform, iac, provisioning]
---

# US-036: Provision a List via the management API / Terraform provider

## User Story

**As a** site owner
**I want to** create and configure Lists through the management API and terraform-provider-foryou
**So that** list provisioning is reproducible infrastructure-as-code

## Acceptance Criteria

- **Given** valid management credentials
  **When** I declare a List (and its attributes) via the management API / TF resource
  **Then** the List is created idempotently and matches the declared spec
- **Given** an existing TF-managed List
  **When** I change its definition and re-apply
  **Then** the List is updated in place without duplicating it
- **Given** a List provisioned via TF
  **When** I inspect it in the UI
  **Then** it appears identically to a UI-created List

## Notes
MANDATORY — one List per site for the listmonk migration (US-089+). The
management API is greenfield (foryou has no forms system or management surface
today); build it fresh alongside the List/Attribute/Signup domain.
