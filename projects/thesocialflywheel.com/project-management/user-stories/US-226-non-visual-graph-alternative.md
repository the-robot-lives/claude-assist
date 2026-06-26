---
id: US-226
title: "Non-Visual Graph Alternative"
slug: non-visual-graph-alternative
personas: [P-008]
epic: "Mutuals Graph & Degrees"
priority: must-have
complexity: high
tags: [accessibility, graph, a11y]
---

# US-226: Non-Visual Graph Alternative

## User Story

**As an** Accessibility-First user (P-008)
**I want to** access all the information in the visual mutuals graph through a structured text or table alternative
**So that** I can explore my network without relying on the visual canvas

## Acceptance Criteria

- **Given** I navigate to the graph view
  **When** my screen reader or keyboard focus enters the page
  **Then** a prominent "Switch to list view" control is available as the first interactive element

- **Given** I activate list view
  **When** the view loads
  **Then** I see a navigable table or grouped list: 1st-degree mutuals, then 2nd-degree, then 3rd, then 4th — each entry showing name, degree, and mutual count

- **Given** I am using a screen reader in list view
  **When** I navigate through entries
  **Then** each row announces "Name, Nth-degree mutual, X mutuals in common" without requiring visual reference

## Notes
List view must be the default when OS reduced-motion preference is set, or when user has previously selected it.
