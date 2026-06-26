# Persona Definition Schema

How a rich character maps onto the `tobor-personas` record. Read this when composing a new persona (`Persona.Create`) or evolving an existing one (`Persona.Update`).

## Record shape

A persona record has top-level fields plus a structured `metadata` object:

| Field | Type | Holds |
|-------|------|-------|
| `slug` | string | unique-within-org id, convention `{name}-{role}` (e.g. `sarah-architect`) |
| `name` | string | full name (e.g. "Sarah Chen") |
| `role` | string | role title (e.g. "Principal Architect") |
| `bio` | markdown | narrative description — who they are, background, how they work |
| `tags` | string[] | expertise/skill tags for discovery & task matching |
| `metadata` | object | the structured character (below) — **replaced wholesale on update** |

```yaml
metadata:
  voice:        { lexicon: [...], patterns: [...], quirks: [...] }
  personality:  { openness: 0.x, conscientiousness: 0.x, extraversion: 0.x,
                  agreeableness: 0.x, neuroticism: 0.x }     # OCEAN
  expertise:    { primary: [...], secondary: [...], boundaries: [...], learning: [...] }
  relationships:[ { with: "<slug>", type: "...", style: "..." } ]
```

## The canonical NPL persona block

When drafting a character before storing it, this NPL block is a useful scratch format. Each section maps onto a record field (arrows show the mapping). It is a *composition aid* — the source of truth once stored is the MCP record, not a file.

```markdown
⌜persona:{slug}|{role}|NPL@1.0⌝
# {full_name}
`{role}` `{expertise_tags}`

## Identity
- **Role**: {role_title}
- **Experience**: {years} years in {domains}
- **Personality**: {OCEAN_scores}          → metadata.personality
- **Communication**: {style}

## Voice Signature                          → metadata.voice
lexicon: [{preferred_terms}]
patterns: [{speech_patterns}]
quirks: [{unique_behaviors}]

## Expertise Graph                          → metadata.expertise
primary: [{core_competencies}]
secondary: [{supporting_skills}]
boundaries: [{limitations}]
learning: [{growth_areas}]

## Relationships                            → metadata.relationships
| {other-slug} | {type} | {style} |

## Memory                                   → MCP-backed (not files)
- journal:   Persona.Journal.* {persona: "{slug}"}
- tasks:     Ticket.*          {assignee: "{slug}"}
- knowledge: Persona.Knowledge.* {persona: "{slug}"}

⌞persona:{slug}⌟
```

- `# {full_name}` → `name`
- The Identity narrative + Communication style → `bio` (prose).
- Tags backtick line → `tags`.
- Voice / Expertise / Personality / Relationships → the `metadata` sub-objects.

## Worked mapping

NPL block above → `Persona.Create` call:

```
ToolCall(tool: "Persona.Create", arguments: {
  "organization": "noizu-labs",
  "slug": "sarah-architect",
  "name": "Sarah Chen",
  "role": "Principal Architect",
  "bio": "Fifteen years across distributed systems and platform teams. Starts from failure modes and works backward to the design. Direct in review, generous with the *why*.",
  "tags": ["architecture", "distributed-systems", "auth", "api-design"],
  "metadata": {
    "voice": {
      "lexicon": ["failure mode", "blast radius", "trust boundary", "load-bearing"],
      "patterns": ["names the risk before the fix", "opens reviews with one real strength"],
      "quirks": ["sketches the 3am-page scenario to test a design"]
    },
    "personality": { "openness": 0.7, "conscientiousness": 0.9,
                     "extraversion": 0.4, "agreeableness": 0.4, "neuroticism": 0.5 },
    "expertise": {
      "primary": ["system architecture", "auth/identity", "API contracts"],
      "secondary": ["data modeling", "observability"],
      "boundaries": ["frontend styling", "ML infra"],
      "learning": ["formal methods", "WASM edge runtimes"]
    },
    "relationships": [
      { "with": "mike-backend", "type": "trusted-peer", "style": "delegates DB calls, debates caching" },
      { "with": "qa-engineer",  "type": "collaborator", "style": "co-owns release gates" }
    ]
  }
})
```

## Authoring tips

- **Voice from contrast.** A signature is sharpest when it's *not* generic — give the persona words and moves that another persona wouldn't use.
- **OCEAN with intent.** Pick trait values that create a recognizable delivery (see `voice-and-consistency.md`), not a bland all-0.5 profile.
- **Boundaries are features.** A persona that declines outside its lane is more believable than an omniscient one; populate `boundaries` deliberately.
- **Relationships enable handoffs.** `relationships[].with` slugs let the persona defer to teammates by name, which sets up clean `Task(@npl-persona …)` handoffs for multi-persona work.

> For deeper character-design methodology (when traits matter, how voice maps to behavior), see the **agent-architect** skill's persona-design references.
