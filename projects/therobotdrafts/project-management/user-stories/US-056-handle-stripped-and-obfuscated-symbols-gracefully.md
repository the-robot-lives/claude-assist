---
id: US-056
persona: P-004
persona_slug: trd-reverse-engineer
title: "Handle stripped and obfuscated symbols gracefully"
epic: "Ingestion & reverse-engineering"
priority: P2
segment: secondary
tags: [obfuscation, stripped-symbols, synthetic-names, robustness]
---

# US-056 — Handle stripped and obfuscated symbols gracefully

**As** Sven, the reverse engineer,
**I want** have stripped or obfuscated artifacts produce a usable model with synthetic stable names,
**so that** I can still navigate code whose symbols were destroyed.

## Acceptance criteria
- [ ] Missing/obfuscated names are replaced with deterministic synthetic identifiers stable across re-imports
- [ ] Structure and call edges are recovered even when names are meaningless
- [ ] I can rename a synthetic node and have my name stick across sessions
- [ ] Heavily obfuscated regions are marked low-confidence rather than presented as fully resolved

## Notes
Robustness for Sven's real inputs (vendored/obfuscated binaries); advanced edge handling, hence P2.
