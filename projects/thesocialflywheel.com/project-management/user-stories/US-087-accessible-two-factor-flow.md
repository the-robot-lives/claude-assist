---
id: US-087
title: "Accessible Two-Factor Authentication Flow"
slug: accessible-two-factor-flow
personas: [P-008]
epic: "Authentication & Security"
priority: must-have
complexity: medium
tags: [accessibility, 2fa, wcag, a11y]
---

# US-087: Accessible Two-Factor Authentication Flow

## User Story

**As an** accessibility-first user
**I want to** complete 2FA challenges without barriers related to my disability
**So that** I can secure my account without needing assistance

## Acceptance Criteria

- **Given** I am at the 2FA code entry screen
  **When** I use a screen reader
  **Then** the input field is labeled, the countdown timer is announced, and the "Resend code" link is reachable by keyboard

- **Given** the platform uses a visual TOTP QR code for setup
  **When** I cannot scan the QR code
  **Then** a plaintext secret key is available to copy and enter manually into my authenticator app
