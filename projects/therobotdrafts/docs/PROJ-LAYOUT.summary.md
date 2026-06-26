# Project Layout (Summary) — The Robot Draft

Tree-only companion to [PROJ-LAYOUT.md](PROJ-LAYOUT.md). Keep in sync on structural changes.

```
therobotdrafts/
├── Assets/                     # Unity source (committed)
│   ├── Scripts/                #   C# source
│   │   ├── Authoring/          #     UI-agnostic core (Model/Commands/Rules/State/Seams)
│   │   ├── CodeGen/            #     code/wireframe ↔ model bridge (skeleton/parse/highlight/salt+HTML)
│   │   ├── Llm/                #     OpenAI-compatible endpoint client
│   │   ├── Styleguide/         #     Noizu styleguide theme engine (resolver/token-eval/yaml-lite)
│   │   ├── Uml/                #     2D UML editor harness (UmlCanvas partials + node/edge views)
│   │   ├── Uml3D/              #     3D mesh scene (slabs, camera rig, edges, regions)
│   │   │   └── Shapes/         #       per-kind 3D silhouettes (NodeShape + MeshBuilder + Vector + 14 kinds)
│   │   ├── AuthoringDemoBootstrap.cs
│   │   └── ComingSoonBootstrap.cs
│   ├── Editor/                 #   BuildMac.cs (batch build hook)
│   ├── Scenes/                 #   Boot.unity
│   ├── Tests/EditMode/         #   AuthoringCoreTests (NUnit)
│   └── prompts/authoring/      #   .media.prompt + .png mockups
├── docs/                       # Design corpus
│   ├── ARCHITECTURE.md
│   ├── CONCEPTS.md
│   ├── PROJ-ARCH.md            #   + .summary.md
│   ├── arch/                   #   unified-model, ingestion, layout, rendering-and-vr, …
│   ├── adrs/                   #   ADR-001..003
│   ├── specs/                  #   authoring-ux, rendering-and-vr, file-formats, …
│   ├── sparx-ea-parity.md
│   ├── ux-review-current-build.md
│   ├── diagrams/               #   (empty)
│   ├── layout/                 #   assets.md, scripts.md, docs.md
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
├── project-management/         # personas/ (P-001..P-009), user-stories/ (US-001..US-100)
├── Packages/                   # manifest.json, packages-lock.json
├── ProjectSettings/            # Unity .asset settings (committed)
├── Makefile                    # build/run/test/open/clean/doctor
├── build-mac.sh                # headless macOS .app build
├── README.md
├── .gitignore
└── therobotdrafts.sln          # generated (gitignored)
```
