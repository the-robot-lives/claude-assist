# BEAM OS

An operating system that runs the Erlang BEAM VM from the ground level up.

Firmware hands control to a small purpose-built kernel (**nucleus**) whose only job
is to host the Erlang runtime system (ERTS). There is no Linux underneath, no Unix
userland, no init system, no shell — the BEAM *is* the userland, and OTP supervision
trees are the service manager. Everything above the VM (device management, network
configuration, logging, remote access, workloads) is Erlang/OTP code.

## Why

OTP already is most of an operating system: preemptive scheduling of millions of
lightweight processes, message-passing IPC, per-process isolation and fault
recovery, hot code upgrade, clustering. Running it on a general-purpose Unix
duplicates all of that one layer down and pays for it in boot time, image size,
attack surface, and latency jitter.

Collapsing the stack buys:

- **Millisecond boot** into a supervised Erlang node (Firecracker/KVM microVM class).
- **Tiny, immutable images** — one kernel binary + one embedded OTP release.
- **Fault tolerance at the right layer** — supervisors restart Erlang processes
  instead of systemd restarting Unix processes; `heart` + distribution handle node
  failure.
- **Determinism** — no daemons, cron jobs, or page cache competing with the
  schedulers; scheduler-per-core with nothing else on the machine.
- **A minimal trusted computing base** — a few tens of kLOC of kernel instead of a
  full Linux distribution.

Target workloads: single-purpose appliance nodes — message brokers, edge gateways,
routers/protocol bridges, control planes, and orchestration nodes for its sibling
project [`fast-os`](../fast-os/README.md) (AI-first OS; beam-os is a candidate
control-plane substrate for it).

## How

The load-bearing design decision: **nucleus implements a small Linux-syscall-ABI
subset, and ERTS runs on it as an unmodified statically-linked musl binary.**

Rather than inventing a custom kernel ABI and porting OTP to it (the LING/GRiSP
approach, which couples us to OTP internals forever), we build stock OTP as a
static musl executable on Linux, audit exactly which syscalls it makes (~60, half
of which can be stubbed), and implement that subset in the kernel. OTP upgrades
then cost a re-audit, not a re-port. See the
[implementation plan](docs/implementation-plan.md) for the full rationale and the
alternatives considered.

```
┌────────────────────────────────────────────────────┐
│ workloads: broker / gateway / control plane        │  Erlang
│ beam_os OTP apps: boot, console, net_mgr, dev_mgr  │  Erlang
├────────────────────────────────────────────────────┤
│ ERTS + BeamAsm JIT — stock OTP, static musl build  │  C (unmodified*)
├────────────────────────────────────────────────────┤
│ osl: Linux syscall ABI subset (contract + tests)   │  spec
├────────────────────────────────────────────────────┤
│ nucleus: boot, paging, SMP threads, futex, timers, │  Rust
│ IRQs, ramfs, virtio-net/blk, smoltcp, epoll        │
├────────────────────────────────────────────────────┤
│ Limine/UEFI  •  QEMU / KVM / Firecracker  •  metal │
└────────────────────────────────────────────────────┘
```

\* modulo a small vendored patch set (e.g. the `erl_child_setup` forker — see plan §2.9).

## Prior art (and why not just use it)

| Project | What it proves | Why it isn't this project |
|---|---|---|
| **LING / Erlang-on-Xen** | Full ERTS re-implementation as a Xen unikernel works | Dormant since ~2016, frozen on ancient OTP, Xen-only |
| **GRiSP** | Stock-ish OTP runs without Linux (on RTEMS/newlib, bare-metal boards) | Embedded-board focus; RTEMS is still a third-party RTOS underneath |
| **Nerves** | BEAM-as-PID-1 appliances are practical and shippable | Still a full Linux kernel; the reference baseline we benchmark against |
| **AtomVM** | Erlang semantics on microcontrollers | A different VM, subset of OTP; possible future MCU tier, not the core |
| **Unikraft** | Linux-binary-compat unikernels run big runtimes unmodified | Used in Phase 0 as a spike substrate; long-term we want our own ground-up kernel |
| **HydrOS** | Research: multi-kernel Erlang OS, drivers in Erlang | Research prototype, dead; Phase 4 borrows its drivers-in-Erlang ideas |

## Roadmap

| Phase | Deliverable / demo | Rough size |
|---|---|---|
| **0 — Port-surface audit** | Static musl OTP release; strace/seccomp audit → `osl` syscall spec; optional Unikraft boot proof | 1–2 wks |
| **1 — Nucleus boots** | Rust kernel on QEMU q35: Limine boot, serial, paging, SMP kernel threads, timers | 3–6 wks |
| **2 — BEAM boots** | Interactive Erlang shell on serial, all cores scheduling, interpreter first then JIT | 6–10 wks |
| **3 — I/O** | virtio-net + smoltcp → sockets → **distribution between two QEMU nodes**; virtio-blk + ro-ramfs code loading | 6–10 wks |
| **4 — OS-in-Erlang userland** | `beam_os` apps: boot/supervision, net config, console, remote shell, hot upgrade; drivers-in-Erlang experiments | ongoing |
| **5 — Targets & hardening** | aarch64, Firecracker/Cloud Hypervisor microVMs, W^X, <200 ms boot-to-shell budget, crypto/TLS port | ongoing |

Sizes assume part-time solo effort; every phase ends demoable.

## Planned layout

```
beam-os/
├── README.md
├── docs/                 # architecture + implementation plan + osl syscall spec
├── nucleus/              # Rust kernel (boot, mm, smp, time, irq, virtio, net, vfs)
├── osl/                  # syscall-subset spec, conformance tests, stub matrix
├── otp/                  # OTP pin, static-musl build harness, vendored patches
├── runtime/              # beam_os OTP apps (boot, console, net_mgr, dev_mgr)
├── images/               # image assembly: limine.conf, ramfs bundling, mkimage
├── spikes/               # phase-0 unikraft / strace-audit scratch work
└── Makefile              # make audit | run | image | test
```

## Status

**Planning.** Nothing builds yet. Start with
[docs/implementation-plan.md](docs/implementation-plan.md).
