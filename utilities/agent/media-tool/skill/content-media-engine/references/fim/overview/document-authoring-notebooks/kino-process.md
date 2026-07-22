# Kino.Process

## What
Kino.Process provides real-time Erlang/Elixir process monitoring and visualization for LiveBook notebooks — inspecting process trees, supervision trees, message queues, and system metrics in interactive development environments.

## How
- The LLM emits Elixir: `Kino.Process.app_tree(:my_app)` / `Kino.Process.sup_tree(pid)` for tree visualization, `Kino.Process.info(pid)` and `render_seq_trace/1` for detail, and `memory_usage/0` for a system overview.
- Rendered by evaluating the LiveBook cell after adding `{:kino, "~> 0.12.0"}`; built into Kino.
- Final artifact: interactive process trees and information panels rendered in LiveBook cells.

## Why
- Reach for Kino.Process to debug and understand OTP systems in LiveBook — investigating crashes and bottlenecks, reviewing supervision-tree design, analyzing resource-heavy processes, and teaching supervision principles — with click-to-inspect and live updates.
- Tradeoffs: LiveBook-only, monitoring overhead on production systems, point-in-time snapshots, and basic filtering options.
- It is the runtime/OTP-introspection member of the Kino family, complementing Kino.ETS for storage-table inspection.

## Source
- Solution reference: `fim/solution/kino-process.md`
