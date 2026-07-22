# Verbosity / Depth Slider

| Field | Value |
|-------|-------|
| **ID** | `verbosity-depth-slider` |
| **Category** | Input & Forms |
| **Used In** | 01-Query & Answer, 13-Settings & Preferences |

## Description

Controls how much explanation a `/query` answer includes, either as a persisted default in settings or as a one-off override on a single question.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `--verbose` / `--beginner` flag equivalent |
| **Compact** | Named-level picker (brief/standard/thorough) |
| **Expanded** | Per-domain verbosity override table |

## Props / Configuration

- `level` — brief \| standard \| thorough
- `scope` — default \| one-off \| per-domain

## Interactions

- A one-off override never mutates the stored default.
