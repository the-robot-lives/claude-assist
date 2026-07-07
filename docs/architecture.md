# fast-os Architecture

Status: draft v0.1 · 2026-07-07

fast-os is a from-scratch, Rust-based operating system with two non-negotiable design axes:

1. **Speed** — lowest achievable latency and highest throughput on modern hardware, with no legacy compatibility tax.
2. **Agent-native** — LLM agents are a first-class OS actor alongside users and processes, with kernel-level primitives for inference, semantic memory, intent, and scoped authority.

Everything below is derived from those two axes. When they conflict, speed wins in the kernel; agent affordances live in tier-0 userspace services.

---

## 1. Kernel model: framekernel

Classic microkernels pay an IPC tax on every service interaction; monolithic kernels pay in safety and modularity. fast-os adopts a **framekernel** design (validated by Asterinas): the whole kernel runs in a single address space at supervisor privilege for monolithic-class performance, but Rust's ownership and module system partition it into:

- **frame/** — the small privileged core containing all `unsafe` code: paging, interrupts, context switch, DMA windows, atomics over MMIO. Target: <15% of kernel LOC, the only code that can violate memory safety.
- **services/** (in-kernel) — scheduler, VFS, network stack, IPC, capability tables. 100% safe Rust compiled against the frame's safe API. A bug here panics a subsystem, not memory safety.

No stable in-kernel ABI. Kernel services are compiled together; whole-program optimization (LTO, PGO) across the entire kernel is a release requirement, not an option.

## 2. Syscall interface: async rings, not traps

The dominant syscall cost on modern CPUs is the mode switch plus the speculation-barrier tax. fast-os makes the **submission/completion ring the primary syscall interface** (io_uring generalized to *all* kernel services), not a bolt-on:

- Each thread gets a per-core ring *triple* — main, latency, and polling rings (Glommio-validated layout) — so latency classes are segregated at the ring level. Filesystem, network, IPC, timers, inference requests — everything is a ring entry.
- Traps exist only for: initial ring setup, blocking waits (futex-style), and faults.
- Batch-by-default: the standard library never issues one-op syscalls; it accumulates and flushes.
- Kernel-side polling threads (per-core, adaptive) drain rings without mode switches under load; interrupt-driven wakeups under idle.
- **Bypass lane**: capability-granted direct NIC/NVMe queue access for tier-0 services — even ideal rings cost ~6× true kernel-bypass (see performance-research.md §1).
- Ring entries are untrusted input; the ring layer is fuzzed in CI.

Expected effect: syscall-heavy workloads (agents are syscall-heavy — lots of small file/tool/socket ops) run at near-function-call cost.

## 3. Scheduling: thread-per-core, shared-nothing

- **Cores are partitioned, not shared.** Default execution model is thread-per-core with work-stealing only as an explicit opt-in. No global run-queue lock.
- **Pluggable policy over fixed mechanism** (sched_ext lesson): scheduling policies are safe-Rust modules; the kernel ships mechanism (queues, preemption, accounting) plus two default policies.
- **Two shipped scheduling classes:**
  - *Latency class* — interactive/UI/agent-response paths; EEVDF-style virtual deadlines.
  - *Throughput class* — batch, compilation, background inference; long quanta, cache-affine.
- **Inference-aware:** the scheduler knows about accelerator queues (NPU/GPU). Token-generation streams register a deadline hint so decode loops don't get preempted mid-token-batch.
- Big.LITTLE / P-E core aware from day one (required for Apple-class ARM64 targets).

## 4. Memory

- Address spaces exist for userland isolation, but **zero-copy is the default contract**: ring buffers, page-remap grants, and copy-on-write handoff replace read/write copies wherever both sides opt in.
- Huge pages by default for kernel, code, and model weights; userland promotion is profile-driven (TLB-miss counters), not blanket THP-style. Per-core page-table replicas on NUMA/multi-die; TLB shootdown avoidance via per-core address-space epochs.
- **Semantic memory tier** (agent-facing, see agent-integration.md): KV caches, embeddings, and model weights are kernel-tracked resource types with their own reclamation policy — weights are shared read-only mappings across all consumers; KV cache pages are evictable with recompute cost accounting.

## 5. Storage & filesystem

- Log-structured, checksummed native FS (`fastfs`) designed for NVMe queue depth, not spinning-rust seek order. CoW snapshots power the agent audit/replay journal.
- All system state is **structured and queryable** (typed key-space, watchable), not text files. `/etc`-style config is a typed store with schema; agents and humans read the same API. A FUSE-style compat view can render it as files.

## 6. Drivers & the Tool Bus

Every driver and system service exposes a **self-describing, typed interface** (capability-scoped, versioned, introspectable) on the system **Tool Bus**. One interface definition serves three consumers:

1. Kernel/userland programs (generated Rust/C bindings)
2. CLI/GUI (auto-generated surfaces)
3. **Agents** — the same interface is exported as tool schemas (MCP-compatible), so "the OS is the tool server" is literal.

Drivers run in-kernel (framekernel services) when performance-critical (NVMe, NIC, GPU/NPU submission) and in userspace when not (USB peripherals, sensors).

## 7. Security: capabilities everywhere

- No ambient authority. Every resource handle is an unforgeable capability; process = code + capability set.
- Capabilities are **attenuable** (derive weaker from stronger), **revocable** (kill a delegation subtree in O(1)), and **auditable** (every grant is journaled).
- This is the substrate that makes autonomous agents safe to run: an agent task gets a capability bundle scoped to exactly its task, time-boxed, revoked on completion. See agent-integration.md §4.

## 8. Boot & footprint

- Target: **<350 ms power-on to interactive shell** on NVMe x86_64; <150 ms resume. Measured in CI from day one; boot-time regression fails the build. Firmware vs. OS time reported separately (firmware is the uncontrollable cost).
- Warm-reboot path (kexec-style, skips firmware) from Phase 2 — doubles as the fast kernel-update dev loop. Service bring-up is a parallel dependency graph; first-interactive precedes non-critical drivers.
- Static-linked, single-binary system services; no dynamic linker on the hot path.
- Minimal base image <64 MiB (excluding model weights).

## 9. Userland

- `fsh` — hybrid shell: every command line is either a program invocation or an intent phrase; both compile to Tool Bus calls (see agent-integration.md §6).
- SDK: Rust-first, C ABI for ports. POSIX is a *compat personality*, not the native API — planned as a userspace shim layer in Phase 3, so existing software ports without contaminating native interfaces.

## 10. Hardware targets

| Priority | Target | Role |
|---|---|---|
| P0 | QEMU/KVM virt (x86_64, aarch64) | dev loop, CI |
| P1 | x86_64 bare metal (NVMe, e1000e/virtio) | homelab/server |
| P1 | ARM64 SoCs w/ NPU (Apple-class, Snapdragon X) | flagship agent device |
| P2 | Rockchip/Jetson-class edge | later |

## 11. What we deliberately do NOT build (initially)

Legacy BIOS boot (UEFI only), 32-bit anything, X11, in-kernel POSIX, swap-to-disk for general memory (only KV-cache spill), and networking protocols older than needed for TLS 1.3 + QUIC + SSH.

---

## System diagram

```
┌────────────────────────────────────────────────────────────┐
│ userland   apps · fsh shell · agent tasks · POSIX shim     │
├────────────────────────────────────────────────────────────┤
│ tier-0 services (userspace, privileged caps)               │
│   inferd (model exec) · agentd (agent lifecycle)           │
│   toolbusd (schema registry) · memoryd (semantic memory)   │
├──────────────── async SQ/CQ rings (primary syscall) ───────┤
│ kernel services (safe Rust): sched · vfs/fastfs · net      │
│   ipc · capability tables · tool bus transport             │
├────────────────────────────────────────────────────────────┤
│ frame (unsafe core): paging · irq · ctx switch · DMA       │
└────────────────────────────────────────────────────────────┘
        x86_64 / ARM64 · NPU/GPU submission queues
```
