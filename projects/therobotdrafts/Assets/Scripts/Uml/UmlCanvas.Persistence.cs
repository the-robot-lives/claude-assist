using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;

namespace TheRobotDraft.Uml
{
    // --- serialized diagram (JsonUtility DTOs: public fields, [Serializable], List<> ok) ---

    [Serializable]
    public class DiagramDto
    {
        public List<ElementDto> elements = new();
        public List<EdgeDto> edges = new();
        public List<NodeGeomDto> nodeGeom = new();
        public List<EdgeGeomDto> edgeGeom = new();
        public string activePackage;
    }

    [Serializable]
    public class ElementDto
    {
        public string id;
        public int kind;
        public string name;
        public string parent;
        public bool isAbstract;
        public string language;
        public string stereotype;
    }

    [Serializable]
    public class EdgeDto
    {
        public string id;
        public int kind;
        public string from;
        public string to;
        public string label;
        public string srcMult;
        public string tgtMult;
    }

    [Serializable]
    public class NodeGeomDto
    {
        public string id;
        public float px, py, sx, sy;
    }

    [Serializable]
    public class EdgeGeomDto
    {
        public string id;
        public List<WpDto> waypoints = new();
        public bool hasSrc;
        public int srcSide;
        public float srcT;
        public bool hasTgt;
        public int tgtSide;
        public float tgtT;
    }

    [Serializable]
    public class WpDto { public float x, y; }

    /// <summary>
    /// Save / load of the whole diagram — model (classifiers, members, edges with language/stereotype and
    /// multiplicities) plus all geometry/view-state (positions, sizes, orthogonal routes, endpoint pins). Written
    /// as JSON to <see cref="DiagramPath"/>. Load rebuilds through the public command API and remaps the saved
    /// ids to freshly-minted ones (the model assembly's internals aren't reachable from the view).
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private static string DiagramPath => Path.Combine(Application.persistentDataPath, "uml-diagram.json");

        public void SaveDiagram()
        {
            try
            {
                File.WriteAllText(DiagramPath, JsonUtility.ToJson(BuildDto(), true));
                Flash("saved diagram → " + DiagramPath);
            }
            catch (Exception ex) { Flash("save failed: " + ex.Message); }
        }

        public bool LoadDiagram()
        {
            try
            {
                if (!File.Exists(DiagramPath)) return false;
                var dto = JsonUtility.FromJson<DiagramDto>(File.ReadAllText(DiagramPath));
                if (dto?.elements == null || dto.elements.Count == 0) return false;
                ApplyDto(dto);
                Flash("loaded diagram");
                return true;
            }
            catch (Exception ex)
            {
                Debug.LogWarning("UML diagram load failed: " + ex);
                return false;
            }
        }

        private DiagramDto BuildDto()
        {
            var dto = new DiagramDto();
            foreach (var el in _model.Elements)
                dto.elements.Add(new ElementDto
                {
                    id = el.Id.Value,
                    kind = (int)el.Kind,
                    name = el.Name,
                    parent = el.Parent.IsValid ? el.Parent.Value : "",
                    isAbstract = el.IsAbstract,
                    language = el.Language,
                    stereotype = el.Stereotype,
                });

            foreach (var e in _model.Edges)
                dto.edges.Add(new EdgeDto
                {
                    id = e.Id.Value,
                    kind = (int)e.Kind,
                    from = e.From.Value,
                    to = e.To.Value,
                    label = e.Label,
                    srcMult = e.SourceMultiplicity,
                    tgtMult = e.TargetMultiplicity,
                });

            foreach (var kv in _pos)
            {
                var nd = new NodeGeomDto { id = kv.Key.Value, px = kv.Value.x, py = kv.Value.y };
                if (_size.TryGetValue(kv.Key, out var s)) { nd.sx = s.x; nd.sy = s.y; }
                dto.nodeGeom.Add(nd);
            }

            var edgeIds = new HashSet<EdgeId>();
            foreach (var k in _waypoints.Keys) edgeIds.Add(k);
            foreach (var k in _srcAnchor.Keys) edgeIds.Add(k);
            foreach (var k in _tgtAnchor.Keys) edgeIds.Add(k);
            foreach (var id in edgeIds)
            {
                var g = new EdgeGeomDto { id = id.Value };
                if (_waypoints.TryGetValue(id, out var wps))
                    foreach (var w in wps) g.waypoints.Add(new WpDto { x = w.x, y = w.y });
                if (_srcAnchor.TryGetValue(id, out var sa)) { g.hasSrc = true; g.srcSide = (int)sa.Side; g.srcT = sa.T; }
                if (_tgtAnchor.TryGetValue(id, out var ta)) { g.hasTgt = true; g.tgtSide = (int)ta.Side; g.tgtT = ta.T; }
                dto.edgeGeom.Add(g);
            }

            dto.activePackage = _activePackage.IsValid ? _activePackage.Value : "";
            return dto;
        }

        private void ApplyDto(DiagramDto dto)
        {
            NewWorld();
            _pos.Clear(); _size.Clear();
            _waypoints.Clear(); _srcAnchor.Clear(); _tgtAnchor.Clear();

            var byId = new Dictionary<string, ElementDto>();
            foreach (var e in dto.elements) byId[e.id] = e;

            // Rebuild elements parent-before-child, mapping saved ids → freshly minted ones.
            var idMap = new Dictionary<string, ElementId>();
            foreach (var elDto in OrderByDepth(dto.elements, byId))
            {
                var kind = (ElementKind)elDto.kind;
                ElementId parent = string.IsNullOrEmpty(elDto.parent) ? ElementId.None
                    : (idMap.TryGetValue(elDto.parent, out var p) ? p : ElementId.None);
                _ctl.EnterAddNode(kind);
                var nid = _ctl.CommitAddNode(parent, elDto.name);
                if (!nid.IsValid) continue;
                idMap[elDto.id] = nid;
                if (elDto.isAbstract) _ctl.SetAbstract(nid, true);
                if (!string.IsNullOrEmpty(elDto.language) || !string.IsNullOrEmpty(elDto.stereotype))
                    _ctl.SetMeta(nid, elDto.language, elDto.stereotype);
            }

            var edgeMap = new Dictionary<string, EdgeId>();
            if (dto.edges != null)
                foreach (var eDto in dto.edges)
                {
                    if (!idMap.TryGetValue(eDto.from, out var nf) || !idMap.TryGetValue(eDto.to, out var nt)) continue;
                    _ctl.EnterConnect(CommitStyle.OneShot, (EdgeKind)eDto.kind);
                    _ctl.BeginConnect(nf);
                    var ne = _ctl.CommitConnect(nt);
                    if (!ne.IsValid) continue;
                    edgeMap[eDto.id] = ne;
                    if (!string.IsNullOrEmpty(eDto.label) || !string.IsNullOrEmpty(eDto.srcMult)
                        || !string.IsNullOrEmpty(eDto.tgtMult))
                        _ctl.SetEdgeMeta(ne, eDto.label, eDto.srcMult, eDto.tgtMult);
                }
            _ctl.EnterSelect();

            if (dto.nodeGeom != null)
                foreach (var nd in dto.nodeGeom)
                    if (idMap.TryGetValue(nd.id, out var nid))
                    {
                        _pos[nid] = new Vector2(nd.px, nd.py);
                        if (nd.sx > 1f && nd.sy > 1f) _size[nid] = new Vector2(nd.sx, nd.sy);
                    }

            if (dto.edgeGeom != null)
                foreach (var g in dto.edgeGeom)
                    if (edgeMap.TryGetValue(g.id, out var eid))
                    {
                        if (g.waypoints != null && g.waypoints.Count > 0)
                        {
                            var l = new List<Vector2>(g.waypoints.Count);
                            foreach (var w in g.waypoints) l.Add(new Vector2(w.x, w.y));
                            _waypoints[eid] = l;
                        }
                        if (g.hasSrc) _srcAnchor[eid] = new EndAnchor((BoxSide)g.srcSide, g.srcT);
                        if (g.hasTgt) _tgtAnchor[eid] = new EndAnchor((BoxSide)g.tgtSide, g.tgtT);
                    }

            _activePackage = (!string.IsNullOrEmpty(dto.activePackage) && idMap.TryGetValue(dto.activePackage, out var ap))
                ? ap : ElementId.None;
            _selectedId = ElementId.None;
            _selectedEdge = EdgeId.None;
            RebuildFromModel();
        }

        private static List<ElementDto> OrderByDepth(List<ElementDto> els, Dictionary<string, ElementDto> byId)
        {
            int Depth(ElementDto e)
            {
                int d = 0, guard = 0;
                var cur = e;
                while (cur != null && !string.IsNullOrEmpty(cur.parent) && byId.TryGetValue(cur.parent, out var par))
                {
                    d++; cur = par;
                    if (++guard > 100000) break;
                }
                return d;
            }
            var list = new List<ElementDto>(els);
            list.Sort((a, b) => Depth(a).CompareTo(Depth(b)));
            return list;
        }
    }
}
