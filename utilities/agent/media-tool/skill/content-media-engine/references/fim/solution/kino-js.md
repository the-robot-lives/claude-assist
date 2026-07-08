# Kino.JS / Kino.JS.Live — Custom JavaScript widgets in Elixir Livebook

Kino.JS lets you build **custom, interactive widgets** for Livebook by pairing an Elixir module with a bit of front-end JavaScript. `Kino.JS` renders static (one-way) widgets; `Kino.JS.Live` adds a stateful server process for **two-way** communication (Elixir ⇄ JS) via events. This is the escape hatch behind every higher-level Kino widget (VegaLite, MapLibre, Plotly wrappers) — reach for it when no existing widget fits. Runs only inside Livebook/Kino.

**Current Version**: ships with core `kino` (~> 0.11+)  **License**: Apache-2.0  **Runtime**: Livebook / Kino; your JS runs in the browser cell, your Elixir on the node

> Accuracy note: the real API is a **module that `use Kino.JS`** and defines a `main.js` asset exporting `init(ctx, data)`, created with `Kino.JS.new(__MODULE__, data)`. The stub's `Kino.JS.new(content, js: …, css: …)` keyword form is **not** the current API — the correct patterns are below. On the JS side, the context object is conventionally `ctx` and exposes `ctx.root`, `ctx.pushEvent`, `ctx.handleEvent`, `ctx.importJS`, `ctx.importCSS`.

## Official Resources & Documentation
- Kino.JS docs: https://hexdocs.pm/kino/Kino.JS.html
- Kino.JS.Live docs: https://hexdocs.pm/kino/Kino.JS.Live.html
- Kino smart cells guide: https://hexdocs.pm/kino/Kino.SmartCell.html
- "Custom kinos" tutorial: https://hexdocs.pm/kino/custom_kinos.html
- Kino repo: https://github.com/livebook-dev/kino
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([{:kino, "~> 0.12"}])
```

## Core Syntax / API Reference

### Static widget with `Kino.JS`
A widget is a module that `use Kino.JS`, defines a `main.js` **asset** exporting `init(ctx, data)`, and a constructor calling `Kino.JS.new/2`:
```elixir
defmodule KinoDocs.HTML do
  use Kino.JS

  def new(html) when is_binary(html) do
    Kino.JS.new(__MODULE__, html)
  end

  asset "main.js" do
    """
    export function init(ctx, html) {
      ctx.root.innerHTML = html;
    }
    """
  end
end

KinoDocs.HTML.new("<h3>Hello from JS</h3>")
```
- `Kino.JS.new(module, data)` — `data` is any term serializable to JSON; it arrives as the 2nd arg of `init`.
- `asset "main.js" do … end` — inline the entry module. It **must** `export function init(ctx, data)`.
- `ctx.root` — the DOM node you render into.

### Assets from files instead of inline
```elixir
defmodule KinoDocs.Widget do
  use Kino.JS
  # serves everything under priv/assets/widget, main.js is the entry
  @assets_dir "priv/assets/widget"
  def new(data), do: Kino.JS.new(__MODULE__, data)
end
```
Inline `asset` blocks are simplest for FIM/notebook output; a directory is for shipping a real package.

### Loading external JS/CSS from the client
Inside `init`, pull in libraries at runtime:
```elixir
asset "main.js" do
  """
  export async function init(ctx, data) {
    await ctx.importJS("https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js");
    await ctx.importCSS("https://cdn.jsdelivr.net/npm/some-lib/dist/style.css");
    // window.d3 is now available
    ctx.root.innerHTML = "<svg width='400' height='200'></svg>";
  }
  """
end
```

### Stateful, two-way widget with `Kino.JS.Live`
`Kino.JS.Live` runs a server process (GenServer-like) that holds state and exchanges events with the browser:
```elixir
defmodule KinoDocs.Counter do
  use Kino.JS
  use Kino.JS.Live

  def new(initial \\ 0), do: Kino.JS.Live.new(__MODULE__, initial)

  # broadcast a reset to all connected clients
  def reset(kino), do: Kino.JS.Live.cast(kino, :reset)

  @impl true
  def init(initial, ctx) do
    {:ok, assign(ctx, count: initial)}
  end

  # called each time a browser client connects — send it current state
  @impl true
  def handle_connect(ctx) do
    {:ok, ctx.assigns.count, ctx}
  end

  # events pushed from JS via ctx.pushEvent(name, payload)
  @impl true
  def handle_event("bump", %{"by" => by}, ctx) do
    count = ctx.assigns.count + by
    broadcast_event(ctx, "update", count)
    {:noreply, assign(ctx, count: count)}
  end

  # casts from Elixir (e.g. Counter.reset/1)
  @impl true
  def handle_cast(:reset, ctx) do
    broadcast_event(ctx, "update", 0)
    {:noreply, assign(ctx, count: 0)}
  end

  asset "main.js" do
    """
    export function init(ctx, count) {
      ctx.root.innerHTML = `
        <button id="inc">+</button>
        <span id="c">${count}</span>
        <button id="dec">-</button>`;
      const c = ctx.root.querySelector("#c");
      ctx.root.querySelector("#inc").onclick = () => ctx.pushEvent("bump", {by: 1});
      ctx.root.querySelector("#dec").onclick = () => ctx.pushEvent("bump", {by: -1});
      ctx.handleEvent("update", (n) => { c.textContent = n; });
    }
    """
  end
end

KinoDocs.Counter.new(0)
```

### The `Kino.JS.Live` callback surface
| Callback | Purpose |
|---|---|
| `init(arg, ctx)` | set initial server state (`assign/2`) |
| `handle_connect(ctx)` | return `{:ok, initial_data, ctx}` sent to a newly connected client |
| `handle_event(name, payload, ctx)` | handle a `ctx.pushEvent` from JS |
| `handle_cast(msg, ctx)` | handle `Kino.JS.Live.cast/2` from Elixir |
| `handle_call(msg, from, ctx)` | handle `Kino.JS.Live.call/2` (synchronous) |
| `handle_info(msg, ctx)` | handle arbitrary process messages (timers, PubSub) |

Elixir→browser: `broadcast_event(ctx, name, payload)` (all clients) or `send_event(ctx, client_id, name, payload)` (one). Browser→Elixir: `ctx.pushEvent(name, payload)`.

### JS-side `ctx` API (inside `init`)
- `ctx.root` — the widget's root DOM element.
- `ctx.pushEvent(name, payload)` — send an event to Elixir (`handle_event`).
- `ctx.handleEvent(name, (payload) => …)` — receive an Elixir `broadcast_event`/`send_event`.
- `ctx.importJS(url)` / `ctx.importCSS(url)` — async-load external assets.
- `ctx.handleSync(...)` — advanced synchronization hook (rarely needed).

## Widget types you can build
Static HTML/SVG renderers, chart wrappers (D3/Plotly/Chart.js loaded via `importJS`), custom input controls (sliders, color pickers, canvases) that push values back to Elixir, live dashboards driven by `handle_info` timers or PubSub, editable tables/grids, and full smart cells (via `Kino.SmartCell`) that generate Elixir code from a UI.

## How-To (worked recipes)

### How to style a Kino.JS widget (CSS-in-JS / importCSS / theming)
There is no `css:` option — inject a `<style>` in `init`, or `ctx.importCSS`:
```elixir
asset "main.js" do
  """
  export function init(ctx, data) {
    ctx.root.innerHTML = `
      <style>
        .card { padding:16px; border-radius:10px; background:#0f172a; color:#e2e8f0;
                font-family: ui-sans-serif, system-ui; border:1px solid #334155; }
        .card button { margin:0 8px; padding:4px 12px; border-radius:6px;
                       border:1px solid #475569; background:#1e293b; color:#e2e8f0; cursor:pointer; }
        @media (prefers-color-scheme: light) {
          .card { background:#fff; color:#0f172a; border-color:#e2e8f0; }
        }
      </style>
      <div class="card">${data.label}</div>`;
  }
  """
end
```
Scope selectors to your widget (a wrapper class) so styles don't leak across cells.

### How to load and use an external chart library
```elixir
defmodule TinyChart do
  use Kino.JS
  def new(points), do: Kino.JS.new(__MODULE__, points)

  asset "main.js" do
    """
    export async function init(ctx, points) {
      await ctx.importJS("https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js");
      const canvas = document.createElement("canvas");
      ctx.root.appendChild(canvas);
      new Chart(canvas, {
        type: "line",
        data: { labels: points.map(p => p.x), datasets: [{ data: points.map(p => p.y) }] }
      });
    }
    """
  end
end

TinyChart.new(Enum.map(1..10, &%{x: &1, y: &1 * &1}))
```

### How to push updates from Elixir to the browser on a timer
```elixir
defmodule Clock do
  use Kino.JS
  use Kino.JS.Live
  def new(), do: Kino.JS.Live.new(__MODULE__, nil)

  @impl true
  def init(_, ctx) do
    Process.send_after(self(), :tick, 1000)
    {:ok, assign(ctx, time: DateTime.utc_now())}
  end

  @impl true
  def handle_connect(ctx), do: {:ok, DateTime.to_string(ctx.assigns.time), ctx}

  @impl true
  def handle_info(:tick, ctx) do
    now = DateTime.utc_now()
    broadcast_event(ctx, "tick", DateTime.to_string(now))
    Process.send_after(self(), :tick, 1000)
    {:noreply, assign(ctx, time: now)}
  end

  asset "main.js" do
    """
    export function init(ctx, time) {
      ctx.root.innerHTML = `<code>${time}</code>`;
      ctx.handleEvent("tick", (t) => { ctx.root.querySelector("code").textContent = t; });
    }
    """
  end
end

Clock.new()
```

### How to receive a value from a custom control back into Elixir
```elixir
# JS: ctx.pushEvent("picked", {color: value})
# Elixir handle_event:
def handle_event("picked", %{"color" => color}, ctx) do
  send(ctx.assigns.parent, {:color, color})   # forward to a notebook process/frame
  {:noreply, ctx}
end
```

## Do's and Don'ts
### ✅ Do
- Use the **module + `use Kino.JS` + `asset "main.js"` + `Kino.JS.new/2`** pattern — that is the real API.
- Export exactly `function init(ctx, data)` from `main.js`.
- Reach for `Kino.JS.Live` only when you need two-way state; `Kino.JS` suffices for render-only widgets.
- Load libraries with `ctx.importJS`/`ctx.importCSS` rather than assuming globals exist.
- Scope CSS to a wrapper class so styles don't bleed into other cells.
- Keep JSON payloads small and serializable (no PIDs/refs/functions).

### ❌ Don't
- Don't call `Kino.JS.new(html, js: …, css: …)` — that keyword form isn't the API; pass data and put JS in `asset`.
- Don't hold non-JSON terms in the data you pass to `new/2` — they won't serialize.
- Don't do heavy compute in JS `init` on the main thread — it blocks the cell UI.
- Don't forget `handle_connect/1` in a `Kino.JS.Live` widget — late-joining clients get no initial state without it.
- Don't rely on globals persisting across cells; each widget's `init` must set up its own DOM/state.
- Don't skip input sanitization when injecting user-provided HTML via `innerHTML`.

## Styling, Theming & Customization
Styling is done in the front end: an inline `<style>` block in `init`, `ctx.importCSS(url)` for external stylesheets, or setting inline styles on elements. There is no Elixir-side `css:` option. Best practice: wrap your widget in a uniquely-classed root and scope all selectors under it, and support `prefers-color-scheme` for light/dark parity. For fonts/assets, `importCSS` a webfont or embed as data URIs.

## Advanced Features
- **Smart cells** (`Kino.SmartCell`): build a form-driven cell that generates Elixir source — this is how the Chart/Map/DB smart cells work.
- **Per-client messaging**: `send_event(ctx, client_id, …)` targets one browser; `broadcast_event` hits all.
- **Synchronous calls**: `Kino.JS.Live.call/2` + `handle_call/3` for request/response from Elixir into the widget's server.
- **Process integration**: `handle_info/2` lets the widget react to timers, `Phoenix.PubSub`, telemetry, or GenServer messages.
- **Composition**: a `Kino.JS.Live` widget can embed and drive other kinos, or forward events to a `Kino.Frame`.

## Common Pitfalls & Troubleshooting
- **Blank widget / `init is not a function`**: `main.js` didn't `export function init(ctx, data)`.
- **Data missing in JS**: the term wasn't JSON-serializable (PID/ref/tuple keys) — send plain maps/lists/strings.
- **Late clients show stale/empty state**: implement `handle_connect/1` to hand new clients the current state.
- **Events don't arrive**: name mismatch between `pushEvent`/`handle_event` or `broadcast_event`/`handleEvent`.
- **Library undefined**: `importJS` promise not awaited, or the CDN blocked — `await ctx.importJS(...)` before use.
- **Styles leak between cells**: unscoped global selectors — namespace under a wrapper class.

## Integration Notes (Livebook/Kino)
- This is the foundation layer: kino-plotly.md's fallback and any bespoke chart/map/table widget are built on Kino.JS.
- Pairs with `Kino.Frame` (dynamic output regions) and `Kino.Control`/`Kino.Input` for notebook UIs.
- Promote a widget to a **smart cell** with `Kino.SmartCell` when non-coders should configure it via a form.

## Best For / Avoid For
`livebook`, `elixir`, `custom-widgets`, `javascript-interop`, `two-way-events`, `smart-cells`, `dashboards`
- **Best for**: anything no built-in Kino covers — custom visualizations, interactive controls, live dashboards, embedding arbitrary JS libraries, and smart cells.
- **Avoid for**: standard charts/maps/tables (use Kino.VegaLite/Kino.Plotly/Kino.MapLibre/Kino.DataTable — less code), or non-Livebook UIs (build a normal web app instead).

## See Also
- [kino-plotly.md](kino-plotly.md) — a concrete Kino.JS fallback wrapper in practice
- [kino-vegalite.md](kino-vegalite.md), [kino-maplibre.md](kino-maplibre.md), [kino-datatable.md](kino-datatable.md) — higher-level widgets built on this layer
- [kino-mermaid.md](kino-mermaid.md) — render diagrams without hand-writing JS
- `../use-case/elixir-livebook-components.md`
