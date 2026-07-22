---
id: US-077
title: "Store setup wizard"
slug: "store-setup-wizard"
personas: [P-001, P-002]
epic: "Onboarding & Setup"
priority: "must-have"
complexity: "M"
tags: [onboarding, setup]
---

# US-077: Store setup wizard

## User Story

**As a** market-stall owner (P-001),
**I want to** complete a short guided wizard to set up my store profile right after signup,
**So that** my register is ready to sell within minutes.

## Acceptance Criteria

- [ ] Given a newly signed-up user, when they complete signup, then they are routed directly into the store setup wizard (store name, currency convention, business type).
- [ ] Given the wizard, when the user selects a business type (e.g., market stall, minimart), then default catalog categories and tax defaults are pre-populated for that type.
- [ ] Given the user, when they skip optional steps (logo, business hours), then the wizard still completes and those can be configured later in Settings.

## Notes

Wizard should take under 3 minutes for a novice user to complete. Depends on US-076. Related: US-085 (exchange rate), US-088 (business hours/tax).
