# ADR-0005: Inference as a tier-0 userspace service (inferd)

Date: 2026-07-07 · Status: accepted

## Context
Options for where model execution lives: (a) in-kernel, (b) per-application libraries (status quo elsewhere — N× weight duplication, no global scheduling), (c) a single privileged userspace service.

## Decision
(c): `inferd` owns accelerators and model residency, exposed via the same ring interface as kernel services. The kernel contributes what only it can: scheduler deadline hints for decode streams and the semantic-memory tier (shared weight mappings, KV-page eviction with recompute-cost accounting).

## Consequences
- Weights loaded once, shared by all consumers; centralized hot/cold model policy.
- Backend churn (NPU vendor stacks) is isolated to inferd providers — kernel unaffected. CPU backend is the permanent correctness baseline.
- Crash isolation: inferd restart drops in-flight inference, never the system.
- The `reflex` class (always-resident small model, <50 ms) becomes an OS guarantee that fsh intent-parsing and UI assist can build on.

## Alternatives rejected
In-kernel inference (massive TCB growth, vendor blobs in supervisor mode — unacceptable); per-app libraries (defeats shared residency and global scheduling, the core reasons an agent-native OS wins).
