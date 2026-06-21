# Unity New-Project Setup Checklist

Fill in the decisions, then tick the setup steps. See `references/version-cheatsheet.md` for the pipeline decision and `references/engine-core.md` §3 for setup detail.

## Decisions
- [ ] **Domain:** ____ (game 2D / game 3D / app-UI / CAD-industrial / XR)
- [ ] **Target platforms:** ____
- [ ] **Editor version:** ____ (default Unity 6 / `6000.x`)
- [ ] **License tier:** ____ (Personal / Pro / Enterprise / **Industry — required for CAD**)
- [ ] **Render pipeline:** ____ (URP default / HDRP fixed-high-end / BiRP legacy-only)
- [ ] **Template:** ____ (Universal 3D / Universal 2D / HD 3D)

## Core setup
- [ ] Project created from the chosen template
- [ ] `packages-lock.json` committed; `enableLockFile` on
- [ ] Render Graph enabled (Compatibility Mode **off**) if URP/HDRP
- [ ] Active Input Handling set (New, or **Both** during migration); Input Actions asset created
- [ ] Assembly definitions (`.asmdef`) planned for compile boundaries
- [ ] Scripting backend chosen (IL2CPP for ship/required platforms); stripping level set
- [ ] **Build Profiles** created (replaces Build Settings); scene list populated
- [ ] Version control = **Unity Version Control (UVCS)** or git + `.gitignore` (Library/, Temp/, Build/, Logs/, obj/)
- [ ] `.meta` files committed (Visible Meta Files mode)

## Domain add-ons (tick what applies)
- [ ] **2D:** Universal 2D template, Sprite Atlas V2 on, 2D feature set + Tilemap Extras + Pixel Perfect
- [ ] **App UI:** UI Toolkit + UI Builder; PanelSettings scale mode chosen; Localization + Accessibility (6.2+) if needed
- [ ] **3D rendering:** APV lighting, Volume profile, quality tiers; GPU Resident Drawer (Forward+) if many shared meshes
- [ ] **DOTS:** Entities/Burst/Collections/Mathematics; SubScenes for baking
- [ ] **XR:** XR Plugin Management + provider; XRI Starter Assets; single-pass instanced; URP
- [ ] **CAD:** Industry license confirmed; Asset Transformer Toolkit; dataprep plan (six-phase)
- [ ] **Multiplayer:** Multiplayer Center recommendation; NGO 2.x / Netcode for Entities

## Hygiene
- [ ] Addressables initialized (preferred over Resources)
- [ ] Profiler + Frame Debugger baseline captured early
- [ ] No deprecated/EOL paths chosen (see version-cheatsheet)
