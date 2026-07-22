---
id: US-112
title: "Shared API contract for native apps"
slug: shared-api-contract-for-native-apps
personas: [P-001, P-002, P-008, P-009]
epic: "Cross-Platform Apps"
priority: must-have
complexity: high
tags: [api, native-apps, contracts]
---

# US-112: Shared API contract for native apps

## User Story

**As a** platform engineer  
**I want to** expose typed API contracts for web, iOS, Android, and macOS clients  
**So that** platform apps stay consistent without duplicating billing rules

## Acceptance Criteria

- **Given** a client requests customers, invoices, payments, reports, or app actions  
  **When** the API contract is used by any supported platform  
  **Then** validation, authorization, status transitions, currency values, and audit events behave consistently

## Notes
Financial invariants live server-side. Native apps consume contracts; they do not reimplement invoice numbering, payment application, or balance rules.
