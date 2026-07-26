using UnityEngine;
using UnityEngine.UI;

namespace TheRobotDraft.Uml.Chrome
{
    /// <summary>
    /// From-scratch macOS-lookalike form chrome (dark Nocturne). No Asset Store packs —
    /// all surfaces are procedurally rasterized 9-slice (or 3-slice) sprites with SDF
    /// rounded corners. Shared by dialogs via UmlCanvas / BrowseNav constructors.
    /// </summary>
    public static class MacOsControlKit
    {
        /// <summary>
        /// Supersampling factor for the procedurally rasterized sprite atlas. Every metric below
        /// (and every texel-space literal in the SDF rasterizers) is authored in 1× design texels
        /// and scaled by this; <see cref="PixelsPerUnit"/> scales in lockstep, so a sprite's
        /// *rendered* corner radius and border width are unchanged while the rasterization gains
        /// detail. At 1× a 14px corner was resolved by 14 texels and visibly softened once the
        /// CanvasScaler pushed past 1:1 on a high-DPI display.
        /// <para>Cost is one-time texture memory: 11 sprites × <see cref="TextureSize"/>².</para>
        /// </summary>
        public const float Density = 2f;

        public const int TextureSize = (int)(64 * Density);
        public const float CornerRadius = 14f * Density;
        public const float PanelCornerRadius = 16f * Density;
        public const float CheckboxCornerRadius = 10f * Density;
        public const float SliceBorder = 20f * Density;
        public const float PixelsPerUnit = 100f * Density;

        // --- Concept D / Nocturne palette (demo tokens; tint multiplies grayscale sprites) ---
        public static readonly Color PrimaryFill = ConceptDTheme.Primary;
        public static readonly Color SecondaryFill = ConceptDTheme.Secondary;
        public static readonly Color TextFieldFill = ConceptDTheme.Field;
        public static readonly Color PanelFill = ConceptDTheme.Dialog;
        public static readonly Color PopoverFill = ConceptDTheme.Popover;
        public static readonly Color MenuRowFill = ConceptDTheme.MenuRow;
        public static readonly Color MenuRowHover = ConceptDTheme.AccentDim;
        public static readonly Color CheckboxFill = ConceptDTheme.Checkbox;
        public static readonly Color CheckboxCheckedFill = ConceptDTheme.CheckboxOn;
        public static readonly Color SeparatorFill = ConceptDTheme.Line;
        public static readonly Color ScrollWellFill = ConceptDTheme.ScrollWell;
        public static readonly Color BackdropFill = ConceptDTheme.Backdrop;
        public static readonly Color ProgressTrackFill = ConceptDTheme.ProgressTrack;
        public static readonly Color SegmentIdleFill = ConceptDTheme.SegmentIdle;
        public static readonly Color SegmentActiveFill = ConceptDTheme.Accent;

        private static Sprite _primaryBtn, _secondaryBtn, _textField, _panel, _popover, _menuRow;
        private static Sprite _checkbox, _separator, _scrollWell, _progressTrack, _segment;

        public enum Role
        {
            PrimaryButton,
            SecondaryButton,
            TextField,
            Panel,
            Popover,
            MenuRow,
            Checkbox,
            Separator,
            ScrollWell,
            ProgressTrack,
            Segment,
            Backdrop
        }

        public readonly struct Style
        {
            public readonly Role Role;
            public readonly Sprite Sprite;
            public readonly Image.Type ImageType;
            public readonly Color Color;
            public readonly string SpriteName;
            public readonly Vector4 SliceBorders;

            public Style(Role role, Sprite sprite, Image.Type imageType, Color color, string spriteName,
                Vector4 sliceBorders)
            {
                Role = role;
                Sprite = sprite;
                ImageType = imageType;
                Color = color;
                SpriteName = spriteName;
                SliceBorders = sliceBorders;
            }

            public bool IsSlicedRounded =>
                Sprite != null
                && (ImageType == Image.Type.Sliced || ImageType == Image.Type.Tiled)
                && (ImageType != Image.Type.Sliced || Sprite.border.x >= 1f || Sprite.border.y >= 1f);
        }

        public static Style StyleFor(Role role)
        {
            switch (role)
            {
                case Role.PrimaryButton:
                    return MakeStyle(role, PrimaryButtonSprite(), PrimaryFill);
                case Role.SecondaryButton:
                    return MakeStyle(role, SecondaryButtonSprite(), SecondaryFill);
                case Role.TextField:
                    return MakeStyle(role, TextFieldSprite(), TextFieldFill);
                case Role.Panel:
                    return MakeStyle(role, PanelSprite(), PanelFill);
                case Role.Popover:
                    return MakeStyle(role, PopoverSprite(), PopoverFill);
                case Role.MenuRow:
                    return MakeStyle(role, MenuRowSprite(), MenuRowFill);
                case Role.Checkbox:
                    return MakeStyle(role, CheckboxSprite(), CheckboxFill);
                case Role.Separator:
                    return MakeStyle(role, SeparatorSprite(), SeparatorFill, Image.Type.Sliced);
                case Role.ScrollWell:
                    return MakeStyle(role, ScrollWellSprite(), ScrollWellFill);
                case Role.ProgressTrack:
                    return MakeStyle(role, ProgressTrackSprite(), ProgressTrackFill);
                case Role.Segment:
                    return MakeStyle(role, SegmentSprite(), SegmentIdleFill);
                case Role.Backdrop:
                    // Full-bleed dim — solid Simple (no corner slice needed).
                    return new Style(role, null, Image.Type.Simple, BackdropFill, "MacOsBackdrop", Vector4.zero);
                default:
                    return StyleFor(Role.SecondaryButton);
            }
        }

        private static Style MakeStyle(Role role, Sprite sp, Color color, Image.Type type = Image.Type.Sliced) =>
            new Style(role, sp, type, color, sp != null ? sp.name : role.ToString(),
                sp != null ? sp.border : Vector4.zero);

        public static Role ClassifyButtonColor(Color c)
        {
            float max = Mathf.Max(c.r, Mathf.Max(c.g, c.b));
            float min = Mathf.Min(c.r, Mathf.Min(c.g, c.b));
            return (max - min) > 0.10f ? Role.PrimaryButton : Role.SecondaryButton;
        }

        public static Style Apply(Image image, Role role, Color? overrideColor = null)
        {
            if (image == null) throw new System.ArgumentNullException(nameof(image));
            var style = StyleFor(role);
            if (overrideColor.HasValue)
            {
                style = new Style(style.Role, style.Sprite, style.ImageType, overrideColor.Value,
                    style.SpriteName, style.SliceBorders);
            }

            if (style.Sprite != null)
            {
                image.sprite = style.Sprite;
                image.type = style.ImageType;
            }
            else
            {
                image.sprite = null;
                image.type = Image.Type.Simple;
            }

            image.color = style.Color;
            image.pixelsPerUnitMultiplier = 1f;
#if UNITY_2020_1_OR_NEWER
            image.useSpriteMesh = false;
#endif
            return style;
        }

        public static Style ApplyButton(Image image, Color requestedColor) =>
            Apply(image, ClassifyButtonColor(requestedColor), requestedColor);

        public static void ApplyButtonInteraction(Button button, Color requestedColor)
        {
            if (button == null) return;
            var role = ClassifyButtonColor(requestedColor);
            ApplySelectableColors(button, role == Role.PrimaryButton ? 1.12f : 1.08f,
                role == Role.PrimaryButton ? 0.88f : 0.90f);
            if (button.targetGraphic is Image img) img.color = requestedColor;
        }

        public static Style ApplyTextField(Image image) => Apply(image, Role.TextField);
        public static Style ApplyPanel(Image image, Color? color = null) => Apply(image, Role.Panel, color);
        public static Style ApplyPopover(Image image, Color? color = null) => Apply(image, Role.Popover, color);
        public static Style ApplyMenuRow(Image image, Color? color = null) => Apply(image, Role.MenuRow, color);
        public static Style ApplyCheckbox(Image image, bool isChecked = false) =>
            Apply(image, Role.Checkbox, isChecked ? CheckboxCheckedFill : CheckboxFill);
        public static Style ApplySeparator(Image image) => Apply(image, Role.Separator);
        public static Style ApplyScrollWell(Image image) => Apply(image, Role.ScrollWell);
        public static Style ApplyProgressTrack(Image image) => Apply(image, Role.ProgressTrack);
        public static Style ApplySegment(Image image, bool active) =>
            Apply(image, Role.Segment, active ? SegmentActiveFill : SegmentIdleFill);
        public static Style ApplyBackdrop(Image image) => Apply(image, Role.Backdrop);

        public static void ApplyMenuRowInteraction(Button button)
        {
            if (button == null) return;
            ApplySelectableColors(button, 1.15f, 0.92f);
            // Highlight uses accent-ish tint via ColorBlock on white-ish row sprite.
            var colors = button.colors;
            colors.highlightedColor = new Color(1.25f, 1.25f, 1.25f, 1f);
            colors.pressedColor = new Color(0.9f, 0.9f, 0.9f, 1f);
            button.colors = colors;
        }

        // --- construction helpers (tests + optional direct use) ---

        public static Button CreateButton(Transform parent, string name, Vector2 size, Color color)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Button" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyButton(img, color);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            ApplyButtonInteraction(btn, color);
            return btn;
        }

        public static InputField CreateTextField(Transform parent, string name, Vector2 size)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Input" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyTextField(img);
            var field = go.AddComponent<InputField>();
            field.targetGraphic = img;
            return field;
        }

        public static Image CreatePanel(Transform parent, string name, Vector2 size)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Panel" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyPanel(img);
            return img;
        }

        public static Image CreatePopover(Transform parent, string name, Vector2 size)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Popover" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyPopover(img);
            return img;
        }

        public static Image CreateCheckboxBox(Transform parent, string name, Vector2 size, bool isChecked)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Checkbox" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyCheckbox(img, isChecked);
            return img;
        }

        public static Image CreateMenuRow(Transform parent, string name, Vector2 size)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "MenuRow" : name, typeof(RectTransform));
            ((RectTransform)go.transform).SetParent(parent, false);
            ((RectTransform)go.transform).sizeDelta = size;
            var img = go.AddComponent<Image>();
            ApplyMenuRow(img);
            return img;
        }

        public static Image CreateSeparator(Transform parent, string name, float width)
        {
            var go = new GameObject(string.IsNullOrEmpty(name) ? "Separator" : name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.sizeDelta = new Vector2(width, 1f);
            var img = go.AddComponent<Image>();
            ApplySeparator(img);
            return img;
        }

        private static void ApplySelectableColors(Selectable sel, float lift, float press)
        {
            var colors = sel.colors;
            colors.normalColor = Color.white;
            colors.highlightedColor = new Color(lift, lift, lift, 1f);
            colors.pressedColor = new Color(press, press, press, 1f);
            colors.selectedColor = colors.highlightedColor;
            colors.disabledColor = new Color(0.55f, 0.55f, 0.55f, 0.55f);
            colors.colorMultiplier = 1f;
            colors.fadeDuration = 0.08f;
            sel.colors = colors;
            sel.transition = Selectable.Transition.ColorTint;
        }

        // --- sprites ---

        public static Sprite PrimaryButtonSprite() =>
            _primaryBtn ?? (_primaryBtn = BuildRaised("MacOsPrimaryButton", CornerRadius, strong: true));

        public static Sprite SecondaryButtonSprite() =>
            _secondaryBtn ?? (_secondaryBtn = BuildRaised("MacOsSecondaryButton", CornerRadius, strong: false));

        public static Sprite TextFieldSprite() =>
            _textField ?? (_textField = BuildRecessed("MacOsTextField", CornerRadius, borderW: 2.2f * Density, well: 0.55f));

        public static Sprite PanelSprite() =>
            _panel ?? (_panel = BuildRaised("MacOsPanel", PanelCornerRadius, strong: false, body: 0.92f, rim: 0.08f));

        public static Sprite PopoverSprite() =>
            _popover ?? (_popover = BuildRaised("MacOsPopover", CornerRadius, strong: false, body: 0.90f, rim: 0.10f));

        public static Sprite MenuRowSprite() =>
            _menuRow ?? (_menuRow = BuildRaised("MacOsMenuRow", 8f * Density, strong: false, body: 0.93f, rim: 0.03f));

        public static Sprite CheckboxSprite() =>
            _checkbox ?? (_checkbox = BuildRecessed("MacOsCheckbox", CheckboxCornerRadius, borderW: 3f * Density, well: 0.50f));

        public static Sprite SeparatorSprite() =>
            _separator ?? (_separator = BuildSeparator("MacOsSeparator"));

        public static Sprite ScrollWellSprite() =>
            _scrollWell ?? (_scrollWell = BuildRecessed("MacOsScrollWell", CornerRadius, borderW: 1.5f * Density, well: 0.48f));

        public static Sprite ProgressTrackSprite() =>
            _progressTrack ?? (_progressTrack = BuildRaised("MacOsProgressTrack", 10f * Density, strong: false, body: 0.88f, rim: 0.04f));

        public static Sprite SegmentSprite() =>
            _segment ?? (_segment = BuildRaised("MacOsSegment", 10f * Density, strong: false, body: 0.94f, rim: 0.05f));

        // --- SDF rasterizers ---

        private static Sprite BuildRaised(string name, float radius, bool strong,
            float body = 0.95f, float rim = 0.06f)
        {
            const int n = TextureSize;
            const float aa = 0.6f * Density; // edge antialias half-width, in texels
            var tex = NewTex(n);
            float cx = (n - 1) * 0.5f, cy = (n - 1) * 0.5f;
            float w = n - 3f * Density, h = n - 3f * Density;

            for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++)
            {
                float px = x + 0.5f, py = y + 0.5f;
                float d = SignedDistRoundRect(px, py, cx, cy, w, h, radius);
                float a = Mathf.Clamp01(1f - Smooth01(d + aa, d - aa, 0f));
                if (a < 0.004f) { tex.SetPixel(x, y, default); continue; }

                float ny = Mathf.InverseLerp(cy - h * 0.5f, cy + h * 0.5f, py);
                float nx = Mathf.InverseLerp(cx - w * 0.5f, cx + w * 0.5f, px);
                float v = body;
                float topLift = strong ? 0.14f : 0.08f;
                v += (ny - 0.45f) * topLift;
                float spec = Mathf.Exp(-Mathf.Pow((1f - ny) * 6.5f, 2f)) * (strong ? 0.10f : 0.05f);
                v += spec;
                v -= Mathf.Exp(-Mathf.Pow(ny * 5.5f, 2f)) * (strong ? 0.10f : 0.07f);
                // Rim highlight: offset and falloff are both texel-space, so scale with Density.
                v += Mathf.Exp(-Mathf.Pow((d + 0.9f * Density) / Density, 2f) * 3.5f) * rim;
                v += (1f - Mathf.Abs(nx - 0.5f) * 2f) * 0.02f;
                v = Mathf.Clamp(v, 0.55f, 1.12f);
                tex.SetPixel(x, y, new Color(v, v, v, a));
            }

            tex.Apply(false, false);
            return ToSlicedSprite(tex, name, SliceBorder);
        }

        private static Sprite BuildRecessed(string name, float radius, float borderW, float well)
        {
            const int n = TextureSize;
            const float aa = 0.6f * Density; // edge antialias half-width, in texels
            var tex = NewTex(n);
            float cx = (n - 1) * 0.5f, cy = (n - 1) * 0.5f;
            float w = n - 3f * Density, h = n - 3f * Density;

            for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++)
            {
                float px = x + 0.5f, py = y + 0.5f;
                float dOuter = SignedDistRoundRect(px, py, cx, cy, w, h, radius);
                float a = Mathf.Clamp01(1f - Smooth01(dOuter + aa, dOuter - aa, 0f));
                if (a < 0.004f) { tex.SetPixel(x, y, default); continue; }

                float dInner = SignedDistRoundRect(px, py, cx, cy,
                    w - 2f * borderW, h - 2f * borderW, Mathf.Max(2f * Density, radius - borderW));
                float ny = Mathf.InverseLerp(cy - h * 0.5f, cy + h * 0.5f, py);

                float wellV = well;
                wellV -= Mathf.Exp(-Mathf.Pow((1f - ny) * 4.2f, 2f)) * 0.12f;
                wellV += Mathf.Exp(-Mathf.Pow(ny * 4.5f, 2f)) * 0.04f;
                float rimV = 0.95f + (ny - 0.5f) * 0.06f;
                // Border ramp and outer-rim glow are texel-space; scale both with Density.
                float t = Smooth01(-0.4f * Density, 0.9f * Density, dInner);
                float v = Mathf.Lerp(wellV, rimV, t);
                v += Mathf.Exp(-Mathf.Pow((dOuter + 0.7f * Density) / Density, 2f) * 4f) * 0.08f;
                v = Mathf.Clamp(v, 0.35f, 1.05f);
                tex.SetPixel(x, y, new Color(v, v, v, a));
            }

            tex.Apply(false, false);
            return ToSlicedSprite(tex, name, SliceBorder);
        }

        /// <summary>1×8 horizontal hairline for menu separators (3-slice left/right caps optional).</summary>
        private static Sprite BuildSeparator(string name)
        {
            const int n = (int)(8 * Density);
            const float cap = 2f * Density;
            var tex = NewTex(n);
            for (int y = 0; y < n; y++)
            for (int x = 0; x < n; x++)
            {
                // Thin mid-row line with soft vertical AA (thickness held in design texels).
                float dy = Mathf.Abs(y + 0.5f - n * 0.5f) / Density;
                float a = Mathf.Clamp01(1f - dy);
                float v = 0.85f;
                tex.SetPixel(x, y, new Color(v, v, v, a * 0.9f));
            }

            tex.Apply(false, false);
            // Horizontal 3-slice: left/right 2px caps, stretch center.
            var sp = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), PixelsPerUnit,
                0, SpriteMeshType.FullRect, new Vector4(cap, cap, cap, cap));
            sp.name = name;
            return sp;
        }

        private static float SignedDistRoundRect(float x, float y, float cx, float cy, float w, float h, float r)
        {
            float hx = Mathf.Max(0f, w * 0.5f - r);
            float hy = Mathf.Max(0f, h * 0.5f - r);
            float dx = Mathf.Abs(x - cx) - hx;
            float dy = Mathf.Abs(y - cy) - hy;
            float ax = Mathf.Max(dx, 0f);
            float ay = Mathf.Max(dy, 0f);
            return Mathf.Sqrt(ax * ax + ay * ay) + Mathf.Min(Mathf.Max(dx, dy), 0f) - r;
        }

        private static float Smooth01(float edge0, float edge1, float x)
        {
            if (Mathf.Abs(edge1 - edge0) < 1e-5f) return x < edge0 ? 0f : 1f;
            float t = Mathf.Clamp01((x - edge0) / (edge1 - edge0));
            return t * t * (3f - 2f * t);
        }

        private static Texture2D NewTex(int n)
        {
            var t = new Texture2D(n, n, TextureFormat.RGBA32, false)
            {
                filterMode = FilterMode.Bilinear,
                wrapMode = TextureWrapMode.Clamp,
                name = "MacOsControlTex"
            };
            t.SetPixels32(new Color32[n * n]);
            return t;
        }

        private static Sprite ToSlicedSprite(Texture2D tex, string name, float border)
        {
            var sp = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f),
                PixelsPerUnit, 0, SpriteMeshType.FullRect, new Vector4(border, border, border, border));
            sp.name = name;
            return sp;
        }

#if UNITY_EDITOR
        public static void ResetCachesForTests()
        {
            _primaryBtn = _secondaryBtn = _textField = _panel = _popover = _menuRow = null;
            _checkbox = _separator = _scrollWell = _progressTrack = _segment = null;
        }
#endif
    }
}
