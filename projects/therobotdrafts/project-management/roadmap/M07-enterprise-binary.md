# M7 — Enterprise Interchange & Binary Ingestion

Objective: Give HoloGraph identity-preserving interchange with the enterprise modeling world and reverse-compilation of artifacts that ship without source. On the interchange side: XMI import/export with full relationship fidelity and round-trip diff, a fidelity report of dropped elements, Rational Rose petal import, EA `.qea` native-repository import, BPMN/DMN/ArchiMate interchange, full UML 2.5.1 authoring breadth, SysML block diagrams, and notation validation. On the ingestion side: JAR decompilation (CFR/JADX), native binary recovery (Ghidra headless), stripped/obfuscated symbol handling, LLM-assisted bytecode lift, and a shared structural diff engine powering both model-version and binary-version comparison plus findings export. This is the convergence milestone: it depends on both M4 (unified code-graph, ingestion adapter contract, merge) and M5 (projection families, `IxModel` IR, trd-converter wrapper). It reuses the reverse-engineered Unity specs — `docs/formats/xmi-format.md`, `docs/formats/qea-format.md`, and the `docs/diagrams/` corpus (including the `oqo.qea` EA fixture) — as the interchange contract.

## Entry criteria

- `M4 exit`: unified code-graph, ingestion adapter contract v1, adapter merge, and re-ingest diff are live.
- `M5 exit`: projection engine, `IxModel` IR, trd-converter service wrapper, and export matrix are live.
- Cross-cutting a11y constraints from M3 apply: the import wizard, fidelity report, new diagram views, and version-diff view must be keyboard-reachable and encode kind/edge-type and diff status beyond color.

## Gate tasks

- **M7-GATE-01** (BE-INT) — Freeze the XMI 2.1 dialect, deterministic id scheme, and fidelity-report schema. Export dialect XMI 2.1 with `schema.omg.org` namespaces (EA-compatible, no `<xmi:Extension>` by default), stable non-GUID `xmi:id`s so re-exports diff small, and the dropped/unresolved-element report shape (never drop an element whose type didn't resolve — keep a placeholder). `depends: M4 exit, M5 exit` `size: M` `stories: US-060, US-063, US-067`
- **M7-GATE-02** (BE-CORE) — Freeze the structural diff engine contract. One diff engine shared by model-version drift (US-014) and binary-version compare (US-058): node/edge add/remove/change deltas computed over stable identity. `depends: M4 exit` `size: M` `stories: US-014, US-058`
- **M7-GATE-03** (BE-ING) — Freeze the binary/decompiler adapter behaviour. Extend the M4 ingestion adapter contract to binary artifacts (JAR, native), emitting the same code-graph facts with provenance (`static-candidate`/`synthetic` for recovered names). `depends: M4 exit` `size: M` `stories: US-049, US-050`
- **M7-GATE-04** (BE-INT) — Freeze the notation-validation ruleset interface. Per-notation validators returning structured violations against notation standards. `depends: M5 exit` `size: S` `stories: US-069`

## Lanes & tasks

### BE-INT — interchange + 2D projection (`backend/lib/holograph/interchange/`, `.../projection/`)

- **M7-BE-INT-01** — XMI import (full relationship fidelity). Two-pass id-map resolution (forward references); reconstruct generalization, interface realization, and the split-association `memberEnd` case; handle all three type-reference encodings; never drop untyped/unresolved elements (placeholders). `depends: M7-GATE-01` `size: L` `stories: US-060`
- **M7-BE-INT-02** — XMI export + round-trip diff. Deterministic ids, stable re-export, diff of export vs re-import for fidelity. `depends: M7-BE-INT-01, M7-GATE-02` `size: L` `stories: US-063`
- **M7-BE-INT-03** — Fidelity report. Inventory of dropped, unresolved, and placeholder elements produced on import. `depends: M7-BE-INT-01, M7-GATE-01` `size: M` `stories: US-067`
- **M7-BE-INT-04** — Rose petal import. Parse legacy Rational Rose petal files (`.mdl`/`.cat`/`.ptl`) into the model, preserving legacy names. `depends: M7-GATE-01` `size: M` `stories: US-061`
- **M7-BE-INT-05** — EA `.qea` import. Read the SQLite `.qea` repository (`t_package`/`t_object`/`t_connector`/`t_attribute`/`t_operation`/`t_xref`/`t_diagram*`) read-only, keyed on `ea_guid` identity; validate against the `oqo.qea` fixture. `depends: M7-GATE-01` `size: L` `stories: US-062`
- **M7-BE-INT-06** — BPMN/DMN/ArchiMate interchange. Exchange-XML import/export via the `IxModel` first-class BPMN/DMN types (identity-preserving). `depends: M7-GATE-01` `size: L` `stories: US-066`
- **M7-BE-INT-07** — UML 2.5.1 authoring/projection breadth. Extend projection + interchange to the full 14-type UML set beyond the M5 v1 families. `depends: M5 exit` `size: L` `stories: US-064`
- **M7-BE-INT-08** — SysML block diagram projection + verify. BDD/IBD as SysML profile applications, with verification. `depends: M7-BE-INT-07` `size: M` `stories: US-065`
- **M7-BE-INT-09** — Notation validation. Validators for authored and imported diagrams against notation standards. `depends: M7-GATE-04` `size: M` `stories: US-069`
- **M7-BE-INT-10** — Findings export bundle. Export the recovered model plus reverse-engineering findings (annotations from M6) as a shareable bundle. `depends: M7-BE-INT-02` `size: M` `stories: US-059`

### BE-ING — ingestion + graph analysis (`backend/lib/holograph/ingest/`, `.../analysis/`, Oban)

- **M7-BE-ING-01** — JAR decompile ingest (CFR/JADX). Subprocess-wrap CFR/JADX; JVM bytecode → code-graph facts (class hierarchy, call edges); Oban worker. `depends: M7-GATE-03` `size: L` `stories: US-049`
- **M7-BE-ING-02** — Native binary ingest (Ghidra headless). Drive `analyzeHeadless`; recover CFG/call graph from ELF/PE/Mach-O → code-graph facts. `depends: M7-GATE-03` `size: L` `stories: US-050`
- **M7-BE-ING-03** — Stripped/obfuscated symbol handling. Synthetic names, confidence flags, and graceful degradation when symbols are missing (DWARF/PDB consumed first when present). `depends: M7-BE-ING-01, M7-BE-ING-02` `size: M` `stories: US-056`
- **M7-BE-ING-04** — Binary+source merge. Fold decompiled facts into the unified graph, reusing the M4 merge and the same-fact-shape invariant. `depends: M7-BE-ING-01, M7-BE-ING-02, M4 exit` `size: M` `stories: US-049`

### BE-AI — LLM/agents (`backend/lib/holograph/agents/`)

- **M7-BE-AI-01** — Bytecode/IR lift assist. LLM elaboration of decompiled output toward readable source; flagged non-deterministic and low-confidence, never silently upgraded. `depends: M7-BE-ING-01, M7-BE-ING-02` `size: M` `stories: US-054`

### BE-CORE — domain model + persistence (`backend/lib/holograph/graph/`, `db/changelog/`)

- **M7-BE-CORE-01** — Structural diff engine. Implement the frozen diff contract; produce model-version structural drift. `depends: M7-GATE-02` `size: L` `stories: US-014`
- **M7-BE-CORE-02** — Binary-version compare. Apply the diff engine to two decompiled model versions of a vendored binary. `depends: M7-BE-CORE-01, M7-BE-ING-01` `size: M` `stories: US-058`

### BE-API — REST surface (`backend/lib/holograph_web/{controllers,plugs}/`)

- **M7-BE-API-01** — Import endpoints + fidelity report. XMI/Rose/EA/BPMN/DMN/ArchiMate import with the fidelity report attached. `depends: M7-BE-INT-01, M7-BE-INT-04, M7-BE-INT-05, M7-BE-INT-06, M7-BE-INT-03` `size: L` `stories: US-060, US-061, US-062, US-066, US-067`
- **M7-BE-API-02** — Export endpoints. XMI round-trip export and findings export. `depends: M7-BE-INT-02, M7-BE-INT-10` `size: M` `stories: US-063, US-059`
- **M7-BE-API-03** — Binary ingest endpoints. Submit a JAR/native artifact; return a job handle. `depends: M7-BE-ING-01, M7-BE-ING-02` `size: M` `stories: US-049, US-050`
- **M7-BE-API-04** — Version-compare endpoint. Model-version and binary-version drift over the diff engine. `depends: M7-BE-CORE-01, M7-BE-CORE-02` `size: M` `stories: US-014, US-058`

### FE-SHELL — app UX, non-3D UI (`frontend/src/app/`, `.../components/`)

- **M7-FE-SHELL-01** — Import wizard. Upload XMI/Rose/EA/binary; show progress and the fidelity report. `depends: M7-BE-API-01, M7-BE-API-03` `size: L` `stories: US-060, US-061, US-062, US-067`
- **M7-FE-SHELL-02** — Full UML 2.5.1 authoring/diagram breadth UI. Author and view across the full 14-type set. `depends: M7-BE-INT-07` `size: L` `stories: US-064`
- **M7-FE-SHELL-03** — SysML block diagram view. `depends: M7-BE-INT-08` `size: M` `stories: US-065`
- **M7-FE-SHELL-04** — Notation-validation surfacing. Inline, non-color-encoded violations. `depends: M7-BE-INT-09` `size: M` `stories: US-069`
- **M7-FE-SHELL-05** — Version-diff view. Visualize structural drift (added/removed/changed) for model and binary versions. `depends: M7-BE-API-04, M7-FE-GRAPH-01` `size: M` `stories: US-014, US-058`
- **M7-FE-SHELL-06** — Findings export UI. `depends: M7-BE-API-02` `size: S` `stories: US-059`

### FE-GRAPH — graph/layout algorithms, pure TS (`frontend/src/graph/`)

- **M7-FE-GRAPH-01** — Diff visualization model. Turn a diff-engine delta into add/remove/change render sets for the version-diff view. `depends: M7-GATE-02` `size: M` `stories: US-014, US-058`

### QA — e2e + fixtures (`frontend/cypress/`, `backend/test/integration/`, `vnext/fixtures/`)

- **M7-QA-01** — XMI round-trip + fidelity tests. Export → re-import diff = 0 on a golden set; verify unresolved-element placeholders and the fidelity report. `depends: M7-BE-INT-02, M7-BE-INT-03` `size: L` `stories: US-060, US-063, US-067`
- **M7-QA-02** — EA/Rose/BPMN import fixtures. `oqo.qea` plus corpus samples for Rose and BPMN/DMN/ArchiMate. `depends: M7-BE-INT-04, M7-BE-INT-05, M7-BE-INT-06` `size: M` `stories: US-061, US-062, US-066`
- **M7-QA-03** — Decompiler fixtures. A sample JAR and a native binary → expected code-graph shape, including a stripped variant. `depends: M7-BE-ING-01, M7-BE-ING-02, M7-BE-ING-03` `size: L` `stories: US-049, US-050, US-056`
- **M7-QA-04** — Version-compare tests. Model-version and binary-version drift correctness. `depends: M7-BE-CORE-02` `size: M` `stories: US-014, US-058`

## Integration & exit criteria

- **M7-INT-01** (BE-INT + FE-SHELL) — XMI round-trip + fidelity report. Import XMI, export it, diff for fidelity, and read the dropped-element report. `stories: US-060, US-063, US-067`
- **M7-INT-02** (BE-ING + BE-AI + FE-SHELL) — Binary reverse-compilation. Decompile a JAR and a native binary into a navigable model, handle stripped symbols, and lift bytecode with LLM assist. `stories: US-049, US-050, US-054, US-056`
- **M7-INT-03** (BE-CORE + FE-GRAPH + FE-SHELL) — Version drift compare. Compare two model versions and two binary versions over the shared diff engine. `stories: US-014, US-058`
- **M7-INT-04** (BE-INT + FE-SHELL) — Enterprise import + breadth + validation. Import EA/Rose/BPMN, author across full UML 2.5.1, project/verify a SysML block diagram, and validate notation. `stories: US-061, US-062, US-064, US-065, US-066, US-069`
- **M7-INT-05** (BE-INT + BE-CORE) — Findings export. Export the recovered model plus persisted findings. `stories: US-059`

Exit criteria:

- XMI imports with full relationship fidelity (US-060), exports and round-trips with a small diff (US-063), and reports dropped elements (US-067); Rose petal (US-061), EA `.qea` (US-062), and BPMN/DMN/ArchiMate (US-066) import as first-class model elements.
- The full UML 2.5.1 set is authorable (US-064), SysML block diagrams project and verify (US-065), and diagrams validate against notation standards (US-069).
- A JAR decompiles into a navigable model (US-049), a native binary's call graph is recovered (US-050), stripped/obfuscated symbols degrade gracefully (US-056), and bytecode lifts toward readable source with LLM assist (US-054).
- The shared diff engine compares model versions (US-014) and vendored-binary versions (US-058); the recovered model and findings export (US-059).
- Every story has at least one test at the appropriate layer; round-trip fidelity, decompiler output, and version-compare are covered by fixtures; a11y constraints hold on all new UI.

Demo script: import an XMI model → export it → diff for fidelity → read the dropped-element report → import `oqo.qea` and a Rose petal → author a UML state machine and a SysML block diagram → validate notation → decompile a JAR and a native binary → lift the bytecode → compare two binary versions for drift → export findings.

## Parallelization notes

- Supports ~8 concurrent workers and is the widest milestone: BE-INT (interchange, likely a pair), BE-ING (binary, likely a pair), BE-AI, BE-CORE, BE-API, FE-SHELL (may be a pair given the breadth UI), FE-GRAPH, QA.
- Gate tasks land first and split the milestone cleanly into two independent halves that only rejoin at the diff engine: GATE-01 unblocks the interchange half, GATE-03 unblocks the binary half, GATE-02 is the shared seam (diff engine) both halves and FE-GRAPH depend on, GATE-04 unblocks notation validation.
- Lane isolation: BE-INT owns interchange/projection, BE-ING owns ingest/analysis + decompiler subprocess wrappers, BE-CORE owns the diff engine + graph persistence, and the FE lanes own their frontend subtrees. The interchange and binary halves never touch the same directories.
- Merge order: gates → interchange lane (BE-INT) and binary lane (BE-ING/BE-AI) in parallel → BE-CORE diff engine → BE-API → FE lanes → integration tasks, with INT-03 (version compare) last since it depends on both halves via the diff engine.
- Reuse: the M5 trd-converter wrapper and `IxModel` IR carry the export path; the M4 merge and adapter contract carry binary facts; the `docs/diagrams/` corpus and `oqo.qea` are the fixture source.

## Stories delivered

| ID | Priority | Persona | Title |
|----|----------|---------|-------|
| US-049 | P0 | Sven (reverse-engineer) | Decompile a JAR into a navigable bubble model |
| US-060 | P0 | Robert (legacy modeler) | Import XMI with full relationship fidelity |
| US-063 | P0 | Robert (legacy modeler) | Export to XMI and round-trip diff for fidelity |
| US-050 | P1 | Sven (reverse-engineer) | Recover a native binary's call graph |
| US-054 | P1 | Sven (reverse-engineer) | Lift bytecode toward readable source |
| US-061 | P1 | Robert (legacy modeler) | Import Rational Rose petal files |
| US-062 | P1 | Robert (legacy modeler) | Import an EA native repository |
| US-064 | P1 | Robert (legacy modeler) | Author across the full UML 2.5.1 diagram set |
| US-065 | P1 | Robert (legacy modeler) | Project and verify a SysML block diagram |
| US-067 | P1 | Robert (legacy modeler) | Get a fidelity report of dropped elements on import |
| US-014 | P2 | Dana (systems architect) | Compare two model versions to see structural drift |
| US-056 | P2 | Sven (reverse-engineer) | Handle stripped and obfuscated symbols gracefully |
| US-058 | P2 | Sven (reverse-engineer) | Compare two versions of a vendored binary |
| US-059 | P2 | Sven (reverse-engineer) | Export the recovered model and findings |
| US-066 | P2 | Robert (legacy modeler) | Interchange BPMN, DMN, and ArchiMate models |
| US-069 | P2 | Robert (legacy modeler) | Validate diagrams against notation standards |
