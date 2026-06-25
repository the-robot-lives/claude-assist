using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A standard-UML classifier box (class / interface / enum / struct) with three compartments —
    /// stereotype+name, attributes (fields), operations (methods) — so members render <em>inside</em> the box,
    /// not as separate nodes. The body drags to move, the right-edge handle drags to draw a relationship
    /// (§4.1), and the bottom-right grip drags to resize. Left-click selects; right-click / ctrl-click opens
    /// the add-member / delete menu (§3.1).
    /// </summary>
    public sealed class UmlNodeView : MonoBehaviour,
        IPointerClickHandler, IBeginDragHandler, IDragHandler,
        IPointerEnterHandler, IPointerExitHandler
    {
        public ElementId Id;
        public RectTransform Rt { get; private set; }

        /// <summary>True for a use-case system boundary / region — it carries the nodes inside it when it moves.</summary>
        public bool IsBoundary { get; private set; }
        private System.Collections.Generic.List<ElementId> _carrying; // nodes captured inside a boundary at drag-start

        private UmlCanvas _canvas;
        private CanvasGroup _hotspots; // the four connect handles, revealed on hover
        private Graphic _bg;           // Image for boxes, UmlNoteGraphic (clipped corner) for notes
        private Outline _outline;   // selection highlight (toggled)
        private Outline _border;    // permanent thin box border (conventional UML look)
        private Color _baseColor;   // resting body fill, restored after affordance tinting
        private Color _textColor = new Color(0.13f, 0.15f, 0.19f, 1f);
        private int _memberSize = 15;

        public const float DefaultWidth = 220f;
        private const float RowH = 18f;

        public void Init(UmlCanvas canvas, ElementId id, string name, string stereotype, ElementKind kind,
            Color hue, Font font, System.Collections.Generic.List<string> attributes,
            System.Collections.Generic.List<string> operations, string language, NodeStyle style,
            Vector2 sizeOverride)
        {
            _canvas = canvas;
            Id = id;
            Rt = (RectTransform)transform;
            Rt.anchorMin = Rt.anchorMax = new Vector2(0.5f, 0.5f);
            Rt.pivot = new Vector2(0.5f, 0.5f);

            // Kind-derived defaults (conventional UML look), overridden by an explicit per-element style.
            bool note = kind == ElementKind.Note;
            bool shape = IsShapeKind(kind);
            bool titled = IsTitledBox(kind);
            bool boundary = kind == ElementKind.Boundary;
            bool frame = kind == ElementKind.Frame;
            bool lifeline = kind == ElementKind.Lifeline;
            // Both system boundaries and interaction frames are "regions" that carry their nested nodes when moved.
            IsBoundary = boundary || frame;
            bool darkFill = kind == ElementKind.Actor || kind == ElementKind.StateStart || kind == ElementKind.StateEnd
                || kind == ElementKind.ForkJoin || kind == ElementKind.Junction
                || kind == ElementKind.Terminate || kind == ElementKind.FlowFinal;
            Color defaultFill =
                note ? new Color(0.99f, 0.96f, 0.74f, 1f)
                : darkFill ? new Color(0.20f, 0.21f, 0.25f, 1f)
                : Color.Lerp(hue, Color.white, 0.88f);
            Color defaultBorder = note ? new Color(0.78f, 0.70f, 0.40f, 1f)
                                       : Color.Lerp(hue, new Color(0.25f, 0.27f, 0.32f, 1f), 0.55f);
            Color defaultText = note ? new Color(0.16f, 0.15f, 0.06f, 1f) : new Color(0.13f, 0.15f, 0.19f, 1f);

            _baseColor = style.Has ? style.Fill : defaultFill;
            _textColor = style.Has ? style.Text : defaultText;
            _memberSize = style.Has && style.FontSize > 0 ? style.FontSize : 15;
            int nameSize = style.Has && style.FontSize > 0 ? style.FontSize + 3 : 18;
            font_ = style.Has && !string.IsNullOrEmpty(style.FontName) ? ResolveFont(style.FontName) : font;

            if (note) _bg = gameObject.AddComponent<UmlNoteGraphic>();
            else if (shape)
            {
                var sg = gameObject.AddComponent<UmlShapeGraphic>();
                sg.Shape = ShapeFor(kind);
                _bg = sg;
            }
            else _bg = gameObject.AddComponent<Image>();
            _bg.color = _baseColor;

            _border = gameObject.AddComponent<Outline>();
            _border.effectColor = style.Has ? style.Border : defaultBorder;
            _border.effectDistance = new Vector2(1f, 1f);

            _outline = gameObject.AddComponent<Outline>();
            _outline.effectColor = new Color(0.12f, 0.55f, 0.85f, 1f);
            _outline.effectDistance = new Vector2(2.5f, 2.5f);
            _outline.enabled = false;

            if (note)
            {
                BuildNote(name, sizeOverride);
            }
            else if (shape)
            {
                BuildShape(kind, name, sizeOverride);
            }
            else if (boundary)
            {
                BuildBoundary(name, sizeOverride, 360f, 260f);
            }
            else if (frame)
            {
                BuildBoundary(name, sizeOverride, 280f, 180f);
            }
            else if (lifeline)
            {
                BuildLifeline(name, sizeOverride);
            }
            else if (titled)
            {
                BuildTitledBox(kind, name, stereotype, sizeOverride);
            }
            else
            {
                float stereoH = string.IsNullOrEmpty(stereotype) ? 0f : 16f;
                float langH = string.IsNullOrEmpty(language) ? 0f : 14f;
                float headerH = 30f + stereoH + langH;
                float attrH = Mathf.Max(1, attributes.Count) * RowH + 6f;
                float opH = Mathf.Max(1, operations.Count) * RowH + 6f;
                float contentH = headerH + 2f + attrH + 2f + opH;

                float w = sizeOverride.x > 1f ? sizeOverride.x : DefaultWidth;
                float h = Mathf.Max(contentH, sizeOverride.y);
                Rt.sizeDelta = new Vector2(w, h);

                Color headerColor = style.Has ? Color.Lerp(style.Fill, Color.black, 0.10f)
                                              : Color.Lerp(hue, Color.white, 0.52f);
                var header = Panel("Header", 0f, headerH, headerColor);
                var nameColor = style.Has ? style.Text : new Color(0.11f, 0.12f, 0.15f, 1f);
                var subColor = style.Has ? Color.Lerp(style.Text, _baseColor, 0.35f)
                                         : new Color(0.30f, 0.32f, 0.38f, 1f);
                float ty = -4f;
                if (stereoH > 0f)
                {
                    Row(header, stereotype, ty, stereoH, 14, subColor, TextAnchor.MiddleCenter);
                    ty -= stereoH;
                }
                var nameRow = Row(header, name, ty, 28f, nameSize, nameColor, TextAnchor.MiddleCenter);
                nameRow.fontStyle = FontStyle.Bold;
                // An object-diagram instance underlines "name : Class" — the UML hallmark of an instance.
                if (kind == ElementKind.ObjectInstance)
                {
                    var ul = NewChild("NameUnderline", header);
                    ul.anchorMin = new Vector2(0.5f, 1f); ul.anchorMax = new Vector2(0.5f, 1f);
                    ul.pivot = new Vector2(0.5f, 1f);
                    ul.sizeDelta = new Vector2(Mathf.Min(w - 28f, name.Length * (nameSize * 0.56f) + 8f), 2f);
                    ul.anchoredPosition = new Vector2(0f, ty - 22f);
                    var uimg = ul.gameObject.AddComponent<Image>();
                    uimg.color = nameColor; uimg.raycastTarget = false;
                }
                ty -= 28f;
                if (langH > 0f)
                    Row(header, "{" + language + "}", ty, langH, 12, subColor, TextAnchor.MiddleCenter);

                float y = -headerH;
                Divider(y); y -= 2f;

                // Attributes compartment (fields).
                float ay = y;
                AddRows(attributes, ref ay, attrH);
                y -= attrH;
                Divider(y); y -= 2f;

                // Operations compartment (methods).
                AddRows(operations, ref y, opH);
            }

            // Four connect hotspots (§4.1 quick-handle), one per side — revealed on hover (CanvasGroup), and the
            // link leaves from the side you grab.
            var hotGo = new GameObject("Hotspots", typeof(RectTransform));
            var hotRt = (RectTransform)hotGo.transform;
            hotRt.SetParent(transform, false);
            hotRt.anchorMin = Vector2.zero; hotRt.anchorMax = Vector2.one;
            hotRt.offsetMin = Vector2.zero; hotRt.offsetMax = Vector2.zero;
            _hotspots = hotGo.AddComponent<CanvasGroup>();
            _hotspots.alpha = 0f;
            _hotspots.blocksRaycasts = false;
            foreach (BoxSide side in new[] { BoxSide.Left, BoxSide.Right, BoxSide.Top, BoxSide.Bottom })
            {
                var handleGo = new GameObject("ConnectHandle:" + side, typeof(RectTransform));
                handleGo.AddComponent<UmlConnectHandle>().Init(_canvas, this, side, hotRt);
            }
            // Resize is done by grabbing the box border (see OnBeginDrag) — no separate grip.
        }

        public void OnPointerEnter(PointerEventData e)
        {
            if (_hotspots != null) { _hotspots.alpha = 1f; _hotspots.blocksRaycasts = true; }
        }

        public void OnPointerExit(PointerEventData e)
        {
            if (_hotspots != null) { _hotspots.alpha = 0f; _hotspots.blocksRaycasts = false; }
        }

        public const float BorderGrab = 9f; // px from the edge that begins a resize instead of a move

        public void SetSelected(bool on) { if (_outline != null) _outline.enabled = on; }

        public void SetAffordance(AffordanceTint tint)
        {
            if (_bg == null) return;
            _bg.color = tint switch
            {
                AffordanceTint.Valid => new Color(0.80f, 0.93f, 0.82f, 1f),
                AffordanceTint.Invalid => new Color(0.97f, 0.82f, 0.78f, 1f), // §5.1 vermillion-family (light)
                _ => _baseColor,
            };
        }

        // --- interaction ---

        private bool _resizeL, _resizeR, _resizeT, _resizeB;

        public void OnPointerClick(PointerEventData e)
        {
            bool context = e.button == PointerEventData.InputButton.Right
                           || (e.button == PointerEventData.InputButton.Left && UmlCanvas.CtrlOrCmd());
            if (context) _canvas.ShowNodeMenu(this, e.position);
            else if (e.button == PointerEventData.InputButton.Left) _canvas.Select(this);
        }

        public void OnBeginDrag(PointerEventData e)
        {
            // Grabbing within BorderGrab px of an edge starts a resize on those edges; otherwise it's a move.
            _resizeL = _resizeR = _resizeT = _resizeB = false;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(Rt, e.position, e.pressEventCamera, out var lp))
            {
                float hw = Rt.sizeDelta.x * 0.5f, hh = Rt.sizeDelta.y * 0.5f;
                _resizeR = lp.x > hw - BorderGrab;
                _resizeL = lp.x < -hw + BorderGrab;
                _resizeT = lp.y > hh - BorderGrab;
                _resizeB = lp.y < -hh + BorderGrab;
            }
            // A boundary that's about to be moved (not resized) captures the nodes nested inside it, so they
            // travel with it as a group.
            bool resizing = _resizeL || _resizeR || _resizeT || _resizeB;
            _carrying = (IsBoundary && !resizing) ? _canvas.NodesInside(this) : null;
        }

        public void OnDrag(PointerEventData e)
        {
            // Divide by canvas scale AND diagram zoom so geometry tracks the cursor at any zoom level.
            Vector2 d = e.delta / (_canvas.ScaleFactor * _canvas.Zoom);
            if (_resizeL || _resizeR || _resizeT || _resizeB) { ResizeBy(d); return; }
            Rt.anchoredPosition += d;
            _canvas.OnNodeMoved(Id, Rt.anchoredPosition);
            if (IsBoundary && _carrying != null) _canvas.MoveNodesBy(_carrying, d);
        }

        private void ResizeBy(Vector2 d)
        {
            Vector2 size = Rt.sizeDelta, pos = Rt.anchoredPosition;
            if (_resizeR) { size.x += d.x; pos.x += d.x * 0.5f; }
            if (_resizeL) { size.x -= d.x; pos.x += d.x * 0.5f; }
            if (_resizeT) { size.y += d.y; pos.y += d.y * 0.5f; }
            if (_resizeB) { size.y -= d.y; pos.y += d.y * 0.5f; }
            size.x = Mathf.Max(140f, size.x);
            size.y = Mathf.Max(70f, size.y);
            Rt.sizeDelta = size;
            Rt.anchoredPosition = pos;
            _canvas.OnNodeResized(Id, size);
            _canvas.OnNodeMoved(Id, pos);
        }

        // --- layout helpers ---

        private void AddRows(System.Collections.Generic.List<string> items, ref float y, float compartmentH)
        {
            if (items.Count == 0) { y -= compartmentH; return; }
            float top = y - 3f;
            foreach (var s in items)
            {
                Row(transform, s, top, RowH, _memberSize, _textColor, TextAnchor.MiddleLeft);
                top -= RowH;
            }
            y -= compartmentH;
        }

        private RectTransform Panel(string name, float topY, float height, Color color)
        {
            var rt = NewChild(name, transform);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(0f, height);
            rt.anchoredPosition = new Vector2(0f, topY);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = color;
            img.raycastTarget = false;
            return rt;
        }

        private void Divider(float y)
        {
            var rt = NewChild("Divider", transform);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(0f, 2f);
            rt.anchoredPosition = new Vector2(0f, y);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = new Color(0.66f, 0.68f, 0.73f, 1f);
            img.raycastTarget = false;
        }

        private Text Row(Transform parent, string text, float topY, float height, int fontSize,
            Color color, TextAnchor align)
        {
            var rt = NewChild("Row", parent);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(-20f, height);
            rt.anchoredPosition = new Vector2(0f, topY);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            return t;
        }

        // --- use-case / state-machine / activity / deployment shapes ---

        private static bool IsShapeKind(ElementKind k) => k switch
        {
            ElementKind.Actor or ElementKind.UseCase or ElementKind.State or ElementKind.Activity
                or ElementKind.StateStart or ElementKind.StateEnd or ElementKind.Decision
                or ElementKind.ForkJoin or ElementKind.Junction or ElementKind.History
                or ElementKind.Terminate or ElementKind.FlowFinal or ElementKind.DeploymentNode
                or ElementKind.Collaboration or ElementKind.PackageNode or ElementKind.Activation
                or ElementKind.Port => true,
            _ => false,
        };

        /// <summary>A box rendered as a single titled rectangle (stereotype + name), with no member compartments.</summary>
        private static bool IsTitledBox(ElementKind k) =>
            k == ElementKind.PrimitiveType || k == ElementKind.Component || k == ElementKind.Artifact
            || k == ElementKind.Part;

        private static UmlShape ShapeFor(ElementKind k) => k switch
        {
            ElementKind.UseCase or ElementKind.Collaboration => UmlShape.Ellipse,
            ElementKind.State or ElementKind.Activity => UmlShape.RoundedRect,
            ElementKind.StateStart or ElementKind.Junction => UmlShape.Disc,
            ElementKind.StateEnd => UmlShape.RingDisc,
            ElementKind.Decision => UmlShape.Diamond,
            ElementKind.ForkJoin or ElementKind.Activation or ElementKind.Port => UmlShape.Bar,
            ElementKind.History => UmlShape.Disc,
            ElementKind.Terminate => UmlShape.Cross,
            ElementKind.FlowFinal => UmlShape.FlowFinal,
            ElementKind.DeploymentNode => UmlShape.Cube,
            ElementKind.PackageNode => UmlShape.Folder,
            _ => UmlShape.Actor,
        };

        private void BuildShape(ElementKind kind, string name, Vector2 sizeOverride)
        {
            Vector2 def = kind switch
            {
                ElementKind.UseCase => new Vector2(168f, 78f),
                ElementKind.State => new Vector2(132f, 60f),
                ElementKind.Activity => new Vector2(150f, 54f),
                ElementKind.Actor => new Vector2(74f, 116f),
                ElementKind.StateStart => new Vector2(26f, 26f),
                ElementKind.StateEnd => new Vector2(30f, 30f),
                ElementKind.Junction => new Vector2(16f, 16f),
                ElementKind.Decision => new Vector2(82f, 56f),
                ElementKind.ForkJoin => new Vector2(120f, 14f),
                ElementKind.History => new Vector2(30f, 30f),
                ElementKind.Terminate => new Vector2(28f, 28f),
                ElementKind.FlowFinal => new Vector2(28f, 28f),
                ElementKind.DeploymentNode => new Vector2(156f, 96f),
                ElementKind.Collaboration => new Vector2(150f, 90f),
                ElementKind.PackageNode => new Vector2(150f, 96f),
                ElementKind.Activation => new Vector2(14f, 90f),
                ElementKind.Port => new Vector2(16f, 16f),
                _ => new Vector2(120f, 60f),
            };
            float w = sizeOverride.x > 1f ? sizeOverride.x : def.x;
            float h = sizeOverride.y > 1f ? sizeOverride.y : def.y;
            Rt.sizeDelta = new Vector2(w, h);

            // Markers / control nodes carry no internal label (their meaning is the glyph).
            switch (kind)
            {
                case ElementKind.StateStart:
                case ElementKind.StateEnd:
                case ElementKind.Junction:
                case ElementKind.ForkJoin:
                case ElementKind.FlowFinal:
                case ElementKind.Terminate:
                case ElementKind.Decision:
                case ElementKind.Activation:
                case ElementKind.Port:
                    return;
                case ElementKind.History:
                    AddCenteredLabel("H", _memberSize + 4, FontStyle.Bold, new Color(0.13f, 0.15f, 0.19f, 1f));
                    return;
            }

            var rt = NewChild("Name", transform);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = name;
            t.fontSize = _memberSize + 1;
            t.color = kind == ElementKind.Actor || kind == ElementKind.DeploymentNode
                ? new Color(0.13f, 0.15f, 0.19f, 1f) : _textColor;
            t.alignment = TextAnchor.MiddleCenter;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            if (kind == ElementKind.Actor)
            {
                // Name below the stick figure.
                rt.anchorMin = new Vector2(0f, 0f); rt.anchorMax = new Vector2(1f, 0f);
                rt.pivot = new Vector2(0.5f, 0f);
                rt.sizeDelta = new Vector2(40f, 22f);
                rt.anchoredPosition = new Vector2(0f, 0f);
            }
            else if (kind == ElementKind.DeploymentNode)
            {
                // Inside the front face of the 3-D box (leave the top/right depth clear).
                rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
                rt.offsetMin = new Vector2(12f, 8f); rt.offsetMax = new Vector2(-12f - CubeDepth, -8f - CubeDepth);
            }
            else if (kind == ElementKind.PackageNode)
            {
                // In the folder body, below the tab.
                rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
                rt.offsetMin = new Vector2(12f, 6f); rt.offsetMax = new Vector2(-12f, -24f);
            }
            else
            {
                // Centered inside the ellipse / rounded rect.
                rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
                rt.offsetMin = new Vector2(12f, 6f); rt.offsetMax = new Vector2(-12f, -6f);
            }
        }

        internal const float CubeDepth = 14f;

        private void AddCenteredLabel(string text, int size, FontStyle weight, Color color)
        {
            var rt = NewChild("Name", transform);
            rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero; rt.offsetMax = Vector2.zero;
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text; t.fontSize = size; t.color = color; t.fontStyle = weight;
            t.alignment = TextAnchor.MiddleCenter; t.supportRichText = false; t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Overflow; t.verticalOverflow = VerticalWrapMode.Overflow;
        }

        // --- titled box (component / artifact / primitive) ---

        private void BuildTitledBox(ElementKind kind, string name, string stereotype, Vector2 sizeOverride)
        {
            float w = sizeOverride.x > 1f ? sizeOverride.x : (kind == ElementKind.PrimitiveType ? 150f : 180f);
            float h = sizeOverride.y > 1f ? sizeOverride.y : 64f;
            Rt.sizeDelta = new Vector2(w, h);

            float ty = -8f;
            if (!string.IsNullOrEmpty(stereotype))
            {
                Row(transform, stereotype, ty, 16f, 13,
                    new Color(0.30f, 0.32f, 0.38f, 1f), TextAnchor.MiddleCenter);
                ty -= 18f;
            }
            var nameRow = Row(transform, name, ty, 24f, _memberSize + 2, _textColor, TextAnchor.MiddleCenter);
            nameRow.fontStyle = FontStyle.Bold;

            if (kind == ElementKind.Component) AddComponentIcon();
            else if (kind == ElementKind.Artifact) AddArtifactIcon();
        }

        /// <summary>The two-tab component icon, tucked into the top-right corner.</summary>
        private void AddComponentIcon()
        {
            var iconCol = _border != null ? _border.effectColor : new Color(0.3f, 0.33f, 0.4f, 1f);
            var body = NewChild("CompIcon", transform);
            body.anchorMin = body.anchorMax = new Vector2(1f, 1f);
            body.pivot = new Vector2(1f, 1f);
            body.sizeDelta = new Vector2(20f, 16f);
            body.anchoredPosition = new Vector2(-8f, -8f);
            var bimg = body.gameObject.AddComponent<Image>(); bimg.color = _baseColor; bimg.raycastTarget = false;
            var bout = body.gameObject.AddComponent<Outline>();
            bout.effectColor = iconCol; bout.effectDistance = new Vector2(1f, 1f);
            for (int i = 0; i < 2; i++)
            {
                var tab = NewChild("CompTab", transform);
                tab.anchorMin = tab.anchorMax = new Vector2(1f, 1f);
                tab.pivot = new Vector2(1f, 1f);
                tab.sizeDelta = new Vector2(8f, 4f);
                tab.anchoredPosition = new Vector2(-24f, -10f - i * 6f);
                var timg = tab.gameObject.AddComponent<Image>(); timg.color = _baseColor; timg.raycastTarget = false;
                var tout = tab.gameObject.AddComponent<Outline>();
                tout.effectColor = iconCol; tout.effectDistance = new Vector2(1f, 1f);
            }
        }

        /// <summary>A small folded-corner mark identifying an «artifact».</summary>
        private void AddArtifactIcon()
        {
            var iconCol = _border != null ? _border.effectColor : new Color(0.3f, 0.33f, 0.4f, 1f);
            var corner = NewChild("ArtifactIcon", transform);
            corner.anchorMin = corner.anchorMax = new Vector2(1f, 1f);
            corner.pivot = new Vector2(1f, 1f);
            corner.sizeDelta = new Vector2(12f, 12f);
            corner.anchoredPosition = new Vector2(-8f, -8f);
            var img = corner.gameObject.AddComponent<Image>();
            img.color = iconCol; img.raycastTarget = false;
        }

        // --- use-case system boundary (frame) ---

        private void BuildBoundary(string name, Vector2 sizeOverride, float defW, float defH)
        {
            float w = sizeOverride.x > 1f ? sizeOverride.x : defW;
            float h = sizeOverride.y > 1f ? sizeOverride.y : defH;
            Rt.sizeDelta = new Vector2(w, h);

            // The body itself is click-through so use cases dropped on top stay interactive; the visible frame
            // is four thin bars (which double as resize edges), and a title chip near the top is the move grab.
            if (_bg != null) { _bg.color = new Color(0f, 0f, 0f, 0f); _bg.raycastTarget = false; }
            if (_border != null) _border.enabled = false;

            var frameCol = new Color(0.42f, 0.46f, 0.54f, 1f);
            FrameBar(new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 2f), frameCol);   // top
            FrameBar(new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0.5f, 0f), new Vector2(0f, 2f), frameCol);   // bottom
            FrameBar(new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(0f, 0.5f), new Vector2(2f, 0f), frameCol);   // left
            FrameBar(new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(1f, 0.5f), new Vector2(2f, 0f), frameCol);   // right

            // Title chip (inset from the top edge so grabbing it moves rather than resizes).
            var chip = NewChild("BoundaryTitle", transform);
            chip.anchorMin = new Vector2(0f, 1f); chip.anchorMax = new Vector2(0f, 1f);
            chip.pivot = new Vector2(0f, 1f);
            chip.sizeDelta = new Vector2(Mathf.Min(w - 8f, name.Length * 9f + 24f), 24f);
            chip.anchoredPosition = new Vector2(6f, -6f);
            var cimg = chip.gameObject.AddComponent<Image>();
            cimg.color = new Color(0.16f, 0.18f, 0.22f, 0.9f); cimg.raycastTarget = true;
            var label = Row(chip, name, -2f, 20f, _memberSize, new Color(0.90f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft);
            label.fontStyle = FontStyle.Bold;
        }

        private void FrameBar(Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 thickness, Color color)
        {
            var rt = NewChild("Frame", transform);
            rt.anchorMin = aMin; rt.anchorMax = aMax; rt.pivot = pivot;
            rt.sizeDelta = thickness; rt.anchoredPosition = Vector2.zero;
            var img = rt.gameObject.AddComponent<Image>();
            img.color = color; img.raycastTarget = true; // routes pointer events to the parent UmlNodeView
        }

        // --- sequence-diagram lifeline ---

        private void BuildLifeline(string name, Vector2 sizeOverride)
        {
            float w = sizeOverride.x > 1f ? sizeOverride.x : 132f;
            float h = sizeOverride.y > 1f ? sizeOverride.y : 240f;
            Rt.sizeDelta = new Vector2(w, h);

            var borderCol = _border != null ? _border.effectColor : new Color(0.3f, 0.33f, 0.4f, 1f);
            // The whole column is grabbable, but only the head box + dashed life line are drawn.
            if (_bg != null) { _bg.color = new Color(0f, 0f, 0f, 0f); _bg.raycastTarget = true; }
            if (_border != null) _border.enabled = false;

            const float headH = 40f;
            var head = Panel("LifelineHead", 0f, headH, _baseColor);
            var hb = head.gameObject.AddComponent<Outline>();
            hb.effectColor = borderCol; hb.effectDistance = new Vector2(1f, 1f);

            var nameRow = Row(head, name, -9f, 22f, _memberSize, _textColor, TextAnchor.MiddleCenter);
            nameRow.fontStyle = FontStyle.Bold;
            // Instance underline (a lifeline head is an object).
            var ul = NewChild("LLUnderline", head);
            ul.anchorMin = new Vector2(0.5f, 1f); ul.anchorMax = new Vector2(0.5f, 1f); ul.pivot = new Vector2(0.5f, 1f);
            ul.sizeDelta = new Vector2(Mathf.Min(w - 16f, name.Length * (_memberSize * 0.56f) + 8f), 2f);
            ul.anchoredPosition = new Vector2(0f, -30f);
            var uimg = ul.gameObject.AddComponent<Image>(); uimg.color = _textColor; uimg.raycastTarget = false;

            // Dashed life line down the center (a horizontal dash sprite rotated 90° tiles vertically).
            var line = NewChild("LifeLine", transform);
            line.anchorMin = line.anchorMax = new Vector2(0.5f, 0.5f); line.pivot = new Vector2(0.5f, 0.5f);
            line.sizeDelta = new Vector2(h - headH, 2.5f);
            line.localEulerAngles = new Vector3(0f, 0f, 90f);
            line.anchoredPosition = new Vector2(0f, -headH * 0.5f);
            var limg = line.gameObject.AddComponent<Image>();
            limg.sprite = DashSprite(); limg.type = Image.Type.Tiled;
            limg.color = new Color(0.45f, 0.49f, 0.56f, 1f); limg.raycastTarget = false;
        }

        private static Sprite _dashSprite;

        private static Sprite DashSprite()
        {
            if (_dashSprite != null) return _dashSprite;
            var tex = new Texture2D(6, 1, TextureFormat.RGBA32, false)
                { wrapMode = TextureWrapMode.Repeat, filterMode = FilterMode.Point };
            for (int x = 0; x < 6; x++) tex.SetPixel(x, 0, x < 3 ? Color.white : new Color(1, 1, 1, 0));
            tex.Apply();
            _dashSprite = Sprite.Create(tex, new Rect(0, 0, 6, 1), new Vector2(0.5f, 0.5f), 100f);
            return _dashSprite;
        }

        // --- note (comment) rendering ---

        private void BuildNote(string text, Vector2 sizeOverride)
        {
            float w = sizeOverride.x > 1f ? sizeOverride.x : 220f;
            float h = sizeOverride.y > 1f ? sizeOverride.y : 96f;
            Rt.sizeDelta = new Vector2(w, h);
            // The dog-eared corner + clipped top-right are drawn by UmlNoteGraphic (the box mesh itself).

            // Free wrapped text filling the box (with padding).
            var bodyRt = NewChild("NoteText", transform);
            bodyRt.anchorMin = Vector2.zero; bodyRt.anchorMax = Vector2.one;
            bodyRt.offsetMin = new Vector2(8f, 6f); bodyRt.offsetMax = new Vector2(-8f, -6f);
            var t = bodyRt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text;
            t.fontSize = _memberSize;
            t.color = _textColor;
            t.alignment = TextAnchor.UpperLeft;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
        }

        private Font font_;

        private static readonly System.Collections.Generic.Dictionary<string, Font> _fontCache = new();

        /// <summary>Resolve an OS font by name (cached); falls back to the built-in legacy font.</summary>
        private static Font ResolveFont(string name)
        {
            if (string.IsNullOrEmpty(name)) return Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            if (_fontCache.TryGetValue(name, out var cached) && cached != null) return cached;
            Font f = null;
            try { f = Font.CreateDynamicFontFromOSFont(name, 16); } catch { /* unknown OS font */ }
            if (f == null) f = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            _fontCache[name] = f;
            return f;
        }

        private static RectTransform NewChild(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            return rt;
        }
    }

    public enum AffordanceTint { None, Valid, Invalid }

    /// <summary>The four box sides a relationship can attach to / leave from.</summary>
    public enum BoxSide { Left, Right, Top, Bottom }

    /// <summary>An optional per-element visual override (fill / border / text color, font, size). Has=false → defaults.</summary>
    public struct NodeStyle
    {
        public bool Has;
        public Color Fill, Border, Text;
        public int FontSize;     // 0 = default
        public string FontName;  // null/empty = default legacy font
    }

    /// <summary>A per-side connect hotspot: drag from it to start a relationship that leaves from that side.</summary>
    public sealed class UmlConnectHandle : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private UmlCanvas _canvas;
        private UmlNodeView _node;
        private BoxSide _side;

        public void Init(UmlCanvas canvas, UmlNodeView node, BoxSide side, Transform parent)
        {
            _canvas = canvas; _node = node; _side = side;
            var rt = (RectTransform)transform;
            rt.SetParent(parent, false);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(15f, 15f);
            switch (side)
            {
                case BoxSide.Left:   rt.anchorMin = rt.anchorMax = new Vector2(0f, 0.5f); rt.anchoredPosition = new Vector2(2f, 0f); break;
                case BoxSide.Right:  rt.anchorMin = rt.anchorMax = new Vector2(1f, 0.5f); rt.anchoredPosition = new Vector2(-2f, 0f); break;
                case BoxSide.Top:    rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 1f); rt.anchoredPosition = new Vector2(0f, -2f); break;
                default:             rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0f); rt.anchoredPosition = new Vector2(0f, 2f); break;
            }
            gameObject.AddComponent<Image>().color = new Color(0.30f, 0.85f, 0.95f, 1f);
        }

        public void OnBeginDrag(PointerEventData e) => _canvas.BeginLink(_node, _side, e.position);
        public void OnDrag(PointerEventData e) => _canvas.UpdateLink(e.position);
        public void OnEndDrag(PointerEventData e) => _canvas.EndLink(e.position);
    }

    /// <summary>
    /// A UML note background: a rectangle whose top-right corner is actually clipped off (a pentagon), with the
    /// folded-over flap drawn in a darker shade. Outline effects then trace the clipped silhouette.
    /// </summary>
    public sealed class UmlNoteGraphic : Graphic
    {
        public float Fold = 16f;

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            Rect r = GetPixelAdjustedRect();
            float f = Mathf.Min(Fold, Mathf.Min(r.width, r.height) * 0.5f);
            float xMin = r.xMin, xMax = r.xMax, yMin = r.yMin, yMax = r.yMax;

            Color32 body = color;
            Color32 flap = new Color(color.r * 0.86f, color.g * 0.86f, color.b * 0.82f, color.a);

            // Body pentagon (top-right corner removed), as a fan from the bottom-left.
            var p0 = new Vector2(xMin, yMin);
            var p1 = new Vector2(xMax, yMin);
            var p2 = new Vector2(xMax, yMax - f);
            var p3 = new Vector2(xMax - f, yMax);
            var p4 = new Vector2(xMin, yMax);
            Tri(vh, p0, p1, p2, body);
            Tri(vh, p0, p2, p3, body);
            Tri(vh, p0, p3, p4, body);

            // Folded flap inside the cut corner (darker).
            Tri(vh, p3, p2, new Vector2(xMax - f, yMax - f), flap);
        }

        private static void Tri(VertexHelper vh, Vector2 a, Vector2 b, Vector2 c, Color32 col)
        {
            int i = vh.currentVertCount;
            vh.AddVert(a, col, Vector2.zero);
            vh.AddVert(b, col, Vector2.zero);
            vh.AddVert(c, col, Vector2.zero);
            vh.AddTriangle(i, i + 1, i + 2);
        }
    }

    /// <summary>The procedural shapes used by non-class UML nodes.</summary>
    public enum UmlShape { Ellipse, RoundedRect, Disc, RingDisc, Actor, Diamond, Bar, FlowFinal, Cube, Cross, Folder }

    /// <summary>Draws use-case (ellipse), state (rounded rect), start/final markers (disc / ring), and actors (stick figure).</summary>
    public sealed class UmlShapeGraphic : Graphic
    {
        public UmlShape Shape = UmlShape.Ellipse;

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();
            Rect r = GetPixelAdjustedRect();
            Vector2 c = r.center;
            Color32 col = color;
            switch (Shape)
            {
                case UmlShape.Ellipse:
                    AddEllipse(vh, c, r.width * 0.5f, r.height * 0.5f, 44, col);
                    break;
                case UmlShape.Disc:
                {
                    float rad = Mathf.Min(r.width, r.height) * 0.5f;
                    AddEllipse(vh, c, rad, rad, 36, col);
                    break;
                }
                case UmlShape.RingDisc:
                {
                    float rad = Mathf.Min(r.width, r.height) * 0.5f;
                    AddRing(vh, c, rad, rad * 0.74f, 36, col);
                    AddEllipse(vh, c, rad * 0.5f, rad * 0.5f, 28, col);
                    break;
                }
                case UmlShape.RoundedRect:
                    AddRoundedRect(vh, r, Mathf.Min(16f, Mathf.Min(r.width, r.height) * 0.5f), col);
                    break;
                case UmlShape.Actor:
                    AddActor(vh, r, col);
                    break;
                case UmlShape.Diamond:
                    AddDiamond(vh, r, col);
                    break;
                case UmlShape.Bar:
                    AddQuad(vh, new Vector2(r.xMin, r.yMin), new Vector2(r.xMax, r.yMin),
                        new Vector2(r.xMax, r.yMax), new Vector2(r.xMin, r.yMax), col);
                    break;
                case UmlShape.FlowFinal:
                {
                    float rad = Mathf.Min(r.width, r.height) * 0.5f;
                    AddRing(vh, c, rad, rad - Mathf.Max(2.5f, rad * 0.14f), 32, col);
                    float d = rad * 0.5f;
                    AddLine(vh, new Vector2(c.x - d, c.y - d), new Vector2(c.x + d, c.y + d), 3f, col);
                    AddLine(vh, new Vector2(c.x - d, c.y + d), new Vector2(c.x + d, c.y - d), 3f, col);
                    break;
                }
                case UmlShape.Cross:
                {
                    float d = Mathf.Min(r.width, r.height) * 0.5f;
                    AddLine(vh, new Vector2(c.x - d, c.y - d), new Vector2(c.x + d, c.y + d), 3.5f, col);
                    AddLine(vh, new Vector2(c.x - d, c.y + d), new Vector2(c.x + d, c.y - d), 3.5f, col);
                    break;
                }
                case UmlShape.Cube:
                    AddCube(vh, r, UmlNodeView.CubeDepth, col);
                    break;
                case UmlShape.Folder:
                    AddFolder(vh, r, col);
                    break;
            }
        }

        /// <summary>A package "folder": a small tab on the upper-left, then the body rectangle below it.</summary>
        private static void AddFolder(VertexHelper vh, Rect r, Color32 col)
        {
            float tabH = Mathf.Min(18f, r.height * 0.22f);
            float tabW = Mathf.Min(r.width * 0.42f, 80f);
            float bodyTop = r.yMax - tabH;
            // Tab.
            AddQuad(vh, new Vector2(r.xMin, bodyTop), new Vector2(r.xMin + tabW, bodyTop),
                new Vector2(r.xMin + tabW, r.yMax), new Vector2(r.xMin, r.yMax), col);
            // Body.
            AddQuad(vh, new Vector2(r.xMin, r.yMin), new Vector2(r.xMax, r.yMin),
                new Vector2(r.xMax, bodyTop), new Vector2(r.xMin, bodyTop), col);
        }

        private static void AddQuad(VertexHelper vh, Vector2 a, Vector2 b, Vector2 cc, Vector2 d, Color32 col)
        {
            int i = vh.currentVertCount;
            vh.AddVert(a, col, Vector2.zero);
            vh.AddVert(b, col, Vector2.zero);
            vh.AddVert(cc, col, Vector2.zero);
            vh.AddVert(d, col, Vector2.zero);
            vh.AddTriangle(i, i + 1, i + 2);
            vh.AddTriangle(i, i + 2, i + 3);
        }

        private static void AddDiamond(VertexHelper vh, Rect r, Color32 col)
        {
            Vector2 c = r.center;
            var top = new Vector2(c.x, r.yMax);
            var right = new Vector2(r.xMax, c.y);
            var bottom = new Vector2(c.x, r.yMin);
            var left = new Vector2(r.xMin, c.y);
            AddQuad(vh, left, bottom, right, top, col);
        }

        /// <summary>A 3-D box (deployment node): front face plus a top and right face in shaded tints.</summary>
        private static void AddCube(VertexHelper vh, Rect r, float depth, Color32 col)
        {
            float d = Mathf.Min(depth, Mathf.Min(r.width, r.height) * 0.3f);
            float xMin = r.xMin, xMax = r.xMax, yMin = r.yMin, yMax = r.yMax;
            Color32 top = Shade(col, 1.10f);
            Color32 side = Shade(col, 0.86f);

            // Front face.
            var fA = new Vector2(xMin, yMin);
            var fB = new Vector2(xMax - d, yMin);
            var fC = new Vector2(xMax - d, yMax - d);
            var fD = new Vector2(xMin, yMax - d);
            AddQuad(vh, fA, fB, fC, fD, col);
            // Top face.
            AddQuad(vh, fD, fC, new Vector2(xMax, yMax), new Vector2(xMin + d, yMax), top);
            // Right face.
            AddQuad(vh, fB, new Vector2(xMax, yMin + d), new Vector2(xMax, yMax), fC, side);
        }

        private static Color32 Shade(Color32 c, float f) =>
            new Color(Mathf.Clamp01(c.r / 255f * f), Mathf.Clamp01(c.g / 255f * f), Mathf.Clamp01(c.b / 255f * f),
                c.a / 255f);

        private static void AddEllipse(VertexHelper vh, Vector2 c, float rx, float ry, int segs, Color32 col)
        {
            int center = vh.currentVertCount;
            vh.AddVert(c, col, Vector2.zero);
            for (int i = 0; i <= segs; i++)
            {
                float a = i / (float)segs * Mathf.PI * 2f;
                vh.AddVert(new Vector3(c.x + Mathf.Cos(a) * rx, c.y + Mathf.Sin(a) * ry), col, Vector2.zero);
            }
            for (int i = 0; i < segs; i++) vh.AddTriangle(center, center + 1 + i, center + 2 + i);
        }

        private static void AddRing(VertexHelper vh, Vector2 c, float rOut, float rIn, int segs, Color32 col)
        {
            int start = vh.currentVertCount;
            for (int i = 0; i <= segs; i++)
            {
                float a = i / (float)segs * Mathf.PI * 2f;
                float cs = Mathf.Cos(a), sn = Mathf.Sin(a);
                vh.AddVert(new Vector3(c.x + cs * rOut, c.y + sn * rOut), col, Vector2.zero);
                vh.AddVert(new Vector3(c.x + cs * rIn, c.y + sn * rIn), col, Vector2.zero);
            }
            for (int i = 0; i < segs; i++)
            {
                int o = start + i * 2;
                vh.AddTriangle(o, o + 1, o + 2);
                vh.AddTriangle(o + 1, o + 3, o + 2);
            }
        }

        private static void AddRoundedRect(VertexHelper vh, Rect r, float rad, Color32 col)
        {
            var pts = new System.Collections.Generic.List<Vector2>();
            const int seg = 6;
            void Corner(Vector2 cc, float start)
            {
                for (int i = 0; i <= seg; i++)
                {
                    float a = start + i / (float)seg * (Mathf.PI * 0.5f);
                    pts.Add(new Vector2(cc.x + Mathf.Cos(a) * rad, cc.y + Mathf.Sin(a) * rad));
                }
            }
            Corner(new Vector2(r.xMin + rad, r.yMin + rad), Mathf.PI);
            Corner(new Vector2(r.xMax - rad, r.yMin + rad), Mathf.PI * 1.5f);
            Corner(new Vector2(r.xMax - rad, r.yMax - rad), 0f);
            Corner(new Vector2(r.xMin + rad, r.yMax - rad), Mathf.PI * 0.5f);

            int ci = vh.currentVertCount;
            vh.AddVert(r.center, col, Vector2.zero);
            for (int i = 0; i < pts.Count; i++) vh.AddVert(pts[i], col, Vector2.zero);
            for (int i = 0; i < pts.Count; i++)
            {
                int n = (i + 1) % pts.Count;
                vh.AddTriangle(ci, ci + 1 + i, ci + 1 + n);
            }
        }

        private static void AddLine(VertexHelper vh, Vector2 a, Vector2 b, float th, Color32 col)
        {
            Vector2 d = (b - a).normalized;
            Vector2 n = new Vector2(-d.y, d.x) * (th * 0.5f);
            int i = vh.currentVertCount;
            vh.AddVert(a - n, col, Vector2.zero);
            vh.AddVert(a + n, col, Vector2.zero);
            vh.AddVert(b + n, col, Vector2.zero);
            vh.AddVert(b - n, col, Vector2.zero);
            vh.AddTriangle(i, i + 1, i + 2);
            vh.AddTriangle(i, i + 2, i + 3);
        }

        private static void AddActor(VertexHelper vh, Rect r, Color32 col)
        {
            float cx = r.center.x, top = r.yMax, bot = r.yMin;
            float headR = Mathf.Min(r.width * 0.20f, r.height * 0.12f);
            float headCy = top - headR - 2f;
            AddEllipse(vh, new Vector2(cx, headCy), headR, headR, 22, col);
            float th = Mathf.Max(2.5f, r.width * 0.05f);
            float bodyTop = headCy - headR;
            float bodyBot = bot + r.height * 0.36f;
            AddLine(vh, new Vector2(cx, bodyTop), new Vector2(cx, bodyBot), th, col);            // spine
            float armY = bodyTop - (bodyTop - bodyBot) * 0.28f;
            AddLine(vh, new Vector2(cx - r.width * 0.30f, armY), new Vector2(cx + r.width * 0.30f, armY), th, col); // arms
            AddLine(vh, new Vector2(cx, bodyBot), new Vector2(cx - r.width * 0.26f, bot + 2f), th, col); // left leg
            AddLine(vh, new Vector2(cx, bodyBot), new Vector2(cx + r.width * 0.26f, bot + 2f), th, col); // right leg
        }
    }
}
