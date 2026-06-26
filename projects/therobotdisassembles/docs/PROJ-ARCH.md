# PROJ-ARCH.md — Architecture Summary

> Full architecture write-up. For the one-page version see [PROJ-ARCH.summary.md](PROJ-ARCH.summary.md). For the big-picture pipeline diagram see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 1. Purpose & differentiator

The Robot Dissassembles decompiles **Apple-Silicon (arm64) Mach-O binaries** into readable source code (Python, Rust, Go). Where Ghidra and IDA Pro excel at *accurate binary analysis* but struggle with *semantic intent* — they tell you *what* code does, not *why* — this tool inserts an **LLM semantic-lift stage** between its verified IR and target-language codegen. The LLM proposes variable names, types, recognized idioms (hashing/crypto/compression), and doc comments; those proposals are layered as **advisory hints** over a **verified** IR and never override deterministic facts.

## 2. Stage-by-stage architecture

### 2.1 Binary Loader (`Core/Parsing`)
Reads a Mach-O 64 file and produces a `BinaryImage`: segments, sections, symbol table, fixups, entrypoints. Owns the file-offset↔VM-address map behind a single `Address` abstraction. Detects fat/universal containers and selects the arm64 slice. **Recommendation: a hand-written parser** — the Mach-O header is small and stable, and a bespoke parser avoids a stale third-party dependency. The parser is internal, not a public API. Detail: [binary-loading.md](arch/binary-loading.md).

### 2.2 Disassembler (`Core/Disassembly`)
Decodes `__TEXT,__text` bytes into `Instruction[]` using **Capstone via a thin P/Invoke wrapper** ([ADR-002](adrs/ADR-002-capstone-via-pinvoke.md)). The wrapper exposes not just mnemonic/operands but **register reads/writes and flag effects** (needed by SSA). Prefers **CFG-driven (recursive) decode** to linear sweep so data-in-code (literals, jump tables) isn't mis-decoded as instructions, honoring `LC_DATA_IN_CODE`. Detail: [disassembly.md](arch/disassembly.md).

### 2.3 CFG Builder (`Core/ControlFlow`)
Splits instructions into basic blocks, classifies edges (fallthrough/cond/ret/call/indirect), and detects **functions** via a layered strategy: symbol-table entries first, then `bl`/`b` call targets, then prologue heuristics + `__eh_frame`/compact-unwind for stripped binaries. Resolves indirect calls through `__stubs`/chained fixups to imported symbols. Finds loops via back-edges. Output: `ControlFlowGraph`. Detail: [control-flow.md](arch/control-flow.md).

### 2.4 IR Lowerer + SSA (`Core/PseudoCode`)
Lowers the arm64 CFG into a **typed SSA IR** ([ADR-003](adrs/ADR-003-ssa-based-ir.md)). Every register/immediate/alu/load-store op becomes an IR op; SSA renaming runs over the CFG with phi insertion at dominance frontiers. Two deliberately hard problems:

- **Condition flags (NZCV) → explicit IR values.** ARM64 `cmp`/`adds` set flags, `b.eq`/`csel` consume them. Leaving flags implicit is the classic source of decompiler garbage; we lower them to first-class values so the dataflow is honest.
- **Calling convention → signatures.** arm64 AAPCS (`x0–x7` args, `x0` return, `x29`/`x30` frame). Parameter count recovered from callsite arg-prep cross-referenced with the callee body.

**Type recovery** starts constraint-based (size from load/store width, structure from access patterns, value ranges) and deepens later. Memory model is **coarse** initially (load/store ordering without full memory-SSA); full memory-SSA is deferred. Output: `SsaModule`. Detail: [ir-and-ssa.md](arch/ir-and-ssa.md).

### 2.5 LLM Semantic Lift (`Core/LLM`) — the differentiator
Takes the `SsaModule` plus heuristic **idiom-library** matches and asks the LLM to propose names/types/idioms/comments. Three properties make this safe and useful ([ADR-004](adrs/ADR-004-llm-output-is-advisory.md)):

1. **Advisory, not authoritative.** Output is a separate `SemanticHints` layer with **provenance** (LLM/heuristic/symbol) and **confidence**. A validation pass rejects any hint that violates typing or CFG invariants.
2. **Reproducible & cached.** Prompts are **content-addressed** (hash of input chunk + model id + prompt-version) so re-runs hit a cache and tests are deterministic. The stage is impure (network) but behaves like a pure function of its input.
3. **Injection-resistant.** Binary bytes/strings enter the prompt as **delimited, escaped data**; the model is told the input is adversarial; hints are never executed.

**Cost control:** the idiom library + heuristics short-circuit obvious cases (memset, strcmp, sha256, AES rounds) without an LLM call; the LLM only sees genuinely ambiguous code. Output: `AnnotatedModule` (`SsaModule` + `SemanticHints`). Detail: [llm-semantic-lift.md](arch/llm-semantic-lift.md).

### 2.6 Codegen (`Core/Codegen`)
Lowers the `AnnotatedModule` to target source via a per-language target AST and pretty-printer. **Verified-over-advisory:** uses LLM-proposed names for locals/params when type-consistent, emits recovered-or-suggested types, and inlines doc comments — but drops any hint conflicting with a verified IR fact (emitting a diagnostic). Python is the first backend; Rust and Go follow. Detail: [codegen.md](arch/codegen.md).

## 3. Architectural rules (the invariants)

1. **Pure stages, impure edges.** All six stages are pure functions over immutable records. Impurity (file I/O in the Loader, network in the LLM stage) is confined to those two edges. This is what makes the pipeline unit-testable without mocks, cacheable, and snapshot-friendly.
2. **Advisory over verified.** Deterministic analysis produces verified facts; the LLM produces advisory hypotheses. Verified always wins. Hints are never executed and never mutate the IR.
3. **End-to-end slice first.** Phase 0 wires the entire chain before any stage is deepened ([ADR-005](adrs/ADR-005-end-to-end-slice-first.md)).

## 4. Cross-cutting

- **`Address` abstraction** — virtual addresses everywhere downstream; offset mapping owned by the Loader.
- **Symbol resolver** — address↔name with Swift/C++ demangling (P/Invoke to `libswift-demangle`/libc++ demangle).
- **Diagnostic sink** — structured per-stage diagnostics feeding both the CLI and test assertions.
- **`IBinarySource`** — abstracts fat slice / raw Mach-O / `.dylib` / raw hex behind one type the downstream stages consume.

## 5. Tech stack
C#/.NET 8 · Capstone (native, via P/Invoke) · Claude API · **Spectre.Console** (rich CLI) + **Terminal.Gui** (interactive TUI). Build via `Makefile` wrapping `dotnet`. (The README's "Textual" is a Python library — corrected in [ADR-001](adrs/ADR-001-dotnet-solution-layout.md).)

## 6. Solution layout (summary)
```
src/TherobotDissassembles.Core/   # six stages + shared contract types
src/TherobotDissassembles.CLI/    # Spectre.Console driver
src/TherobotDissassembles.TUI/    # Terminal.Gui interactive explorer
tests/TherobotDissassembles.Tests/ # golden / differential / property
```
Full annotation: [layout/solution-layout.md](layout/solution-layout.md).
