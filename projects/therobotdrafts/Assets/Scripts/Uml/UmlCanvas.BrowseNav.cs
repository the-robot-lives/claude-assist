using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Browse-nav integration seam (Track C1). UmlCanvas is the concrete source + action
    /// sink for <see cref="BrowseNavPanel"/>: it exposes the model/diagrams as a read tree
    /// (<see cref="IBrowseTreeSource"/>) and performs the panel's verbs
    /// (<see cref="IBrowseNavActions"/>) through the existing controller / command / geometry
    /// paths. The v1 tree is the CONTAINMENT hierarchy; drag-drop creates per-diagram
    /// placements in C0's <c>PlacementStore</c> without cloning the element.
    /// </summary>
    public sealed partial class UmlCanvas : IBrowseTreeSource, IBrowseNavActions
    {
        private BrowseNavPanel _browseNav;

        /// <summary>Built alongside BuildPalette() during HUD setup.</summary>
        private void BuildBrowseNav()
        {
            _browseNav = new BrowseNavPanel(_root, _font, this, this);
            _browseNav.Build();
        }

        // ================= IBrowseTreeSource (read) =================

        /// <summary>Top-level packages (diagrams), in the same order BuildTabBar lays out tabs.</summary>
        public IEnumerable<ElementId> Diagrams
        {
            get
            {
                if (_model == null) yield break; // BuildCanvas() runs before NewWorld()/LoadDiagram() creates the model
                foreach (var el in _model.Elements)
                    if (el.Kind == ElementKind.Package && !el.Parent.IsValid)
                        yield return el.Id;
            }
        }

        /// <summary>Tree children: pages (nested packages) + diagram nodes; members are hidden.</summary>
        public IEnumerable<ElementId> ChildrenOf(ElementId id)
        {
            if (_model == null || !_model.TryGet(id, out var el)) yield break;
            foreach (var childId in el.ChildIds)
                if (_model.TryGet(childId, out var c) && !KindInfo.IsMember(c.Kind))
                    yield return childId;
        }

        public bool TryGetElement(ElementId id, out ModelElement element)
        {
            if (_model == null) { element = null; return false; }
            return _model.TryGet(id, out element);
        }

        public ElementId ActiveDiagram => TopLevelOf(_activePackage);

        public ElementId OwningDiagramOf(ElementId id) => TopLevelOf(id);

        public IEnumerable<ElementId> DiagramsPlacing(ElementId element) => _placements.DiagramsPlacing(element);

        public Vector2 ScreenToModel(Vector2 screenPos) => ScreenToModelPx(screenPos);

        // ================= IBrowseNavActions (intents) =================

        public void EditProperties(ElementId id)
            => OpenNodeEditModal(id, new Vector2(Screen.width * 0.5f, Screen.height * 0.5f));

        public void RenameElement(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return;
            ShowNamePrompt("Rename " + el.Kind, el.Name ?? "", v =>
            {
                if (_ctl.Rename(id, v)) { RebuildFromModel(); Flash("renamed"); }
            });
        }

        public void DeleteElement(ElementId id)
        {
            if (!_model.Contains(id)) return;
            CloseMenu();
            // Mirror DeleteSelected: FixActiveAfterChange handles deleting the active diagram; stale
            // placements left behind are skipped on rebuild (see RebuildFromModel's linked-appearance loop).
            if (_ctl.Delete(id)) { SetSelected(ElementId.None); FixActiveAfterChange(); RebuildFromModel(); Flash("deleted"); }
        }

        /// <summary>Open the diagram/page the element lives on, then center the camera on it.</summary>
        public void SelectAndFrame(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return;
            if (el.Kind == ElementKind.Package) { GoToPackage(id); return; } // a diagram/page row
            if (el.Parent.IsValid) GoToPackage(el.Parent);                    // the page it sits on
            FocusOnNode(id);                                                  // sets selection + frames
        }

        public void OpenDiagram(ElementId diagramId) => GoToPackage(diagramId);

        public void ShowRowMenu(ElementId id, bool isDiagram, Vector2 screenPos)
            => ShowBrowseNavMenu(id, isDiagram, screenPos);

        /// <summary>
        /// THE C0 SEAM. Link an existing element into <paramref name="diagram"/> by creating a
        /// per-diagram placement (never a clone). Undoable via the geometry history.
        /// </summary>
        public void RequestPlacement(ElementId element, ElementId diagram, Vector2? modelPos)
        {
            if (!element.IsValid || !diagram.IsValid || !_model.Contains(element)) return;
            if (_placements.Contains(diagram, element)) { Flash("already placed here"); return; }

            BeginGeoEdit(); // geometry-undo snapshot (Ctrl/Cmd+Z restores the store)
            _placements.Set(diagram, element, Placement.At(modelPos ?? DefaultPlacementSeed(diagram)));
            RebuildFromModel(); // shows it if diagram == active; refreshes the browse tree via the hook
            Flash(_model.TryGet(element, out var e) ? "linked " + e.Name : "linked element");
        }

        /// <summary>A spread-out seed position for a link dropped on a diagram row (no cursor point).</summary>
        private Vector2 DefaultPlacementSeed(ElementId diagram)
        {
            int n = 0;
            foreach (var _ in _placements.InDiagram(diagram)) n++;
            return new Vector2(-220f + (n % 5) * 130f, 60f - (n / 5) * 130f);
        }

        // ================= row context menu (canvas-owned: uses CreateMenu/MenuItem) =================

        private void ShowBrowseNavMenu(ElementId id, bool isDiagram, Vector2 screenPos)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) return;
            var items = new List<MenuItem>();

            if (isDiagram)
            {
                items.Add(new MenuItem("Open", true, () => { CloseMenu(); OpenDiagram(id); }));
                items.Add(new MenuItem("Rename…", true, () => RenameElement(id)));
                items.Add(MenuItem.Separator());
                items.Add(new MenuItem("Delete diagram", true, () => DeleteElement(id)));
            }
            else
            {
                items.Add(new MenuItem("Edit Properties…", true, () => { CloseMenu(); EditProperties(id); }));
                items.Add(new MenuItem("Rename…", true, () => RenameElement(id)));
                items.Add(new MenuItem("Find in Diagram", true, () => { CloseMenu(); SelectAndFrame(id); }));
                bool canLink = KindInfo.IsDiagramNode(el.Kind) && !KindInfo.IsMember(el.Kind);
                items.Add(new MenuItem("Add Placement Here ▸", canLink, () => ShowAddPlacementMenu(id, screenPos)));
                items.Add(MenuItem.Separator());
                items.Add(new MenuItem("Delete", true, () => DeleteElement(id)));
            }

            CreateMenu(screenPos, el.Name ?? "(unnamed)", items);
        }

        /// <summary>Submenu of diagrams that do NOT already place the element — selecting one links it there.</summary>
        private void ShowAddPlacementMenu(ElementId id, Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var d in Diagrams)
            {
                if (_placements.Contains(d, id)) continue; // (diagram,element) is unique — skip existing
                var did = d;
                string name = _model.TryGet(d, out var de) ? de.Name : "(diagram)";
                items.Add(new MenuItem(name, true, () => { CloseMenu(); RequestPlacement(id, did, null); }));
            }
            if (items.Count == 0)
                items.Add(new MenuItem("(already in every diagram)", false, null));
            CreateMenu(screenPos + new Vector2(220f, 0f), "Add Placement", items);
        }

        void IBrowseNavActions.Flash(string msg) => Flash(msg); // explicit: reuse the private HUD Flash

        // ================= existing-element picker (D-step-2 dependency) =================

        /// <summary>
        /// Modal picker over the model: a searchable list of elements matching <paramref name="filter"/>
        /// (null ⇒ every diagram node). Invokes <paramref name="onPicked"/> with the chosen element and
        /// closes. A filtered flat view of the same data the browse tree renders.
        /// </summary>
        public void PickElement(System.Func<ModelElement, bool> filter, System.Action<ElementId> onPicked)
        {
            CloseMenu();

            var backdrop = new GameObject("PickBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            backdrop.AddComponent<Image>().color = new Color(0f, 0f, 0f, 0.45f);
            backdrop.AddComponent<UmlModalBackdrop>().Canvas = this;
            _menu = backdrop;

            const float w = 520f, h = 460f, pad = 16f;
            var panel = new GameObject("ElementPicker", typeof(RectTransform));
            var rt = (RectTransform)panel.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = Vector2.zero;
            panel.AddComponent<Image>().color = new Color(0.14f, 0.16f, 0.20f, 1f);

            MakeText(rt, "Pick an element", new Vector2(pad, -12f), new Vector2(w - 2 * pad, 24f), 16,
                new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;

            var search = MakeInput(rt, new Vector2(pad, -44f), w - 2 * pad, "", "search elements…");

            // Scroll list.
            var viewport = new GameObject("Viewport", typeof(RectTransform));
            var vrt = (RectTransform)viewport.transform;
            vrt.SetParent(rt, false);
            vrt.anchorMin = new Vector2(0f, 0f); vrt.anchorMax = new Vector2(1f, 1f);
            vrt.pivot = new Vector2(0f, 1f);
            vrt.offsetMin = new Vector2(pad, pad + 40f);       // leave room for Cancel row
            vrt.offsetMax = new Vector2(-pad, -86f);           // below the search box
            viewport.AddComponent<Image>().color = new Color(0.10f, 0.11f, 0.14f, 1f);
            viewport.AddComponent<RectMask2D>();

            var scroll = panel.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped; scroll.scrollSensitivity = 26f;

            var contentGo = new GameObject("Content", typeof(RectTransform));
            var content = (RectTransform)contentGo.transform;
            content.SetParent(vrt, false);
            content.anchorMin = new Vector2(0f, 1f); content.anchorMax = new Vector2(1f, 1f);
            content.pivot = new Vector2(0.5f, 1f);
            scroll.viewport = vrt; scroll.content = content;

            float listW = w - 2 * pad;

            void Rebuild()
            {
                for (int i = content.childCount - 1; i >= 0; i--) Destroy(content.GetChild(i).gameObject);
                string q = (search.text ?? "").Trim();

                // Collect + sort matches by name.
                var matches = new List<ModelElement>();
                foreach (var el in _model.Elements)
                {
                    if (filter != null && !filter(el)) continue;
                    if (q.Length > 0 && (el.Name ?? "").IndexOf(q, System.StringComparison.OrdinalIgnoreCase) < 0
                        && el.Kind.ToString().IndexOf(q, System.StringComparison.OrdinalIgnoreCase) < 0) continue;
                    matches.Add(el);
                }
                matches.Sort((a, b) => string.Compare(a.Name, b.Name, System.StringComparison.OrdinalIgnoreCase));

                float y = -4f;
                foreach (var el in matches)
                {
                    var pick = el.Id;
                    string owner = _model.TryGet(TopLevelOf(el.Id), out var od) ? od.Name : "";
                    string label = $"{el.Name}   ·  {el.Kind}" + (string.IsNullOrEmpty(owner) ? "" : $"   —  {owner}");
                    MakePickRow(content, label, new Vector2(2f, y), listW - 8f, () =>
                    {
                        CloseMenu();
                        onPicked?.Invoke(pick);
                    });
                    y -= 30f;
                }
                if (matches.Count == 0)
                    MakeText(content, "no matches", new Vector2(8f, y), new Vector2(listW - 16f, 22f), 13,
                        new Color(0.55f, 0.60f, 0.68f, 1f), TextAnchor.MiddleLeft).raycastTarget = false;
                else y -= 4f;
                content.sizeDelta = new Vector2(0f, -y + 4f);
            }

            search.onValueChanged.AddListener(_ => Rebuild());
            Rebuild();

            MakeButton(rt, "Cancel", new Vector2(w - 108f, -(h - 50f)), new Vector2(92f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            if (EventSystem.current != null) EventSystem.current.SetSelectedGameObject(search.gameObject);
            search.ActivateInputField();
        }

        private void MakePickRow(RectTransform parent, string label, Vector2 topLeft, float width, System.Action onClick)
        {
            var go = new GameObject("Pick", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(width, 28f);
            rt.anchoredPosition = topLeft;
            var img = go.AddComponent<Image>();
            img.color = new Color(0.18f, 0.20f, 0.25f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() => onClick());
            MakeText(rt, label, new Vector2(8f, 0f), new Vector2(width - 12f, 28f), 14,
                new Color(0.90f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft).raycastTarget = false;
        }
    }
}
