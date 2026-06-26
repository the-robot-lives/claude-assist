# PROJ-ARCH.summary.md — Architecture (one page)

> The whole design on a single page. Detail lives in [PROJ-ARCH.md](PROJ-ARCH.md) and the [arch/](arch/) deep-dives.

---

## What it is
A macOS-native, Apple-Silicon-only **arm64 decompiler** in C#/.NET 8. Mach-O in, readable source out, with an **LLM semantic-lift stage** that recovers intent (names/types/idioms/comments) traditional decompilers miss.

## The six stages (the spine)

| # | Stage | Input → Output | Key idea |
|---|-------|----------------|----------|
| 1 | **Binary Loader** | file → `BinaryImage` | Parse Mach-O 64; pick arm64 slice from fat binaries; own the file-offset↔VM-address map. Roll-own parser. |
| 2 | **Disassembler** | `BinaryImage` → `Instruction[]` | Capstone via thin P/Invoke wrapper ([ADR-002](adrs/ADR-002-capstone-via-pinvoke.md)); expose reg reads/writes + flags; honor data-in-code. |
| 3 | **CFG Builder** | `Instruction[]` → `ControlFlowGraph` | Basic blocks; function detection (symbols → calls → eh_frame); loops; resolve dyld stubs. |
| 4 | **IR Lowerer + SSA** | `ControlFlowGraph` → `SsaModule` | Typed SSA IR ([ADR-003](adrs/ADR-003-ssa-based-ir.md)); **NZCV flags → explicit values**; AAPCS signatures; constraint-based type recovery. |
| 5 | **LLM Semantic Lift** | `SsaModule` → `AnnotatedModule` | The differentiator ([ADR-004](adrs/ADR-004-llm-output-is-advisory.md)): advisory names/types/idioms/comments with provenance+confidence; idiom library short-circuits obvious cases; content-addressed caching. |
| 6 | **Codegen** | `AnnotatedModule` → source | Python (first), then Rust/Go; verified-over-advisory when weaving hints. |

## The three rules that make it hold together

1. **Pure stages, impure edges.** Every stage is a pure function over immutable records; only the Loader (file I/O) and LLM stage (network) touch the outside world. Result: trivial to unit-test, cache, and snapshot.
2. **LLM output is advisory, not authoritative.** IR facts from deterministic analysis are *verified*; LLM hints are *hypotheses*. On conflict, **verified wins** and the hint is dropped (with a diagnostic). Hints are never executed.
3. **End-to-end slice first.** Phase 0 wires all six stages before deepening any one ([ADR-005](adrs/ADR-005-end-to-end-slice-first.md)) — bytes→source, even if the source is trivial.

## Stack
- C# / .NET 8 (`net8.0`)
- Capstone disassembler (native `libcapstone` via P/Invoke)
- Claude API for the semantic-lift stage
- CLI: **Spectre.Console** · Interactive TUI: **Terminal.Gui** (README's "Textual" was a Python-library mistake)
- Build via a `Makefile` wrapping `dotnet` (mirrors sibling `therobotdrafts` conventions)

## Stage contracts (the types handed between stages)
`BinaryImage` → `Instruction[]` → `ControlFlowGraph` → `SsaModule` → `AnnotatedModule` (= `SsaModule` + `SemanticHints`) → `string`. Full definitions: [pipeline-and-data-flow.md](arch/pipeline-and-data-flow.md).

## Phase plan (condensed)
- **Phase 0** — Walking skeleton: every stage wired, bytes→source. (slice-first)
- **Phase 1** — Loader + disassembly depth (fat, fixups, demangle, data-in-code).
- **Phase 2** — CFG + SSA depth (function detection, loops, flags, signatures).
- **Phase 3** — LLM lift + Python codegen (chunking, validation, caching, injection boundary).
- **Phase 4** — Rust codegen + UX (Spectre CLI, Terminal.Gui TUI).
- **Phase 5** — Hardening (type recovery v2, perf, more targets, v1.0).

See [IMPLEMENTATION-PHASES.md](IMPLEMENTATION-PHASES.md) for deliverables + definitions of done.
