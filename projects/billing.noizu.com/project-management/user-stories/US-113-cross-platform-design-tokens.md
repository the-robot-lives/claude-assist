---
id: US-113
title: "Cross-platform design tokens"
slug: cross-platform-design-tokens
personas: [P-007, P-008, P-009]
epic: "Cross-Platform Apps"
priority: should-have
complexity: medium
tags: [design-system, tokens, accessibility]
---

# US-113: Cross-platform design tokens

## User Story

**As a** product designer  
**I want to** define shared color, typography, spacing, state, and semantic tokens for all Billing Noizu apps  
**So that** web, iOS, Android, and macOS feel consistent while respecting platform conventions

## Acceptance Criteria

- **Given** the Billing Noizu design system exists  
  **When** a platform implementation consumes tokens  
  **Then** critical colors, text hierarchy, status indicators, and focus states remain accessible and recognizable across platforms

## Notes
Shared tokens should not force identical components. Web, SwiftUI, AppKit-adjacent SwiftUI, and Material 3 implementations should stay platform-native.
