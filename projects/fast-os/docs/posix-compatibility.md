# POSIX / Linux Compatibility Strategy

Status: v0.1 · 2026-07-07 · Research-grounded plan for running existing software on fast-os without contaminating native interfaces. Refines the "POSIX personality" placeholder in [architecture.md](architecture.md) §9 and roadmap Phase 3.

## 1. What the research says

**Compatibility is smaller than it looks.** The Loupe study (ASPLOS'24) measured what applications *actually* need: 40–60% of syscalls found in application code never need real implementations to pass full test suites; some apps run standard benchmarks with only ~20% of what static analysis reports. Systematically measured, OSv would have needed 37 syscalls instead of the 92 it implemented ad hoc. Applications are surprisingly resilient to stubbed and faked syscalls ([Loupe paper](https://arxiv.org/abs/2309.15996), [tool](https://github.com/unikraft/loupe)).

**Target the Linux ABI, not the POSIX spec.** Every successful modern compat effort targets Linux binary compatibility, because that's what shipped software is built against: gVisor implements 277 of 351 amd64 syscalls in userspace Go and runs most container workloads ([compat tables](https://gvisor.dev/docs/user_guide/compatibility/linux/amd64/)); Asterinas provides 210–230+ Linux syscalls and boots real distro userlands ([paper](https://arxiv.org/pdf/2506.03876)); Graphene/Gramine does it as a libOS over a small platform adaptation layer ([thesis](https://www.chiachetsai.com/files/Graphene-Thesis-Chia-Che-Tsai.pdf), [libOS design](https://dl.acm.org/doi/pdf/10.1145/3453933.3454011)). "Emulating the Linux API is the best way to support existing applications without modification" is the consistent conclusion ([Loupe, §1](https://arxiv.org/html/2309.15996)).

**Three placement options, one clear fit.** (a) In-kernel Linux ABI (Asterinas): fastest, but drags Linux semantics into our kernel and TCB. (b) Userspace syscall interception (gVisor): safest, ~2–3× syscall overhead. (c) libOS/personality process (Graphene, Drawbridge/[picoprocess](https://www.usenix.org/system/files/conference/atc13/atc13-howell.pdf)): Linux semantics implemented in a userspace layer that maps onto a small native API — isolation without per-syscall interception cost, since the "syscalls" become in-process calls onto our rings.

## 2. Decision: `linux-personality` as a libOS

A userspace personality layer, per process group:

```
┌──────────────────────────────────────────────┐
│ unmodified Linux binary (ELF, musl or glibc) │
├──────────────────────────────────────────────┤
│ linux-personality libOS                      │
│  syscall entry (SUD/trap redirect) →         │
│  Linux semantics (fds, signals, procfs,      │
│  futex, epoll→ring adapter, fork/exec)       │
├──────────────────────────────────────────────┤
│ fast-os native: rings + capabilities         │
└──────────────────────────────────────────────┘
```

- **Entry**: syscall-user-dispatch-style redirection — the kernel bounces `syscall` instructions from personality processes back into the libOS handler in-process. No kernel round-trip for the ~70% of calls the libOS can satisfy locally (memory, fd table, time via vDSO-style page); the rest compile to ring ops.
- **Semantics live in userspace**: fork/exec, signals, `/proc`, epoll/poll/select (adapters over CQ waits), futex (maps to native wait primitive). The fast-os kernel stays Linux-free.
- **Capabilities still bound everything**: a personality process holds a capability bundle like any native process; POSIX "root" inside the personality confers nothing outside it. Compat never widens authority — this is the line gVisor draws too, and it's what makes running dubious legacy software on an agent-managed OS acceptable.
- **Filesystem view**: personality processes see a synthesized FHS (`/etc`, `/proc`, `/tmp`) projected from the typed config store and native namespaces; native processes never see it.

## 3. Scope: measured, not speculative — "full" as a milestone ladder

Adopt Loupe's methodology directly rather than chasing all ~350 syscalls:

1. **Target-set definition**: the concrete apps we want (initial list: busybox/toybox, git, curl, openssh, python3, node, postgres, redis, nginx, cargo/rustc).
2. **Measure** with Loupe-style dynamic analysis on Linux to get the true required/stub-able/fake-able syscall sets for those workloads.
3. **Implement in tiers**: T1 measured-required (est. 40–70 syscalls per Loupe/OSv data), T2 stubs/fakes with logging, T3 the long tail on demand. CI runs each target app's test suite inside the personality.
4. **"Full POSIX"** (SUSv4 conformance-grade) is declared only when the Open Group test suite areas we care about pass — tracked as a Phase 6+ stretch goal, since research shows conformance-completeness has poor ROI vs. app-measured compatibility.

## 4. What we refuse to do

No Linux semantics in the fast-os kernel (Asterinas's path — right for a Linux replacement, wrong for us); no ptrace-style interception as the primary mechanism (gVisor's historical perf tax); no promise that personality processes get native-class performance — they get *good* performance and full isolation, and porting to native rings is the upgrade path.

## 5. Roadmap hooks

- Phase 3 (as planned): personality v0 — static musl binaries, T1 syscalls, busybox-class tools.
- Phase 4–5: dynamic linking, fork/exec, sockets tier — git/curl/python milestones.
- Phase 6+: postgres/nginx-class services; SUSv4 conformance stretch.

Sources: [Loupe (ASPLOS'24)](https://arxiv.org/abs/2309.15996) · [Loupe tool](https://github.com/unikraft/loupe) · [gVisor compatibility](https://gvisor.dev/docs/user_guide/compatibility/) / [amd64 table](https://gvisor.dev/docs/user_guide/compatibility/linux/amd64/) · [Asterinas paper](https://arxiv.org/pdf/2506.03876) · [Graphene thesis](https://www.chiachetsai.com/files/Graphene-Thesis-Chia-Che-Tsai.pdf) · [libOS for containers](https://dl.acm.org/doi/pdf/10.1145/3453933.3454011) · [Embassies/picoprocess](https://www.usenix.org/system/files/conference/atc13/atc13-howell.pdf)
