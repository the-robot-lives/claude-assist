# Pending patches — image-import feature wiring

While this session was working, `InterchangeModel.cs` and `UmlCanvas.cs` were modified on this
machine by something else (another Claude session, most likely — both grew by almost exactly the
size of this session's own edits). The device bridge couldn't serve the new content back for a
proper merge, so rather than force-overwriting that work, this session's changes to those two
files are delivered here as patches.

**If Unity already compiles clean and shows the in-app menu bar / image import, the parallel
session made equivalent changes — delete this folder and you're done.**

Otherwise, from the `therobotdrafts/` project root:

```bash
git apply --3way _claude_patches/InterchangeModel.patch
git apply --3way _claude_patches/UmlCanvas.patch
```

(or apply by hand — both are small):

## InterchangeModel.patch (required — new files depend on it)
Appends members to the two interchange enums (ordinals of existing members unchanged):
- `IxElementType`: UseCase, State, StateStart, StateEnd, Decision, ForkJoin, Activity, FlowFinal,
  Component, Lifeline, MindNode, DeploymentNode, Database, Cloud
- `IxEdgeType`: Transition, Include, Extend, MessageSync, MessageAsync, MessageReply

Without this, `PlantUmlReader.cs`, `UmlCanvas.Interchange.cs`, and `UmlCanvas.ImageImport.cs`
will not compile.

## UmlCanvas.patch (wiring + layout)
Four localized edits:
1. `ShowNodeMenu` — adds "Import diagram from this image…" when a node has an attached picture.
2. `ShowCanvasGenerateMenu` — adds "Import diagram from image…  (vision LLM)".
3. `ShowEmptyMenu` — replaces the bare "LLM settings…" entry with "Export ▸" and "Settings ▸".
4. `BuildCanvas` — calls `BuildMenuBar()` and shifts the tab bar (−2 → −32), hint (−42 → −74),
   and nav-chip bar (−40 → −72) down to make room for the new menu-bar strip.

Delete `_claude_patches/` after applying.
