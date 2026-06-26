# layout/assets.md — `Assets/`

Everything Unity treats as project content. The bulk is `Scripts/` (its own file); the rest is
the boot scene, the editor build hook, the EditMode tests, and the authoring-UX media prompts.

```
Assets/
├── Scripts/                    # All C# source → [scripts.md](scripts.md)
├── Editor/
│   └── BuildMac.cs             # Editor-only batch build entry point (called by build-mac.sh / Makefile)
├── Scenes/
│   └── Boot.unity              # Entry scene (loads the Coming-Soon splash / demo bootstrap)
├── Tests/
│   └── EditMode/
│       ├── TheRobotDraft.Authoring.Tests.asmdef   # Test assembly def (references the authoring core)
│       └── AuthoringCoreTests.cs                   # NUnit EditMode tests for the authoring core
└── prompts/
    └── authoring/              # Authoring-UX concept art: .media.prompt source + generated .png
        ├── 01-desktop-toolbar-screen.media.prompt   (+ .png)
        ├── 02-vr-radial-menu.media.prompt           (+ .png)
        ├── 03-creation-palette.media.prompt         (+ .png)
        └── 04-edge-draw-choreography.media.prompt   (+ .png)
```

## Notes

- Every file has a sibling `.meta` (Unity GUID/import settings); committed but omitted here.
- `.media.prompt` files are generate-media-prompt sources; the `.png` next to each is the
  generated mockup. Run the tests headless with `make test`.
