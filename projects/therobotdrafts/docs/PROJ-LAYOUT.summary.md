# Project Layout (Summary) — The Robot Draft

Tree-only companion to [PROJ-LAYOUT.md](PROJ-LAYOUT.md). Keep in sync on structural changes.

```
therobotdrafts/
├── Assets/                     # Unity source (committed)
│   ├── Scripts/                #   C# source
│   │   ├── Authoring/          #     UI-agnostic core (Model/Commands/Rules/State/Seams)
│   │   ├── CodeGen/            #     code ↔ model bridge (skeleton/parse/highlight)
│   │   ├── Llm/                #     OpenAI-compatible endpoint client
│   │   ├── Uml/                #     2D UML editor harness (UmlCanvas + node/edge views)
│   │   ├── Uml3D/              #     3D mesh scene (slabs, camera rig, edges)
│   │   ├── AuthoringDemoBootstrap.cs
│   │   └── ComingSoonBootstrap.cs
│   ├── Editor/                 #   BuildMac.cs (batch build hook)
│   ├── Scenes/                 #   Boot.unity
│   ├── Tests/EditMode/         #   AuthoringCoreTests (NUnit)
│   └── prompts/authoring/      #   .media.prompt + .png mockups
├── docs/                       # Design corpus
│   ├── ARCHITECTURE.md
│   ├── CONCEPTS.md
│   ├── adrs/                   #   ADR-001..003
│   ├── specs/                  #   authoring-ux, rendering-and-vr, file-formats, …
│   ├── diagrams/               #   (empty)
│   ├── layout/                 #   assets.md, scripts.md, docs.md
│   ├── PROJ-LAYOUT.md
│   └── PROJ-LAYOUT.summary.md
├── Packages/                   # manifest.json, packages-lock.json
├── ProjectSettings/            # Unity .asset settings (committed)
├── Makefile                    # build/run/test/open/clean/doctor
├── build-mac.sh                # headless macOS .app build
├── README.md
├── .gitignore
└── therobotdrafts.sln          # generated (gitignored)
```
