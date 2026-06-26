---
id: P-001
name: "Dana Okonkwo"
slug: "systems-architect"
archetype: "Systems Architect"
segment: "primary"
tags: [architecture, review, large-systems, modeling]
---

# Dana Okonkwo — Systems Architect

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 38-46 |
| **Role** | Principal Software Architect |
| **Technical Level** | Expert |
| **Industry** | Enterprise SaaS / platform engineering |
| **Location** | Distributed team, US-East HQ |

## Bio

Dana owns the architecture of a 4-million-line platform spread across a dozen services and three languages. Her day is a stream of design reviews, dependency arguments, and "why is this coupled to that" investigations. She is tired of UML diagrams that are beautiful on the day they're drawn and lies six weeks later.

## Goals

1. See the *current* structure of a system, derived from code, not from a stale diagram someone drew last year
2. Trace dependencies and call paths across service and module boundaries to spot coupling and cycles
3. Produce authoritative architecture views she can hand to teams and stakeholders

## Frustrations

1. Diagrams drift out of sync with code the moment they're committed
2. Existing tools (Sparx EA, Rose) model systems as flat 2D walls that don't scale to her codebase
3. Reverse-engineering features in legacy tools are shallow and choke on large repos

## Behaviors

- Lives in the IDE and `git log`; sketches on a whiteboard then abandons the sketch
- Uses Sparx EA reluctantly; exports PlantUML for docs
- Reviews PRs structurally, not just line-by-line

## Job to Be Done

> "When I inherit or audit a large system, I want to see its live structure as a navigable model, so I can reason about coupling and direct change without trusting stale documentation."

## Relationship to Product

Dana is the flagship user. She discovers the tool through an architecture-review pain point, adopts it for its always-live reverse-engineered model, and stays for cross-boundary tracing and on-demand standard diagrams. She churns if ingestion is slow, inaccurate, or can't handle her repo size.

## Scenarios

1. **Coupling audit** — Dana imports the monorepo, frames the whole system, and drills into the service with the most inbound dependencies to understand why it's a bottleneck.
2. **Review handoff** — She projects a subsystem region into a standard UML component diagram and exports it to the design doc.
