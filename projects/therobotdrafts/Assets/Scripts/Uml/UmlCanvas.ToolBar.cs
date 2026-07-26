using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.Uml.Chrome;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The context toolbar (nav-redesign IA v2): a slim strip under the menu bar carrying the
    /// Select | Connect | Place segmented tool modes, the Connect relationship-type picker, and the
    /// Place element-kind chip. Tool modes make element interaction explicit — Select drags move,
    /// Connect drags/click-pairs create edges, Place clicks drop the armed kind — replacing the old
    /// modifier-only scheme (which still works as power-user overrides in every mode).
    /// </summary>
    public sealed partial class UmlCanvas
    {
        internal enum ToolMode { Select, Connect, Place }

        private ToolMode _toolMode = ToolMode.Select;
        private EdgeKind _toolConnectKind = EdgeKind.Association;
        private ElementKind _toolPlaceKind = ElementKind.Class;
        private ElementId _toolConnectSource = ElementId.None;

        // Toolbar widget refs for state refresh + chrome reflow.
        private readonly Image[] _toolModeBg = new Image[3];
        private readonly Text[] _toolModeText = new Text[3];
        private GameObject _toolRelGroup;
        private Text _toolRelText;
        private GameObject _toolPlaceGroup;
        private Text _toolPlaceText;
        private Text _toolModeChip;
        private Text _toolCrumb;
        private RectTransform _contextToolbar;
        private RectTransform _toolModesRt;
        private RectTransform _toolRelRt;
        private RectTransform _toolPlaceRt;
        private RectTransform _toolCrumbRt;
        private RectTransform _toolModeChipRt;

        // Concept D demo tokens (design/nav-redesign/demo).
        private static readonly Color ToolBarBg = ConceptDTheme.Bg2;
        private static readonly Color ToolAccent = ConceptDTheme.Accent;
        private static readonly Color ToolAccentWarm = ConceptDTheme.Warm;
        private static readonly Color ToolIdleBg = ConceptDTheme.Bg;
        private static readonly Color ToolIdleText = ConceptDTheme.TextDim;
        private static readonly Color ToolActiveText = ConceptDTheme.AccentOn;

        /// <summary>Alias onto the shell layout budget; see <see cref="ChromeMetrics"/>.</summary>
        internal const float ContextToolbarHeight = ChromeMetrics.ContextToolbarHeight;

        // Segmented mode control (demo .modes: 2px track padding, .mode-btn 4px/16px pad).
        private const float SegBtnW = 84f;
        private const float SegBtnH = 26f;
        private const float SegPad = 2f;
        private const float SegTrackW = SegBtnW * 3f + SegPad * 2f;
        private const float CrumbWidth = 200f;
        /// <summary>X of the mode segmented control, right of the breadcrumb.</summary>
        private const float ModesX = 12f + CrumbWidth + 10f;
        /// <summary>X of the Connect / Place pickers, right of the mode control.</summary>
        private const float AfterModesX = ModesX + SegTrackW + 10f;
        /// <summary>
        /// Width consumed by the toolbar's right cluster (mode chip · ⌘K · Layout ▾), measured from
        /// the window's right edge. The HUD row continues leftward from here.
        /// </summary>
        internal const float ToolbarRightClusterWidth = 326f;

        /// <summary>Relationship kinds offered by the Connect picker (the core UML set; context menus
        /// still offer the full <see cref="EdgeKind"/> vocabulary per family).</summary>
        private static readonly EdgeKind[] ConnectKinds =
        {
            EdgeKind.Association, EdgeKind.DirectedAssociation, EdgeKind.Dependency,
            EdgeKind.Generalization, EdgeKind.Realization, EdgeKind.Composition,
            EdgeKind.Aggregation, EdgeKind.NoteLink,
        };

        /// <summary>Quick Place kinds for the toolbar chip menu; the palette rail arms any of the 151.</summary>
        private static readonly ElementKind[] QuickPlaceKinds =
        {
            ElementKind.Class, ElementKind.Interface, ElementKind.Enum, ElementKind.Package,
            ElementKind.Component, ElementKind.Actor, ElementKind.Note,
        };

        /// <summary>Build the context toolbar strip. Called from <c>BuildCanvas</c> right after the menu bar.</summary>
        private void BuildContextToolbar()
        {
            var barGo = new GameObject("ContextToolbar", typeof(RectTransform));
            var bar = (RectTransform)barGo.transform;
            _contextToolbar = bar;
            bar.SetParent(_root, false);
            bar.anchorMin = new Vector2(0f, 1f); bar.anchorMax = new Vector2(1f, 1f);
            bar.pivot = new Vector2(0f, 1f);
            bar.sizeDelta = new Vector2(0f, ContextToolbarHeight);
            bar.anchoredPosition = new Vector2(0f, -ChromeMetrics.ContextToolbarTop); // directly under the menu bar
            var bg = barGo.AddComponent<Image>();
            bg.color = ToolBarBg;
            bg.raycastTarget = false;

            // Segmented mode control (demo .modes): dark track + accent pill when active.
            var segGo = new GameObject("ToolModes", typeof(RectTransform));
            var seg = (RectTransform)segGo.transform;
            _toolModesRt = seg;
            seg.SetParent(bar, false);
            seg.anchorMin = seg.anchorMax = new Vector2(0f, 0.5f);
            seg.pivot = new Vector2(0f, 0.5f);
            seg.anchoredPosition = new Vector2(ModesX, 0f);
            seg.sizeDelta = new Vector2(SegTrackW, SegBtnH + SegPad * 2f);
            var segBg = segGo.AddComponent<Image>();
            MacOsControlKit.ApplyPanel(segBg, ConceptDTheme.Bg);

            string[] labels = { "Select", "Connect", "Place" };
            string[] tips =
            {
                "Select (V) — pick and move elements",
                "Connect (C) — draw relationships",
                "Place (P) — drop the armed element kind",
            };
            for (int i = 0; i < 3; i++)
            {
                int index = i;
                var bGo = new GameObject("Mode:" + labels[i], typeof(RectTransform));
                var bRt = (RectTransform)bGo.transform;
                bRt.SetParent(seg, false);
                bRt.anchorMin = bRt.anchorMax = new Vector2(0f, 0.5f);
                bRt.pivot = new Vector2(0f, 0.5f);
                bRt.sizeDelta = new Vector2(SegBtnW, SegBtnH);
                bRt.anchoredPosition = new Vector2(SegPad + i * SegBtnW, 0f);
                var img = bGo.AddComponent<Image>();
                MacOsControlKit.ApplySegment(img, false);
                _toolModeBg[i] = img;
                var btn = bGo.AddComponent<Button>();
                btn.targetGraphic = img;
                btn.onClick.AddListener(() => SetToolMode((ToolMode)index));
                var txt = MakeText(bRt, labels[i], Vector2.zero, new Vector2(SegBtnW, SegBtnH),
                    ChromeMetrics.FontControl, ToolIdleText, TextAnchor.MiddleCenter);
                _toolModeText[i] = txt;
                UiTooltip.Bind(bGo, tips[i], _font);
            }

            // Connect relationship picker (visible only in Connect mode).
            _toolRelGroup = new GameObject("RelPicker", typeof(RectTransform));
            var relRt = (RectTransform)_toolRelGroup.transform;
            _toolRelRt = relRt;
            relRt.SetParent(bar, false);
            relRt.anchorMin = relRt.anchorMax = new Vector2(0f, 0.5f);
            relRt.pivot = new Vector2(0f, 0.5f);
            relRt.sizeDelta = new Vector2(170f, SegBtnH);
            relRt.anchoredPosition = new Vector2(AfterModesX, 0f);
            var relImg = _toolRelGroup.AddComponent<Image>();
            MacOsControlKit.ApplyButton(relImg, ConceptDTheme.Secondary);
            var relBtn = _toolRelGroup.AddComponent<Button>();
            relBtn.targetGraphic = relImg;
            MacOsControlKit.ApplyButtonInteraction(relBtn, ConceptDTheme.Secondary);
            relBtn.onClick.AddListener(() =>
            {
                var corners = new Vector3[4];
                relRt.GetWorldCorners(corners);
                ShowConnectKindMenu(new Vector2(corners[0].x, corners[0].y - 2f));
            });
            _toolRelText = MakeText(relRt, RelLabel(_toolConnectKind) + " ▾", new Vector2(8f, 0f),
                new Vector2(160f, SegBtnH), ChromeMetrics.FontControl, ToolAccentWarm, TextAnchor.MiddleLeft);
            UiTooltip.Bind(_toolRelGroup, "Relationship type for Connect mode", _font);

            // Place kind chip (visible only in Place mode).
            _toolPlaceGroup = new GameObject("PlaceKind", typeof(RectTransform));
            var plRt = (RectTransform)_toolPlaceGroup.transform;
            _toolPlaceRt = plRt;
            plRt.SetParent(bar, false);
            plRt.anchorMin = plRt.anchorMax = new Vector2(0f, 0.5f);
            plRt.pivot = new Vector2(0f, 0.5f);
            plRt.sizeDelta = new Vector2(150f, SegBtnH);
            plRt.anchoredPosition = new Vector2(AfterModesX, 0f);
            var plImg = _toolPlaceGroup.AddComponent<Image>();
            MacOsControlKit.ApplyButton(plImg, ConceptDTheme.Secondary);
            var plBtn = _toolPlaceGroup.AddComponent<Button>();
            plBtn.targetGraphic = plImg;
            MacOsControlKit.ApplyButtonInteraction(plBtn, ConceptDTheme.Secondary);
            plBtn.onClick.AddListener(() =>
            {
                var corners = new Vector3[4];
                plRt.GetWorldCorners(corners);
                ShowPlaceKindMenu(new Vector2(corners[0].x, corners[0].y - 2f));
            });
            _toolPlaceText = MakeText(plRt, _toolPlaceKind + " ▾", new Vector2(8f, 0f),
                new Vector2(140f, 24f), 13, ToolAccent, TextAnchor.MiddleLeft);
            UiTooltip.Bind(_toolPlaceGroup, "Element kind armed for Place mode", _font);

            // Breadcrumb on the left edge (model ▸ … ▸ active page), kept fresh by the status poll.
            _toolCrumb = MakeText(bar, "", new Vector2(14f, 0f), new Vector2(264f, ContextToolbarHeight), 12,
                ConceptDTheme.TextDim, TextAnchor.MiddleLeft);
            _toolCrumbRt = (RectTransform)_toolCrumb.transform;
            UiTooltip.Bind(_toolCrumb.gameObject, "Active package / diagram path", _font);

            // Right cluster (compact): Layout ▾ · ⌘K · mode chip (Cam/2D live in HUD row; reflowed with inspector).
            float rx = -8f;
            _toolModeChip = MakeText(bar, "SELECT", Vector2.zero, new Vector2(170f, ContextToolbarHeight), 13,
                ToolAccent, TextAnchor.MiddleRight);
            var chipRt = (RectTransform)_toolModeChip.transform;
            _toolModeChipRt = chipRt;
            chipRt.anchorMin = chipRt.anchorMax = new Vector2(1f, 1f);
            chipRt.pivot = new Vector2(1f, 1f);
            chipRt.anchoredPosition = new Vector2(rx, 0f);
            rx -= 178f;

            AddToolbarRightButton(bar, "⌘K", 40f, ref rx, "Command palette", () => ToggleCommandPalette());
            AddToolbarRightButton(bar, "Layout ▾", 84f, ref rx, "Layout algorithms", () =>
                ShowCanvasLayoutMenu(new Vector2(Screen.width - 320f * ScaleFactor, (Screen.height / ScaleFactor - 64f) * ScaleFactor)));

            BuildSelectionToolbar();
            RefreshToolBar();
        }

        private void AddToolbarRightButton(RectTransform bar, string label, float width, ref float rx,
            string tooltip, System.Action onClick)
        {
            var go = new GameObject("ToolbarBtn:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(bar, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 0.5f);
            rt.pivot = new Vector2(1f, 0.5f);
            rt.sizeDelta = new Vector2(width, 24f);
            rt.anchoredPosition = new Vector2(rx, 0f);
            var img = go.AddComponent<Image>();
            MacOsControlKit.ApplyButton(img, ConceptDTheme.Secondary);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            MacOsControlKit.ApplyButtonInteraction(btn, ConceptDTheme.Secondary);
            btn.onClick.AddListener(() => onClick());
            MakeText(rt, label, Vector2.zero, new Vector2(width, 24f), 12,
                ConceptDTheme.Text, TextAnchor.MiddleCenter).raycastTarget = false;
            UiTooltip.Bind(go, tooltip, _font);
            rx -= width + 8f;
        }

        private static string RelLabel(EdgeKind kind) => kind switch
        {
            EdgeKind.DirectedAssociation => "Directed Assoc.",
            EdgeKind.NoteLink => "Note Link",
            _ => kind.ToString(),
        };

        private void ShowConnectKindMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var kind in ConnectKinds)
            {
                var k = kind;
                string check = k == _toolConnectKind ? "✓ " : "   ";
                items.Add(new MenuItem(check + RelLabel(k), true, () =>
                {
                    CloseMenu();
                    _toolConnectKind = k;
                    RefreshToolBar();
                    Flash("connect: " + RelLabel(k));
                }));
            }
            CreateMenu(screenPos, "Relationship", items);
        }

        private void ShowPlaceKindMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var kind in QuickPlaceKinds)
            {
                var k = kind;
                string check = k == _toolPlaceKind ? "✓ " : "   ";
                items.Add(new MenuItem(check + k, true, () =>
                {
                    CloseMenu();
                    _toolPlaceKind = k;
                    RefreshToolBar();
                    Flash("place: " + k);
                }));
            }
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Any kind → use the palette rail", false, null));
            CreateMenu(screenPos, "Place kind", items);
        }

        /// <summary>Switch the active tool mode: updates the segmented control, shows/hides the mode's
        /// companion picker, echoes the mode in the chip + hint, and clears any half-done connect.</summary>
        internal void SetToolMode(ToolMode mode)
        {
            _toolMode = mode;
            _toolConnectSource = ElementId.None;
            RefreshToolBar();
            switch (mode)
            {
                case ToolMode.Select:
                    Flash("Select — click picks, drag moves");
                    break;
                case ToolMode.Connect:
                    Flash("Connect (" + RelLabel(_toolConnectKind) + ") — click a source node, then a target (or drag node→node)");
                    break;
                case ToolMode.Place:
                    Flash("Place (" + _toolPlaceKind + ") — click empty canvas to add (or drag from the palette)");
                    break;
            }
        }

        /// <summary>Arm Place mode with a specific kind (palette click / toolbar chip).</summary>
        public void ArmPlaceKind(ElementKind kind)
        {
            _toolPlaceKind = kind;
            SetToolMode(ToolMode.Place);
        }

        private void RefreshToolBar()
        {
            if (_toolModeBg[0] == null) return; // toolbar not built yet
            for (int i = 0; i < 3; i++)
            {
                bool active = (int)_toolMode == i;
                bool warm = active && _toolMode == ToolMode.Connect;
                // Active segment = solid accent (or warm for Connect); idle = transparent track cell.
                if (active)
                {
                    MacOsControlKit.ApplySegment(_toolModeBg[i], true);
                    if (warm) _toolModeBg[i].color = ToolAccentWarm;
                    _toolModeText[i].color = warm ? ConceptDTheme.WarmOn : ToolActiveText;
                    _toolModeText[i].fontStyle = FontStyle.Bold;
                }
                else
                {
                    MacOsControlKit.ApplySegment(_toolModeBg[i], false);
                    _toolModeBg[i].color = new Color(0f, 0f, 0f, 0.001f); // invisible but raycastable
                    _toolModeText[i].color = ToolIdleText;
                    _toolModeText[i].fontStyle = FontStyle.Normal;
                }
            }
            if (_toolRelGroup != null) _toolRelGroup.SetActive(_toolMode == ToolMode.Connect);
            if (_toolPlaceGroup != null) _toolPlaceGroup.SetActive(_toolMode == ToolMode.Place);
            if (_toolRelText != null) _toolRelText.text = RelLabel(_toolConnectKind) + "  ▾";
            if (_toolPlaceText != null) _toolPlaceText.text = _toolPlaceKind + "  ▾";
            if (_toolModeChip != null)
            {
                _toolModeChip.text = _toolMode switch
                {
                    ToolMode.Connect => "CONNECT · " + RelLabel(_toolConnectKind).ToUpperInvariant(),
                    ToolMode.Place => "PLACE · " + _toolPlaceKind.ToString().ToUpperInvariant(),
                    _ => "SELECT",
                };
                _toolModeChip.color = _toolMode == ToolMode.Connect ? ToolAccentWarm : ToolAccent;
            }
        }

        // ------------------------------------------------------------------ kind browser (⇧⌘K)

        /// <summary>The full element-kind browser: search across every palette section, click a kind
        /// to arm Place mode with it. The "More…" path when the quick chips aren't enough.</summary>
        internal void ShowKindBrowser()
        {
            CloseMenu();
            var backdrop = new GameObject("KindBrowserBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            var bdImg = backdrop.AddComponent<Image>();
            bdImg.color = new Color(0f, 0f, 0f, 0.35f);
            var bdBtn = backdrop.AddComponent<Button>();
            bdBtn.targetGraphic = bdImg;
            bdBtn.onClick.AddListener(CloseMenu);
            _menu = backdrop;

            const float w = 480f, inputH = 40f, rowH = 26f;
            const int maxRows = 16;
            var panel = new GameObject("KindBrowser", typeof(RectTransform));
            var rt = (RectTransform)panel.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(w, inputH + maxRows * rowH + 12f);
            rt.anchoredPosition = new Vector2(0f, -100f);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyPopover(panel.AddComponent<Image>());

            var inputGo = new GameObject("KindInput", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(rt, false);
            inRt.anchorMin = new Vector2(0f, 1f); inRt.anchorMax = new Vector2(1f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(0f, inputH);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyTextField(inputGo.AddComponent<Image>());
            var input = inputGo.AddComponent<InputField>();
            var textComp = MakeText(inRt, "", new Vector2(12f, 0f), new Vector2(w - 24f, inputH), 16,
                new Color(0.95f, 0.97f, 1f, 1f), TextAnchor.MiddleLeft);
            textComp.raycastTarget = true;
            var ph = MakeText(inRt, "Element kind…  (click to arm Place)", new Vector2(12f, 0f),
                new Vector2(w - 24f, inputH), 16, new Color(0.45f, 0.5f, 0.58f, 1f), TextAnchor.MiddleLeft);
            ph.fontStyle = FontStyle.Italic;
            input.textComponent = textComp;
            input.placeholder = ph;

            var results = new GameObject("KindResults", typeof(RectTransform));
            var resRt = (RectTransform)results.transform;
            resRt.SetParent(rt, false);
            resRt.anchorMin = new Vector2(0f, 1f); resRt.anchorMax = new Vector2(1f, 1f);
            resRt.pivot = new Vector2(0f, 1f);
            resRt.sizeDelta = new Vector2(0f, maxRows * rowH);
            resRt.anchoredPosition = new Vector2(0f, -(inputH + 6f));

            void Refresh(string filter)
            {
                for (int i = resRt.childCount - 1; i >= 0; i--) Destroy(resRt.GetChild(i).gameObject);
                string f = (filter ?? "").Trim().ToLowerInvariant();
                var seen = new HashSet<string>();
                float ky = 0f; int count = 0;
                foreach (var sec in PaletteSections())
                    foreach (var it in sec.items)
                    {
                        if (count >= maxRows) break;
                        if (f.Length > 0
                            && it.label.ToLowerInvariant().IndexOf(f, System.StringComparison.Ordinal) < 0
                            && sec.title.ToLowerInvariant().IndexOf(f, System.StringComparison.Ordinal) < 0) continue;
                        if (!seen.Add(it.kind + "|" + it.label)) continue;
                        var kind = it.kind;
                        var item = new MenuItem(sec.title + " · " + it.label, true, () =>
                        {
                            CloseMenu();
                            ArmPlaceKind(kind);
                        });
                        MakeMenuButton(resRt, item, new Vector2(6f, ky), new Vector2(w - 12f, rowH - 2f));
                        ky -= rowH;
                        count++;
                    }
            }
            Refresh("");
            input.onValueChanged.AddListener(Refresh);

            if (UnityEngine.EventSystems.EventSystem.current != null)
                UnityEngine.EventSystems.EventSystem.current.SetSelectedGameObject(inputGo);
            input.ActivateInputField();
        }

        // ------------------------------------------------------------------ floating selection toolbar

        private RectTransform _selToolbar;

        /// <summary>The contextual toolbar that floats beside the selected node (demo parity):
        /// Link (connect from here) · Edit · Frame · Del.</summary>
        private void BuildSelectionToolbar()
        {
            var go = new GameObject("SelectionToolbar", typeof(RectTransform));
            _selToolbar = (RectTransform)go.transform;
            _selToolbar.SetParent(_root, false);
            _selToolbar.anchorMin = _selToolbar.anchorMax = new Vector2(0f, 0f);
            _selToolbar.pivot = new Vector2(0f, 0.5f);
            _selToolbar.sizeDelta = new Vector2(4f + 4f * 48f, 30f);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyPopover(go.AddComponent<Image>());

            float bx = 2f;
            void Btn(string label, System.Action act)
            {
                var b = new GameObject("Sel:" + label, typeof(RectTransform));
                var brt = (RectTransform)b.transform;
                brt.SetParent(_selToolbar, false);
                brt.anchorMin = brt.anchorMax = new Vector2(0f, 0.5f);
                brt.pivot = new Vector2(0f, 0.5f);
                brt.sizeDelta = new Vector2(46f, 26f);
                brt.anchoredPosition = new Vector2(bx, 0f);
                var img = b.AddComponent<Image>();
                TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyButton(img,
                    TheRobotDraft.Uml.Chrome.MacOsControlKit.SecondaryFill);
                var btn = b.AddComponent<Button>();
                btn.targetGraphic = img;
                TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyButtonInteraction(btn,
                    TheRobotDraft.Uml.Chrome.MacOsControlKit.SecondaryFill);
                btn.onClick.AddListener(() => act());
                MakeText(brt, label, Vector2.zero, brt.sizeDelta, 12,
                    new Color(0.78f, 0.83f, 0.89f, 1f), TextAnchor.MiddleCenter).raycastTarget = false;
                bx += 48f;
            }
            Btn("Link", () =>
            {
                if (!_selectedId.IsValid) return;
                var source = _selectedId;
                SetToolMode(ToolMode.Connect);
                _toolConnectSource = source;
                Flash("connect (" + RelLabel(_toolConnectKind) + "): source set — click the target");
            });
            Btn("Edit", () => { if (_selectedId.IsValid) OpenNodeEditModal(_selectedId, Input.mousePosition); });
            Btn("Frame", () => { if (_selectedId.IsValid) FocusOnNode(_selectedId); });
            Btn("Del", () => DeleteSelected());
            _selToolbar.gameObject.SetActive(false);
        }

        /// <summary>Keep the floating toolbar glued beside the selected node (called every frame).</summary>
        private void UpdateSelectionToolbar()
        {
            if (_selToolbar == null) return;
            bool show = _selectedId.IsValid && _menu == null && _scene != null
                && _scene.TryGetNode(_selectedId, out var node) && node != null;
            if (!show)
            {
                if (_selToolbar.gameObject.activeSelf) _selToolbar.gameObject.SetActive(false);
                return;
            }
            _scene.TryGetNode(_selectedId, out var n);
            var cam = _scene.Rig != null ? _scene.Rig.Cam : null;
            if (cam == null) { _selToolbar.gameObject.SetActive(false); return; }
            // Anchor just past the node's actual right edge (collider extents), not a fixed offset,
            // so wide nodes don't swallow the toolbar.
            var col = n.GetComponentInChildren<BoxCollider>();
            Vector3 edge = col != null
                ? n.transform.position + n.transform.right * (col.bounds.extents.x + 0.15f)
                : n.transform.position;
            Vector3 sp = cam.WorldToScreenPoint(edge);
            if (sp.z <= 0f) { _selToolbar.gameObject.SetActive(false); return; }
            if (!_selToolbar.gameObject.activeSelf) _selToolbar.gameObject.SetActive(true);
            float sf = Mathf.Max(ScaleFactor, 0.0001f);
            _selToolbar.anchoredPosition = new Vector2(sp.x / sf + 10f, sp.y / sf + 14f);
        }

        /// <summary>V / C / P mode shortcuts (called from <c>Update</c> after the modifier shortcuts).</summary>
        private void HandleToolModeKeys(bool ctrl)
        {
            if (ctrl) return;
            if (Input.GetKeyDown(KeyCode.V)) SetToolMode(ToolMode.Select);
            else if (Input.GetKeyDown(KeyCode.C)) SetToolMode(ToolMode.Connect);
            else if (Input.GetKeyDown(KeyCode.P)) SetToolMode(ToolMode.Place);
        }

        /// <summary>Escape backs out one level: pending connect source → cleared; Connect/Place mode →
        /// Select. Returns true if it consumed the press.</summary>
        private bool CancelToolInteraction()
        {
            if (_toolConnectSource.IsValid)
            {
                _toolConnectSource = ElementId.None;
                Flash("connect: source cleared");
                return true;
            }
            if (_toolMode != ToolMode.Select)
            {
                SetToolMode(ToolMode.Select);
                return true;
            }
            return false;
        }

        /// <summary>Connect-mode click-pair flow: first node click picks the source, second commits the
        /// edge with the toolbar's relationship kind (same controller idiom as connect-by-drag).</summary>
        private void HandleConnectClick(ElementId nodeId)
        {
            if (!_toolConnectSource.IsValid)
            {
                _toolConnectSource = nodeId;
                SetSelected(nodeId);
                Flash("connect (" + RelLabel(_toolConnectKind) + "): source set — click the target");
                return;
            }
            if (_toolConnectSource == nodeId)
            {
                _toolConnectSource = ElementId.None;
                Flash("connect: source cleared");
                return;
            }
            var source = _toolConnectSource;
            _toolConnectSource = ElementId.None;
            _ctl.EnterConnect(CommitStyle.OneShot, _toolConnectKind);
            _ctl.BeginConnect(source);
            var edge = _ctl.CommitConnect(nodeId);
            _ctl.EnterSelect();
            if (edge.IsValid)
            {
                RebuildFromModel();
                SetSelected(nodeId);
                Flash("connected (" + RelLabel(_toolConnectKind) + ") — click the next source");
            }
            else
            {
                Flash("can't connect those two with " + RelLabel(_toolConnectKind));
            }
        }
    }
}
