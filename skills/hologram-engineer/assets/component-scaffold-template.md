# Hologram Scaffold Templates

Copy-paste starting points. Replace `App`/`MyApp` and names. Every snippet stays inside the transpilable subset for client-reachable code.

## Layout (required shape)

```elixir
defmodule App.MainLayout do
  use Hologram.Component

  # Optional props passed from the page: `layout App.MainLayout, page_title: "…"`
  prop :page_title, :string, default: "App"

  def template do
    ~HOLO"""
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>{@page_title}</title>
        <Hologram.UI.Runtime />
      </head>
      <body>
        <a class="skip-link" href="#main">Skip to content</a>
        <header><nav><!-- nav --></nav></header>
        <main id="main"><slot /></main>
      </body>
    </html>
    """
  end
end
```

## Page (stateful, server-initialized)

```elixir
defmodule App.ThingPage do
  use Hologram.Page

  route "/things/:id"
  param :id, :integer
  layout App.MainLayout

  def init(params, component, _server) do
    thing = App.Things.get!(params.id)
    put_state(component, thing: thing)
  end

  def template do
    ~HOLO"""
    <main aria-labelledby="t">
      <h1 id="t" tabindex="-1">{@thing.name}</h1>
      <button $click={:do_something}>Do it</button>
    </main>
    """
  end

  def action(:do_something, _params, component) do
    put_state(component, :done, true)
  end
end
```

## Stateless component

```elixir
defmodule App.Badge do
  use Hologram.Component

  prop :label, :string
  prop :tone, :string, default: "neutral"

  def template do
    ~HOLO"""
    <span class="badge badge-{@tone}">{@label}</span>
    """
  end
end
```

## Stateful component (needs a unique cid when used)

```elixir
defmodule App.Counter do
  use Hologram.Component

  prop :start, :integer, default: 0

  # Client-side init (component added dynamically on the client)
  def init(props, component) do
    put_state(component, :count, props.start)
  end

  # Server-side init (rendered during SSR)
  def init(props, component, server) do
    {put_state(component, :count, props.start), server}
  end

  def template do
    ~HOLO"""
    <div class="counter">
      <button $click={:dec} aria-label="Decrease">−</button>
      <span role="status" aria-live="polite">{@count}</span>
      <button $click={:inc} aria-label="Increase">+</button>
    </div>
    """
  end

  def action(:inc, _p, c), do: put_state(c, :count, c.state.count + 1)
  def action(:dec, _p, c), do: put_state(c, :count, c.state.count - 1)
end
```

Usage (note the required `cid`):

```elixir
~HOLO"""
<App.Counter cid="cart_qty" start={1} />
"""
```

## Action → command round-trip (optimistic + reconcile)

```elixir
def action(:toggle_fav, _p, c) do
  c
  |> put_state([:item, :fav], !c.state.item.fav)          # optimistic
  |> put_command(:persist_fav, id: c.state.item.id, fav: !c.state.item.fav)
end

def command(:persist_fav, params, server) do
  case App.Items.set_fav(params.id, params.fav) do
    {:ok, _}          -> server
    {:error, _reason} -> put_action(server, :fav_reverted, id: params.id)
  end
end

def action(:fav_reverted, _p, c) do
  put_state(c, [:item, :fav], !c.state.item.fav)          # undo
end
```

## Validated form (non-synchronized, isomorphic)

```elixir
def template do
  ~HOLO"""
  <form $submit.prevent_default={:submit}>
    <label for="email">Email</label>
    <input id="email" name="email" type="email"
           aria-invalid={@errors[:email] != nil} aria-describedby="email-err" />
    {%if @errors[:email]}<p id="email-err" role="alert">{@errors[:email]}</p>{/if}
    <button type="submit">Save</button>
  </form>
  """
end

def action(:submit, params, component) do
  cs = changeset(params.event)
  if cs.valid? do
    component |> put_state(:errors, %{}) |> put_command(:save, attrs: params.event)
  else
    put_state(component, :errors, Map.new(cs.errors))
  end
end

def command(:save, params, server) do
  case App.Accounts.save(params.attrs) do
    {:ok, _}            -> put_action(server, :saved)
    {:error, changeset} -> put_action(server, :form_errors, errors: Map.new(changeset.errors))
  end
end

def changeset(attrs) do
  {%{}, %{email: :string}}
  |> Ecto.Changeset.cast(attrs, [:email])
  |> Ecto.Changeset.validate_required([:email])
  # avoid regex validators in the client path
end
```

## Middleware-gated command (auth)

```elixir
# Attach middleware to EVERY module that defines command/3 — it does not cascade.
defmodule App.AdminPage do
  use Hologram.Page
  # ... route/layout ...

  # (middleware wiring per your version's middleware API — verify against /docs/middleware)
  def command(:delete_all, _params, server) do
    App.Admin.wipe!()
    put_action(server, :wiped)
  end
end
```

## Realtime broadcast (from a command)

```elixir
def command(:post_message, params, server) do
  App.Chat.save!(params)
  server
  |> put_action(:sent)
  |> put_broadcast_except([{:user, params.user_id}], {:room, params.room_id}, :new_message, text: params.text)
end

def action(:new_message, params, component) do
  put_state(component, :messages, [params.text | component.state.messages])
end
```
