# Hologram Client/Server Model, JS Interop & Realtime

How code is split and transpiled, the transports, JavaScript interop, and server→client push.

## What runs where

- **Actions run on the client** (transpiled Elixir → JS). No trust boundary.
- **Commands run on the server** (privileged, middleware-gated).
- **First render is SSR**; then Hologram mounts the page in the browser and manages a **virtual DOM** for updates.
- **Client state lives in the browser.**

## Transpilation (how the client code becomes JS)

At build time, the `:hologram` mix compiler:
1. Statically builds a **call graph** of your code.
2. Determines which functions are **reachable from client action handlers / templates**.
3. **Compiles that Elixir to JavaScript.**

Only client-reachable code is transpiled. If a function you call from an action uses something unsupported (processes, regex, an un-transpiled stdlib function), compilation surfaces it — move that work into a `command` instead. See [hologram-transpilation-limits.md](hologram-transpilation-limits.md).

## Transports

Hologram wires transport automatically — you never write HTTP/fetch code:

- **HTTP/2 request/response** handles every action→command round-trip.
- A **Server-Sent Events (SSE) stream** carries server-pushed updates (Realtime).

There is **no persistent WebSocket** (a key difference from LiveView).

## JavaScript interop

Elixir client code can call into JavaScript. Type conversion across the JS boundary:

| Elixir | JavaScript |
|--------|-----------|
| map | object |
| list | array |
| integer / float | number |
| — | opaque JS values (bigint, function, symbol) → `Hologram.JS.NativeValue` struct |

- **JS Promises automatically become Elixir `Task`s** — `await` them with `Task.await/1`.
- The interop surface includes calling JS functions, constructing objects, reading/writing properties, `typeof`/`instanceof` checks, and evaluating/execing JS. (API names such as `JS.call`, `JS.new`, `JS.get`, `JS.set`, `JS.typeof`, `JS.instanceof` appear in the docs — verify exact arities against `/docs/javascript-interop` for your version.)

### Interop constraints (important)

- Interop functions are usable **only in code reachable through action handlers**.
- They are **no-ops during SSR** (there is no browser yet).
- They are **not unit-testable** — exercise them with **feature/browser tests** only (see [hologram-testing-and-deployment.md](hologram-testing-and-deployment.md)).

## Realtime (server → client push)

Realtime lets the server push actions to connected clients over the SSE stream.

### Channels (typed values)

**Identity channels** (who receives):
- `{:instance, instance_id}` — one browser tab
- `{:session, session_id}` — one session (all tabs)
- `{:user, user_id}` — a user across devices

**Application channels** (topics): plain terms like `:notifications` or `{:room, 42}`.

### Broadcasting

**From handlers** (`init/3`, `command/3`) — deferred/transactional, sent when the handler commits:

```elixir
def command(:post_message, params, server) do
  MyApp.Chat.save!(params)
  put_broadcast(server, {:room, params.room_id}, :new_message, message: params.text)
end

# exclude some identities (e.g. the sender)
put_broadcast_except(server, [{:user, params.user_id}], {:room, params.room_id}, :new_message)
```

**Outside handlers** — immediate:

```elixir
Hologram.Realtime.broadcast_action({:room, 42}, :new_message, message: "hi")
Hologram.Realtime.subscribe(component, {:room, 42})   # verify arity in your version
```

Subscriptions are **sticky for the page's lifetime** and auto-cleaned when the page unmounts.

### Delivery guarantees — there are none

Realtime is **fire-and-forget, at-most-once**: no acks, no replay buffer, no ordering guarantees. The sender also receives its own broadcast unless excluded with `put_broadcast_except`. **Do not** use Realtime as a source of truth or for anything that must not be lost — treat it as a hint to refresh, and reconcile against authoritative server state via a command when correctness matters.

## Design implications

- Keep **client-reachable code small and pure** — it all becomes JS.
- Push **anything privileged, stateful (OTP), regex-based, or heavy** into commands.
- Use Realtime for presence, live counters, notifications, and "something changed, refetch" signals — not for guaranteed message delivery.
