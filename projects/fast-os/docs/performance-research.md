# OS Performance Research Notes

Status: v0.1 · 2026-07-07 · Web survey of current techniques and results for making operating systems faster, with implications for fast-os design. Companion to [architecture.md](architecture.md).

## 1. Syscall overhead & async rings

Findings:

- io_uring's value stack decomposes cleanly: shared memory rings eliminate syscall overhead, SQPOLL eliminates submission overhead, `io_uring_cmd` bypasses the block layer, and registered buffers eliminate per-I/O page mapping ([io_uring for Systems Engineers](https://toziegler.github.io/2025-12-08-io-uring/), [io_uring in 2026 deep dive](https://techbytes.app/posts/linux-io-uring-2026-async-io-deep-dive-explained/)).
- Batched submission amortizes syscall cost and exploits device parallelism; DBMS-focused analysis quantifies when it pays off ([io_uring for High-Performance DBMSs](https://arxiv.org/html/2512.04859v1)).
- Ceiling check: even io_uring needs ≥6× the cycle budget per message vs. true kernel-bypass (DPDK/RDMA ≈40 cycles/message) ([A Wake-Up Call for Kernel-Bypass on Modern Hardware, DaMoN'25](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/papers/damon25_wake_up_call.pdf)).
- Userspace Bypass (OSDI'23) accelerates syscall-intensive code by transparently executing user instructions in-kernel — evidence the trap boundary itself, not the work, is the cost ([USENIX paper](https://www.usenix.org/system/files/osdi23-zhou-zhe.pdf)).
- Security note: ring shared-memory surfaces have real attack surface — e.g. the io_uring ZCRX freelist race ([analysis](https://www.penligent.ai/hackinglabs/io_uring-zcrx-freelist-race-four-bytes-past-the-edge/)).

**fast-os implications:** ADR-0003 (rings primary) is validated, but Linux data shows retrofit limits we avoid natively: build SQPOLL-equivalent adaptive polling, registered buffers, multi-shot ops, and buffer-ring provisioning in from day one rather than as opt-ins. For NIC/NVMe fast paths, plan a DPDK-style bypass lane: capability-granted direct queue access for tier-0 services (inferd, net), since even perfect rings leave ~6× on the table. Treat every ring entry as untrusted input; fuzz the ring layer in CI (the ZCRX bug class).

## 2. The user/kernel boundary itself

Findings:

- Unikraft syscalls are 2–3× faster than Linux (KPTI/mitigation-dependent), but run-time-translated syscalls still cost ~10× a function call; removing user/kernel separation entirely recovers up to 90% of overhead, worth 24% even on 8KB `recvfrom()` payloads ([Unikraft, EuroSys'21](https://arxiv.org/pdf/2104.12721), [Unikraft performance docs](https://unikraft.org/docs/concepts/performance)).
- Unikernel Linux (UKL) shows the same effect grafted onto Linux ([UKL paper](https://arxiv.org/pdf/2206.00789)).
- Speculation mitigations (KPTI etc.) are a large, permanent multiplier on every trap — a tax rings mostly dodge because they cross the boundary rarely.

**fast-os implications:** Confirms the framekernel bet (ADR-0002): keep monolithic-style single-address-space inside the kernel, cross the user boundary rarely (rings), and make the boundary cheap when crossed (minimal trap path, no legacy compat in it). Consider a future *trusted-task* mode — capability-gated, kani-verified userland services granted unikernel-style in-address-space execution — as the endgame for inferd's decode loop.

## 3. Thread-per-core / shared-nothing (userland and kernel)

Findings:

- Production migrations keep validating the model: Apache Iggy's thread-per-core + io_uring rewrite follows ScyllaDB/Redpanda (Seastar) ([Iggy migration, Feb 2026](https://iggy.apache.org/blogs/2026/02/27/thread-per-core-io_uring/), [Seastar shared-nothing](https://seastar.io/shared-nothing/)).
- Glommio's design is instructive: proportional-share scheduling with *three io_uring rings per core* — main, latency, and polling — segregating latency classes at the ring level ([Datadog/glommio](https://github.com/DataDog/glommio), [intro post](https://www.datadoghq.com/blog/engineering/introducing-glommio/)).
- Cooperative thread-per-core removes locking from the programming model entirely ([glommio docs](https://docs.rs/glommio)).
- Linux `sched_ext` lets BPF programs define scheduling policy at runtime — strong signal that one fixed scheduler policy is the wrong abstraction ([sched_ext hands-on](https://hackmd.io/@williamgood/Sy8oCgqgge), [scx tutorials](https://eunomia.dev/tutorials/44-scx-simple/)).

**fast-os implications:** Adopt Glommio's per-core ring *triple* (main/latency/poll) as the kernel-side ring layout — this is a concrete upgrade to architecture.md §2, which specified one SQ/CQ pair per thread. Make scheduler policy pluggable (safe-Rust policy modules over fixed mechanism, our sched_ext analogue) rather than hardcoding EEVDF; latency/throughput classes become two shipped policies, with inference-deadline policy a third.

## 4. Memory: TLB, huge pages, address translation

Findings:

- Huge-page promotion is a cost/benefit problem — promote the fewest pages that eliminate the most TLB misses; naive THP-style promotion wastes memory and stalls ([HawkEye-style HW-assisted selection, patent lit.](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/12130750)).
- Speculative/hash-based address translation can start data fetch before the page walk completes ([Revelator, 2025](https://arxiv.org/pdf/2508.02007)).
- Page-table/TLB placement matters on NUMA: replicating and migrating page tables cuts remote-walk cost ([numaPTE](https://arxiv.org/pdf/2401.15558)).

**fast-os implications:** architecture.md §4's "huge pages by default" needs nuance: default huge for kernel, code, and model weights (ideal case — large, read-only, shared), but drive userland promotion by TLB-miss profiling counters, not blanket policy. Per-core page-table replicas fit our shared-nothing design and kill cross-core shootdown traffic on NUMA/multi-die parts. KV-cache pages are the perfect huge-page client: large, contiguous, kernel-tracked (semantic memory tier).

## 5. Boot time

Findings:

- Sub-2s cold-boot to interactive GUI is achieved on modest embedded hardware via the same recipe every time: eliminate the bootloader stage (Falcon-mode-style direct kernel load), build the smallest targeted kernel, defer everything deferrable to after first paint ([Witekio](https://witekio.com/blog/linux-boot-time/), [Promwad](https://promwad.com/news/fast-boot-embedded-linux), [Toradex](https://www.toradex.com/blog/embedded-linux-boot-time-optimization)).
- The dominant fixed cost is firmware, not the OS — kexec's speedup comes from skipping firmware entirely ([Oracle kexec](https://blogs.oracle.com/linux/reboot-faster-with-kexec)).
- Unikraft boots in <1 ms on Firecracker; microVM cold starts in milliseconds are production reality ([Unikraft Cloud](https://shivangsnewsletter.com/p/how-unikraft-cloud-reduces-serverless), [serverless-edge study](https://arxiv.org/pdf/2403.00515)).

**fast-os implications:** Our <350 ms target is conservative for the OS-controlled portion — the risk is UEFI firmware time we don't control; measure and report firmware vs. OS boot separately in the Phase 0 CI harness. Adopt: single-stage boot (no chained loader logic beyond load+jump), fully parallel service bring-up with explicit dependency graph, first-interactive before non-critical drivers. Add a kexec-style warm-reboot path (skip firmware) early — it also gives us fast kernel-update cycles for development.

## 6. Kernel extensibility for I/O placement

Findings:

- eBPF-in-the-data-path keeps producing wins: pushing LSM-tree compaction logic into the kernel via eBPF recovers performance lost to boundary crossings ([RESYSTANCE](https://arxiv.org/pdf/2603.05162)); kernel-bypass TCP stacks are being opened up and commoditized ([ATC'25](https://www.usenix.org/system/files/atc25-awamoto.pdf)).

**fast-os implications:** We don't need an eBPF clone — safe Rust kernel services *are* our extensibility story (framekernel advantage: extensions are just safe code compiled in). But the lesson stands: provide a sanctioned way to run app-supplied logic next to the data (per-ring completion hooks, capability-gated), so apps never resort to chatty round-trips.

---

## Summary of doc changes driven by this survey

| Doc | Change |
|---|---|
| architecture.md §2 | Per-core ring triple (main/latency/poll); bypass lane for tier-0 services; ring fuzzing in CI |
| architecture.md §3 | Scheduler = fixed mechanism + pluggable safe-Rust policy modules |
| architecture.md §4 | Profile-driven huge-page promotion; per-core page-table replicas |
| architecture.md §8 | Firmware vs. OS boot-time split in CI; warm-reboot (kexec-style) path |
| roadmap.md | Phase 0 exit adds firmware/OS boot split; Phase 2 adds ring fuzz harness |
