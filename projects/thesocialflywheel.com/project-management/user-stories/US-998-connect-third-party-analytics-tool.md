---
id: US-998
title: "Connect Third-Party Analytics Tool"
slug: connect-third-party-analytics-tool
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: could-have
complexity: high
tags: [integrations, analytics, third-party, oauth]
---

# US-998: Connect Third-Party Analytics Tool

## User Story

**As a** Creator
**I want to** authorize Flywheel to push my analytics events to an external analytics platform (such as a self-hosted instance or approved partner) via OAuth
**So that** I can consolidate my content performance data in a single tool I already use

## Acceptance Criteria

- **Given** the Integrations settings page
  **When** I connect an approved analytics partner via OAuth
  **Then** Flywheel begins forwarding my post impression, reaction, and reach events to that platform in real time

- **Given** a connected analytics integration
  **When** I revoke access from Flywheel
  **Then** event forwarding stops immediately and the partner platform is notified to delete my forwarded data per the partner data agreement

## Notes
Only Flywheel-approved analytics partners are listed. Data forwarded to partners contains only aggregate and anonymized event data; no other users' identities are included.
