---
id: US-081
title: "Submit a rich noizu.com project inquiry"
slug: enhance-noizu-contact-form
personas: [P-005]
epic: "Inquiries & Lead Capture"
priority: must-have
complexity: medium
tags: [inquiry, noizu-com, contact-form, item-4]
---

# US-081: Submit a rich noizu.com project inquiry

## User Story

**As a** prospective client on noizu.com
**I want to** describe my company, project type, budget, and timeline in the contact form
**So that** I get a relevant, prompt follow-up

## Acceptance Criteria

- **Given** the noizu.com contact form
  **When** it renders
  **Then** it offers optional Company, Project type/service, Budget range, and Timeline atop name + email + free-text inquiry
- **Given** I fill only the required fields
  **When** I submit
  **Then** the submission succeeds with the optional fields empty
- **Given** I fill the optional fields
  **When** I submit
  **Then** their values are stored as declared attributes on the noizu.com "contact" list

## Notes
MANDATORY — plan item 4. Repoints noizu.com `ContactModal.tsx` from listmonk to
the foryou public endpoint targeting a noizu.com "contact" list.
