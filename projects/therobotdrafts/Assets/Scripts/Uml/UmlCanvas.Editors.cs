using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Structured property editors for the UML canvas — the Rational Rose / Sparx EA "feel": you pick visibility
    /// from a scope control, type the member name and its type / parameters / return type in labelled fields, and
    /// toggle static/abstract, instead of hand-typing UML punctuation. Members still serialize to the canonical
    /// signature string the model stores in <see cref="ModelElement.Name"/> (see <see cref="UmlMemberSignature"/>),
    /// so the renderer, reverse-engineering pipeline, and undo stack are all unchanged. Classifiers get a Properties
    /// dialog for name, implementation language, custom stereotype, and the abstract modifier.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private static readonly string[] CommonLanguages =
            { "C#", "C/C++", "Rust", "Go", "Java", "Python", "Node.js", "Elixir", "TypeScript" };
        private static readonly string[] CommonMultiplicities = { "1", "0..1", "0..*", "1..*", "*" };

        private static readonly Color LabelColor = new Color(0.62f, 0.68f, 0.78f, 1f);

        // --- member (attribute / operation) editor ---

        /// <summary>
        /// Open the structured attribute/operation editor. When <paramref name="existing"/> is valid the dialog
        /// edits that member (its signature is parsed back into the controls); otherwise it adds a new member
        /// under <paramref name="parent"/>.
        /// </summary>
        private void ShowMemberEditor(ElementId parent, ElementKind kind, ElementId existing, Vector2 screenPos,
            System.Action onClose = null)
        {
            CloseMenu();
            bool isField = kind == ElementKind.Field;
            bool editing = existing.IsValid && _model.TryGet(existing, out _);

            MemberParts parts = editing && _model.TryGet(existing, out var ex)
                ? UmlMemberSignature.Parse(kind, ex.Name)
                : MemberParts.ForNew(kind);

            float w = 470f, h = (isField ? 322f : 420f) + 110f; // +room for the comment / doc field
            string title = (editing ? "Edit " : "Add ") + (isField ? "Attribute" : "Operation")
                           + "   —   Rose / Sparx convention";
            var panel = BeginModal(w, h, title);

            float y = -50f;
            FormLabel(panel, "Visibility (scope)", ref y, w);
            var getVis = MakeVisibilityPicker(panel, new Vector2(16f, y), parts.Visibility);
            y -= 38f;

            FormLabel(panel, "Name", ref y, w);
            var nameInput = MakeInput(panel, new Vector2(16f, y), w - 32f, parts.Name,
                isField ? "fieldName" : "operationName");
            y -= 44f;

            InputField paramsInput = null;
            InputField typeInput;
            if (isField)
            {
                FormLabel(panel, "Type", ref y, w);
                typeInput = MakeInput(panel, new Vector2(16f, y), w - 32f, parts.Type,
                    "Type  (e.g. decimal, Guid, List<Order>)");
                y -= 44f;
            }
            else
            {
                FormLabel(panel, "Parameters   (name : Type, comma-separated)", ref y, w);
                paramsInput = MakeInput(panel, new Vector2(16f, y), w - 32f, parts.Parameters,
                    "amount : decimal, note : string");
                y -= 44f;
                FormLabel(panel, "Return type", ref y, w);
                typeInput = MakeInput(panel, new Vector2(16f, y), w - 32f, parts.Type, "void");
                y -= 44f;
            }

            var getStatic = MakeCheckbox(panel, new Vector2(16f, y), "static", parts.IsStatic);
            Func<bool> getAbstract = () => false;
            if (!isField) getAbstract = MakeCheckbox(panel, new Vector2(170f, y), "abstract", parts.IsAbstract);
            y -= 38f;

            // Comment / doc — the member's Description, surfaced for code generation + import round-trip.
            string currentComment = editing && _model.TryGet(existing, out var exc) ? exc.Description : "";
            FormLabel(panel, "Comment / doc   (rendered above the member in generated code)", ref y, w);
            var commentInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 64f, currentComment,
                "What this member is for…");

            void Submit()
            {
                var np = new MemberParts
                {
                    Visibility = getVis(),
                    Name = nameInput.text,
                    Type = typeInput.text,
                    Parameters = paramsInput != null ? paramsInput.text : "",
                    DefaultValue = parts.DefaultValue,
                    IsStatic = getStatic(),
                    IsAbstract = !isField && getAbstract(),
                };
                string sig = UmlMemberSignature.Compose(kind, np);
                string comment = commentInput.text;
                CloseMenu();
                if (editing)
                {
                    _ctl.Rename(existing, sig);
                    _ctl.SetDescription(existing, comment);
                    RebuildFromModel();
                    SetSelected(parent);
                    Flash("updated " + (isField ? "attribute" : "operation"));
                }
                else
                {
                    _ctl.EnterAddNode(kind);
                    var id = _ctl.CommitAddNode(parent, sig);
                    if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); onClose?.Invoke(); return; }
                    if (!string.IsNullOrWhiteSpace(comment)) _ctl.SetDescription(id, comment);
                    RebuildFromModel();
                    SetSelected(parent);
                    Flash("added " + (isField ? "attribute" : "operation"));
                }
                onClose?.Invoke();
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => { CloseMenu(); onClose?.Invoke(); });
            if (editing)
                MakeButton(panel, "Delete", new Vector2(16f, yBtn), new Vector2(92f, 34f),
                    new Color(0.45f, 0.18f, 0.12f, 1f),
                    () => { CloseMenu(); _ctl.Delete(existing); RebuildFromModel(); SetSelected(parent); Flash("deleted member"); onClose?.Invoke(); });

            FocusInput(nameInput);
        }

        // --- element editor (single screen: properties + fields + operations) ---

        private void ShowClassifierEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            CloseMenu();

            // Gather members.
            var attrs = new List<(ElementId id, string name)>();
            var ops = new List<(ElementId id, string name)>();
            foreach (var cid in el.ChildIds)
                if (_model.TryGet(cid, out var c))
                {
                    if (c.Kind == ElementKind.Field) attrs.Add((cid, c.Name));
                    else if (c.Kind == ElementKind.Function) ops.Add((cid, c.Name));
                }

            const int perRow = 4;
            const float chipW = 100f, chipH = 26f, chipGap = 6f, rowH = 28f;
            int langRows = (CommonLanguages.Length + perRow - 1) / perRow;
            const float descH = 72f; // multiline description input height
            float w = 480f;
            float h = 250f + langRows * (chipH + chipGap) + (el.Kind == ElementKind.Class ? 36f : 0f)
                      + 24f + descH + 12f
                      + 48f + attrs.Count * rowH + 48f + ops.Count * rowH + 60f;
            var panel = BeginModal(w, h, "Edit " + el.Kind + "   —   " + el.Name);

            float y = -50f;
            FormLabel(panel, "Name", ref y, w);
            var nameInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Name, "TypeName");
            y -= 44f;

            FormLabel(panel, "Implementation language", ref y, w);
            var langInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Language,
                "C# / Rust / Go / Java / Python / Node.js / Elixir…");
            y -= 40f;
            for (int i = 0; i < CommonLanguages.Length; i++)
            {
                var captured = CommonLanguages[i];
                float cx = 16f + (i % perRow) * (chipW + chipGap);
                float cy = y - (i / perRow) * (chipH + chipGap);
                MakeButton(panel, captured, new Vector2(cx, cy), new Vector2(chipW, chipH),
                    new Color(0.18f, 0.22f, 0.28f, 1f), () => langInput.text = captured);
            }
            y -= langRows * (chipH + chipGap) + 4f;

            FormLabel(panel, "Stereotype   («…» — overrides the derived one)", ref y, w);
            var stereoInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Stereotype,
                "entity, service, controller, value…");
            y -= 44f;

            FormLabel(panel, "Description   (free text — fed to code generation)", ref y, w);
            var descInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, descH, el.Description,
                "What this element is / does…");
            y -= descH + 12f;

            Func<bool> getAbstract = () => el.IsAbstract;
            if (el.Kind == ElementKind.Class)
            {
                getAbstract = MakeCheckbox(panel, new Vector2(16f, y), "abstract", el.IsAbstract);
                y -= 36f;
            }

            // Commit the property fields (so edits aren't lost when jumping to a member sub-dialog).
            void ApplyProps()
            {
                string nn = string.IsNullOrWhiteSpace(nameInput.text) ? el.Name : nameInput.text.Trim();
                if (nn != el.Name) _ctl.Rename(id, nn);
                if (el.Kind == ElementKind.Class && getAbstract() != el.IsAbstract) _ctl.SetAbstract(id, getAbstract());
                _ctl.SetMeta(id, langInput.text, stereoInput.text);
                _ctl.SetDescription(id, descInput.text);
            }
            void Reopen() => ShowClassifierEditor(id, screenPos);

            var rowText = new Color(0.86f, 0.89f, 0.94f, 1f);
            var editCol = new Color(0.20f, 0.34f, 0.42f, 1f);
            var delCol = new Color(0.42f, 0.20f, 0.16f, 1f);
            var addCol = new Color(0.18f, 0.30f, 0.24f, 1f);

            void MemberSection(string title, List<(ElementId id, string name)> list, ElementKind kind)
            {
                bool canHave = ContainmentRules.CanContain(el.Kind, kind).IsValid;
                FormLabel(panel, title + (canHave ? "" : "  (not allowed for this kind)"), ref y, w);
                foreach (var m in list)
                {
                    var mid = m.id; var mkind = kind;
                    MakeText(panel, "• " + Ellipsize(m.name, 42), new Vector2(20f, y), new Vector2(w - 190f, 22f),
                        14, rowText, TextAnchor.MiddleLeft);
                    MakeButton(panel, "Edit", new Vector2(w - 164f, y), new Vector2(66f, 22f), editCol,
                        () => { ApplyProps(); ShowMemberEditor(id, mkind, mid, screenPos, Reopen); });
                    MakeButton(panel, "Del", new Vector2(w - 92f, y), new Vector2(60f, 22f), delCol,
                        () => { ApplyProps(); _ctl.Delete(mid); RebuildFromModel(); Reopen(); });
                    y -= rowH;
                }
                if (canHave)
                {
                    string verb = kind == ElementKind.Field ? "＋ Add attribute" : "＋ Add operation";
                    MakeButton(panel, verb, new Vector2(20f, y), new Vector2(160f, 26f), addCol,
                        () => { ApplyProps(); ShowMemberEditor(id, kind, ElementId.None, screenPos, Reopen); });
                    y -= 32f;
                }
            }

            MemberSection("Attributes (fields)", attrs, ElementKind.Field);
            MemberSection("Operations (methods)", ops, ElementKind.Function);

            void Submit()
            {
                CloseMenu();
                ApplyProps();
                RebuildFromModel();
                SetSelected(id);
                Flash("updated element");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(nameInput);
        }

        // --- style editor (color / font / size) ---

        private static readonly Color[] StylePalette =
        {
            new Color(1f, 1f, 1f, 1f), new Color(0.90f, 0.91f, 0.93f, 1f),
            new Color(0.99f, 0.96f, 0.74f, 1f), new Color(0.80f, 0.89f, 0.98f, 1f),
            new Color(0.80f, 0.93f, 0.82f, 1f), new Color(0.98f, 0.83f, 0.80f, 1f),
            new Color(0.90f, 0.84f, 0.96f, 1f), new Color(0.99f, 0.88f, 0.74f, 1f),
            new Color(0.45f, 0.48f, 0.54f, 1f), new Color(0.14f, 0.15f, 0.18f, 1f),
        };

        private static readonly string[] StyleFonts =
            { "(default)", "Arial", "Helvetica", "Courier New", "Verdana", "Georgia", "Times New Roman" };

        private void ShowStyleEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            CloseMenu();
            bool has = _styles.TryGetValue(id, out var cur);

            Color fill = has ? cur.Fill : new Color(1f, 1f, 1f, 1f);
            Color border = has ? cur.Border : new Color(0.42f, 0.45f, 0.51f, 1f);
            Color text = has ? cur.Text : new Color(0.13f, 0.15f, 0.19f, 1f);
            string fontName = has ? (cur.FontName ?? "") : "";
            int size = has && cur.FontSize > 0 ? cur.FontSize : 15;

            float w = 520f, h = 424f;
            var panel = BeginModal(w, h, "Style   —   " + (el.Kind == ElementKind.Note ? "Note" : el.Name));
            float y = -50f;

            y = SwatchRow(panel, "Fill", y, w, fill, c => fill = c);
            y = SwatchRow(panel, "Border / line", y, w, border, c => border = c);
            y = SwatchRow(panel, "Text", y, w, text, c => text = c);

            FormLabel(panel, "Font  (OS fonts; falls back to default)", ref y, w);
            var fontLabel = MakeText(panel, "current: " + (string.IsNullOrEmpty(fontName) ? "(default)" : fontName),
                new Vector2(w - 220f, y + 22f), new Vector2(204f, 18f), 12, LabelColor, TextAnchor.MiddleRight);
            float fx = 16f;
            foreach (var fn in StyleFonts)
            {
                var cap = fn;
                MakeButton(panel, fn, new Vector2(fx, y), new Vector2(66f, 26f),
                    new Color(0.18f, 0.22f, 0.28f, 1f),
                    () => { fontName = cap == "(default)" ? "" : cap; fontLabel.text = "current: " + cap; });
                fx += 70f;
            }
            y -= 34f;

            FormLabel(panel, "Font size", ref y, w);
            var sizeLabel = MakeText(panel, size.ToString(), new Vector2(70f, y), new Vector2(50f, 24f), 16,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleCenter);
            MakeButton(panel, "−", new Vector2(16f, y), new Vector2(42f, 24f), new Color(0.18f, 0.22f, 0.28f, 1f),
                () => { size = Mathf.Max(8, size - 1); sizeLabel.text = size.ToString(); });
            MakeButton(panel, "+", new Vector2(126f, y), new Vector2(42f, 24f), new Color(0.18f, 0.22f, 0.28f, 1f),
                () => { size = Mathf.Min(40, size + 1); sizeLabel.text = size.ToString(); });
            y -= 34f;

            void Submit()
            {
                CloseMenu();
                _styles[id] = new NodeStyle
                {
                    Has = true, Fill = fill, Border = border, Text = text,
                    FontName = string.IsNullOrEmpty(fontName) ? null : fontName, FontSize = size,
                };
                RebuildFromModel();
                SetSelected(id);
                Flash("styled");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Reset", new Vector2(16f, yBtn), new Vector2(92f, 34f),
                new Color(0.40f, 0.30f, 0.16f, 1f),
                () => { CloseMenu(); _styles.Remove(id); RebuildFromModel(); SetSelected(id); Flash("style reset"); });
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        private float SwatchRow(RectTransform panel, string label, float y, float w, Color initial,
            Action<Color> onPick)
        {
            FormLabel(panel, label, ref y, w);
            var preview = MakeSwatch(panel, new Vector2(w - 46f, y + 22f), 26f, initial);
            float x = 16f;
            const float sw = 32f, gap = 6f;
            foreach (var c in StylePalette)
            {
                var cap = c;
                MakeButton(panel, "", new Vector2(x, y), new Vector2(sw, 26f), c,
                    () => { onPick(cap); preview.color = cap; });
                x += sw + gap;
            }
            // "Pick…" opens the HSV wheel for any colour beyond the presets. The preview swatch holds the live
            // value, so it doubles as the picker's starting colour and reflects whatever the picker commits.
            MakeButton(panel, "Pick…", new Vector2(x + 4f, y), new Vector2(70f, 26f),
                new Color(0.24f, 0.30f, 0.40f, 1f),
                () => ShowColorPicker(label, preview.color, c => { onPick(c); preview.color = c; }));
            return y - 34f;
        }

        private Image MakeSwatch(RectTransform parent, Vector2 topLeft, float size, Color c)
        {
            var go = new GameObject("Swatch", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(size, size);
            rt.anchoredPosition = topLeft;
            var img = go.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = false;
            return img;
        }

        /// <summary>
        /// HSV colour picker popup, layered above the Style modal: an interactive hue/saturation wheel plus vertical
        /// Value (brightness) and Alpha sliders, with a live hex readout + preview swatch. It is its own dim backdrop
        /// parented to <c>_root</c> (a sibling of the Style modal, NOT the shared <c>_menu</c>), so closing it leaves
        /// the Style modal intact. <paramref name="commit"/> receives the picked colour on OK.
        /// </summary>
        private void ShowColorPicker(string channel, Color initial, Action<Color> commit)
        {
            // Decompose the starting colour into the H/S/V/A state the picker edits. Sliders compose with the wheel.
            Color.RGBToHSV(initial, out float hue, out float sat, out float val);
            float alpha = initial.a;

            // Dim backdrop — a sibling of the Style modal, tracked locally. The Image blocks pointer events from
            // reaching the Style modal / canvas underneath, but clicking the dim area does NOT close the picker:
            // it closes only via its own OK / Cancel buttons (a stray click must not discard the pick).
            var backdrop = new GameObject("ColorPickerBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            var bdImg = backdrop.AddComponent<Image>();
            bdImg.color = new Color(0f, 0f, 0f, 0.45f);
            bdImg.raycastTarget = true; // swallow clicks on the dim area without dismissing

            void Close() { if (backdrop != null) Destroy(backdrop); }

            const float w = 320f, h = 380f;
            var panelGo = new GameObject("ColorPicker", typeof(RectTransform));
            var rt = (RectTransform)panelGo.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = Vector2.zero;
            panelGo.AddComponent<Image>().color = new Color(0.14f, 0.16f, 0.20f, 1f);

            MakeText(rt, "Pick colour   —   " + channel, new Vector2(16f, -12f), new Vector2(w - 32f, 24f), 16,
                new Color(0.86f, 0.90f, 0.96f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;

            // Hue/saturation wheel.
            var wheelGo = new GameObject("Wheel", typeof(RectTransform));
            var wheelRt = (RectTransform)wheelGo.transform;
            wheelRt.SetParent(rt, false);
            wheelRt.anchorMin = wheelRt.anchorMax = new Vector2(0f, 1f);
            wheelRt.pivot = new Vector2(0f, 1f);
            wheelRt.sizeDelta = new Vector2(180f, 180f);
            wheelRt.anchoredPosition = new Vector2(16f, -48f);
            var wheel = wheelGo.AddComponent<UmlColorWheelGraphic>();

            // Live preview swatch + hex readout (declared before the slider/wheel callbacks that update them).
            var preview = MakeSwatch(rt, new Vector2(16f, -240f), 40f, initial);
            preview.raycastTarget = false;
            var hexLabel = MakeText(rt, "", new Vector2(64f, -244f), new Vector2(w - 80f, 24f), 16,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleLeft);

            void Refresh()
            {
                var c = Color.HSVToRGB(hue, sat, val);
                c.a = alpha;
                preview.color = c;
                hexLabel.text = "#" + ColorUtility.ToHtmlStringRGBA(c);
            }

            wheel.OnHueSat = (newHue, newSat) => { hue = newHue; sat = newSat; Refresh(); };

            // Vertical Value (brightness) and Alpha sliders to the right of the wheel.
            MakeText(rt, "Value", new Vector2(214f, -48f), new Vector2(48f, 18f), 12,
                LabelColor, TextAnchor.MiddleCenter);
            MakeVerticalSlider(rt, new Vector2(224f, -70f), 22f, 150f, val, v => { val = v; Refresh(); });

            MakeText(rt, "Alpha", new Vector2(262f, -48f), new Vector2(48f, 18f), 12,
                LabelColor, TextAnchor.MiddleCenter);
            MakeVerticalSlider(rt, new Vector2(272f, -70f), 22f, 150f, alpha, a => { alpha = a; Refresh(); });

            Refresh();

            float yBtn = -(h - 46f);
            MakeButton(rt, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f),
                () => { var c = Color.HSVToRGB(hue, sat, val); c.a = alpha; commit(c); Close(); });
            MakeButton(rt, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), Close);
        }

        /// <summary>A bottom-to-top <see cref="Slider"/> (0..1) styled to match the dialog chrome; reports live drags.</summary>
        private Slider MakeVerticalSlider(RectTransform parent, Vector2 topLeft, float width, float height,
            float value, Action<float> onChange)
        {
            var go = new GameObject("Slider", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(width, height);
            rt.anchoredPosition = topLeft;

            // Track background.
            var bg = go.AddComponent<Image>();
            bg.color = new Color(0.20f, 0.22f, 0.27f, 1f);

            // Fill (grows from the bottom as the value increases).
            var fillArea = new GameObject("Fill", typeof(RectTransform));
            var fillRt = (RectTransform)fillArea.transform;
            fillRt.SetParent(rt, false);
            Stretch(fillRt);
            var fillImg = fillArea.AddComponent<Image>();
            fillImg.color = new Color(0.30f, 0.55f, 0.66f, 1f);

            // Handle.
            var handle = new GameObject("Handle", typeof(RectTransform));
            var handleRt = (RectTransform)handle.transform;
            handleRt.SetParent(rt, false);
            handleRt.sizeDelta = new Vector2(width, 10f);
            var handleImg = handle.AddComponent<Image>();
            handleImg.color = new Color(0.86f, 0.90f, 0.96f, 1f);

            var slider = go.AddComponent<Slider>();
            slider.direction = Slider.Direction.BottomToTop;
            slider.fillRect = fillRt;
            slider.handleRect = handleRt;
            slider.targetGraphic = handleImg;
            slider.minValue = 0f;
            slider.maxValue = 1f;
            slider.value = Mathf.Clamp01(value);
            slider.onValueChanged.AddListener(v => onChange(v));
            return slider;
        }

        // --- note (comment) editor ---

        private void ShowNoteEditor(ElementId parent, ElementId existing, Vector2 screenPos)
        {
            CloseMenu();
            bool editing = existing.IsValid && _model.TryGet(existing, out _);
            string current = editing && _model.TryGet(existing, out var ex) ? ex.Name : "note";
            string currentDesc = editing && _model.TryGet(existing, out var exd) ? exd.Description : "";

            float w = 460f, h = 360f;
            var panel = BeginModal(w, h, editing ? "Edit Note" : "Add Note");

            float y = -50f;
            FormLabel(panel, "Note text", ref y, w);
            var input = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 110f, current, "Free comment text…");
            y -= 122f;

            FormLabel(panel, "Description   (free text — fed to code generation)", ref y, w);
            var descInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 72f, currentDesc,
                "What this note is about…");

            void Submit()
            {
                string txt = string.IsNullOrWhiteSpace(input.text) ? "note" : input.text;
                CloseMenu();
                if (editing)
                {
                    _ctl.Rename(existing, txt);
                    _ctl.SetDescription(existing, descInput.text);
                    RebuildFromModel();
                    SetSelected(existing);
                    Flash("updated note");
                }
                else
                {
                    _ctl.EnterAddNode(ElementKind.Note);
                    var id = _ctl.CommitAddNode(parent, txt);
                    if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
                    _ctl.SetDescription(id, descInput.text);
                    _pos[id] = ScreenToLayer(screenPos);
                    RebuildFromModel();
                    SetSelected(id);
                    Flash("added note");
                }
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(input);
        }

        private InputField MakeMultilineInput(RectTransform parent, Vector2 topLeft, float width, float height,
            string value, string placeholder)
        {
            var inputGo = new GameObject("Input", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(parent, false);
            inRt.anchorMin = inRt.anchorMax = new Vector2(0f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(width, height);
            inRt.anchoredPosition = topLeft;
            inputGo.AddComponent<Image>().color = new Color(0.20f, 0.22f, 0.27f, 1f);
            var input = inputGo.AddComponent<InputField>();

            var textComp = MakeText(inRt, "", new Vector2(8f, -4f), new Vector2(width - 16f, height - 8f), 15,
                new Color(0.96f, 0.97f, 1f, 1f), TextAnchor.UpperLeft);
            textComp.raycastTarget = true;
            textComp.horizontalOverflow = HorizontalWrapMode.Wrap;
            var ph = MakeText(inRt, placeholder ?? "", new Vector2(8f, -4f), new Vector2(width - 16f, height - 8f), 15,
                new Color(0.5f, 0.55f, 0.62f, 1f), TextAnchor.UpperLeft);
            ph.fontStyle = FontStyle.Italic;
            ph.horizontalOverflow = HorizontalWrapMode.Wrap;

            input.textComponent = textComp;
            input.placeholder = ph;
            input.lineType = InputField.LineType.MultiLineNewline;
            input.text = value ?? "";
            return input;
        }

        // --- relationship (multiplicity / label) editor ---

        private void ShowEdgeMetaEditor(EdgeId edge, Vector2 screenPos)
        {
            if (!_model.TryGet(edge, out var e)) return;
            CloseMenu();

            float w = 470f, h = 352f;
            var panel = BeginModal(w, h, "Relationship   —   multiplicity & label");

            float y = -50f;
            FormLabel(panel, "Source-end multiplicity   (at " + EndName(e.From) + ")", ref y, w);
            var srcInput = MakeInput(panel, new Vector2(16f, y), w - 32f, e.SourceMultiplicity, "e.g. 1, 0..*, 1..*");
            y -= 38f;
            MultiplicityChips(panel, ref y, srcInput);

            FormLabel(panel, "Label   (association name / role — drawn at the midpoint)", ref y, w);
            var labelInput = MakeInput(panel, new Vector2(16f, y), w - 32f, e.Label, "line item, places, owns…");
            y -= 44f;

            FormLabel(panel, "Target-end multiplicity   (at " + EndName(e.To) + ")", ref y, w);
            var tgtInput = MakeInput(panel, new Vector2(16f, y), w - 32f, e.TargetMultiplicity, "e.g. 1, 0..*, 1..*");
            y -= 38f;
            MultiplicityChips(panel, ref y, tgtInput);

            void Submit()
            {
                CloseMenu();
                _ctl.SetEdgeMeta(edge, labelInput.text, srcInput.text, tgtInput.text);
                RebuildFromModel();
                Flash("updated relationship");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(srcInput);
        }

        private void MultiplicityChips(RectTransform panel, ref float y, InputField target)
        {
            float x = 16f;
            foreach (var m in CommonMultiplicities)
            {
                var captured = m;
                MakeButton(panel, m, new Vector2(x, y), new Vector2(70f, 26f),
                    new Color(0.18f, 0.22f, 0.28f, 1f), () => target.text = captured);
                x += 74f;
            }
            y -= 34f;
        }

        private string EndName(ElementId id) => _model.TryGet(id, out var el) ? el.Name : "?";

        // --- form building blocks ---

        /// <summary>Dim modal backdrop + centered panel with a bold title. Sets <c>_menu</c> so CloseMenu tears it down.</summary>
        private RectTransform BeginModal(float w, float h, string title)
        {
            CloseMenu();
            var backdrop = new GameObject("ModalBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            backdrop.AddComponent<Image>().color = new Color(0f, 0f, 0f, 0.45f);
            backdrop.AddComponent<UmlModalBackdrop>().Canvas = this;
            _menu = backdrop;

            var panelGo = new GameObject("Dialog", typeof(RectTransform));
            var rt = (RectTransform)panelGo.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = Vector2.zero;
            panelGo.AddComponent<Image>().color = new Color(0.14f, 0.16f, 0.20f, 1f);

            MakeText(rt, title, new Vector2(16f, -12f), new Vector2(w - 32f, 24f), 16,
                new Color(0.86f, 0.90f, 0.96f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;
            return rt;
        }

        private void FormLabel(RectTransform parent, string text, ref float y, float w)
        {
            MakeText(parent, text, new Vector2(16f, y), new Vector2(w - 32f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);
            y -= 20f;
        }

        private InputField MakeInput(RectTransform parent, Vector2 topLeft, float width, string value, string placeholder)
        {
            var inputGo = new GameObject("Input", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(parent, false);
            inRt.anchorMin = inRt.anchorMax = new Vector2(0f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(width, 32f);
            inRt.anchoredPosition = topLeft;
            inputGo.AddComponent<Image>().color = new Color(0.20f, 0.22f, 0.27f, 1f);
            var input = inputGo.AddComponent<InputField>();

            var textComp = MakeText(inRt, "", new Vector2(8f, 0f), new Vector2(width - 16f, 32f), 16,
                new Color(0.96f, 0.97f, 1f, 1f), TextAnchor.MiddleLeft);
            textComp.raycastTarget = true;
            var ph = MakeText(inRt, placeholder ?? "", new Vector2(8f, 0f), new Vector2(width - 16f, 32f), 16,
                new Color(0.5f, 0.55f, 0.62f, 1f), TextAnchor.MiddleLeft);
            ph.fontStyle = FontStyle.Italic;

            input.textComponent = textComp;
            input.placeholder = ph;
            input.lineType = InputField.LineType.SingleLine;
            input.text = value ?? "";
            return input;
        }

        /// <summary>Four-way segmented scope control (+ public / - private / # protected / ~ package).</summary>
        private Func<UmlVisibility> MakeVisibilityPicker(RectTransform parent, Vector2 topLeft, UmlVisibility initial)
        {
            var current = initial;
            var opts = new[] { UmlVisibility.Public, UmlVisibility.Private, UmlVisibility.Protected, UmlVisibility.Package };
            var images = new Image[opts.Length];
            const float bw = 104f, bh = 28f, gap = 4f;

            void Repaint()
            {
                for (int i = 0; i < opts.Length; i++)
                    images[i].color = opts[i] == current
                        ? new Color(0.20f, 0.42f, 0.52f, 1f)
                        : new Color(0.18f, 0.20f, 0.25f, 1f);
            }

            for (int i = 0; i < opts.Length; i++)
            {
                var v = opts[i];
                var go = new GameObject("Vis:" + v, typeof(RectTransform));
                var rt = (RectTransform)go.transform;
                rt.SetParent(parent, false);
                rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
                rt.pivot = new Vector2(0f, 1f);
                rt.sizeDelta = new Vector2(bw, bh);
                rt.anchoredPosition = topLeft + new Vector2(i * (bw + gap), 0f);
                var img = go.AddComponent<Image>();
                images[i] = img;
                var btn = go.AddComponent<Button>();
                btn.targetGraphic = img;
                btn.onClick.AddListener(() => { current = v; Repaint(); });
                MakeText(rt, v.Label(), new Vector2(8f, 0f), new Vector2(bw - 12f, bh), 14,
                    new Color(0.90f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft);
            }
            Repaint();
            return () => current;
        }

        /// <summary>A labelled checkbox; the returned delegate reads its live state at submit time.</summary>
        private Func<bool> MakeCheckbox(RectTransform parent, Vector2 topLeft, string label, bool initial)
        {
            bool state = initial;
            var go = new GameObject("Check:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(22f, 22f);
            rt.anchoredPosition = topLeft;
            var img = go.AddComponent<Image>();
            img.color = new Color(0.20f, 0.22f, 0.27f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            var mark = MakeText(rt, state ? "✓" : "", new Vector2(2f, 0f), new Vector2(20f, 22f), 16,
                new Color(0.40f, 0.85f, 0.60f, 1f), TextAnchor.MiddleCenter);
            MakeText(parent, label, topLeft + new Vector2(28f, 0f), new Vector2(120f, 22f), 15,
                new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft);
            btn.onClick.AddListener(() => { state = !state; mark.text = state ? "✓" : ""; });
            return () => state;
        }

        private static void FocusInput(InputField input)
        {
            if (input == null) return;
            if (EventSystem.current != null) EventSystem.current.SetSelectedGameObject(input.gameObject);
            input.ActivateInputField();
            input.MoveTextEnd(false);
        }
    }
}
