# Eval criteria catalog

Recommended `eval` fragments per media type. Thresholds are always **[0,1]** (criterion scores 0–10 are normalized by the tool).

## Shared shape

```yaml
eval:
  pass_threshold: 0.7
  max_attempts: 3
  required_pass: [relevance]
  criteria:
    relevance:
      weight: 3
      description: "..."
      fail_signals: []
  reject_if: []
```

## Image (raster)

```yaml
eval:
  pass_threshold: 0.75
  max_attempts: 3
  required_pass: [relevance]
  criteria:
    relevance:
      weight: 3
      description: "Primary subject and any required text/logo from the brief are present"
      fail_signals: ["missing subject", "missing headline"]
    composition: { weight: 2, description: "Clear hierarchy, balanced layout" }
    technical: { weight: 2, description: "Sharp, correct aspect, no heavy artifacts" }
    brand_fit: { weight: 1, description: "Palette and style match brand notes" }
  reject_if:
    - "watermark or signature visible"
    - "obvious AI artifacts"
```

## SVG

```yaml
eval:
  pass_threshold: 0.7
  required_pass: [validity]
  criteria:
    validity: { weight: 3, description: "Well-formed SVG with viewBox; no markdown fences" }
    brand_fit: { weight: 2, description: "Brand colors and geometry match brief" }
    simplicity: { weight: 2, description: "Readable at small size; compact paths" }
    relevance: { weight: 2, description: "Subject matches brief" }
  reject_if:
    - "contains explanatory prose outside SVG"
    - "photorealistic raster embedded"
```

## Diagram

```yaml
eval:
  pass_threshold: 0.7
  required_pass: [prompt_coverage]
  criteria:
    prompt_coverage: { weight: 3, description: "All primary entities/edges from the brief appear" }
    syntax_quality: { weight: 2, description: "Valid DSL; no fences; renderable" }
    readability: { weight: 2, description: "Labels short and legible when rendered" }
    layout: { weight: 1, description: "Logical flow; minimal edge crossings" }
  reject_if:
    - "missing primary node named in brief"
```

## HTML / landing / style-guide

```yaml
eval:
  pass_threshold: 0.7
  required_pass: [completeness]
  criteria:
    completeness: { weight: 3, description: "All requested sections/features present" }
    responsiveness: { weight: 2, description: "Mobile-friendly layout signals" }
    cta_clarity: { weight: 2, description: "Primary CTA visible and clear" }
    a11y_basics: { weight: 1, description: "Semantic headings; buttons/links labeled" }
  reject_if:
    - "empty body"
    - "external assets required but not declared"
```

## Game (HTML canvas)

```yaml
eval:
  pass_threshold: 0.7
  required_pass: [feature_coverage]
  criteria:
    feature_coverage: { weight: 3, description: "Core mechanics from brief implemented" }
    playability_signals: { weight: 2, description: "Input loop, win/lose, restart" }
    self_contained: { weight: 2, description: "Opens in browser without build step" }
```

## Video

```yaml
eval:
  pass_threshold: 0.7
  required_pass: [prompt_adherence]
  criteria:
    prompt_adherence: { weight: 3, description: "Key subjects and actions from brief visible in frames" }
    motion_quality: { weight: 3, description: "Smooth motion; no severe warping" }
    technical: { weight: 2, description: "Duration and aspect roughly match request" }
  reject_if:
    - "watermark visible"
    - "abrupt cut before promised reveal"
```

## Music (structural)

```yaml
eval:
  mode: structural
  pass_threshold: 0.45
  criteria:
    technical: { weight: 3, description: "Non-silent audio with reasonable duration" }
    genre_fit: { weight: 1, description: "Structural stand-in; semantic later" }
  reject_if:
    - "silence or near-silence"
```

## Voice (structural; ASR later)

```yaml
eval:
  mode: structural
  pass_threshold: 0.45
  required_pass: [technical]
  criteria:
    technical: { weight: 3, description: "Speech audio present, not silence" }
    intelligibility: { weight: 2, description: "Volume proxy for intelligibility" }
  reject_if:
    - "silence or near-silence"
```

## Scorability by extension (runtime)

| Class | Method |
|-------|--------|
| png/jpg/webp | vision LLM |
| svg/mmd/html/tsx/… | text ≤32KB; optional `visual: true` → raster/screenshot → vision |
| mp4/webm/mov | hybrid: frames → vision + structural streams/duration |
| mp3/wav/ogg/flac | structural (duration + mean volume) |
