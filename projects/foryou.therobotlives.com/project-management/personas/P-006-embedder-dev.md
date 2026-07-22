---
id: P-006
name: "Sasha Vetrov"
slug: embedder-dev
archetype: "Developer embedding the signup widget on an external site"
segment: secondary
tags: [developer, widget, embed, integration, cors]
---

# P-006: Sasha Vetrov

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 29 |
| Occupation | Front-end developer maintaining several portfolio sites |
| Location | Berlin, Germany |
| Tech comfort | expert |

## Bio
Sasha maintains the marketing sites across the portfolio. Today each site
copy-pastes a bespoke React form that POSTs to listmonk with a hardcoded list
UUID. Sasha wants one drop-in widget to embed instead of maintaining N forms.

## Goals
- Embed a signup form with a single script/iframe snippet, no per-site React.
- Have fields render automatically from the list's declared attributes.
- Trust that cross-origin submissions work (CORS) and degrade gracefully.

## Frustrations
- Maintaining copy-pasted signup components across nine-plus sites.
- Hardcoded list UUIDs and duplicated validation logic.
- CORS failures that silently break external signups.

## Behaviors
- Prefers a documented, versioned embed snippet over hand-rolled forms.
- Tests cross-origin behavior and console errors before shipping.
- Wants the widget themeable enough to match each site.

## Job to Be Done
> "When I add signup capture to a site, I want to drop in one widget that renders
> the list's fields, so I stop maintaining bespoke forms per site."

## Relationship to Product
The consumer of the embeddable widget (plan item 3 vehicle) and the CORS-open
public endpoint. Central to the listmonk migration story.

## Scenarios
- **Scenario 1:** Embed — adds the widget snippet to a site pointing at a list.
- **Scenario 2:** Dynamic fields — the widget renders declared attributes with the
  right field types and validation.
- **Scenario 3:** Migration — swaps a legacy listmonk form for the widget and
  verifies cross-origin submit succeeds.
