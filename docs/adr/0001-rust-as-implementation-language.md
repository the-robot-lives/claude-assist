# ADR-0001: Rust as implementation language

Date: 2026-07-07 · Status: accepted

## Context
A from-scratch kernel needs bare-metal control, and our architecture (framekernel, ADR-0002) depends on language-enforced isolation between privileged and unprivileged kernel code. Candidates: C, C++, Zig, Rust.

## Decision
Rust (nightly for kernel features), `no_std` in the kernel, `std` port for userland.

## Consequences
- Framekernel is only viable with an ownership-checked language — C/C++/Zig cannot statically confine unsafety, which would force a microkernel (IPC tax) or monolith (no isolation).
- Mature ecosystem: bootloader crates, smoltcp, rkyv, kani; Asterinas and Redox prove kernel-scale Rust.
- Costs accepted: nightly churn, compile times, hiring pool. Mitigation: pin toolchain per release; xtask + Nix reproducibility.
