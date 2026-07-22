---
id: US-016
title: "Configure Service branding"
slug: service-branding
personas: [P-004]
epic: "Services & Branding"
priority: should-have
complexity: medium
tags: [service, branding, logo, theme]
---

# US-016: Configure Service branding

## User Story

**As a** Service editor
**I want to** set a Service's logo and colors
**So that** its public forms match the site's identity

## Acceptance Criteria

- **Given** I edit a Service's branding
  **When** I upload a logo and set colors
  **Then** public signup forms and widgets for that Service reflect them
- **Given** I provide an invalid image or color
  **When** I save
  **Then** I see a validation error and existing branding is unchanged
- **Given** no branding is set
  **When** a public form renders
  **Then** it falls back to sensible defaults

## Notes
Branding is consumed by the public signup page and embeddable widget.
