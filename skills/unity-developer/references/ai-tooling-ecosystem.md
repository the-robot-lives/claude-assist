# Unity 6.x AI, Gameplay Packages, Multiplayer & DevOps Ecosystem

Snapshot focused on Unity 6.0/6.1/6.2 (`6000.0`/`.1`/`.2`). Verified against official package docs (June 2026). Items not re-verified live are flagged `[verify]`.

## 1. Unity AI (formerly Muse) — the big rebrand

**Critical:** Unity **consolidated Muse into "Unity AI"** integrated in the Editor as of **Unity 6.2 (6000.2)**. Standalone "Muse" branding (Chat/Sprite/Texture/Animate/Behavior) is **legacy** in 6.2+.

| Old Muse name | Current (6.2+) | Package |
|---|---|---|
| Muse Chat | **Unity AI Assistant** | `com.unity.ai.assistant` |
| Muse Sprite | **Sprite Generator** | `com.unity.ai.generators` |
| Muse Texture | **Texture2D Generator** | `com.unity.ai.generators` |
| Muse Animate | **Animation Generator** | `com.unity.ai.generators` |
| Muse Behavior | **Unity Behavior** (free, separate) | `com.unity.behavior` |
| Sentis (runtime) | **Inference Engine** | `com.unity.ai.inference` |

**Unity AI Assistant** (`com.unity.ai.assistant`, 6000.2+): in-editor generative assistant via the **AI menu**, three modes — **`/ask`** (answers/docs, read-only), **`/run`** (generates executable editor-action scripts), **`/code`** (generates/reviews C#). Metered via **credits** in the Unity Dashboard.

**Unity AI Generators** (`com.unity.ai.generators`, 6000.2+): Sprite, Texture2D, Sound (text-to-audio), Animation (text/video→clips), Material (PBR), Terrain Layer generators. Credit-metered.

**Gotchas:** consumption is credit/points-based (not flat subscription — verify numbers on unity.com); AI features are **opt-in** (accept T&Cs; some orgs disable centrally); **pre-6.2 projects (6.0/6.1) still use Muse package names** — match product name to editor version (#1 source of confusion).

## 2. Inference Engine (formerly Sentis) — on-device NN inference
`com.unity.ai.inference` v2.2.2 (rename of **Sentis**, successor to **Barracuda**; old `com.unity.sentis` superseded). Import trained models, run real-time on all platforms (incl. offline). **Model format: ONNX, opset 7–15** (unsupported ops fail at import — re-export lower opset or simplify). Backends: `BackendType.GPUCompute`, `CPU`; run via a `Worker`. Use cases: pose/gesture, NPC perception, classification/segmentation, super-resolution, small LLMs. Pairs with Unity Behavior.

## 3. Unity Behavior (formerly Muse Behavior)
`com.unity.behavior` v1.0+, **free**, GA. Visual **behavior graphs** (behavior trees with **non-linear** structure — branches can merge). **Nodes** (action/condition/flow) + **Blackboard Variables** (shared, serialized). For NPC behavior, gameplay logic, cinematic orchestration. `[verify generative authoring tie-in]`.

## 4. Gameplay & Tooling Packages

**Cinemachine 3.x** (`com.unity.cinemachine` v3.1.7) — **biggest migration headache of the Unity 6 era:**
- Namespace `Cinemachine` → **`Unity.Cinemachine`** (every `using` changes).
- `CinemachineVirtualCamera` → **`CinemachineCamera`**; `CinemachineFreeLook` replaced (orbital rig); reference base `CinemachineVirtualCameraBase` in scripts.
- Dropped **`m_` prefix** on public fields (`m_Priority` → `Priority`).
- Upgrade: (1) fix scripts to compile; (2) run **Cinemachine Upgrader** (object/scene/project); (3) manually repair script refs + Animation/Timeline bindings (class types changed). 2.x and 3.x are **mutually exclusive** in a project.

**Input System** (`com.unity.inputsystem` v1.14.2): successor to legacy Input Manager. Author **Input Actions** (action maps → actions → bindings); drive via **PlayerInput** or generated C#. **Active Input Handling** (Player settings): Old / New / **Both**. Gotcha: mixing `Input.GetKey` with the new system silently no-ops if the wrong handler is active — set **Both** during migration.

**Visual Scripting** (`com.unity.visualscripting` ~v1.9): Bolt successor, node-based Script Graphs + State Graphs (FSM). Initialize via Project Settings first. Slower than C# for hot paths.

**Splines** (`com.unity.splines` v2.7.2): `SplineContainer`, `SplineAnimate`; roads/trajectories/procedural placement.

**AI Navigation** (`com.unity.ai.navigation` v2.0.13): package replacement for the old NavMesh window. **`NavMeshSurface`** (bake areas, runtime baking), `NavMeshModifier`, `NavMeshLink`, `NavMeshObstacle`, `NavMeshAgent`. Legacy `Window → AI → Navigation` is gone — use components or builds have no navmesh.

**Other staples:** **Timeline** (cinematic/sequencing; rebind to Cinemachine 3 tracks after upgrade), **Animation Rigging** (runtime IK/constraints), **ProBuilder** (in-editor mesh modeling) + **Polybrush**, **Terrain Tools**, **Localization** (String/Asset Tables, Smart Strings, Addressables-integrated).

## 5. Multiplayer / Netcode

**Multiplayer Center** (Unity 6, built-in): `Window → Multiplayer → Multiplayer Center` — recommends a customized package/service set + Quickstart samples. The recommended on-ramp.

**Netcode for GameObjects (NGO)** (`com.unity.netcode.gameobjects` v2.x, ~2.4): GameObject networking — `NetworkObject`, `NetworkBehaviour`, **`NetworkVariable<T>`**, **RPCs** (unified `[Rpc]` attribute in 2.x), `NetworkManager`, on Unity Transport. **Distributed Authority (NEW in Unity 6):** authority/ownership distributed across clients; one **session owner** (first joiner, auto-promoted) handles global state. Lower latency, but fragmented physics + weaker anti-cheat — **not for competitive server-authoritative games**. Pairs with Multiplayer Services + a DA-capable relay.

**Netcode for Entities** (`com.unity.netcode`): DOTS/ECS netcode — server-authoritative, client prediction + interpolation, ghost snapshots. For large-scale/high-perf sims. Don't mix with NGO.

**Multiplayer Play Mode** (`com.unity.multiplayer.playmode`): up to 4 player instances from one Editor.

**Unity Gaming Services (UGS):** Relay (NAT punch-through), Lobby, Matchmaker, **Multiplayer Services SDK** (`com.unity.services.multiplayer`).

## 6. Addressables & Asset Management
**Addressables** (`com.unity.addressables` v2.x, ~2.3): built on AssetBundles + address-based load/release, automatic dependency + reference-count memory management, local/remote-agnostic. Types: `AssetReference`, Addressable Groups, content catalogs. **Cloud Content Delivery (CCD)** = UGS CDN for remote catalogs `[verify naming]`. **Gotcha:** Addressables 2.x integrates with **Build Profiles**; misconfigured remote vs local load paths → "works in editor, 404 in build."

## 7. DevOps / Workflow

| Product | Was | Notes |
|---|---|---|
| **Unity Version Control (UVCS)** | Plastic SCM | Centralized+distributed; **Gluon** (artist partial checkout) vs full workspace; CLI `cm`. |
| **Unity Build Automation** | Cloud Build | CI build farm under Unity DevOps/Cloud. |
| **Unity Cloud** | — | Umbrella dashboard (projects, DevOps, AI, builds, asset manager). |
| **Unity Test Framework** (`com.unity.test-framework`) | — | NUnit-based; EditMode + PlayMode; Test Runner. |
| **Package Manager (UPM)** | — | Registry + Git URL + local/`file:` + tarball; custom packages via `package.json` + asmdef; scoped registries for private. |

## 8. Notable Third-Party Staples
**Odin Inspector & Serializer** (supercharged inspector/serialization, near-ubiquitous in pro projects), **DOTween** (tweening), **A\* Pathfinding Project**, **UniTask** (allocation-free async/await), **Hot Reload**, **NaughtyAttributes** (free Odin-lite), **Rewired** (advanced input), **MEC** (More Effective Coroutines). TextMeshPro is now **built into Unity 6**.

## 9. Cross-Cutting Gotchas & Black Magic
- **Version naming:** Unity 6 = `6000.x` in code/CI (`6000.0`=6.0, etc.).
- **Muse vs Unity AI:** never assume Muse names on 6.2, or AI-menu names on 6.0 — match to editor version.
- **Cinemachine 2→3** is the most disruptive upgrade — always run the Upgrader; rebind Timeline/Animation.
- **Input System "Both" mode** during migration to avoid silent no-op input.
- **AI Navigation:** old Navigation window removed — bake via `NavMeshSurface` or builds have no navmesh.
- **Render pipelines** not auto-portable; custom render features need Render Graph migration.
- **Distributed Authority** ≠ secure — don't ship competitive PvP on it.
- **ONNX opset** mismatches break Inference Engine imports — keep models opset 7–15.

> Sources: live Unity docs (June 2026) — `com.unity.ai.inference@2.2`, `com.unity.behavior@1.0`, `com.unity.cinemachine@3.1`, `com.unity.ai.assistant@1.0`, `com.unity.ai.generators@1.0`, Input System 1.14, AI Navigation 2.0, Addressables 2.3, Splines 2.7, NGO 2.x. Pricing/credit specifics + exact Muse-sunset date flagged `[verify]`.
