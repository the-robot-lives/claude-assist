# Calibrated Answer Block

| Field | Value |
|-------|-------|
| **ID** | `calibrated-answer-block` |
| **Category** | AI-Specific |
| **Used In** | 01-Query & Answer, 02-Knowledge Article Viewer |

## Description

The core generated-content block: a depth-calibrated answer or article body, rendered in the terminal with headings, code blocks, and inline citations. Depth (brevity vs. full explanation) is driven by the user's per-domain expertise level and any one-off override in effect.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | Single-paragraph quick answer for a trivial or expert-level question |
| **Compact** | Standard multi-paragraph answer with headings |
| **Expanded** | Full article body with all sections (background, detail, examples, sources) |

## Props / Configuration

- `depth` — novice \| intermediate \| advanced \| expert; resolved from profile or override
- `domain` — the expertise domain used to resolve depth
- `citations` — ordered list of source references rendered inline
- `verbosity` — brief \| standard \| thorough

## Interactions

- Streams token-by-token as the agent generates it, matching normal Claude Code output behavior.
- Depth can be overridden for a single response without touching stored profile settings.
