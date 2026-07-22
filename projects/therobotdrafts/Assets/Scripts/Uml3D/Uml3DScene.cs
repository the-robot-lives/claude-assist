using System.Collections.Generic;
using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// The manager the integration layer drives to render a UML diagram as a real 3-D scene. It does <em>not</em>
    /// read the authoring model directly (<c>UmlCanvas</c> owns that); instead it exposes an imperative API:
    /// add / remove nodes and edges, raycast the scene to pick a node, and pass orbit / dolly / pan / frame
    /// commands through to its <see cref="UmlCameraRig"/>. On <see cref="Awake"/> it builds the rig (on a child),
    /// a <see cref="DiagramRoot"/> transform that all nodes/edges parent under, and a directional light so the lit
    /// node material is visible.
    /// </summary>
    public sealed class Uml3DScene : MonoBehaviour
    {
        /// <summary>Transform all nodes and edges parent under, so the whole diagram can be moved as one.</summary>
        public Transform DiagramRoot { get; private set; }

        /// <summary>The rig camera — for positioning 2-D overlay menus over nodes and for screenshots.</summary>
        public Camera Camera => _rig != null ? _rig.Cam : null;

        /// <summary>The camera rig, exposed for callers that need direct access to its state.</summary>
        public UmlCameraRig Rig => _rig;

        /// <summary>All live nodes, keyed by element id.</summary>
        public IReadOnlyDictionary<ElementId, UmlNode3D> Nodes => _nodes;

        private UmlCameraRig _rig;
        private Transform _nodeRoot, _edgeRoot;
        private readonly Dictionary<ElementId, UmlNode3D> _nodes = new();
        private readonly List<UmlEdge3D> _edges = new();
        private Light _light;

        private bool _initialized;

        private void Awake() => Init();

        /// <summary>Idempotent setup: rig, diagram root, node/edge roots and a fill light. Safe to call early.</summary>
        public void Init()
        {
            if (_initialized) return;
            _initialized = true;

            DiagramRoot = new GameObject("DiagramRoot").transform;
            DiagramRoot.SetParent(transform, false);

            _nodeRoot = new GameObject("Nodes").transform;
            _nodeRoot.SetParent(DiagramRoot, false);
            _edgeRoot = new GameObject("Edges").transform;
            _edgeRoot.SetParent(DiagramRoot, false);

            var rigGo = new GameObject("CameraRig");
            rigGo.transform.SetParent(transform, false);
            _rig = rigGo.AddComponent<UmlCameraRig>();
            _rig.Init();
            // Pleasant solid slate background; applied after the rig is built so this wins over any rig default.
            if (_rig.Cam != null)
            {
                _rig.Cam.clearFlags = CameraClearFlags.SolidColor;
                _rig.Cam.backgroundColor = new Color(0.70f, 0.73f, 0.78f, 1f); // light slate
            }

            EnsureLight();
        }

        /// <summary>
        /// Create our own directional light (this is a standalone-built app, so don't gate on whether the scene
        /// already has one) and raise ambient so the slab side/back faces aren't pure black. The face content is
        /// unlit uGUI and readable regardless, but the lit slab should still shade nicely.
        /// </summary>
        private void EnsureLight()
        {
            if (_light == null)
            {
                // Three-point rig: a warm key that casts soft shadows (so nodes read as lit solids that
                // shade and shadow one another), a cool fill that lifts the shadow side, and a back/rim light
                // that grazes the top edges to separate silhouettes from the background.
                var keyGo = new GameObject("UmlKeyLight");
                keyGo.transform.SetParent(transform, false);
                _light = keyGo.AddComponent<Light>();
                _light.type = LightType.Directional;
                _light.color = new Color(1f, 0.97f, 0.92f);
                _light.intensity = 1.15f;
                keyGo.transform.rotation = Quaternion.Euler(48f, -34f, 0f);
                try
                {
                    _light.shadows = LightShadows.Soft;
                    _light.shadowStrength = 0.5f;
                    _light.shadowBias = 0.04f;
                    _light.shadowNormalBias = 0.4f;
                }
                catch (System.Exception) { }

                var fillGo = new GameObject("UmlFillLight");
                fillGo.transform.SetParent(transform, false);
                var fill = fillGo.AddComponent<Light>();
                fill.type = LightType.Directional;
                fill.color = new Color(0.80f, 0.86f, 1f);
                fill.intensity = 0.45f;
                fill.shadows = LightShadows.None;
                fillGo.transform.rotation = Quaternion.Euler(18f, 150f, 0f);

                var rimGo = new GameObject("UmlRimLight");
                rimGo.transform.SetParent(transform, false);
                var rim = rimGo.AddComponent<Light>();
                rim.type = LightType.Directional;
                rim.color = new Color(0.85f, 0.90f, 1f);
                rim.intensity = 0.55f;
                rim.shadows = LightShadows.None;
                rimGo.transform.rotation = Quaternion.Euler(-42f, 18f, 0f);
            }

            // Gradient (trilight) ambient so faces out of the key light read as soft sky/ground bounce rather
            // than flat gray. Guarded so it never throws in batchmode / headless builds.
            try
            {
                RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
                RenderSettings.ambientSkyColor = new Color(0.62f, 0.66f, 0.72f);
                RenderSettings.ambientEquatorColor = new Color(0.42f, 0.44f, 0.48f);
                RenderSettings.ambientGroundColor = new Color(0.20f, 0.21f, 0.24f);
                QualitySettings.shadowDistance = Mathf.Max(QualitySettings.shadowDistance, 60f);
            }
            catch (System.Exception)
            {
                // Ignore: ambient settings are a visual nicety, not required for correctness.
            }
        }

        // --- nodes ---

        /// <summary>Create and register a node (same arguments as <see cref="UmlNode3D.Init"/>).</summary>
        public UmlNode3D AddNode(ElementId id, string name, string stereotype, ElementKind kind, Color fill,
            Color text, List<string> attributes, List<string> operations, Vector2 sizePx)
        {
            Init();
            var go = new GameObject("Node:" + (id.Value ?? "?"));
            go.transform.SetParent(_nodeRoot, false);
            var node = go.AddComponent<UmlNode3D>();
            node.Init(id, name, stereotype, kind, fill, text, attributes, operations, sizePx);
            _nodes[id] = node;
            return node;
        }

        /// <summary>Destroy every node and clear the registry (edges are left untouched).</summary>
        public void RemoveAllNodes()
        {
            foreach (var kv in _nodes)
                if (kv.Value != null) Destroy(kv.Value.gameObject);
            _nodes.Clear();
        }

        /// <summary>Look up a live node by id.</summary>
        public bool TryGetNode(ElementId id, out UmlNode3D node) => _nodes.TryGetValue(id, out node);

        // --- edges ---

        /// <summary>Create and register a blank edge; call <see cref="UmlEdge3D.SetRoute"/> to draw it.</summary>
        public UmlEdge3D AddEdge()
        {
            Init();
            var go = new GameObject("Edge");
            go.transform.SetParent(_edgeRoot, false);
            var edge = go.AddComponent<UmlEdge3D>();
            _edges.Add(edge);
            return edge;
        }

        /// <summary>Destroy every edge.</summary>
        public void ClearEdges()
        {
            foreach (var e in _edges)
                if (e != null) Destroy(e.gameObject);
            _edges.Clear();
        }

        /// <summary>Show/hide every edge at once (e.g. to isolate a node selection for a snapshot).</summary>
        public void SetEdgesVisible(bool visible) => _edgeRoot?.gameObject.SetActive(visible);

        // --- picking ---

        /// <summary>
        /// Raycast the rig camera through <paramref name="screenPos"/> and return the hit <see cref="UmlNode3D"/>,
        /// or null. A collider hit maps to its node via <c>GetComponentInParent</c> (the collider lives on the
        /// node's slab child).
        /// </summary>
        public UmlNode3D Raycast(Vector2 screenPos)
        {
            if (_rig == null) return null;
            Ray ray = _rig.ScreenPointToRay(screenPos);
            if (Physics.Raycast(ray, out RaycastHit hit, 10000f))
                return hit.collider != null ? hit.collider.GetComponentInParent<UmlNode3D>() : null;
            return null;
        }

        // --- camera pass-throughs ---

        public void Orbit(float dYaw, float dPitch) => _rig?.Orbit(dYaw, dPitch);
        public void Dolly(float delta) => _rig?.Dolly(delta);
        public void PanPivot(Vector2 screenDelta) => _rig?.PanPivot(screenDelta);
        public Vector3 WorldToScreen(Vector3 world) => _rig != null ? _rig.WorldToScreen(world) : Vector3.zero;
        public Ray ScreenPointToRay(Vector2 screenPos) =>
            _rig != null ? _rig.ScreenPointToRay(screenPos) : new Ray(Vector3.zero, Vector3.forward);

        /// <summary>Compute the bounds of all node colliders and frame them in the camera.</summary>
        public void FrameAll()
        {
            if (_rig == null) return;
            bool any = false;
            Bounds b = new Bounds(Vector3.zero, Vector3.zero);
            foreach (var kv in _nodes)
            {
                var n = kv.Value;
                if (n == null) continue;
                var col = n.GetComponentInChildren<Collider>();
                if (col == null) continue;
                if (!any) { b = col.bounds; any = true; }
                else b.Encapsulate(col.bounds);
            }
            if (!any) b = new Bounds(DiagramRoot != null ? DiagramRoot.position : Vector3.zero, Vector3.one * 4f);
            _rig.Frame(b);
        }
    }
}
