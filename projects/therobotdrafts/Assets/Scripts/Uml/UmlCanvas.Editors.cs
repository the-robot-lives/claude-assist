using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

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
        private void ShowMemberEditor(ElementId parent, ElementKind kind, ElementId existing, Vector2 screenPos)
        {
            CloseMenu();
            bool isField = kind == ElementKind.Field;
            bool editing = existing.IsValid && _model.TryGet(existing, out _);

            MemberParts parts = editing && _model.TryGet(existing, out var ex)
                ? UmlMemberSignature.Parse(kind, ex.Name)
                : MemberParts.ForNew(kind);

            float w = 470f, h = isField ? 322f : 420f;
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
                CloseMenu();
                if (editing)
                {
                    _ctl.Rename(existing, sig);
                    RebuildFromModel();
                    SetSelected(parent);
                    Flash("updated " + (isField ? "attribute" : "operation"));
                }
                else
                {
                    _ctl.EnterAddNode(kind);
                    var id = _ctl.CommitAddNode(parent, sig);
                    if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
                    RebuildFromModel();
                    SetSelected(parent);
                    Flash("added " + (isField ? "attribute" : "operation"));
                }
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
            if (editing)
                MakeButton(panel, "Delete", new Vector2(16f, yBtn), new Vector2(92f, 34f),
                    new Color(0.45f, 0.18f, 0.12f, 1f),
                    () => { CloseMenu(); _ctl.Delete(existing); RebuildFromModel(); SetSelected(parent); Flash("deleted member"); });

            FocusInput(nameInput);
        }

        // --- classifier (class / interface / enum / struct) properties editor ---

        private void ShowClassifierEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            CloseMenu();

            float w = 470f, h = 430f;
            var panel = BeginModal(w, h, "Properties   —   " + el.Kind);

            float y = -50f;
            FormLabel(panel, "Name", ref y, w);
            var nameInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Name, "TypeName");
            y -= 44f;

            FormLabel(panel, "Implementation language", ref y, w);
            var langInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Language,
                "C# / Rust / Go / Java / Python / Node.js / Elixir…");
            y -= 40f;
            // Quick-pick chips that fill the language field (wrapped into rows).
            const int perRow = 4;
            const float chipW = 100f, chipH = 26f, chipGap = 6f;
            for (int i = 0; i < CommonLanguages.Length; i++)
            {
                var captured = CommonLanguages[i];
                float cx = 16f + (i % perRow) * (chipW + chipGap);
                float cy = y - (i / perRow) * (chipH + chipGap);
                MakeButton(panel, captured, new Vector2(cx, cy), new Vector2(chipW, chipH),
                    new Color(0.18f, 0.22f, 0.28f, 1f), () => langInput.text = captured);
            }
            int rows = (CommonLanguages.Length + perRow - 1) / perRow;
            y -= rows * (chipH + chipGap) + 4f;

            FormLabel(panel, "Stereotype   («…» — overrides the derived one)", ref y, w);
            var stereoInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Stereotype,
                "entity, service, controller, value…");
            y -= 44f;

            Func<bool> getAbstract = () => el.IsAbstract;
            if (el.Kind == ElementKind.Class)
                getAbstract = MakeCheckbox(panel, new Vector2(16f, y), "abstract", el.IsAbstract);

            void Submit()
            {
                string newName = string.IsNullOrWhiteSpace(nameInput.text) ? el.Name : nameInput.text.Trim();
                bool wantAbstract = getAbstract();
                CloseMenu();
                if (newName != el.Name) _ctl.Rename(id, newName);
                if (el.Kind == ElementKind.Class && wantAbstract != el.IsAbstract) _ctl.SetAbstract(id, wantAbstract);
                _ctl.SetMeta(id, langInput.text, stereoInput.text);
                RebuildFromModel();
                SetSelected(id);
                Flash("updated properties");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(nameInput);
        }

        // --- note (comment) editor ---

        private void ShowNoteEditor(ElementId parent, ElementId existing, Vector2 screenPos)
        {
            CloseMenu();
            bool editing = existing.IsValid && _model.TryGet(existing, out _);
            string current = editing && _model.TryGet(existing, out var ex) ? ex.Name : "note";

            float w = 460f, h = 240f;
            var panel = BeginModal(w, h, editing ? "Edit Note" : "Add Note");

            float y = -50f;
            FormLabel(panel, "Note text", ref y, w);
            var input = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 110f, current, "Free comment text…");

            void Submit()
            {
                string txt = string.IsNullOrWhiteSpace(input.text) ? "note" : input.text;
                CloseMenu();
                if (editing)
                {
                    _ctl.Rename(existing, txt);
                    RebuildFromModel();
                    SetSelected(existing);
                    Flash("updated note");
                }
                else
                {
                    _ctl.EnterAddNode(ElementKind.Note);
                    var id = _ctl.CommitAddNode(parent, txt);
                    if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
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
