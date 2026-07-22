# fast-os TODO — pending tobor ticket migration

> Filed as a flat note because tobor MCP extended support (tickets/artifacts)
> is offline at the moment. Migrate each item into tickets under session
> `a21c8711-de78-4ca7-af59-b9bdc5761f7d` (noizu-labs / noizu-infra,
> "fast-os roadmap") once it's back online, then delete this file.

Follow-ups from the 2026-07-16 roadmap session (see
[docs/implementation-roadmap.md](../docs/implementation-roadmap.md) §8):

- [ ] Review & accept [ADR-0006 dual process model](../docs/adr/0006-dual-process-model.md); M2's checklist assumes it
- [ ] M0: stand up `xtask` + CI boot smoke test with boot-ms trend tracking (unblocks every later gate)
- [ ] Decide x86_64 now-or-defer; record the decision (ADR or roadmap.md edit)
- [ ] M1 spike: GIC init + timer interrupt on QEMU virt — first preemption tick
- [ ] Register the roadmap + ADR-0006 as session artifacts in tobor when extended support returns
- [ ] Hook up Loom's access to the `loom@therobotlives.com` mailbox (commit co-author identity established 2026-07-16 in root CLAUDE.md)
