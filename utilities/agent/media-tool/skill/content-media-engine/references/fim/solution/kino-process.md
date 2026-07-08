# Kino.Process — OTP process & supervision-tree visualization in Elixir Livebook

Kino.Process renders live Erlang/Elixir process topology as diagrams inside Livebook: application trees, supervision trees, and message-passing sequence traces. It reads the running BEAM and draws a Mermaid graph of the processes and their links/monitors, so you can *see* an OTP application's structure and message flow. Part of the **core `kino` package**. Runs only inside Livebook/Kino.

**Current Version**: ships with core `kino` (~> 0.11+); output is Mermaid rendered in-browser  **License**: Apache-2.0  **Runtime**: Livebook / Kino (introspects the connected BEAM node)

> Accuracy note: the real public functions are `app_tree/2`, `sup_tree/2`, and `seq_trace/2` (plus `render_seq_trace/2` in some versions). The stub's `Kino.Process.info/1` and `Kino.Process.memory_usage/0` are **not** part of the API — use `Process.info/1` and `:erlang`/`:recon` for those metrics, as shown below.

## Official Resources & Documentation
- Kino.Process docs: https://hexdocs.pm/kino/Kino.Process.html
- Kino repo: https://github.com/livebook-dev/kino
- OTP design principles (supervision): https://www.erlang.org/doc/design_principles/des_princ.html
- `Process` module: https://hexdocs.pm/elixir/Process.html
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([{:kino, "~> 0.12"}])
```
No extra dependency — it introspects the running node. To visualize *your* app, run Livebook attached to that node (or `Mix.install` your app into the notebook so its supervision tree is alive).

## Core Syntax / API Reference

### `Kino.Process.app_tree/2` — an application's whole tree
```elixir
Kino.Process.app_tree(:my_app)
Kino.Process.app_tree(:kino, direction: :top_down)
```
Draws the application master, its root supervisor, and all descendant processes. `opts`:
- `:direction` — `:top_down` (default) or `:left_right` (`:top_bottom`/`:left_right` layout of the Mermaid graph).

Pass the application atom. For the current app in a project notebook, use its OTP app name.

### `Kino.Process.sup_tree/2` — a single supervision tree
```elixir
{:ok, sup} = MyApp.Supervisor.start_link([])
Kino.Process.sup_tree(sup)

# By registered name:
Kino.Process.sup_tree(MyApp.Supervisor, direction: :left_right)
```
Accepts a supervisor pid or registered name. Shows children, their types (worker/supervisor), and links.

### `Kino.Process.seq_trace/2` — trace message passing
Runs a function while tracing the messages exchanged between the involved processes, then renders a Mermaid **sequence diagram** of what was sent:
```elixir
Kino.Process.seq_trace(fn ->
  parent = self()
  child = spawn(fn -> receive do {:ping, from} -> send(from, :pong) end end)
  send(child, {:ping, parent})
  receive do :pong -> :ok end
end)
```
Some versions expose `render_seq_trace/2`; prefer `seq_trace/2` in current Kino. You can also pass a list of pids to trace instead of a function in supported versions.

### Reading process metrics (not via Kino.Process)
For per-process info/memory (the capability the stub mislabeled), use standard tools and render the result:
```elixir
pid = spawn(fn -> Process.sleep(10_000) end)

Process.info(pid, [:memory, :message_queue_len, :status, :reductions])
# => [memory: 2680, message_queue_len: 0, status: :waiting, reductions: 12]

# top memory processes (with :recon added as a dep):
# :recon.proc_count(:memory, 10)
```
Wrap such data in `Kino.DataTable.new/1` for a sortable view.

## What you can visualize
Application trees (`app_tree`), supervision trees for any supervisor (`sup_tree`), and message-passing sequence traces (`seq_trace`). The rendered output is a Mermaid graph/sequence diagram — static SVG per call, re-run to refresh.

## How-To (worked recipes)

### How to visualize your application's supervision tree
```elixir
# If your app is started in the notebook or the attached node:
Kino.Process.app_tree(:my_app, direction: :left_right)
```
Nodes are processes; edges are supervision links. Supervisors and workers are visually distinguished.

### How to inspect an ad-hoc supervisor you start
```elixir
children = [
  {Agent, fn -> 0 end},
  {Task.Supervisor, name: MyTaskSup}
]
{:ok, sup} = Supervisor.start_link(children, strategy: :one_for_one)
Kino.Process.sup_tree(sup)
```

### How to trace and diagram a message exchange
```elixir
Kino.Process.seq_trace(fn ->
  {:ok, agent} = Agent.start_link(fn -> %{} end)
  Agent.update(agent, &Map.put(&1, :k, 1))
  Agent.get(agent, & &1)
end)
```
The resulting sequence diagram shows the calls/casts between your process and the Agent.

### How to change layout direction ("styling" analog)
Kino.Process output is a Mermaid diagram; your styling lever is layout direction and scope, not colors:
```elixir
Kino.Process.app_tree(:my_app, direction: :top_down)   # or :left_right
```
For a hand-styled architecture diagram, author it yourself with `Kino.Mermaid` (colors, classDefs) — see kino-mermaid.md.

### How to build a sortable process metrics table
```elixir
Process.list()
|> Enum.map(fn pid ->
  info = Process.info(pid, [:registered_name, :memory, :message_queue_len]) || []
  %{
    pid: inspect(pid),
    name: info[:registered_name] |> then(&(&1 && inspect(&1))) || "",
    memory: info[:memory] || 0,
    mailbox: info[:message_queue_len] || 0
  }
end)
|> Enum.sort_by(& &1.memory, :desc)
|> Enum.take(20)
|> Kino.DataTable.new(keys: [:pid, :name, :memory, :mailbox], name: "Top processes by memory")
```

## Do's and Don'ts
### ✅ Do
- Attach Livebook to (or `Mix.install`) the app whose tree you want — otherwise `app_tree` finds nothing.
- Use `sup_tree/2` for a focused view of one supervisor; `app_tree/2` for the whole app.
- Use `seq_trace/2` to *see* who-sends-what during a specific operation.
- Use `Process.info/1` (+ optionally `:recon`) for memory/mailbox metrics and render via `Kino.DataTable`.
- Re-run the cell to refresh — trees are point-in-time snapshots.

### ❌ Don't
- Don't call `Kino.Process.info/1` or `memory_usage/0` — they aren't in the API; use `Process.info/1` / `:recon`.
- Don't run heavy tracing (`seq_trace`) against busy production processes — tracing has overhead.
- Don't expect auto-refreshing trees — call again (optionally via `Kino.animate/3`) for updates.
- Don't pass an application that isn't started — `app_tree` needs a live tree.
- Don't visualize enormous trees at once — scope to a subtree with `sup_tree/2`.

## Styling, Theming & Customization
Kino.Process renders Mermaid with a fixed style; the only knob is `:direction` (`:top_down` / `:left_right`) and *which* tree/scope you render. It does not accept colors, classDefs, or labels. When you need a styled, annotated architecture diagram, capture the topology mentally and re-author it with `Kino.Mermaid` where you control `classDef`, colors, and grouping (see kino-mermaid.md). For refreshing snapshots, wrap a call in `Kino.animate/3`.

## Advanced Features
- **Sequence tracing**: `seq_trace/2` converts real message flow into a diagram — invaluable for understanding GenServer call/cast chains.
- **Scoped views**: `sup_tree/2` on a subtree keeps large systems legible.
- **Metrics pairing**: `Process.info/1`, `:erlang.memory/0`, and `:recon.proc_count/2` feed `Kino.DataTable`/charts for quantitative analysis.
- **Live refresh**: `Kino.animate(1000, fn _ -> Kino.Process.app_tree(:my_app) end)` for a heartbeat view.

## Common Pitfalls & Troubleshooting
- **Empty/`app_tree` fails**: the application isn't started on the connected node, or the app atom is wrong.
- **`info/1`/`memory_usage/0` undefined**: those aren't Kino.Process functions — use `Process.info/1` / `:recon`.
- **Diagram too dense**: scope down with `sup_tree/2`, or split by subsystem.
- **Trace shows nothing**: the traced function didn't actually exchange messages, or processes died before rendering.
- **Production overhead**: tracing and frequent snapshots cost CPU — throttle and scope.

## Integration Notes (Livebook/Kino)
- Best used in a notebook attached to a running node (remote node connection or `Mix.install` of your app).
- Complements kino-ets.md: find the process owning an ETS table, then inspect the table.
- Output is Mermaid — the same rendering path as kino-mermaid.md, so it slots into notebook documentation.

## Best For / Avoid For
`livebook`, `elixir`, `erlang`, `otp`, `supervision-tree`, `debugging`, `process-monitoring`, `observability`
- **Best for**: understanding/debugging OTP supervision structure, teaching supervision strategies, tracing message flows, architecture review of a running system.
- **Avoid for**: production dashboards, styled architecture diagrams (author with Kino.Mermaid), or quantitative metrics at scale (use `:recon`/observer/telemetry).

## See Also
- [kino-ets.md](kino-ets.md) — inspect ETS tables owned by processes you find here
- [kino-mermaid.md](kino-mermaid.md) — author styled architecture diagrams by hand
- [kino-datatable.md](kino-datatable.md) — render process metrics tables
- `../use-case/elixir-livebook-components.md`
