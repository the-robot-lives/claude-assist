using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Styleguide
{
    /// <summary>
    /// Ports the styleguide's token-resolution pipeline (components/styleguide/app/src/lib/css-gen/defaults.ts) to C#.
    /// ~10–15 seeds expand into ~300 CSS custom properties across three levels:
    /// <list type="number">
    /// <item><b>Level 1</b> — base tokens computed from seeds: the spacing scale (from <c>unit</c>), the font-size
    /// scale (from <c>font-size-base</c>), the gray ramp (white→black lerp), the slate ramp, brand/palette colors +
    /// their <c>color-mix</c> light/mid variants, and semantic aliases (success/warning/error/info → palette).</item>
    /// <item><b>Level 2/3</b> — static component-foundation tokens (font weights, line heights, transitions, radius
    /// scale, border widths, shadow elevation, …) that reference Level-1 tokens via <c>var()</c>.</item>
    /// <item><b>Seed overrides</b> — the active (uncommented) entries in <c>style-guide.vars.yaml</c> win at every
    /// level, exactly as in the source engine.</item>
    /// </list>
    /// Then the selected <see cref="ColorMode"/> (from color-modes.yaml) is applied so <c>--surface</c>,
    /// <c>--text</c>, <c>--border</c>, … resolve to the right light/dark ramp. Runs once per theme load / edit; the
    /// canvas caches the result.
    ///
    /// Faithful-reduction note: the full Level 2/3 map is ~700 lines of static var() references. This port carries
    /// the foundation tokens the wireframe renderer + HTML export consume; the remainder are CSS-only (cards, buttons,
    /// fields, HUI) with no Unity analog and round-trip through the YAML untouched. The seed-driven Level-1 math is
    /// ported in full (spacing/font/gray/slate/brand/palette/semantic) since that is where a theme's identity lives.
    /// </summary>
    public static class ThemeResolver
    {
        /// <summary>Resolve a complete theme from the parsed YAML + a seed map. <paramref name="seeds"/> are the
        /// active vars (YAML overrides); base-token seeds default when absent.</summary>
        public static ResolvedTheme Resolve(YamlLite.Node varsYaml, YamlLite.Node colorModesYaml,
            YamlLite.Node semanticClassesYaml, Dictionary<string, string> seeds, ColorMode mode)
        {
            var theme = new ResolvedTheme
            {
                VarsYaml = varsYaml,
                ColorModesYaml = colorModesYaml,
                SemanticClassesYaml = semanticClassesYaml,
                Mode = mode,
            };
            seeds = seeds ?? new Dictionary<string, string>();

            // Level 1 — computed base tokens.
            BuildBaseTokens(theme.Tokens, seeds);
            // Level 2/3 — static foundation tokens (the subset the renderer + export use).
            AddLevel2And3(theme.Tokens);
            // Seed overrides win at every level (active YAML entries).
            foreach (var kv in seeds) theme.Tokens[kv.Key] = kv.Value;

            // Apply the selected color mode: surface/text/border/etc. get concrete ramp values.
            ApplyColorMode(theme, colorModesYaml, mode);

            return theme;
        }

        /// <summary>Flatten the active (uncommented) entries of a parsed <c>style-guide.vars.yaml</c> into a seed map.
        /// Comments are not nodes in the value tree (the parser only stores real <c>key: value</c> pairs), so every
        /// entry here is active — matching the convention that <c># name: value</c> means "matches default".</summary>
        public static Dictionary<string, string> SeedsFromVarsYaml(YamlLite.Node varsYaml)
        {
            var seeds = new Dictionary<string, string>();
            if (varsYaml == null) return seeds;
            // vars: { groups: [ { name, vars: { key: value, … } }, … ] }
            if (!varsYaml.TryGet("vars", out var vars)) return seeds;
            if (!vars.TryGet("groups", out var groups) || !groups.IsList) return seeds;
            foreach (var g in groups.Items)
            {
                if (g == null || !g.TryGet("vars", out var gvars) || !gvars.IsMap) continue;
                foreach (var kv in gvars.Map)
                    if (kv.Value != null && kv.Value.IsScalar) seeds[kv.Key] = kv.Value.Scalar;
            }
            return seeds;
        }

        // =========================================================================================
        // Level 1 — seed → base token computation
        // =========================================================================================

        private static void BuildBaseTokens(Dictionary<string, string> v, Dictionary<string, string> seed)
        {
            string S(string name, string def) => seed.TryGetValue(name, out var s) && !string.IsNullOrEmpty(s) ? s : def;

            // ── Spacing scale from unit ──
            int unit = ParseInt(S("unit", S("space-1", "8")), 8);
            v["unit"] = unit + "px";
            v["radius"] = S("radius", "2px");
            v["space-half"] = (unit / 2f) + "px";
            v["col-gap"] = (unit * 2) + "px";
            var spacingMultipliers = new (string name, int mult)[]
            {
                ("space-1",1),("space-2",2),("space-3",3),("space-4",4),("space-5",5),("space-6",6),
                ("space-7",7),("space-8",8),("space-9",9),("space-10",10),("space-11",11),("space-12",12),
                ("space-15",15),("space-16",16),("space-18",18),("space-20",20),("space-25",25),("space-30",30),
                ("space-32",32),("space-35",35),("space-37",37),("space-48",48),("space-52",52),("space-60",60),
                ("space-64",64),("space-80",80),("space-90",90),("space-96",96),("space-108",108),("space-112",112),
                ("space-128",128),("space-144",144),("space-150",150),("space-160",160),
            };
            foreach (var (name, mult) in spacingMultipliers) v[name] = (unit * mult) + "px";
            v["space-1-mid"] = Mathf.RoundToInt(unit * 1.5f) + "px";
            v["space-2-mid"] = Mathf.RoundToInt(unit * 2.5f) + "px";
            v["space-4-mid"] = Mathf.RoundToInt(unit * 4.5f) + "px";
            v["space-5-mid"] = Mathf.RoundToInt(unit * 5.5f) + "px";
            v["space-7-mid"] = Mathf.RoundToInt(unit * 7.5f) + "px";

            // Border + size tokens.
            v["size-border-thin"] = "1px"; v["size-border-thick"] = "2px"; v["size-border-heavy"] = "3px";
            v["size-border-medium"] = "1.5px"; v["size-border-accent"] = "5px"; v["size-border-extra-heavy"] = "4px";
            v["size-2xs"] = Mathf.RoundToInt(unit * 1.25f) + "px";
            v["size-md-sm"] = Mathf.RoundToInt(unit * 1.75f) + "px";
            v["size-lg"] = Mathf.RoundToInt(unit * 2.5f) + "px";

            // ── Font-size scale from base ──
            int b = ParseInt(S("font-size-base", "16"), 16);
            v["line-height-base"] = S("line-height-base", "1.5");
            var fontScale = new (string name, float ratio)[]
            {
                ("font-size-xs", 0.6875f), ("font-size-sm", 0.8125f), ("font-size-md", 1f), ("font-size-lg", 1.25f),
                ("font-size-xl", 1.5f), ("font-size-2xl", 2f), ("font-size-3xl", 2.5f), ("font-size-display", 3.5f),
            };
            v["font-size-base"] = b + "px";
            foreach (var (name, ratio) in fontScale) v[name] = Mathf.RoundToInt(b * ratio) + "px";
            v["size-xs"] = Mathf.RoundToInt(b * 0.6875f) + "px";
            v["size-sm"] = Mathf.RoundToInt(b * 0.8125f) + "px";
            v["size-md"] = b + "px";
            v["size-xl"] = Mathf.RoundToInt(b * 1.5f) + "px";

            // ── Font stacks ──
            v["font-sans"] = S("font-sans", "'Space Grotesk', -apple-system, sans-serif");
            v["font-mono"] = S("font-mono", "'IBM Plex Mono', 'Menlo', monospace");

            // ── Surface ramp from white/black ──
            string white = S("white", "#ffffff"), black = S("black", "#000000");
            v["white"] = white; v["black"] = black;
            v["off-white"] = S("off-white", LerpHex(white, black, 0.02f));
            var grayStops = new (string name, float t)[]
            {
                ("gray-50",0.04f),("gray-100",0.07f),("gray-200",0.12f),("gray-300",0.26f),("gray-400",0.38f),
                ("gray-500",0.54f),("gray-600",0.62f),("gray-700",0.74f),("gray-800",0.87f),("gray-900",0.93f),
            };
            foreach (var (name, t) in grayStops) v[name] = S(name, LerpHex(white, black, t));

            // ── Slate ramp (Tailwind defaults, seed-overridable) ──
            var slate = new (string name, string hex)[]
            {
                ("slate-50","#f8fafc"),("slate-100","#f1f5f9"),("slate-200","#e2e8f0"),("slate-300","#cbd5e1"),
                ("slate-400","#94a3b8"),("slate-500","#64748b"),("slate-600","#475569"),("slate-700","#334155"),
                ("slate-800","#1e293b"),("slate-900","#0f172a"),("slate-950","#020617"),
            };
            foreach (var (name, hex) in slate) v[name] = S(name, hex);

            // ── Brand primaries + light/mid variants (color-mix with surface) ──
            v["surface"] = "var(--white)"; // provisional; the color-mode pass sets the real surface
            AddBrand(v, seed, "brand-red", "red", "#e20613", 0.12f, 0.20f);
            AddBrand(v, seed, "brand-blue", "blue", "#0047ab", 0.12f, 0.20f);
            AddBrand(v, seed, "brand-yellow", "yellow", "#f5c518", 0.18f, 0.35f);

            // ── Palette colors + light variants ──
            var palette = new (string name, string hex)[]
            {
                ("rose","#e11d48"),("orange","#ea580c"),("amber","#d97706"),("lime","#65a30d"),("emerald","#059669"),
                ("teal","#0d9488"),("cyan","#0891b2"),("sky","#0284c7"),("indigo","#4f46e5"),("violet","#7c3aed"),
                ("purple","#9333ea"),("fuchsia","#c026d3"),("pink","#db2777"),
            };
            foreach (var (name, hex) in palette)
            {
                v[name] = S(name, hex);
                v[name + "-light"] = S(name + "-light", $"color-mix(in srgb, var(--{name}) 12%, var(--surface))");
            }

            // ── Semantic aliases + tint variants ──
            AddSemantic(v, seed, "success", "var(--emerald)");
            AddSemantic(v, seed, "warning", "var(--amber)");
            AddSemantic(v, seed, "error", "var(--rose)");
            AddSemantic(v, seed, "info", "var(--brand-blue)");

            // ── Base aliases ──
            v["base-font-family"] = "var(--font-sans)";
            v["base-font-color"] = "var(--text)";
            v["base-background"] = "var(--surface)";
            v["base-line-height"] = "var(--line-height-base)";
            v["base-font-size"] = "var(--font-size-base)";
        }

        private static void AddBrand(Dictionary<string, string> v, Dictionary<string, string> seed,
            string brandName, string bare, string defHex, float lightPct, float midPct)
        {
            string hex = seed.TryGetValue(brandName, out var b) && !string.IsNullOrEmpty(b) ? b
                : (seed.TryGetValue(bare, out var bn) && !string.IsNullOrEmpty(bn) ? bn : defHex);
            v[brandName] = hex;
            int lp = Mathf.RoundToInt(lightPct * 100), mp = Mathf.RoundToInt(midPct * 100);
            v[brandName + "-light"] = seed.TryGetValue(brandName + "-light", out var bl) && !string.IsNullOrEmpty(bl)
                ? bl : $"color-mix(in srgb, {hex} {lp}%, var(--surface))";
            v[brandName + "-mid"] = seed.TryGetValue(brandName + "-mid", out var bm) && !string.IsNullOrEmpty(bm)
                ? bm : $"color-mix(in srgb, {hex} {mp}%, var(--surface))";
        }

        private static void AddSemantic(Dictionary<string, string> v, Dictionary<string, string> seed,
            string name, string defAlias)
        {
            v[name] = seed.TryGetValue(name, out var s) && !string.IsNullOrEmpty(s) ? s : defAlias;
            v[name + "-tint"] = seed.TryGetValue(name + "-tint", out var t) && !string.IsNullOrEmpty(t)
                ? t : $"color-mix(in srgb, var(--{name}) 12%, var(--surface))";
        }

        // =========================================================================================
        // Level 2/3 — static foundation tokens (renderer/export-relevant subset)
        // =========================================================================================

        private static void AddLevel2And3(Dictionary<string, string> v)
        {
            // Font weights + line heights.
            v["font-weight-normal"] = "400"; v["font-weight-medium"] = "500";
            v["font-weight-semibold"] = "600"; v["font-weight-bold"] = "700";
            v["line-height-tight"] = "1.3"; v["line-height-normal"] = "1.5"; v["line-height-relaxed"] = "1.6";
            // Radius scale (the renderer reads `radius` for corner rounding).
            v["radius-none"] = "0"; v["radius-sm"] = "4px"; v["radius-md"] = "6px";
            v["radius-lg"] = "8px"; v["radius-xl"] = "12px"; v["radius-circle"] = "9999px";
            // Border widths + dividers.
            v["border-thin"] = "var(--size-border-thin)"; v["border-thick"] = "var(--size-border-thick)";
            v["border-heavy"] = "var(--size-border-heavy)"; v["hr-height"] = "var(--border-thin)";
            // Shadow color carries alpha (color-mode sets the base).
            v["shadow-color"] = "rgba(0,0,0,0.1)";
            v["on-semantic-color"] = "var(--white)";
        }

        // =========================================================================================
        // color-mode application
        // =========================================================================================

        /// <summary>Apply the light/dark color-mode map: set surface/text/border/etc. tokens to the mode's ramp
        /// values, then resolve them to concrete hex so the renderer (and HTML export) get final colors.</summary>
        private static void ApplyColorMode(ResolvedTheme theme, YamlLite.Node colorModesYaml, ColorMode mode)
        {
            if (colorModesYaml == null) { DefaultColorMode(theme, mode); return; }
            if (!colorModesYaml.TryGet("color-modes", out var modes)) { DefaultColorMode(theme, mode); return; }
            string key = mode == ColorMode.Dark ? "dark" : "light";
            if (!modes.TryGet(key, out var modeMap) || !modeMap.IsMap) { DefaultColorMode(theme, mode); return; }
            // Pull the mode's semantic→raw mappings into the token map (e.g. surface → "var(--white)").
            foreach (var kv in modeMap.Map)
                if (kv.Value != null && kv.Value.IsScalar) theme.Tokens[kv.Key] = kv.Value.Scalar;
            // Resolve the surface/text/border family to concrete colors for fast renderer access.
            foreach (var name in new[] { "surface", "surface-alt", "surface-inverse", "text", "text-secondary",
                                         "text-muted", "text-inverse", "border", "border-strong", "shadow-color" })
            {
                if (theme.Tokens.TryGetValue(name, out var raw))
                {
                    if (TokenEvaluator.TryColor(theme, raw, out var c, Color.white))
                        theme.Tokens["__" + name] = "#" + ColorUtility.ToHtmlStringRGBA(c);
                }
            }
        }

        private static void DefaultColorMode(ResolvedTheme theme, ColorMode mode)
        {
            // Minimal fallback when no color-modes.yaml is present: light = white surface/dark text, dark = inverse.
            theme.Tokens["surface"] = mode == ColorMode.Dark ? "var(--slate-800)" : "var(--white)";
            theme.Tokens["text"] = mode == ColorMode.Dark ? "var(--gray-100)" : "var(--black)";
            theme.Tokens["border"] = mode == ColorMode.Dark ? "var(--gray-700)" : "var(--slate-200)";
            theme.Tokens["text-muted"] = mode == ColorMode.Dark ? "var(--gray-300)" : "var(--gray-500)";
        }

        // =========================================================================================
        // helpers
        // =========================================================================================

        public static int ParseInt(string s, int def)
        {
            if (string.IsNullOrEmpty(s)) return def;
            // strip "px" and trailing non-digits
            int n = 0; bool neg = false; int i = 0;
            if (i < s.Length && s[i] == '-') { neg = true; i++; }
            bool any = false;
            for (; i < s.Length; i++)
            {
                if (s[i] < '0' || s[i] > '9') break;
                n = n * 10 + (s[i] - '0'); any = true;
            }
            if (!any) return def;
            return neg ? -n : n;
        }

        /// <summary>Linear-interpolate two hex colors (the styleguide's gray-ramp builder).</summary>
        public static string LerpHex(string hexA, string hexB, float t)
        {
            if (!HexToColor(hexA, out var a)) return hexA;
            if (!HexToColor(hexB, out var bb)) return hexA;
            return "#" + ColorUtility.ToHtmlStringRGBA(Color.Lerp(a, bb, t));
        }

        public static bool HexToColor(string hex, out Color c)
        {
            c = default;
            if (string.IsNullOrEmpty(hex)) return false;
            string h = hex.Trim();
            if (!h.StartsWith("#")) h = "#" + h;
            return ColorUtility.TryParseHtmlString(h, out c);
        }
    }
}
