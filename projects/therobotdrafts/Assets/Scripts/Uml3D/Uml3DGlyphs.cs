using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Wireframe widget glyphs drawn as live uGUI children of a 3-D node's face canvas (see
    /// <see cref="UmlNode3D.BuildFace"/>). Each concrete widget kind renders a distinct lo-fi glyph composed from
    /// a handful of shared primitives (filled panels, thin rules, centered labels, small markers) — the same
    /// vocabulary the legacy 2-D <c>UmlNodeView</c> used, lifted into a static helper so the 3-D face path and a
    /// future 2-D path share one implementation. No meshes, no RenderTextures: a wireframe is flat by definition,
    /// and the face canvas already provides a legible, always-full-bright surface.
    ///
    /// PlantUML-<c>salt</c> parity is the target vocabulary (button, text field, checkbox/radio, listbox, table,
    /// tab, tree, …). Item-bearing widgets (table columns, list/tree/dropdown/menu/tabs entries) source their
    /// items from the node's Field members — the same convention an ERD table uses for its columns.
    /// </summary>
    public static class WireframeGlyph
    {
        /// <summary>A resolved palette for one widget: surface (card fill), border, text, and a control accent.</summary>
        public struct Colors
        {
            public Color Surface;   // card / panel fill (opaque)
            public Color SurfaceAlt;// alternate row / recessed fill
            public Color Border;    // thin control border
            public Color Text;      // label / value text
            public Color Muted;     // placeholder / secondary text
            public Color Accent;    // primary control fill (button, progress, slider thumb)
            public Color Track;     // inactive track (progress / slider)
        }

        /// <summary>Default lo-fi palette derived from a kind hue (used when no styleguide theme is loaded).</summary>
        public static Colors FromHue(Color hue)
        {
            Color surface = Color.Lerp(hue, Color.white, 0.90f);
            return new Colors
            {
                Surface = surface,
                SurfaceAlt = Color.Lerp(hue, Color.white, 0.82f),
                Border = Color.Lerp(hue, new Color(0.25f, 0.27f, 0.32f, 1f), 0.45f),
                Text = new Color(0.13f, 0.15f, 0.19f, 1f),
                Muted = new Color(0.42f, 0.45f, 0.52f, 1f),
                Accent = hue.a < 0.02f ? new Color(0.31f, 0.64f, 0.63f, 1f) : Color.Lerp(hue, Color.white, 0.25f),
                Track = Color.Lerp(hue, Color.white, 0.70f),
            };
        }

        /// <summary>
        /// Build the glyph for <paramref name="kind"/> as children of <paramref name="face"/>. <paramref name="items"/>
        /// are the widget's Field-member items (table columns, list entries, …); <paramref name="name"/> is the
        /// widget's label/placeholder text. The face canvas is already sized + masked by the caller.
        /// </summary>
        public static void Build(ElementKind kind, string name, List<string> items, RectTransform face,
            Colors col, Font font)
        {
            if (font == null) font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            float w = face.sizeDelta.x;
            float h = face.sizeDelta.y;
            items = items ?? new List<string>();

            switch (kind)
            {
                case ElementKind.UiWidget:
                case ElementKind.Card:        BuildCard(face, name, items, w, h, col, font); break;
                case ElementKind.Button:      BuildButton(face, name, w, h, col, font); break;
                case ElementKind.Label:       BuildLabel(face, name, w, h, col, font); break;
                case ElementKind.Link:        BuildLink(face, name, w, h, col, font); break;
                case ElementKind.TextField:   BuildTextField(face, name, w, h, col, font, false); break;
                case ElementKind.Password:    BuildTextField(face, name, w, h, col, font, true); break;
                case ElementKind.TextArea:    BuildTextArea(face, name, w, h, col, font); break;
                case ElementKind.Checkbox:    BuildCheckable(face, name, w, h, col, font, false); break;
                case ElementKind.Radio:       BuildCheckable(face, name, w, h, col, font, true); break;
                case ElementKind.Dropdown:    BuildDropdown(face, name, items, w, h, col, font); break;
                case ElementKind.List:        BuildList(face, items, w, h, col, font); break;
                case ElementKind.Table:       BuildTable(face, items, w, h, col, font); break;
                case ElementKind.Tree:        BuildTree(face, items, w, h, col, font); break;
                case ElementKind.Image:       BuildImage(face, name, w, h, col, font); break;
                case ElementKind.Tabs:        BuildTabs(face, items, w, h, col, font); break;
                case ElementKind.Menu:        BuildMenu(face, items, w, h, col, font); break;
                case ElementKind.Toolbar:     BuildMenu(face, items, w, h, col, font); break;
                case ElementKind.Breadcrumb:  BuildBreadcrumb(face, items, w, h, col, font); break;
                case ElementKind.Separator:   BuildSeparator(face, w, h, col); break;
                case ElementKind.Progress:    BuildProgress(face, name, w, h, col, font); break;
                case ElementKind.Slider:      BuildSlider(face, name, w, h, col, font); break;
                default:                      BuildLabel(face, name, w, h, col, font); break;
            }
        }

        // =========================================================================================
        // primitives — the shared lo-fi vocabulary
        // =========================================================================================

        private static RectTransform NewChild(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            return rt;
        }

        /// <summary>An opaque filled rectangle with an optional 1px border outline.</summary>
        private static RectTransform Panel(string name, Transform parent, float cx, float cy, float w, float h,
            Color fill, Color? border = null)
        {
            var rt = NewChild(name, parent);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = new Vector2(cx, cy);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = fill;
            img.raycastTarget = false;
            if (border.HasValue)
            {
                var o = rt.gameObject.AddComponent<Outline>();
                o.effectColor = border.Value;
                o.effectDistance = new Vector2(1f, 1f);
            }
            return rt;
        }

        /// <summary>A horizontal rule spanning a given width, centered on cx, at vertical offset y (canvas-center origin).</summary>
        private static RectTransform HBar(Transform parent, float cx, float y, float width, float thickness, Color c)
        {
            var rt = NewChild("HBar", parent);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(width, thickness);
            rt.anchoredPosition = new Vector2(cx, y);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = false;
            return rt;
        }

        private static RectTransform VBar(Transform parent, float cx, float cy, float thickness, float height, Color c)
        {
            var rt = NewChild("VBar", parent);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(thickness, height);
            rt.anchoredPosition = new Vector2(cx, cy);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = false;
            return rt;
        }

        /// <summary>A small filled square marker (checkbox box, dropdown caret base, etc.).</summary>
        private static RectTransform Square(Transform parent, float cx, float cy, float size, Color fill, Color border)
            => Panel("Square", parent, cx, cy, size, size, fill, border);

        /// <summary>A small filled disc (radio dot, slider thumb) approximated by a square — crisp at lo-fi scale.</summary>
        private static RectTransform Disc(Transform parent, float cx, float cy, float size, Color fill)
            => Panel("Disc", parent, cx, cy, size, size, fill);

        private static Text Label(RectTransform parent, string text, float cx, float cy, float w, float h,
            int size, Color color, TextAnchor align = TextAnchor.MiddleCenter, bool bold = false, Font font = null)
        {
            var rt = NewChild("Label", parent);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = new Vector2(cx, cy);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font ?? (font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.alignment = align;
            t.fontStyle = bold ? FontStyle.Bold : FontStyle.Normal;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            return t;
        }

        // =========================================================================================
        // per-kind glyphs
        // =========================================================================================

        private static void BuildButton(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            const float pad = 10f;
            float bw = Mathf.Min(w - pad * 2f, Mathf.Max(48f, name.Length * 8f + 28f));
            float bh = Mathf.Min(h - pad * 2f, 30f);
            Panel("Button", face, 0f, 0f, bw, bh, col.Accent, col.Border);
            Label(face, name, 0f, 0f, bw - 8f, bh, 14, new Color(1f, 1f, 1f, 1f), TextAnchor.MiddleCenter, true, font);
        }

        private static void BuildLabel(RectTransform face, string name, float w, float h, Colors col, Font font)
            => Label(face, name, 0f, 0f, w - 16f, h, 14, col.Text, TextAnchor.MiddleLeft, false, font);

        private static void BuildLink(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            // Underlined text — a thin rule beneath the label width.
            float tw = Mathf.Min(w - 16f, name.Length * 7f + 8f);
            Label(face, name, 0f, 1f, w - 16f, h, 14, col.Accent, TextAnchor.MiddleLeft, false, font);
            HBar(face, 0f, -h * 0.5f + 8f, tw, 1.2f, col.Accent);
        }

        private static void BuildTextField(RectTransform face, string name, float w, float h, Colors col,
            Font font, bool masked)
        {
            const float pad = 10f;
            float fh = Mathf.Min(h - pad * 2f, 26f);
            Panel("Field", face, 0f, 0f, w - pad * 2f, fh, col.Surface, col.Border);
            string shown = masked ? new string('•', Mathf.Max(4, name.Length)) : name;
            Label(face, shown, 0f, 0f, w - pad * 2f - 10f, fh, 13,
                string.IsNullOrEmpty(name) ? col.Muted : col.Text, TextAnchor.MiddleLeft, false, font);
        }

        private static void BuildTextArea(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            const float pad = 8f;
            Panel("Area", face, 0f, 0f, w - pad * 2f, h - pad * 2f, col.Surface, col.Border);
            var t = Label(face, name, 0f, 0f, w - pad * 2f - 8f, h - pad * 2f - 6f, 13,
                string.IsNullOrEmpty(name) ? col.Muted : col.Text, TextAnchor.UpperLeft, false, font);
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Truncate;
        }

        private static void BuildCheckable(RectTransform face, string name, float w, float h, Colors col,
            Font font, bool radio)
        {
            float box = Mathf.Min(16f, h - 8f);
            float left = -w * 0.5f + 12f;
            if (radio) Disc(face, left + box * 0.5f, 0f, box, col.Surface);
            else Square(face, left + box * 0.5f, 0f, box, col.Surface, col.Border);
            Label(face, name, left + box + 4f, 0f, w - (left + box + 4f) - 6f - w * 0.5f, h, 13,
                col.Text, TextAnchor.MiddleLeft, false, font);
        }

        private static void BuildDropdown(RectTransform face, string name, List<string> items, float w, float h,
            Colors col, Font font)
        {
            const float pad = 10f;
            float dh = Mathf.Min(h - pad * 2f, 26f);
            float right = w * 0.5f - pad;
            Panel("Dropdown", face, 0f, 0f, w - pad * 2f, dh, col.Surface, col.Border);
            string shown = items.Count > 0 ? items[0] : name;
            Label(face, shown, -w * 0.25f, 0f, w - pad * 4f, dh, 13,
                string.IsNullOrEmpty(shown) ? col.Muted : col.Text, TextAnchor.MiddleLeft, false, font);
            // Caret ▾ as two thin bars forming a downward triangle.
            float cx = right - 8f;
            HBar(face, cx - 4f, 2f, 5f, 1.4f, col.Muted);
            HBar(face, cx, -2f, 5f, 1.4f, col.Muted);
            HBar(face, cx + 4f, 2f, 5f, 1.4f, col.Muted);
        }

        private static void BuildList(RectTransform face, List<string> items, float w, float h, Colors col, Font font)
        {
            const float pad = 8f;
            Panel("ListBox", face, 0f, 0f, w - pad * 2f, h - pad * 2f, col.Surface, col.Border);
            if (items.Count == 0) items = new List<string> { "item 1", "item 2", "item 3" };
            Rows(face, items, w - pad * 2f - 8f, h - pad * 2f, pad, col, font, numbered: false, indentGlyph: null);
        }

        private static void BuildTable(RectTransform face, List<string> cols, float w, float h, Colors col, Font font)
        {
            const float pad = 6f;
            float innerW = w - pad * 2f, innerH = h - pad * 2f;
            Panel("Table", face, 0f, 0f, innerW, innerH, col.Surface, col.Border);
            if (cols.Count == 0) cols = new List<string> { "Name", "Value" };

            float top = innerH * 0.5f;       // canvas-center origin, working downward
            float rowH = Mathf.Min(18f, innerH / (cols.Count > 0 ? 3f : 1f));
            float headerY = top - rowH * 0.5f;
            // Header band + column dividers.
            HBar(face, 0f, headerY, innerW, rowH, col.SurfaceAlt);
            float cw = innerW / cols.Count;
            for (int i = 1; i < cols.Count; i++)
                VBar(face, -innerW * 0.5f + cw * i, 0f, 1f, innerH, col.Border);
            for (int i = 0; i < cols.Count; i++)
                Label(face, cols[i], -innerW * 0.5f + cw * (i + 0.5f), headerY, cw - 6f, rowH, 12,
                    col.Text, TextAnchor.MiddleCenter, true, font);
            // A couple of illustrative empty data rows.
            float y = headerY - rowH;
            for (int r = 0; r < 2 && y > -innerH * 0.5f + rowH * 0.5f; r++)
            {
                HBar(face, 0f, y, innerW, 1f, new Color(col.Border.r, col.Border.g, col.Border.b, 0.5f));
                y -= rowH;
            }
        }

        private static void BuildTree(RectTransform face, List<string> items, float w, float h, Colors col, Font font)
        {
            const float pad = 8f;
            Panel("Tree", face, 0f, 0f, w - pad * 2f, h - pad * 2f, col.Surface, col.Border);
            if (items.Count == 0) items = new List<string> { "root", "branch", "leaf" };
            Rows(face, items, w - pad * 2f - 8f, h - pad * 2f, pad, col, font, numbered: false, indentGlyph: "▸");
        }

        private static void BuildImage(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            const float pad = 8f;
            float iw = w - pad * 2f, ih = h - pad * 2f;
            Panel("Img", face, 0f, 0f, iw, ih, col.SurfaceAlt, col.Border);
            // Diagonal-X placeholder (two crossed rules).
            float hw = iw * 0.5f - 6f, hh = ih * 0.5f - 6f;
            LineX(face, -hw, -hh, hw, hh, col.Border);
            LineX(face, -hw, hh, hw, -hh, col.Border);
            if (!string.IsNullOrEmpty(name))
                Label(face, name, 0f, -ih * 0.5f + 8f, iw - 8f, 12f, 11, col.Muted, TextAnchor.MiddleCenter, false, font);
        }

        private static void BuildTabs(RectTransform face, List<string> tabs, float w, float h, Colors col, Font font)
        {
            const float pad = 6f;
            if (tabs.Count == 0) tabs = new List<string> { "Tab 1", "Tab 2", "Tab 3" };
            float innerW = w - pad * 2f, innerH = h - pad * 2f;
            float stripH = Mathf.Min(22f, innerH * 0.3f);
            float top = innerH * 0.5f;
            // Tab strip.
            float tw = innerW / Mathf.Max(1, tabs.Count);
            for (int i = 0; i < tabs.Count; i++)
            {
                float cx = -innerW * 0.5f + tw * (i + 0.5f);
                Panel("Tab", face, cx, top - stripH * 0.5f, tw - 4f, stripH,
                    i == 0 ? col.Surface : col.SurfaceAlt, col.Border);
                Label(face, tabs[i], cx, top - stripH * 0.5f, tw - 8f, stripH, 12,
                    col.Text, TextAnchor.MiddleCenter, i == 0, font);
            }
            // Body.
            float bodyH = innerH - stripH - 4f;
            Panel("TabBody", face, 0f, -innerH * 0.5f + bodyH * 0.5f, innerW, bodyH, col.Surface, col.Border);
        }

        private static void BuildMenu(RectTransform face, List<string> items, float w, float h, Colors col, Font font)
        {
            const float pad = 6f;
            Panel("Bar", face, 0f, 0f, w - pad * 2f, h - pad * 2f, col.SurfaceAlt, col.Border);
            if (items.Count == 0) items = new List<string> { "File", "Edit", "View", "Help" };
            float itemW = (w - pad * 2f) / items.Count;
            for (int i = 0; i < items.Count; i++)
                Label(face, items[i], -w * 0.5f + pad + itemW * (i + 0.5f), 0f, itemW - 4f, h - pad * 2f, 12,
                    col.Text, TextAnchor.MiddleCenter, false, font);
        }

        private static void BuildBreadcrumb(RectTransform face, List<string> items, float w, float h, Colors col, Font font)
        {
            if (items.Count == 0) items = new List<string> { "Home", "Section", "Page" };
            // Lay the crumbs left-to-right separated by ›, wrapped to the face width.
            var joined = new System.Text.StringBuilder();
            for (int i = 0; i < items.Count; i++)
            {
                if (i > 0) joined.Append(" › ");
                joined.Append(items[i]);
            }
            Label(face, joined.ToString(), 0f, 0f, w - 16f, h, 13, col.Text, TextAnchor.MiddleLeft, false, font);
        }

        private static void BuildSeparator(RectTransform face, float w, float h, Colors col)
            => HBar(face, 0f, 0f, w - 12f, 2f, col.Border);

        private static void BuildProgress(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            const float pad = 12f;
            float trackH = Mathf.Min(12f, h - pad * 2f);
            float trackW = w - pad * 2f;
            Panel("Track", face, 0f, 0f, trackW, trackH, col.Track, col.Border);
            // Fill ~60% (illustrative; name may carry a percentage but the lo-fi bar is schematic).
            float fillW = trackW * 0.6f;
            Panel("Fill", face, -trackW * 0.5f + fillW * 0.5f, 0f, fillW, trackH - 2f, col.Accent);
            if (!string.IsNullOrEmpty(name))
                Label(face, name, 0f, trackH * 0.5f + 6f, trackW, 12f, 11, col.Muted,
                    TextAnchor.MiddleCenter, false, font);
        }

        private static void BuildSlider(RectTransform face, string name, float w, float h, Colors col, Font font)
        {
            const float pad = 12f;
            float trackH = 4f;
            float trackW = w - pad * 2f;
            Panel("Track", face, 0f, 0f, trackW, trackH, col.Track);
            Disc(face, trackW * 0.1f, 0f, 12f, col.Accent); // thumb near the left
            if (!string.IsNullOrEmpty(name))
                Label(face, name, 0f, 10f, trackW, 12f, 11, col.Muted,
                    TextAnchor.MiddleCenter, false, font);
        }

        private static void BuildCard(RectTransform face, string title, List<string> lines, float w, float h,
            Colors col, Font font)
        {
            const float pad = 8f;
            Panel("Card", face, 0f, 0f, w - pad * 2f, h - pad * 2f, col.Surface, col.Border);
            float top = (h - pad * 2f) * 0.5f;
            if (!string.IsNullOrEmpty(title))
            {
                Label(face, title, 0f, top - 12f, w - pad * 4f, 18f, 14, col.Text,
                    TextAnchor.UpperLeft, true, font);
                HBar(face, 0f, top - 26f, w - pad * 4f, 1f, col.Border);
            }
            // Optional body lines from the card's Field members.
            float y = top - 38f;
            foreach (var line in lines)
            {
                if (y < -(h - pad * 2f) * 0.5f + 6f) break;
                Label(face, line, 0f, y, w - pad * 4f, 14f, 12, col.Muted,
                    TextAnchor.UpperLeft, false, font);
                y -= 16f;
            }
        }

        // =========================================================================================
        // shared row-stack helper for list / tree / card body
        // =========================================================================================

        /// <summary>Stack <paramref name="items"/> top-down inside the face, with optional numbering or indent glyphs.</summary>
        private static void Rows(RectTransform face, List<string> items, float width, float height, float pad,
            Colors col, Font font, bool numbered, string indentGlyph)
        {
            int n = Mathf.Max(1, items.Count);
            float rowH = Mathf.Min(18f, height / n);
            float topY = (height * 0.5f) - pad - rowH * 0.5f;
            float leftX = -width * 0.5f + pad;
            for (int i = 0; i < n; i++)
            {
                float y = topY - i * rowH;
                if (y < -height * 0.5f + pad) break;
                string prefix = numbered ? (i + 1) + ". "
                    : (indentGlyph != null ? new string(' ', i * 2) + indentGlyph + " " : "");
                Label(face, prefix + items[i], leftX + width * 0.5f, y, width - 6f, rowH, 12,
                    col.Text, TextAnchor.MiddleLeft, false, font);
            }
        }

        /// <summary>A thin diagonal rule between two points (canvas-center origin) as a rotated thin Image.</summary>
        private static void LineX(RectTransform face, float x0, float y0, float x1, float y1, Color c)
        {
            float dx = x1 - x0, dy = y1 - y0;
            float len = Mathf.Sqrt(dx * dx + dy * dy);
            if (len < 0.5f) return;
            float cx = (x0 + x1) * 0.5f, cy = (y0 + y1) * 0.5f;
            float ang = Mathf.Atan2(dy, dx) * Mathf.Rad2Deg;
            var rt = NewChild("Diag", face);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(len, 1.4f);
            rt.anchoredPosition = new Vector2(cx, cy);
            rt.localEulerAngles = new Vector3(0f, 0f, ang);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = c;
            img.raycastTarget = false;
        }
    }
}
