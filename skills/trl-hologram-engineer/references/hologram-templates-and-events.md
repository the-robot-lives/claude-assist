# Hologram Templates & Events

The `~HOLO` template language and the full event-binding system.

## The template: `~HOLO` sigil or `.holo` file

Templates are written either inline in `template/0`:

```elixir
def template do
  ~HOLO"""
  <p>Hello, {@name}!</p>
  """
end
```

…or as a **colocated `.holo` file** with the same base name as the module file, in the same directory. Register `.holo` in `.formatter.exs` (`inputs: [".../**/*.{ex,exs,holo}"]`).

Templates are **plain HTML** plus Hologram's expression and control-flow syntax. All interpolated expressions are **automatically HTML-escaped** (XSS-safe by default).

## Interpolation

State and props are accessed with `@key`.

| Purpose | Syntax |
|---------|--------|
| Text expression | `<p>Hello, {@name}!</p>` |
| Full attribute | `<div class={@class_name}>` |
| Interpolated attribute string | `<div class="base-{@dynamic}">` |
| Component prop (expression) | `<MyComponent count={42} />` |
| Component prop (string literal) | `<MyComponent title="Hello" />` |
| Escape a literal brace | `\{@literal\}` |

Any Elixir expression works inside `{ }`, e.g. `<a href={"/posts/#{@post.id}"}>`.

## Control-flow blocks

Blocks use the `{% ... }` … `{/...}` form.

### Conditional

```elixir
~HOLO"""
{%if @logged_in}
  <p>Welcome back, {@name}!</p>
{%else}
  <a href="/login">Log in</a>
{/if}
"""
```

Uses Elixir truthiness (`nil`/`false` are falsy).

### Iteration

```elixir
~HOLO"""
<div class="posts">
  {%for post <- @posts}
    <PostPreview post={post} />
  {/for}
</div>
"""
```

Supports Elixir pattern matching in the generator (e.g. `{%for {id, label} <- @options}`).

### Raw (no processing / no escaping)

```elixir
~HOLO"""
{%raw}
  <p>{ this is not interpolated }</p>
{/raw}
"""
```

Use `{%raw}` deliberately — it bypasses interpolation (and thus escaping).

## Events

Event bindings are attributes prefixed with `$`.

### Supported events

`$blur`, `$change`, `$click`, `$click_outside`, `$focus`, `$key_down`, `$key_up`, `$mouse_move`, `$pointer_cancel`, `$pointer_down`, `$pointer_move`, `$pointer_up`, `$reach_bottom`, `$reach_left`, `$reach_right`, `$reach_top`, `$resize`, `$scroll`, `$select`, `$submit`, `$transition_cancel`, `$transition_end`, `$transition_run`, `$transition_start`.

**Global targets:** `<window $key_down.ctrl+k="open_palette" />` and `<document …>` for document-level events.

### Binding forms

| Form | Example | Triggers |
|------|---------|----------|
| Text (actions only) | `<button $click="my_action">` | action `:my_action` on this component |
| Shorthand w/ params (actions) | `<button $click={:my_action, param_1: 1}>` | action with params |
| Longhand (actions) | `<button $click={action: :my_action, target: "cart", params: %{key: v}}>` | action on target cid |
| Command | `<button $click={command: :my_command, params: %{key: v}}>` | server command |
| Delay | `<button $click={action: :my_action, delay: 1000}>` | after 1000ms |
| Conditional (nil = no binding) | `<button $click={if @editable do :save end}>` | binds only when truthy |

**Targets:** `"page"`, `"layout"`, or a component `cid`.

### Modifiers (dot-chained)

| Modifier | Effect |
|----------|--------|
| Key filter | `$key_down.enter="submit"`, `$key_down.ctrl+enter="send"` |
| `.debounce(ms)` | Wait for a pause (default 250ms). E.g. `$change.debounce(300)` |
| `.throttle(ms)` | Rate-limit (default 100ms). E.g. `$mouse_move.throttle(100)` |
| `.once` | Fire at most once |
| `.prevent_default` | `event.preventDefault()` |
| `.allow_default` | Do not prevent default |
| `.stop_propagation` | `event.stopPropagation()` |

**Key names:** letters/digits; `alt ctrl meta shift`; `arrow_up arrow_down arrow_left arrow_right`; `backspace caps_lock delete end enter escape home insert page_up page_down space tab`; `f1`–`f12`; symbol aliases `backquote backslash bracket_left bracket_right comma equal minus period quote semicolon slash`.

### Reach events (infinite scroll / lazy load)

```elixir
~HOLO"""
<div $reach_bottom="load_more">…</div>
<div $reach_bottom={action: :load_more}.within(200px)>…</div>
<div $reach_right="load_more".within(50%)>…</div>
"""
```

`within(distance)` fires the event when the scroll position comes within the given distance (px or %) of the edge.

## Event data

Event details arrive under `params.event`.

| Event kind | Fields |
|------------|--------|
| Keyboard (`$key_down`/`$key_up`) | `alt_key, code, ctrl_key, key, meta_key, repeat, shift_key` |
| Mouse (`$click`, `$mouse_move`, …) | `client_x, client_y, movement_x, movement_y, offset_x, offset_y, page_x, page_y, screen_x, screen_y` |
| Pointer (`$pointer_*`) | mouse fields plus `pointer_type` |
| Form-level `$submit` / `$change` | form fields directly, e.g. `%{email: "...", password: "..."}` |

```elixir
def action(:key_pressed, params, component) do
  case params.event.key do
    "Escape" -> put_state(component, :open, false)
    _        -> component
  end
end
```

## Common examples

```elixir
# Command palette (global shortcut)
~HOLO"""
<window $key_down.ctrl+k="open_palette" />
"""

# Debounced search box (input-level $change fires per keystroke)
~HOLO"""
<input type="text" $change.debounce(300)={:search} />
"""

# Prevent default form submit and handle it as an action
~HOLO"""
<form $submit.prevent_default="save_form">
  <input name="email" />
  <button type="submit">Save</button>
</form>
"""

# Close a menu when clicking outside it
~HOLO"""
<div class="menu" $click_outside="close_menu">…</div>
"""
```
