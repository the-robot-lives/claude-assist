# Livebook (.livemd) - FIM Solution Documentation

## Description
[Livebook](https://livebook.dev) is an interactive notebook for Elixir. Its `.livemd` format is **Live Markdown** — standard Markdown plus executable Elixir code cells and Kino smart-cell metadata — making it the Elixir-native counterpart to Jupyter for reproducible, runnable technical content. It is the authoring surface that hosts the `kino-*` components catalogued elsewhere in this library.

## Basic Authoring
````markdown
# Rate Limiting in Elixir

A runnable walkthrough using a token bucket.

## Setup

```elixir
Mix.install([:kino, :kino_vega_lite])
```

## Token Bucket

```elixir
defmodule Bucket do
  def refill(tokens, rate, elapsed), do: tokens + rate * elapsed
end

Bucket.refill(0, 2, 5)
```

<!-- livebook:{"output":true} -->

```elixir
Kino.DataTable.new([%{algo: "token", burst: true}])
```
````

## Toolchain
- **Livebook app** - Run/edit `.livemd`, deploy as apps, collaborate
- **Mix.install** - Self-contained dependency declaration per notebook
- **Kino** - Interactive outputs: tables, inputs, plots, maps, mermaid (see `kino-*.md`)
- **livebook server / Livebook Teams** - Host notebooks as deployed apps
- **Export** - Markdown source is the file; render/share via Livebook or HTML

## Strengths
- Live Markdown is readable plain text and Git-friendly
- Reproducible: `Mix.install` pins deps inside the notebook
- Rich interactivity via Kino smart cells (forms, charts, maps, ETS)
- Notebooks deployable as standalone web apps
- First-class for Elixir/BEAM topics where Jupyter is awkward

## Limitations
- Elixir/BEAM-centric (not a general polyglot notebook)
- Smaller ecosystem and audience than Jupyter
- Smart-cell metadata is Livebook-specific
- Rendering interactivity requires the Livebook runtime

## Best Use Cases
- Runnable Elixir/Phoenix/OTP tutorials and explainers
- Reproducible BEAM data-processing and analysis write-ups
- Interactive docs deployed as Livebook apps
- Companion notebooks for Elixir portfolio projects (NoizuPromptLingo, etc.)

## NPL-FIM Integration
```npl
⌜livebook-author|livemd|FIM@1.0⌝
format: livemd (live-markdown)
deps: Mix.install
components: [kino-datatable, kino-vegalite, kino-mermaid]
deploy: livebook-app | html-export
⌞livebook-author⌟
```

NPL agents author `.livemd` when the runnable content targets the Elixir/BEAM ecosystem, composing Kino smart cells for interactivity.
