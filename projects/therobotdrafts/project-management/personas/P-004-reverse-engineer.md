---
id: P-004
name: "Sven Halvorsen"
slug: "reverse-engineer"
archetype: "Reverse Engineer / Security Researcher"
segment: "secondary"
tags: [reverse-engineering, binaries, decompilation, security, source-less]
---

# Sven Halvorsen — Reverse Engineer / Security Researcher

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 30-40 |
| **Role** | Application Security Researcher |
| **Technical Level** | Expert |
| **Industry** | Security consultancy |
| **Location** | Remote, Oslo |

## Bio

Sven spends his days inside code he has no source for — third-party SDKs, vendored binaries, dependencies that ship as JARs and DLLs. He chains ILSpy, JADX, CFR, and Ghidra by hand and rebuilds the structure in his head. He wants the structure surfaced for him so he can spend his attention on the interesting parts.

## Goals

1. Lift compiled artifacts (IL, bytecode, native) back toward readable structure and models
2. Explore a source-less dependency's shape to find attack surface and trust boundaries
3. Cross-reference call paths into and out of suspicious modules

## Frustrations

1. Decompiler output is a flat pile of files with no shape
2. Switching between three decompilers for three artifact types is tedious
3. No spatial way to see how a binary's pieces relate

## Behaviors

- Runs decompilers from the CLI, greps the output
- Keeps mental maps that evaporate between sessions
- Annotates findings in external notes

## Job to Be Done

> "When I analyze a dependency I have no source for, I want it decompiled into a navigable model, so I can find the parts that matter without reconstructing the whole structure by hand."

## Relationship to Product

Sven is the source-less / binary-ingestion user. He values decompiler integration, the unified code-graph across artifact types, and tracing. He churns if decompilation is shallow, single-language, or loses cross-references.

## Scenarios

1. **SDK audit** — Sven imports a vendored JAR, lets it decompile into bubbles, and traces every path that touches the crypto module.
2. **Native dive** — He loads a stripped native binary and explores the recovered call graph to locate the parser.
