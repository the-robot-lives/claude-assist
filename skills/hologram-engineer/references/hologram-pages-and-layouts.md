# Hologram Pages & Layouts

Routing, page lifecycle, layouts, and navigation.

## Pages — `use Hologram.Page`

A page is **always stateful** (assigned cid `"page"`) and is **always initialized server-side** via `init/3` during SSR. It becomes interactive on the client after hydration.

### Available macros & callbacks

| Element | Signature / form | Purpose |
|---------|------------------|---------|
| `route/1` | `route "/posts/:id"` | Declare the URL route (static or with dynamic segments) |
| `param/2` | `param :id, :integer` | Type a dynamic segment. Types: `:atom`, `:float`, `:integer`, `:string` |
| `layout/1,2` | `layout MyApp.MainLayout` or `layout MyApp.MainLayout, title: "…"` | Set the root layout (required), optionally with props |
| `init/3` | `def init(params, component, _server)` | Seed state during SSR; returns component (and optionally server) |
| `template/0` | returns `~HOLO"""…"""` | Markup (or a colocated `.holo` file) |
| `action/3` | `def action(name, params, component)` | Client-side event handler |
| `command/3` | `def command(name, params, server)` | Server-side handler |

### Routes and params

```elixir
route "/products"                                        # static
route "/users/:username/posts/:post_id/comments"         # dynamic

param :username, :string
param :post_id, :integer
```

Typed params are available as `params.username`, `params.post_id` in `init/3`.

### `init/3` — server-side initialization

```elixir
def init(params, component, _server) do
  post = %{id: params.id, title: "Example Post", content: "…", likes: 0}
  put_state(component, :post, post)
end
```

`init/3` runs during page render (SSR). The default implementation returns the component/server unchanged, so it is optional if the page has no initial state. You may also return `{component, server}` when you also mutate server state (session/cookies).

### Full page example

```elixir
defmodule Blog.PostPage do
  use Hologram.Page

  route "/posts/:id"
  param :id, :integer
  layout Blog.MainLayout

  def init(params, component, _server) do
    post = %{id: params.id, title: "Example Post", content: "This is the full content...", likes: 0}
    put_state(component, :post, post)
  end

  def template do
    ~HOLO"""
    <article>
      <h1>{@post.title}</h1>
      <p>{@post.content}</p>
      <div class="likes">
        Likes: {@post.likes}
        <button $click="like_post">Like</button>
      </div>
    </article>
    """
  end

  def action(:like_post, _params, component) do
    component
    |> put_state([:post, :likes], component.state.post.likes + 1)
    |> put_command(:save_like, post_id: component.state.post.id)
  end

  def command(:save_like, params, server) do
    IO.puts("Liked post #{params.post_id}")
    server
  end
end
```

## Layouts — `use Hologram.Component`

Layouts are **regular components** that serve as the root of a page's component tree. They have no special macro; a layout is any component assigned to a page via `layout/1,2`. It is always assigned cid `"layout"`.

**A layout template MUST contain:**
1. `<Hologram.UI.Runtime />` inside the `<head>` — mounts the client runtime.
2. A `<slot />` where the page's content is injected.

```elixir
defmodule Blog.MainLayout do
  use Hologram.Component

  def template do
    ~HOLO"""
    <html>
      <head>
        <meta charset="utf-8" />
        <title>My Blog</title>
        <Hologram.UI.Runtime />
      </head>
      <body>
        <header><nav><!-- … --></nav></header>
        <main><slot /></main>
      </body>
    </html>
    """
  end
end
```

### Passing data to the layout

```elixir
# Static props from the page
layout MyApp.MainLayout, page_title: "My Page", show_sidebar?: true
```

The layout receives these as props (`prop :page_title, :string`, etc.). To set them dynamically, compute values in the page's `init/3` and pass via state/context.

## Navigation — `Hologram.UI.Link`

`Hologram.UI.Link` gives SPA-like client-side transitions while keeping SSR benefits, real browser history/back-forward, and correct address-bar URLs.

```elixir
~HOLO"""
<Hologram.UI.Link to={Blog.PostPage, id: 42}>Read post</Hologram.UI.Link>
"""
```

**Prefetch on interaction:** prefetch begins on `$pointer_down` and the content swaps on `$pointer_up`, so navigation feels near-instant.

### Programmatic navigation

From an action, navigate with `put_page`:

```elixir
def action(:go_home, _params, component) do
  put_page(component, Blog.HomePage)
end

def action(:open_post, params, component) do
  put_page(component, Blog.PostPage, id: params.id)
end
```

## UX note

Because navigation preserves history and does SSR + prefetch, use `Hologram.UI.Link` for internal navigation rather than plain `<a>` where you want the SPA transition. Manage focus after navigation (see [patterns/accessibility-patterns.md](patterns/accessibility-patterns.md)) — client-side route changes do not automatically move focus.
