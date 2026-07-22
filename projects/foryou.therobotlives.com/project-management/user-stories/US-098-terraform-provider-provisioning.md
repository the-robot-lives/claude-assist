---
id: US-098
title: "Provision lists as code via the Terraform provider"
slug: terraform-provider-provisioning
personas: [P-003]
epic: "Infrastructure"
priority: should-have
complexity: medium
tags: [infra, terraform, iac, provisioning]
---

# US-098: Provision lists as code via the Terraform provider

## User Story

**As a** platform operator
**I want to** manage Services and Lists through terraform-provider-foryou
**So that** provisioning is reproducible and reviewable

## Acceptance Criteria

- **Given** the TF provider
  **When** I declare Services/Lists/attributes in HCL and apply
  **Then** resources are created to match, idempotently
- **Given** a drift between HCL and live state
  **When** I plan
  **Then** the provider reports the diff accurately
- **Given** a resource is removed from HCL
  **When** I apply
  **Then** it is deprovisioned safely

## Notes
Underpins per-site list provisioning for migration (US-090). Mirrors
`Management.FormsController`/`resource_user.go` provider patterns.
