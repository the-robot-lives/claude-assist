# Unity UI & Application-Style Graphics (Priority)

Building **application-style UIs** in Unity — dashboards, kiosks, desktop/tablet productivity tools, configurators — not just game HUDs. Targets Unity **6.0 / 6.1 / 6.2** (`6000.x`). Verified against `docs.unity3d.com` 6000.2 manual.

## TL;DR decision guide

| Use case | System | Why |
|---|---|---|
| **App/productivity/kiosk/dashboard UI** (priority) | **UI Toolkit (runtime)** | Web-like authoring (UXML/USS), flexbox layout, true data binding, scales to dense UIs, retained-mode performance |
| Game HUD needing custom shaders/materials, VFX, mask-clip, Timeline-animated UI | **uGUI (Canvas)** | UI Toolkit still lacks these at runtime |
| **All editor tooling / custom inspectors / EditorWindows** | **UI Toolkit (editor)** — Unity's official recommendation | First-class, SerializedObject binding, UI Builder |
| Quick throwaway editor UI, debug overlays | **IMGUI** | Immediate-mode, code-only |

**Official Unity 6.2 stance:** *Runtime* — uGUI "recommended," UI Toolkit the alternative; *Editor* — UI Toolkit "recommended," IMGUI the alternative. Unity states UI Toolkit "is intended to become the recommended UI system" but "currently lacks features that uGUI and IMGUI provide." For **application-style UI specifically**, UI Toolkit is the better fit and is production-viable in 6.x — the gaps below are mostly game-rendering features.

## 1. UI Toolkit (the modern system)

Web-inspired, **retained-mode**: a hierarchy of `VisualElement` objects styled by USS and laid out by a flexbox engine. Same system for editor and runtime.

**Core pieces:**
- **`VisualElement`** — base node (the "div"). Hierarchy = visual tree.
- **UXML** — XML structure (`VisualTreeAsset`). Reusable templates via `<ui:Template>` / `<ui:Instance>`.
- **USS** — Unity Style Sheets (CSS-like). **TSS** (Theme Style Sheets) for themes.
- **UQuery** — LINQ-like DOM query: `root.Q<Button>("submit")`, `root.Query<Label>(className:"row").ToList()`.
- **Layout engine** — **Yoga** flexbox. Default `flex-direction: column` (note: column, not row like web).
- **UI Builder** — WYSIWYG authoring (`Window > UI Toolkit > UI Builder`).

**Runtime setup:** add **`UIDocument`** MonoBehaviour + a **`PanelSettings`** asset + a **Source Asset** (the UXML). Access via `uiDocument.rootVisualElement`. **Initialize in `OnEnable()`, clean up in `OnDisable()`** — UI Toolkit disables/re-enables the MonoBehaviour on UI reload (not Awake/Start).

```csharp
void OnEnable() {
    var root = GetComponent<UIDocument>().rootVisualElement;
    root.Q<Button>("save").clicked += OnSave;                       // command event
    root.Q<TextField>("name").RegisterValueChangedCallback(e => Model.Name = e.newValue);
    root.RegisterCallback<PointerDownEvent>(OnDown);               // low-level events
}
```

**USS vs CSS:** selectors (type `Button`, class `.row`, name `#save`, descendant, `*`); pseudo-classes `:hover :active :focus :checked :disabled :root`. Custom properties `--my-color: #333;` + `var(--my-color)`. Units `px`/`%` only (no em/rem/vh). Transitions supported (no `@keyframes`). **No grid/float** — flexbox only. Unity-specific props are `-unity-` prefixed (`-unity-font-definition`, `-unity-text-align`).

**Custom controls (Unity 6 — important change):** Unity 6 **replaced `UxmlFactory`/`UxmlTraits`** with source-generated attributes:
```csharp
[UxmlElement]                          // available in UXML + UI Builder Library
public partial class GaugeControl : VisualElement   // MUST be partial
{
    [UxmlAttribute] public float Value { get; set; }
    public GaugeControl() {
        RegisterCallback<AttachToPanelEvent>(_ => { /* init */ });
        RegisterCallback<DetachFromPanelEvent>(_ => { /* cleanup */ });
    }
}
```

### Data binding (the big 6.x feature for app UI)
- **Runtime binding** — binds any plain C# object's properties to control properties; works at runtime and in editor.
- **SerializedObject binding** — preferred for editor/serialized data; supports undo/redo.

```csharp
public class VM : INotifyBindablePropertyChanged {
    public event EventHandler<BindablePropertyChangedEventArgs> propertyChanged;
    int _count;
    [CreateProperty]                       // marks property bindable (Unity.Properties)
    public int Count {
        get => _count;
        set { if (_count==value) return; _count=value;
              propertyChanged?.Invoke(this, new BindablePropertyChangedEventArgs(nameof(Count))); }
    }
}
label.dataSource = vm;
label.SetBinding("text", new DataBinding {
    dataSourcePath = PropertyPath.FromName(nameof(VM.Count)),
    bindingMode = BindingMode.ToTarget
});
```
**`BindingMode`**: `ToTarget` / `ToSource` / `TwoWay` / `ToTargetOnce`. Type converters via `binding.sourceToUiConverters.AddConverter(...)`. Bindings can also be authored in UXML/UI Builder → MVVM-style designer/programmer separation. **This binding system is what makes UI Toolkit genuinely competitive for data-driven application UIs** — the closest Unity gets to MVVM natively.

### What UI Toolkit runtime still LACKS (as of 6.2)
Custom materials/shaders on UI; arbitrary mask clipping (uGUI `Mask`/`RectMask2D` style); Animation Clip / Timeline / Visual Scripting integration; serialized `UnityEvents` in inspector (code-first wire-up); mature world-space UI (a World Space Render Mode exists on PanelSettings but lags uGUI — verify for VR/3D-diegetic UI). **For screen-space application UIs none of these gaps matter** — this is exactly where UI Toolkit shines.

## 2. uGUI (Canvas-based) — current status

Still the **runtime-recommended** system per Unity and required for the features UI Toolkit lacks.
- **Canvas render modes:** Screen Space Overlay / Screen Space Camera / World Space.
- **`CanvasScaler`** for DPI: Constant Pixel Size, **Scale With Screen Size** (reference resolution + match), Constant Physical Size.
- **Layout:** `HorizontalLayoutGroup`, `VerticalLayoutGroup`, `GridLayoutGroup`, `ContentSizeFitter`, `LayoutElement`, `AspectRatioFitter`.
- **TextMeshPro is now built-in** (SDF text, rich text, fallback fonts). Legacy `Text` is superseded.
- **Input:** `EventSystem` + **`InputSystemUIInputModule`** (with the new Input System).

**uGUI performance (critical for UI-heavy apps):** a Canvas rebuilds its **entire batch** when *any* element changes. **Split dynamic vs static content onto separate Canvases** — the single most impactful optimization. Group same-material/atlas elements; disable `Raycast Target` on non-interactive Graphics; use `RectMask2D` over `Mask`; profile with Frame Debugger.

## 3. IMGUI
Immediate-mode, code-only (`OnGUI`, `EditorGUILayout`). Use for quick `EditorWindow`/debug tooling and rapid prototyping. Not for runtime app UI.

## 4. Application / desktop / kiosk concerns

| Concern | Guidance |
|---|---|
| **DPI / responsive** | PanelSettings (UI Toolkit) or CanvasScaler (uGUI). For crisp app UI across resolutions: **Scale With Screen Size** + reference resolution, or **Constant Physical Size** (Reference/Fallback DPI) for tablets/kiosks. |
| **Multi-monitor** | `PanelSettings.targetDisplay` / `Display.displays`; `Display.displays[i].Activate()`. |
| **Window/screen mgmt** | `Screen.SetResolution`, `Screen.fullScreenMode` (`FullScreenWindow`, `ExclusiveFullScreen`, `Windowed`). Borderless kiosk: windowed + cover screen, disable OS chrome. |
| **Cursor** | `Cursor.visible`, `Cursor.lockState`, `Cursor.SetCursor(tex, hotspot, mode)`. |
| **Embedding / native** | No first-party native-window API. Routes: render to `RenderTexture` then composite, or **Unity as a Library (UaaL)** to embed Unity in a native shell. Embedding native OS windows inside Unity needs native plugins. |

## 5. PanelSettings (runtime UI Toolkit scaling)
- **Render Mode:** World Space | Screen Space Overlay.
- **Scale Mode:** *Constant Pixel Size* (`Scale`); *Constant Physical Size* (`Reference DPI`, `Fallback DPI` — best cross-device physical consistency); *Scale With Screen Size* (`Reference Resolution`, `Screen Match Mode`, `Match` 0–1).
- **Target Texture** (render UI into a RenderTexture), **Target Display**, **Sort Order** (layer multiple panels), **Dynamic Atlas Settings**, **Collider Update Mode** (World Space only).

## 6. Vector graphics / crisp scalable 2D — ⚠️ caveat
- **Vector Graphics package** (`com.unity.vectorgraphics`) is **still 2.0.0-preview / experimental** — Unity explicitly says **"not recommended in production."** Imports a subset of SVG 1.1; **no text, no per-pixel masking, no filters/animation/interactivity.**
- Practical crisp-UI strategy instead: **text** via SDF (TextMeshPro / built-in UI Toolkit text, resolution-independent); **icons** via SDF sprites, 9-slice, or pre-rasterized SVG at multiple scales; **shapes** via USS (`border-radius`, gradients). For in-scene 2D, Sprite Shape (spline-based) is production-grade but is scene geometry, not UI.

## 7. Localization & i18n
**`com.unity.localization`** (~1.5.x, production). Concepts: **`Locale`**, **`StringTable`/`AssetTable`**, **`LocalizedString`/`LocalizedAsset`**, **Smart Strings** (placeholders, plurals, gender). Import/export **XLIFF, CSV, Google Sheets**. **Pseudo-localization** for early layout/overflow testing — essential for app UI that must not clip across languages. For CJK/RTL: configure **font fallback chains** (TMP fallback assets / `-unity-font-definition` fallbacks); budget for large font atlases.

## 8. Accessibility — new in Unity 6.2 ✅
**Accessibility module** (`com.unity.modules.accessibility`) is **built-in starting Unity 6.2**. Provides **`AccessibilityHierarchy`** + **`AccessibilityNode`** to expose UI to assistive tech, screen reader support, and font scaling. Platforms: **iOS VoiceOver**, **Android TalkBack**. Works with both UI Toolkit and uGUI. ⚠️ New — desktop screen-reader (NVDA/JAWS/VoiceOver-macOS) coverage is limited; verify per platform.

## 9. Performance & gotchas (UI-heavy app UIs)

**UI Toolkit:** minimize total `VisualElement` count and hierarchy depth; set **`pickingMode = PickingMode.Ignore`** on non-interactive elements; use **`ListView`/`MultiColumnListView`** (pooled/virtualized) for large tables — don't instantiate thousands of elements; lean on the **Dynamic Atlas** and prefer textureless USS styling over images; set bindings once and push changes via property notifications.

**uGUI:** separate dynamic vs static canvases (top priority); disable raycast targets; `RectMask2D` > `Mask`; watch overdraw and layout-group rebuilds.

**Recommended app-UI pattern (MVVM):** UXML (view, designer-authored) + USS (theme) + C# view-model implementing `INotifyBindablePropertyChanged` with `[CreateProperty]` members, bound via UI Toolkit data-binding. Keeps logic out of the view; supports theming/localization swaps.

> Uncertainty: world-space UI Toolkit maturity lags uGUI; Vector Graphics package is preview; desktop accessibility coverage unverified; exact minor-version of specific binding refinements not pinned (data-binding + `[UxmlElement]` source-gen is the Unity 6 baseline).
