using System.Collections.Generic;
using System.Globalization;
using UnityEngine;

namespace TheRobotDraft.Styleguide
{
    /// <summary>
    /// Resolves a raw styleguide token (which may reference other tokens via <c>var(--x)</c>, or be a
    /// <c>color-mix(in srgb, C p%, D)</c> / <c>rgba(...)</c> / hex expression) to a concrete <see cref="Color"/> or
    /// string. Unity has no CSS engine; this is the small evaluator that makes the resolved theme renderable. The
    /// styleguide uses only sRGB color-mixes (never oklch/lab), so <see cref="Color.Lerp"/> in gamma space is an
    /// exact match — a faithful reduction, not a lossy one.
    /// </summary>
    public static class TokenEvaluator
    {
        /// <summary>Resolve a raw token to an opaque Color, blending onto <paramref name="fallback"/> for translucent
        /// values; returns false if the token isn't a color (font stacks, px, z-index).</summary>
        public static bool TryColor(ResolvedTheme theme, string raw, out Color color, Color fallback = default)
        {
            color = fallback;
            string value = Resolve(theme, raw, new HashSet<string>());
            if (value == null) return false;
            return TryParseColor(value, out color, fallback);
        }

        /// <summary>Resolve a raw token to its final string form (var() references followed).</summary>
        public static string Resolve(ResolvedTheme theme, string raw, HashSet<string> seen = null)
        {
            seen = seen ?? new HashSet<string>();
            if (string.IsNullOrWhiteSpace(raw)) return null;
            string s = raw.Trim();

            // var(--name) or var(--name, fallback)
            int vi = s.IndexOf("var(");
            if (vi >= 0)
            {
                int innerStart = vi + 4;
                string inner = ExtractBalanced(s, innerStart);
                string refName = inner;
                string defaultVal = null;
                int comma = IndexOfTopLevel(inner, ',');
                if (comma >= 0) { refName = inner.Substring(0, comma).Trim(); defaultVal = inner.Substring(comma + 1).Trim(); }
                string bare = refName.TrimStart('-');
                if (seen.Contains(bare)) return defaultVal; // cycle guard
                seen.Add(bare);
                string resolved = theme != null && theme.Tokens.TryGetValue(bare, out var v)
                    ? Resolve(theme, v, seen) : null;
                seen.Remove(bare);
                if (resolved != null) return resolved;
                return defaultVal != null ? Resolve(theme, defaultVal, seen) : null;
            }
            return s;
        }

        private static bool TryParseColor(string s, out Color color, Color fallback)
        {
            color = fallback;
            if (string.IsNullOrEmpty(s)) return false;
            s = s.Trim();
            string lower = s.ToLowerInvariant();

            if (lower.StartsWith("color-mix("))
                return TryColorMix(s, out color, fallback);
            if (lower.StartsWith("rgba(") || lower.StartsWith("rgb("))
                return TryRgba(s, out color, fallback);
            if (s == "transparent") { color = new Color(0, 0, 0, 0); return true; }
            if (lower.StartsWith("hsl(") || lower.StartsWith("hsla("))
                return TryHsl(s, out color, fallback);
            // hex (#rgb, #rrggbb, #rrggbbaa)
            string hex = s.StartsWith("#") ? s : "#" + s;
            if (ColorUtility.TryParseHtmlString(hex, out color)) return true;
            return false;
        }

        /// <summary>color-mix(in srgb, C1 P%, C2) → linear interpolation Color.Lerp(C2, C1, P/100).</summary>
        private static bool TryColorMix(string s, out Color color, Color fallback)
        {
            color = fallback;
            int open = s.IndexOf('(');
            int close = s.LastIndexOf(')');
            if (open < 0 || close <= open) return false;
            // body after "in srgb," (we only support srgb; the styleguide uses nothing else).
            string body = s.Substring(open + 1, close - open - 1);
            int inKw = body.ToLowerInvariant().IndexOf("in srgb");
            if (inKw >= 0) body = body.Substring(inKw + "in srgb".Length).TrimStart().TrimStart(',').TrimStart();

            var parts = SplitTopLevel(body, ',');
            if (parts.Count < 2) return false;
            string c1Raw = parts[0].Trim();
            string c2Raw = parts[1].Trim();
            float p1 = ExtractPercent(c1Raw, out c1Raw);

            if (!TryParseColor(c1Raw, out var c1, Color.clear)) return false;
            // The second color may be `transparent` or a bare color; its percentage defaults to (100 - p1).
            if (!TryParseColor(c2Raw, out var c2, Color.clear))
            {
                if (c2Raw.ToLowerInvariant() == "transparent") c2 = new Color(c1.r, c1.g, c1.b, 0f);
                else return false;
            }
            float t = Mathf.Clamp01(p1 / 100f);
            // Standard CSS color-mix in sRGB: result = c1*t + c2*(1-t), per channel including alpha.
            color = new Color(
                Mathf.Lerp(c2.r, c1.r, t),
                Mathf.Lerp(c2.g, c1.g, t),
                Mathf.Lerp(c2.b, c1.b, t),
                Mathf.Lerp(c2.a, c1.a, t));
            return true;
        }

        private static bool TryRgba(string s, out Color color, Color fallback)
        {
            color = fallback;
            int open = s.IndexOf('('), close = s.LastIndexOf(')');
            if (open < 0 || close <= open) return false;
            var parts = s.Substring(open + 1, close - open - 1).Split(',');
            if (parts.Length < 3) return false;
            if (!TryFloat(parts[0], out float r) || !TryFloat(parts[1], out float g) || !TryFloat(parts[2], out float b))
                return false;
            float a = 1f;
            if (parts.Length >= 4 && !TryFloat(parts[3], out a)) return false;
            // rgba() channels are 0–255 (alpha 0–1); tolerate either via range sniff.
            color = new Color(r / 255f, g / 255f, b / 255f, parts.Length >= 4 ? a : 1f);
            return true;
        }

        private static bool TryHsl(string s, out Color color, Color fallback)
        {
            color = fallback;
            int open = s.IndexOf('('), close = s.LastIndexOf(')');
            if (open < 0 || close <= open) return false;
            var parts = s.Substring(open + 1, close - open - 1).Split(',');
            if (parts.Length < 3) return false;
            if (!TryFloat(parts[0], out float h) || !TryFloat(parts[1], out float satp) || !TryFloat(parts[2], out float lp))
                return false;
            Color rgb = Color.HSVToRGB((h % 360f) / 360f, satp / 100f, lp / 100f);
            float a = parts.Length >= 4 && TryFloat(parts[3], out float av) ? av : 1f;
            color = new Color(rgb.r, rgb.g, rgb.b, a);
            return true;
        }

        // --- small parse helpers ---

        private static float ExtractPercent(string token, out string rest)
        {
            rest = token;
            int pct = token.IndexOf('%');
            if (pct < 0) return 100f; // no explicit % → treat as 100% of this color (single-color mix)
            string num = token.Substring(0, pct).Trim();
            // the color is whatever preceded the number — but in CSS the form is "C P%"; split trailing number.
            // Find the last space: color is before, percent after.
            int sp = token.LastIndexOf(' ');
            if (sp >= 0)
            {
                rest = token.Substring(0, sp).Trim();
                if (TryFloat(token.Substring(sp + 1, pct - sp - 1).Trim(), out float p)) return p;
            }
            rest = token.Substring(0, pct).Trim();
            return TryFloat(num, out float pp) ? pp : 100f;
        }

        private static bool TryFloat(string s, out float v) => float.TryParse((s ?? "").Trim().TrimEnd('%'),
            NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out v);

        private static class CultureInfo { public static System.Globalization.CultureInfo InvariantCulture => System.Globalization.CultureInfo.InvariantCulture; }
        private static class NumberStyles { public const System.Globalization.NumberStyles Float = System.Globalization.NumberStyles.Float; }

        private static string ExtractBalanced(string s, int start)
        {
            int depth = 0;
            for (int i = start; i < s.Length; i++)
            {
                if (s[i] == '(') depth++;
                else if (s[i] == ')') { depth--; if (depth == 0) return s.Substring(start, i - start); }
            }
            return s.Substring(start);
        }

        private static int IndexOfTopLevel(string s, char ch)
        {
            int depth = 0;
            for (int i = 0; i < s.Length; i++)
            {
                if (s[i] == '(') depth++;
                else if (s[i] == ')') depth--;
                else if (s[i] == ch && depth == 0) return i;
            }
            return -1;
        }

        private static List<string> SplitTopLevel(string s, char sep)
        {
            var result = new List<string>();
            int depth = 0, start = 0;
            for (int i = 0; i < s.Length; i++)
            {
                if (s[i] == '(') depth++;
                else if (s[i] == ')') depth--;
                else if (s[i] == sep && depth == 0) { result.Add(s.Substring(start, i - start)); start = i + 1; }
            }
            result.Add(s.Substring(start));
            return result;
        }
    }
}
