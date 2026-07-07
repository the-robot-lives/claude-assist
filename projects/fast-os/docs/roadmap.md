# fast-os Roadmap

Status: draft v0.1 · 2026-07-07. Phases gate on exit criteria, not dates. Solo/small-team pacing assumed; each phase is roughly a quarter of focused work.

## Phase 0 — Toolchain & boot (foundation)

Rust `no_std` workspace, cross-compilation for x86_64 + aarch64, UEFI bootloader (or Limine), QEMU dev loop, GDB stub, CI that boots every commit.

**Exit:** `make run` boots to a kernel log line on QEMU x86_64 and aarch64 in CI; boot time measured and recorded per commit, firmware vs. OS time split out.

## Phase 1 — Frame (the unsafe core)

Paging, interrupts/exceptions, timers, per-core init, context switch, physical/virtual allocators, DMA windows. Safe-API boundary established; `unsafe` confined to `frame/` and enforced by CI lint.

**Exit:** preemptive multitasking of kernel threads on both arches; frame safe-API documented; unsafe-LOC ratio reported in CI (<15% target).

## Phase 2 — Kernel services & rings

Capability tables, SQ/CQ ring syscall layer, thread-per-core scheduler (latency + throughput classes), IPC, initial fastfs (read-write, no snapshots yet), virtio drivers (blk, net, console), first userland process + Rust std port skeleton.

**Exit:** userland process does ring-based file and network I/O; syscall microbenchmarks vs Linux io_uring published in-repo; ring fuzz harness in CI; warm-reboot (kexec-style) path working.

## Phase 3 — Userland & Tool Bus

toolbusd + schema registry, `fsh` (command mode only), typed config store, service manager, structured logging, NVMe + real NIC drivers for bare-metal P1 hardware, POSIX shim (enough for a static busybox-class port).

**Exit:** self-hosted interactive shell session on bare metal x86_64; every system service introspectable via Tool Bus; boot <500 ms on reference NVMe box.

## Phase 4 — Inference online

inferd with CPU backend (quantized GGML-class kernels), model residency manager, `reflex` request class with an always-resident small model, ring API for inference, GPU (Vulkan) backend stretch.

**Exit:** any userland program can stream tokens from a local model via rings; two clients share one resident model; decode latency SLO held under CPU load (scheduler deadline hints working).

## Phase 5 — Agent-native surface

agentd (agent tasks, budgets, delegation), context handles + memoryd v1, flight recorder + `fast replay`, fsh intent mode (reflex classification → plan preview → staged effects), capability approval UI.

**Exit:** demo scenario — "find the biggest logs, compress ones older than a week, and schedule that weekly" executed as an agent task with plan preview, scoped caps, full replayable journal.

## Phase 6 — Flagship targets & polish

ARM64 SoC bring-up with NPU backend for inferd, fastfs snapshots + CoW journal integration, escalation ladder (local↔remote model policy), system copilot service, energy budgets, first external-developer SDK release.

**Exit:** fast-os on one ARM64 NPU device runs the Phase-5 demo with reflex inference on-NPU; <350 ms boot on x86_64 reference hardware.

## Distribution milestones

Installable VM live disk (D1) and self-hosting (D2) are specified in [roadmap-distribution.md](roadmap-distribution.md); D1.a slots after Phase 3, D1.b after Phase 4, self-hosting ladder runs Phase 3→post-6.

## Later / explicitly deferred

Display server + UI toolkit (with auto tool-export), multi-user, QUIC-native network stack maturity, POSIX personality completeness, secure model attestation, package ecosystem.

## Standing workstreams (every phase)

- **perf/**: benchmarks in CI; regressions fail merge (boot time, syscall latency, ctx-switch, tokens/sec).
- **safety/**: unsafe-code audit, capability model review at each phase gate.
- **docs/**: ADR per irreversible decision; architecture docs updated in the same PR as the change.

## Risks

| Risk | Mitigation |
|---|---|
| Scope: "an OS" is unbounded | Framekernel + no legacy compat; phases gate hard; deferred list is a contract |
| NPU vendor stacks are closed/churning | CPU backend is the correctness baseline; NPU is an accelerator, never a dependency |
| Solo bus-factor | Subtree in Noizu monorepo, ADRs capture rationale, CI reproduces everything |
| Driver long tail | virtio-first strategy; bare metal limited to 1–2 reference boxes until Phase 6 |
