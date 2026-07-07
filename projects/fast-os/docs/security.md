# Security Architecture

Status: v0.1 · 2026-07-07 · Expands ADR-0004 into a full model: authorization that exceeds both Unix permissions and NT ACLs, plus memory/runtime protection. Companion to [agent-integration.md](agent-integration.md) §4 (agent authority) and [architecture.md](architecture.md) §7.

## 1. Authorization: capabilities as mechanism, ACL-grade policy on top

### 1.1 Why not Unix, why not only NT ACLs

Unix permission bits (owner/group/other × rwx) are famously too coarse — one group axis, no delegation, no deny, no audit tie-in ([CS513 comparison](https://www.cs.cornell.edu/courses/cs513/2000SP/L07.html)). NT got the expressiveness right: every object carries a security descriptor with ACEs granting or denying fine-grained rights per user/group SID, with inheritance and auditing ([NT vs UNIX security](https://www.researchgate.net/publication/2511660_A_Comparison_of_the_Security_of_Windows_NT_and_UNIX)). But ACLs have two structural defects capabilities fix ([capability-based security](https://grokipedia.com/page/Capability-based_security), [access matrix: rows vs columns](https://identitymanagementinstitute.org/access-control-matrix-and-capability-list/)):

- **Ambient authority / confused deputy**: an ACL system checks *who you are*, so a privileged process tricked into acting on an attacker's behalf passes every check. Capabilities check *what you hold*, carrying intentionality — the deputy can only use the specific token it was handed. For an OS that runs autonomous agents, this is the whole ballgame: prompt injection is a confused-deputy factory.
- **Delegation**: ACLs centralize policy mutation (edit the object's list); capabilities delegate by handing over an attenuated token — O(1), decentralized, revocable at the subtree ([Fuchsia's rethink](https://blog.mi.hdm-stuttgart.de/index.php/2023/07/30/fuchsia-rethinking-os-security-design-after-50-years/)).

Zircon/Fuchsia validates the mechanism at production scale: fully isolated processes by default, all kernel access through unforgeable handles with per-handle rights ([Understanding Fuchsia Security](https://arxiv.org/pdf/2108.04183)). What pure capability systems historically lack is *administrability* — answering "who can touch this object?" requires walking every subject. So:

### 1.2 The fast-os model: two layers, one mechanism

**Layer 1 — enforcement (capabilities, the only mechanism).** As ADR-0004: every resource handle is an unforgeable, typed capability with a rights mask; attenuable, revocable (O(1) delegation-subtree kill), journaled. No UIDs consulted at access time, no setuid, no root.

**Layer 2 — policy (the issuer).** `authd`, a tier-0 service, decides *which capability bundles get minted* for which principals — and this layer is deliberately NT-ACL-superset expressive:

- **Principals**: users, groups/roles, services, *agent tasks*, and *delegation chains* (a principal acting via another — first-class, so "Keith-via-backup-agent" is distinguishable from "Keith").
- **Policy entries** (ACE-equivalents) on any object or namespace: allow *and deny* rules, typed rights (not just rwx — per-interface-method on Tool Bus objects), inheritance down subvolume/namespace trees, and **conditions**: time-of-day, machine state, budget remaining, staged-approval requirements, "only when flight-recording".
- **Answers both directions cheaply**: "what can this principal reach?" (its minted bundles) and "who can reach this object?" (policy query) — the ACL-style audit question pure capability systems answer badly.
- **Windows-compat mapping**: NT security descriptors from tier-2 apps ([app-compatibility.md](app-compatibility.md)) translate mechanically — SIDs→principals, ACEs→policy entries — since our policy layer is a superset.

Key invariant: policy is *advice to the mint*, never checked on the hot path. Access-time cost is a capability-table lookup (ns-class), preserving the performance thesis; revocation and policy changes invalidate minted capabilities via epoch bump.

### 1.3 Users and login

Multi-user exists but sessions hold *bundles*, not identities-with-ambient-power. Login = authenticate (passkey/FIDO2-first, password fallback) → authd mints the session's root bundle from policy. "Administrator" is a bundle containing mint-and-revoke authority, requestable per-operation with approval on the trusted overlay ([graphics-display.md](graphics-display.md) §4) — sudo's UX without sudo's ambient blast radius.

## 2. Memory & runtime protection

Defense stack, ordered by what does the real work:

1. **Language**: the framekernel confines all `unsafe` to `frame/` (<15% LOC, kani-model-checked) — spatial/temporal memory safety for 85%+ of kernel code by construction, the mitigation class regulators now treat as baseline ([kernel mitigations review](https://www.mdpi.com/1424-8220/26/8/2452)).
2. **W^X everywhere, no exceptions**: no page ever writable+executable, kernel or user; kernel code unreadable from userspace; no runtime kernel code patching (no JIT in kernel — eBPF-style extension needs are met by compiled-in safe Rust, [performance-research.md](performance-research.md) §6). W^X plus no-leak discipline makes code injection and much code reuse impractical ([Spectre-era kernel safety](https://arxiv.org/pdf/2411.18094)).
3. **ARM64 hardware, on by default on the flagship target**: **PAC** (sign return addresses + key data pointers), **BTI** (branch-target enforcement) for control-flow integrity ([CFI on Arm64](https://sipearl.com/wp-content/uploads/2023/10/SiPearl-White_Paper_Control_Flow_Integrity-on-Arm64.pdf)); **MTE** memory tagging for the residual unsafe code and all personality/foreign processes — Apple ships MTE-class enforcement fleet-wide, proving cost is acceptable ([Apple memory integrity](https://innovation.consumerreports.org/apples-new-iphone-memory-protections-safeguards-devices-against-sophisticated-attacks/)). x86_64 equivalents (CET shadow stacks/IBT) where present.
4. **KASLR, honestly weighted**: we ship it (free entropy) but treat it as speed bump, not boundary — timing side channels break KASLR on all major OSes in seconds ([DrK](https://dl.acm.org/doi/10.1145/2976749.2978321), [efficacy analysis](https://medium.com/@jackrtschetter/assessing-the-efficacy-of-kaslr-and-karl-for-software-security-42ceecc97db4)). Nothing in our threat model may *depend* on secret kernel layout.
5. **Speculation**: default-on mitigations at the user/kernel boundary; the ring architecture crosses that boundary rarely, so the tax is small (this is a security *and* perf win — [performance-research.md](performance-research.md) §1). Cross-core: sensitive services (authd, key management) get core-exclusive placement via the shared-nothing scheduler.
6. **Ring/DMA hygiene**: ring entries are untrusted input, fuzzed in CI ([architecture.md](architecture.md) §2); IOMMU/SMMU mandatory for device DMA and lane-B/C queue grants — a bypass-lane holder can DMA only into its own granted buffers ([networking.md](networking.md) §2).
7. **CHERI, watched not adopted**: object-granularity hardware capabilities would unify our software capability model with hardware enforcement; Morello/CheriBSD analysis shows promise with real gaps ([CheriBSD security analysis](https://arxiv.org/pdf/2601.19074), [usability study](https://arxiv.org/pdf/2506.23682)). Our handle layer is designed so a CHERI backend could enforce it 1:1 later — tracked as a future ADR.

## 3. Platform integrity

Measured boot: UEFI secure boot → signed kernel image → fastfs root subvolume merkle verification (dm-verity-class) for the immutable OS image; A/B update slots sign-checked before kexec ([roadmap-distribution.md](roadmap-distribution.md) D1.c). Secrets: per-device key hierarchy in a TPM/Secure-Enclave-backed keystore service; fastfs per-policy-domain encryption keys derive from it. The flight recorder is append-only and mirror-forced — tamper-evidence for agent actions is a platform-integrity property, not an application feature.

## 4. Agent-specific posture (summary; detail in agent-integration.md)

No ambient authority means prompt injection can't escalate past the granted bundle; `effectful` operations stage for approval on the spoof-proof trusted overlay; synthetic input and screen capture are per-surface capabilities; every capability exercise is journaled and replayable. Foreign-app tiers run behind personality/VM capability bundles — legacy software gets NT-grade *policy* expressiveness with capability *enforcement* underneath.

## 5. Sequencing

Phase 2: capability tables + rights masks (already roadmapped), W^X, KASLR. Phase 3: authd v1 (principals, policy mint, deny rules), signed images. Phase 5: trusted overlay approvals, delegation-chain principals, budget conditions (with agentd). Phase 6: PAC/BTI/MTE on ARM64 flagship, IOMMU enforcement for bypass lanes, measured boot end-to-end. Post-D2: CHERI evaluation ADR.

Sources: [Capability-based security](https://grokipedia.com/page/Capability-based_security) · [Fuchsia security rethink](https://blog.mi.hdm-stuttgart.de/index.php/2023/07/30/fuchsia-rethinking-os-security-design-after-50-years/) · [Understanding Fuchsia Security](https://arxiv.org/pdf/2108.04183) · [NT vs UNIX security comparison](https://www.researchgate.net/publication/2511660_A_Comparison_of_the_Security_of_Windows_NT_and_UNIX) · [Cornell CS513 access control notes](https://www.cs.cornell.edu/courses/cs513/2000SP/L07.html) · [ACM/capability matrix](https://identitymanagementinstitute.org/access-control-matrix-and-capability-list/) · [Spectre-era kernel safety](https://arxiv.org/pdf/2411.18094) · [memory-corruption mitigation analysis](https://arxiv.org/pdf/2309.04119) · [CFI on Arm64 (PAC/BTI)](https://sipearl.com/wp-content/uploads/2023/10/SiPearl-White_Paper_Control_Flow_Integrity-on-Arm64.pdf) · [Apple memory integrity/MTE](https://innovation.consumerreports.org/apples-new-iphone-memory-protections-safeguards-devices-against-sophisticated-attacks/) · [DrK KASLR break](https://dl.acm.org/doi/10.1145/2976749.2978321) · [KASLR efficacy](https://medium.com/@jackrtschetter/assessing-the-efficacy-of-kaslr-and-karl-for-software-security-42ceecc97db4) · [kernel security systematic review](https://www.mdpi.com/1424-8220/26/8/2452) · [CheriBSD/Morello analysis](https://arxiv.org/pdf/2601.19074)
