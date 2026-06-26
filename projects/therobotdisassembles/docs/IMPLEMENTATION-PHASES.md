# IMPLEMENTATION-PHASES.md — Phases & Definitions of Done

> Six phases, thinnest-vertical-slice first ([ADR-005](adrs/ADR-005-end-to-end-slice-first.md)). Each phase lists **Goal / Deliverables (named) / Definition of Done / Depends on**. Phase 0 wires the whole chain end-to-end before any stage is deepened.

---

## Phase 0 — Walking skeleton (end-to-end slice)

**Goal:** Prove every stage is wired by getting bytes in → *some* source out, even if the output is trivial. Establish the solution, build tooling, and CI.

**Deliverables:**
- .NET solution + all four projects scaffolded ([layout/solution-layout.md](layout/solution-layout.md)); `Makefile` (`build`/`run`/`test`/`clean`/`doctor`); `.gitignore`; CI workflow.
- Mach-O header parse + `__TEXT,__text` extraction → minimal `BinaryImage`.
- Capstone decode via linear sweep → `Instruction[]` (CFG-driven decode deferred).
- Naive CFG: one basic block per symbol-table function; no loop detection.
- Trivial IR: registers → SSA values; **no** flag lowering yet.
- LLM lift = **passthrough** (produces empty `SemanticHints`; no network).
- Python codegen: print straight-line assignments.
- One sample: `samples/hello` (single-function arm64 binary, source-committed for golden diff).

**Definition of Done:**
- `make build` builds the solution; `make test` is green (scaffold tests + the hello sample).
- `make run -- samples/hello` prints Python derived from the binary.
- Each stage is independently unit-testable against its input record.
- CI runs `make build && make test`.

**Depends on:** nothing.

---

## Phase 1 — Loader & disassembly depth

**Goal:** Make the front-end correct and complete enough to feed a real CFG.

**Deliverables:**
- Fat/Universal binary handling → arm64 slice selection.
- Full load-command set: `LC_SEGMENT_64`, `LC_SYMTAB`/`LC_DYSYMTAB`, `LC_DYLD_INFO_ONLY` / `LC_DYLD_CHAINED_FIXUPS`, `LC_MAIN`, `LC_DATA_IN_CODE`, `LC_BUILD_VERSION`.
- Symbol table parse + **demangling** (Swift/C++ via P/Invoke).
- Chained-fixup / `__stubs` resolution to imported symbols.
- **Branch-driven (recursive) decode**; honor `LC_DATA_IN_CODE`.
- Capstone P/Invoke wrapper exposes register reads/writes + flag effects.

**Definition of Done:**
- Golden tests pass against a small source→binary corpus (≥5 binaries).
- No data-in-code range is decoded as an instruction.
- Indirect calls through `__stubs` resolve to named imports on the corpus.

**Depends on:** Phase 0.

---

## Phase 2 — CFG + SSA depth

**Goal:** Honest control flow and a verified SSA IR, including the flag-lowering problem.

**Deliverables:**
- Layered **function boundary detection**: symbols → `bl`/`b` targets → prologue heuristics → `__eh_frame`/compact-unwind fallback.
- Edge classification + **loop detection** (back-edges → natural loops).
- SSA renaming with phi insertion at dominance frontiers.
- **NZCV flags → explicit IR values.**
- AAPCS calling-convention → function signatures (param count from callsite arg-prep × callee body).
- Coarse memory model (load/store ordering; full memory-SSA deferred).
- Constraint-based type recovery v1 (size/width + access patterns).

**Definition of Done:**
- IR round-trips (lower IR → re-emit, structurally stable).
- Differential tests: CFG matches Ghidra CFG export on N binaries (≥10).
- No IR invariant violation on the corpus (every value defined once, phi operands consistent).

**Depends on:** Phase 1.

---

## Phase 3 — LLM semantic lift + Python codegen

**Goal:** Realize the differentiator — advisory semantics woven into Python output, safely.

**Deliverables:**
- Function-sized **chunking** (with region fallback for large functions).
- Context-window builder (SSA function + CFG + callee/caller summaries + recovered types).
- **Idiom library v1** (memset/memcpy/strcmp/sha256/AES-rounds/CRC32) matched by heuristics.
- LLM hint emission with **provenance + confidence**.
- **Validation pass** rejecting hints that violate typing/CFG invariants.
- **Content-addressed caching** (hash: input chunk + model + prompt-version).
- **Injection boundary**: binary content is delimited/escaped data; hints never executed.
- Python codegen honoring verified-over-advisory hints; inline docstrings.

**Definition of Done:**
- Idiom library matches the named patterns with no LLM call.
- LLM hints survive validation ≥ X% on the golden set (X set during the phase, recorded in [testing-strategy.md](specs/testing-strategy.md)).
- Re-running with cache produces byte-identical output.
- Cost/cache metrics captured (LLM calls per binary, cache hit rate).

**Depends on:** Phase 2.

---

## Phase 4 — More codegen + UX

**Goal:** A second target backend and a usable interactive experience.

**Deliverables:**
- **Rust** codegen backend (feature parity with Python's hint weaving).
- **Spectre.Console** CLI: `decompile`, `cfg`, `interactive` subcommands, status/progress, rich diagnostics.
- **Terminal.Gui** interactive TUI: function list, CFG/disassembly/IR/source split views.
- Dump/explorer views (raw Mach-O, symbol table, CFG graph export to dot).

**Definition of Done:**
- Rust backend passes the same golden suite shape as Python.
- CLI and TUI drive Phase-0→3 pipeline on the corpus without errors.
- Snapshot tests for both codegen backends green.

**Depends on:** Phase 3.

---

## Phase 5 — Hardening

**Goal:** Production quality and broader coverage.

**Deliverables:**
- Type recovery v2 (richer constraints, struct recovery).
- Performance optimization (large-binary decode time, memory).
- ARM64e/PAC **read-only** support (display/annotate; no deobfuscation).
- Additional target (Go; Swift-aware output where recoverable).
- Documentation polish, examples, tutorials; **v1.0**.

**Definition of Done:**
- Type-recovery precision improves measurably over Phase 2 v1 (metric recorded in testing-strategy).
- A defined large binary (e.g. a shipped Apple framework slice) decompiles within a target time budget.
- Release-vetted golden + differential suites green; v1.0 tagged.

**Depends on:** Phase 4.

---

## Phase → stage map

| Stage | Phase 0 (skeleton) | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|-------|--------------------|---------|---------|---------|---------|---------|
| Loader | minimal `__TEXT` | full + fat + fixups | — | — | — | — |
| Disasm | linear sweep | branch-driven + data-in-code | — | — | — | — |
| CFG | one block/fn | — | real fns + loops | — | — | — |
| IR/SSA | trivial | — | flags + sigs + types v1 | — | — | types v2 |
| LLM lift | passthrough | — | — | real + cache + injection | — | — |
| Codegen | Python (print) | — | — | Python + hints | + Rust | + Go |
| UX | — | — | — | — | CLI + TUI | polish |

Risks that gate phases are tracked in [TECHNICAL-RISKS.md](TECHNICAL-RISKS.md).
