using UnityEngine;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Procedurally-rasterized icon sprites for the navigation toolbar (orbit / pan / X / Y / Z), so the chips show
    /// real images independent of whatever glyphs the built-in font happens to carry. Each icon is drawn white with
    /// a transparent background into a small RGBA texture and cached as a <see cref="Sprite"/>; the chip background
    /// behind it carries the active/inactive tint.
    /// </summary>
    public static class UmlNavIcons
    {
        private const int N = 64;          // icon texture is N×N
        private const float Stroke = 2.6f; // disk radius stamped along each stroke (≈5-px line)

        private static Sprite _orbit, _pan, _x, _y, _z;

        public static Sprite Orbit => _orbit != null ? _orbit : (_orbit = BuildOrbit());
        public static Sprite Pan => _pan != null ? _pan : (_pan = BuildPan());
        public static Sprite AxisX => _x != null ? _x : (_x = BuildX());
        public static Sprite AxisY => _y != null ? _y : (_y = BuildY());
        public static Sprite AxisZ => _z != null ? _z : (_z = BuildZ());

        // Reuse the axis icon textures as resize cursors (transparent background, white arrows).
        public static Texture2D TexX => AxisX.texture;
        public static Texture2D TexY => AxisY.texture;
        public static Texture2D TexZ => AxisZ.texture;

        // --- icon definitions (canvas is 0..63, origin bottom-left) ---

        private static Sprite BuildX()
        {
            var t = NewTex(); var w = Color.white;
            Line(t, V(12, 32), V(52, 32), w);
            Arrow(t, V(12, 32), V(52, 32), w);   // right head
            Arrow(t, V(52, 32), V(12, 32), w);   // left head
            t.Apply(); return ToSprite(t);
        }

        private static Sprite BuildY()
        {
            var t = NewTex(); var w = Color.white;
            Line(t, V(32, 12), V(32, 52), w);
            Arrow(t, V(32, 12), V(32, 52), w);   // top head
            Arrow(t, V(32, 52), V(32, 12), w);   // bottom head
            t.Apply(); return ToSprite(t);
        }

        private static Sprite BuildZ()
        {
            // Depth axis: a diagonal double arrow (reads as "into / out of the screen").
            var t = NewTex(); var w = Color.white;
            Line(t, V(16, 16), V(48, 48), w);
            Arrow(t, V(16, 16), V(48, 48), w);
            Arrow(t, V(48, 48), V(16, 16), w);
            t.Apply(); return ToSprite(t);
        }

        private static Sprite BuildPan()
        {
            // Four-way move arrows (a plus with an arrowhead on each arm).
            var t = NewTex(); var w = Color.white;
            Line(t, V(32, 10), V(32, 54), w);
            Line(t, V(10, 32), V(54, 32), w);
            Arrow(t, V(32, 30), V(32, 54), w);   // up
            Arrow(t, V(32, 34), V(32, 10), w);   // down
            Arrow(t, V(34, 32), V(10, 32), w);   // left
            Arrow(t, V(30, 32), V(54, 32), w);   // right
            t.Apply(); return ToSprite(t);
        }

        private static Sprite BuildOrbit()
        {
            // A near-full circular arrow (rotate-around).
            var t = NewTex(); var w = Color.white;
            Vector2 c = V(32, 32); float r = 18f;
            const float start = 40f, end = 330f;
            int steps = 90;
            Vector2 prev = OnCircle(c, r, start);
            for (int i = 1; i <= steps; i++)
            {
                float a = Mathf.Lerp(start, end, i / (float)steps);
                Vector2 p = OnCircle(c, r, a);
                Line(t, prev, p, w);
                prev = p;
            }
            // Arrowhead at the open (start) end, pointing along the clockwise tangent.
            Vector2 head = OnCircle(c, r, start);
            Vector2 tangent = (OnCircle(c, r, start - 12f) - head).normalized;
            ArrowAt(t, head, tangent, w);
            t.Apply(); return ToSprite(t);
        }

        // --- tiny software rasterizer ---

        private static Vector2 V(float x, float y) => new Vector2(x, y);

        private static Vector2 OnCircle(Vector2 c, float r, float deg)
        {
            float a = deg * Mathf.Deg2Rad;
            return new Vector2(c.x + Mathf.Cos(a) * r, c.y + Mathf.Sin(a) * r);
        }

        private static Texture2D NewTex()
        {
            var t = new Texture2D(N, N, TextureFormat.RGBA32, false)
            { filterMode = FilterMode.Bilinear, wrapMode = TextureWrapMode.Clamp };
            t.SetPixels32(new Color32[N * N]); // all (0,0,0,0) transparent
            return t;
        }

        private static Sprite ToSprite(Texture2D t) =>
            Sprite.Create(t, new Rect(0, 0, N, N), new Vector2(0.5f, 0.5f), N);

        private static void Disk(Texture2D t, float cx, float cy, float r, Color c)
        {
            int x0 = Mathf.Max(0, Mathf.FloorToInt(cx - r)), x1 = Mathf.Min(N - 1, Mathf.CeilToInt(cx + r));
            int y0 = Mathf.Max(0, Mathf.FloorToInt(cy - r)), y1 = Mathf.Min(N - 1, Mathf.CeilToInt(cy + r));
            float r2 = r * r;
            for (int y = y0; y <= y1; y++)
                for (int x = x0; x <= x1; x++)
                {
                    float dx = x + 0.5f - cx, dy = y + 0.5f - cy;
                    if (dx * dx + dy * dy <= r2) t.SetPixel(x, y, c);
                }
        }

        private static void Line(Texture2D t, Vector2 a, Vector2 b, Color c)
        {
            float len = Vector2.Distance(a, b);
            int steps = Mathf.Max(1, Mathf.CeilToInt(len));
            for (int i = 0; i <= steps; i++) { var p = Vector2.Lerp(a, b, i / (float)steps); Disk(t, p.x, p.y, Stroke, c); }
        }

        /// <summary>Draw an arrowhead at <paramref name="tip"/> for a segment pointing from <paramref name="from"/>.</summary>
        private static void Arrow(Texture2D t, Vector2 from, Vector2 tip, Color c) =>
            ArrowAt(t, tip, (tip - from).normalized, c);

        /// <summary>Draw an arrowhead at <paramref name="tip"/> opening back along <paramref name="dir"/> (unit).</summary>
        private static void ArrowAt(Texture2D t, Vector2 tip, Vector2 dir, Color c)
        {
            if (dir.sqrMagnitude < 1e-4f) return;
            const float len = 11f, ang = 32f * Mathf.Deg2Rad;
            Vector2 back = -dir;
            Vector2 l = new Vector2(back.x * Mathf.Cos(ang) - back.y * Mathf.Sin(ang),
                                    back.x * Mathf.Sin(ang) + back.y * Mathf.Cos(ang));
            Vector2 r = new Vector2(back.x * Mathf.Cos(-ang) - back.y * Mathf.Sin(-ang),
                                    back.x * Mathf.Sin(-ang) + back.y * Mathf.Cos(-ang));
            Line(t, tip, tip + l * len, c);
            Line(t, tip, tip + r * len, c);
        }
    }
}
