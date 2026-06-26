# arch/ingestion.md — Ingestion & Reverse Engineering

Ingestion turns raw inputs into facts. It does **not** decide layout or notation — its only job is
to extract accurate, language-aware structure and hand it to the [Unified Model](unified-model.md).
There are three paths, chosen by input type; each emits the **same fact shape**, so downstream
subsystems never branch on input type.

## Source path (compiler-grade)

For languages with mature frontends, the tool drives the real compiler's semantic model rather than
re-implementing parsing — giving resolved symbols, overload resolution, and full type information.
Adapters target Roslyn (C#/.NET), Clang (C/C++/Obj-C), Eclipse JDT (Java), the TypeScript checker
(TS/JS), `go/types` (Go), and LSP servers generally where no frontend adapter exists yet.

## Source path (fast/broad)

For breadth across many languages and files that don't compile cleanly, the tool uses **tree-sitter**
for syntax and **SCIP** (SCIP/LSIF-style indexes) for cross-file references. Lower fidelity than a
compiler frontend, but resolves quickly and degrades gracefully on partial or broken code.

## Binary path (decompilers)

For artifacts with no source — a third-party DLL, a JAR, a stripped native binary — the tool lifts
bytecode, IL, and machine code back toward readable structure using **ILSpy** (IL), **CFR** and
**JADX** (JVM/Android), and **Ghidra** (native). This is the *reverse-compile* capability: explore a
dependency you were never given source for.

## As built

The current Unity code implements only the source path, in two strategies that produce the same
`ParsedModel`: a deterministic, network-free **structural parser** (`CodeGen/CodeStructParser.cs` —
C# strong via brace-matching + doc-comment scan; TS/Java a lighter regex pass) tried first, falling
back to an **LLM JSON parser** (`CodeGen/CodeParser.cs`) that asks an OpenAI-compatible model to
emit a `JsonUtility`-shaped description of the pasted source. The binary/decompiler path is not built.

→ Further reading: [../specs/reverse-engineering.md](../specs/reverse-engineering.md) (fidelity tiers, per-tool detail), [../ARCHITECTURE.md §1](../ARCHITECTURE.md).
