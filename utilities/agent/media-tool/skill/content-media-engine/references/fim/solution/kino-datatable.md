# Kino.DataTable — Interactive tables in Elixir Livebook

Kino.DataTable renders any tabular Elixir data as an interactive HTML table in a Livebook cell, with client-side sorting, column selection, and pagination. It is part of the **core `kino` package** (no extra dependency) and accepts anything that looks like rows: a list of maps, a list of keyword lists, a list of structs, or any source implementing the `Table.Reader` protocol (Explorer `DataFrame`, query results, etc.). Runs only inside Livebook/Kino.

**Current Version**: ships with core `kino` (~> 0.11+)  **License**: Apache-2.0  **Runtime**: Livebook / Kino

> Accuracy note: `Kino.DataTable.new/2` expects **records with named fields** (maps, keyword lists, structs) or a `Table.Reader` source. A list of *bare tuples* is not directly supported — map tuples to maps/keyword lists first (shown below). The older stub's `{"Alice", 30}` + `keys:` form does not reflect the current API.

## Official Resources & Documentation
- Kino.DataTable docs: https://hexdocs.pm/kino/Kino.DataTable.html
- Table.Reader protocol: https://hexdocs.pm/table/Table.Reader.html
- Explorer (DataFrames): https://hexdocs.pm/explorer
- Kino repo: https://github.com/livebook-dev/kino
- Livebook: https://livebook.dev/

## Installation & Setup
### Mix / Livebook setup cell
```elixir
Mix.install([{:kino, "~> 0.12"}])
```
For DataFrame sources also add `{:explorer, "~> 0.8"}`.

## Core Syntax / API Reference

### Entry point
```elixir
Kino.DataTable.new(tabular, opts \\ [])
```
`tabular` — a list of records (maps / keyword lists / structs) or a `Table.Reader`. `opts`:
- `:keys` — list of atoms selecting **which columns to show and in what order** (also whitelists fields).
- `:name` — table title shown in the UI.
- `:sorting_enabled` — boolean (default `true`).
- `:num_rows` — initial rows per page.

### From a list of maps (most common)
```elixir
data = [
  %{name: "Alice", age: 30, city: "NYC"},
  %{name: "Bob", age: 25, city: "LA"},
  %{name: "Carol", age: 35, city: "Chicago"}
]

Kino.DataTable.new(data)
```

### Select / order columns with `:keys`
```elixir
Kino.DataTable.new(data, keys: [:name, :city], name: "People")
```
Only `:name` and `:city` render, in that order.

### From keyword lists
```elixir
rows = [
  [name: "Alice", age: 30],
  [name: "Bob", age: 25]
]
Kino.DataTable.new(rows)
```

### From bare tuples — convert first
```elixir
tuples = [{"Alice", 30, "NYC"}, {"Bob", 25, "LA"}]

rows =
  Enum.map(tuples, fn {name, age, city} ->
    %{name: name, age: age, city: city}
  end)

Kino.DataTable.new(rows)
```

### From an Explorer DataFrame (Table.Reader)
```elixir
require Explorer.DataFrame, as: DF
df = DF.new(name: ["Alice", "Bob"], age: [30, 25])
Kino.DataTable.new(df)         # DataFrames implement Table.Reader
```

### Large data with pagination
```elixir
large = Enum.map(1..10_000, fn i -> %{id: i, value: :rand.uniform(100)} end)
Kino.DataTable.new(large, keys: [:id, :value], num_rows: 25)
```
Pagination is client-driven; the full dataset lives in the notebook process, so memory is bounded by your data, not the view.

## Output/data shapes it accepts
List of maps, list of keyword lists, list of structs (struct fields become columns), Explorer `DataFrame`, and any custom `Table.Reader` implementation (query results, CSV readers, etc.). Heterogeneous rows are unioned into the full column set; missing cells render empty.

## How-To (worked recipes)

### How to control columns, order, and the table title ("styling")
Kino.DataTable has no CSS theming; its "styling" surface is column selection, ordering, naming, and sort behavior:
```elixir
Kino.DataTable.new(users,
  keys: [:id, :name, :signed_up_at, :plan],   # choose + order columns
  name: "Active users",                        # header title
  sorting_enabled: true,                        # click headers to sort
  num_rows: 20
)
```
For actual visual formatting (colors, badges, custom cells), pre-format values into strings/emoji in Elixir, or drop to `Kino.JS` for a bespoke table.

### How to display query results
Any list of maps works — e.g. from Ecto or a Postgrex result mapped to maps:
```elixir
%Postgrex.Result{columns: cols, rows: rows} = result

rows
|> Enum.map(fn row -> cols |> Enum.zip(row) |> Map.new() end)
|> Enum.map(fn m -> Map.new(m, fn {k, v} -> {String.to_atom(k), v} end) end)
|> Kino.DataTable.new(name: "Query result")
```

### How to pre-format cells (dates, money, booleans)
```elixir
orders
|> Enum.map(fn o ->
  %{
    id: o.id,
    total: "$#{:erlang.float_to_binary(o.total, decimals: 2)}",
    paid: (if o.paid?, do: "✅", else: "—"),
    date: Calendar.strftime(o.inserted_at, "%Y-%m-%d")
  }
end)
|> Kino.DataTable.new(keys: [:id, :date, :total, :paid])
```

### How to combine with a chart
Inspect rows, then plot the same data:
```elixir
data = [%{category: "A", value: 30}, %{category: "B", value: 55}]
Kino.DataTable.new(data)                              # table view
# in another cell, feed the same list to VegaLite / Plotly
```

## Do's and Don'ts
### ✅ Do
- Feed records with named fields (maps/keyword lists/structs) or a `Table.Reader` source.
- Use `:keys` to whitelist and order columns — it also hides noisy fields.
- Convert tuples/rows-with-positional-columns into maps before passing them in.
- Prefer an Explorer `DataFrame` for large/typed data; it streams through Table.Reader efficiently.
- Pre-format display values (dates, currency) in Elixir since there's no cell renderer API.

### ❌ Don't
- Don't pass a list of bare tuples and expect `keys:` to name them — map them to maps first.
- Don't expect inline editing — the table is read-only.
- Don't look for CSS/theme options — there are none; format values instead or use `Kino.JS`.
- Don't hold multi-million-row lists in the notebook just to view them — sample/aggregate first.
- Don't rely on column order from map iteration — set it explicitly with `:keys`.

## Styling, Theming & Customization
Kino.DataTable is intentionally minimal: no CSS hooks, no per-cell renderers. Your customization levers are `:keys` (columns + order), `:name` (title), `:sorting_enabled`, `:num_rows`, and **value pre-formatting** in Elixir (emoji, formatted strings). For badges, colors, conditional formatting, or clickable cells, build a custom table with `Kino.JS`/`Kino.JS.Live` (see kino-js.md).

## Advanced Features
- **Table.Reader interop**: anything implementing the protocol (Explorer, custom readers) renders without conversion.
- **Struct support**: pass a list of structs; their fields become columns (`:__struct__`/`:__meta__` are filtered).
- **Pairing**: the canonical "inspect → chart" pattern — DataTable to eyeball rows, then Kino.VegaLite/Kino.Plotly to visualize.
- **Smart cells**: Livebook's Explorer "Data transform" smart cell produces DataFrames that drop straight into `Kino.DataTable.new/1`.

## Common Pitfalls & Troubleshooting
- **Empty/oddly-named columns**: you passed tuples or structs with unexpected fields; map to explicit maps and set `:keys`.
- **Columns in surprising order**: map key order isn't stable — pass `:keys`.
- **Huge/slow cell**: dataset too large; page with `:num_rows`, or sample/aggregate upstream.
- **A field won't display**: it's not in `:keys`, or rows are missing that key (renders blank).
- **Want colors/badges**: not supported natively — pre-format to strings/emoji or use `Kino.JS`.

## Integration Notes (Livebook/Kino)
- Core Kino — always available, zero setup.
- Natural companion to Explorer for data wrangling and to Kino.VegaLite/Kino.Plotly for visualization.
- The `Kino.Explorer` widget is a richer, DataFrame-specific alternative when you're working entirely in Explorer.

## Best For / Avoid For
`livebook`, `elixir`, `tables`, `data-inspection`, `query-results`, `pagination`
- **Best for**: quickly inspecting query results, CSV/JSON imports, pipeline intermediates, and any list-of-maps during exploration.
- **Avoid for**: editable grids, richly styled/conditional-formatted tables, or non-Livebook UIs (build with Kino.JS or a web grid instead).

## See Also
- [kino-vegalite.md](kino-vegalite.md), [kino-plotly.md](kino-plotly.md) — chart the inspected data
- [kino-ets.md](kino-ets.md) — the ETS-specific table viewer
- [kino-js.md](kino-js.md) — build a custom, styled, or editable table
- `../use-case/elixir-livebook-components.md`, `../use-case/data-visualization.md`
