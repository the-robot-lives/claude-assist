---
id: US-081
title: "Bulk onboarding for NGO programs"
slug: "bulk-ngo-onboarding"
personas: [P-007]
epic: "Onboarding & Setup"
priority: "won't-have-yet"
complexity: "XL"
tags: [onboarding, ngo, bulk, admin]
---

# US-081: Bulk onboarding for NGO programs

## User Story

**As an** NGO program manager (P-007),
**I want to** onboard a batch of merchants at once from a roster (e.g., a training cohort list),
**So that** I don't have to walk each merchant through signup individually.

## Acceptance Criteria

- [ ] Given a program manager has admin access, when they upload a roster (phone numbers + store names) via a bulk import screen, then a pending invite is created per merchant and an SMS invite link is sent to each.
- [ ] Given a merchant taps their invite link, when they complete OTP verification, then their store is pre-populated with the name/type supplied in the roster, skipping redundant setup steps.
- [ ] Given the program manager, when they view the cohort dashboard, then they can see per-merchant onboarding status (invited / verified / active).

## Notes

XL — decompose into (a) bulk import + invite generation, (b) pre-filled setup flow, (c) cohort status dashboard as separate implementation tickets before build. Won't-have-yet for v1 launch; targeted for a post-launch NGO partnership phase. Depends on US-076, US-077.
