---
id: US-088
title: "Business hours/tax settings"
slug: "business-hours-tax-settings"
personas: [P-002, P-006]
epic: "Settings & Localization"
priority: "should-have"
complexity: "M"
tags: [localization, settings, tax]
---

# US-088: Business hours/tax settings

## User Story

**As a** minimart owner (P-002),
**I want to** configure my business hours and applicable tax rate,
**So that** reports reflect accurate operating periods and receipts show correct tax breakdowns.

## Acceptance Criteria

- [ ] Given Settings > Business, when the user enters opening/closing hours per day of week, then reporting features can filter/label sales as within or outside stated hours.
- [ ] Given the user sets a tax rate (or marks the store as tax-exempt), when a sale is completed, then the receipt itemizes tax according to the configured rate.
- [ ] Given no tax rate has been configured, when a sale is completed, then the receipt omits a tax line entirely rather than showing a $0.00 or blank placeholder.

## Notes

Cambodian small-merchant tax reporting requirements are an open regulatory question in the README — this story covers the configuration UI only, not compliance/e-invoicing logic. Related: reporting features (Reporting epic, other agent's range).
