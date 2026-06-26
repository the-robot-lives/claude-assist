# CONCEPTS.md — Glossary

> The vocabulary used across the decompiler docs. Read this first if a term in another doc is unfamiliar.

---

## Binary formats

- **Mach-O** — Apple's native executable/object format. This project targets **Mach-O 64** (`MH_MAGIC_64`, `0xfeedfacf`) for the **arm64** (AArch64) architecture. See [binary-formats.md](specs/binary-formats.md).
- **Fat / Universal binary** — A container (`FAT_MAGIC` arch array) holding multiple Mach-O slices (e.g. arm64 + x86_64). The loader picks the arm64 slice and treats it as a standalone Mach-O.
- **Load command** — A typed record in the Mach-O header describing one aspect of the binary (a segment, the symbol table, the entrypoint, fixup data). e.g. `LC_SEGMENT_64`, `LC_SYMTAB`, `LC_MAIN`, `LC_DYLD_INFO_ONLY`, `LC_DYLD_CHAINED_FIXUPS`, `LC_DATA_IN_CODE`.
- **Segment / Section** — Segments (`LC_SEGMENT_64`) divide the file into VM regions; each holds **sections** (e.g. `__TEXT,__text` = code, `__TEXT,__stubs` = dyld call stubs, `__DATA,__got` = global offset table).
- **Symbol table (`LC_SYMTAB`)** — The list of named symbols (`nlist_64`): imported, exported, and local. Function symbols here are the primary source of function boundaries and names.
- **Fixups** — Address-binding metadata the dynamic linker (`dyld`) resolves at load: classic (`LC_DYLD_INFO_ONLY`) or modern **chained fixups** (`LC_DYLD_CHAINED_FIXUPS`). Used to resolve indirect calls through `__stubs` to imported symbols.
- **`__PAGEZERO`** — The low virtual-memory guard segment (unmapped); relevant to the address-space model, not to code.

## Disassembly

- **Disassembly** — Translating raw bytes into instructions. We use the **Capstone** engine (see [disassembly.md](arch/disassembly.md) and [ADR-002](adrs/ADR-002-capstone-via-pinvoke.md)).
- **Linear sweep** — Decoding every byte in order. Fast but garbles data-in-code (literals, jump tables) into fake instructions.
- **CFG-driven / recursive decode** — Decoding by following branches; avoids decoding data. Our preferred strategy once symbol/branch info exists.
- **Data-in-code (`LC_DATA_IN_CODE`)** — A table marking byte ranges inside `__TEXT` that are *data*, not instructions. Must be honored to avoid garbage from linear sweeping.
- **Condition flags (NZCV)** — The ARM64 condition flags (Negative, Zero, Carry, oVerflow). `cmp`/adds set them; `b.eq`/`csel` read them. Lowering them to explicit IR values is a key correctness concern (see [ir-and-ssa.md](arch/ir-and-ssa.md)).

## Control flow

- **Basic block** — A maximal straight-line sequence of instructions with one entry and one exit (no branches in, no branches out except at the end).
- **Control Flow Graph (CFG)** — A graph of basic blocks connected by edges (fallthrough, conditional, return, call, indirect). See [control-flow.md](arch/control-flow.md).
- **Function boundary detection** — Determining where functions start/end. Sources, in priority order: symbol table, call (`bl`) targets, prologue heuristics, `__eh_frame`/compact-unwind data for stripped binaries.
- **Dominance / dominance frontier** — Block A *dominates* B if every path to B goes through A. The *dominance frontier* is where phi nodes must be inserted during SSA construction.
- **Natural loop / back-edge** — A back-edge points to an earlier (dominating) block; back-edges define natural loops. Loop detection underpins while/for recovery.

## IR & SSA

- **IR (Intermediate Representation)** — A language-agnostic in-memory program form between assembly and target source. See [ir-and-ssa.md](arch/ir-and-ssa.md) and [ADR-003](adrs/ADR-003-ssa-based-ir.md).
- **SSA (Static Single Assignment)** — A form where every variable is assigned exactly once; merge points use **phi nodes** to select values. Makes dataflow analysis tractable.
- **Phi node** — "Choose this value depending on which predecessor block we came from." Lives at dominance frontiers.
- **Memory SSA** — Extending SSA semantics to memory (loads/stores). We start with a **coarse** memory model and defer full memory-SSA.
- **Type recovery** — Inferring high-level types (int, pointer, struct) from instruction evidence (load/store widths, access patterns, value ranges). Constraint-based.

## The LLM semantic-lift stage

- **Semantic lift** — The differentiating stage: pass the SSA IR through an LLM to recover **names, types, idioms, and comments** — the *intent* traditional decompilers miss. See [llm-semantic-lift.md](arch/llm-semantic-lift.md) and [ADR-004](adrs/ADR-004-llm-output-is-advisory.md).
- **Semantic hint** — One unit of LLM output (a renamed variable, a guessed type, an idiom match, a comment). Every hint carries **provenance** (LLM vs heuristic vs symbol-table) and **confidence**.
- **Advisory vs verified** — IR facts recovered by deterministic analysis are *verified*; LLM hints are *advisory*. The **verified-over-advisory** rule: verified wins on conflict; hints are only adopted where they don't contradict verified facts.
- **Idiom library** — A catalog of recognizable code patterns (memset, memcpy, strcmp, sha256, AES rounds, CRC32, etc.) matched by cheap heuristics to avoid an LLM call for obvious cases.
- **Prompt injection (from untrusted binaries)** — Risk that bytes/strings inside a hostile binary trick the LLM. Mitigated by treating binary content as delimited **data**, never instructions; hints are never executed.

## Codegen

- **Codegen backend** — Lowers the (annotated) SSA IR to a target language (Python, Rust, Go). See [codegen.md](arch/codegen.md) and [target-languages.md](specs/target-languages.md).
- **Target AST / pretty-printer** — Codegen builds a language-specific syntax tree then renders it to source text with formatting.

## Tooling / process

- **Golden test** — Source → compile → decompile → compare against a stored expectation. See [testing-strategy.md](specs/testing-strategy.md).
- **Differential test** — Compare our output (CFG, IR) against a reference decompiler (Ghidra) on the same binary to catch regressions.
- **End-to-end slice** — A thinnest-possible pipeline that runs bytes→source through *every* stage, even with trivial quality. Phase 0's goal (see [ADR-005](adrs/ADR-005-end-to-end-slice-first.md)).
- **Demangling** — Recovering the human-readable form of a mangled symbol (Swift `_$s…`, Itanium/C++ `_ZN…`). Done via `libswift-demangle`/libc++ demangle (P/Invoke).
