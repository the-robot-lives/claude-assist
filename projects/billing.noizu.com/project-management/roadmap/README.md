---
title: billing.noizu.com Product Management Roadmap
milestone: M0-M5
status: draft
generated: 2026-07-22
---

# billing.noizu.com Product Management Roadmap

## Purpose

`billing.noizu.com` is a finance operations dashboard for invoicing, client billing, payments, estimates, expense rebilling, and revenue tracking across Noizu-operated products and services. The project currently had a concept README and no PM artifact tree; this roadmap seeds 7 personas and 100 user stories so design, PRD, and engineering work can proceed against stable IDs.

## Roadmap Principles

1. Financial state is append-only by default. Invoices, payments, credits, refunds, and write-offs preserve history through explicit events instead of silent overwrites.
2. Human approval gates external financial action. Agent assistance may draft, suggest, summarize, and reconcile, but sending invoices, follow-ups, refunds, and write-offs stay human-confirmed.
3. Stripe-first without PCI expansion. Hosted payment links and webhooks are preferred; raw card or bank data is never stored locally.
4. Project context differentiates the product. Customers, invoices, estimates, and expenses should carry delivery context from projects, milestones, time entries, and support/account notes.
5. Quiet, accessible finance UX. Dense information is acceptable, but flows must remain keyboard-friendly, readable, recoverable, and low-friction.

## Persona Coverage

| Persona | Segment | Primary Roadmap Pressure |
|---------|---------|--------------------------|
| [P-001 Maya Rivera](../personas/P-001-founder-operator.md) | primary | Founder operator |
| [P-002 Nadia Okafor](../personas/P-002-finance-admin.md) | primary | Finance and billing admin |
| [P-003 Owen Patel](../personas/P-003-project-delivery-lead.md) | secondary | Project delivery lead |
| [P-004 Clara Jensen](../personas/P-004-client-ap-contact.md) | secondary | Client accounts payable contact |
| [P-005 Mateo Silva](../personas/P-005-bookkeeper-accountant.md) | tertiary | Bookkeeper and accountant |
| [P-006 Leah Brooks](../personas/P-006-account-manager.md) | tertiary | Account manager |
| [P-007 Eli Freeman](../personas/P-007-accessibility-conscious-owner.md) | edge-case | Accessibility-conscious owner |

## Workstream Lanes

| Lane | Name | Ownership | Story Range |
|------|------|-----------|-------------|
| WS-A | Platform, Access, and Workspace | Auth, workspace setup, roles, setup checklist | US-001..US-010 |
| WS-B | Customers and Contacts | Customer profile, contacts, addresses, terms, history | US-011..US-022 |
| WS-C | Projects and Service Catalog | Billable projects, service items, delivery metadata | US-023..US-032 |
| WS-D | Invoices, PDFs, and Delivery | Drafting, totals, validation, PDF rendering, email delivery | US-033..US-050 |
| WS-E | Estimates and Proposals | Estimate lifecycle, revisions, approval, conversion | US-051..US-060 |
| WS-F | Payments and Credits | Stripe links, manual payments, credits, refunds, reconciliation | US-061..US-072 |
| WS-G | Expenses and Rebilling | Expense capture, receipts, assignment, invoice conversion | US-073..US-080 |
| WS-H | Reporting and Exports | AR dashboard, aging, revenue, tax, CSV exports | US-081..US-088 |
| WS-I | Agent-Assisted Billing | Invoice drafting, risk flags, summaries, follow-ups, explanations | US-089..US-095 |
| WS-J | Settings, Audit, and Accessibility | Branding, payment config, numbering, audit log, keyboard-first UX | US-096..US-100 |

## Milestone Summaries

**M0 - Product Baseline and Contracts.** No user stories delivered. Confirm domain model, route ownership, ledger invariants, Stripe boundary, PDF worker contract, event/audit schema, and export contract before implementation.

**M1 - MVP Billing Spine.** Foundation needed to create customers, configure branding/payment basics, draft validated invoices, generate PDFs, send emails, record manual payments, and view receivables.

Stories: [US-001](../user-stories/US-001-create-secure-account.md), [US-002](../user-stories/US-002-sign-in-with-protected-session.md), [US-003](../user-stories/US-003-reset-forgotten-password.md), [US-004](../user-stories/US-004-invite-billing-teammate.md), [US-005](../user-stories/US-005-accept-workspace-invitation.md), [US-006](../user-stories/US-006-assign-role-permissions.md), [US-008](../user-stories/US-008-complete-billing-setup-checklist.md), [US-011](../user-stories/US-011-create-customer-profile.md), [US-012](../user-stories/US-012-edit-customer-profile.md), [US-013](../user-stories/US-013-archive-inactive-customer.md), [US-014](../user-stories/US-014-add-customer-contact.md), [US-018](../user-stories/US-018-set-customer-payment-terms.md), [US-021](../user-stories/US-021-tag-and-filter-customers.md), [US-023](../user-stories/US-023-create-billable-project.md), [US-024](../user-stories/US-024-assign-project-to-customer.md), [US-025](../user-stories/US-025-create-reusable-service-item.md), [US-029](../user-stories/US-029-track-project-service-period.md), [US-033](../user-stories/US-033-create-draft-invoice.md), [US-034](../user-stories/US-034-add-invoice-line-item.md), [US-035](../user-stories/US-035-edit-draft-invoice.md), [US-036](../user-stories/US-036-calculate-invoice-totals.md), [US-037](../user-stories/US-037-validate-invoice-before-send.md), [US-038](../user-stories/US-038-render-branded-invoice-pdf.md), [US-039](../user-stories/US-039-preview-invoice-email.md), [US-040](../user-stories/US-040-send-invoice-by-email.md), [US-046](../user-stories/US-046-convert-draft-to-final-invoice-number.md), [US-050](../user-stories/US-050-handle-invoice-send-failure.md), [US-062](../user-stories/US-062-record-manual-payment.md), [US-064](../user-stories/US-064-mark-invoice-paid.md), [US-070](../user-stories/US-070-show-payment-history.md), [US-081](../user-stories/US-081-view-accounts-receivable-dashboard.md), [US-082](../user-stories/US-082-view-receivables-aging-report.md), [US-086](../user-stories/US-086-export-customers-csv.md), [US-087](../user-stories/US-087-export-invoices-csv.md), [US-088](../user-stories/US-088-export-payments-csv.md), [US-096](../user-stories/US-096-configure-invoice-branding.md), [US-097](../user-stories/US-097-configure-payment-methods.md), [US-098](../user-stories/US-098-manage-invoice-numbering-rules.md), [US-099](../user-stories/US-099-review-audit-log.md), [US-100](../user-stories/US-100-use-accessible-keyboard-first-workflows.md).

**M2 - Invoice Operations and Collections.** Round out daily billing operations: customer defaults, invoice lifecycle, email resend/view states, credits, partial payments, and activity timelines.

Stories: [US-007](../user-stories/US-007-switch-between-workspaces.md), [US-009](../user-stories/US-009-preview-sample-invoice-during-setup.md), [US-010](../user-stories/US-010-recover-from-setup-validation-errors.md), [US-015](../user-stories/US-015-set-primary-billing-contact.md), [US-016](../user-stories/US-016-store-billing-and-shipping-addresses.md), [US-017](../user-stories/US-017-capture-customer-tax-id.md), [US-019](../user-stories/US-019-set-customer-currency-preference.md), [US-020](../user-stories/US-020-add-internal-customer-notes.md), [US-022](../user-stories/US-022-view-customer-billing-history.md), [US-026](../user-stories/US-026-edit-service-item-pricing.md), [US-027](../user-stories/US-027-set-project-billing-code.md), [US-028](../user-stories/US-028-mark-project-billable-status.md), [US-030](../user-stories/US-030-attach-delivery-notes-to-project.md), [US-031](../user-stories/US-031-map-external-project-references.md), [US-032](../user-stories/US-032-import-service-catalog-csv.md), [US-041](../user-stories/US-041-resend-invoice-email.md), [US-042](../user-stories/US-042-track-invoice-viewed-state.md), [US-043](../user-stories/US-043-void-sent-invoice.md), [US-044](../user-stories/US-044-write-off-invoice-balance.md), [US-045](../user-stories/US-045-duplicate-invoice-as-draft.md), [US-047](../user-stories/US-047-search-and-filter-invoices.md), [US-049](../user-stories/US-049-download-invoice-pdf.md), [US-061](../user-stories/US-061-create-stripe-payment-link.md), [US-063](../user-stories/US-063-record-partial-payment.md), [US-065](../user-stories/US-065-apply-customer-credit.md), [US-066](../user-stories/US-066-create-credit-note.md), [US-067](../user-stories/US-067-record-refund.md), [US-068](../user-stories/US-068-reconcile-stripe-webhook-payment.md), [US-069](../user-stories/US-069-review-unmatched-payment-event.md), [US-071](../user-stories/US-071-protect-payment-data-scope.md), [US-072](../user-stories/US-072-send-payment-receipt.md), [US-083](../user-stories/US-083-view-revenue-by-customer.md), [US-084](../user-stories/US-084-view-revenue-by-project.md), [US-085](../user-stories/US-085-view-tax-summary.md), [US-092](../user-stories/US-092-summarize-customer-billing-history.md), [US-093](../user-stories/US-093-draft-overdue-follow-up-email.md).

**M3 - Estimates, Expenses, and Project Context.** Add estimate-to-invoice workflows, expense rebilling, delivery context, richer reports, and bookkeeping support.

Stories: [US-051](../user-stories/US-051-create-estimate.md), [US-052](../user-stories/US-052-add-estimate-line-items.md), [US-053](../user-stories/US-053-send-estimate-for-approval.md), [US-054](../user-stories/US-054-track-estimate-viewed-status.md), [US-055](../user-stories/US-055-record-estimate-approval.md), [US-056](../user-stories/US-056-revise-estimate.md), [US-057](../user-stories/US-057-compare-estimate-revisions.md), [US-058](../user-stories/US-058-convert-estimate-to-invoice.md), [US-059](../user-stories/US-059-decline-estimate-with-reason.md), [US-060](../user-stories/US-060-expire-stale-estimate.md), [US-073](../user-stories/US-073-capture-expense.md), [US-074](../user-stories/US-074-attach-receipt-file.md), [US-075](../user-stories/US-075-assign-expense-to-customer.md), [US-076](../user-stories/US-076-assign-expense-to-project.md), [US-077](../user-stories/US-077-mark-expense-billable.md), [US-078](../user-stories/US-078-apply-expense-markup.md), [US-079](../user-stories/US-079-convert-expenses-to-invoice-lines.md), [US-080](../user-stories/US-080-export-expense-records.md), [US-089](../user-stories/US-089-draft-invoice-from-milestone.md), [US-090](../user-stories/US-090-draft-invoice-from-time-entries.md).

**M4 - Automation and Integrations.** Introduce higher leverage automation and external coordination, including Stripe webhook reconciliation, time-entry invoice drafting, and client-sensitive follow-up assistance.

Stories: [US-048](../user-stories/US-048-show-invoice-activity-timeline.md), [US-091](../user-stories/US-091-flag-overdue-risk.md), [US-094](../user-stories/US-094-reconcile-imported-payment-events.md), [US-095](../user-stories/US-095-explain-invoice-balance-changes.md).

**M5 - Release Hardening.** Validate full persona journeys, accessibility, auditability, export correctness, data migration/import needs, and operational readiness. No new backlog scope unless release testing exposes a blocker.

## Story Assignment Matrix

| Story | Title | Epic | Lane | Milestone | Priority | Complexity | Depends On |
|-------|-------|------|------|-----------|----------|------|------------|
| [US-001](../user-stories/US-001-create-secure-account.md) | Create secure account | Onboarding and Access | WS-A | M1 | must-have | M | none |
| [US-002](../user-stories/US-002-sign-in-with-protected-session.md) | Sign in with protected session | Onboarding and Access | WS-A | M1 | must-have | M | none |
| [US-003](../user-stories/US-003-reset-forgotten-password.md) | Reset forgotten password | Onboarding and Access | WS-A | M1 | must-have | L | none |
| [US-004](../user-stories/US-004-invite-billing-teammate.md) | Invite billing teammate | Onboarding and Access | WS-A | M1 | must-have | M | none |
| [US-005](../user-stories/US-005-accept-workspace-invitation.md) | Accept workspace invitation | Onboarding and Access | WS-A | M1 | must-have | L | none |
| [US-006](../user-stories/US-006-assign-role-permissions.md) | Assign role permissions | Onboarding and Access | WS-A | M1 | must-have | H | none |
| [US-007](../user-stories/US-007-switch-between-workspaces.md) | Switch between workspaces | Onboarding and Access | WS-A | M2 | should-have | M | none |
| [US-008](../user-stories/US-008-complete-billing-setup-checklist.md) | Complete billing setup checklist | Onboarding and Access | WS-A | M1 | must-have | M | none |
| [US-009](../user-stories/US-009-preview-sample-invoice-during-setup.md) | Preview sample invoice during setup | Onboarding and Access | WS-A | M2 | should-have | M | none |
| [US-010](../user-stories/US-010-recover-from-setup-validation-errors.md) | Recover from setup validation errors | Onboarding and Access | WS-A | M2 | must-have | L | none |
| [US-011](../user-stories/US-011-create-customer-profile.md) | Create customer profile | Customers and Contacts | WS-B | M1 | must-have | M | US-001 |
| [US-012](../user-stories/US-012-edit-customer-profile.md) | Edit customer profile | Customers and Contacts | WS-B | M1 | must-have | M | US-001 |
| [US-013](../user-stories/US-013-archive-inactive-customer.md) | Archive inactive customer | Customers and Contacts | WS-B | M1 | should-have | L | US-001 |
| [US-014](../user-stories/US-014-add-customer-contact.md) | Add customer contact | Customers and Contacts | WS-B | M1 | must-have | M | US-001 |
| [US-015](../user-stories/US-015-set-primary-billing-contact.md) | Set primary billing contact | Customers and Contacts | WS-B | M2 | must-have | L | US-001 |
| [US-016](../user-stories/US-016-store-billing-and-shipping-addresses.md) | Store billing and shipping addresses | Customers and Contacts | WS-B | M2 | must-have | M | US-001 |
| [US-017](../user-stories/US-017-capture-customer-tax-id.md) | Capture customer tax ID | Customers and Contacts | WS-B | M2 | must-have | M | US-001 |
| [US-018](../user-stories/US-018-set-customer-payment-terms.md) | Set customer payment terms | Customers and Contacts | WS-B | M1 | must-have | M | US-001 |
| [US-019](../user-stories/US-019-set-customer-currency-preference.md) | Set customer currency preference | Customers and Contacts | WS-B | M2 | should-have | M | US-001 |
| [US-020](../user-stories/US-020-add-internal-customer-notes.md) | Add internal customer notes | Customers and Contacts | WS-B | M2 | should-have | L | US-001 |
| [US-021](../user-stories/US-021-tag-and-filter-customers.md) | Tag and filter customers | Customers and Contacts | WS-B | M1 | should-have | M | US-001 |
| [US-022](../user-stories/US-022-view-customer-billing-history.md) | View customer billing history | Customers and Contacts | WS-B | M2 | must-have | M | US-001 |
| [US-023](../user-stories/US-023-create-billable-project.md) | Create billable project | Projects and Service Catalog | WS-C | M1 | must-have | M | US-011 |
| [US-024](../user-stories/US-024-assign-project-to-customer.md) | Assign project to customer | Projects and Service Catalog | WS-C | M1 | must-have | M | US-011 |
| [US-025](../user-stories/US-025-create-reusable-service-item.md) | Create reusable service item | Projects and Service Catalog | WS-C | M1 | must-have | M | US-011 |
| [US-026](../user-stories/US-026-edit-service-item-pricing.md) | Edit service item pricing | Projects and Service Catalog | WS-C | M2 | should-have | M | US-011 |
| [US-027](../user-stories/US-027-set-project-billing-code.md) | Set project billing code | Projects and Service Catalog | WS-C | M2 | should-have | M | US-011 |
| [US-028](../user-stories/US-028-mark-project-billable-status.md) | Mark project billable status | Projects and Service Catalog | WS-C | M2 | should-have | L | US-011 |
| [US-029](../user-stories/US-029-track-project-service-period.md) | Track project service period | Projects and Service Catalog | WS-C | M1 | must-have | M | US-011 |
| [US-030](../user-stories/US-030-attach-delivery-notes-to-project.md) | Attach delivery notes to project | Projects and Service Catalog | WS-C | M2 | should-have | M | US-011 |
| [US-031](../user-stories/US-031-map-external-project-references.md) | Map external project references | Projects and Service Catalog | WS-C | M2 | could-have | M | US-011 |
| [US-032](../user-stories/US-032-import-service-catalog-csv.md) | Import service catalog CSV | Projects and Service Catalog | WS-C | M2 | could-have | M | US-011 |
| [US-033](../user-stories/US-033-create-draft-invoice.md) | Create draft invoice | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-034](../user-stories/US-034-add-invoice-line-item.md) | Add invoice line item | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-035](../user-stories/US-035-edit-draft-invoice.md) | Edit draft invoice | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-036](../user-stories/US-036-calculate-invoice-totals.md) | Calculate invoice totals | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-037](../user-stories/US-037-validate-invoice-before-send.md) | Validate invoice before send | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-038](../user-stories/US-038-render-branded-invoice-pdf.md) | Render branded invoice PDF | Invoices and Delivery | WS-D | M1 | must-have | H | US-011, US-023, US-096, US-098 |
| [US-039](../user-stories/US-039-preview-invoice-email.md) | Preview invoice email | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-040](../user-stories/US-040-send-invoice-by-email.md) | Send invoice by email | Invoices and Delivery | WS-D | M1 | must-have | H | US-011, US-023, US-096, US-098 |
| [US-041](../user-stories/US-041-resend-invoice-email.md) | Resend invoice email | Invoices and Delivery | WS-D | M2 | should-have | M | US-011, US-023, US-096, US-098 |
| [US-042](../user-stories/US-042-track-invoice-viewed-state.md) | Track invoice viewed state | Invoices and Delivery | WS-D | M2 | should-have | M | US-011, US-023, US-096, US-098 |
| [US-043](../user-stories/US-043-void-sent-invoice.md) | Void sent invoice | Invoices and Delivery | WS-D | M2 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-044](../user-stories/US-044-write-off-invoice-balance.md) | Write off invoice balance | Invoices and Delivery | WS-D | M2 | should-have | M | US-011, US-023, US-096, US-098 |
| [US-045](../user-stories/US-045-duplicate-invoice-as-draft.md) | Duplicate invoice as draft | Invoices and Delivery | WS-D | M2 | should-have | L | US-011, US-023, US-096, US-098 |
| [US-046](../user-stories/US-046-convert-draft-to-final-invoice-number.md) | Convert draft to final invoice number | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-047](../user-stories/US-047-search-and-filter-invoices.md) | Search and filter invoices | Invoices and Delivery | WS-D | M2 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-048](../user-stories/US-048-show-invoice-activity-timeline.md) | Show invoice activity timeline | Invoices and Delivery | WS-D | M4 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-049](../user-stories/US-049-download-invoice-pdf.md) | Download invoice PDF | Invoices and Delivery | WS-D | M2 | must-have | L | US-011, US-023, US-096, US-098 |
| [US-050](../user-stories/US-050-handle-invoice-send-failure.md) | Handle invoice send failure | Invoices and Delivery | WS-D | M1 | must-have | M | US-011, US-023, US-096, US-098 |
| [US-051](../user-stories/US-051-create-estimate.md) | Create estimate | Estimates and Proposals | WS-E | M3 | should-have | M | US-011, US-023, US-033 |
| [US-052](../user-stories/US-052-add-estimate-line-items.md) | Add estimate line items | Estimates and Proposals | WS-E | M3 | should-have | M | US-011, US-023, US-033 |
| [US-053](../user-stories/US-053-send-estimate-for-approval.md) | Send estimate for approval | Estimates and Proposals | WS-E | M3 | should-have | H | US-011, US-023, US-033 |
| [US-054](../user-stories/US-054-track-estimate-viewed-status.md) | Track estimate viewed status | Estimates and Proposals | WS-E | M3 | could-have | M | US-011, US-023, US-033 |
| [US-055](../user-stories/US-055-record-estimate-approval.md) | Record estimate approval | Estimates and Proposals | WS-E | M3 | should-have | M | US-011, US-023, US-033 |
| [US-056](../user-stories/US-056-revise-estimate.md) | Revise estimate | Estimates and Proposals | WS-E | M3 | should-have | M | US-011, US-023, US-033 |
| [US-057](../user-stories/US-057-compare-estimate-revisions.md) | Compare estimate revisions | Estimates and Proposals | WS-E | M3 | could-have | M | US-011, US-023, US-033 |
| [US-058](../user-stories/US-058-convert-estimate-to-invoice.md) | Convert estimate to invoice | Estimates and Proposals | WS-E | M3 | should-have | H | US-011, US-023, US-033 |
| [US-059](../user-stories/US-059-decline-estimate-with-reason.md) | Decline estimate with reason | Estimates and Proposals | WS-E | M3 | could-have | L | US-011, US-023, US-033 |
| [US-060](../user-stories/US-060-expire-stale-estimate.md) | Expire stale estimate | Estimates and Proposals | WS-E | M3 | could-have | L | US-011, US-023, US-033 |
| [US-061](../user-stories/US-061-create-stripe-payment-link.md) | Create Stripe payment link | Payments and Credits | WS-F | M2 | must-have | H | US-033, US-097 |
| [US-062](../user-stories/US-062-record-manual-payment.md) | Record manual payment | Payments and Credits | WS-F | M1 | must-have | M | US-033, US-097 |
| [US-063](../user-stories/US-063-record-partial-payment.md) | Record partial payment | Payments and Credits | WS-F | M2 | must-have | M | US-033, US-097 |
| [US-064](../user-stories/US-064-mark-invoice-paid.md) | Mark invoice paid | Payments and Credits | WS-F | M1 | must-have | M | US-033, US-097 |
| [US-065](../user-stories/US-065-apply-customer-credit.md) | Apply customer credit | Payments and Credits | WS-F | M2 | should-have | M | US-033, US-097 |
| [US-066](../user-stories/US-066-create-credit-note.md) | Create credit note | Payments and Credits | WS-F | M2 | should-have | M | US-033, US-097 |
| [US-067](../user-stories/US-067-record-refund.md) | Record refund | Payments and Credits | WS-F | M2 | should-have | M | US-033, US-097 |
| [US-068](../user-stories/US-068-reconcile-stripe-webhook-payment.md) | Reconcile Stripe webhook payment | Payments and Credits | WS-F | M2 | should-have | H | US-033, US-097 |
| [US-069](../user-stories/US-069-review-unmatched-payment-event.md) | Review unmatched payment event | Payments and Credits | WS-F | M2 | should-have | M | US-033, US-097 |
| [US-070](../user-stories/US-070-show-payment-history.md) | Show payment history | Payments and Credits | WS-F | M1 | must-have | M | US-033, US-097 |
| [US-071](../user-stories/US-071-protect-payment-data-scope.md) | Protect payment data scope | Payments and Credits | WS-F | M2 | must-have | M | US-033, US-097 |
| [US-072](../user-stories/US-072-send-payment-receipt.md) | Send payment receipt | Payments and Credits | WS-F | M2 | should-have | M | US-033, US-097 |
| [US-073](../user-stories/US-073-capture-expense.md) | Capture expense | Expense Rebilling | WS-G | M3 | should-have | M | US-011, US-023, US-033 |
| [US-074](../user-stories/US-074-attach-receipt-file.md) | Attach receipt file | Expense Rebilling | WS-G | M3 | should-have | M | US-011, US-023, US-033 |
| [US-075](../user-stories/US-075-assign-expense-to-customer.md) | Assign expense to customer | Expense Rebilling | WS-G | M3 | should-have | M | US-011, US-023, US-033 |
| [US-076](../user-stories/US-076-assign-expense-to-project.md) | Assign expense to project | Expense Rebilling | WS-G | M3 | should-have | M | US-011, US-023, US-033 |
| [US-077](../user-stories/US-077-mark-expense-billable.md) | Mark expense billable | Expense Rebilling | WS-G | M3 | should-have | L | US-011, US-023, US-033 |
| [US-078](../user-stories/US-078-apply-expense-markup.md) | Apply expense markup | Expense Rebilling | WS-G | M3 | could-have | M | US-011, US-023, US-033 |
| [US-079](../user-stories/US-079-convert-expenses-to-invoice-lines.md) | Convert expenses to invoice lines | Expense Rebilling | WS-G | M3 | should-have | H | US-011, US-023, US-033 |
| [US-080](../user-stories/US-080-export-expense-records.md) | Export expense records | Expense Rebilling | WS-G | M3 | could-have | M | US-011, US-023, US-033 |
| [US-081](../user-stories/US-081-view-accounts-receivable-dashboard.md) | View accounts receivable dashboard | Reporting and Exports | WS-H | M1 | must-have | H | US-033, US-061 |
| [US-082](../user-stories/US-082-view-receivables-aging-report.md) | View receivables aging report | Reporting and Exports | WS-H | M1 | must-have | M | US-033, US-061 |
| [US-083](../user-stories/US-083-view-revenue-by-customer.md) | View revenue by customer | Reporting and Exports | WS-H | M2 | should-have | M | US-033, US-061 |
| [US-084](../user-stories/US-084-view-revenue-by-project.md) | View revenue by project | Reporting and Exports | WS-H | M2 | should-have | M | US-033, US-061 |
| [US-085](../user-stories/US-085-view-tax-summary.md) | View tax summary | Reporting and Exports | WS-H | M2 | should-have | M | US-033, US-061 |
| [US-086](../user-stories/US-086-export-customers-csv.md) | Export customers CSV | Reporting and Exports | WS-H | M1 | must-have | L | US-033, US-061 |
| [US-087](../user-stories/US-087-export-invoices-csv.md) | Export invoices CSV | Reporting and Exports | WS-H | M1 | must-have | M | US-033, US-061 |
| [US-088](../user-stories/US-088-export-payments-csv.md) | Export payments CSV | Reporting and Exports | WS-H | M1 | must-have | M | US-033, US-061 |
| [US-089](../user-stories/US-089-draft-invoice-from-milestone.md) | Draft invoice from milestone | Agent-Assisted Billing | WS-I | M3 | could-have | H | M1/M2 billing events |
| [US-090](../user-stories/US-090-draft-invoice-from-time-entries.md) | Draft invoice from time entries | Agent-Assisted Billing | WS-I | M3 | could-have | H | M1/M2 billing events |
| [US-091](../user-stories/US-091-flag-overdue-risk.md) | Flag overdue risk | Agent-Assisted Billing | WS-I | M4 | should-have | M | M1/M2 billing events |
| [US-092](../user-stories/US-092-summarize-customer-billing-history.md) | Summarize customer billing history | Agent-Assisted Billing | WS-I | M2 | should-have | M | M1/M2 billing events |
| [US-093](../user-stories/US-093-draft-overdue-follow-up-email.md) | Draft overdue follow-up email | Agent-Assisted Billing | WS-I | M2 | should-have | M | M1/M2 billing events |
| [US-094](../user-stories/US-094-reconcile-imported-payment-events.md) | Reconcile imported payment events | Agent-Assisted Billing | WS-I | M4 | could-have | H | M1/M2 billing events |
| [US-095](../user-stories/US-095-explain-invoice-balance-changes.md) | Explain invoice balance changes | Agent-Assisted Billing | WS-I | M4 | should-have | M | M1/M2 billing events |
| [US-096](../user-stories/US-096-configure-invoice-branding.md) | Configure invoice branding | Settings, Audit, and Accessibility | WS-J | M1 | must-have | M | M0 platform contracts |
| [US-097](../user-stories/US-097-configure-payment-methods.md) | Configure payment methods | Settings, Audit, and Accessibility | WS-J | M1 | must-have | H | M0 platform contracts |
| [US-098](../user-stories/US-098-manage-invoice-numbering-rules.md) | Manage invoice numbering rules | Settings, Audit, and Accessibility | WS-J | M1 | must-have | M | M0 platform contracts |
| [US-099](../user-stories/US-099-review-audit-log.md) | Review audit log | Settings, Audit, and Accessibility | WS-J | M1 | must-have | M | M0 platform contracts |
| [US-100](../user-stories/US-100-use-accessible-keyboard-first-workflows.md) | Use accessible keyboard-first workflows | Settings, Audit, and Accessibility | WS-J | M1 | must-have | M | M0 platform contracts |

Complexity key: `L` = low, `M` = medium, `H` = high.

## M0 Contract Checklist

- Customer, contact, project, service item, invoice, estimate, payment, credit, expense, attachment, email event, and audit event schemas are reviewed before implementation.
- Invoice numbering, void, write-off, credit, refund, and payment reconciliation invariants are documented before mutable workflows ship.
- Stripe integration boundary is explicit: hosted links and webhook references are stored; raw payment instruments are not.
- PDF worker contract defines input HTML, template variables, storage key format, retry behavior, and failure states.
- Export contract defines stable IDs, timestamps, currency formatting, and tax/discount fields for CSV and JSON.
- Agent-assisted workflows disclose generated content and require human confirmation before external communication or balance changes.

## Release Readiness Gates

- Every must-have story has a PRD pass before implementation.
- Every user story maps to at least one screen during the next screen-extraction phase.
- Every persona has at least three completed journey tests.
- Core flows pass keyboard-only testing: customer create, invoice create/send, payment record, export, audit review.
- Financial operations have audit events and recovery paths.
- CSV exports reconcile against invoice/payment totals for representative fixture data.

## Open Decisions

1. Whether `billing.noizu.com` is internal-only first or client-accessible in MVP.
2. Whether estimates are M2 or M3 if client approval portal is needed earlier.
3. Whether multi-entity invoicing is deferred entirely or included as a hidden data-model constraint.
4. Which Noizu products provide first integration inputs: timely, support desk, consulting portal, or subscription systems.
5. Whether accounting-system export targets require QuickBooks/Xero-specific fields before MVP.
