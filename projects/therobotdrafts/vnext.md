# vnext plan for theobotdrafts HoloGraph WebGPU + Elixir web rewrite

<proposed_plan>
# HoloGraph vnexti (Elixir/3D/WebGPU) Blueprint for `projects/therobotdrafts/vnexti`

## Summary
Build a new web-native vNext app at `projects/therobotdrafts/vnexti` using Phoenix + Next.js, with a WebGPU-accelerated 3D graph renderer, collaborative patch-based drafting, remote filesystem roundtrip, and a full UX redesign. Keep model-first collaboration as the foundation and design for incremental capability growth.

## Priority sequence (implementation order)
1. Create project skeleton and repo wiring.
2. Define canonical spec-driven document model + persistence.
3. Implement Phoenix API and channels for documents, presence, and patches.
4. Ship WebGPU-first 3D baseline (nodes/edges/camera/interaction).
5. Add CRUD graph editing with authoritative patch application.
6. Add agentic drafting pipeline (spec → proposed patches → review → apply).
7. Add remote filesystem adapters (local/GitHub/Codespace).
8. Harden collaborative editing (presence, conflicts, history, undo/redo).
9. Redesign node components + full UX overhaul.
10. Add billing model + quota enforcement + observability.
11. Production hardening, templates, and onboarding polish.

## Key changes
- Create `projects/therobotdrafts/vnexti/backend` and `projects/therobotdrafts/vnexti/frontend` from `components/start-app` as the platform baseline.
- Add backend domains: `Docs`, `Graph`, `Draft`, `Agents`, `Billing`.
- Add document/version data model: `projects`, `graph_documents`, `graph_document_versions`, `collab_events`, `billing_events`.
- Implement API routes:
  - `POST /api/v1/docs`
  - `GET /api/v1/docs/:id`
  - `POST /api/v1/docs/:id/patches`
  - `POST /api/v1/docs/:id/export`
  - `POST /api/v1/agents/draft`
- Add Phoenix channel `graph:doc:*` with events:
  - `doc:join`, `doc:leave`
  - `patch:apply`, `patch:reject`
  - `cursor:move`, `presence:state`
- Add frontend renderer abstraction `IRenderer` over Babylon.js WebGPU (with swap points for raw WebGPU later):
  - batched instances, GPU selection IDs, camera controls, LOD labels, node + edge pipelines, depth-based UI.
- Add roundtrip interface `RoundtripProvider` with adapters:
  - `LocalFSAdapter`, `GitHubAdapter`, `CodespaceAdapter`.
- Implement node redesign:
  - node families, typed ports, clearer labels, glow/depth contrast, rail-based actions, mini-map, recenter/orientation lock.
- UX first screen map:
  - project home, 3D canvas, collaboration strip, AI drafting sidepanel, history/version HUD, command palette.
- Implement billing:
  - free tier and Pro/Team gating, AI usage metering, document/seat/AI caps, and overage behavior.

## Test plan
- Unit/property tests for patch application and conflict resolution.
- Channel integration tests for join/apply/reject lifecycle and presence sync.
- Render/perf checks on 1k and 10k node scenes (fps budget, frame drops, input latency).
- Adapter contract tests for local and GitHub roundtrip providers.
- AI draft path tests: malformed patch rejection, idempotent apply, cancel/timeout.
- E2E path: spec drafting → draft review → collaborative apply → export.

## Assumptions and defaults
- Render stack default: WebGPU-first with Babylon.js.
- Collaboration model default: spec-first CRDT-like patch model over Phoenix channels.
- Billing default: freemium + AI usage metering.
- `tobor-sessions` MCP was not discoverable in this environment; session registration is pending when tool access is available.
- `projects/therobotdrafts/vnext` is currently empty; this plan targets `vnexti` as the new implementation line.
</proposed_plan>
