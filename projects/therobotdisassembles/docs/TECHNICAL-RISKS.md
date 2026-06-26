# TECHNICAL-RISKS.md — Risks, Mitigations, Open Questions

> The load-bearing risks and what the design does about each. Every mitigation names a phase or ADR. Open questions are explicitly called out so they get answered before they bite.

---

## Risk register

| # | Risk | Likelihood / Impact | Mitigation | Where |
|---|------|---------------------|------------|-------|
| R1 | **Capstone binding staleness / API drift.** Published .NET Capstone bindings (`Capstone.Net`) are abandoned and version-locked; arm64 coverage lags. | High / High | Ship an **own minimal P/Invoke wrapper** over a **pinned native `libcapstone`** dylib; provide a **vendored local build fallback** so CI isn't dependent on a Homebrew version. | [ADR-002](adrs/ADR-002-capstone-via-pinvoke.md); wrapper built in Phase 0, exercised Phase 1+ |
| R2 | **LLM hallucination in codegen** — invented names/types that look right but are wrong, or invented APIs. | High / High | LLM output is **advisory only**; a **validation pass** rejects hints violating typing/CFG invariants; **verified-over-advisory** at codegen; hints never executed. | [ADR-004](adrs/ADR-004-llm-output-is-advisory.md); Phase 3 |
| R3 | **Prompt injection from untrusted binaries** — bytes/strings in a hostile binary manipulate the LLM. | Medium / High | Binary content enters prompts as **delimited, escaped data**; model is told input is adversarial; output is **hints, never code that runs**; provenance tags let codegen ignore anything suspicious. | [ADR-004](adrs/ADR-004-llm-output-is-advisory.md), [llm-semantic-lift.md](arch/llm-semantic-lift.md) §injection; Phase 3 |
| R4 | **Condition-flag (NZCV) garbage.** Implicit flags are the classic source of decompiler nonsense (`cmp`→`b.eq`/`csel` chains). | High / High | Lower NZCV to **explicit IR values** so dataflow is honest; covered as a first-class Phase-2 deliverable and a named test class. | [ADR-003](adrs/ADR-003-ssa-based-ir.md); Phase 2 |
| R5 | **Type-recovery fidelity** — wrong/missing types cascade into unreadable output. | High / Medium | Start **constraint-based** (size/width + access patterns) in Phase 2; deepen in Phase 5. Defer full memory-SSA until proven needed. | [ir-and-ssa.md](arch/ir-and-ssa.md); Phases 2 & 5 |
| R6 | **Linear-sweep garbage on stripped binaries** — decoding data as instructions. | Medium / High | Prefer **branch-driven (recursive) decode**; honor `LC_DATA_IN_CODE`; symbol/eh_frame-driven function detection. | [disassembly.md](arch/disassembly.md), [control-flow.md](arch/control-flow.md); Phases 1–2 |
| R7 | **Fat/Universal & arm64e/PAC** — universal containers, pointer auth, BTI complicate parsing/decompilation. | Medium / Medium | Fat-slice selection Phase 1; **arm64e/PAC is display-only** (annotate, don't deobfuscate), deferred to Phase 5. Phases 0–4 ship arm64 only. | [binary-formats.md](specs/binary-formats.md); Phase 5 |
| R8 | **Swift / Obj-C / C++ mangling** — unreadable symbol names; Swift mangling is complex. | Medium / Medium | Reuse `libswift-demangle` + libc++ demangle via P/Invoke (don't reimplement); document coverage gaps. | [binary-loading.md](arch/binary-loading.md); Phase 1 |
| R9 | **Indirect-call resolution** — `bl` to `__stubs`/`__got` hides the real callee. | Medium / Medium | Resolve via chained fixups (`LC_DYLD_CHAINED_FIXUPS`) / classic `LC_DYLD_INFO_ONLY` to imported symbols. | [control-flow.md](arch/control-flow.md); Phase 1 |
| R10 | **LLM cost & nondeterminism** — per-binary cost unbounded; output varies run-to-run. | Medium / Medium | **Content-addressed caching** (hash: chunk + model + prompt-version) → reproducible + cheap reruns; **idiom library** short-circuits obvious cases without an LLM call. | [llm-semantic-lift.md](arch/llm-semantic-lift.md); Phase 3 |
| R11 | **Test corpus / ground truth** — hard to assert decompiler correctness without known source. | Medium / Medium | **Golden** (source→compile→decompile→diff) + **differential** (vs Ghidra CFG) + **property** tests (parser/CFG/SSA invariants). | [testing-strategy.md](specs/testing-strategy.md); corpus built Phase 0+, grown each phase |
| R12 | **Native dylib distribution** — users lacking `libcapstone` / Swift demangle libs. | Medium / Low | `make doctor` checks prerequisites; document install (`brew install capstone`); long-term vendor the dylibs. | [layout/solution-layout.md](layout/solution-layout.md); Phase 0/4 |

## Open questions (decide before they block)

- **OQ-1** Capstone dylib version + exact pinning strategy (Homebrew path vs vendored build) — resolve at Phase 0 wrap-up.
- **OQ-2** Confidence threshold for adopting LLM hints in codegen (the "≥ X%" in Phase 3 DoD) — calibrate empirically on the golden corpus during Phase 3.
- **OQ-3** Full memory-SSA: do we need it, or does the coarse model suffice for readable output? Revisit after Phase 2 differential results.
- **OQ-4** Which LLM provider/model(s) to support beyond Claude (the README says Claude/Azure-hosted) — keep the client behind an interface so this stays a config choice.
- **OQ-5** Swift-mangling coverage ceiling — how much Swift-specific recovery (optional chaining, generics) is in scope for v1.0 vs later.
