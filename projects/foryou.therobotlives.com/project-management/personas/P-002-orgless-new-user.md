---
id: P-002
name: "Dario Fenn"
slug: orgless-new-user
archetype: "New authenticated user with no organization yet"
segment: secondary
tags: [onboarding, organization, first-run, owner-to-be]
---

# P-002: Dario Fenn

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 27 |
| Occupation | Solo founder building a small SaaS |
| Location | Porto, Portugal |
| Tech comfort | high |

## Bio
Dario just authenticated into foryou (via SSO) to set up signup capture for his
own project. He has an account but belongs to **no organization**, so there is
nothing for him to own or configure yet — the app currently strands him.

## Goals
- Create an organization so he can own a Service and start collecting signups.
- Get from "logged in, empty" to "my first list is live" without reading docs.

## Frustrations
- Landing on an empty `/app` with no clear next step.
- Not understanding the Organization → Service → List hierarchy up front.
- Dead-end UIs that assume an org already exists.

## Behaviors
- Explores product UI directly rather than reading documentation.
- Abandons quickly if the first-run path is unclear.
- Expects a visible "create org / get started" call to action.

## Job to Be Done
> "When I log in for the first time with no organization, I want an obvious way
> to create one, so I can start owning and configuring my signup service."

## Relationship to Product
Represents the create-org onboarding gap (plan item 2). His path exercises the
`/app/orgs/new` flow, the orgless CTA on `/app`, and the "+ New org" switcher
entry.

## Scenarios
- **Scenario 1:** First run — logs in, sees an orgless CTA, creates an org with
  slug + name.
- **Scenario 2:** Switcher add — later creates a second org from the org switcher.
- **Scenario 3:** Straight to value — after org creation is guided toward creating
  a first Service and List.
