# fast-os Agent & LLM Integration Design

Status: draft v0.1 · 2026-07-07

Prior art ([AIOS](https://arxiv.org/pdf/2403.16971), Microsoft's [UFO²](https://arxiv.org/pdf/2504.14603), [Agent libOS](https://arxiv.org/pdf/2606.03895)) builds agent runtimes *on top of* an existing OS. fast-os inverts this: the OS itself provides the scheduler, context manager, tool layer, and access control that those projects re-implement in userspace. An agent on fast-os is an OS-managed entity, like a process.

## 1. The agent as a kernel-visible object

New first-class object type: **agent task** — (goal, model binding, capability bundle, context handle, budget). Created via `agentd`, tracked by the kernel like a process group. Properties:

- **Budgeted**: token, energy, and wall-clock budgets enforced by the kernel scheduler, not by convention. Exhaustion suspends the task and notifies its principal.
- **Suspendable/resumable**: the context handle (conversation state + KV cache) is a checkpointable resource. Suspend an agent mid-task, resume days later — same semantics as process freeze.
- **Delegatable**: agent tasks spawn sub-tasks with attenuated capabilities and sub-budgets (tree accounting, like cgroups).

## 2. inferd — inference as a system service

One privileged service owns model execution, analogous to a display server owning the GPU:

- **Model residency manager**: weights are memory-mapped, shared, and reference-counted across all consumers. Loading policy (which models stay hot on NPU/GPU/RAM) is centralized — no per-app model duplication.
- **Backends**: pluggable execution providers — CPU (GGML-style quantized kernels), GPU (Vulkan compute), NPU (per-SoC providers; Hexagon and OpenVINO-class backends are now proven upstream in llama.cpp, validating this layering).
- **Request classes**: `interactive` (streaming decode, latency SLO, scheduler deadline hints), `batch` (embeddings, background summarization), `reflex` (tiny always-resident model, <50 ms budget — powers intent parsing and UI assist).
- **Continuous batching** across all clients; KV-cache paging cooperates with the kernel semantic-memory tier.
- Local-first; remote endpoints (Anthropic/OpenAI-compatible) are just another backend behind the same ring API, gated by an explicit network capability.

## 3. Semantic memory (memoryd + kernel tier)

Context is a resource, managed like memory:

- **Context handles**: kernel-tracked objects holding conversation state, KV cache pages, and retrieval indexes. Copy-on-write forking (branch a conversation), snapshot/restore, TTL policies.
- **System memory graph**: a structured store of embeddings + facts about *this machine and its user* (installed tools, project locations, recurring tasks, preferences). Capability-gated per namespace; apps contribute facts through typed APIs, agents query it instead of grepping the filesystem.
- **Eviction economics**: KV pages carry recompute cost estimates; the kernel evicts cheapest-to-recompute first, spills to NVMe second.

## 4. Authority: capabilities + audit

Autonomous execution is safe iff authority is scoped and observable:

- Every agent task runs with an explicit capability bundle — files by subtree, network by host set, Tool Bus interfaces by schema, budgets. **No ambient authority; prompt injection cannot escalate what the kernel never granted.**
- **Two-phase effects**: destructive Tool Bus operations (delete, send, pay, deploy) are declared in schemas as `effectful`; agentd stages them and requires either a standing policy grant or interactive human approval. Approval UI is an OS surface, not per-app.
- **Flight recorder**: every inference call, tool call, and capability exercise by an agent task is appended to a per-task journal on fastfs (CoW snapshots make this cheap). `fast replay <task>` reconstructs exactly what an agent did and why. Journals are the substrate for debugging, trust, and later fine-tuning.

## 5. Tool Bus: the OS is the MCP server

Every service/driver interface (architecture.md §6) is exported as a typed, self-describing tool schema:

- Discovery: `toolbusd` serves the schema registry; agents enumerate what this machine can do, filtered to their capabilities.
- Zero glue: no per-app MCP servers for OS functions — files, processes, network, packages, displays, audio are native tools.
- External MCP servers mount *onto* the bus as leaf namespaces, so third-party tools and OS tools are uniform.
- GUI apps built on the fast-os UI toolkit get their actions auto-exported (menu/command = tool), giving UFO²-style app control without screenshot scraping.

## 6. Human interface: intent everywhere

- **fsh**: each input line is classified by the reflex model (<50 ms): exact command → execute; intent phrase → plan preview (the *actual* Tool Bus calls it will make, with capabilities highlighted) → confirm or auto-run per policy. History is semantic — "that thing I did to the postgres pod last week" resolves.
- **System copilot**: a standing, low-budget agent task with read-mostly capabilities: explains errors, watches logs, proposes fixes as staged effects. It's an unbundled feature of the OS, removable like any service.
- **Escalation ladder**: reflex model → local mid-size model → remote frontier model, chosen per request by cost/latency policy. Users see and set the policy.

## 7. Performance notes (why this belongs in the OS)

- Ring-based syscalls make tool call round-trips ~µs; agent loops issue thousands of small ops.
- Shared model residency removes the N×weights RAM tax that plagues per-app inference today.
- Kernel-scheduled decode (deadline hints) keeps token streams smooth under load — impossible to guarantee from userspace.
- Context handles avoid re-prefill on agent resume — the single biggest latency cost in today's stacked runtimes.

## 8. Open questions (tracked as future ADRs)

Model-format commitment (GGUF vs. proprietary per-NPU blobs); whether memoryd's embedding index lives in-kernel or userspace; multi-user semantics for the system memory graph; secure attestation of which model produced which action.
