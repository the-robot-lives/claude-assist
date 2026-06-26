---
id: US-094
persona: P-008
persona_slug: trd-automation-agent
title: "Configure endpoints and keys via env/secret"
epic: "Automation / headless / API"
priority: P1
segment: edge-case
tags: [config, env, secrets, security]
---

# US-094 — Configure endpoints and keys via env/secret

**As** ARIA, the automation agent,
**I want** configure the LLM endpoint, model, and API key via environment/secret rather than PlayerPrefs,
**so that** I can run securely in CI without a human entering keys in a GUI modal.

## Acceptance criteria
- [ ] Endpoint, model, and key are read from environment variables/secrets when present, overriding GUI settings
- [ ] No secret is required to be typed into a GUI for headless runs
- [ ] Keys are not written back to disk in plaintext by the headless path
- [ ] A missing/invalid credential fails fast with a clear, non-secret-leaking error

## Notes
Counters UX-review P1-3 (plaintext key in PlayerPrefs); ARIA needs env/secret config (P-008 relationship).
