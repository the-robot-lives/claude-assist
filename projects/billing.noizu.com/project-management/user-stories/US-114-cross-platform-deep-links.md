---
id: US-114
title: "Cross-platform deep links"
slug: cross-platform-deep-links
personas: [P-002, P-006, P-008, P-009]
epic: "Cross-Platform Apps"
priority: should-have
complexity: high
tags: [deep-links, universal-links, app-links]
---

# US-114: Cross-platform deep links

## User Story

**As a** billing collaborator  
**I want to** open invoice, customer, payment, estimate, and report links in the best available app  
**So that** email, push, chat, and browser links route me directly to the right billing context

## Acceptance Criteria

- **Given** I open a Billing Noizu link from web, iOS, Android, or macOS  
  **When** I am authorized for the workspace  
  **Then** the appropriate app opens the target record and falls back to web if no native app is installed

## Notes
Use web URLs as the canonical link format. Native universal links and app links should resolve to the same route model.
