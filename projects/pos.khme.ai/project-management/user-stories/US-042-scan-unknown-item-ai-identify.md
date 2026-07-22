---
id: US-042
title: "Scan an unknown item for AI-assisted identification"
slug: "scan-unknown-item-ai-identify"
personas: [P-005]
epic: "Companion App"
priority: "should-have"
complexity: "L"
tags: [companion-app, ai, barcode, onboarding]
---

# US-042: Scan an unknown item for AI-assisted identification

## User Story

**As a** stockroom clerk (P-005),
**I want to** scan or photograph an item that isn't yet in the catalog and have the app suggest what it is and which category it belongs to,
**So that** I can add new stock to the system quickly without knowing product codes or typing full descriptions.

## Acceptance Criteria

- [ ] Given I scan a barcode that has no catalog match, when the app checks it, then it first attempts a barcode-database lookup (product name, category, typical packaging) before falling back to any other method.
- [ ] Given the barcode lookup finds no match (common for imported/regional goods), when I'm prompted, then I can take a photo of the item, and the app returns AI-suggested name, category, and (if visible) unit size, which I can accept or edit.
- [ ] Given the AI suggestion is uncertain, when confidence is low, then the app clearly labels it as a suggestion ("looks like: Instant Coffee — confirm?") rather than presenting it as fact, and never auto-saves without my confirmation.
- [ ] Given I am offline when scanning an unknown item, when no AI/barcode-lookup service is reachable, then the app falls back gracefully to manual entry ([[US-043]]) rather than blocking the workflow.

## Notes

Barcode-lookup-then-photo-fallback order is a deliberate cost/accuracy tradeoff — barcode DB lookups are cheap and exact, AI image identification is used only when needed. Feeds directly into [[US-043]] for the actual catalog-add step. Cross-epic: AI provider/service integration details belong to Integrations (US-076–100); this story covers the in-app UX only.
