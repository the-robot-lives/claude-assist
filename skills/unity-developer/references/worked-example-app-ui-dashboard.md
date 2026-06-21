# Worked Example: Kiosk Dashboard App UI (Unity 6 / UI Toolkit)

End-to-end demonstration for the **application/OS-style UI** case — not a game HUD. Shows choosing UI Toolkit, wiring data binding, and handling kiosk scaling.

## Request
> "I'm building a touchscreen kiosk app in Unity that shows live machine status (a list of machines with state, temperature, throughput) on a fixed 1920×1080 portrait display. It updates from a backend feed. Crisp text, responsive layout."

## Step 1 — System choice (Workflow 2)
- This is **screen-space application UI** (data-dense, no custom shaders/VFX/world-space). → **UI Toolkit (runtime)**. None of UI Toolkit's runtime gaps (custom materials, mask-clip, Timeline UI) apply.
- Crisp text → SDF (UI Toolkit text is resolution-independent). Fixed kiosk display → **Constant Physical Size** or a fixed Reference Resolution.

## Step 2 — Scaffold
1. Create a `UIDocument`: `GameObject → UI Toolkit → UI Document`.
2. Create a **PanelSettings** asset; assign it. Scale Mode = **Constant Physical Size** (Reference DPI tuned for the kiosk panel) — or Scale With Screen Size with Reference Resolution 1080×1920 (portrait), Match = 0.5.
3. Author UXML in **UI Builder** (`Window → UI Toolkit → UI Builder`).

`MachineRow.uxml` (a reusable template):
```xml
<ui:UXML xmlns:ui="UnityEngine.UIElements">
  <ui:VisualElement class="row">
    <ui:Label name="machine-name" class="row__name" />
    <ui:Label name="state" class="row__state" />
    <ui:Label name="temp" class="row__temp" />
    <ui:Label name="throughput" class="row__tput" />
  </ui:VisualElement>
</ui:UXML>
```

`Dashboard.uss`:
```css
.row { flex-direction: row; padding: 12px; border-bottom-width: 1px;
       border-bottom-color: var(--divider); }
.row__name  { flex-grow: 1; -unity-font-style: bold; font-size: 28px; }
.row__state { width: 160px; }
.state--ok    { color: rgb(46,204,113); }
.state--fault { color: rgb(231,76,60); }
:root { --divider: rgba(255,255,255,0.12); }
```
> USS reminders: default `flex-direction` is **column**; units are `px`/`%` only; Unity-specific props are `-unity-` prefixed.

## Step 3 — View-model + data binding (MVVM)
```csharp
using Unity.Properties;
using System.ComponentModel;
using System;

public class Machine : INotifyBindablePropertyChanged {
    public event EventHandler<BindablePropertyChangedEventArgs> propertyChanged;
    void Raise(string p) => propertyChanged?.Invoke(this, new BindablePropertyChangedEventArgs(p));

    string _state; float _temp;
    [CreateProperty] public string Name { get; set; }
    [CreateProperty] public string State { get => _state; set { if (_state==value) return; _state=value; Raise(nameof(State)); } }
    [CreateProperty] public float  Temp  { get => _temp;  set { if (_temp ==value) return; _temp =value; Raise(nameof(Temp)); } }
}
```

## Step 4 — Virtualized list (don't instantiate thousands of rows)
```csharp
using UnityEngine;
using UnityEngine.UIElements;
using System.Collections.Generic;

public class Dashboard : MonoBehaviour {
    [SerializeField] VisualTreeAsset rowTemplate;
    readonly List<Machine> _machines = new();
    ListView _list;

    void OnEnable() {                                   // OnEnable, not Start
        var root = GetComponent<UIDocument>().rootVisualElement;
        _list = root.Q<ListView>("machine-list");
        _list.makeItem = () => rowTemplate.Instantiate();
        _list.bindItem = (e, i) => {
            var m = _machines[i];
            var nameLbl = e.Q<Label>("machine-name");
            nameLbl.dataSource = m;
            nameLbl.SetBinding("text", new DataBinding {
                dataSourcePath = PropertyPath.FromName(nameof(Machine.Name)),
                bindingMode = BindingMode.ToTarget
            });
            var state = e.Q<Label>("state");
            state.text = m.State;
            state.EnableInClassList("state--fault", m.State == "FAULT");
            state.EnableInClassList("state--ok", m.State == "OK");
        };
        _list.itemsSource = _machines;
    }

    public void Ingest(IEnumerable<Machine> feed) {     // called from backend poller
        _machines.Clear(); _machines.AddRange(feed);
        _list.RefreshItems();
    }
}
```
`ListView` pools rows — only visible items are realized. Bound `Label`s auto-update when the VM raises `propertyChanged`.

## Step 5 — Backend feed (low-GC async)
```csharp
async Awaitable PollLoop(System.Threading.CancellationToken ct) {
    while (!ct.IsCancellationRequested) {
        await Awaitable.BackgroundThreadAsync();        // off main thread for IO/parse
        var data = await FetchAndParse();               // your HTTP/MQTT call
        await Awaitable.MainThreadAsync();              // back for UI mutation
        GetComponent<Dashboard>().Ingest(data);
        await Awaitable.WaitForSecondsAsync(2f, ct);
    }
}
// start: _ = PollLoop(destroyCancellationToken);  // auto-cancels on destroy
```

## Step 6 — Kiosk concerns
- Fullscreen borderless: `Screen.fullScreenMode = FullScreenMode.FullScreenWindow;` hide cursor `Cursor.visible = false;`.
- Localization: add `com.unity.localization`, use Smart Strings + pseudo-localization to catch clipping early; configure CJK font fallback chains if needed.
- Accessibility (6.2+): the built-in Accessibility module can expose the hierarchy to TalkBack/VoiceOver on mobile kiosks.
- Set `pickingMode = PickingMode.Ignore` on non-interactive labels to cut hit-testing.

## Gotchas hit
- **Init in `Start()` → null root** — UI Toolkit re-enables the MonoBehaviour on UI reload; use `OnEnable`/`OnDisable`.
- **Blurry text at odd resolutions** — wrong PanelSettings scale mode; Constant Physical Size or matched Reference Resolution fixes it.
- **GC spikes on each feed** — rebuilding the whole tree instead of using `ListView` + binding; virtualize + bind once.

## Result
A data-driven kiosk dashboard: UI Toolkit UXML/USS view, MVVM via `INotifyBindablePropertyChanged` + `[CreateProperty]` bindings, a pooled `ListView` for the machine table, low-GC `Awaitable` polling, and kiosk-grade scaling/fullscreen — the "application framework" path Unity offers natively, no game-HUD baggage.
