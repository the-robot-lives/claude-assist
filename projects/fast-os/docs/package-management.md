# Package Management: `fpkg`

Status: v0.1 · 2026-07-07 · Design for fast-os software installation: verified and reproducible from the first byte, capability-aware, and able to install Windows/macOS/Linux packages into the compat and VM tiers. Builds on [security.md](security.md), [fastfs-design.md](fastfs-design.md), and [app-compatibility.md](app-compatibility.md).

## 1. Principles

1. **Verified bits from the start** — nothing executes that isn't content-addressed and signature-checked against a policy-trusted key. This is a boot-time-through-runtime invariant, not an install-time check.
2. **Reproducible** — a package is a pure function of its inputs; same inputs → identical output hash. Enables SBOMs, provenance, and binary-transparency by construction.
3. **Capability-declared** — every package ships a manifest of the capabilities it needs; install surfaces them, runtime enforces them. No package gets ambient authority ([security.md](security.md) §1).
4. **Atomic & reversible** — installs/upgrades are fastfs snapshot transitions; rollback is instant.

## 2. Model: content-addressed store (Nix-validated, hardened)

Adopt the proven core of the Nix model — packages installed into immutable store paths named by a cryptographic hash of *all* their inputs, so dependencies are exact and installs are atomic and reproducible ([Nix](https://nixos.org/), [Wikipedia](https://en.wikipedia.org/wiki/Nix_(package_manager))). Nix already demonstrates this is the foundation for demonstrably secure supply chains: provenance, determinism, and dependency bookkeeping baked into the build graph, so SBOMs are exact rather than inferred ([secure supply chain with Nix](https://nixcademy.com/posts/secure-supply-chain-with-nix/), [JFrog](https://jfrog.com/learn/devops/nix/)).

fast-os specifics:

- **Store = a fastfs subvolume**, one immutable, checksummed path per (name, version, input-hash). Sharing and dedup are free (CoW); GC reclaims unreferenced paths. Store paths are mounted read-only and merkle-verified ([security.md](security.md) §3) — corruption or tampering is detected on read, not just install.
- **Profiles/Scenes reference store paths**; there is no global mutable `/usr`. A [Scene](design/shell.md) or user profile is a set of references; switching or rolling back is a pointer swap + reboot-free re-link.
- **No install scripts with ambient power.** Nix's real-world weak point is imperative privilege-escalation paths and post-install hooks ([Snyk NixOS deep-dive](https://labs.snyk.io/resources/nixos-deep-dive/)); fast-os packages declare effects instead — any privileged action at install is a staged, capability-checked Tool Bus operation, never an arbitrary root script.

## 3. Verified bits: the trust chain

End to end, every layer checks the one below:

1. **Signing (Sigstore-class)**: each artifact carries a provenance attestation cryptographically linking published package → exact source commit → build system that produced it ([Sigstore/SLSA guide](https://blogs.pavanrangani.com/supply-chain-security-slsa-sigstore-guide/), [Sigstore supply chain](https://oneuptime.com/blog/post/2026-01-25-sigstore-supply-chain-security/view)). Keyless signing with transparency-log inclusion is the target.
2. **SLSA provenance** as a hard gate: `fpkg` refuses artifacts below the policy's required SLSA level; provenance is generated from the reproducible build graph, so "which code got in" is unambiguous ([SLSA model](https://blogs.pavanrangani.com/supply-chain-security-slsa-sigstore-guide/)).
3. **Policy-trusted keys** (`authd`, [security.md](security.md) §1.2): which signers/roots are acceptable is a policy decision per namespace — the org channel, the community channel, and the user's own key each have distinct trust. Deny rules and conditions apply (e.g. "no unsigned packages ever", "AI-model blobs require the ML-team key").
4. **Runtime re-verification**: because store paths are merkle-verified fastfs and W^X is absolute ([security.md](security.md) §2), a package verified at install can't be silently swapped later — the bits are re-checked on execution. This is the "verified from the start" invariant: measured boot → signed kernel → verified store → capability-gated execution form one unbroken chain.
5. **Binary transparency**: the transparency log makes install-time equivocation detectable — you can prove the artifact you got is the one everyone got.

## 4. Capability manifests

Every package declares, in its manifest: the Tool Bus interfaces it needs, filesystem subtrees, network host-sets, device classes, and whether it requests `effectful` privileges. `fpkg install` renders this as the same plan-preview/approval surface as everything else ([design/installer.md](design/installer.md), [agent-integration.md](agent-integration.md) §4) — you see exactly what a package may touch *before* it lands, and the grant is what the runtime enforces. A CLI tool that asks for the camera is visible and refusable at install; a compromised update that suddenly wants network egress trips a re-approval.

## 5. Cross-platform: install Windows / macOS / Linux packages

The compat and VM tiers ([app-compatibility.md](app-compatibility.md)) are real install targets, and `fpkg` is the single front-end that drives foreign package managers inside them — the way Homebrew Bundle already orchestrates formulae, casks, WinGet, and Flatpak from one Brewfile ([Homebrew everywhere](https://brew.sh/), [Homebrew + Flatpak](https://www.webpronews.com/homebrew-5-0-4-update-adds-flatpak-support-for-cross-platform-apps/), [brew/winget automation](https://justinjbird.com/blog/2026/installing-tools-using-homebrew-or-winget/)).

```
fpkg install linux:postgresql     → apt/Flatpak inside linux-personality (tier 1)
fpkg install win:notepad++        → winget inside Wine-on-personality (tier 2)
fpkg install mac:some-cli         → Homebrew inside a macOS guest (tier 3, Apple HW)
fpkg install win:some-game        → winget inside a Windows microVM (tier 3)
```

Design of the bridge:

- **Backends** behind one interface: `apt`, `Flatpak`, `winget`, `Homebrew` each wrapped as an `fpkg` provider that runs inside the appropriate tier's personality/guest and reports results back on the Tool Bus. Homebrew's cross-platform Brewfile model (WinGet-on-WSL, Flatpak, casks, Cargo, Mac App Store in one manifest — [brew.sh](https://brew.sh/)) is the direct precedent that this is tractable.
- **Verification at the boundary**: foreign packages can't meet fast-os's SLSA/Sigstore bar, so they are installed into a **tier-scoped, capability-boxed** subvolume — a `win:` app gets a Windows-app capability bundle and nothing native. Trust is contained by the tier, not extended to the host. The foreign manager's own signature checks (winget hash/cert, apt GPG, Flatpak GPG) are required and surfaced, but treated as *tier-internal* assurance, not host trust.
- **Uniform manifest**: a single `Scene.pkgs` / profile manifest lists native + `linux:` + `win:` + `mac:` entries together, so "reload this Scene" ([design/shell.md](design/shell.md) §1) re-provisions foreign apps into their tiers exactly like native ones. Declarative, reproducible where the backend allows, capability-boxed always.
- **One agent surface**: `fpkg` operations are Tool Bus calls, so the [Bar's](design/shell.md) intent lane ("install the linux build of postgres") plans a real, previewable `fpkg` action with visible capabilities and tier placement.

## 6. UX

Native: `fpkg add <name>` (search → capability preview → staged install → snapshot). No separate "update the index" step — the channel is a live, verifiable feed. Rollback: `fpkg rollback` swaps the profile pointer. The [Bar](design/shell.md) is the graphical front-end; capability approval reuses the trusted overlay.

## 7. Sequencing

Phase 3: content-addressed store on fastfs, signature verification, native `fpkg`, capability manifests. Phase 4: SLSA-gate + transparency log, binary re-verification tie-in. Phase 5: cross-platform bridge (`linux:` first, then `win:` via Wine tier), intent-lane integration. Phase 6+: `mac:`/VM backends, org/community channel policy tooling.

## 8. Deliberately rejected

Mutable global prefix (`/usr`, registry) — breaks atomicity and verification; unsigned/AUR-style arbitrary build scripts with root — the exact ambient-authority hole the whole design closes; trusting foreign package signatures as host trust — contained to tiers instead.

Sources: [Nix](https://nixos.org/) · [Nix (Wikipedia)](https://en.wikipedia.org/wiki/Nix_(package_manager)) · [secure supply chain with Nix](https://nixcademy.com/posts/secure-supply-chain-with-nix/) · [JFrog on Nix](https://jfrog.com/learn/devops/nix/) · [Snyk NixOS deep-dive](https://labs.snyk.io/resources/nixos-deep-dive/) · [SLSA + Sigstore guide](https://blogs.pavanrangani.com/supply-chain-security-slsa-sigstore-guide/) · [Sigstore supply chain](https://oneuptime.com/blog/post/2026-01-25-sigstore-supply-chain-security/view) · [npm supply-chain 2026](https://mondoo.com/blog/npm-supply-chain-security-package-manager-defenses-2026) · [Homebrew](https://brew.sh/) · [Homebrew + Flatpak](https://www.webpronews.com/homebrew-5-0-4-update-adds-flatpak-support-for-cross-platform-apps/) · [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/) · [brew/winget automation](https://justinjbird.com/blog/2026/installing-tools-using-homebrew-or-winget/)
