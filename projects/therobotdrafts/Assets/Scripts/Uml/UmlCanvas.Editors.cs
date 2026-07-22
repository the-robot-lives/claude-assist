using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;
using TheRobotDraft.Llm;

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
            string memberLanguage = LanguageForElement(parent);

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
                typeInput = MakeCatalogCombobox(panel, new Vector2(16f, y), w - 32f, parts.Type,
                    "Type  (e.g. decimal, Guid, List<Order>)", GlobalCatalog.FieldTypesForLanguage(memberLanguage),
                    value => GlobalCatalog.RememberFieldType(memberLanguage, value));
                y -= 44f;
            }
            else
            {
                FormLabel(panel, "Parameters   (name : Type, comma-separated)", ref y, w);
                paramsInput = MakeInput(panel, new Vector2(16f, y), w - 32f, parts.Parameters,
                    "amount : decimal, note : string");
                y -= 44f;
                FormLabel(panel, "Return type", ref y, w);
                typeInput = MakeCatalogCombobox(panel, new Vector2(16f, y), w - 32f, parts.Type, "void",
                    GlobalCatalog.FieldTypesForLanguage(memberLanguage),
                    value => GlobalCatalog.RememberFieldType(memberLanguage, value));
                y -= 44f;
            }

            var getStatic = MakeCheckbox(panel, new Vector2(16f, y), "static", parts.IsStatic);
            Func<bool> getAbstract = () => false;
            if (!isField) getAbstract = MakeCheckbox(panel, new Vector2(170f, y), "abstract", parts.IsAbstract);
            y -= 38f;

            // Comment / doc — the member's CodeDoc, surfaced for code generation + import round-trip.
            string currentComment = editing && _model.TryGet(existing, out var exc) ? exc.CodeDoc : "";
            FormLabel(panel, "Comment / doc   (rendered above the member in generated code)", ref y, w);
            var commentInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 64f, currentComment,
                "What this member is for…");
            y -= 78f;

            ModelElement linkElement = null;
            if (editing) _model.TryGet(existing, out linkElement);
            string currentCode = linkElement != null ? linkElement.DeepLinkCode : "";
            string currentUuid = linkElement != null ? linkElement.DeepLinkUuid : "";
            bool currentEmbed = linkElement != null ? linkElement.EmbedDeepLinkCode : DeepLinkIdentity.DefaultEmbed(kind);
            FormLabel(panel, "Deep link   " + DeepLinkIdentity.Marker(currentCode), ref y, w);
            MakeText(panel, currentUuid, new Vector2(16f, y), new Vector2(w - 32f, 18f), 11,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 24f;
            var getEmbedDeepLink = MakeCheckbox(panel, new Vector2(16f, y), "embed in generated docs", currentEmbed);
            y -= 36f;

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
                GlobalCatalog.RememberFieldType(memberLanguage, typeInput.text);
                CloseMenu();
                if (editing)
                {
                    _ctl.Rename(existing, sig);
                    _ctl.SetCodeDoc(existing, comment);
                    if (getEmbedDeepLink() != currentEmbed)
                        _ctl.SetEmbedDeepLinkCode(existing, getEmbedDeepLink());
                    RebuildFromModel();
                    SetSelected(parent);
                    Flash("updated " + (isField ? "attribute" : "operation"));
                }
                else
                {
                    _ctl.EnterAddNode(kind);
                    var id = _ctl.CommitAddNode(parent, sig);
                    if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); onClose?.Invoke(); return; }
                    if (!string.IsNullOrWhiteSpace(comment)) _ctl.SetCodeDoc(id, comment);
                    if (getEmbedDeepLink() != DeepLinkIdentity.DefaultEmbed(kind))
                        _ctl.SetEmbedDeepLinkCode(id, getEmbedDeepLink());
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

            const float rowH = 28f;
            const float descH = 72f; // multiline description/doc input height
            float w = 480f;
            float h = 286f + (el.Kind == ElementKind.Class ? 36f : 0f)
                      + 24f + descH + 12f + 24f + descH + 12f
                      + 48f + attrs.Count * rowH + 48f + ops.Count * rowH + 60f;
            var panel = BeginModal(w, h, "Edit " + el.Kind + "   —   " + el.Name);

            float y = -50f;
            FormLabel(panel, "Name", ref y, w);
            var nameInput = MakeInput(panel, new Vector2(16f, y), w - 32f, el.Name, "TypeName");
            y -= 44f;

            FormLabel(panel, "Implementation language", ref y, w);
            var langInput = MakeCatalogCombobox(panel, new Vector2(16f, y), w - 32f, el.Language,
                "C# / Rust / Go / Java / Python / Node.js / Elixir…",
                GlobalCatalog.Languages, GlobalCatalog.RememberLanguage);
            y -= 44f;

            FormLabel(panel, "Stereotype   («…» — overrides the derived one)", ref y, w);
            var stereoInput = MakeCatalogCombobox(panel, new Vector2(16f, y), w - 32f, el.Stereotype,
                "entity, service, controller, value…", GlobalCatalog.StereotypesForLanguage(el.Language),
                value => GlobalCatalog.RememberStereotype(langInput.text, value));
            y -= 44f;

            FormLabel(panel, "Description   (UML/product note)", ref y, w);
            var descInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, descH, el.Description,
                "What this element is / does…");
            y -= descH + 12f;

            FormLabel(panel, "Code docs   (generated source comment)", ref y, w);
            var docInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, descH, el.CodeDoc,
                "Comment emitted above this type in generated code…");
            y -= descH + 12f;

            FormLabel(panel, "Deep link   " + DeepLinkIdentity.Marker(el.DeepLinkCode), ref y, w);
            MakeText(panel, el.DeepLinkUuid ?? "", new Vector2(16f, y), new Vector2(w - 32f, 18f), 11,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 24f;
            var getEmbedDeepLink = MakeCheckbox(panel, new Vector2(16f, y), "embed in generated docs",
                el.EmbedDeepLinkCode);
            y -= 36f;

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
                GlobalCatalog.RememberLanguage(langInput.text);
                GlobalCatalog.RememberStereotype(langInput.text, stereoInput.text);
                _ctl.SetMeta(id, langInput.text, stereoInput.text);
                _ctl.SetDescription(id, descInput.text);
                _ctl.SetCodeDoc(id, docInput.text);
                if (getEmbedDeepLink() != el.EmbedDeepLinkCode)
                    _ctl.SetEmbedDeepLinkCode(id, getEmbedDeepLink());
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

        /// <summary>Parse a hex literal into a colour. Seeds the broad default swatch palette.</summary>
        private static Color Hex(string h) { ColorUtility.TryParseHtmlString(h, out var c); return c; }

        /// <summary>
        /// A broad default swatch palette for fill / border / text — light tints, saturated hues, and a dark/neutral
        /// ramp — so the presets are visibly distinct rather than a wall of similar pastels. Anything beyond these
        /// comes from the HSV picker and can be saved into the user's custom swatches (below).
        /// </summary>
        private static readonly Color[] StylePalette =
        {
            // light tints (good fills)
            Hex("#FFFFFF"), Hex("#F4F2EC"), Hex("#DCEBFB"), Hex("#DAF1DE"), Hex("#FCF3C9"),
            Hex("#FCE3C4"), Hex("#FBDAD6"), Hex("#ECE1F6"), Hex("#D6F0EE"), Hex("#E3E6EA"),
            // saturated hues (good fills / accents)
            Hex("#E03B3B"), Hex("#F08A24"), Hex("#F4C20D"), Hex("#EAE034"), Hex("#8BC34A"),
            Hex("#2FA84F"), Hex("#14A3A0"), Hex("#29B6D8"), Hex("#2D7FF0"), Hex("#4250C8"),
            Hex("#7E57C2"), Hex("#C840A8"), Hex("#EC5C8D"), Hex("#8D6E63"),
            // dark / neutral ramp (good text + borders)
            Hex("#1A1C20"), Hex("#2E3338"), Hex("#44515E"), Hex("#18345E"), Hex("#14512E"),
            Hex("#5E1A1A"), Hex("#3A1E5E"), Hex("#6B7280"), Hex("#9AA1AA"),
        };

        // --- custom (user-saved) swatches — persisted in PlayerPrefs so they survive sessions ---

        private const string CustomSwatchPrefKey = "trd.style.customSwatches";
        private const int MaxCustomSwatches = 24;

        // Swatch-grid geometry, shared by the height calc and the row builder.
        private const float SwatchSize = 22f;
        private const float SwatchGap = 5f;
        private const int SwatchPerRow = 18;

        private static int SwatchRows(int count) => count <= 0 ? 0 : (count + SwatchPerRow - 1) / SwatchPerRow;

        private static List<Color> LoadCustomSwatches()
        {
            var list = new List<Color>();
            var raw = PlayerPrefs.GetString(CustomSwatchPrefKey, "");
            if (string.IsNullOrEmpty(raw)) return list;
            foreach (var tok in raw.Split(','))
                if (!string.IsNullOrWhiteSpace(tok) && ColorUtility.TryParseHtmlString(tok.Trim(), out var c))
                    list.Add(c);
            return list;
        }

        private static void SaveCustomSwatches(List<Color> list)
        {
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < list.Count; i++)
            {
                if (i > 0) sb.Append(',');
                sb.Append('#').Append(ColorUtility.ToHtmlStringRGBA(list[i]));
            }
            PlayerPrefs.SetString(CustomSwatchPrefKey, sb.ToString());
            PlayerPrefs.Save();
        }

        /// <summary>Add a colour to the front of the saved swatches (de-duped, newest first, capped).</summary>
        private static void AddCustomSwatch(Color c)
        {
            var list = LoadCustomSwatches();
            string key = ColorUtility.ToHtmlStringRGBA(c);
            list.RemoveAll(x => ColorUtility.ToHtmlStringRGBA(x) == key);
            list.Insert(0, c);
            if (list.Count > MaxCustomSwatches) list.RemoveRange(MaxCustomSwatches, list.Count - MaxCustomSwatches);
            SaveCustomSwatches(list);
        }

        private static void RemoveCustomSwatch(Color c)
        {
            var list = LoadCustomSwatches();
            string key = ColorUtility.ToHtmlStringRGBA(c);
            list.RemoveAll(x => ColorUtility.ToHtmlStringRGBA(x) == key);
            SaveCustomSwatches(list);
        }

        private static readonly string[] StyleFonts =
            { "(default)", "Arial", "Helvetica", "Courier New", "Verdana", "Georgia", "Times New Roman" };

        private void ShowStyleEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out _)) return;
            bool has = _styles.TryGetValue(id, out var cur);
            Color fill = has ? cur.Fill : new Color(1f, 1f, 1f, 1f);
            Color border = has ? cur.Border : new Color(0.42f, 0.45f, 0.51f, 1f);
            Color text = has ? cur.Text : new Color(0.13f, 0.15f, 0.19f, 1f);
            string fontName = has ? (cur.FontName ?? "") : "";
            int size = has && cur.FontSize > 0 ? cur.FontSize : 15;
            ShowStyleEditorState(id, screenPos, fill, border, text, fontName, size);
        }

        /// <summary>
        /// The style editor, built from explicit current values so it can re-open in place (preserving in-progress
        /// edits) after the saved-swatch list changes. Each colour channel shows the broad default palette plus the
        /// user's saved swatches; "Pick…" opens the HSV wheel, "＋ Save" stores the current colour as a swatch, and
        /// Alt-clicking a saved swatch removes it.
        /// </summary>
        private void ShowStyleEditorState(ElementId id, Vector2 screenPos,
            Color fill, Color border, Color text, string fontName, int size)
        {
            if (!_model.TryGet(id, out var el)) return;
            CloseMenu();

            int customCount = LoadCustomSwatches().Count;
            int rowsPerChannel = SwatchRows(StylePalette.Length) + SwatchRows(customCount);
            float channelH = 22f + rowsPerChannel * (SwatchSize + SwatchGap) + (customCount > 0 ? 8f : 0f) + 10f;

            float w = 520f;
            float h = 50f + 3f * channelH + 34f /*font*/ + 34f /*size*/ + 22f /*hint*/ + 56f /*buttons*/;
            var panel = BeginModal(w, h, "Style   —   " + (el.Kind == ElementKind.Note ? "Note" : el.Name));
            float y = -50f;

            void Reopen() => ShowStyleEditorState(id, screenPos, fill, border, text, fontName, size);

            y = SwatchRow(panel, "Fill", y, w, fill, c => fill = c, Reopen);
            y = SwatchRow(panel, "Border / line", y, w, border, c => border = c, Reopen);
            y = SwatchRow(panel, "Text", y, w, text, c => text = c, Reopen);

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

            MakeText(panel, "Pick… then ＋ Save to add a swatch · Alt-click a saved swatch to remove",
                new Vector2(16f, y), new Vector2(w - 32f, 18f), 11, LabelColor, TextAnchor.MiddleLeft);

            void Submit()
            {
                CloseMenu();
                BeginGeoEdit(); // style is undoable via the geometry history (Ctrl/Cmd+Z)
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
                () => { CloseMenu(); BeginGeoEdit(); _styles.Remove(id); RebuildFromModel(); SetSelected(id); Flash("style reset"); });
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        private float SwatchRow(RectTransform panel, string label, float y, float w, Color initial,
            Action<Color> onPick, Action requestRefresh)
        {
            // Header line: label (left), live preview + Pick… + ＋ Save (right). The preview holds the live value,
            // so it doubles as the picker's starting colour and as what "＋ Save" stores.
            MakeText(panel, label, new Vector2(16f, y), new Vector2(180f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            var preview = MakeSwatch(panel, new Vector2(w - 190f, y + 1f), SwatchSize, initial);
            MakeButton(panel, "Pick…", new Vector2(w - 160f, y), new Vector2(64f, 22f),
                new Color(0.24f, 0.30f, 0.40f, 1f),
                () => ShowColorPicker(label, preview.color, c => { onPick(c); preview.color = c; }));
            MakeButton(panel, "＋ Save", new Vector2(w - 92f, y), new Vector2(76f, 22f),
                new Color(0.20f, 0.40f, 0.34f, 1f),
                () => { AddCustomSwatch(preview.color); Flash("swatch saved"); requestRefresh(); });
            y -= 22f;

            // Default palette grid, then the user's saved swatches (newest first; Alt-click to remove).
            y = SwatchGrid(panel, StylePalette, y, false, onPick, preview, requestRefresh);
            var customs = LoadCustomSwatches();
            if (customs.Count > 0)
            {
                y -= 8f;
                y = SwatchGrid(panel, customs.ToArray(), y, true, onPick, preview, requestRefresh);
            }
            return y - 10f;
        }

        /// <summary>Lay out a colour array as a wrapped grid of clickable swatches; returns y past the last row.</summary>
        private float SwatchGrid(RectTransform panel, Color[] colors, float y, bool isCustom,
            Action<Color> onPick, Image preview, Action requestRefresh)
        {
            float x = 16f;
            int col = 0;
            foreach (var c in colors)
            {
                var cap = c;
                MakeButton(panel, "", new Vector2(x, y), new Vector2(SwatchSize, SwatchSize), cap, () =>
                {
                    if (isCustom && AltDown()) { RemoveCustomSwatch(cap); Flash("swatch removed"); requestRefresh(); }
                    else { onPick(cap); preview.color = cap; }
                });
                if (++col >= SwatchPerRow) { col = 0; x = 16f; y -= SwatchSize + SwatchGap; }
                else x += SwatchSize + SwatchGap;
            }
            if (col != 0) y -= SwatchSize + SwatchGap; // close a partial last row
            return y;
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

        // --- quick comment / inline-doc editor (right-click a node or a member) ---

        /// <summary>
        /// Quick single-field editor for an element's source-code documentation comment. This is distinct from the
        /// UML/product Description and is what generation renders above the type / field / method.
        /// </summary>
        private void ShowCommentEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            CloseMenu();

            bool isMember = KindInfo.IsMember(el.Kind);
            string what = isMember ? (el.Kind == ElementKind.Field ? "field" : "method") : "element";

            float w = 460f, h = 244f;
            var panel = BeginModal(w, h, "Comment   —   " + Ellipsize(string.IsNullOrEmpty(el.Name) ? what : el.Name, 36));

            float y = -50f;
            FormLabel(panel, "Inline doc-comment   (rendered above this " + what + " in generated code)", ref y, w);
            var input = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 108f, el.CodeDoc ?? "",
                "Comment text — becomes the doc-comment above this " + what + " in generated code…");

            void Submit()
            {
                CloseMenu();
                _ctl.SetCodeDoc(id, input.text);
                // A member's comment is shown via its owning node; rebuild and reselect the node either way.
                ElementId owner = isMember && el.Parent.IsValid ? el.Parent : id;
                RebuildFromModel();
                SetSelected(owner);
                Flash(OwnerHasCode(owner)
                    ? "comment saved — regenerate code to refresh the inline comments"
                    : "comment saved");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "OK", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
            FocusInput(input);
        }

        /// <summary>True if the node already has generated or imported code (so an edited comment needs a regen to land in source).</summary>
        private bool OwnerHasCode(ElementId nodeId) =>
            _model.TryGet(nodeId, out var n)
            && (!string.IsNullOrEmpty(n.Code)
                || (!string.IsNullOrEmpty(n.SourceFile) && _sourceFiles.ContainsKey(n.SourceFile)));

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

            FormLabel(panel, "Description   (UML/product note)", ref y, w);
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
                    _placements.SetPos(id, ScreenToLayer(screenPos));
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
            string edgeLanguage = LanguageForEdge(e);

            float w = 470f, h = 420f;
            var panel = BeginModal(w, h, "Relationship   —   multiplicity · label · constraint");

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

            FormLabel(panel, "Constraint   (drawn in braces — e.g. {ordered}, {xor}, a guard)", ref y, w);
            var constraintInput = MakeCatalogCombobox(panel, new Vector2(16f, y), w - 32f, e.Constraint,
                "{ordered}, {unique}, {subset}…", GlobalCatalog.ConstraintsForLanguage(edgeLanguage),
                value => GlobalCatalog.RememberConstraint(edgeLanguage, value));
            y -= 38f;

            void Submit()
            {
                CloseMenu();
                GlobalCatalog.RememberConstraint(edgeLanguage, constraintInput.text);
                _ctl.SetEdgeMeta(edge, labelInput.text, srcInput.text, tgtInput.text, constraintInput.text);
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

        private string LanguageForElement(ElementId id) =>
            _model.TryGet(id, out var el) ? el.Language : null;

        private string LanguageForEdge(ModelEdge edge)
        {
            string from = LanguageForElement(edge.From);
            if (!string.IsNullOrWhiteSpace(from)) return from;
            return LanguageForElement(edge.To);
        }

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

        private InputField MakeCatalogCombobox(RectTransform parent, Vector2 topLeft, float width, string value,
            string placeholder, List<string> options, Action<string> remember)
        {
            const float dropW = 36f;
            const float addW = 56f;
            const float gap = 6f;
            float inputW = Mathf.Max(120f, width - dropW - addW - gap * 2f);
            var input = MakeInput(parent, topLeft, inputW, value, placeholder);
            var opts = new List<string>(options ?? new List<string>());
            opts.Sort(StringComparer.OrdinalIgnoreCase);

            GameObject list = null;
            void CloseList()
            {
                if (list != null)
                {
                    Destroy(list);
                    list = null;
                }
            }

            void AddCurrent()
            {
                if (string.IsNullOrWhiteSpace(input.text)) return;
                remember?.Invoke(input.text);
                if (!ContainsIgnoreCase(opts, input.text)) opts.Add(input.text.Trim());
                opts.Sort(StringComparer.OrdinalIgnoreCase);
                Flash("saved option");
            }

            void OpenList()
            {
                CloseList();
                opts.Sort(StringComparer.OrdinalIgnoreCase);
                if (opts.Count == 0) return;
                parent.SetAsLastSibling();

                const float ih = 28f;
                float lh = Mathf.Min(opts.Count, 8) * ih + 4f;
                list = new GameObject("ComboList", typeof(RectTransform));
                var lrt = (RectTransform)list.transform;
                lrt.SetParent(parent, false);
                lrt.anchorMin = lrt.anchorMax = new Vector2(0f, 1f);
                lrt.pivot = new Vector2(0f, 1f);
                lrt.sizeDelta = new Vector2(inputW, lh);
                lrt.anchoredPosition = topLeft + new Vector2(0f, -34f);
                list.AddComponent<Image>().color = new Color(0.13f, 0.15f, 0.19f, 0.99f);
                list.AddComponent<RectMask2D>();

                var content = new GameObject("C", typeof(RectTransform));
                var crt = (RectTransform)content.transform;
                crt.SetParent(lrt, false);
                crt.anchorMin = new Vector2(0f, 1f);
                crt.anchorMax = new Vector2(1f, 1f);
                crt.pivot = new Vector2(0.5f, 1f);
                crt.sizeDelta = new Vector2(0f, opts.Count * ih);
                crt.anchoredPosition = Vector2.zero;

                var scroll = list.AddComponent<ScrollRect>();
                scroll.content = crt;
                scroll.viewport = lrt;
                scroll.horizontal = false;
                scroll.movementType = ScrollRect.MovementType.Clamped;

                float iy = 0f;
                foreach (var option in opts)
                {
                    var ov = option;
                    var igo = new GameObject("I", typeof(RectTransform));
                    var irt = (RectTransform)igo.transform;
                    irt.SetParent(crt, false);
                    irt.anchorMin = irt.anchorMax = new Vector2(0f, 1f);
                    irt.pivot = new Vector2(0f, 1f);
                    irt.sizeDelta = new Vector2(inputW, ih);
                    irt.anchoredPosition = new Vector2(0f, iy);
                    var iimg = igo.AddComponent<Image>();
                    iimg.color = new Color(0.18f, 0.20f, 0.25f, 1f);
                    var ibtn = igo.AddComponent<Button>();
                    ibtn.targetGraphic = iimg;
                    ibtn.onClick.AddListener(() => { input.text = ov; CloseList(); });
                    MakeText(irt, ov, new Vector2(8f, 0f), new Vector2(inputW - 12f, ih), 14,
                        new Color(0.9f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft);
                    iy -= ih;
                }
            }

            float x = topLeft.x + inputW + gap;
            MakeButton(parent, "v", new Vector2(x, topLeft.y), new Vector2(dropW, 32f),
                new Color(0.18f, 0.22f, 0.28f, 1f), () => { if (list != null) CloseList(); else OpenList(); });
            MakeButton(parent, "Add", new Vector2(x + dropW + gap, topLeft.y), new Vector2(addW, 32f),
                new Color(0.20f, 0.40f, 0.34f, 1f), AddCurrent);
            return input;
        }

        private static bool ContainsIgnoreCase(List<string> options, string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return true;
            string trimmed = value.Trim();
            foreach (var option in options)
                if (string.Equals(option, trimmed, StringComparison.OrdinalIgnoreCase))
                    return true;
            return false;
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
