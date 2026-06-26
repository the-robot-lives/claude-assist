using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A small draggable cube shown on a node while it is in "resize mode" (entered by double-clicking the node).
    /// Each handle constrains the resize to one axis: <see cref="Role.Width"/> (X, on the right edge),
    /// <see cref="Role.Height"/> (Y, on the top edge), <see cref="Role.Depth"/> (Z thickness, at the face center)
    /// and <see cref="Role.Uniform"/> (all axes, at the top-right corner). A scene <see cref="Physics"/> raycast
    /// that hits the cube maps back here via <c>GetComponentInParent</c>; the canvas reads <see cref="HandleRole"/>
    /// and <see cref="Node"/> to drive the constrained drag.
    /// </summary>
    public sealed class UmlResizeHandle3D : MonoBehaviour
    {
        public enum Role { Width, Height, Depth, Uniform }

        public Role HandleRole;
        public ElementId Node;
        /// <summary>Face-local placement in {-1,0,1} per axis: which corner / edge / center this handle sits at.</summary>
        public Vector2 Dir;

        private Material _mat;
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private const float Size = 0.16f;

        public static UmlResizeHandle3D Create(Transform parent, ElementId node, Role role, Vector2 dir, Color color)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = "ResizeHandle:" + role;
            go.transform.SetParent(parent, false);
            go.transform.localScale = Vector3.one * Size;

            var h = go.AddComponent<UmlResizeHandle3D>();
            h.Node = node;
            h.HandleRole = role;
            h.Dir = dir;

            var mr = go.GetComponent<MeshRenderer>();
            h._mat = MakeMaterial(color);
            mr.sharedMaterial = h._mat;
            return h;
        }

        public void SetWorldPosition(Vector3 world) => transform.position = world;

        public void SetColor(Color color)
        {
            if (_mat == null) return;
            _mat.color = color;
            if (_mat.HasProperty(BaseColorId)) _mat.SetColor(BaseColorId, color);
        }

        private static Material MakeMaterial(Color color)
        {
            Shader sh = Shader.Find("Universal Render Pipeline/Unlit");
            if (sh == null) sh = Shader.Find("Unlit/Color");
            if (sh == null) sh = Shader.Find("Sprites/Default");
            if (sh == null) sh = Shader.Find("Standard");
            var m = new Material(sh) { color = color };
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            return m;
        }
    }
}
