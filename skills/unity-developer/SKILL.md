---
name: unity-developer
description: >
  Design, build, debug, and optimize Unity applications across games (2D and 3D),
  application/kiosk UIs, CAD/industrial visualization, and VR/AR/XR — using current
  Unity 6 (6000.x) features, packages, and APIs. Use this skill when the user wants
  to build a Unity game or app, choose a render pipeline (URP/HDRP), write C#
  MonoBehaviour/ScriptableObject/ECS code or shaders (Shader Graph/HLSL/compute),
  build UI in UI Toolkit or uGUI, set up 2D (tilemaps, 2D lights, sprite rigging,
  Box2D v3), import CAD models (STEP/CATIA/etc. via Pixyz/Asset Transformer), build
  digital twins or design-review apps, set up VR/AR (OpenXR, XR Interaction Toolkit,
  Quest, Apple Vision Pro/PolySpatial, AR Foundation), use DOTS/ECS/Burst/Jobs,
  profile performance, manage Addressables, or migrate across Unity breaking changes
  — even if they don't say "Unity." Also trigger when users mention Unity 6, URP,
  HDRP, Render Graph, UI Toolkit, UXML/USS, Shader Graph, DOTS, ECS, Burst, XRI,
  PolySpatial, Pixyz, Asset Transformer, Cinemachine, Netcode for GameObjects,
  Sentis/Inference Engine, Unity AI/Muse, Addressables, or GameObject/Prefab work.
---

# Unity Developer

Build, debug, and optimize Unity 6.x projects across game (2D/3D), application/UI, CAD/industrial, and VR/AR/XR — with version-accurate APIs and current package names.

## Overview

This skill is a generalist Unity engineering companion grounded in the **Unity 6 (`6000.x`)** feature set as of 2024–2026. It gives version-correct guidance (current package names, not deprecated ones), names the API that actually exists in your editor, and flags what changed between versions. It spans four domains in one place so a project that mixes them (e.g. a CAD model reviewed in VR, or a game with an application-grade settings UI) is handled coherently.

**Core Purpose:**
- **Decide** the render pipeline, project template, and packages from requirements.
- **Build** game 2D/3D systems, application/kiosk UIs, CAD ingestion pipelines, and XR experiences with concrete setup steps and code.
- **Write** C# (MonoBehaviour/ScriptableObject/ECS), shaders (Shader Graph/HLSL/compute), and UI (UXML/USS + data binding).
- **Profile & optimize** CPU/GPU/GC/draw-calls/build-size with the right tool for the symptom.
- **Migrate** across Unity 6 breaking changes (Render Graph, Cinemachine 3, Muse→Unity AI, AI Navigation, Input System).
- **Stay current** — name the rebrand (Pixyz→Asset Transformer, Sentis→Inference Engine, Plastic→UVCS) and avoid EOL paths (Reflect, MARS, WMR).

## Core Philosophy

1. **Version accuracy over folklore.** Unity rebrands and breaks things fast. Always state the assumed editor version, name the *current* package/API, and append "verify in Package Manager" to version numbers — they are editor-pinned.
2. **Modern path first.** Default to URP + Render Graph, UI Toolkit for app UI, Input System, Addressables, and `Awaitable`. Name the legacy alternative only when it is genuinely required, and say why.
3. **Measure before optimizing.** Every performance recommendation starts from a Profiler/Frame Debugger/Memory Profiler capture, not intuition.
4. **Respect the fake-null trap and the platform reality.** Unity's overloaded `==`, IL2CPP stripping, GC behavior, and mobile/XR constraints are first-class concerns, not afterthoughts.
5. **Domain-coherent, not domain-siloed.** A CAD-in-VR app or a game-with-app-UI is one project — pipeline and package choices are made holistically.

## When to Use This Skill

- **Starting a Unity project** — choosing pipeline (URP/HDRP/BiRP), template, and packages.
- **Game development** — 2D (tilemaps, 2D lights, sprite rigging, Box2D v3, pixel-perfect) or 3D (rendering, lighting, physics, animation, Cinemachine).
- **Application / kiosk / dashboard UI** — UI Toolkit (UXML/USS + data binding) or uGUI, scaling, localization, accessibility.
- **CAD / industrial visualization** — importing STEP/CATIA/etc. via Asset Transformer (Pixyz), dataprep for massive assemblies, digital twins, design review.
- **VR / AR / MR** — OpenXR, XR Interaction Toolkit 3.x, Quest, Apple Vision Pro (PolySpatial), AR Foundation, XR performance.
- **Performance & scale** — DOTS/ECS/Burst/Jobs, GC/draw-call/build-size optimization, profiling.
- **Migration & upgrades** — Unity 6 breaking changes, deprecated-API replacement.

> For native Apple GPU programming outside Unity, see **trl-metal-graphics-dev** (`references/shaders/msl-reference.md`).
> For game design (mechanics, systems, balance) rather than engineering, see **trl-game-design**.
> For application UX/visual design of the screens this skill builds, see **trl-user-experience-engineer**.

## Domain Map

| Domain | Primary reference | Default pipeline | Key modern API |
|--------|-------------------|------------------|----------------|
| Engine, scripting, project setup | `engine-core.md` | — | Awaitable, ScriptableObjects, asmdefs, Build Profiles |
| 3D rendering & graphics | `rendering-graphics.md` | URP / HDRP | Render Graph, APV, GPU Resident Drawer, STP |
| Application / UI graphics | `ui-and-app-graphics.md` | URP | UI Toolkit + runtime data binding |
| 2D games | `2d-development.md` | URP (Universal 2D) | 2D Renderer, Box2D v3, Tilemap, 2D Animation |
| Performance / DOTS | `dots-ecs-performance.md` | — | ECS (`ISystem`), Burst, Jobs, Addressables |
| VR / AR / XR | `xr-vr-ar.md` | URP | OpenXR, XRI 3.x, AR Foundation, PolySpatial |
| CAD / industrial | `cad-industrial.md` | HDRP (desktop) / URP (XR) | Asset Transformer, GPU Occlusion Culling |
| AI / tooling / multiplayer / DevOps | `ai-tooling-ecosystem.md` | — | Unity AI, Inference Engine, NGO 2.x, Cinemachine 3 |

## Workflow

```
Scope & pipeline decision  →  Domain setup  →  Implement (C#/shader/UI/dataprep)
        │                          │                      │
        ▼                          ▼                      ▼
  engine-core +            domain reference +     worked examples as
  version-cheatsheet       agent-playbook         templates
                                   │
                                   ▼
                    Profile  →  Optimize  →  Migrate (if upgrading)
```

The agent always runs the **Scope & Pipeline Decision** first (Workflow 1 in the playbook), then branches to the domain workflow, then loops through profiling/optimization. See [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) for the seven executable workflows.

## Quick Start Guides

### Build a Unity game (2D or 3D)
1. Run the scope/pipeline decision — 2D → **Universal 2D**, 3D cross-platform → **URP**, AAA-fidelity → **HDRP**.
2. For 2D, follow [2d-development.md](references/2d-development.md) + [worked-example-2d-lit-platformer.md](references/worked-example-2d-lit-platformer.md).
3. For 3D rendering/lighting, see [rendering-graphics.md](references/rendering-graphics.md).
4. Wire input (Input System), camera (Cinemachine 3), and assets (Addressables) per [ai-tooling-ecosystem.md](references/ai-tooling-ecosystem.md).
5. Profile per [dots-ecs-performance.md](references/dots-ecs-performance.md) before optimizing.

### Build an application / kiosk / dashboard UI
1. Confirm screen-space app UI → **UI Toolkit (runtime)** (see the TL;DR table in [ui-and-app-graphics.md](references/ui-and-app-graphics.md)).
2. Scaffold UIDocument + PanelSettings + UXML/USS; bind a view-model with `INotifyBindablePropertyChanged` + `[CreateProperty]`.
3. Follow [worked-example-app-ui-dashboard.md](references/worked-example-app-ui-dashboard.md) end-to-end.

### Bring CAD into Unity / build a digital twin
1. Confirm the **Unity Industry** license (bundles Asset Transformer) — see [cad-industrial.md](references/cad-industrial.md).
2. Run the **six-phase dataprep** (Import → Heal → Stage → Optimize → LODs → Export).
3. Render at scale with GPU Resident Drawer + Occlusion Culling. For VR review, follow [worked-example-cad-vr-review.md](references/worked-example-cad-vr-review.md).

### Set up VR / AR
1. Enable the provider (OpenXR/ARKit/ARCore/visionOS) in XR Plug-in Management.
2. Add XR Origin + XRI Starter Assets; use the Near-Far Interactor + mediated locomotion.
3. Apply XR performance (single-pass stereo, MSAA, foveation). See [xr-vr-ar.md](references/xr-vr-ar.md).

### Upgrade / fix a breaking change
1. Identify the symptom in the migration table ([version-cheatsheet.md](references/version-cheatsheet.md)).
2. Apply the documented path (e.g. Cinemachine Upgrader, Render Graph `RecordRenderGraph`, Muse→Unity AI rename).

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Any Unity project / scripting / setup** | `engine-core.md`, `version-cheatsheet.md` |
| **3D rendering, shaders, lighting, post** | `rendering-graphics.md` |
| **App/kiosk/dashboard UI, UXML/USS, binding** | `ui-and-app-graphics.md`, `worked-example-app-ui-dashboard.md` |
| **2D game (tilemaps, 2D lights, sprites, physics)** | `2d-development.md`, `worked-example-2d-lit-platformer.md` |
| **Performance, DOTS/ECS, Burst, build size** | `dots-ecs-performance.md` |
| **VR/AR/MR setup and performance** | `xr-vr-ar.md` |
| **CAD import, dataprep, digital twins, Industry license** | `cad-industrial.md`, `worked-example-cad-vr-review.md` |
| **AI features, Cinemachine, netcode, Addressables, DevOps** | `ai-tooling-ecosystem.md` |
| **What is this called now / what version / what breaks** | `version-cheatsheet.md` |
| **Executing a task as an agent** | `agent-playbook.claude-code.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-metal-graphics-dev** — native Apple Metal GPU programming (lower-level than Unity).
- **trl-game-design** — game mechanics, systems, and balance (the *what*, vs this skill's *how*).
- **trl-user-experience-engineer** — UX and visual design of application screens.
- **trl-ios-mobile-engineer** / **trl-android-mobile** — native mobile shells, store deployment, Unity-as-a-Library embedding.
- **trl-technical-writer** — documenting the systems and tools this skill builds.

## Bundled Resources

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role + 7 executable workflows (scope, app UI, 2D, XR, CAD, performance, migration).
- [engine-core.md](references/engine-core.md) — Versioning/LTS, licensing, project setup, scripting idioms, engine-level gotchas.
- [rendering-graphics.md](references/rendering-graphics.md) — Pipelines, Render Graph, shaders, lighting/APV, post/upscaling, batching/profiling.
- [ui-and-app-graphics.md](references/ui-and-app-graphics.md) — UI Toolkit + data binding, uGUI, app/kiosk concerns, localization, accessibility (priority domain).
- [2d-development.md](references/2d-development.md) — 2D renderer, lights/shadows, tilemaps, sprite tooling/animation, Box2D v3, pixel-perfect (priority domain).
- [dots-ecs-performance.md](references/dots-ecs-performance.md) — DOTS/ECS, Burst/Jobs, GC/pooling/profiling, IL2CPP/stripping, Addressables.
- [xr-vr-ar.md](references/xr-vr-ar.md) — XR plugin architecture, XRI 3.x, hand tracking, AR Foundation, PolySpatial, Quest, VR performance.
- [cad-industrial.md](references/cad-industrial.md) — Unity Industry, Asset Transformer (Pixyz), CAD formats, six-phase dataprep, digital twins, rendering at scale (priority domain).
- [ai-tooling-ecosystem.md](references/ai-tooling-ecosystem.md) — Unity AI/Muse, Inference Engine, Behavior, Cinemachine 3, Input System, netcode, Addressables, DevOps.
- [version-cheatsheet.md](references/version-cheatsheet.md) — Version decoder, rebrand map, deprecations, package versions, top cross-domain gotchas.
- [worked-example-2d-lit-platformer.md](references/worked-example-2d-lit-platformer.md) — End-to-end 2D lit pixel-art platformer.
- [worked-example-app-ui-dashboard.md](references/worked-example-app-ui-dashboard.md) — End-to-end kiosk dashboard with UI Toolkit + data binding.
- [worked-example-cad-vr-review.md](references/worked-example-cad-vr-review.md) — End-to-end CAD-to-Quest-VR design-review app.

### Assets
- [project-setup-checklist.md](assets/project-setup-checklist.md) — New-project decision + setup checklist (pipeline, packages, VCS, build).
- [performance-audit-checklist.md](assets/performance-audit-checklist.md) — Profiling-first optimization checklist by bottleneck class.
- [project-tracker.md](assets/project-tracker.md) — Track a Unity build's milestones, decisions, and open risks.
