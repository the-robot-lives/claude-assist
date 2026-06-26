# Project Layout — The Robot Draft

A Unity 6 (6000.x) VR-capable UML/IDE: reverse-engineer code into a navigable 3D model,
project regions into standard diagrams, and round-trip back to code. Pre-alpha — a working
2D/3D UML editor stub plus the full design corpus under `docs/`.

```
therobotdrafts/
├── Assets/                     # Unity assets — all committed source → [layout/assets.md](layout/assets.md)
│   ├── Scripts/                #   C# source (authoring core, codegen, LLM, styleguide, 2D + 3D UML) → [layout/scripts.md](layout/scripts.md)
│   ├── Editor/                 #   Editor-only scripts (BuildMac batch entry point)
│   ├── Scenes/                 #   Boot.unity — entry scene
│   ├── prompts/                #   .media.prompt files + generated PNG mockups (authoring UX)
│   └── Tests/                  #   EditMode test suite (NUnit)
├── docs/                       # Design corpus → [layout/docs.md](layout/docs.md)
│   ├── ARCHITECTURE.md         #   System architecture overview
│   ├── CONCEPTS.md             #   Domain concepts / glossary
│   ├── PROJ-ARCH.md            #   Architecture map (+ .summary.md, arch/* detail)
│   ├── arch/                   #   Architecture detail files (unified-model, ingestion, layout…)
│   ├── adrs/                   #   Architecture Decision Records (DOTS, unified model, packing)
│   ├── specs/                  #   Feature & format specs (authoring UX, rendering/VR, file formats…)
│   ├── sparx-ea-parity.md      #   Feature parity vs. Sparx Enterprise Architect
│   ├── ux-review-current-build.md  # UX review of the current build
│   ├── diagrams/               #   (empty) diagram exports
│   ├── PROJ-LAYOUT.md          #   This file
│   └── PROJ-LAYOUT.summary.md  #   Tree-only companion (keep in sync)
├── project-management/         # Generated planning corpus (9 personas + 100 user stories)
│   ├── personas/               #   P-001…P-009 + index.yaml
│   └── user-stories/           #   US-001…US-100 + index.yaml
├── Packages/                   # Unity package manifest
│   ├── manifest.json           #   Declared UPM dependencies (Rider, test-framework, uGUI, XR…)
│   └── packages-lock.json      #   Resolved dependency lock
├── ProjectSettings/            # Unity project settings (.asset) — committed, configures the editor
├── Makefile                    # make build/run/test/open/clean/doctor — wraps Unity batch mode
├── build-mac.sh                # Headless macOS .app build (auto-selects Unity w/ Mac Build Support)
├── README.md                   # Start here — what it is, why, running the stub
├── .gitignore                  # Unity-aware ignores (Library, Builds, *.csproj, *.sln, .vscode…)
└── therobotdrafts.sln          # Generated solution (gitignored; present locally)
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| Unity editor | Install version in `ProjectSettings/ProjectVersion.txt` via Unity Hub (Mac Build Support for `build`/`run`) |
| `Assets/Scripts/Llm/LlmSettings.cs` | Point at an OpenAI-compatible `/chat/completions` endpoint for LLM code↔model features |
| `make doctor` | Run to confirm the resolved editor and Mac Build Support before building |
| `make doc-pointers` | Regenerate `docs/doc-pointer-db.json` and expand Markdown `deeplink:` references via `../../utilities/shell/misc-git-utils/bin/doc-pointers` |

## Notes

- **Generated / gitignored** (present locally, not documented as source): `Library/`, `Builds/`,
  `Logs/`, `UserSettings/`, `Temp/`, `obj/`, `*.csproj`, `*.sln`, `.vscode/`.
- `.meta` files accompany every committed asset (required by Unity); omitted from these trees.
