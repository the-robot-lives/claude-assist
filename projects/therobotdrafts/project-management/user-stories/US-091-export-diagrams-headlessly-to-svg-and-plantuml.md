---
id: US-091
persona: P-008
persona_slug: trd-automation-agent
title: "Export diagrams headlessly to SVG and PlantUML"
epic: "Automation / headless / API"
priority: P1
segment: edge-case
tags: [export, headless, svg, plantuml]
---

# US-091 — Export diagrams headlessly to SVG and PlantUML

**As** ARIA, the automation agent,
**I want** export current diagrams to SVG and PlantUML from a headless command,
**so that** nightly docs and review pipelines never drift from the model.

## Acceptance criteria
- [ ] A headless export command emits SVG and PlantUML for specified regions/notations
- [ ] Output paths and formats are parameterized for pipeline use
- [ ] The command runs without a display and reports what it wrote
- [ ] Requesting an export of an empty/invalid region fails with a clear non-zero error, not an empty file written silently

## Notes
Serves ARIA's doc-export scenario (P-008 scenario 2) and goal 3 (headless artifact export).
