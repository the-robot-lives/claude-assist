# Worked Example: An Interactive, Realtime, Accessible Dashboard

End-to-end build of a small but complete Hologram feature — a team "activity dashboard" with a live feed, an optimistic action, a validated form, and realtime updates. It demonstrates the whole workflow: model & boundary → build → integrate → UX/quality.

## The requirement

> A `/teams/:slug/dashboard` page showing a team's recent activity. Members can post a quick note (validated, persisted), the feed loads more on scroll, and new notes from *other* members appear live. It must be keyboard-accessible and feel instant.

## Phase 1 — Model & boundary

**Routes/params/state:**
- Route `/teams/:slug/dashboard`, `param :slug, :string`.
- Page state: `%{team: ..., notes: [...], cursor: ..., loading: false, done: false, draft: "", errors: []}`.

**Interaction → action vs command map:**

| Interaction | Action (client) | Command (server) |
|-------------|-----------------|------------------|
| Type in the note box | `:set_draft` (put_state) | — |
| Submit note | `:submit_note` (validate client-side) | `:create_note` (persist, broadcast) |
| Scroll to bottom | `:load_more` (guard + put_command) | `:fetch_page` |
| Note arrives from another user | `:note_received` (prepend) | — (pushed via Realtime) |

**Trust map:** `:create_note` writes to the DB → needs middleware auth on **this page module** (and on any component exposing a command).

## Phase 2 — Build the page

```elixir
defmodule App.Teams.DashboardPage do
  use Hologram.Page

  route "/teams/:slug/dashboard"
  param :slug, :string
  layout App.MainLayout

  def init(params, component, server) do
    team = App.Teams.get_by_slug!(params.slug)
    %{notes: notes, next: cursor} = App.Teams.recent_notes(team.id, nil)

    component =
      put_state(component,
        team: team, notes: notes, cursor: cursor,
        loading: false, done: cursor == nil, draft: "", errors: []
      )

    # Subscribe this page to the team's realtime channel. From a handler, use the
    # documented Hologram.Realtime.subscribe/3 — verify the exact arity for your version.
    server = Hologram.Realtime.subscribe(server, {:room, team.id})
    {component, server}
  end

  # This page keeps its template in a colocated dashboard_page.holo file (shown below),
  # so no template/0 is defined here. Alternatively, inline it with ~HOLO\""" ... \""".
end
```

> **Colocation note:** with a same-named `.holo` file in the module's directory, Hologram resolves the template automatically — you do not hand-write a `template/0` that "points at" the file. If you prefer an inline template, define `template/0` returning `~HOLO"""..."""`. Verify the colocation convention against your installed version.

## The template (`dashboard_page.holo`)

```html
<main aria-labelledby="dash-title">
  <h1 id="dash-title" tabindex="-1">{@team.name} — Activity</h1>

  <form $submit.prevent_default={:submit_note} class="note-form">
    <label for="note">Post a note</label>
    <textarea id="note" value={@draft} $change={:set_draft}
              aria-invalid={@errors[:body] != nil} aria-describedby="note-err"></textarea>
    {%if @errors[:body]}<p id="note-err" role="alert">{@errors[:body]}</p>{/if}
    <button type="submit" disabled={@draft == ""}>Post</button>
  </form>

  <p role="status" aria-live="polite">
    {%if @loading}Loading more…{%else}{length(@notes)} notes{/if}
  </p>

  <ul class="feed" $reach_bottom={:load_more}.within(400px)>
    {%for note <- @notes}
      <li class="note">
        <strong>{note.author}</strong>
        <p>{note.body}</p>
      </li>
    {/for}
  </ul>

  {%if @done}<p class="feed-end">You're all caught up.</p>{/if}
</main>
```

Note the accessibility touches: labelled form, `aria-invalid` + associated `role="alert"` error, a persistent `role="status"` live region, and an `<h1 tabindex="-1">` we can focus after navigation.

## Phase 3 — Actions & commands

```elixir
# --- Drafting -------------------------------------------------------------
def action(:set_draft, params, component) do
  put_state(component, :draft, params.event.value)
end

# --- Submit: validate on the client, persist on the server ----------------
def action(:submit_note, _params, component) do
  cs = App.Teams.note_changeset(%{body: component.state.draft})

  if cs.valid? do
    component
    |> put_state(:errors, [])
    |> put_command(:create_note, team_id: component.state.team.id, body: component.state.draft)
  else
    put_state(component, :errors, Map.new(cs.errors))   # instant, no round-trip
  end
end

def command(:create_note, params, server) do
  # middleware has already authorized the caller before we get here
  case App.Teams.create_note(params.team_id, params.body) do
    {:ok, note} ->
      server
      |> put_action(:note_created, note: note)
      # broadcast to everyone else on the channel (exclude the author's own client if desired)
      |> put_broadcast({:room, params.team_id}, :note_received, note: note)

    {:error, changeset} ->
      put_action(server, :note_failed, errors: Map.new(changeset.errors))
  end
end

def action(:note_created, params, component) do
  component
  |> put_state(:notes, [params.note | component.state.notes])
  |> put_state(:draft, "")
end

def action(:note_failed, params, component) do
  put_state(component, :errors, params.errors)
end

# --- Realtime: a note from another member ---------------------------------
def action(:note_received, params, component) do
  # de-dupe in case we also authored it
  if Enum.any?(component.state.notes, &(&1.id == params.note.id)) do
    component
  else
    put_state(component, :notes, [params.note | component.state.notes])
  end
end

# --- Infinite scroll ------------------------------------------------------
def action(:load_more, _params, component) do
  if component.state.loading or component.state.done do
    component
  else
    component
    |> put_state(:loading, true)
    |> put_command(:fetch_page, team_id: component.state.team.id, cursor: component.state.cursor)
  end
end

def command(:fetch_page, params, server) do
  %{notes: notes, next: next} = App.Teams.recent_notes(params.team_id, params.cursor)
  put_action(server, :page_loaded, notes: notes, next: next)
end

def action(:page_loaded, params, component) do
  component
  |> put_state(:notes, component.state.notes ++ params.notes)
  |> put_state(:cursor, params.next)
  |> put_state(:loading, false)
  |> put_state(:done, params.next == nil)
end
```

## The shared changeset (isomorphic validation)

```elixir
# Runs BOTH client-side (in :submit_note) and server-side (in App.Teams.create_note).
def note_changeset(attrs) do
  {%{}, %{body: :string}}
  |> Ecto.Changeset.cast(attrs, [:body])
  |> Ecto.Changeset.validate_required([:body])
  |> Ecto.Changeset.validate_length(:body, min: 1, max: 280)
  # NOTE: no regex validators — they don't transpile to the client
end
```

## Phase 4 — UX & quality review

Walking the checklists from the patterns files:

- **Snappy:** typing, validation, and optimistic insert are all client actions (no round-trip). Only persistence and paging hit the server. ✔
- **Pending/error states:** the submit button disables on empty draft; `role="status"` announces loading; `role="alert"` surfaces errors; failure path (`:note_failed`) reconciles. ✔
- **Focus:** `<h1 tabindex="-1">` is focused after navigating into the dashboard (add a `:focus_heading` follow-up action calling the focus interop). ✔
- **Keyboard:** native `<form>`/`<button>`/`<textarea>` are keyboard-operable; submit works on Enter within the form. ✔
- **Realtime is a hint, not truth:** `:note_received` de-dupes and simply prepends; the authoritative note list still comes from the server on load/paging. Fire-and-forget delivery is acceptable here (a missed live note reappears on refresh/paging). ✔
- **Transpilation:** every client action uses only `Enum`, `Map`, `String`, list ops — all supported. No regex, no processes. The changeset's client run avoids regex validators. ✔
- **Security:** `:create_note` is a command; middleware on `DashboardPage` authorizes it. If we later extract the note form into its own stateful component that defines `command/3`, we must add middleware to *that* module too (middleware does not cascade). ✔

## What this example exercised

Pages + `init/3`, colocated templates, client actions, server commands, `put_state`/`put_command`/`put_action`/`put_broadcast`, isomorphic Ecto validation, `$submit`/`$change`/`$reach_bottom` events, optimistic updates with reconciliation, realtime push with de-dupe, ARIA live regions, and focus management — the full surface of the skill in one feature.
