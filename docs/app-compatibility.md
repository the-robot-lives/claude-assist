# Foreign Application Compatibility: Linux, Windows, macOS

Status: v0.1 · 2026-07-07 · Unified plan for running foreign-OS applications on fast-os. Linux syscall-level detail lives in [posix-compatibility.md](posix-compatibility.md); this doc adds the Windows and macOS strategies and the tiering that binds them.

## 1. The stack: translate where proven, virtualize where not

Field evidence sets the strategy. Wine proves API *translation* works at production quality for Windows apps — it maps Win32 calls onto POSIX at near-native speed and is mature ([WineHQ](https://www.winehq.org/), [Wine 11, Jan 2026](https://www.helpnetsecurity.com/2026/01/14/wine-11-released/)). Darling proves the same approach for macOS is *not* mature — a decade in, it runs CLI apps and very few GUI apps ([darlinghq](https://www.darlinghq.org/), [GitHub](https://github.com/darlinghq/darling), [LWN](https://lwn.net/Articles/794871/)). So: translation layers for Linux and Windows; virtualization as both the macOS answer and the universal escape hatch.

```
tier 0  native fast-os apps            rings + capabilities (full speed)
tier 1  Linux apps                     linux-personality libOS
tier 2  Windows apps                   wine-class layer ON TOP of tier 1
tier 3  any OS incl. macOS             microVM guests + integration bridge
```

Every tier is capability-bound: foreign apps get a personality/VM capability bundle; nothing foreign ever holds native ambient authority.

## 2. Tier 1 — Linux (the keystone)

Per [posix-compatibility.md](posix-compatibility.md): libOS personality, Loupe-measured syscall tiers, synthesized FHS view. Everything below leans on this tier, which is why it's Phase 3 and the others aren't.

## 3. Tier 2 — Windows: Wine on the personality, not a Wine port

Wine already targets POSIX; porting it to fast-os's native API would mean maintaining a fork forever. Instead, **run Wine inside linux-personality** — Wine is simply the harshest Linux application in our Loupe target set. Windows apps then stack: Win32 → Wine → personality → rings.

- What Wine needs from the platform is well-documented by its own evolution: correct futex/poll semantics, mmap richness, and — per Wine 11's headline — **NT-style synchronization primitives** (NTSYNC kernel support materially improves correctness/perf; [Wine 11](https://www.gamingonlinux.com/2026/01/windows-compatibility-layer-wine-11-arrives-bringing-masses-of-improvements-to-linux/)). Design win available: fast-os can expose NT-semantics wait objects natively via ring waits, and the personality forwards ntsync ioctls to them — better-than-Linux Wine hosting is achievable because we don't retrofit.
- WoW64-complete Wine 11 means one 64-bit personality suffices for 32-bit Windows apps ([Wine 11 notes](https://www.helpnetsecurity.com/2026/01/14/wine-11-released/)) — keeps our 64-bit-only rule intact.
- Graphics: Wine's Vulkan path (DXVK/vkd3d) maps onto our Vulkan-first GPU stance (tech-choices) once the display server exists; until then, Windows CLI/service apps only.
- Agent integration: Wine processes are personality processes — flight-recorded, budgeted, staged-effects like everything else.

## 4. Tier 3 — macOS: honesty required

Translation is not a viable plan of record: Darling remains early-stage for GUI ([status](https://www.darlinghq.org/)), Apple Silicon-era binaries (arm64e, tightly coupled frameworks, notarization) raise the wall further ([darling#1762](https://github.com/darlinghq/darling/issues/1762)), and **Apple's EULA licenses macOS only on Apple hardware** — a legal constraint no engineering fixes.

Plan of record:

- **macOS CLI tools** (open-source builds: llvm, swift toolchains): where a Linux build exists, use tier 1 — most "macOS apps" people need on a dev box are actually cross-platform.
- **Darling-on-personality** as an experimental community lane (same trick as Wine — Darling targets Linux), CLI-scope expectations, no roadmap commitment.
- **On Apple hardware** (our ARM64 flagship target *is* Apple-class): tier-3 macOS guest VMs are the legally clean, functionally complete answer — fast-os as host, macOS virtualized where the EULA permits. GPU/paravirt quality gates this.

## 5. Tier 3 generally — microVMs as the universal fallback

Firecracker-style microVMs (see [performance-research.md](performance-research.md) §5: sub-ms unikernel boots, ms-class Linux guests) make "just run the real OS" cheap:

- Per-app Linux guests for the personality's long tail (weird kernel-module-touching software), Windows guests for anti-cheat/driver-entangled apps Wine can't carry, macOS guests on Apple hardware.
- **Integration bridge**: a guest agent exports the guest's apps onto the Tool Bus (windows/filesystems/clipboard as capability-scoped tools), so tier-3 apps still participate in the agent-native surface — UFO²-style control of foreign GUIs without pretending they're native.

## 6. Compatibility decision matrix

| Workload | Path | Expectation |
|---|---|---|
| Linux CLI/server (git, postgres, node) | tier 1 | good perf, full isolation |
| Linux GUI | tier 1 + display server (post-Phase 6) | deferred |
| Windows CLI/services | tier 2 | after tier-1 maturity |
| Windows GUI/games | tier 2 + Vulkan display stack; tier 3 for driver-entangled | post display server |
| macOS open-source CLI | tier 1 (Linux builds) | now-path |
| macOS GUI / proprietary | tier 3 VM on Apple hardware only | legal + paravirt gated |
| Kernel-coupled anything | tier 3 | by design |

## 7. Roadmap hooks

Phase 3: tier 1 v0 (as planned). Phase 5: NT-sync native wait objects land with agentd's wait machinery (shared plumbing). Phase 6: Wine-in-personality target-set entry; microVM host support (KVM-class) — also required by [roadmap-distribution.md](roadmap-distribution.md) S4. Post-D2: display server unlocks GUI tiers; macOS guest evaluation on Apple hardware.

Sources: [WineHQ](https://www.winehq.org/) · [Wine (Wikipedia)](https://en.wikipedia.org/wiki/Wine_(software)) · [Wine 11 release](https://www.helpnetsecurity.com/2026/01/14/wine-11-released/) · [Wine 11 on GamingOnLinux](https://www.gamingonlinux.com/2026/01/windows-compatibility-layer-wine-11-arrives-bringing-masses-of-improvements-to-linux/) · [Darling](https://www.darlinghq.org/) · [darling GitHub](https://github.com/darlinghq/darling) · [Darling LWN](https://lwn.net/Articles/794871/) · [darling#1762 (Apple Silicon)](https://github.com/darlinghq/darling/issues/1762)
