# layout/scripts.md — `Assets/Scripts/`

All C# runtime source. The authoring **core** (model, rules, commands, controller — UI-agnostic)
backs everything; **CodeGen** is the code/wireframe ↔ model bridge, **Llm** the endpoint client,
**Styleguide** the theme engine (port of the Noizu styleguide), **Uml** the 2D editor harness, and
**Uml3D** the real 3D mesh scene. Bootstraps wire scenes to these.

```
Scripts/
├── AuthoringDemoBootstrap.cs   # Wires a demo scene onto the authoring/UML harness
├── ComingSoonBootstrap.cs      # Renders the pre-alpha "Coming Soon" splash (Boot scene)
│
├── Authoring/                  # UI-agnostic authoring core (reused by both 2D and 3D)
│   ├── TheRobotDraft.Authoring.asmdef   # Assembly definition
│   ├── AssemblyInfo.cs
│   ├── Model/
│   │   ├── AuthoringModel.cs    # One element: kind, name, containment parent, modifiers
│   │   ├── ElementId.cs         # Stable element identity
│   │   └── Kinds.cs             # Element/relationship kind enums
│   ├── Commands/
│   │   ├── Commands.cs          # Id minting + mutating commands (GUID / qualified-name hash)
│   │   └── UndoStack.cs         # Undo/redo command stack (§1)
│   ├── Rules/
│   │   └── Validity.cs          # Legality checks w/ human reason → §B invalid affordance UI
│   ├── State/
│   │   ├── AuthoringController.cs  # Affordance resolution: target/parent/endpoint + reason (§5.1)
│   │   ├── AuthoringMode.cs        # Current interaction mode
│   │   └── AffordanceState.cs      # How a candidate target reads right now
│   ├── Seams/
│   │   ├── IBubblePicker.cs     # Seam: pick a bubble (raycast abstraction)
│   │   ├── IPacker.cs           # Seam: layout/packing strategy (real packer owns 3D, ADR-003)
│   │   └── Math.cs              # Geometry helpers
│   └── README.md               # Authoring-core orientation
│
├── CodeGen/                    # Deterministic + LLM code ↔ model bridge
│   ├── CodeGenContext.cs        # Per-element data the generator needs (identity, members, notes, rels)
│   ├── CodeSkeleton.cs          # Offline source skeleton from UML signatures (C#/Java/TS/Python)
│   ├── CodeParser.cs            # Parses LLM's structured JSON of pasted source back to model (code→model)
│   ├── CodeStructParser.cs      # Network-free structural parser (first-choice import; C# strong, TS/Java light)
│   ├── CodeHighlighter.cs       # Source → Unity rich-text for read-only code viewer
│   ├── WireframeContext.cs      # Per-region input for wireframe gen (Screen/Panel + ordered widgets)
│   └── WireframeSkeleton.cs     # Offline HTML mockup + PlantUML `salt` emitters for a Screen/Panel region
│
├── Llm/                        # LLM endpoint access
│   ├── LlmClient.cs            # Dependency-free OpenAI-compatible /chat/completions client
│   └── LlmSettings.cs          # Endpoint URL / model / key configuration  ← set for LLM features
│
├── Styleguide/                 # Noizu styleguide theme engine (drives wireframe + HTML export)
│   ├── ThemeResolver.cs        # Ports css-gen: ~15 YAML seeds → ~300 resolved tokens (3 levels)
│   ├── TokenEvaluator.cs       # Resolves var()/color-mix()/rgba()/hex token expressions → Color
│   ├── ResolvedTheme.cs        # Resolved theme + ColorMode (light/dark) value object
│   └── YamlLite.cs             # Comment/order-preserving YAML round-trip for theme .vars.yaml editing
│
├── Uml/                        # 2D standard-UML editor harness (desktop stand-in for DOTS bubbles)
│   ├── UmlCanvas.cs             # Interactive editor: tabs/packages, boxes, add/connect, undo (§1–§5)
│   ├── UmlCanvas.CodeImport.cs  #   partial — drive import, ParsedModel → elements + edges
│   ├── UmlCanvas.CodeGen.cs     #   partial — walk model → CodeGenContext, run skeleton/LLM
│   ├── UmlCanvas.Layout.cs      #   partial — 2D node/edge layout
│   ├── UmlCanvas.Editors.cs     #   partial — inline editors (name/description prompts)
│   ├── UmlCanvas.Persistence.cs #   partial — save/load diagram state
│   ├── UmlCanvas.Images.cs      #   partial — per-node images (clipboard paste, attach/clear, persist)
│   ├── UmlCanvas.Packages.cs    #   partial — folder→package-tab linking + jump navigation
│   ├── UmlCanvas.Refactor.cs    #   partial — node Rename / Move-to-file / LLM free-form refactor
│   ├── UmlCanvas.Shadow.cs      #   partial — on-disk shadow files; VS Code edits re-parse back to model
│   ├── UmlNodeView.cs           # Classifier box w/ stereotype/attributes/operations compartments
│   ├── UmlEdgeView.cs           # Relationship line + UML arrowheads/end decorations
│   ├── UmlMemberSignature.cs    # Member visibility glyphs (Rose/Sparx scope: + - # ~)
│   ├── UmlColorWheel.cs         # Procedural HSV hue/sat disc for the style picker
│   ├── UmlNavIcons.cs           # Procedurally-rasterized nav-toolbar icon sprites (orbit/pan/X/Y/Z)
│   ├── UmlLayerMarker.cs        # Cross-Z-layer "continues elsewhere" chevron (click to follow)
│   └── UmlImageClipboard.cs     # Snapshot diagram → PNG + OS clipboard (macOS osascript)
│
└── Uml3D/                      # Real 3D mesh scene (slabs, camera orbit, Z-layer depth)
    ├── Uml3DScene.cs           # Imperative manager: add/remove nodes+edges, raycast pick, camera cmds
    ├── Uml3DConfig.cs          # 3D scene tuning constants
    ├── Uml3DGlyphs.cs          # Lo-fi wireframe widget glyphs as uGUI children of a node face
    ├── UmlCameraRig.cs         # 6-DOF rig: orbit/dolly/pan/roll/free-fly + Frame-to-fit
    ├── UmlNode3D.cs            # Procedural box slab + world-space uGUI compartments, lit, pickable
    ├── UmlRegion3D.cs          # Dotted hollow-cube system boundary that encloses member nodes
    ├── UmlEdge3D.cs            # World-space polyline relationship + dashed kinds + cone arrowhead
    ├── UmlEdgeHandle3D.cs      # Draggable 3D handle for drawing/editing an edge
    ├── UmlResizeHandle3D.cs    # Per-axis draggable resize cubes (width/height/depth/uniform)
    └── Shapes/                 # Per-kind 3D node silhouettes (18 files)
        ├── Uml3DNodeShape.cs       # ElementKind → mesh + face-text style dispatcher
        ├── Uml3DMeshBuilder.cs     # Primitive accumulator (prisms/boxes/cylinders…) → one welded mesh
        ├── Uml3DVector.cs          # "Design in 2D, extrude to depth" vector→volumetric part hierarchy
        ├── Uml3DRobot.cs           # Built-robot avatar handle (root + re-tintable per-part renderers)
        └── Uml3DShape_*.cs (14)    # One silhouette per kind: Actor, Cloud, Component, Cylinder,
                                    #   Diamond, DiscMarker, DogEar, FinalState, Flowchart, FlowFinal,
                                    #   Folder, MindNode, RoundedRect, UseCase
```

## Notes

- `Authoring/` is **pure logic** — no `UnityEngine` UI dependency — so the same model, rules,
  and commands back both the 2D `Uml/` harness and the 3D `Uml3D/` scene.
- The 2D harness is an explicit desktop stand-in for the planned DOTS bubble renderer; the real
  spatial packer lives behind `Seams/IPacker.cs` and owns 3D layout (ADR-003).
- Runtime has no `System.Text.Json` — both `LlmClient` and `CodeParser` use `JsonUtility`-shaped
  DTOs (single root object with a named array).
- **Shape coordinate contract** (`Uml3DMeshBuilder`): every mesh is origin-centered, inscribed in
  the w×h×d box, readable front cap toward +Z (where the text canvas sits). `Styleguide/` is a
  faithful reduction of `components/styleguide/app`'s css-gen: seed-driven Level-1 token math is
  ported in full; CSS-only component tokens round-trip untouched.
