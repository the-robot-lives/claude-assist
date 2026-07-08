using System.Collections.Generic;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// Wireframe code generation for a Screen/Panel region — the counterpart of <see cref="CodeSkeleton"/> for UI
    /// mockups. Two deterministic (offline, no-LLM) emitters:
    /// <list type="bullet">
    /// <item><see cref="GenerateHtml"/> — a standalone HTML document whose element tree mirrors the widget tree
    /// (button, input, table, …) styled by inline CSS, so the mockup opens in any browser.</item>
    /// <item><see cref="GenerateSalt"/> — a PlantUML <c>salt</c> wireframe block, the canonical interchange format
    /// for UI wireframes (PlantUML <c>salt</c> parity being the feature's target vocabulary).</item>
    /// </list>
    /// When a resolved styleguide theme is supplied, tokens are emitted as a <c>:root{}</c> CSS-variable block and
    /// referenced by class; otherwise inline hex defaults keep the mockup self-contained.
    /// </summary>
    public static class WireframeSkeleton
    {
        /// <summary>An optional resolved-theme CSS-var block (e.g. <c>--surface:#fff;…</c>); null ⇒ inline defaults.</summary>
        public static string ThemeRootVars;

        /// <summary>Generate the standalone HTML mockup for <paramref name="ctx"/>.</summary>
        public static string GenerateHtml(WireframeContext ctx)
        {
            var sb = new StringBuilder();
            string title = string.IsNullOrWhiteSpace(ctx.Name) ? "Wireframe" : ctx.Name.Trim();
            string tag = ctx.RegionKind == ElementKind.Screen ? "Screen" : "Panel";

            sb.Append("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" "
                + "content=\"width=device-width, initial-scale=1\">\n<title>").Append(Escape(title))
              .Append(" — wireframe</title>\n<style>\n");
            if (!string.IsNullOrEmpty(ThemeRootVars))
                sb.Append(":root{\n").Append(ThemeRootVars).Append("\n}\n");
            sb.Append(HtmlCss()).Append("\n</style>\n</head>\n<body>\n");
            sb.Append("<!-- ").Append(tag).Append(": ").Append(Escape(title)).Append(" — generated wireframe mockup -->\n");
            sb.Append("<main class=\"wf-screen\">\n");
            sb.Append("  <header class=\"wf-title\">").Append(Escape(title)).Append("</header>\n");
            sb.Append("  <section class=\"wf-body\">\n");
            foreach (var w in ctx.Widgets)
            {
                string html = WidgetHtml(w);
                foreach (var line in html.Replace("\r\n", "\n").Split('\n'))
                    sb.Append("    ").Append(line).Append('\n');
            }
            sb.Append("  </section>\n</main>\n</body>\n</html>\n");
            return sb.ToString();
        }

        /// <summary>Generate the PlantUML <c>salt</c> wireframe block for <paramref name="ctx"/>.</summary>
        public static string GenerateSalt(WireframeContext ctx)
        {
            var sb = new StringBuilder();
            string title = string.IsNullOrWhiteSpace(ctx.Name) ? "Wireframe" : ctx.Name.Trim();
            sb.Append("@startsalt\n");
            sb.Append("{^\n");
            sb.Append("  {+").Append(EscapeSalt(title)).Append("+}\n");
            foreach (var w in ctx.Widgets)
                AppendSaltWidget(sb, w, "  ");
            sb.Append("}\n");
            sb.Append("@endsalt\n");
            return sb.ToString();
        }

        // --- HTML ---

        private static string WidgetHtml(WireframeContext.Widget w)
        {
            string label = Escape(w.Label ?? "");
            switch (w.Kind)
            {
                case ElementKind.Panel:
                    return PanelHtml(w);
                case ElementKind.Button:
                    return "<button class=\"wf-btn\">" + label + "</button>";
                case ElementKind.Label:
                    return "<span class=\"wf-label\">" + label + "</span>";
                case ElementKind.Link:
                    return "<a class=\"wf-link\" href=\"#\">" + label + "</a>";
                case ElementKind.TextField:
                    return "<input class=\"wf-input\" type=\"text\" placeholder=\"" + label + "\">";
                case ElementKind.Password:
                    return "<input class=\"wf-input\" type=\"password\" placeholder=\"" + label + "\">";
                case ElementKind.TextArea:
                    return "<textarea class=\"wf-textarea\" placeholder=\"" + label + "\"></textarea>";
                case ElementKind.Checkbox:
                    return "<label class=\"wf-check\"><input type=\"checkbox\"> " + label + "</label>";
                case ElementKind.Radio:
                    return "<label class=\"wf-check\"><input type=\"radio\"> " + label + "</label>";
                case ElementKind.Dropdown:
                    return SelectHtml(label, w.Items);
                case ElementKind.List:
                    return ListHtml("ul", w.Items.Count > 0 ? w.Items : new List<string> { label });
                case ElementKind.Table:
                    return TableHtml(w.Items);
                case ElementKind.Tree:
                    return ListHtml("ul wf-tree", w.Items.Count > 0 ? w.Items : new List<string> { label });
                case ElementKind.Image:
                    return "<div class=\"wf-image\">" + (string.IsNullOrEmpty(label) ? "image" : label) + "</div>";
                case ElementKind.Tabs:
                    return TabsHtml(w.Items.Count > 0 ? w.Items : new List<string> { "Tab 1", "Tab 2" });
                case ElementKind.Menu:
                case ElementKind.Toolbar:
                    return NavHtml(w.Items.Count > 0 ? w.Items : new List<string> { "File", "Edit", "View" });
                case ElementKind.Breadcrumb:
                    return NavHtml(w.Items.Count > 0 ? w.Items : new List<string> { "Home", "Section", "Page" }, "wf-breadcrumb");
                case ElementKind.Card:
                    return CardHtml(w);
                case ElementKind.Separator:
                    return "<hr class=\"wf-sep\">";
                case ElementKind.Progress:
                    return "<progress class=\"wf-progress\" value=\"60\" max=\"100\"></progress>";
                case ElementKind.Slider:
                    return "<input class=\"wf-slider\" type=\"range\">";
                case ElementKind.UiWidget:
                default:
                    return "<div class=\"wf-widget\">" + label + "</div>";
            }
        }

        private static string SelectHtml(string placeholder, List<string> items)
        {
            var sb = new StringBuilder();
            sb.Append("<select class=\"wf-input\">\n");
            if (items.Count == 0) sb.Append("  <option>").Append(placeholder).Append("</option>\n");
            else foreach (var i in items) sb.Append("  <option>").Append(Escape(i)).Append("</option>\n");
            sb.Append("</select>");
            return sb.ToString();
        }

        private static string ListHtml(string cls, List<string> items)
        {
            string tag = cls.Contains("ul") ? "ul" : "ol";
            var sb = new StringBuilder();
            sb.Append('<').Append(tag).Append(" class=\"").Append(cls.Replace("ul ", "")).Append("\">\n");
            foreach (var i in items) sb.Append("  <li>").Append(Escape(i)).Append("</li>\n");
            sb.Append("</").Append(tag).Append('>');
            return sb.ToString();
        }

        private static string TableHtml(List<string> cols)
        {
            if (cols.Count == 0) cols = new List<string> { "Name", "Value" };
            var sb = new StringBuilder();
            sb.Append("<table class=\"wf-table\">\n  <thead><tr>");
            foreach (var c in cols) sb.Append("<th>").Append(Escape(c)).Append("</th>");
            sb.Append("</tr></thead>\n  <tbody>\n");
            for (int r = 0; r < 2; r++)
            {
                sb.Append("    <tr>");
                for (int c = 0; c < cols.Count; c++) sb.Append("<td>—</td>");
                sb.Append("</tr>\n");
            }
            sb.Append("  </tbody>\n</table>");
            return sb.ToString();
        }

        private static string TabsHtml(List<string> tabs)
        {
            var sb = new StringBuilder();
            sb.Append("<nav class=\"wf-tabs\">\n");
            for (int i = 0; i < tabs.Count; i++)
                sb.Append("  <a class=\"wf-tab" + (i == 0 ? " is-active" : "") + "\" href=\"#\">" + Escape(tabs[i]) + "</a>\n");
            sb.Append("</nav>\n<section class=\"wf-tab-body\"></section>");
            return sb.ToString();
        }

        private static string NavHtml(List<string> items, string cls = "wf-menu")
        {
            var sb = new StringBuilder();
            sb.Append("<nav class=\"").Append(cls).Append("\">\n");
            foreach (var i in items) sb.Append("  <a href=\"#\">").Append(Escape(i)).Append("</a>\n");
            sb.Append("</nav>");
            return sb.ToString();
        }

        private static string CardHtml(WireframeContext.Widget w)
        {
            var sb = new StringBuilder();
            sb.Append("<article class=\"wf-card\">\n");
            if (!string.IsNullOrEmpty(w.Label)) sb.Append("  <h3>").Append(Escape(w.Label)).Append("</h3>\n");
            foreach (var l in w.Items) sb.Append("  <p>").Append(Escape(l)).Append("</p>\n");
            foreach (var child in w.Children)
            {
                string html = WidgetHtml(child);
                foreach (var line in html.Replace("\r\n", "\n").Split('\n'))
                    if (line.Length > 0) sb.Append("  ").Append(line).Append('\n');
            }
            sb.Append("</article>");
            return sb.ToString();
        }

        private static string PanelHtml(WireframeContext.Widget w)
        {
            var sb = new StringBuilder();
            sb.Append("<section class=\"wf-panel\">\n");
            if (!string.IsNullOrWhiteSpace(w.Label))
                sb.Append("  <header class=\"wf-panel-title\">").Append(Escape(w.Label)).Append("</header>\n");
            foreach (var child in w.Children)
            {
                string html = WidgetHtml(child);
                foreach (var line in html.Replace("\r\n", "\n").Split('\n'))
                    if (line.Length > 0) sb.Append("  ").Append(line).Append('\n');
            }
            sb.Append("</section>");
            return sb.ToString();
        }

        // --- PlantUML salt ---

        private static string WidgetSalt(WireframeContext.Widget w)
        {
            string label = EscapeSalt(w.Label ?? "");
            switch (w.Kind)
            {
                case ElementKind.Panel:        return SaltPanel(w);
                case ElementKind.Button:       return "{[" + label + "]}";
                case ElementKind.Label:        return "\"" + label + "\"";
                case ElementKind.Link:         return "\"" + label + "\"";
                case ElementKind.TextField:    return "{\"" + label + "\"}";
                case ElementKind.Password:     return "{\"" + new string('*', Mathf_MinLen(label, 6)) + "\"}";
                case ElementKind.TextArea:     return "{\"" + label + "\\n…\"}";
                case ElementKind.Checkbox:     return "[X] " + label;
                case ElementKind.Radio:        return "(X) " + label;
                case ElementKind.Dropdown:     return "^\"" + label + "\"^";
                case ElementKind.List:         return SaltList(w.Items, label);
                case ElementKind.Tree:         return SaltList(w.Items, label);
                case ElementKind.Table:        return SaltTable(w.Items);
                case ElementKind.Image:        return "[[[" + (string.IsNullOrEmpty(label) ? "image" : label) + "]]]";
                case ElementKind.Tabs:         return SaltTabs(w.Items);
                case ElementKind.Menu:
                case ElementKind.Toolbar:      return SaltMenu(w.Items);
                case ElementKind.Breadcrumb:   return "\"" + SaltBreadcrumb(w.Items) + "\"";
                case ElementKind.Card:         return SaltCard(w);
                case ElementKind.Separator:    return "--";
                case ElementKind.Progress:     return "[##" + new string(' ', 6) + "]";
                case ElementKind.Slider:       return "[o" + new string('-', 10) + "]";
                case ElementKind.UiWidget:
                default:                       return "\"" + label + "\"";
            }
        }

        private static void AppendSaltWidget(StringBuilder sb, WireframeContext.Widget w, string indent)
        {
            string text = WidgetSalt(w);
            foreach (var line in text.Replace("\r\n", "\n").Split('\n'))
                if (line.Length > 0)
                    sb.Append(indent).Append(line).Append('\n');
        }

        private static string SaltList(List<string> items, string fallback)
        {
            var sb = new StringBuilder();
            sb.Append("{^");
            if (items.Count == 0) sb.Append("\"" + fallback + "\"");
            else for (int i = 0; i < items.Count; i++) sb.Append("\"" + EscapeSalt(items[i]) + (i + 1 < items.Count ? "\\n" : "") + "\"");
            sb.Append("}^");
            return sb.ToString();
        }

        private static string SaltTable(List<string> cols)
        {
            if (cols.Count == 0) cols = new List<string> { "Name", "Value" };
            var sb = new StringBuilder();
            sb.Append("{#\n");
            // Header.
            sb.Append("  ");
            for (int i = 0; i < cols.Count; i++) sb.Append("." + EscapeSalt(cols[i]) + (i + 1 < cols.Count ? " | " : "\n"));
            // Two data rows.
            for (int r = 0; r < 2; r++)
            {
                sb.Append("  ");
                for (int i = 0; i < cols.Count; i++) sb.Append(".—" + (i + 1 < cols.Count ? " | " : "\n"));
            }
            sb.Append("}#");
            return sb.ToString();
        }

        private static string SaltTabs(List<string> tabs)
        {
            if (tabs.Count == 0) tabs = new List<string> { "Tab 1", "Tab 2" };
            var sb = new StringBuilder();
            sb.Append("{+");
            for (int i = 0; i < tabs.Count; i++) sb.Append("[" + EscapeSalt(tabs[i]) + "]" + (i + 1 < tabs.Count ? " " : ""));
            sb.Append("+}");
            return sb.ToString();
        }

        private static string SaltMenu(List<string> items)
        {
            if (items.Count == 0) items = new List<string> { "File", "Edit", "View" };
            var sb = new StringBuilder();
            sb.Append("{+");
            for (int i = 0; i < items.Count; i++) sb.Append("\"" + EscapeSalt(items[i]) + "\"" + (i + 1 < items.Count ? " | " : ""));
            sb.Append("+}");
            return sb.ToString();
        }

        private static string SaltBreadcrumb(List<string> items)
        {
            if (items.Count == 0) items = new List<string> { "Home", "Section", "Page" };
            var sb = new StringBuilder();
            for (int i = 0; i < items.Count; i++)
            {
                sb.Append(EscapeSalt(items[i]));
                if (i + 1 < items.Count) sb.Append(" › ");
            }
            return sb.ToString();
        }

        private static string SaltCard(WireframeContext.Widget w)
        {
            var sb = new StringBuilder();
            sb.Append("{^\n  {+").Append(EscapeSalt(w.Label ?? "")).Append("+}\n  --\n");
            foreach (var l in w.Items) sb.Append("  \"").Append(EscapeSalt(l)).Append("\"\\n");
            foreach (var child in w.Children)
                AppendSaltWidget(sb, child, "  ");
            sb.Append("}^");
            return sb.ToString();
        }

        private static string SaltPanel(WireframeContext.Widget w)
        {
            var sb = new StringBuilder();
            sb.Append("{^\n");
            if (!string.IsNullOrWhiteSpace(w.Label))
                sb.Append("  {+").Append(EscapeSalt(w.Label)).Append("+}\n");
            foreach (var child in w.Children)
                AppendSaltWidget(sb, child, "  ");
            sb.Append("}^");
            return sb.ToString();
        }

        // --- CSS + helpers ---

        private static string HtmlCss() =>
            "*{box-sizing:border-box} body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;"
            + "background:#f3f4f6;color:#111827;padding:24px} .wf-screen{max-width:760px;margin:0 auto;background:#fff;"
            + "border:1px solid #d1d5db;border-radius:8px;overflow:hidden} .wf-title{padding:14px 18px;font-weight:700;"
            + "border-bottom:1px solid #e5e7eb;background:#f9fafb} .wf-body{padding:18px;display:flex;flex-direction:column;"
            + "gap:12px} .wf-btn{padding:8px 16px;background:#0f766e;color:#fff;border:none;border-radius:6px;cursor:pointer;"
            + "align-self:flex-start} .wf-label,.wf-link{font-size:14px} .wf-link{color:#0284c7;text-decoration:underline}"
            + " .wf-input,.wf-textarea{padding:6px 10px;border:1px solid #d1d5db;border-radius:6px;font:inherit}"
            + " .wf-textarea{min-height:64px} .wf-check{font-size:14px} .wf-image{min-height:96px;background:#e5e7eb;"
            + "border:1px dashed #9ca3af;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#6b7280}"
            + " .wf-panel{border:1px solid #e5e7eb;border-radius:8px;padding:12px;display:flex;flex-direction:column;gap:10px}"
            + " .wf-panel-title{font-size:13px;font-weight:700;color:#374151}"
            + " .wf-table{width:100%;border-collapse:collapse;font-size:14px} .wf-table th,.wf-table td{border:1px solid #e5e7eb;"
            + "padding:6px 10px;text-align:left} .wf-table thead{background:#f9fafb} .wf-menu,.wf-breadcrumb,.wf-tabs{display:flex;gap:14px}"
            + " .wf-menu a,.wf-breadcrumb a,.wf-tab{font-size:14px;color:#374151;text-decoration:none} .wf-tab.is-active"
            + "{font-weight:700;border-bottom:2px solid #0f766e} .wf-tab-body{min-height:48px} .wf-card{border:1px solid #e5e7eb;"
            + "border-radius:8px;padding:12px} .wf-card h3{margin:0 0 8px;font-size:15px} .wf-card p{margin:4px 0;color:#6b7280}"
            + " .wf-sep{border:none;border-top:1px solid #e5e7eb} .wf-tree,.wf-table ul{margin:0;padding-left:20px}";

        private static string Escape(string s) =>
            (s ?? "").Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;");

        private static string EscapeSalt(string s) => (s ?? "").Replace("[", "(").Replace("]", ")").Replace("{", "(").Replace("}", ")").Replace("|", "/");

        private static int Mathf_MinLen(string s, int min) => System.Math.Max(min, s.Length);
    }
}
