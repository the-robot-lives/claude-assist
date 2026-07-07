# ADR-0002: Framekernel architecture

Date: 2026-07-07 · Status: accepted

## Context
"Fastest possible" rules out the microkernel IPC tax on every service interaction; a classic monolith gives up modularity and safety. Asterinas demonstrates a third way: single supervisor address space, with Rust ownership partitioning the kernel into a small unsafe frame and safe services (their TCB ≈14% of codebase, Linux-class performance).

## Decision
Single-address-space kernel: `frame/` holds all `unsafe` code (paging, IRQ, ctx switch, DMA); every other kernel service is 100% safe Rust against the frame's API. CI enforces the unsafe boundary and reports unsafe-LOC ratio (<15% target). Whole-kernel LTO/PGO required for release builds.

## Consequences
- Monolithic-class syscall/IPC performance with auditable safety core.
- No stable in-kernel ABI — kernel services compile together; third-party drivers must be upstreamed or run in userspace.
- A safe-service panic is recoverable per-subsystem; frame bugs remain fatal — hence kani model checking on frame/.

## Alternatives rejected
seL4-style microkernel (IPC cost, formal verification burden), Linux fork (legacy tax defeats project purpose), unikernel (single-app scope too narrow).
