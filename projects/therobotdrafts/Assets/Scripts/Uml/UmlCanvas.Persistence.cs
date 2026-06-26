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
        public List<SourceFileDto> sourceFiles = new();
        public string activePackage;
        public List<PackageLinkDto> packageLinks = new(); // PackageNode id → target Package id
        public List<NodeImageDto> nodeImages = new();      // element id → PNG filename under trd-images/
    }

    /// <summary>Links a node to the PNG filename (under persistentDataPath/trd-images/) shown as its face card.</summary>
    [Serializable]
    public class NodeImageDto
    {
        public string nodeId;
        public string file;
    }

    /// <summary>Links a folder PackageNode on a diagram to the top-level Package (tab) it opens.</summary>
    [Serializable]
    public class PackageLinkDto
    {
        public string nodeId;
        public string pkgId;
    }

    /// <summary>One imported source file's original text, keyed by its path — backs the overlay round-trip.</summary>
    [Serializable]
    public class SourceFileDto
    {
        public string path;
        public string content;
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
        public string description;
        public string codeDoc;
        public List<string> items = new();
        public int zLayer;
        public string code;
        public string sourceFile;
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
        public string constraint;
    }

    [Serializable]
    public class NodeGeomDto
    {
        public string id;
        public float px, py, sx, sy;
        public float pz; // continuous world-Z offset (default 0; backward-compatible — absent in old saves reads 0)
        public float th; // per-node Z thickness in world units (default 0 ⇒ use Uml3DConfig.NodeThickness)
        public bool hasStyle;
        public float fillR, fillG, fillB, fillA;
        public float borderR, borderG, borderB, borderA;
        public float textR, textG, textB, textA;
        public int fontSize;
        public string fontName;
        public float radius; // styleguide theme corner radius (px) (default 0; absent in old saves reads 0)
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
        public bool curved;
        public bool hasLevel;
        public float level;
        public int number;
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

        // The file Ctrl/Cmd+S writes to. Null ⇒ the default autosave slot (DiagramPath); set by "Save As…" / "Open file…".
        private string _currentDiagramPath;
        private string CurrentPath => string.IsNullOrEmpty(_currentDiagramPath) ? DiagramPath : _currentDiagramPath;

        /// <summary>Save to the current file (the named file from Save As / Open, else the default autosave slot).</summary>
        public void SaveDiagram()
        {
            if (WriteDiagram(CurrentPath)) Flash("saved diagram → " + CurrentPath);
        }

        /// <summary>Choose a file and save the diagram there; subsequent Ctrl/Cmd+S then targets that file.</summary>
        public void SaveDiagramAs()
        {
            CloseMenu();
            string path = BrowseForSaveFile(Path.GetFileName(CurrentPath));
            if (string.IsNullOrEmpty(path)) { Flash("save cancelled"); return; }
            if (!path.EndsWith(".json", StringComparison.OrdinalIgnoreCase)) path += ".json";
            if (WriteDiagram(path)) { _currentDiagramPath = path; Flash("saved → " + path); }
        }

        /// <summary>Choose a diagram file and load it, replacing the current diagram; Ctrl/Cmd+S then targets it.</summary>
        public void OpenDiagramFile()
        {
            CloseMenu();
            string path = BrowseForOpenFile();
            if (string.IsNullOrEmpty(path)) { Flash("open cancelled"); return; }
            try
            {
                if (!File.Exists(path)) { Flash("file not found: " + path); return; }
                var dto = JsonUtility.FromJson<DiagramDto>(File.ReadAllText(path));
                if (dto?.elements == null || dto.elements.Count == 0) { Flash("not a valid diagram: " + Path.GetFileName(path)); return; }
                ApplyDto(dto);
                _currentDiagramPath = path;
                if (_scene != null) _scene.FrameAll();
                Flash("opened " + Path.GetFileName(path));
            }
            catch (Exception ex) { Flash("open failed: " + ex.Message); }
        }

        /// <summary>Write the current diagram DTO to a path. Returns false (and flashes) on an IO error.</summary>
        private bool WriteDiagram(string path)
        {
            try { File.WriteAllText(path, JsonUtility.ToJson(BuildDto(), true)); return true; }
            catch (Exception ex) { Flash("save failed: " + ex.Message); return false; }
        }

        // --- native file pickers (editor panels; macOS player shells out to osascript; else a sensible fallback) ---

        private static string BrowseForSaveFile(string defaultName)
        {
#if UNITY_EDITOR
            string baseName = string.IsNullOrEmpty(defaultName) ? "uml-diagram" : Path.GetFileNameWithoutExtension(defaultName);
            return UnityEditor.EditorUtility.SaveFilePanel("Save diagram as", "", baseName, "json") ?? "";
#else
            if (Application.platform == RuntimePlatform.OSXPlayer)
            {
                string nm = (string.IsNullOrEmpty(defaultName) ? "uml-diagram.json" : defaultName).Replace("\"", "");
                return OsascriptPath("POSIX path of (choose file name with prompt \"Save diagram as\" default name \"" + nm + "\")");
            }
            // No native dialog on this platform — fall back to the persistent data folder so a save still lands somewhere.
            return Path.Combine(Application.persistentDataPath, string.IsNullOrEmpty(defaultName) ? "uml-diagram.json" : defaultName);
#endif
        }

        private static string BrowseForOpenFile()
        {
#if UNITY_EDITOR
            return UnityEditor.EditorUtility.OpenFilePanel("Open diagram", "", "json") ?? "";
#else
            if (Application.platform == RuntimePlatform.OSXPlayer)
                return OsascriptPath("POSIX path of (choose file with prompt \"Open diagram\")");
            return "";
#endif
        }

#if !UNITY_EDITOR
        /// <summary>Run an osascript one-liner that prints a POSIX path; returns "" on cancel / error.</summary>
        private static string OsascriptPath(string script)
        {
            try
            {
                var psi = new System.Diagnostics.ProcessStartInfo("osascript")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                };
                psi.ArgumentList.Add("-e");
                psi.ArgumentList.Add(script);
                using (var proc = System.Diagnostics.Process.Start(psi))
                {
                    string outText = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return ""; // user cancelled (osascript -128) or error
                    return (outText ?? "").Trim();
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning("file picker failed: " + ex.Message);
                return "";
            }
        }
#endif

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
                    description = el.Description,
                    codeDoc = el.CodeDoc,
                    items = new List<string>(el.Items),
                    zLayer = el.ZLayer,
                    code = el.Code,
                    sourceFile = el.SourceFile,
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
                    constraint = e.Constraint,
                });

            foreach (var kv in _pos)
            {
                var nd = new NodeGeomDto { id = kv.Key.Value, px = kv.Value.x, py = kv.Value.y };
                if (_posZ.TryGetValue(kv.Key, out var pz)) nd.pz = pz;
                if (_nodeDepth.TryGetValue(kv.Key, out var th)) nd.th = th;
                if (_size.TryGetValue(kv.Key, out var s)) { nd.sx = s.x; nd.sy = s.y; }
                if (_styles.TryGetValue(kv.Key, out var st) && st.Has)
                {
                    nd.hasStyle = true;
                    nd.fillR = st.Fill.r; nd.fillG = st.Fill.g; nd.fillB = st.Fill.b; nd.fillA = st.Fill.a;
                    nd.borderR = st.Border.r; nd.borderG = st.Border.g; nd.borderB = st.Border.b; nd.borderA = st.Border.a;
                    nd.textR = st.Text.r; nd.textG = st.Text.g; nd.textB = st.Text.b; nd.textA = st.Text.a;
                    nd.fontSize = st.FontSize; nd.fontName = st.FontName;
                    nd.radius = st.Radius;
                }
                dto.nodeGeom.Add(nd);
            }

            var edgeIds = new HashSet<EdgeId>();
            foreach (var k in _waypoints.Keys) edgeIds.Add(k);
            foreach (var k in _srcAnchor.Keys) edgeIds.Add(k);
            foreach (var k in _tgtAnchor.Keys) edgeIds.Add(k);
            foreach (var k in _curved) edgeIds.Add(k);
            foreach (var k in _msgLevel.Keys) edgeIds.Add(k);
            foreach (var k in _msgNumber.Keys) edgeIds.Add(k);
            foreach (var id in edgeIds)
            {
                var g = new EdgeGeomDto { id = id.Value };
                if (_waypoints.TryGetValue(id, out var wps))
                    foreach (var w in wps) g.waypoints.Add(new WpDto { x = w.x, y = w.y });
                if (_srcAnchor.TryGetValue(id, out var sa)) { g.hasSrc = true; g.srcSide = (int)sa.Side; g.srcT = sa.T; }
                if (_tgtAnchor.TryGetValue(id, out var ta)) { g.hasTgt = true; g.tgtSide = (int)ta.Side; g.tgtT = ta.T; }
                g.curved = _curved.Contains(id);
                if (_msgLevel.TryGetValue(id, out var lv)) { g.hasLevel = true; g.level = lv; }
                if (_msgNumber.TryGetValue(id, out var num)) g.number = num;
                dto.edgeGeom.Add(g);
            }

            foreach (var kv in _sourceFiles)
                dto.sourceFiles.Add(new SourceFileDto { path = kv.Key, content = kv.Value });

            foreach (var kv in _packageLink)
                dto.packageLinks.Add(new PackageLinkDto { nodeId = kv.Key.Value, pkgId = kv.Value.Value });

            foreach (var kv in _nodeImage)
                if (!string.IsNullOrEmpty(kv.Value))
                    dto.nodeImages.Add(new NodeImageDto { nodeId = kv.Key.Value, file = kv.Value });

            dto.activePackage = _activePackage.IsValid ? _activePackage.Value : "";
            return dto;
        }

        private void ApplyDto(DiagramDto dto)
        {
            NewWorld();
            _pos.Clear(); _posZ.Clear(); _size.Clear(); _nodeDepth.Clear();
            _waypoints.Clear(); _srcAnchor.Clear(); _tgtAnchor.Clear(); _curved.Clear(); _styles.Clear();
            _msgLevel.Clear(); _msgNumber.Clear(); _packageLink.Clear();
            _nodeImage.Clear(); _imageCache.Clear();

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
                if (!string.IsNullOrEmpty(elDto.description))
                    _ctl.SetDescription(nid, elDto.description);
                if (!string.IsNullOrEmpty(elDto.codeDoc))
                    _ctl.SetCodeDoc(nid, elDto.codeDoc);
                if (elDto.items != null && elDto.items.Count > 0)
                    _ctl.SetPropertyItems(nid, elDto.items);
                if (!string.IsNullOrEmpty(elDto.code))
                    _ctl.SetCode(nid, elDto.code);
                if (!string.IsNullOrEmpty(elDto.sourceFile))
                    _ctl.SetSourceFile(nid, elDto.sourceFile);
                _ctl.SetZLayer(nid, elDto.zLayer);
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
                        || !string.IsNullOrEmpty(eDto.tgtMult) || !string.IsNullOrEmpty(eDto.constraint))
                        _ctl.SetEdgeMeta(ne, eDto.label, eDto.srcMult, eDto.tgtMult, eDto.constraint);
                }
            _ctl.EnterSelect();

            if (dto.nodeGeom != null)
                foreach (var nd in dto.nodeGeom)
                    if (idMap.TryGetValue(nd.id, out var nid))
                    {
                        _pos[nid] = new Vector2(nd.px, nd.py);
                        if (nd.pz != 0f) _posZ[nid] = nd.pz;
                        if (nd.th > 0f) _nodeDepth[nid] = nd.th;
                        if (nd.sx > 1f && nd.sy > 1f) _size[nid] = new Vector2(nd.sx, nd.sy);
                        if (nd.hasStyle)
                            _styles[nid] = new NodeStyle
                            {
                                Has = true,
                                Fill = new Color(nd.fillR, nd.fillG, nd.fillB, nd.fillA),
                                Border = new Color(nd.borderR, nd.borderG, nd.borderB, nd.borderA),
                                Text = new Color(nd.textR, nd.textG, nd.textB, nd.textA),
                                FontSize = nd.fontSize, FontName = nd.fontName,
                                Radius = nd.radius,
                            };
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
                        if (g.curved) _curved.Add(eid);
                        if (g.hasLevel) _msgLevel[eid] = g.level;
                        if (g.number > 0) _msgNumber[eid] = g.number;
                    }

            if (dto.sourceFiles != null)
                foreach (var sf in dto.sourceFiles)
                    if (sf != null && !string.IsNullOrEmpty(sf.path))
                        _sourceFiles[sf.path] = sf.content ?? "";

            if (dto.packageLinks != null)
                foreach (var pl in dto.packageLinks)
                    if (pl != null && idMap.TryGetValue(pl.nodeId, out var lnode) && idMap.TryGetValue(pl.pkgId, out var lpkg))
                        _packageLink[lnode] = lpkg;

            if (dto.nodeImages != null)
                foreach (var ni in dto.nodeImages)
                    if (ni != null && !string.IsNullOrEmpty(ni.file) && idMap.TryGetValue(ni.nodeId, out var inode))
                        _nodeImage[inode] = ni.file;

            _activePackage = (!string.IsNullOrEmpty(dto.activePackage) && idMap.TryGetValue(dto.activePackage, out var ap))
                ? ap : ElementId.None;
            _selectedId = ElementId.None;
            _selectedEdge = EdgeId.None;
            _ctl.ClearHistory(); // a load is not an undoable edit
            RebuildFromModel();
        }

        /// <summary>Delete the persisted diagram file (so the next launch opens fresh).</summary>
        public void DeleteSavedDiagram()
        {
            try { if (File.Exists(DiagramPath)) File.Delete(DiagramPath); Flash("deleted saved file"); }
            catch (Exception ex) { Flash("delete failed: " + ex.Message); }
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
