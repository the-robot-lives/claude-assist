# fast-os

A from-scratch, Rust-based operating system built on two axes: **the fastest possible OS** on modern hardware, and **agent/LLM support designed in from the bottom up** — inference, semantic memory, intent, and scoped agent authority as OS primitives, not apps.

## Why

Every current agent stack (AIOS, UFO², desktop copilots) re-implements a scheduler, context manager, tool layer, and permission system *on top of* an OS that fights it. fast-os makes those the OS: agents are kernel-visible tasks with budgets and capabilities; every driver and service is a typed, discoverable tool; models are shared, scheduler-aware system resources.

## Design pillars

1. **Framekernel** — single-address-space kernel, all `unsafe` confined to a small frame; monolithic speed with language-enforced isolation.
2. **Rings, not traps** — io_uring-style async SQ/CQ rings are the *primary* syscall interface for every service, including inference.
3. **Capabilities everywhere** — no ambient authority; agent tasks get attenuable, revocable, journaled capability bundles.
4. **Inference as a system service** — `inferd` owns model residency across NPU/GPU/CPU; a `reflex`-class small model is always resident.
5. **The OS is the tool server** — all system interfaces export MCP-compatible schemas on the Tool Bus; no glue code between agents and the machine.
6. **No legacy tax** — UEFI-only, 64-bit-only, POSIX as an optional userspace personality.

Targets: x86_64 desktop/server and ARM64 NPU-equipped SoCs; QEMU/KVM for the dev loop.

## Documentation

| Doc | Contents |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Kernel design, rings, scheduler, memory, storage, security |
| [docs/agent-integration.md](docs/agent-integration.md) | Agent tasks, inferd, semantic memory, Tool Bus, fsh intent mode |
| [docs/roadmap.md](docs/roadmap.md) | Phases 0–6 with exit criteria, risks, standing workstreams |
| [docs/tech-choices.md](docs/tech-choices.md) | Technology decision matrix |
| [docs/performance-research.md](docs/performance-research.md) | Cited survey of OS-speed techniques + design implications |
| [docs/fastfs-design.md](docs/fastfs-design.md) | Native FS: snapshots, subvolumes, per-directory RAID/redundancy policy |
| [docs/posix-compatibility.md](docs/posix-compatibility.md) | Linux/POSIX personality strategy (Loupe-measured scope) |
| [docs/app-compatibility.md](docs/app-compatibility.md) | Running Linux, Windows, and macOS applications (tiered plan) |
| [docs/roadmap-distribution.md](docs/roadmap-distribution.md) | Path to installable VM live disk + self-hosting |
| [docs/graphics-display.md](docs/graphics-display.md) | GPU kernel layer, viewd compositor, input/audio, trusted overlay |
| [docs/networking.md](docs/networking.md) | Three-lane net stack, QUIC-first, capability-scoped network authority |
| [docs/adr/](docs/adr/) | Architecture decision records |

## Repository layout

```
fast-os/
├── boot/            # UEFI/Limine boot path
├── kernel/
│   ├── frame/       # privileged unsafe core (paging, IRQ, ctx switch, DMA)
│   └── services/    # safe-Rust kernel services (sched, fastfs, net, ipc, caps)
├── drivers/         # virtio first; NVMe/NIC for bare metal
├── services/        # tier-0 userspace: inferd, agentd, toolbusd, memoryd
├── userland/        # fsh shell, SDK, std port, POSIX shim
├── tools/           # xtask build/run/test orchestration
├── tests/           # QEMU snapshot + property tests
└── docs/
```

## Quickstart (macOS)

```bash
brew install qemu          # plus Rust via https://rustup.rs if needed
./run.sh                   # build + boot in QEMU (HVF on Apple Silicon); exit: Ctrl-a x
```

Boots the phase-0 proto-kernel to a banner and the `fsh0` proto-shell (`help`, `info`, `uptime`, `echo`, `panic`).

## Status

Phase 0 in progress: proto-kernel boots on QEMU aarch64 `virt` ([kernel/](kernel/README.md)). See [roadmap](docs/roadmap.md).

## Related

`projects/beam-os` explores a BEAM-from-the-ground-up OS; fast-os is the performance-first, agent-native counterpart. Convergence point: fast-os's Tool Bus could host a BEAM runtime as a tier-0 service.
