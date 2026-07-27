---
id: P-009
name: "Priya Raghavan"
slug: "priya-the-documentation-lead"
archetype: "The Documentation Lead"
segment: "primary"
tags: [technical-writing, docs-as-code, api-documentation, version-drift, single-source-of-truth, docs-team]
---

# Priya Raghavan — The Documentation Lead

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 33-45 |
| **Role** | Documentation Lead / Staff Technical Writer at a B2B SaaS company |
| **Technical Level** | Advanced |
| **Industry** | Developer tools / API platform |
| **Location** | Bangalore, India |

## Bio

Priya owns the documentation set for a platform API used by several thousand developer customers. It's roughly 600 pages across reference, guides, tutorials, and concept material, published with Docusaurus out of a git repo. The reference section is generated from OpenAPI and is always right. The other 450 pages are hand-written prose that restates the reference, and she has no reliable way to know which of them a release just made wrong. Her team is two writers and a rotating engineer.

## Goals

1. Know, on the day a release ships, exactly which pages the change invalidated — instead of learning it from a support ticket six weeks later
2. Draft the corrections and the new task guides against the current spec, so writers edit rather than start from blank
3. Hold one definition per term across the whole set, and have that enforced rather than remembered

## Frustrations

1. v3 renamed three fields and added an auth step. The reference updated automatically; 40 guide pages did not, and finding them meant grepping for old parameter names and hoping the prose spelled them the same way
2. Confluence and Docusaurus both treat a page as a blob — nothing records that this tutorial depends on that endpoint spec, so nothing can tell her the dependency broke
3. Vale catches "don't say 'simply'" but has no idea the product changed; her linter is fluent in style and illiterate about behavior
4. ChatGPT writes plausible quickstarts using parameter names from a version they deprecated last year

## Behaviors

- Works docs-as-code: everything in git, PRs reviewed by engineers, published on merge
- Runs a docs audit before each quarterly release and it always slips, because it's manual
- Keeps a private spreadsheet mapping "features" to "pages that mention them" — perpetually out of date
- Sits in release planning to catch breaking changes early; catches maybe two thirds of them
- Measures success by support ticket deflection and time-to-first-successful-call

## Job to Be Done

> "When engineering ships a breaking change, I want a list of every page that is now wrong plus a draft correction for each that uses the current names, so my two-person team can keep 600 pages true to a product that ships every two weeks."

## Relationship to Product

Priya would discover the Knowledge Base through the technical writing community (Write the Docs Slack, the annual conference) or from an engineer who saw it first. Her onboarding is not "describe your genre and tone" — it is "point at the repo, ingest the OpenAPI spec and the Markdown tree, tell me what's already contradictory." Her decision drivers are ingest fidelity, drift detection precision, and Markdown export that round-trips cleanly into Docusaurus. She'd churn fast on false positives: a consistency engine that flags thirty non-issues per release gets muted and then cancelled. She also needs the canon/generated tag to survive export, because her org will not publish unreviewed AI prose under the company's name.

## Scenarios

1. **Post-release drift sweep** — v3.2 ships. Priya re-imports the updated OpenAPI spec as canon. The consistency engine flags 14 derived entries whose source spec entries changed, ranked by severity: 3 hard errors (a removed parameter still documented as required), 8 terminology drifts, 3 stale examples. She resolves the 3 errors that morning and queues the rest.
2. **New feature, no blank page** — Engineering adds a webhooks endpoint. Priya imports the spec entry, then generates a task guide and a troubleshooting entry from it. Both arrive citing the endpoint spec, the auth concept entry, and the existing retry-policy rule. She rewrites about a third of each for voice, promotes them, and the graph wires the "see also" edges without her writing a single link by hand.
