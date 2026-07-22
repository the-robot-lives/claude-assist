# Kino.ETS

## What
Kino.ETS is a core Kino component that provides real-time visualization of Erlang Term Storage (ETS) tables inside Elixir LiveBook — showing table contents, metadata, and statistics with live updates.

## How
- The LLM emits Elixir: `Kino.ETS.new(table)` on an ETS table reference or named table, optionally with `refresh: 1000` for live monitoring.
- Rendered by evaluating the LiveBook cell; built into Kino with no additional dependencies.
- Final artifact: an interactive table viewer with metadata rendered in a LiveBook cell.

## Why
- Reach for Kino.ETS to debug and monitor ETS tables during development — inspecting cache/state tables, watching growth and access patterns, or teaching ETS behavior — with zero configuration and configurable live refresh.
- Tradeoffs: LiveBook-only, frequent refresh can impact table performance, read-only view, and it may slow with very large tables.
- It is the ETS-inspection member of the Kino family, complementing Kino.Process for OTP/runtime introspection.

## Source
- Solution reference: `fim/solution/kino-ets.md`
