# Hologram UX Interaction Patterns

Reusable, high-quality interaction patterns built from Hologram's event and state primitives. Each keeps the UI snappy by preferring client actions and using commands only where the server is needed.

## Principle: client-first, optimistic, progressively enhanced

- **Client-first:** any interaction that only rearranges local state should be an `action` — no round-trip.
- **Optimistic:** update state immediately for reversible changes; reconcile from the command's returned action.
- **Progressive enhancement:** first paint is SSR HTML — make it meaningful and functional-looking before hydration.

## Prefetch-on-interaction navigation

Use `Hologram.UI.Link` for internal navigation. It prefetches on `$pointer_down` and swaps on `$pointer_up`, so pages feel instant while keeping real history and address-bar URLs.

```elixir
~HOLO"""
<nav>
  <Hologram.UI.Link to={App.HomePage}>Home</Hologram.UI.Link>
  <Hologram.UI.Link to={App.PostPage, id: @post.id}>Open</Hologram.UI.Link>
</nav>
"""
```

Reserve plain `<a>` for external links. After navigation, move focus to the new main heading (see accessibility patterns).

## Infinite scroll / lazy loading

Use `$reach_bottom` with `within(distance)` to load before the user hits the edge.

```elixir
~HOLO"""
<div class="feed" $reach_bottom={:load_more}.within(400px)>
  {%for item <- @items}
    <FeedCard item={item} />
  {/for}
  {%if @loading}<p class="loading" role="status">Loading…</p>{/if}
</div>
"""
```

```elixir
def action(:load_more, _params, component) do
  if component.state.loading or component.state.done do
    component
  else
    component
    |> put_state(:loading, true)
    |> put_command(:fetch_page, cursor: component.state.cursor)
  end
end

def command(:fetch_page, params, server) do
  %{items: items, next: next} = App.Feed.page(params.cursor)
  put_action(server, :page_loaded, items: items, next: next)
end

def action(:page_loaded, params, component) do
  component
  |> put_state(:items, component.state.items ++ params.items)
  |> put_state(:cursor, params.next)
  |> put_state(:loading, false)
  |> put_state(:done, params.next == nil)
end
```

Guard against duplicate loads with a `loading` flag; stop at `done`.

## Search-as-you-type (debounced)

Debounce input to avoid a command per keystroke. Filter client-side when the dataset is already loaded; hit the server only when needed.

```elixir
~HOLO"""
<input type="search" value={@query} $change.debounce(300)={:search}
       aria-label="Search products" />
<ul role="listbox">
  {%for p <- @results}<li role="option">{p.name}</li>{/for}
</ul>
"""
```

```elixir
def action(:search, params, component) do
  q = params.event.value
  # client-side filter of already-loaded data — instant, no round-trip
  results = Enum.filter(component.state.all, &String.contains?(String.downcase(&1.name), String.downcase(q)))
  put_state(component, query: q, results: results)
end
```

> Use `String.contains?/2` / `String.downcase/1`, **not** regex — regex does not transpile to the client.

## Command palette (global keyboard shortcut)

Bind a global shortcut on `<window>`; toggle a state flag; trap focus in the palette.

```elixir
~HOLO"""
<window $key_down.ctrl+k.prevent_default={:open_palette} />
{%if @palette_open}
  <div class="palette" role="dialog" aria-modal="true" $key_down.escape={:close_palette} $click_outside={:close_palette}>
    <input type="text" value={@palette_query} $change={:palette_search} aria-label="Command palette" />
    <ul>{%for c <- @palette_results}<li $click={action: :run_command, params: %{id: c.id}}>{c.label}</li>{/for}</ul>
  </div>
{/if}
"""
```

## Popovers / menus / dropdowns

Use `$click_outside` to dismiss, `$key_down.escape` to close, and a boolean state flag to toggle.

```elixir
~HOLO"""
<div class="dropdown">
  <button $click={:toggle_menu} aria-expanded={@menu_open} aria-haspopup="menu">Options</button>
  {%if @menu_open}
    <ul role="menu" $click_outside={:close_menu} $key_down.escape={:close_menu}>
      <li role="menuitem" $click={action: :choose, params: %{id: 1}}>Rename</li>
      <li role="menuitem" $click={action: :choose, params: %{id: 2}}>Delete</li>
    </ul>
  {/if}
</div>
"""
```

## Optimistic mutations with reconciliation

For likes, toggles, reordering — update state instantly, persist via a command, and revert if it fails. See the full like/reconcile example in [../hologram-actions-and-commands.md](../hologram-actions-and-commands.md).

## Throttled continuous events

Rate-limit high-frequency events so you don't thrash state.

```elixir
~HOLO"""
<div class="canvas" $mouse_move.throttle(50)={:track_cursor}>…</div>
"""
```

```elixir
def action(:track_cursor, params, component) do
  put_state(component, cursor: {params.event.offset_x, params.event.offset_y})
end
```

## Delayed / auto-dismissing UI (toasts)

Use the `delay:` binding option or schedule a follow-up action to auto-dismiss.

```elixir
~HOLO"""
{%if @toast}
  <div class="toast" role="status" $click={:dismiss_toast}>
    {@toast}
    <button $click={action: :dismiss_toast, delay: 4000} aria-hidden="true"></button>
  </div>
{/if}
"""
```

## Pending states for every command

Any interaction that fires a `command` must show a pending state (button spinner, disabled control, skeleton) and handle both success and failure actions returned from the server. Never leave a command in flight with no visible feedback.
