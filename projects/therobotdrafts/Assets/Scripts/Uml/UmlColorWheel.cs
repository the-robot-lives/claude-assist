using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A procedural HSV hue/saturation disc, drawn at full value (V=1): hue runs around the rim, saturation runs
    /// from white at the centre to fully-saturated at the rim. The mesh is a triangle fan so it stays crisp at any
    /// size without a texture. Click or drag anywhere on the disc to pick a hue/saturation pair — the chosen value
    /// is reported through <see cref="OnHueSat"/> as (hue, saturation) both normalised to 0..1. Brightness (value)
    /// and alpha are not part of the disc; the style picker composes them with separate sliders.
    /// </summary>
    [RequireComponent(typeof(RectTransform))]
    public sealed class UmlColorWheelGraphic : Graphic, IPointerDownHandler, IDragHandler
    {
        private const int Segments = 48;

        /// <summary>Invoked with (hue, saturation) — both 0..1 — whenever the user clicks or drags on the disc.</summary>
        public Action<float, float> OnHueSat;

        /// <summary>Radius (in local units) of the rendered disc; the disc fills the RectTransform's smaller dimension.</summary>
        public float Radius
        {
            get
            {
                var r = rectTransform.rect;
                return Mathf.Min(r.width, r.height) * 0.5f;
            }
        }

        protected override void OnPopulateMesh(VertexHelper vh)
        {
            vh.Clear();

            var rect = rectTransform.rect;
            Vector2 center = rect.center;
            float radius = Mathf.Min(rect.width, rect.height) * 0.5f;
            if (radius <= 0f) return;

            // Centre vertex (index 0): full white = saturation 0 at V=1.
            var v = UIVertex.simpleVert;
            v.position = center;
            v.color = Color.white;
            vh.AddVert(v);

            // Rim vertices: hue = θ/2π, saturation 1, value 1.
            for (int i = 0; i <= Segments; i++)
            {
                float t = (float)i / Segments;     // 0..1 around the circle
                float theta = t * Mathf.PI * 2f;
                var rim = UIVertex.simpleVert;
                rim.position = new Vector3(
                    center.x + Mathf.Cos(theta) * radius,
                    center.y + Mathf.Sin(theta) * radius, 0f);
                rim.color = Color.HSVToRGB(Mathf.Repeat(t, 1f), 1f, 1f);
                vh.AddVert(rim);
            }

            // Triangle fan from the centre (vertex 0) to consecutive rim vertices (1..Segments+1).
            for (int i = 1; i <= Segments; i++)
                vh.AddTriangle(0, i, i + 1);
        }

        public void OnPointerDown(PointerEventData eventData) => PickFrom(eventData);

        public void OnDrag(PointerEventData eventData) => PickFrom(eventData);

        private void PickFrom(PointerEventData eventData)
        {
            if (OnHueSat == null) return;

            // Canvas is ScreenSpaceOverlay, so the event camera is null for the conversion.
            if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    rectTransform, eventData.position, eventData.pressEventCamera, out var local))
                return;

            var rect = rectTransform.rect;
            Vector2 center = rect.center;
            float radius = Mathf.Min(rect.width, rect.height) * 0.5f;
            if (radius <= 0f) return;

            Vector2 d = local - center;

            // Hue from the angle (atan2), normalised so 0° = red on the right and increases counter-clockwise,
            // matching the rim colours laid down in OnPopulateMesh.
            float angle = Mathf.Atan2(d.y, d.x);                 // -π..π
            float hue = Mathf.Repeat(angle / (Mathf.PI * 2f), 1f); // 0..1

            float sat = Mathf.Clamp01(d.magnitude / radius);

            OnHueSat(hue, sat);
        }
    }
}
