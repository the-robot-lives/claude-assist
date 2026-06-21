---
skill: unity-developer
version: "1.0"
compatible_with:
  - claude-code
last_updated: 2026-06-21
---

# Unity Developer — Introduction

Design, build, debug, and optimize Unity projects on the **Unity 6 (`6000.x`)** feature set (2024–2026), across four domains in one skill: games (2D/3D), application/kiosk UIs, CAD/industrial visualization, and VR/AR/XR. Primary value: version-accurate engineering help that names the *current* package/API (not the deprecated one), flags what changed between editor versions, and defaults to the modern path (URP + Render Graph, UI Toolkit, Input System, Addressables, `Awaitable`). Audience is generalist — fundamentals through advanced/"black magic."

## Input Contract

```yaml
inputs:
  arguments:
    - name: task
      type: freeform
      required: true
      description: "What to build/debug/optimize, ideally with domain + target platform"
      example: "import a STEP assembly and review it in VR on Quest 3"
    - name: existing_code
      type: file-path
      required: false
      description: "C#, shader (.shader/.hlsl/.compute), UXML/USS, or .asmdef for review/debug"
      example: "Assets/Scripts/PlatformerController.cs"
    - name: editor_version
      type: string
      required: false
      description: "Unity editor version; defaults to Unity 6 (6000.x) if omitted"
      example: "6000.2.5f1"
  context_expectations:
    - "Unity 6 (6000.x) assumed unless another version is stated"
    - "Optional: an existing Unity project (Assets/, Packages/manifest.json, ProjectSettings/)"
    - "Package versions are editor-pinned — confirm in the Package Manager"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Pipeline/package decision"
      path: "inline (response)"
      format: markdown
      description: "Render pipeline + template + package list with rationale and assumed version"
    - name: "Code / shaders / UI"
      path: "Assets/** (or inline)"
      format: "C# / ShaderLab+HLSL / UXML+USS"
      description: "Scripts, Shader Graph/HLSL, ECS systems, or UI Toolkit views with matching setup steps"
    - name: "Setup instructions"
      path: "inline (response)"
      format: markdown
      description: "Exact menu paths + Inspector fields to reproduce the configuration"
    - name: "Performance diagnosis"
      path: "inline (response)"
      format: markdown
      description: "Profiler-grounded bottleneck classification + prioritized optimization plan"
    - name: "Migration plan"
      path: "inline (response)"
      format: markdown
      description: "Breaking-change identification + documented upgrade path"
  handoff:
    - skill: trl-game-design
      description: "Hand off when the question is about mechanics/balance, not engineering"
    - skill: trl-user-experience-engineer
      description: "Hand off for UX/visual design of the screens this skill builds"
    - skill: trl-metal-graphics-dev
      description: "Hand off for native Apple Metal GPU work below the Unity layer"
```

## Conventions

```yaml
conventions:
  naming:
    - "Cite the current package id (com.unity.*) and append 'verify in Package Manager' to versions"
    - "Use the current product name; note the old name in parentheses if helpful (e.g. Asset Transformer (Pixyz))"
  structure:
    - "Always run the Scope & Pipeline Decision (playbook Workflow 1) before writing code"
    - "Give exact menu paths and Inspector field names, not vague directions"
    - "Profile before optimizing; cite the specific tool"
  anti_patterns:
    - "Never use ?./??/ReferenceEquals on Unity objects (fake-null trap)"
    - "Never recommend a deprecated/EOL path as primary (Reflect, MARS, WMR, IAspect, Affordance System, Vector Graphics pkg, RaycastNonAlloc) — name the replacement"
    - "Never assume Muse names on 6.2+, or AI-menu names on 6.0"
    - "Never recommend Distributed Authority for competitive server-authoritative games"
  prerequisites:
    - "A task description; for review/debug, the relevant file must be readable"
    - "For CAD work, confirm the Unity Industry license (bundles Asset Transformer)"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|--------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it) |
| 2 (always) | `SKILL.md` | Domain map, workflow, quick starts |
| 3 (executing) | `references/agent-playbook.claude-code.md` | The 7 executable workflows |
| 4 (lookup) | `references/version-cheatsheet.md` | Versions, rebrands, deprecations, top gotchas |
| 5 (domain) | `references/{engine-core,rendering-graphics,ui-and-app-graphics,2d-development,dots-ecs-performance,xr-vr-ar,cad-industrial,ai-tooling-ecosystem}.md` | The matching domain |
| 6 (templates) | `references/worked-example-*.md` | End-to-end demonstrations to adapt |

## Quick Examples

### Start a project
`/unity-developer set up a cross-platform 2D pixel-art platformer with dynamic lighting`

### Application UI
`/unity-developer build a kiosk dashboard in Unity that binds to a live machine-status feed`

### CAD in VR
`/unity-developer get a 1.8M-part CATIA assembly into Unity for Quest 3 design review`

### Debug / optimize
`/unity-developer my game GCs 4ms/frame and has 2000 draw calls` (with scripts in context)
