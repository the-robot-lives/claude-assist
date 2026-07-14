# Hologram Actions & Commands

The central client/server split, the trust boundary, and how state flows between them.

## The core distinction

| | **Action** | **Command** |
|--|-----------|-------------|
| Runs | **Client** (transpiled Elixir/JS in the browser) | **Server** (async) |
| Round-trip? | No | Yes |
| Trust boundary | Crosses none — never trust it for authz | Crosses one — middleware runs before it |
| Can do | Update state, trigger commands/other actions, navigate, update context | DB/files/APIs, session/cookies, privileged ops, trigger client actions |
| Signature | `def action(name, params, component)` → `%Component{}` | `def command(name, params, server)` → `%Server{}` |

**Rule of thumb:** default to an **action** (instant, no round-trip). Reach for a **command** only when you need the server — persistence, secrets, authorization, external APIs.

## Actions (client-side)

`params` is a map of your passed params plus event data under the `:event` key. An action must return a `%Component{}`. All helpers are pure and pipeable.

### Helpers usable in an action

| Helper | Forms |
|--------|-------|
| `put_state` | `put_state(c, :k, v)` · `put_state(c, k1: v1, k2: v2)` · `put_state(c, [:a, :b], v)` (nested) |
| `put_action` | `put_action(c, :name)` · `put_action(c, :name, k: v)` — chain another action |
| `put_command` | `put_command(c, :name)` · `put_command(c, :name, k: v)` — invoke a server command |
| `put_page` | `put_page(c, Page)` · `put_page(c, Page, a: 1, b: 2)` — navigate |
| `put_context` | `put_context(c, :key, value)` — update emitted context |

### Examples

```elixir
def action(:increment, params, component) do
  put_state(component, :count, component.state.count + params.by)
end

def action(:save_form, params, component) do
  component
  |> put_state(:saving, true)
  |> put_command(:save_user, user: params.user)
end
```

## Commands (server-side)

A command runs on the server, asynchronously. **Middleware runs before `command/3`** — this is where authentication/authorization belongs. A command must return a `%Server{}`. It returns work to the client by enqueuing **actions**.

### Returning actions to the client (`put_action` on `%Server{}`)

```elixir
put_action(server, :my_action)
put_action(server, :my_action, param_1: v1, param_2: v2)
put_action(server, name: :my_action, target: "other_component", params: %{key: value})
put_action(server, %Action{name: :my_action})
```

### Example

```elixir
def command(:save_user, params, server) do
  case MyApp.Users.create(params) do
    {:ok, user}         -> put_action(server, :user_saved, user: user)
    {:error, changeset} -> put_action(server, :validation_failed, errors: changeset.errors)
  end
end
```

The `:user_saved` / `:validation_failed` actions then run client-side and update state.

## The full round-trip

```
User clicks
  → action/3 (client): optimistic put_state, then put_command(:save_...)
    → HTTP/2 request to the server
      → middleware (auth) runs
      → command/3 (server): do the work, put_action(:saved | :failed, ...)
    → HTTP/2 response carries the action(s)
  → action/3 (client): reconcile state from the server's authoritative result
```

## Security: actions vs commands

- **Never put authorization in an action.** Actions run in the browser and cross no trust boundary — a user can invoke them arbitrarily. Put all authz in a **command**, gated by **middleware**.
- **Middleware is flat and does NOT cascade.** A page's middleware does not cover its child components' commands. Dispatch runs only the *target module's* middleware. **Attach auth middleware to every component that exposes a command**, not just the page. (See [hologram-forms-session-cookies.md](hologram-forms-session-cookies.md) for middleware.)

## Optimistic vs authoritative updates

- **Optimistic** (reversible, low-risk, e.g. a "like"): update state in the action immediately, then `put_command` to persist; reconcile if the command's returned action reports failure.
- **Authoritative** (irreversible/financial): show a pending state in the action, `put_command`, and only apply the real change when the command's confirming action arrives.

```elixir
# Optimistic like with reconciliation
def action(:like, _params, component) do
  component
  |> put_state([:post, :likes], component.state.post.likes + 1)
  |> put_command(:save_like, post_id: component.state.post.id)
end

def command(:save_like, params, server) do
  case Blog.like_post(params.post_id) do
    {:ok, likes}      -> put_action(server, :like_confirmed, likes: likes)
    {:error, _reason} -> put_action(server, :like_reverted, post_id: params.post_id)
  end
end

def action(:like_confirmed, params, component) do
  put_state(component, [:post, :likes], params.likes)   # authoritative count
end

def action(:like_reverted, _params, component) do
  put_state(component, [:post, :likes], component.state.post.likes - 1)
end
```

## Targeting

Actions and commands target a component by its `cid` (or `"page"` / `"layout"`). In an event binding, use the longhand form to target another component:

```elixir
~HOLO"""
<button $click={action: :add_item, target: "cart", params: %{sku: @sku}}>Add</button>
"""
```
