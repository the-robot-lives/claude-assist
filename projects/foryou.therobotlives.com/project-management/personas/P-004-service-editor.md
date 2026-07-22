---
id: P-004
name: "Priya Raman"
slug: service-editor
archetype: "Service editor who defines lists and typed attributes"
segment: secondary
tags: [editor, lists, attributes, configuration, branding]
---

# P-004: Priya Raman

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 34 |
| Occupation | Growth / lifecycle marketer on a portfolio team |
| Location | Bengaluru, India |
| Tech comfort | medium-high |

## Bio
Priya is a member (editor) of one Service. She designs the signup lists for that
site — a Beta Access list here, a Weekly Digest there — and declares the typed
attributes each list collects. She needs to add fields without waiting on an
engineer or a schema migration.

## Goals
- Create lists within her Service and give each the fields it needs.
- Declare typed attributes (email, string, select, guid, date, …) self-serve.
- Configure per-list contact-preference defaults and double opt-in behavior.

## Frustrations
- Needing an engineer/migration to add one field to a form.
- Rigid form builders that don't support the field types she needs.
- No safe way to reorder or deprecate an attribute without breaking old signups.

## Behaviors
- Iterates on list fields frequently as campaigns evolve.
- Cares about validation (a real email is an email) and required/optional flags.
- Previews the public form before publishing.

## Job to Be Done
> "When I run signup capture for my site, I want to define lists and their typed
> fields myself, so I can launch and iterate forms without engineering help."

## Relationship to Product
The primary author of Lists and Attributes (plan epics 3 & 4). Exercises the
no-migration typed-attribute model, per-list settings, and form preview.

## Scenarios
- **Scenario 1:** New list — creates a Beta Access list and adds email, name,
  invite_token (guid), justification (string).
- **Scenario 2:** Add field — later appends a select attribute with fixed options,
  no migration.
- **Scenario 3:** Preferences — enables weekly-default frequency and double opt-in
  on a newsletter list.
