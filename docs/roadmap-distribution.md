# Distribution Roadmap: Installable VM Image, Live Disk, Self-Hosting

Status: v0.1 · 2026-07-07 · Extends [roadmap.md](roadmap.md) with two concrete destination milestones: **D1 — an installable/live OS image anyone can boot in a VM**, and **D2 — a self-hosting fast-os** (fast-os builds fast-os). Phases reference the main roadmap.

## D1 — Installable VM live disk

Goal: one downloadable `fast-os.img` (UEFI-bootable, x86_64 + aarch64 variants) that boots to a live session in QEMU/UTM/Firecracker/Proxmox, with an optional "install to disk" flow.

### D1.a Live image (after Phase 3)

Prereqs: rings, fastfs v1, fsh command mode, virtio drivers, service manager — all Phase 2–3 exits.

- **Image build pipeline** (`tools/mkimage`): reproducible image assembly in CI — ESP + fastfs root subvolume, versioned; every merge to main produces a bootable artifact. This mostly exists as the Phase 0 CI boot harness; D1 productizes it.
- **Live semantics for free:** boot the root subvolume read-only, overlay a session subvolume via fastfs snapshot — no separate squashfs/overlayfs machinery ([fastfs-design.md](fastfs-design.md) §3.1). "Reset live session" = drop snapshot.
- **First-boot experience:** fsh with the tutorial memoryd namespace preloaded; no login on live boot; networking up via virtio + DHCP.

**Exit:** cold download → `qemu-system-x86_64 -drive file=fast-os.img` → interactive fsh in <5 s wall clock; same image boots UTM (aarch64) unmodified.

### D1.b Installer (after Phase 4, before Phase 5 demo)

- Installer is an agent task in a box: plan preview shows exactly the effects (partition, copy, bootloader), executes staged, journaled, resumable — the flight recorder doubles as install log. This is deliberately our first dogfood of the staged-effects machinery on a destructive workflow.
- Disk layout: ESP + single fastfs pool; user chooses policy defaults (e.g. `mirror:2` `/home` if ≥2 disks).
- Cloud-init-class seeding for headless/VM installs (hostname, keys, model manifest) via typed config store import.

**Exit:** unattended VM install from image + seed file in CI; manual install flow with plan preview on bare-metal reference box.

### D1.c Update channel (parallel with Phase 5)

- A/B root subvolumes + kexec warm reboot = atomic upgrade with rollback; image-delta downloads (fastfs snapshot send/receive).

**Exit:** CI-published channel; live-booted system can install and update to next build.

## D2 — Self-hosting

Goal: fast-os builds, tests, and releases fast-os with no Linux machine in the loop. This is the classic OS maturity bar; it forces broad correctness (toolchain, POSIX personality, storage, networking) rather than demo-path correctness.

Ladder, mapped to main-roadmap phases:

| Step | Needs | Milestone |
|---|---|---|
| S1: edit loop | Phase 3 personality T1 (git, curl, ssh) | clone the fast-os repo, edit, push from fsh |
| S2: cross-check | Phase 4 | run kernel unit tests + image assembly on fast-os (build still cross-compiled on Linux CI) |
| S3: toolchain | rustc + cargo under linux-personality (the long pole — needs fork/exec, dynamic linking, threads, mmap-heavy workloads; see [posix-compatibility.md](posix-compatibility.md) §3 target list) | `cargo build` any pure-Rust crate natively |
| S4: kernel build | S3 + LLVM backend soundness on personality; QEMU or KVM-class virt on fast-os for the test boot | fast-os compiles its own kernel and boots the result in a guest |
| S5: full CI | S4 + runners-as-agent-tasks (budgeted, sandboxed subvolumes per job) | release images produced end-to-end on fast-os; Linux CI retired to cross-check only |

**Exit (self-hosting declared):** three consecutive releases built, tested, and published by fast-os runners; a fresh contributor can bootstrap dev on a fast-os VM alone.

Sequencing note: S3 is the schedule risk — rustc is one of the harshest POSIX-compat workloads there is (it's effectively our Loupe target-set stress test). If personality-hosted rustc stalls, fallback is a native port of the Rust toolchain (bigger effort, cleaner result); decision point after S2, captured as a future ADR.

## Non-goals for D1/D2

Physical install media polish (USB creators, secure-boot signing chains) — after D2; multi-boot alongside other OSes — discouraged, VM-first; package-manager ecosystem — separate track, D1.c's image channel suffices until then.
