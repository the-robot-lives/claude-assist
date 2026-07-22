# Kino.JS

## What
Kino.JS enables creation of custom JavaScript widgets for Elixir LiveBook notebooks, giving full control over widget markup, behavior, styling, and two-way Elixir↔JavaScript communication.

## How
- The LLM emits Elixir defining a widget: HTML `content`, a `js` string (using `ctx.pushEvent`/`ctx.handleEvent` for Elixir communication), and `css`, passed to `Kino.JS.new(content, js: js, css: css) |> Kino.render()`.
- Rendered by evaluating the LiveBook cell after `Mix.install([{:kino, "~> 0.12"}])`.
- Final artifact: a fully custom interactive widget rendered in a LiveBook cell.

## Why
- Reach for Kino.JS when the built-in Kino widgets aren't enough and you need complete customization — bespoke visualizations, specialized input controls, complex UIs, or integrating a JavaScript library — with direct DOM control and two-way communication.
- Tradeoffs: requires JavaScript knowledge, no built-in security sandboxing, complex setup for simple widgets, browser-compatibility considerations, and harder debugging.
- It is the low-level escape hatch of the Kino family; the higher-level Kino.* widgets (DataTable, Plotly, VegaLite, Mermaid) are built for common cases without custom JS.

## Source
- Solution reference: `fim/solution/kino-js.md`
