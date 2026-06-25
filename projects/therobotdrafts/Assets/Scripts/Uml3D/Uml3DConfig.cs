using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Shared constants and the model→world coordinate contract for the 3-D diagram scene. The flat uGUI
    /// renderer (<c>UmlCanvas</c>) lays nodes out in <em>UI pixels</em>; the 3-D scene multiplies those by
    /// <see cref="WorldScale"/> so a conventional 220-px class box becomes ≈2.2 world units wide. Z-layering
    /// (the bubble-view "below / behind" stacking) is expressed as an integer <c>layerDepth</c> — the signed
    /// distance from the active layer — multiplied by <see cref="LayerGap"/>. Keeping all of this in one place
    /// means the camera rig, node, edge and scene code agree on units without a translation step.
    /// </summary>
    public static class Uml3DConfig
    {
        /// <summary>One UI pixel maps to this many world units. A 220-px node ≈ 2.2 units wide.</summary>
        public const float WorldScale = 0.01f;

        /// <summary>Depth (Z thickness) of a node slab, in world units.</summary>
        public const float NodeThickness = 0.18f;

        /// <summary>World-Z distance between two adjacent bubble-view layers (active vs. one-below, etc.).</summary>
        public const float LayerGap = 3.0f;

        /// <summary>
        /// Convert a model-space pixel position plus a (signed) layer depth into a world position.
        /// <paramref name="layerDepth"/> is <c>activeLayer - nodeLayer</c>: 0 = the active/front layer, a
        /// positive value pushes the node back (below/behind) by that many <see cref="LayerGap"/> steps. The
        /// UI's +Y-is-up convention is preserved (no Y flip), so the 3-D layout reads the same as the flat one.
        /// </summary>
        public static Vector3 ModelToWorld(Vector2 posPx, int layerDepth) =>
            new Vector3(posPx.x * WorldScale, posPx.y * WorldScale, layerDepth * LayerGap);
    }
}
