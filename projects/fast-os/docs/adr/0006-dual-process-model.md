# ADR-0006: Dual process model — thin actors and fat core-lease tasks, runtime-switchable

Date: 2026-07-16 · Status: proposed

## Context

The scheduler design (architecture.md, ADR-0003, ADR-0005) already pulls in two
directions at once:

- The agent-native surface wants **enormous numbers of cheap, preemptible,
  message-passing tasks** — agents, tools, watchers — the shape BEAM proved out:
  tiny per-process footprint, reduction-based preemption, mailbox IPC, no shared
  mutable state.
- inferd-class workloads want the opposite: **a whole core, no tick, no
  neighbors** — token-decode loops, codec/DSP kernels, poll-mode I/O. The plan
  already gestures at this with inference-aware deadline hints and a capability
  bypass lane for tier-0 services.

Serving both with a single compromise scheduler class gives up both wins.
Serving them with two unrelated process types forks the syscall surface, the
capability model, the budget accounting, and the test matrix.

Additionally, real workloads change phase at runtime: an inference request is
thin while queued, deserves a core during decode, and is thin again after; an
agent is idle for minutes and hot for seconds. A static at-spawn choice forces
worst-case provisioning.

## Decision

One kernel `Task` object; **execution mode is a mutable scheduling attribute**,
not an identity.

- **Thin mode (default):** tasks run on the shared core pool under per-core,
  shared-nothing scheduler instances with pluggable policy classes (latency/
  EEVDF, throughput). Preemption is cooperative-first — reduction/budget checks
  at safe points (await, alloc, send) — with a hard timer backstop (≤ 2 ms) so a
  misbehaving task can never monopolize a core. Baseline footprint ≤ 2 KiB;
  target ≥ 100k concurrent thin tasks on the 512 MiB dev VM. IPC is per-task
  mailboxes with zero-copy grant handoff.
- **Fat mode (core lease):** a task holding a `CoreLease` capability may be
  promoted onto one or more dedicated cores: thin tasks are drained off, the
  tick is disabled, IPIs are masked except the lease-revocation IPI. The task
  runs to completion and may poll its rings from userspace. Target: ≤ 5 µs p99
  scheduling jitter on a leased core.
- **Runtime switching, both directions, no restart.** Promotion (thin→fat)
  drains and claims a core: ≤ 10 ms p99. Demotion (fat→thin) happens at a
  cooperative yield or on revocation IPI: ≤ 1 ms p99 from signal to re-enqueue.
  Task ID, capabilities, mailbox contents, budgets, and flight-recorder lineage
  are preserved across every switch.
- **Core lease manager:** grants are capability-gated, revocable, and bounded by
  a shared-pool floor — at least one core (core 0) is never leasable, so the
  thin pool and the kernel's own housekeeping always have somewhere to run.
  Budget exhaustion (agentd trees, ADR-0005 metering) forces demotion.
- **One interface:** rings (ADR-0003) are mode-agnostic. Thin tasks batch and
  park on CQ waits; fat tasks poll the same rings. No mode-specific syscalls
  beyond `set_mode` / lease request itself.
- **Asymmetric silicon (Phase 6):** fat leases prefer big cores; the thin pool
  spans the remainder with core-type hints.

Requirement IDs REQ-PM-001…012 and per-milestone exit criteria live in
[implementation-roadmap.md](../implementation-roadmap.md) §2–3.

## Consequences

Positive:

- The agent substrate and the inference substrate stop competing: thin mode is
  the default for the many, fat mode is the earned exception for the few.
- Mode-switching turns core allocation into a runtime policy decision (budgets,
  deadlines, load) instead of a deployment-time one — the scheduler can express
  "this decode burst is worth a core for 800 ms."
- One task type keeps capabilities, budgets, checkpointable context handles, and
  the flight recorder uniform; the test matrix forks only inside the scheduler.
- Thread-per-core shared-nothing scheduling (already chosen) is exactly the
  architecture that makes core draining and leasing tractable.

Negative / accepted costs:

- The scheduler carries a lease manager and a drain path — meaningful complexity
  landing in milestone M2, our hardest milestone.
- Soft preemption in Rust lacks BEAM's compiler-inserted reduction counts; we
  accept safe-point instrumentation plus the timer backstop, meaning worst-case
  thin latency is bounded by the backstop (2 ms), not by reductions.
- Fat leases shrink the thin pool; under lease pressure thin latency SLOs depend
  on the floor policy and budget-driven revocation actually working (tested from
  M2 onward, validated for real by inferd in M6).
- OTP-style supervision trees, distribution, and hot code loading are explicitly
  out of scope for thin mode — that exploration belongs to the sibling
  `beam-os` project; fast-os borrows BEAM's scheduling shape, not its runtime.

## Alternatives considered

1. **Single unified scheduler class with priorities/deadline hints only** —
   rejected: cannot deliver tickless ≤ 5 µs jitter cores while also running 100k
   preemptible tasks; deadline hints don't remove tick and IPI noise.
2. **Two distinct process types (green tasks + native pinned processes)** —
   rejected: forks the capability/budget/IPC/observability surface and freezes
   the thin-vs-fat choice at spawn time, defeating the phase-change workloads
   that motivated this.
3. **Fat mode via dedicated tier-0 services only (no general lease API)** —
   rejected: makes inferd special-cased kernel policy instead of a reusable
   primitive; third-party heavy compute (codecs, sims, model runners) would
   re-request the same mechanism immediately.
