---
id: P-008
name: "Ingrid Halvorsen"
slug: ingrid-halvorsen
archetype: "The Off-Gridder"
segment: edge-case
tags: [privacy, offline-first, air-gapped, git-backup, cloud-skeptic]
---

# P-008: Ingrid Halvorsen

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 47 |
| Occupation | Independent Security Consultant |
| Location | Trondheim, Norway |
| Tech comfort | high |

## Bio
Ingrid has spent two decades in security consulting, much of it advising clients on exactly the kind of data exposure that convenience-first tools tend to introduce. She works offline or on air-gapped machines more often than most developers ever will, treats telemetry as a bug rather than a feature, and reflexively reads a tool's data-handling model before she reads its feature list. She is not anti-technology — she is precisely calibrated about what she trusts and why.

## Goals
- Run the entire product — `/query`, flashcards, quizzes, KB generation — fully offline, with zero network calls she hasn't explicitly authorized.
- Verify, not just be told, that there's no telemetry: she wants to be able to check.
- Back up and version her knowledge base and learning data using tools she already trusts — git, in her case — rather than a proprietary sync mechanism.
- Retain full local control of her data indefinitely, with no dependency on a remote service ever being reachable or even existing.

## Frustrations
- Tools that phone home "for product improvement" without a clear, auditable opt-out, or where the opt-out is trusted rather than verifiable.
- Roadmaps that treat local-first as a stepping stone to a cloud product rather than a permanent, fully-supported mode.
- Ambiguity about what data leaves the machine and when — she wants explicit, inspectable behavior, not a privacy policy she has to trust blindly.
- Any feature that silently assumes network availability and fails ungracefully (rather than clearly and locally) when offline.

## Behaviors
- Audits new tools before trusting them with real use: reads the source where available, checks for outbound network calls, and inspects config for anything resembling an API key, telemetry flag, or update-check endpoint.
- Uses `robot-learns` entirely local-first — `~/.config/the-robot-learns-kb/` lives on an air-gapped or intermittently-networked machine for a meaningful portion of her work.
- Wraps her KB directory in her own git repository for backup and history, treating version control as her trust boundary rather than any built-in sync feature.
- Deeply skeptical, publicly so, of the future therobotlearns.com cloud phase — will scrutinize any sync feature's data flow before ever enabling it, if she enables it at all.
- Values that the "backend IS Claude Code, no server" architecture is a genuine selling point to her, not marketing language, and will verify that claim holds under inspection.

## Job to Be Done
> "When I'm working with sensitive material or offline by necessity, I want a fully local, network-optional knowledge system I can inspect and back up myself, so I never have to trust a vendor's server with my data or availability."

## Relationship to Product
Ingrid is the edge-case persona who stress-tests the product's most fundamental architectural promise: that the backend genuinely is Claude Code running locally, with no server in the loop for core functionality. She is the natural adversarial reviewer of anything that touches the future cloud phase — her skepticism is a useful, if uncomfortable, signal for whether opt-in sync is designed with real data-flow transparency or just described that way. Her workflow (git-backed KB, offline operation, zero tolerance for undisclosed network calls) represents a durable segment of security-conscious and privacy-first developers who will only adopt tools that hold up under their own audit, not the vendor's assurances. Winning Ingrid's trust — and keeping it through the cloud phase rollout — is a meaningful proof point for the product's local-first claims more broadly.

## Scenarios
- **Scenario 1: The Network Audit** — Before trusting `robot-learns` with real work, Ingrid runs it on an air-gapped machine and confirms the CLI, `/query`, and KB generation all function without any network dependency beyond the Claude Code agent invocation itself — no silent background calls, no telemetry pings.
- **Scenario 2: Git as Backup** — Ingrid initializes a private git repository inside `~/.config/the-robot-learns-kb/`, committing her `knowledge/`, `flashcards/`, and `learning-plan.yaml` on her own schedule, giving her full version history and portability without depending on any vendor-provided sync.
- **Scenario 3: Evaluating Cloud Sync Skeptically** — When therobotlearns.com's sync feature ships, Ingrid reads through what data would leave her machine and under what conditions before deciding whether to enable it at all — and if the data flow isn't fully transparent and scoped, she stays local-only and says so publicly in a review.
