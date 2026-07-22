---
id: P-003
name: "Keith (Site Owner / Admin)"
slug: site-owner-admin
archetype: "Portfolio operator provisioning services and reading signups"
segment: tertiary
tags: [admin, owner, provisioning, export, oversight]
---

# P-003: Keith (Site Owner / Admin)

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 40s |
| Occupation | Founder / operator of the DeRobot portfolio |
| Location | United States |
| Tech comfort | expert |

## Bio
Keith runs the whole portfolio of sites. He provisions a Service per site,
oversees the lists each site collects on, and needs to see who signed up for
what — per service and per list — and export it. He also owns the migration off
listmonk and expects list provisioning to be reproducible via Terraform.

## Goals
- Provision and configure Services (one per portfolio site) reliably.
- View and export signups per service and per list from an admin console.
- Move every site off listmonk onto foryou without losing subscribers.

## Frustrations
- Signups scattered across a shared listmonk with copy-pasted per-site forms.
- No admin surface to see or export list membership.
- Provisioning that is click-only and not codifiable in Terraform.

## Behaviors
- Prefers infrastructure-as-code (terraform-provider-foryou) for provisioning.
- Audits signup counts and health across sites regularly.
- Guards admin surfaces behind proper role checks.

## Job to Be Done
> "When I operate the portfolio, I want to provision services and inspect/export
> signups per list from one admin console, so I can run signup capture across
> every site with confidence."

## Relationship to Product
The admin/owner persona behind the Admin Console (plan item 5), the management
API, and the listmonk migration. Also the direct beneficiary of the RequireAdmin
guard fix.

## Scenarios
- **Scenario 1:** Provision — creates a Service and its lists via the management
  API / TF provider.
- **Scenario 2:** Inspect — opens Admin Console, drills service → list → signups
  table, filters, exports CSV.
- **Scenario 3:** Cutover — repoints a site from listmonk to foryou and backfills
  historical subscribers.
