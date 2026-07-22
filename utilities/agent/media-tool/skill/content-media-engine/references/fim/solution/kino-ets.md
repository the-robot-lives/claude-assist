# Kino.ETS — Interactive ETS table viewer in Elixir Livebook

Kino.ETS renders the contents of an [ETS](https://www.erlang.org/doc/man/ets.html) (Erlang Term Storage) table as an interactive, paginated table in a Livebook cell. It is part of the **core `kino` package** and is the ETS-specific sibling of `Kino.DataTable`: point it at a table id or named table and it shows the rows with a manual **Refresh** control in the UI so you can re-read a live, changing table. Runs only inside Livebook/Kino.

**Current Version**: ships with core `kino` (~> 0.11+)  **License**: Apache-2.0  **Runtime**: Livebook / Kino

> Accuracy note: `Kino.ETS.new/1` takes the table reference. Live updating is done with the **Refresh button** in the widget (and/or by re-running the cell / driving it with `Kino.animate`). The stub's `refresh: 1000` option does **not** exist in the public API — use the recipes below for periodic refresh instead.

## Official Resources & Documentation
- Kino.ETS docs: https://hexdocs.pm/kino/Kino.ETS.html
- Erlang `:ets` reference: https://www.erlang.org/doc/man/ets.html
- `Kino.animate/2,3` (periodic re-render): https://hexdocs.pm/kino/Kino.html#animate/3
- Kino repo: https://github.com/livebook-dev/kino
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([{:kino, "~> 0.12"}])
```
No extra dependency — ETS is built into the BEAM, and the viewer ships with Kino.

## Core Syntax / API Reference

### Entry point
```elixir
Kino.ETS.new(tid)
```
`tid` — an ETS table reference (from `:ets.new/2`) **or** a named-table atom (created with the `:named_table` option). Returns a widget; return it as the cell result to render.

### From an anonymous table
```elixir
table = :ets.new(:sample_table, [:set, :public])
:ets.insert(table, {:user_1, "Alice", 30})
:ets.insert(table, {:user_2, "Bob", 25})
:ets.insert(table, {:user_3, "Carol", 35})

Kino.ETS.new(table)
```

### From a named table
```elixir
:ets.new(:stats, [:named_table, :public])
:ets.insert(:stats, {:requests, 1245})
:ets.insert(:stats, {:errors, 12})

Kino.ETS.new(:stats)
```

### Table types & access — what you can view
ETS `type` (first tuple element is the key): `:set` (unique keys), `:ordered_set` (sorted), `:bag` (multiple objects per key), `:duplicate_bag`. Access: `:public` (any process reads/writes), `:protected` (owner writes, others read — the default), `:private` (owner only). Kino.ETS reads via `:ets.tab2list/1`-style access, so the table must be readable from the Livebook process — use `:public` (or `:protected` and inspect from the owner) for tables you create in another process.

### What the viewer shows
- Every stored tuple as a row; tuple positions become columns (`0`, `1`, `2`, …), the key column first.
- A **Refresh** button to re-read current contents.
- Row count / pagination for large tables.

## How-To (worked recipes)

### How to periodically refresh the view ("live monitoring")
There is no `refresh:` option; use `Kino.animate/3` to re-render on an interval, or click Refresh manually:
```elixir
:ets.new(:metrics, [:named_table, :public])
:ets.insert(:metrics, {:hits, 0})

# background writer
spawn(fn ->
  Stream.iterate(0, &(&1 + 1))
  |> Enum.each(fn n ->
    :ets.insert(:metrics, {:hits, n})
    Process.sleep(500)
  end)
end)

# re-render the table every second
Kino.animate(1000, fn _ -> Kino.ETS.new(:metrics) end)
```
`Kino.animate/3` replaces the cell output on each tick, giving you a self-updating view without a built-in refresh option.

### How to inspect a table owned by another process
The table must be readable from the Livebook process:
```elixir
# In the owning process, create it public (or named + public):
:ets.new(:cache, [:named_table, :public, read_concurrency: true])
# In a Livebook cell:
Kino.ETS.new(:cache)
```
If it's `:private`, you can't view it from Livebook — recreate as `:public`/`:protected` for inspection.

### How to view a GenServer/Registry-style state table
```elixir
# Suppose MyApp.Cache holds a public named table :my_cache
Kino.ETS.new(:my_cache)
```
Pair with kino-process.md to see the owning process, and re-render to watch churn.

### How to "style"/shape what you see (styling analog)
Kino.ETS has no visual theming; its customization is **what you store**. To control columns/labels, project the table into a `Kino.DataTable` with named fields:
```elixir
rows =
  :ets.tab2list(:stats)
  |> Enum.map(fn {key, value} -> %{metric: key, value: value} end)

Kino.DataTable.new(rows, keys: [:metric, :value], name: "Stats")
```
This gives you column names, ordering, and titles that Kino.ETS's positional view can't.

## How-To pagination / large tables
```elixir
big = :ets.new(:big, [:set, :public])
Enum.each(1..50_000, fn i -> :ets.insert(big, {i, :rand.uniform(100)}) end)
Kino.ETS.new(big)   # paginate in the UI; avoid tab2list on huge tables
```

## Do's and Don'ts
### ✅ Do
- Create tables `:public` (or `:protected` and inspect from the owner) so Livebook can read them.
- Use `Kino.animate/3` for periodic refresh instead of looking for a `refresh:` option.
- Project into `Kino.DataTable` when you need named columns, ordering, or a title.
- Use it as a debugging lens on caches, registries, and GenServer-backed ETS state.
- Keep refresh intervals modest — each refresh reads the table.

### ❌ Don't
- Don't pass `refresh: N` to `Kino.ETS.new/2` — that option doesn't exist; it will error or be ignored.
- Don't try to view a `:private` table from Livebook — it isn't readable from another process.
- Don't `:ets.tab2list/1` a multi-million-row table just to view it — paginate via the widget or sample.
- Don't expect editing — the viewer is read-only; mutate with `:ets.insert/2` then refresh.
- Don't refresh aggressively on a hot production table — reads add contention.

## Styling, Theming & Customization
Kino.ETS is a fixed, read-only viewer: no CSS, no column renaming, no theming. Positional columns are labeled by tuple index. For anything richer — named columns, ordering, formatted values, badges — convert the table with `:ets.tab2list/1` + `Enum.map/2` into maps and render with `Kino.DataTable` (or a custom `Kino.JS` widget). Treat "styling" here as "shape the data you feed a DataTable."

## Advanced Features
- **Live re-render**: `Kino.animate/3` turns the static snapshot into a monitor.
- **Introspection pairing**: combine with `:ets.info(tid)` (size, memory, type, owner) printed alongside the table for full context.
- **Cross-widget**: feed `:ets.tab2list/1` output into charts (Kino.VegaLite/Kino.Plotly) to visualize cache/metric growth over time.
- **Named-table discovery**: `:ets.all/0` lists tables; inspect any readable one by reference.

## Common Pitfalls & Troubleshooting
- **`refresh:` errors / ignored**: not a real option — use `Kino.animate/3`.
- **Empty or inaccessible**: table is `:private`, or the reference/name is stale (table was deleted or owner died).
- **Positional column names unhelpful**: project into maps + `Kino.DataTable` for labeled columns.
- **Slow refresh**: table is large or hot; increase the interval, paginate, or snapshot less often.
- **`badarg`**: the `tid` is invalid (owner process exited and the table was destroyed).

## Integration Notes (Livebook/Kino)
- Core Kino — always present, zero setup.
- Complements kino-process.md: find the process that owns a table, then inspect the table.
- For DataFrame-shaped data prefer `Kino.DataTable`/`Kino.Explorer`; Kino.ETS is specifically for raw ETS tuples.

## Best For / Avoid For
`livebook`, `elixir`, `erlang`, `ets`, `debugging`, `cache-monitoring`, `state-inspection`
- **Best for**: debugging ETS-backed caches, registries, and GenServer state; teaching ETS behavior; watching a table change during development.
- **Avoid for**: production dashboards, styled/editable tables, or huge tables you'd rather sample and chart.

## See Also
- [kino-datatable.md](kino-datatable.md) — richer table viewer with named columns/ordering
- [kino-process.md](kino-process.md) — find and inspect the process owning a table
- [kino-js.md](kino-js.md) — build a custom, styled, or auto-refreshing table widget
- `../use-case/elixir-livebook-components.md`
