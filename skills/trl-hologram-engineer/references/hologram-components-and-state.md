# Hologram Components & State

Components, props, stateful vs stateless, `cid`, initialization, state, slots, and context.

## `use Hologram.Component`

```elixir
defmodule Greeting do
  use Hologram.Component

  prop :name, :string
  prop :title, :string, default: "Mr."

  def template do
    ~HOLO"""
    <p>Hello, {@title} {@name}!</p>
    """
  end
end
```

## Props — `prop/2` and `prop/3`

Props are the **read-only inputs** a parent passes down.

```elixir
prop :user_id, :integer
prop :count, :integer, default: 0
prop :user, :map, from_context: :current_user   # pull from context instead of a parent
```

**Prop types:** `:any, :atom, :boolean, :bitstring, :float, :function, :integer, :list, :map, :pid, :port, :reference, :string, :tuple`.

## Stateless vs stateful

- **Stateless** — renders purely from props. No state, no `cid`. Prefer these; they are simplest and cheapest.
- **Stateful** — maintains its own mutable state and can receive actions/commands. **Requires a unique `cid`** (component id):

```elixir
~HOLO"""
<Assassin cid="baba_yaga" name="John Wick" kill_count={439} />
"""
```

The `cid` is the **target** for actions and commands. Omitting it, or colliding ids, breaks action/command targeting. Choose stable, descriptive ids (`"cart"`, `"search_box"`).

## Initialization

A stateful component initializes **exactly once** per instance.

### Server-side `init/3`

Runs during page render (SSR). Returns `{component, server}`.

```elixir
def init(_props, component, server) do
  component = put_state(component, :kill_count, 439)
  server = put_session(server, :name, "John Wick")
  {component, server}
end
```

Inside server init you may use `put_state`, `put_session`, and `put_action`.

### Client-side `init/2`

Runs when a component is **dynamically added on the client**. Returns the component.

```elixir
def init(_props, component) do
  put_state(component, kill_count: 439, name: "John Wick")
end
```

## State

- State is a **map stored on the client**. It is Hologram's own mutable data (as opposed to read-only props).
- Read it in templates via `@key` (`@count`, `@post.title`) and in handler code via `component.state.key` (`component.state.post.likes`).
- Initialize with `put_state` in `init`; mutate with `put_state` in actions.

### `put_state` forms

```elixir
put_state(component, :count, 5)                       # single key
put_state(component, count: 5, name: "Ada")           # multiple keys (keyword list)
put_state(component, [:post, :likes], new_value)      # nested path
```

`put_state` is pure and pipeable — chain it:

```elixir
def action(:reset, _params, component) do
  component
  |> put_state(:count, 0)
  |> put_state(:touched, false)
end
```

## Slots

`<slot />` renders child content passed by the parent.

```elixir
defmodule Card do
  use Hologram.Component

  def template do
    ~HOLO"""
    <div class="card"><slot /></div>
    """
  end
end
```

```elixir
# usage
~HOLO"""
<Card>
  <h2>Title</h2>
  <p>Body</p>
</Card>
"""
```

## Context — sharing data without prop drilling

Context propagates data **down** the component tree (ancestor → descendants), one-directional.

### Provide

```elixir
def init(_props, component, server) do
  {put_context(component, :current_user, load_user()), server}
end

# namespaced key to avoid collisions
put_context(component, {MyApp.Auth, :current_user}, user)
```

### Consume

```elixir
prop :user, :map, from_context: :current_user
```

Use context for values shared across many layers (current user, theme, locale). Use plain props when the data only crosses one or two levels.

## Built-in UI components

| Component | Purpose |
|-----------|---------|
| `Hologram.UI.Runtime` | Required in the layout `<head>`; mounts the client runtime |
| `Hologram.UI.Link` | Client-side navigation with prefetch and history (see [hologram-pages-and-layouts.md](hologram-pages-and-layouts.md)) |

## Choosing structure

| Question | If yes |
|----------|--------|
| Does it own mutable data or receive events? | Stateful (give it a `cid`) |
| Does it render purely from inputs? | Stateless |
| Is the same value threaded through many layers? | Context |
| Is data passed one or two levels? | Props |
