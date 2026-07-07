# Networking Stack

Status: v0.1 · 2026-07-07 · Design for fast-os networking: ring-native in-kernel stack, QUIC-first transport, a bypass lane for line-rate work, and capability-scoped network authority for agents. Expands [architecture.md](architecture.md) §2/§11 and the tech-choices smoltcp/QUIC rows.

## 1. Lessons from the field

Linux's own trajectory points at a **hybrid stack**: keep the kernel for control-plane traffic and compatibility, steer data-plane packets to dedicated fast paths — XDP/AF_XDP's four-ring UMEM design (RX/TX/fill/completion, lock-free, zero-copy with driver support) is exactly this ([XDP](https://en.wikipedia.org/wiki/Express_Data_Path), [hybrid networking stack](https://next.redhat.com/2022/12/07/the-hybrid-networking-stack/)). DPDK now ships AF_XDP poll-mode drivers (convergence of bypass and kernel worlds), and MsQuic pairs QUIC directly with XDP. Meanwhile clean-slate research (e.g. [Joyride](https://arxiv.org/pdf/2509.25015)) argues Linux's stack shape itself — not just its boundary — costs performance, security, and reliability; and memory-safe userspace stacks are demonstrably practical ([memory-safe userspace switch](https://pothos.github.io/papers/msc_thesis_memory-safe_network_services_userspace_switch.pdf)). We get to build the hybrid natively instead of retrofitting it.

## 2. Architecture: one NIC, three lanes

```
                    NIC hardware queues (RSS/flow-steered)
        ┌────────────────┼──────────────────────┐
        ▼                ▼                      ▼
  lane A: kernel    lane B: bypass         lane C: guests
  netstack (safe    capability-granted     queue pairs passed
  Rust, smoltcp-    direct queue pairs     to tier-3 microVMs
  derived)          (tier-0 services)      (virtio/vDPA-style)
```

- **Lane A — kernel stack (default):** smoltcp-derived safe-Rust TCP/UDP/IP in a framekernel service. Sockets are ring objects: accept/read/write are SQ entries; multi-shot receive with provided buffer rings (io_uring's endgame features, native from day one — see [performance-research.md](performance-research.md) §1). Zero-copy RX into registered buffer pools; TSO/checksum offloads assumed, not optional.
- **Lane B — bypass lane:** the architecture.md §2 bypass made concrete: a NIC driver hands specific hardware queue pairs (UMEM-style ring quads) directly to a capability-holding tier-0 service. Flow steering keeps control traffic in lane A (the AF_XDP control/data split). First customers: QUIC terminator, distributed-inference transport for inferd.
- **Lane C — guest lane:** queue pairs mapped into tier-3 microVMs ([app-compatibility.md](app-compatibility.md) §5), so guests get near-native networking without a userspace switch hop; a safe-Rust virtual switch handles the slow/filtered path.

## 3. QUIC-first transport

Modern app traffic is HTTP/3/QUIC-shaped, and QUIC-in-userspace-over-UDP wastes the kernel's connection knowledge. fast-os makes QUIC a **first-class kernel-adjacent transport**:

- `quicd` (tier-0, lane B): connection/stream management, TLS 1.3 (rustls-class), 0-RTT resumption. Apps open *streams* via rings — stream-per-request without per-connection syscall churn.
- The native RPC/service mesh story: Tool Bus calls between machines ride QUIC streams; datagram extension carries inference token streams (loss-tolerant, latency-sensitive).
- TCP/TLS remain fully supported in lane A for compatibility; personality processes get standard sockets (epoll adapter per [posix-compatibility.md](posix-compatibility.md) §2).

## 4. Policy, naming, agents

- **Capabilities, not firewall-after-the-fact:** network authority is granted as (direction, host-set/CIDR, port-set, byte/connection budget) capability bundles. A process without a net capability has no stack access at all — the default. Egress policy is thus enforced at the API, with a lane-A packet filter as defense-in-depth only.
- **Agents:** an agent task's net capability is part of its bundle ([agent-integration.md](agent-integration.md) §4) — "this task may fetch from crates.io and nothing else" is one grant line. Remote-model calls from inferd are explicit host-set grants. Every foreign connection by an agent lands in the flight recorder with bytes/host/duration.
- **Naming:** resolverd (DNS/DoH/mDNS) is a Tool Bus service returning *typed, cacheable* results; agents and apps share one resolver view, capability-filtered. Zero-config peer discovery (mDNS) powers the multi-device story later (context handoff between your machines).
- **Time**: NTP/PTP client in lane A early — QUIC, TLS, and the flight recorder all need trustworthy time.

## 5. Performance posture

Targets, CI-measured from Phase 3: lane-A small-RPC latency within 1.3× of Linux io_uring+TCP on the same hardware from the start, beating it as batching matures; lane-B line rate at 2×25 GbE-class with <10% single-core utilization (DPDK/AF_XDP-zc parity per [the wake-up-call data](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/papers/damon25_wake_up_call.pdf)); QUIC stream-open latency <1 RTT resumed, ~µs local.

## 6. Sequencing

Phase 2 (as roadmapped): virtio-net in lane A, sockets over rings. Phase 3: NIC driver for reference hardware, resolverd, NTP. Phase 4–5: quicd on lane B, Tool-Bus-over-QUIC, net capabilities enforced for agent tasks. Phase 6: guest lane C, mDNS/multi-device, performance targets audited.

Sources: [XDP (Wikipedia)](https://en.wikipedia.org/wiki/Express_Data_Path) · [Red Hat hybrid networking stack](https://next.redhat.com/2022/12/07/the-hybrid-networking-stack/) · [Joyride: rethinking Linux's network stack](https://arxiv.org/pdf/2509.25015) · [memory-safe userspace switch thesis](https://pothos.github.io/papers/msc_thesis_memory-safe_network_services_userspace_switch.pdf) · [kernel-bypass wake-up call (DaMoN'25)](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/papers/damon25_wake_up_call.pdf)
