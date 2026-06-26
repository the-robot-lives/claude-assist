---
id: US-059
persona: P-004
persona_slug: trd-reverse-engineer
title: "Export the recovered model and findings"
epic: "Interchange (XMI/Rose/EA/PlantUML import-export)"
priority: P2
segment: secondary
tags: [export, findings, report, sharing]
---

# US-059 — Export the recovered model and findings

**As** Sven, the reverse engineer,
**I want** export the recovered model and my findings to share with my team,
**so that** my analysis isn't trapped in one local session.

## Acceptance criteria
- [ ] The recovered model exports to a standard interchange format (e.g. XMI) plus a findings list
- [ ] Annotations/findings are included or exported alongside in a machine-readable form
- [ ] Synthetic names and confidence flags survive the export
- [ ] Exporting a model with unresolved regions notes them rather than emitting them as resolved

## Notes
Lets Sven hand off audits; ties his findings (US-055) into interchange.
