# Hologram Forms, Session, Cookies & Middleware

Building forms with isomorphic validation, and the server-side state / auth machinery.

## Forms

Hologram supports two input patterns.

### Synchronized inputs (controlled, unidirectional)

Each input binds to a piece of state via an input-level `$change`, with unidirectional data flow. Use `value` for text/email/password/textarea/select; use `checked` for checkboxes/radios.

```elixir
def template do
  ~HOLO"""
  <form $submit.prevent_default="submit">
    <input type="email" value={@email} $change={:set_email} />
    <input type="password" value={@password} $change={:set_password} />
    <label><input type="checkbox" checked={@remember} $change={:toggle_remember} /> Remember me</label>
    <button type="submit">Log in</button>
  </form>
  """
end

def action(:set_email, params, component),   do: put_state(component, :email, params.event.value)
def action(:set_password, params, component),do: put_state(component, :password, params.event.value)
def action(:toggle_remember, params, component), do: put_state(component, :remember, params.event.checked)
```

Input-level `$change` maps to the native `input` event — it **fires per keystroke** (good for live validation; add `.debounce(300)` to smooth it).

### Non-synchronized inputs (read on submit/change)

Read all fields at once from `params.event` on a form-level `$change` or `$submit`. Form-level `$change` maps to the native `change` event — it **fires on blur**, not per keystroke.

```elixir
def template do
  ~HOLO"""
  <form $submit.prevent_default="submit">
    <input name="email" type="email" />
    <input name="password" type="password" />
    <button type="submit">Log in</button>
  </form>
  """
end

def action(:submit, params, component) do
  # params.event is %{email: "...", password: "..."}
  changeset = MyApp.Accounts.login_changeset(params.event)
  if changeset.valid? do
    put_command(component, :login, credentials: params.event)
  else
    put_state(component, :errors, changeset.errors)
  end
end
```

Use synchronized inputs for rich controlled UI (live validation, dependent fields); non-synchronized for simple submit-only forms.

## Isomorphic validation

The same Elixir validation — **including Ecto changesets** — runs both client-side (in an action, for instant feedback) and server-side (in a command, authoritative). Define it once and call it in both places.

```elixir
# One changeset function, shared
def changeset(attrs) do
  %MyApp.User{}
  |> Ecto.Changeset.cast(attrs, [:email, :password])
  |> Ecto.Changeset.validate_required([:email, :password])
  |> Ecto.Changeset.validate_format(:email, ~r/@/)   # NOTE: regex is NOT supported on the client
  |> Ecto.Changeset.validate_length(:password, min: 8)
end
```

> **Transpilation caveat:** regex does not transpile to the client (`~r/…/` / `=~`). If your changeset uses regex validators, either (a) replace them with non-regex checks (`String.contains?/2`, length/format helpers) for the client path, or (b) run only the non-regex validations client-side and let the **command** run the full changeset authoritatively. See [hologram-transpilation-limits.md](hologram-transpilation-limits.md).

### Client → server flow

```elixir
def action(:submit, params, component) do
  cs = changeset(params.event)
  if cs.valid? do
    component |> put_state(:errors, []) |> put_command(:create_user, attrs: params.event)
  else
    put_state(component, :errors, cs.errors)        # instant feedback, no round-trip
  end
end

def command(:create_user, params, server) do
  case MyApp.Accounts.create_user(params.attrs) do   # re-validates authoritatively
    {:ok, user}         -> put_action(server, :user_created, id: user.id)
    {:error, changeset} -> put_action(server, :form_errors, errors: changeset.errors)
  end
end
```

## Session

Server-side session, stored in a **secure, integrity-protected cookie**. Usable in `init/3`, commands, and middleware — anywhere you have `%Server{}`.

```elixir
server = put_session(server, :user_id, user.id)
user_id = get_session(server, :user_id)
server = delete_session(server, :user_id)
```

- Keys must be **atoms or strings** (atoms are converted to strings — `:user_id == "user_id"`). Other key types **raise**.
- Values may be any Elixir data type.

## Cookies

```elixir
value  = get_cookie(server, "theme", "light")           # with default
server = put_cookie(server, "theme", "dark")
server = put_cookie(server, "sid", token, http_only: true, secure: true, same_site: :strict, max_age: 3600)
server = delete_cookie(server, "sid")
```

**Default options:** `http_only: true`, `path: "/"`, `same_site: :lax`, `secure: true`. Available options: `http_only`, `path`, `same_site` (`:strict | :lax | :none`), `secure`, `max_age`, `domain`. Keep `secure: true` in production.

## Middleware

Middleware runs **before `command/3`** and is the place for authentication/authorization.

### Critical security property: middleware is flat and does NOT cascade

> A page's middleware does **not** cover its child components' commands. Dispatch is flat: only the **target module's** middleware runs — never a tree of them.

**Consequence:** if a component (not just the page) exposes a command, attach auth middleware to **that component's module**. Auditing only the page is insufficient. When reviewing a Hologram app for security, enumerate every module that defines `command/3` and confirm each has appropriate middleware.
