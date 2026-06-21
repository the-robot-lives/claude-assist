# Reverse Engineering: Source & Binaries → Model

> This spec defines how The Robot Draft's **ingestion subsystem** turns raw inputs — source
> trees, compiled bytecode/IL, and stripped native binaries — into facts in the **Unified
> Model**. It is written for engineers implementing ingestion: the per-language frontends, the
> decompiler bridges, the dynamic tracers, and the normalization layer that feeds them all into
> one code-graph. Read [`../ARCHITECTURE.md`](../ARCHITECTURE.md) first for where ingestion sits
> in the pipeline; this document is the depth behind §1 (Ingestion) and §2 (Unified Model).

"Reverse compile" — decompilation of source-less artifacts — is a **first-class feature**, not a
fallback. A user can fly into a third-party DLL, a JAR, or a stripped `.so` and explore it as
bubbles and diagrams exactly as they would explore their own source. This spec treats binary
ingestion with the same rigor as source ingestion.

---

## 1. The static/dynamic hard boundary

Everything in this subsystem is governed by one law, and most implementation decisions fall out
of it:

> **Structure is reliably recoverable statically. Behavior over time is not.**

The shape of a system — its classes, types, fields, inheritance, module dependencies — is encoded
directly in source and (in resolved form) in bytecode/IL. A static analyzer can recover it
soundly. **Behavior over time** — the actual ordered sequence of messages between live objects —
depends on *dynamic dispatch* (which override runs depends on the runtime type) and on *data
values* (which branch is taken depends on inputs). Neither is knowable without either running the
program or performing expensive symbolic analysis.

This boundary partitions the four extraction targets:

| Extraction target | What it captures | Technique | Profile |
|-------------------|------------------|-----------|---------|
| **Class / type diagram** | types, fields, methods, inheritance, associations | AST + symbol resolution | **STATIC** |
| **Package / dependency graph** | modules, namespaces, jars, assemblies | symbol refs, import graph, bytecode/IL refs | **STATIC** |
| **Call graph** | caller → callee edges | interprocedural static **or** instrumentation dynamic | **BOTH** |
| **Sequence diagram** | ordered, time-indexed messages with object lifelines | runtime tracing (usual) **or** expensive symbolic analysis | **MOSTLY DYNAMIC** |

The call graph straddles the boundary: a static call graph over-approximates (lists every
*possible* callee at a virtual call site); a dynamic call graph records only edges actually taken.
The sequence diagram falls on the far side — a trace *is* a sequence, so the dynamic path is
natural and the static path is a research-grade symbolic-analysis problem.

**Implementation consequence.** Class and dependency extraction are required, always-on, and feed
the model directly. Call-graph extraction has a static default with an optional dynamic refinement
pass. Sequence extraction is **opt-in and trace-driven** (see §5) — the ingestion subsystem never
promises a sequence diagram from static analysis alone.

---

## 2. The unified internal model

All three ingestion paths — source, binary, and dynamic trace — normalize into **one in-memory
code-graph**. Downstream subsystems (layout, projection, interchange) never branch on input type;
they read this graph. Its conceptual shape follows the OMG **KDM** Code/Structure/Data layers
(see §6 for why), populated by mature tooling rather than by a KDM-conformant extractor.

### 2.1 Graph contents

| Element class | Members | Source of truth |
|---------------|---------|-----------------|
| **Entities** | packages, namespaces, modules, assemblies, types, methods, fields, variables, parameters | every path |
| **References** | symbol uses, imports, inheritance/implementation links | symbol resolution / IL refs / xrefs |
| **Call edges** | caller → callee, with virtual/dynamic-dispatch candidate sets | static call graph or trace |
| **Type edges** | declared type, generic instantiation, parameter & return types, supertype/subtype | type binding / metadata / RTTI |
| **CFG** | per-method control-flow graphs | compiler frontend / IR lifting |

Call edges carry a **provenance** flag: `static-resolved`, `static-candidate` (one of several
possible virtual targets), or `dynamic-observed`. Layout and projection use provenance to render
certainty (e.g., a solid vs. dashed call edge). Never collapse the three into one undistinguished
"call" — the distinction is the static/dynamic boundary made visible.

### 2.2 Why one model

The model is the **hub every ingestion path normalizes into**, and it is the same graph that holds
imported diagrams (XMI, Rose, BPMN — see [`../ARCHITECTURE.md`](../ARCHITECTURE.md) §2). A class
recovered from Roslyn, a class lifted from a stripped binary's vtable, and a class imported from
XMI occupy identical node types and are indistinguishable to layout and projection. This is what
makes cross-source comparison and round-trip possible.

Three invariants the ingestion layer must uphold:

1. **Same fact shape from every path.** A frontend, a decompiler, and a tracer that all describe
   "method `foo` calls method `bar`" must emit the same edge with the same node identities.
2. **Stable identity under re-ingestion.** Re-analyzing a changed file produces a *diff* against
   the existing graph, not a rebuild, so camera position and open views survive edits.
3. **Lossy facts are flagged, never silently upgraded.** A decompiler's invented name
   (`sub_401000`) or a JVM-erased generic must carry a confidence/synthetic marker into the model.

---

## 3. Source ingestion

Source ingestion has two tiers: **compiler-grade** frontends for fidelity, and a
**tree-sitter + SCIP** fast/broad path for polyglot breadth and broken code. Both emit the same
facts; the difference is accuracy and resolution depth.

### 3.1 AST alone is insufficient

A syntax tree is not enough. Extracting a faithful class diagram requires **name resolution and
type binding**: resolving imports, instantiating generics, and performing overload resolution to
know *which* `add()` a call site targets. AST parsing gives you the shape of the code; semantic
analysis gives you what the shapes *mean*. Every source frontend in this subsystem must pair a
parser with a resolver.

### 3.2 Compiler frontends as backends (highest fidelity)

For languages with mature compilers, drive the **real compiler's semantic model** rather than
re-implementing parsing and binding. This yields resolved symbols, full overload resolution, and
complete type information — facts, not guesses.

| Language | Frontend | API surface used | Yields |
|----------|----------|------------------|--------|
| C# / .NET | **Roslyn** | `SemanticModel`, `ISymbol` | resolved symbols, types, call sites, hierarchy |
| C / C++ / Obj-C | **Clang** (LibTooling / libclang / clangd) | AST matchers, cursor API | AST + bindings, template instantiations |
| Java | **Eclipse JDT** | DOM AST + bindings; javac annotation processors | resolved types, hierarchy, references |
| TS / JS | **TypeScript Compiler API** | `Program`, `TypeChecker` | resolved types, structural typing, call sites |
| Go | **`go/ast`, `go/types`, `x/tools/go/callgraph`** | type checker + CHA/RTA/VTA | types, packages, static call graph |

Go is notable for shipping production-grade static **call-graph** algorithms (CHA — Class
Hierarchy Analysis; RTA — Rapid Type Analysis; VTA — Variable Type Analysis) in the standard
toolchain. Use them for the static call-edge pass; they over-approximate virtual dispatch in the
documented, sound way.

### 3.3 LSP as the language-agnostic fallback

Where a dedicated frontend adapter does not yet exist, drive an **LSP server**. LSP provides
semantic data through a uniform protocol; the requests map directly onto model elements:

| LSP request | Model contribution |
|-------------|--------------------|
| `documentSymbol` / `workspace/symbol` | entity inventory (types, methods, fields) |
| `definition` / `references` / `implementation` | reference graph edges |
| `callHierarchy` → `incomingCalls` / `outgoingCalls` | **call edges** |
| `typeHierarchy` → `supertypes` / `subtypes` | **inheritance (type) edges** |
| `semanticTokens` | token-level kind/modifier classification |

LSP is **stateful and round-trip-heavy** — every reference query is a request. Do not query LSP
live during layout; drive it once at ingest time and **persist the result to an index**, then read
the index.

### 3.4 The tree-sitter + SCIP recommended pipeline

For breadth across many languages and graceful degradation on partial or uncompilable code, use:

- **tree-sitter** — a GLR, **incremental, error-tolerant** parser. It produces syntax, *not*
  cross-file semantics. Its **S-expression query language** makes extraction data-driven: encode
  "what is a class declaration" as a query per grammar rather than as bespoke traversal code.
- **stack-graphs** (GitHub) or **SCIP / LSP** for the name resolution tree-sitter lacks.

The recommended default pipeline pairs the two:

```
tree-sitter (structural skeleton, error-tolerant)
        +
SCIP index  (resolved references, types, hierarchies)   ── or live LSP ──
        ↓
normalize into KDM-shaped Code / Structure / Data nodes
        ↓
Unified Model
```

**SCIP** (Sourcegraph) is preferred over LSIF as the persisted index format: it is protobuf-based,
uses **symbol-string identity** as the primary key (rather than file ranges), and carries a
`SymbolRole` bitmask (`Definition`, `Reference`, `Read`, `Write`, `Import`) that maps cleanly onto
model reference/type edges. It is easier to emit and consume than LSIF's verbose line-graph. See
§6 for the full index-format comparison.

**Fidelity note.** This path is lower-fidelity than a compiler frontend (resolution can be partial)
but resolves quickly and survives broken builds. Prefer a frontend when one exists; fall back to
tree-sitter + SCIP for the long tail and for files that do not compile.

---

## 4. Binary ingestion / reverse compile

When there is no source, the ingestion subsystem lifts compiled artifacts back toward structure.
**Fidelity depends entirely on how much the compiler preserved**, which gives a strict spectrum:

> **.NET IL ≈ JVM bytecode  ≫  native + DWARF/PDB  >  stripped native  >  obfuscated**

Managed bytecode retains type names, signatures, and structured control flow → near-source
recovery. Native machine code discards almost everything → names are invented and control flow is
reconstructed. Plan accuracy expectations and UI confidence cues around this ranking.

### 4.1 Decompilers by ecosystem

| Ecosystem | Tools | Notes for the bridge |
|-----------|-------|----------------------|
| **JVM / Android** | **JADX** (DEX/APK→Java, deobfuscation), **CFR** (modern Java: lambdas, records, sealed), **Procyon**, **Fernflower** (IntelliJ built-in), **Vineflower** (maintained Fernflower successor), **Krakatau** (obfuscated/malformed) | bytecode keeps type names & signatures; **generics are erased** at runtime but survive in signature attributes — read them |
| **.NET** | **ILSpy** (de-facto OSS standard; `ilspycmd` for headless), **dnSpy / dnSpyEx** (debugger + IL/C# edit), **dotPeek**, **JustDecompile** | IL retains **most metadata, generics NOT erased** → richest binary recovery |
| **Native** | **Ghidra** (NSA; P-Code IR; free, headless, scriptable — dominant free option), **Hex-Rays IDA Pro** (microcode; commercial gold standard; FLIRT signatures), **Binary Ninja** (LLIL→MLIL→HLIL + SSA), **RetDec** (LLVM IR), **angr** (VEX; symbolic execution, CFG recovery), **radare2 / Cutter** (ESIL) | choose by license and IR; Ghidra is the default free backend, IDA the fidelity ceiling |

For managed bytecode/IL, decompilation is reliable enough that the recovered class diagram is
often **more reliable than parsing the original source for a library** — the resolved types are
already baked in. What is lost: local variable names without debug info, and (on the JVM) erased
generic type arguments — though generic *signatures* survive in attributes.

### 4.2 Bytecode/IL libraries (programmatic access)

For structural extraction you often want library access to metadata rather than full pseudo-source:

| Runtime | Libraries | Use |
|---------|-----------|-----|
| **JVM** | **ASM**, **BCEL**, **Soot**, **WALA** | class/method/field metadata, bytecode call graphs, dataflow |
| **.NET** | **Mono.Cecil**, **System.Reflection.Metadata** | assembly/type/method metadata, IL inspection |

### 4.3 Debug symbols — the biggest native fidelity lever

For native code, the single largest determinant of recoverable structure is whether **debug
symbols** are present:

| Format | Platforms | Carries |
|--------|-----------|---------|
| **DWARF** | ELF / Mach-O (Linux, macOS) | types, struct layouts, function signatures, line program |
| **PDB / portable PDB** | Windows / .NET | symbols, types, line mapping |

When DWARF or PDB is available, native recovery jumps from "invented names over reconstructed
control flow" toward signature- and type-accurate structure. The ingestion bridge must detect and
consume these before falling back to stripped-binary heuristics.

### 4.4 The native pipeline

Native ingestion is a staged lift. Each stage has known-hard sub-problems the implementation must
handle (or degrade gracefully on):

```
binary
  → parse container        (ELF / PE / Mach-O headers, sections, symbols)
  → disassembly            (code-vs-data separation, function boundaries)
  → IR lifting             (to P-Code / VEX / LLIL / LLVM IR)
  → control-flow recovery  (CFG construction, structuring to goto-free form)
  → data-flow              (SSA, variable promotion)
  → type recovery          (infer types from usage / RTTI / DWARF)
  → pseudo-C
```

| Hard sub-problem | Why it's hard |
|------------------|---------------|
| Function-boundary & jump-table discovery | **undecidable in general**; relies on heuristics and signatures |
| Goto-free control-flow structuring | recovering structured loops/conditionals from arbitrary jumps |
| Type recovery | machine code is untyped; types are *inferred*, not read (unless DWARF/PDB) |
| Variable recovery | reconstructing source-level variables from registers/stack slots via SSA |

### 4.5 Limitations — set expectations honestly

| Limitation | Effect on the model |
|------------|---------------------|
| **Stripped binaries** | invented names (`sub_401000`, `var_8`) → mark entities **synthetic**, never present as authoritative names |
| **Optimization** (`-O2`/`-O3`, LTO, **inlining**) | decompiled structure **diverges from source**; you cannot un-inline — callee bodies appear merged into callers |
| **C++ name mangling** | *helps* when symbols exist (the mangled name encodes parameter types) → demangle to recover signatures and class membership |
| **Obfuscation** (control-flow flattening, opaque predicates, VMProtect, Themida) | defeats decompilers; recovery may be impossible — fail loudly, do not emit confident garbage |
| **Recompilability** | decompiler output is **rarely recompilable** and semantically imperfect — it is a *reading aid*, not guaranteed-equivalent source |

### 4.6 The decompiled → model bridge

Decompiler artifacts feed the **same model-construction layer as source** (§2). The bridge maps
tool outputs onto graph elements:

| Model element | Source from decompiler |
|---------------|------------------------|
| **Call edges** | Ghidra `FunctionManager`, angr `CFGFast`, Binary Ninja xrefs |
| **Per-method CFG** | per-function CFGs from any native backend |
| **Class hierarchy** | metadata for JVM/.NET; **RTTI / vtable layout** for native C++ |
| **Candidate classes** | recovered structs promoted to candidate class entities |

The bridge marks all native-derived entities with confidence/provenance so layout can render
certainty. **Binary sequence diagrams are not produced by the bridge** — like source sequence
diagrams, they require a runtime trace (see §5): dynamic instrumentation via **eBPF / ptrace** or
DBI frameworks (**Frida, Pin, DynamoRIO**).

---

## 5. Sequence-diagram extraction (the dynamic path)

Per the §1 boundary, a sequence diagram is an **ordered, time-indexed record of messages between
live objects** — and that record is a *runtime artifact*. The ingestion subsystem extracts
sequences by **tracing a running program**: a trace literally *is* a sequence. This path is
opt-in, requires a runnable build plus representative inputs, and adds runtime overhead.

### 5.1 Tracing techniques by platform

| Platform | Techniques | Notes |
|----------|-----------|-------|
| **JVM** | `java.lang.instrument` + **ASM / ByteBuddy** bytecode weaving; **JVMTI**; **Kieker** | **Kieker is the canonical trace → UML framework** — prefer it as the JVM sequence backend |
| **Native (Linux)** | **eBPF** (uprobes / kprobes), **ptrace** | low-overhead kernel-assisted tracing |
| **Native (DBI)** | **Frida, Pin, DynamoRIO** | dynamic binary instrumentation for source-less native binaries |
| **.NET** | **CLR Profiling API**, **EventPipe**, **ETW** | managed-runtime instrumentation |
| **Any** | sampling profilers | **aggregate, not exact** — good for hot-path summaries, *not* for faithful per-message sequences |

Sampling profilers deserve a warning: they approximate by statistical sampling and **do not
capture an exact message order**. Use them for aggregate call-frequency overlays, never as the
source for a literal sequence diagram.

### 5.2 Static vs. dynamic trade-off

The two approaches are complementary, and the model carries facts from both (via call-edge
provenance, §2.1):

| Dimension | **Static** | **Dynamic** |
|-----------|-----------|-------------|
| Path coverage | all paths | only executed paths |
| Virtual dispatch | over-approximates (candidate sets) | exact dispatch taken |
| Sequence diagrams | hard (symbolic analysis) | natural (a trace *is* the sequence) |
| Soundness | sound but imprecise | precise but incomplete |
| Requirements | source or binary only | runnable build + inputs + overhead |

**Rule of thumb for the implementation:** use static analysis for *structure and the
over-approximated call graph* (always available), and overlay dynamic traces to *refine call edges
to those actually taken* and to *produce sequence diagrams* (when a runnable build exists).

---

## 6. Code-as-model standards

The Unified Model's conceptual shape and the index formats feeding it draw on established
standards. This section explains what each is and why the subsystem chose the layering it did.

### 6.1 OMG metamodels (conceptual shape)

| Standard | What it is | Fit for this subsystem |
|----------|-----------|------------------------|
| **ASTM** (Abstract Syntax Tree Metamodel) | MOF-based AST interchange; part of OMG **ADM** (Architecture-Driven Modernization). GASTM (generic) + SASTM (language-specific) + MISTM (glue). MOF/XMI serialized, so ASTM→UML is a QVT/ATL transform. | Highest-fidelity, lowest-altitude. **Too heavy, verbose, and under-tooled** to be the working model. |
| **KDM** (Knowledge Discovery Metamodel) | MOF metamodel for an **entire system** (code, data, UI, build, platform); **ISO/IEC 19506**. Four layers — Infrastructure (Core/kdm/Source), Program Elements (Code/Action), Resource (Platform/UI/Event/Data), Abstractions (Structure/Conceptual/Build). Well-defined **KDM↔UML transforms**. | **Best-fit conceptual model layer** for a UML pipeline. Used as the *organizing schema*, not the import format. |

KDM's transforms map directly onto The Robot Draft's projection targets: Code→class/activity,
Structure→component, Platform→deployment, Data→ER, UI→navigation. This is why the model is shaped
like KDM's **Code / Structure / Data** layers.

### 6.2 Code-graph indexes (resolved-reference formats)

| Index | Owner | Identity model | Trade-off |
|-------|-------|----------------|-----------|
| **LSIF** | Microsoft | JSON line-graph; **range/position** identity | verbose; position-keyed |
| **SCIP** | Sourcegraph | protobuf; **symbol-string** identity primary; `SymbolRole` bitmask (def/ref/read/write/import) | **easier to emit & consume** — recommended |
| **Kythe** | Google | language-agnostic fact graph; **VName** nodes + typed edges | rich, heavyweight |
| **Glean** | Meta | schema-driven fact DB; **Angle** query language | powerful query, infra-heavy |

### 6.3 The recommended model layer

The subsystem composes mature polyglot tooling into OMG conceptual rigor:

> **tree-sitter** (structural skeleton) **+ SCIP or live LSP** (resolved references, types,
> hierarchies) → normalized into an internal graph shaped like **KDM's Code / Structure / Data**
> layers → transformed to **UML** by the projection subsystem.

This gets KDM's conceptual rigor and clean UML transforms without ASTM's verbosity or the cost of
building a KDM-conformant extractor — while leaning on the best-tooled, most polyglot index format
(SCIP) for resolution.

---

## 7. Fidelity & limitations summary

| Input → target | Best technique | Fidelity | Key limitation |
|----------------|----------------|----------|----------------|
| Source → class/type diagram | compiler frontend (Roslyn/Clang/JDT/TS/`go/types`) | **highest** | needs name resolution, not just AST |
| Source → dependency graph | import graph + symbol refs | **high** | dynamic imports/reflection invisible to static |
| Source → call graph | LSP `callHierarchy` / `go/callgraph` | **high (over-approx.)** | over-approximates virtual dispatch |
| Source → sequence diagram | runtime trace (Kieker etc.) | dynamic-only | needs runnable build + inputs |
| Polyglot / broken source → structure | tree-sitter + SCIP | **medium** | partial resolution; lower than frontend |
| JVM/.NET binary → class diagram | ILSpy / CFR / metadata libs | **high** (≈ source) | JVM generic erasure (signatures survive); lost local names |
| Native + DWARF/PDB → structure | Ghidra/IDA + debug symbols | **medium-high** | depends on symbol completeness |
| Stripped native → structure | Ghidra/IDA heuristics | **low** | invented names; undecidable boundaries |
| Optimized native → source-faithful | any decompiler | **low** | inlining/LTO diverge; cannot un-inline |
| Obfuscated → anything | — | **very low / none** | VMProtect/Themida/flattening defeat tools |
| Binary → sequence diagram | DBI/eBPF trace (Frida/Pin/ptrace) | dynamic-only | needs runnable binary + inputs |

**Two rules the implementation must never break:**

1. **Provenance travels with every fact.** `static-resolved`, `static-candidate`,
   `dynamic-observed`, and `synthetic` (invented names) are distinct in the model. The UI renders
   certainty from them.
2. **Lossy is flagged, never disguised.** A `sub_401000` is never presented as an authoritative
   name; an over-approximated virtual call is never drawn as a certain edge.

---

## Related documents

- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — pipeline overview; §1 Ingestion and §2 Unified Model
- [`diagram-catalog.md`](diagram-catalog.md) — model-element → diagram-notation mappings (projection targets)
- [`file-formats.md`](file-formats.md) — import/export formats and round-trip fidelity
- [`../adrs/`](../adrs/) — decision records (KDM-as-schema, decompiler stack, model-as-source-of-truth)
