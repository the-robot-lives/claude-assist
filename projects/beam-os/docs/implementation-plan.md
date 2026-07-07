# BEAM OS — Implementation Plan

Status: draft v1 (2026-07-07)

Goal: boot from firmware into a supervised Erlang node with **no general-purpose OS
underneath** — a purpose-built kernel hosting an unmodified-as-possible ERTS, with
everything above the VM written in Erlang/OTP.

Guiding principles:

1. **Don't fork OTP.** Treat ERTS as an appliance we host, not a codebase we own.
   Every OTP patch we carry is permanent maintenance debt; the design below keeps
   the patch set to a handful of small, rebasable diffs.
2. **Every phase ends with a demo.** This is a long project; each milestone must
   boot and do something observable, or motivation and reviewability die.
3. **Measure against Nerves.** A minimal-Linux BEAM appliance is the honest
   baseline. If beam-os isn't meaningfully smaller/faster-booting/lower-jitter,
   the premise is falsified — better to learn that early.
4. **Single-purpose, single-tenant.** One address space, one ERTS instance, no
   user/kernel privilege boundary defense-in-depth initially. Isolation is the
   BEAM process model plus the hypervisor boundary (microVMs are the intended
   production posture).

---

## 1. What ERTS actually needs from an operating system

The port surface, from ERTS source structure (`erts/emulator/sys/unix`,
`sys/common`) and prior ports (GRiSP/RTEMS, LING, Unikraft):

| # | Subsystem | What ERTS uses | Notes for nucleus |
|---|---|---|---|
| 1 | CPU/boot | 64-bit entry, per-CPU init, FPU/SSE (floats; BeamAsm emits SIMD) | Limine handles long mode + brings up APs (SMP boot protocol) |
| 2 | Memory | `mmap/munmap/mprotect` anonymous memory for allocator carriers | `+MMscs <mb>` (supercarrier) makes ERTS reserve **one** big region up front and self-manage — drastically shrinks the mmap surface we must implement well |
| 3 | Threads | pthreads: N scheduler threads, dirty CPU/IO pools, aux, poll, sys-msg | musl pthreads ⇒ kernel needs `clone(CLONE_THREAD…)`, `futex`, TLS via `FS`-base (`arch_prctl`), `sched_{get,set}affinity`, `sched_yield` |
| 4 | Time | monotonic + wall clock, hi-res sleep | `clock_gettime(MONOTONIC/REALTIME)` off TSC/kvmclock; LAPIC timer (TSC-deadline) for preemption + `nanosleep`/`futex` timeouts |
| 5 | Polling | kernel-poll: epoll on Linux builds | implement `epoll_create1/ctl/pwait` subset + `eventfd2` + `pipe2`; exact flag usage (oneshot/edge) captured by the Phase-0 audit |
| 6 | Files | load `.beam`/`.app`/boot script; crash dumps | read-only ramfs (release bundle linked into image) behind `openat/read/pread64/fstat/getdents64/…`; write path only for crash dumps → serial or virtio-blk later |
| 7 | Sockets | `inet_drv`/`socket` NIF expect BSD sockets | kernel-side TCP/IP (smoltcp) behind the socket syscalls; virtio-net underneath; raw-frame access reserved for future Erlang-native stack experiments |
| 8 | Console | stdio on fds 0/1/2; OTP ≥26 `prim_tty` does termios ioctls | 16550 serial as the tty; implement `isatty`/`TCGETS/TCSETS/TIOCGWINSZ` minimally or run `-noshell` + own console app until done |
| 9 | Processes | **`erl_child_setup`**: ERTS forks a helper at init to spawn port programs | no fork in a single-address-space kernel. GRiSP faced the same on RTEMS ⇒ small vendored patch to disable the forker; `os:cmd`/spawned ports are simply unsupported (NIFs + linked-in drivers only) |
| 10 | epmd | separate daemon, normally fork/exec'd | run **epmd-less distribution**: `-start_epmd false` + custom `epmd_module` with fixed dist port (standard Nerves/embedded practice) |
| 11 | Entropy | `getrandom` (seeds, crypto later) | RDRAND / virtio-rng |
| 12 | Signals | crash handling (`sigaltstack`), break handling, timer signals | mostly stubbable; audit which registrations must *succeed* vs merely *not fail* |
| 13 | Misc | `uname`, `getpid/gettid`, `prlimit64`, `set_robust_list`, `writev`, `fcntl`, `ioctl(FIONBIO)` | trivial or stub |

Expected total: **~60 syscalls, roughly half stubbable** (return fixed values or
`ENOSYS`-tolerant). The hairy five: `clone`, `futex`, `mmap`, `epoll_*`, and the
socket family. All are well-specified and each has a conformance-testable contract.

## 2. The load-bearing decision: Linux syscall ABI subset

**Nucleus speaks a subset of the Linux syscall ABI. ERTS is built as a stock,
statically linked musl binary and runs unmodified.**

Why this beats the alternatives:

- **The contract is discoverable mechanically.** `strace -f` + a seccomp audit of
  the exact OTP release we intend to ship *is* the spec. No archaeology in ERTS
  internals.
- **OTP upgrades are cheap.** New OTP ⇒ re-run the audit, diff the syscall list,
  extend nucleus if needed. A custom-ABI port (LING) or RTOS port (GRiSP) has to
  chase `sys/unix` internals every major release.
- **Everything is testable on Linux first.** The static binary, the release
  bundle, the epmd-less dist config, the smoke tests — all run identically under
  Linux before nucleus exists, so ERTS-config bugs and kernel bugs never alias.
- **musl's pthreads/malloc come for free** — we implement futex + clone + mmap
  once instead of re-implementing a threading library in a custom libc port
  (newlib route would require exactly that).

Alternatives considered and rejected as the *primary* path:

| Option | Verdict |
|---|---|
| Custom kernel ABI + newlib port of OTP (GRiSP-style) | Rejected: couples us to ERTS internals; we'd own a pthread implementation; every OTP bump is a re-port |
| Ride Unikraft/RTEMS permanently | Rejected as endpoint (they're still third-party OSes — contradicts "ground level up"), but **adopted as Phase-0 spike substrate** to de-risk |
| Nerves-style minimal Linux | Rejected as endpoint (it's Linux); **adopted as the benchmark baseline** |
| AtomVM on bare metal | Rejected: different VM, OTP subset; revisit later as an MCU tier |
| Revive LING | Rejected: dormant, ancient OTP, Xen-only |
| BEAM-in-ring-0 with drivers as Erlang processes (HydrOS) | Deferred: Phase-4 experiment territory, not the foundation |

Consequences accepted:

- No spawned OS processes: `os:cmd/1`, `open_port({spawn_executable,…})` are
  permanently unsupported. Extension points are NIFs, linked-in drivers, and
  Erlang code. This is a feature (TCB stays closed), but it must be documented
  loudly since some hex packages shell out.
- We carry a small OTP patch set (forker disable, possibly a tty edge case).
  Kept in `otp/patches/` with a rebase check in CI.

## 3. Component architecture

```
images/    boot image = limine + nucleus.elf + embedded ramfs (OTP release)
nucleus/   Rust kernel
  ├── boot/      Limine protocol entry, per-CPU setup, AP bring-up
  ├── mm/        phys frame allocator, paging, kernel heap, mmap regions
  ├── task/      kernel threads, scheduler, futex, TLS (FS-base), affinity
  ├── time/      TSC calibration, LAPIC/TSC-deadline timers, clocks
  ├── syscall/   Linux-ABI dispatch + per-syscall impls (the osl surface)
  ├── vfs/       ro ramfs (release bundle), /dev/{console,urandom}, fd table
  ├── net/       virtio-net + smoltcp + socket layer + epoll readiness
  └── drivers/   16550 serial, virtio (pci + mmio transports), rng, blk
osl/       the contract: syscall-subset spec (from audit), stub matrix,
           conformance tests runnable against BOTH Linux and nucleus
otp/       OTP version pin, static-musl build (zig cc or musl-gcc),
           xcomp notes, patches/, release definition (rebar3)
runtime/   beam_os OTP apps:
  ├── beam_os_boot     first app: mounts config, starts supervision tree
  ├── beam_os_console  serial shell/logger mux (until prim_tty fully works)
  ├── beam_os_net      ip/dist config (epmd-less), inet_rc, node naming
  └── beam_os_dev      device inventory surfaced from nucleus (via NIF later)
```

Decisions (defaults chosen; each is revisitable at the phase boundary that
consumes it):

| Decision | Choice | Rationale |
|---|---|---|
| Kernel language | **Rust** | memory safety in the only privileged component; mature bare-metal ecosystem (`x86_64`, `limine`, `smoltcp`); matches existing Rust use in this monorepo |
| First target | **x86_64, QEMU q35** | best-documented bring-up path; KVM acceleration for fast iteration; aarch64 (QEMU `virt`, then hardware) is Phase 5 |
| Bootloader | **Limine** | modern protocol, does long-mode + SMP AP startup for us, trivially scriptable images |
| BEAM flavor order | **interpreter (`emu`) first, BeamAsm second** | JIT needs executable-page plumbing and icache discipline; `--disable-jit`/`-emu_flavor emu` removes that variable from first boot; JIT (with `+JMsingle true` single-RWX-mapping fallback) lands once stable |
| TCP/IP | **smoltcp in-kernel** | Rust-native, proven in embedded; lwIP is the fallback if socket-semantics gaps bite |
| Distribution | **epmd-less, fixed port, `inet_tcp_dist`** | avoids epmd daemon; cleartext on a private virtual network until crypto is ported |
| crypto/OpenSSL | **excluded initially** (`--without-ssl` class build) | porting OpenSSL is its own project; consequences: no `crypto`, `ssl`, `ssh`, TLS dist — revisit in Phase 5 (mbedTLS or BoringSSL static) |
| Code loading | **release bundled in boot image** (ro ramfs) | no block device or filesystem needed for first boot; virtio-blk arrives Phase 3 for crash dumps + code updates |

## 4. Phases

### Phase 0 — Port-surface audit (1–2 wks) ✦ de-risks everything

1. Pin OTP (latest stable, currently 28.x), build **statically against musl**
   (Alpine container or `zig cc`), `--disable-jit` variant + JIT variant.
2. Build a minimal `rebar3` release (kernel/stdlib/sasl + hello app), embedded
   boot script, `-noshell` and shell variants.
3. Run on Linux under `strace -f` and a seccomp-notify recorder through: boot,
   shell interaction, timers, file load, TCP listen/connect, dist ping between
   two nodes, crash dump. Produce `osl/spec/syscalls.md`: every syscall, args
   observed, required-vs-stubbable classification.
4. Prototype the forker problem: confirm `erl_child_setup` behavior when fork is
   denied; draft the vendored patch (GRiSP's RTEMS port is prior art).
5. *(Optional but recommended)* Boot the same static binary under **Unikraft
   binary-compat mode** in QEMU — proof the whole concept works before writing a
   line of kernel code.

**Exit criteria:** syscall spec exists with counts + flags; static release runs
on Linux with seccomp locked to exactly that list; forker patch drafted; go/no-go
on any surprise (e.g. an unimplementable syscall) documented.

### Phase 1 — Nucleus boots (3–6 wks)

Limine boot → serial `println` → GDT/IDT/paging → frame allocator + kernel heap →
LAPIC timer + TSC clock → kernel threads with preemption, futex, per-thread TLS →
SMP: threads scheduled across all cores (Limine starts APs).

**Exit criteria:** demo binary spawns 100 kernel threads across 4 vCPUs, futex
ping-pong benchmark, `make run` boots it in QEMU in <1 s. Unit tests for
allocator/paging run under `cargo test` (hosted) where possible.

### Phase 2 — BEAM boots (6–10 wks) ✦ the flagship milestone

Syscall dispatch + ELF loader (static ELF, no dynamic linking) → implement the
Phase-0 list roughly in this order: memory (`mmap` + supercarrier config),
threads (`clone`/futex/`arch_prctl`), time, ramfs file reads, stubs → wire fds
0/1/2 to serial with minimal termios → apply forker patch → boot the interpreter
release.

**Exit criteria:**
- Interactive Erlang shell on serial in QEMU.
- `erlang:system_info(schedulers_online)` = vCPU count; timer wheel correct
  (`timer:sleep` accuracy test); `rand`, ETS, large binaries, spawn-storm
  (1 M processes) smoke tests pass.
- osl conformance tests pass identically against Linux and nucleus.
- Stretch: BeamAsm flavor boots (`+JMsingle true`).

### Phase 3 — I/O: network + storage (6–10 wks)

virtio-net (PCI transport) → smoltcp integration → socket/epoll syscalls →
`gen_tcp` echo server reachable from host → **distribution: `net_adm:ping/1`
succeeds between two beam-os QEMU nodes** (epmd-less) → virtio-blk + crash-dump
write path → optional: writable FAT/littlefs partition for hot-loaded code.

**Exit criteria:** two-node dist demo (`global` registration across nodes); iperf-class
throughput number recorded vs Nerves baseline; crash dump lands on disk and is
readable by `crashdump_viewer`.

### Phase 4 — OS-in-Erlang userland (ongoing)

`beam_os_*` apps: boot/supervision sequence, net config, console mux, log ring,
remote shell over dist, hot code upgrade story (relup or simpler code-path swap),
observability (recon-style introspection surfaced over dist). Experiments:
device drivers as Erlang processes over raw MMIO/virtio NIF bindings (HydrOS
homage), Erlang-native TCP/IP over raw frames.

### Phase 5 — Targets & hardening (ongoing)

aarch64 (QEMU `virt` w/ virtio-mmio, PL011; then hardware), Firecracker /
Cloud Hypervisor / QEMU `microvm` (virtio-mmio transport shared with aarch64),
W^X + guard pages + KASLR-lite, boot-time budget (**<200 ms firmware→shell in a
microVM**), image-size budget (<20 MB), crypto port (static mbedTLS or BoringSSL
→ `crypto`/`ssl`/`ssh` → TLS distribution), signed images.

## 5. Testing & CI

- **osl conformance suite** (the keystone): every syscall in the spec gets a
  host-runnable test binary executed against Linux (truth) and nucleus (target).
  Divergence = bug, no debate.
- **Serial-driven integration tests**: expect-script drives the Erlang shell over
  QEMU serial; smoke suite = boot, spawn storm, timer accuracy, ETS, dist ping.
- **OTP's own suites (subset)**: `emulator` smoke tests once files+net exist.
- **Benchmarks tracked per merge**: boot-to-shell time, dist round-trip latency,
  scheduler jitter under load — each vs the Nerves baseline image.
- **OTP rebase job**: CI applies `otp/patches/` against the pinned tag and the
  newest OTP; alerts on drift.
- All runnable via `make audit | run | test | image`; CI needs only QEMU + KVM.

## 6. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| `erl_child_setup`/forker can't be cleanly disabled | blocks first boot | Phase-0 item #4; GRiSP proves a no-fork ERTS exists; worst case implement a degenerate in-kernel fork for that single helper |
| epoll/socket semantics subtly wrong under load | dist flakiness, hard bugs | conformance suite first, smoltcp behind a narrow socket layer, lwIP as fallback |
| BeamAsm on custom kernel (exec pages, dual-mapping) | perf ceiling if stuck on interpreter | interpreter flavor is fully supported indefinitely; `+JMsingle true`; JIT is a stretch goal per phase, not a dependency |
| OTP release churn changes syscall surface | recurring tax | that's the design: audit is mechanical; CI rebase job flags drift early |
| `prim_tty` (OTP≥26) termios expectations | no interactive shell | `-noshell` + `beam_os_console` app as interim; implement the handful of ioctls after |
| Crypto absence limits real deployments | no TLS/ssh | scoped consciously to Phase 5; until then beam-os is for private-network appliances |
| Scope creep toward general-purpose OS | project death | non-goals doc; single-tenant single-VM posture; fast-os ambitions stay in fast-os |
| Solo/part-time capacity | stalls | phase demos are small and self-contained; each phase independently valuable (Phase 0 alone yields a reusable static-OTP + seccomp artifact) |

## 7. Open questions

1. License & repo split — Apache-2.0? Extract to its own repo/subtree remote once
   Phase 1 lands (matches monorepo subtree convention).
2. Name check: `nucleus` (kernel) / `osl` (ABI layer) — placeholder names.
3. aarch64 priority — pull forward if a concrete edge-hardware target appears.
4. fast-os relationship — does fast-os consume beam-os as control plane, or do
   they stay independent seeds? Decide when fast-os has a design doc.
5. MCU tier via AtomVM sharing the `runtime/` app conventions — worth it?

## 8. References

- GRiSP (OTP on RTEMS, no fork): grisp.org / grisp/grisp repos
- LING / Erlang-on-Xen: cloudozer/ling — full custom-ABI port, cautionary tale
- Nerves `erlinit`: BEAM-as-PID-1 reference and benchmark baseline
- Unikraft binary-compat (app-elfloader): Linux-ABI-subset unikernels
- HydrOS (Kent): drivers-as-Erlang-processes research
- OTP xcomp docs: `$ERL_TOP/HOWTO/INSTALL-CROSS.md`; ERTS sys layer:
  `erts/emulator/sys/{unix,common}`
- ERTS flags used above: `+MMscs` (supercarrier), `+JMsingle`, `-emu_flavor`,
  `-start_epmd false` / `-epmd_module`
