---
id: US-079
title: "CAPTCHA on Authentication Forms"
slug: captcha-on-auth-forms
personas: [P-004]
epic: "Authentication & Security"
priority: should-have
complexity: medium
tags: [captcha, security, bot-protection, accessibility]
---

# US-079: CAPTCHA on Authentication Forms

## User Story

**As a** cautious newcomer
**I want to** complete a CAPTCHA challenge only when the system detects suspicious behavior
**So that** bots are blocked but my normal login experience is not disrupted

## Acceptance Criteria

- **Given** no suspicious signals are present
  **When** I submit the login form
  **Then** no CAPTCHA is shown and I log in normally

- **Given** suspicious activity is detected (e.g., multiple rapid attempts)
  **When** I submit the login form
  **Then** I am presented with an accessible CAPTCHA challenge including an audio alternative
