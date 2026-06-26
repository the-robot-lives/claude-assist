# Persona Definition Template

Fill this in to draft a persona before storing it via `Persona.Create`. Each section notes which record field it maps to (see `references/persona-definition-schema.md`). Delete the guidance in _italics_ as you fill.

---

## Top-level

| Field | Value |
|-------|-------|
| `slug` | `____-____`  _( {name}-{role}, unique within the org )_ |
| `name` | `____`  _( full name )_ |
| `role` | `____`  _( role title )_ |
| `organization` | `____`  _( resolved $NPL_ORG, literal )_ |
| `project` _(optional)_ | `____`  _( resolved $NPL_PROJECT )_ |

### `tags` (discovery / task matching)
`[ ____, ____, ____ ]`

### `bio` (markdown narrative → the `bio` field)
> _Who they are, background, years/domains, and how they work. 2–4 sentences. This is what gives the character texture beyond the structured metadata._

---

## metadata.voice

```yaml
voice:
  lexicon:  [ ____, ____, ____ ]    # words THEY reach for that others wouldn't
  patterns: [ ____, ____ ]          # recurring sentence shapes / rhetorical moves
  quirks:   [ ____ ]                # small idiosyncrasies — use sparingly
```

## metadata.personality (OCEAN, 0.0–1.0)

| Trait | Value | Intended delivery effect |
|-------|-------|--------------------------|
| openness | `0._` | _conventional ↔ exploratory_ |
| conscientiousness | `0._` | _loose ↔ exhaustive, edge-cases-first_ |
| extraversion | `0._` | _terse ↔ expansive / thinks out loud_ |
| agreeableness | `0._` | _blunt ↔ warm / consensus-seeking_ |
| neuroticism | `0._` | _calm ↔ worst-case-flagging_ |

_Avoid an all-0.5 profile — pick values that create a recognizable voice._

## metadata.expertise

```yaml
expertise:
  primary:    [ ____ ]   # speak decisively, defend the position
  secondary:  [ ____ ]   # competent, flag uncertainty
  boundaries: [ ____ ]   # explicitly decline / defer — features, not gaps
  learning:   [ ____ ]   # genuine curiosity, asks questions
```

## metadata.relationships

| with (slug) | type | style |
|-------------|------|-------|
| `____` | _trusted-peer / collaborator / reports-to / mentor_ | _how they interact — enables handoffs_ |

---

## Ready-to-call shape

```
ToolCall(tool: "Persona.Create", arguments: {
  "organization": "____", "slug": "____", "name": "____", "role": "____",
  "bio": "____",
  "tags": [ ... ],
  "metadata": {
    "voice":        { "lexicon": [...], "patterns": [...], "quirks": [...] },
    "personality":  { "openness": 0._, "conscientiousness": 0._, "extraversion": 0._,
                      "agreeableness": 0._, "neuroticism": 0._ },
    "expertise":    { "primary": [...], "secondary": [...], "boundaries": [...], "learning": [...] },
    "relationships":[ { "with": "____", "type": "____", "style": "____" } ]
  }
})
```
