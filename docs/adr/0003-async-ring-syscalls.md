# ADR-0003: Async submission/completion rings as the primary syscall interface

Date: 2026-07-07 · Status: accepted

## Context
Mode-switch plus speculation-mitigation cost dominates small-op workloads. Agent workloads are exactly that: thousands of small file/tool/socket operations per reasoning step. Linux io_uring proves ring-based batching but remains secondary to trap syscalls.

## Decision
SQ/CQ shared-memory rings are the *primary* interface to every kernel service (I/O, IPC, timers, inference, Tool Bus). Traps only for ring setup, blocking waits, and faults. Standard library batches by default. Per-core kernel pollers drain rings adaptively (poll under load, IRQ-wake under idle).

## Consequences
- Near-function-call cost for hot-path operations; one uniform async model for all services including inference streaming.
- Userland must be async-native; the fast-os std port hides this behind familiar sync facades that batch internally.
- Security review burden: ring memory is a kernel/user shared surface — entries validated as untrusted input; capabilities checked per entry.
