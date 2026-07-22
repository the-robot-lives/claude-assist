---
id: P-006
name: "Casey Blum"
slug: casey-blum
archetype: "The Mechanic"
segment: tertiary
tags: [extensibility, schema-versioning, open-source, sub-agents, tooling]
---

# P-006: Casey Blum

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 31 |
| Occupation | Open-source Tooling Engineer / Developer Tools Contributor |
| Location | Berlin, Germany |
| Tech comfort | high |

## Bio
Casey builds developer tools for a living and can't help but poke at the internals of anything they install. Within a day of setting up `robot-learns`, Casey had already opened the template directory, read every schema file, and started sketching a custom sub-agent. They care less about using the product as intended and more about how cleanly it can be bent, extended, and kept correct as it evolves — the mark of someone who will either become an outsized contributor or an outsized source of edge-case bug reports.

## Goals
- Understand and extend the template system: custom slash commands, new sub-agents, modified schemas.
- Ensure the 9 YAML schemas are versioned sanely so personal customizations survive upstream updates without silent breakage.
- Keep the `knowledge/` index and cross-references internally consistent even after heavy manual editing and schema changes.
- Contribute upstream — fixes, new sub-agents, schema improvements — if the extension points are clean enough to make that worthwhile.

## Frustrations
- Tools that claim to be extensible but actually hardcode assumptions the moment you deviate from the default template.
- Schema or config changes shipped without migration paths, silently breaking a customized setup on update.
- Undocumented coupling between files (e.g., a KB index that gets stale or out of sync when articles are added or edited outside the "blessed" workflow).
- Any sub-agent or command that behaves like a black box with no visibility into what prompt or context it's actually operating on.

## Behaviors
- Reads `CLAUDE.md` (the agent brain file) and every schema under `schemas/*.example` before doing anything else with a new install.
- Writes and tests a custom sub-agent (e.g., a `kb-linker` that cross-references related articles) against the existing `doc-writer` and `topic-expander` patterns.
- Deliberately stress-tests the KB index by bulk-editing files outside the normal flow, then checks whether the index and search still hold up.
- Tracks schema versions across `the-robot-learns` npm releases and writes migration notes for themself — and potentially for others — when a schema changes shape.
- Likely to file detailed GitHub issues with exact reproduction steps rather than vague bug reports, and equally likely to submit a PR if the fix is small.

## Job to Be Done
> "When I want to bend the tool beyond its default template, I want clean extension points and versioned schemas I can rely on, so I can customize and extend the system without my setup silently breaking on the next update."

## Relationship to Product
Casey represents the tertiary but high-leverage segment: not the median user, but the one whose scrutiny determines whether the product's architecture actually holds up under real extension rather than just the happy path demoed in the README. Their interest in the 9 YAML schemas, the sub-agent boundaries (doc-writer, flashcard-generator, topic-expander, quiz-generator, grader), and the template bootstrap process makes them a natural source of both bug reports and unsolicited contributions. A product that keeps Casey engaged and unblocked tends to gain a small but disproportionately valuable pool of community fixes and extensions; a product that frustrates Casey early risks a public, detailed complaint about its extensibility story.

## Scenarios
- **Scenario 1: The Custom Sub-Agent** — Casey writes a new `kb-linker` sub-agent that scans newly generated KB articles and inserts cross-reference links to related existing articles, modeling it closely on `topic-expander`'s existing prompt structure since that's the closest analog in the template.
- **Scenario 2: The Schema Bump** — After upgrading `the-robot-learns` npm package, Casey notices the `flashcard` schema gained a new optional field. They check whether their hand-edited decks still validate, confirm the change is backward compatible, and write themself a short note on what changed in case they need to reference it later.
- **Scenario 3: Index Integrity Stress Test** — Casey manually renames and merges several KB articles outside of any slash command, then runs `/query` against topics those articles cover to see whether the index and search still resolve correctly — and files a precise bug report with exact repro steps when they find a stale reference.
