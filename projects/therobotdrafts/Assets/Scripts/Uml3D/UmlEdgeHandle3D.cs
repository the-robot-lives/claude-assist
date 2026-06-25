using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A small draggable 3-D sphere used to edit the route of the selected link. The 3-D counterpart of the flat
    /// renderer's <c>UmlEdgeHandle</c>: the integration layer (<c>UmlCanvas</c>) spawns one per editable point on the
    /// selected edge — interior waypoints and segment midpoints (the polyline editing affordances) plus the two
    /// endpoint anchors (where the link meets each node face). A scene <see cref="Physics"/> raycast that hits the
    /// sphere maps back to this component via <c>GetComponentInParent&lt;UmlEdgeHandle3D&gt;</c>; the canvas then reads
    /// <see cref="Edge"/>, <see cref="Index"/> and <see cref="Role"/> to know what the drag should move.
    /// </summary>
    public sealed class UmlEdgeHandle3D : MonoBehaviour
    {
        /// <summary>What a handle drives.</summary>
        public enum HandleRole
        {
            /// <summary>An existing interior waypoint (drag = move, Alt-click = delete). <see cref="Index"/> = its slot.</summary>
            Waypoint,
            /// <summary>A segment midpoint (drag = insert a new waypoint there, then continue moving it).
            /// <see cref="Index"/> = the segment index it splits.</summary>
            AddMidpoint,
            /// <summary>The source endpoint attachment on the From node's face.</summary>
            SrcAnchor,
            /// <summary>The target endpoint attachment on the To node's face.</summary>
            TgtAnchor,
        }

        /// <summary>The link this handle belongs to.</summary>
        public EdgeId Edge;

        /// <summary>The route-order index this handle addresses (waypoint slot or segment index; unused for anchors).</summary>
        public int Index;

        /// <summary>What dragging/clicking this handle does.</summary>
        public HandleRole Role;

        private Material _material;
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        private const float Radius = 0.06f; // ⇒ ~0.12 world-unit diameter

        /// <summary>
        /// Build the sphere mesh, an unlit material and a <see cref="SphereCollider"/> sized to match, and tag it with
        /// the edge / index / role it edits. Returns the created component for the caller to keep in its handle list.
        /// </summary>
        public static UmlEdgeHandle3D Create(Transform parent, EdgeId edge, int index, HandleRole role, Color color)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name = "EdgeHandle:" + role;
            go.transform.SetParent(parent, false);
            go.transform.localScale = Vector3.one * (Radius * 2f);

            // CreatePrimitive gives a unit-diameter SphereCollider already; just make sure it's a trigger-free solid
            // so Physics.Raycast picks it. (Sphere primitive ships with a SphereCollider of radius 0.5 in local space.)
            var col = go.GetComponent<SphereCollider>();
            if (col == null) col = go.AddComponent<SphereCollider>();

            var handle = go.AddComponent<UmlEdgeHandle3D>();
            handle.Edge = edge;
            handle.Index = index;
            handle.Role = role;

            var mr = go.GetComponent<MeshRenderer>();
            handle._material = MakeMaterial(color);
            mr.sharedMaterial = handle._material;
            return handle;
        }

        /// <summary>Place the handle at a world position (called each frame so handles track their route points).</summary>
        public void SetWorldPosition(Vector3 world) => transform.position = world;

        /// <summary>Recolor the handle (e.g. to flag a hovered/active drag target).</summary>
        public void SetColor(Color color)
        {
            if (_material == null) return;
            _material.color = color;
            if (_material.HasProperty(BaseColorId)) _material.SetColor(BaseColorId, color);
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
