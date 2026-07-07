# ADR-0004: Capability-based security model

Date: 2026-07-07 · Status: accepted

## Context
Autonomous agents will hold real authority over the machine. POSIX ambient authority (a process can touch anything its UID can) makes prompt-injection escalation catastrophic; bolt-on MAC (SELinux-style) is policy-heavy and human-hostile.

## Decision
Object capabilities as the only authority mechanism. Every resource handle is unforgeable; process/agent = code + capability bundle. Capabilities are attenuable (derive weaker), revocable (O(1) subtree kill), and journaled. Destructive Tool Bus operations are schema-marked `effectful` and staged for policy or human approval.

## Consequences
- Prompt injection cannot escalate beyond the granted bundle — the safety story for agent autonomy rests here.
- Grant UX must be excellent or users will over-grant; the approval surface is an OS-level component (Phase 5).
- No setuid, no root: administrative power is a distinguished capability set held by the local principal.
