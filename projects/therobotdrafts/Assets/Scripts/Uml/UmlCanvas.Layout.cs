using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Auto-layout for the active package's diagram nodes. The importer drops types onto a 4-column grid which
    /// piles a real codebase into a cramped tall strip; these layouts re-place the node positions (<c>_pos</c>, the
    /// only geometry the 3-D renderer reads back) into a readable arrangement. Five strategies are offered:
    /// a tidy grid, a Fruchterman–Reingold force-directed spread, a layered hierarchy (DAG by inheritance /
    /// dependency), a by-source/package cluster (the best default after an import), and an LLM-assisted layout.
    /// Every strategy operates only on the "current set" — diagram nodes parented to <c>_activePackage</c> on
    /// <c>_activeLayer</c> — mirroring <see cref="RebuildFromModel"/>'s element filter, and never moves off-layer
    /// nodes. Geometry-only, so this reuses the authoring model untouched (ADR-003).
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Empty margin (px) added to the largest node footprint to form a layout grid cell.</summary>
        private const float LayoutMarginPx = 60f;

        // --- public dispatch ---

        /// <summary>
        /// Lay the current set out by <paramref name="mode"/> ("grid" / "force" / "hierarchy" / "source"), then
        /// rebuild + frame the scene. Unknown modes fall back to the tidy grid. AI layout has its own async entry
        /// point (<see cref="AutoLayoutAI"/>) since it has to await an LLM round-trip.
        /// </summary>
        public void AutoLayout(string mode)
        {
            CloseMenu();
            if (!_activePackage.IsValid) { Flash("no package to lay out"); return; }
            var ids = CollectLayoutSet();
            if (ids.Count == 0) { Flash("nothing to lay out"); return; }

            string note;
            switch ((mode ?? "source").Trim().ToLowerInvariant())
            {
                case "force": note = LayoutForceDirected(ids); break;
                case "hierarchy": note = LayoutHierarchy(ids); break;
                case "source":
                case "package": note = LayoutBySource(ids); break;
                case "grid": note = LayoutGrid(ids); break;
                default: note = LayoutGrid(ids); break;
            }

            SetSelected(ElementId.None);
            _selectedEdge = EdgeId.None;
            RebuildFromModel();
            _scene.FrameAll();
            Flash(note);
        }

        // --- shared helpers ---

        /// <summary>
        /// The current set: diagram nodes parented to the active package and sitting on the active z-layer (the same
        /// filter <see cref="RebuildFromModel"/> uses, restricted to the active layer so off-layer nodes never move).
        /// </summary>
        private List<ElementId> CollectLayoutSet()
        {
            var set = new List<ElementId>();
            foreach (var el in _model.Elements)
            {
                if (el.Parent != _activePackage) continue;
                if (!KindInfo.IsDiagramNode(el.Kind)) continue;
                if (el.ZLayer != _activeLayer) continue;
                set.Add(el.Id);
            }
            return set;
        }

        /// <summary>Largest node footprint across the set, plus a margin, giving a uniform grid cell (px).</summary>
        private void LayoutCellSize(List<ElementId> ids, float margin, out float cellW, out float cellH)
        {
            float w = 0f, h = 0f;
            foreach (var id in ids)
            {
                Vector2 s = CurrentNodeSizePx(id);
                if (s.x > w) w = s.x;
                if (s.y > h) h = s.y;
            }
            cellW = (w > 1f ? w : UmlNodeView.DefaultWidth) + margin;
            cellH = (h > 1f ? h : 120f) + margin;
        }

        /// <summary>Map each id to its index in the set (for building edge adjacency over the current set only).</summary>
        private Dictionary<ElementId, int> BuildLayoutIndex(List<ElementId> ids)
        {
            var index = new Dictionary<ElementId, int>(ids.Count);
            for (int i = 0; i < ids.Count; i++) index[ids[i]] = i;
            return index;
        }

        /// <summary>Edges of the model whose BOTH endpoints lie in the set, as (fromIndex, toIndex) pairs (no self-loops).</summary>
        private List<(int a, int b)> BuildEdgePairs(List<ElementId> ids, Dictionary<ElementId, int> index)
        {
            var pairs = new List<(int, int)>();
            foreach (var e in _model.Edges)
            {
                if (index.TryGetValue(e.From, out var a) && index.TryGetValue(e.To, out var b) && a != b)
                    pairs.Add((a, b));
            }
            return pairs;
        }

        /// <summary>Smallest square-grid column count that fits <paramref name="n"/> nodes (≥ 1).</summary>
        private static int CeilSqrt(int n) => Mathf.Max(1, Mathf.CeilToInt(Mathf.Sqrt(Mathf.Max(1, n))));

        /// <summary>Center a computed layout's bounding box on the origin, then commit it to <c>_pos</c>.</summary>
        private void CenterAndAssign(List<ElementId> ids, Vector2[] p)
        {
            if (p.Length == 0) return;
            float minX = float.MaxValue, minY = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            for (int i = 0; i < p.Length; i++)
            {
                if (p[i].x < minX) minX = p[i].x;
                if (p[i].x > maxX) maxX = p[i].x;
                if (p[i].y < minY) minY = p[i].y;
                if (p[i].y > maxY) maxY = p[i].y;
            }
            float cx = (minX + maxX) * 0.5f, cy = (minY + maxY) * 0.5f;
            for (int i = 0; i < ids.Count; i++)
                _pos[ids[i]] = new Vector2(p[i].x - cx, p[i].y - cy);
        }

        // --- 1) tidy grid ---

        /// <summary>
        /// Row-major square grid: <c>cols = ceil(sqrt(n))</c>, every cell the size of the largest node footprint plus
        /// a margin, centered on the origin. Instantly de-cramps an import's tall strip.
        /// </summary>
        private string LayoutGrid(List<ElementId> ids)
        {
            int n = ids.Count;
            int cols = CeilSqrt(n);
            LayoutCellSize(ids, LayoutMarginPx, out float cellW, out float cellH);

            var p = new Vector2[n];
            for (int i = 0; i < n; i++)
            {
                int r = i / cols, c = i % cols;
                p[i] = new Vector2(c * cellW, -r * cellH); // rows descend (−y) so the first row reads as the top
            }
            CenterAndAssign(ids, p);
            return $"tidy grid — {n} node{(n == 1 ? "" : "s")}";
        }

        // --- 2) force-directed (Fruchterman–Reingold) ---

        /// <summary>
        /// Fruchterman–Reingold spring layout: repulsion <c>k²/d</c> between every node pair, attraction <c>d²/k</c>
        /// along edges, with a per-iteration max displacement that cools linearly to 0 over ~300 iterations. The ideal
        /// edge length <c>k ≈ sqrt(area/n)</c> scales with the node footprint so connected components spread without
        /// overlapping. Seeded from the current positions (or a grid when they're coincident). Above 400 nodes the
        /// all-pairs repulsion is skipped and we fall back to the tidy grid.
        /// </summary>
        private string LayoutForceDirected(List<ElementId> ids)
        {
            int n = ids.Count;
            if (n > 400) return LayoutGrid(ids) + " (force-directed skipped: >400 nodes)";

            var index = BuildLayoutIndex(ids);
            var edges = BuildEdgePairs(ids, index);

            LayoutCellSize(ids, LayoutMarginPx, out float cellW, out float cellH);
            float spacing = Mathf.Max(cellW, cellH);
            float area = spacing * spacing * n;        // ≈ one cell of breathing room per node
            float k = Mathf.Sqrt(area / Mathf.Max(1, n)); // ideal edge length (= spacing here)

            // Seed from current positions when they actually spread; otherwise a deterministic grid (no RNG) so the
            // symmetry is broken without a varying result run-to-run.
            var pos = new Vector2[n];
            if (CurrentPositionsSpread(ids, spacing))
            {
                for (int i = 0; i < n; i++)
                    pos[i] = _pos.TryGetValue(ids[i], out var cur) ? cur : Vector2.zero;
            }
            else
            {
                int cols = CeilSqrt(n);
                for (int i = 0; i < n; i++)
                    pos[i] = new Vector2((i % cols) * spacing, -(i / cols) * spacing);
            }

            const int iterations = 300;
            float temp = spacing * Mathf.Sqrt(Mathf.Max(1, n)) * 0.1f; // initial max step
            float cool = temp / iterations;
            var disp = new Vector2[n];
            const float eps = 0.01f;

            for (int it = 0; it < iterations; it++)
            {
                for (int i = 0; i < n; i++) disp[i] = Vector2.zero;

                // Repulsion between every pair (O(n²); n ≤ 400 here).
                for (int i = 0; i < n; i++)
                {
                    for (int j = i + 1; j < n; j++)
                    {
                        Vector2 delta = pos[i] - pos[j];
                        float d = delta.magnitude;
                        if (d < eps) { delta = new Vector2((i - j) * 0.01f + eps, (i + j) * 0.007f + eps); d = delta.magnitude; }
                        Vector2 dir = delta / d;
                        float force = (k * k) / d;
                        disp[i] += dir * force;
                        disp[j] -= dir * force;
                    }
                }

                // Attraction along edges.
                foreach (var (a, b) in edges)
                {
                    Vector2 delta = pos[a] - pos[b];
                    float d = delta.magnitude;
                    if (d < eps) d = eps;
                    Vector2 dir = delta / d;
                    float force = (d * d) / k;
                    disp[a] -= dir * force;
                    disp[b] += dir * force;
                }

                // Limit each node's movement to the (cooling) temperature.
                for (int i = 0; i < n; i++)
                {
                    float d = disp[i].magnitude;
                    if (d > eps) pos[i] += (disp[i] / d) * Mathf.Min(d, temp);
                }
                temp = Mathf.Max(0f, temp - cool);
            }

            CenterAndAssign(ids, pos);
            return $"force-directed — {n} node{(n == 1 ? "" : "s")}, {edges.Count} edge{(edges.Count == 1 ? "" : "s")}";
        }

        /// <summary>True when the set's current positions occupy a real extent (so they're worth seeding from).</summary>
        private bool CurrentPositionsSpread(List<ElementId> ids, float spacing)
        {
            float minX = float.MaxValue, minY = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            int have = 0;
            foreach (var id in ids)
            {
                if (!_pos.TryGetValue(id, out var p)) continue;
                have++;
                if (p.x < minX) minX = p.x;
                if (p.x > maxX) maxX = p.x;
                if (p.y < minY) minY = p.y;
                if (p.y > maxY) maxY = p.y;
            }
            if (have < 2) return false;
            return (maxX - minX) + (maxY - minY) > spacing * 0.5f;
        }

        // --- 3) hierarchy (layered) ---

        /// <summary>
        /// Layered layout for class hierarchies: build a DAG from Generalization / Realization / Dependency /
        /// DirectedAssociation edges (from→to), break cycles by dropping back-edges found during a DFS, then assign
        /// each node a layer equal to its longest path from a source (Kahn topological order). Layers become
        /// horizontal rows (y by layer, deeper layers descend); within each row a couple of barycenter passes order
        /// nodes by the average column of their neighbors to reduce crossings. Falls back to the tidy grid when the
        /// set has no hierarchy relationships.
        /// </summary>
        private string LayoutHierarchy(List<ElementId> ids)
        {
            int n = ids.Count;
            var index = BuildLayoutIndex(ids);

            // Directed hierarchy edges over the set.
            var directed = new List<(int from, int to)>();
            foreach (var e in _model.Edges)
            {
                if (!IsHierarchyEdge(e.Kind)) continue;
                if (index.TryGetValue(e.From, out var a) && index.TryGetValue(e.To, out var b) && a != b)
                    directed.Add((a, b));
            }
            if (directed.Count == 0) return LayoutGrid(ids) + " (no hierarchy relationships)";

            // Break cycles: a DFS marks edges into a node still on the recursion stack as back-edges, which we ignore.
            var adj = new List<int>[n];
            for (int i = 0; i < n; i++) adj[i] = new List<int>();
            foreach (var (a, b) in directed) adj[a].Add(b);

            var color = new int[n]; // 0 = unvisited, 1 = on stack, 2 = done
            var backEdges = new HashSet<(int, int)>();
            void Dfs(int u)
            {
                color[u] = 1;
                foreach (var v in adj[u])
                {
                    if (color[v] == 1) backEdges.Add((u, v));
                    else if (color[v] == 0) Dfs(v);
                }
                color[u] = 2;
            }
            for (int i = 0; i < n; i++) if (color[i] == 0) Dfs(i);

            // Surviving DAG edges + indegree for Kahn longest-path layering.
            var dag = new List<(int a, int b)>();
            var outAdj = new List<int>[n];
            var nbr = new List<int>[n]; // undirected, for barycenter ordering
            for (int i = 0; i < n; i++) { outAdj[i] = new List<int>(); nbr[i] = new List<int>(); }
            var indeg = new int[n];
            foreach (var (a, b) in directed)
            {
                if (backEdges.Contains((a, b))) continue;
                dag.Add((a, b));
                outAdj[a].Add(b);
                indeg[b]++;
                nbr[a].Add(b);
                nbr[b].Add(a);
            }
            if (dag.Count == 0) return LayoutGrid(ids) + " (no hierarchy relationships)";

            var layer = new int[n];
            var queue = new Queue<int>();
            for (int i = 0; i < n; i++) if (indeg[i] == 0) queue.Enqueue(i);
            var remaining = (int[])indeg.Clone();
            while (queue.Count > 0)
            {
                int u = queue.Dequeue();
                foreach (var v in outAdj[u])
                {
                    if (layer[u] + 1 > layer[v]) layer[v] = layer[u] + 1;
                    if (--remaining[v] == 0) queue.Enqueue(v);
                }
            }

            int maxLayer = 0;
            for (int i = 0; i < n; i++) if (layer[i] > maxLayer) maxLayer = layer[i];
            if (maxLayer == 0) return LayoutGrid(ids) + " (no hierarchy relationships)";

            // Group into ordered rows, then reduce crossings with a few stable barycenter passes.
            var order = new List<int>[maxLayer + 1];
            for (int l = 0; l <= maxLayer; l++) order[l] = new List<int>();
            for (int i = 0; i < n; i++) order[layer[i]].Add(i);

            var col = new float[n];
            void Recolumn() { for (int l = 0; l <= maxLayer; l++) for (int j = 0; j < order[l].Count; j++) col[order[l][j]] = j; }
            Recolumn();

            float Bary(int node)
            {
                var ns = nbr[node];
                if (ns.Count == 0) return col[node];
                float sum = 0f;
                foreach (var m in ns) sum += col[m];
                return sum / ns.Count;
            }

            for (int pass = 0; pass < 2; pass++)
            {
                for (int l = 0; l <= maxLayer; l++)
                {
                    order[l] = order[l].OrderBy(Bary).ToList(); // OrderBy is stable → deterministic
                    for (int j = 0; j < order[l].Count; j++) col[order[l][j]] = j;
                }
            }

            // Place: layer 0 at the top (y = 0), deeper layers descend; each row centered horizontally.
            LayoutCellSize(ids, LayoutMarginPx, out float cellW, out float cellH);
            var p = new Vector2[n];
            for (int l = 0; l <= maxLayer; l++)
            {
                var row = order[l];
                int m = row.Count;
                float startX = -((m - 1) * cellW) * 0.5f;
                float y = -l * cellH;
                for (int j = 0; j < m; j++) p[row[j]] = new Vector2(startX + j * cellW, y);
            }
            CenterAndAssign(ids, p);
            return $"hierarchy — {n} node{(n == 1 ? "" : "s")} across {maxLayer + 1} layers";
        }

        /// <summary>Edge kinds that imply a layered direction (from→to) for the hierarchy layout.</summary>
        private static bool IsHierarchyEdge(EdgeKind k) =>
            k == EdgeKind.Generalization || k == EdgeKind.Realization
            || k == EdgeKind.Dependency || k == EdgeKind.DirectedAssociation;

        // --- 4) by source / package (cluster) ---

        /// <summary>
        /// Cluster layout: bucket nodes by <see cref="ModelElement.SourceFile"/> (fallback: the namespace prefix of
        /// the name before its last '.', else a single bucket), lay each bucket as its own sub-grid block, and arrange
        /// the blocks in a padded meta-grid so files / packages read as distinct clusters. The best default after a
        /// codebase import.
        /// </summary>
        private string LayoutBySource(List<ElementId> ids)
        {
            int n = ids.Count;
            var index = BuildLayoutIndex(ids);

            var buckets = new Dictionary<string, List<ElementId>>();
            foreach (var id in ids)
            {
                string key = BucketKey(id);
                if (!buckets.TryGetValue(key, out var list)) { list = new List<ElementId>(); buckets[key] = list; }
                list.Add(id);
            }

            var keys = buckets.Keys.ToList();
            keys.Sort(StringComparer.Ordinal); // deterministic block order
            int B = keys.Count;

            LayoutCellSize(ids, LayoutMarginPx, out float cellW, out float cellH);

            // Per-bucket sub-grid dimensions.
            var blockCols = new int[B];
            var blockW = new float[B];
            var blockH = new float[B];
            for (int b = 0; b < B; b++)
            {
                int count = buckets[keys[b]].Count;
                int cols = CeilSqrt(count);
                int rows = Mathf.CeilToInt(count / (float)cols);
                blockCols[b] = cols;
                blockW[b] = cols * cellW;
                blockH[b] = rows * cellH;
            }

            // Arrange the blocks in a meta-grid; meta-column widths / meta-row heights take the max block in each.
            int metaCols = CeilSqrt(B);
            int metaRows = Mathf.CeilToInt(B / (float)metaCols);
            const float blockPad = 120f;
            var colW = new float[metaCols];
            var rowH = new float[metaRows];
            for (int b = 0; b < B; b++)
            {
                int mc = b % metaCols, mr = b / metaCols;
                if (blockW[b] > colW[mc]) colW[mc] = blockW[b];
                if (blockH[b] > rowH[mr]) rowH[mr] = blockH[b];
            }
            var colX = new float[metaCols];
            for (int c = 1; c < metaCols; c++) colX[c] = colX[c - 1] + colW[c - 1] + blockPad;
            var rowY = new float[metaRows];
            for (int r = 1; r < metaRows; r++) rowY[r] = rowY[r - 1] + rowH[r - 1] + blockPad;

            var p = new Vector2[n];
            for (int b = 0; b < B; b++)
            {
                int mc = b % metaCols, mr = b / metaCols;
                float bx = colX[mc];
                float by = rowY[mr]; // y-down within this scratch space; flipped below
                var list = buckets[keys[b]];
                int cols = blockCols[b];
                for (int k = 0; k < list.Count; k++)
                {
                    int r = k / cols, c = k % cols;
                    p[index[list[k]]] = new Vector2(bx + c * cellW, -(by + r * cellH));
                }
            }
            CenterAndAssign(ids, p);
            return $"by source — {n} node{(n == 1 ? "" : "s")} in {B} cluster{(B == 1 ? "" : "s")}";
        }

        /// <summary>The cluster bucket for a node: its source file, else its name's namespace prefix, else one bucket.</summary>
        private string BucketKey(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return "(default)";
            if (!string.IsNullOrEmpty(el.SourceFile)) return el.SourceFile;
            string name = el.Name;
            if (!string.IsNullOrEmpty(name))
            {
                int dot = name.LastIndexOf('.');
                if (dot > 0) return name.Substring(0, dot);
            }
            return "(default)";
        }

        // --- 5) AI-assisted (LLM) ---

        /// <summary>One node's LLM-assigned cluster + normalized position (JsonUtility-serializable).</summary>
        [Serializable]
        private sealed class AiLayoutNode
        {
            public int index;
            public string cluster;
            public float x;
            public float y;
        }

        /// <summary>The LLM layout reply: a root object wrapping the per-node array (JsonUtility can't parse a bare array).</summary>
        [Serializable]
        private sealed class AiLayoutResponse
        {
            public AiLayoutNode[] nodes;
        }

        /// <summary>
        /// Ask the configured LLM to cluster + position the current set, then apply its normalized coordinates. With
        /// no LLM configured (or on any request / parse failure) this falls back to the force-directed layout.
        /// </summary>
        public void AutoLayoutAI()
        {
            CloseMenu();
            if (!_activePackage.IsValid) { Flash("no package to lay out"); return; }
            var ids = CollectLayoutSet();
            if (ids.Count == 0) { Flash("nothing to lay out"); return; }

            if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
            {
                AutoLayout("force");
                Flash("LLM not configured — used force-directed");
                return;
            }

            Flash("AI layout — asking the LLM…");
            StartCoroutine(RunAiLayout(ids));
        }

        private IEnumerator RunAiLayout(List<ElementId> ids)
        {
            int n = ids.Count;
            var index = BuildLayoutIndex(ids);

            // Run the force-directed fallback (with its own rebuild/frame) and a custom flash explaining why.
            void FallbackForce(string why)
            {
                string note = LayoutForceDirected(ids);
                SetSelected(ElementId.None);
                _selectedEdge = EdgeId.None;
                RebuildFromModel();
                _scene.FrameAll();
                Flash(why + " — " + note);
            }

            // Compact prompt: an indexed node list + the relationships among the set.
            var sb = new StringBuilder();
            sb.Append("Nodes (index | name | kind | source):\n");
            for (int i = 0; i < n; i++)
            {
                _model.TryGet(ids[i], out var el);
                string src = (el != null && !string.IsNullOrEmpty(el.SourceFile)) ? Path.GetFileName(el.SourceFile) : "-";
                sb.Append(i).Append(" | ").Append(el?.Name ?? "?").Append(" | ")
                  .Append(el != null ? el.Kind.ToString() : "?").Append(" | ").Append(src).Append('\n');
            }
            sb.Append("\nRelationships (fromIndex -> toIndex | kind):\n");
            foreach (var e in _model.Edges)
            {
                if (index.TryGetValue(e.From, out var a) && index.TryGetValue(e.To, out var b) && a != b)
                    sb.Append(a).Append(" -> ").Append(b).Append(" | ").Append(e.Kind).Append('\n');
            }

            const string system =
                "You are a diagram layout engine. Given nodes and their relationships, assign every node a cluster " +
                "and a normalized position so connected nodes (and nodes sharing a source file) sit close together " +
                "while unrelated clusters are well separated. Return ONLY a JSON object, no prose or code fences, of " +
                "exactly this shape: {\"nodes\":[{\"index\":0,\"cluster\":\"a\",\"x\":0.12,\"y\":0.34}]}. " +
                "x and y are floats in [0,1]. Include every node index exactly once.";

            using (var req = LlmClient.BuildChatRequest(system, sb.ToString()))
            {
                req.timeout = 60;
                yield return req.SendWebRequest();

                if (req.result != UnityWebRequest.Result.Success) { FallbackForce("AI layout failed: " + req.error); yield break; }
                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                { FallbackForce("AI layout failed: " + apiError); yield break; }

                AiLayoutResponse resp = null;
                try { resp = JsonUtility.FromJson<AiLayoutResponse>(ExtractJsonObject(content)); }
                catch (Exception ex) { FallbackForce("AI layout: bad JSON (" + ex.Message + ")"); yield break; }

                if (resp == null || resp.nodes == null || resp.nodes.Length == 0)
                { FallbackForce("AI layout: empty/invalid JSON"); yield break; }

                // Normalized [0,1] → a world-px square sized by node count (y flipped so 0 = top). Uncovered nodes
                // keep their current position.
                float side = Mathf.Min(Mathf.Max(600f, n * 180f), 9000f);
                var p = new Vector2[n];
                for (int i = 0; i < n; i++) p[i] = _pos.TryGetValue(ids[i], out var cur) ? cur : Vector2.zero;
                int placed = 0;
                foreach (var node in resp.nodes)
                {
                    if (node == null || node.index < 0 || node.index >= n) continue;
                    float x = Mathf.Clamp01(node.x), y = Mathf.Clamp01(node.y);
                    p[node.index] = new Vector2((x - 0.5f) * side, (0.5f - y) * side);
                    placed++;
                }
                if (placed == 0) { FallbackForce("AI layout: no usable positions"); yield break; }

                CenterAndAssign(ids, p);
                SetSelected(ElementId.None);
                _selectedEdge = EdgeId.None;
                RebuildFromModel();
                _scene.FrameAll();
                Flash($"AI layout — placed {placed}/{n} node{(n == 1 ? "" : "s")}");
            }
        }

        /// <summary>Trim anything around the outermost JSON object (e.g. stray prose or ```json fences).</summary>
        private static string ExtractJsonObject(string s)
        {
            if (string.IsNullOrEmpty(s)) return s;
            int a = s.IndexOf('{');
            int b = s.LastIndexOf('}');
            return (a >= 0 && b > a) ? s.Substring(a, b - a + 1) : s;
        }
    }
}
