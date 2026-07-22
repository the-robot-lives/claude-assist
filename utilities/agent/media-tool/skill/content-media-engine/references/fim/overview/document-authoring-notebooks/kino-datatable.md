# Kino.DataTable

## What
Kino.DataTable is a core Kino component that renders tabular data as interactive HTML tables — with sorting, filtering, and pagination — inside Elixir LiveBook notebooks.

## How
- The LLM emits Elixir: `Kino.DataTable.new(data)` over a list of maps/structs, or `Kino.DataTable.new(data, keys: [...])` for tuples, including large paginated datasets.
- Rendered by evaluating the LiveBook cell; it is built into Kino with no additional dependencies.
- Final artifact: an interactive table widget rendered in a LiveBook cell.

## Why
- Reach for Kino.DataTable for quick data exploration in LiveBook — inspecting query results, CSV/JSON imports, API responses, or pipeline intermediates — with zero setup, click-to-sort, filtering, and automatic type formatting.
- Tradeoffs: LiveBook-only, limited styling customization, read-only (no inline editing), and large datasets consume notebook memory.
- Within the Kino family it is the tabular-data viewer; pair with Kino.VegaLite/Kino.Plotly when you need charts rather than tables.

## Source
- Solution reference: `fim/solution/kino-datatable.md`
