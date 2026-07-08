using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using UnityEngine;
using UnityEngine.Networking;
using TheRobotDraft.Authoring.Interchange;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The interchange seam (docs/specs/file-formats.md §7): the ONLY place the format-neutral Ix* IR maps onto
    /// <see cref="ElementKind"/> / <see cref="EdgeKind"/> / <see cref="UmlMemberSignature"/> and is driven into the
    /// canvas through the authoring verbs. Format readers/writers (PlantUML / XMI / Mermaid / EA .qea) never touch
    /// the model directly. This partial hosts two consumers of that IR:
    ///   • the image-import review flow (<see cref="IxCommitNode"/> / <see cref="CommitIxReview"/>), driven from
    ///     <c>UmlCanvas.ImageImport.cs</c>; and
    ///   • whole-file import/export (<see cref="MaterializeInterchange"/> / <see cref="BuildInterchangeModel"/>),
    ///     wired onto the canvas Generate menu.
    /// Both share the Ix↔kind mapping so the two paths agree on how a foreign type lands on the canvas.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // ================================================================== image-import review rows
        // (consumed by UmlCanvas.ImageImport.cs — do not rename without updating that file)

        /// <summary>One reviewable node row: the parsed element plus the user's (editable) final choices.</summary>
        internal sealed class IxCommitNode
        {
            public IxElement Source;
            public bool Include = true;
            public ElementKind Kind;
            public string Name;
            public string MembersText;   // one member signature per line (or `;`-separated)
            public string Notes;         // → CodeDoc
            public ElementId CreatedId;  // set during commit
        }

        /// <summary>One reviewable edge row.</summary>
        internal sealed class IxCommitEdge
        {
            public IxEdge Source;
            public bool Include = true;
            public EdgeKind Kind;
            public string FromId;        // IxElement.Id
            public string ToId;
            public string Label;
        }

        // ------------------------------------------------------------------ Ix → canvas kind mapping

        /// <summary>Default <see cref="ElementKind"/> for an interchange element type (frozen IR set).</summary>
        internal static ElementKind MapIxElement(IxElementType t)
        {
            switch (t)
            {
                case IxElementType.Package: return ElementKind.PackageNode;
                case IxElementType.Class: return ElementKind.Class;
                case IxElementType.Interface: return ElementKind.Interface;
                case IxElementType.Enum: return ElementKind.Enum;
                case IxElementType.Struct: return ElementKind.Struct;
                case IxElementType.DataType: return ElementKind.DataType;
                case IxElementType.Table: return ElementKind.EntityTable;
                case IxElementType.Note: return ElementKind.Note;
                case IxElementType.Artifact: return ElementKind.Artifact;
                case IxElementType.Boundary: return ElementKind.Boundary;
                case IxElementType.Actor: return ElementKind.Actor;
                case IxElementType.UseCase: return ElementKind.UseCase;
                case IxElementType.State: return ElementKind.State;
                case IxElementType.StateStart: return ElementKind.StateStart;
                case IxElementType.StateEnd: return ElementKind.StateEnd;
                case IxElementType.Activity: return ElementKind.Activity;
                case IxElementType.Decision: return ElementKind.Decision;
                case IxElementType.ForkJoin: return ElementKind.ForkJoin;
                case IxElementType.FlowFinal: return ElementKind.FlowFinal;
                case IxElementType.Component: return ElementKind.Component;
                case IxElementType.DeploymentNode: return ElementKind.DeploymentNode;
                case IxElementType.Database: return ElementKind.Database;
                case IxElementType.Cloud: return ElementKind.Cloud;
                case IxElementType.Lifeline: return ElementKind.Lifeline;
                case IxElementType.MindNode: return ElementKind.MindNode;
                default: return ElementKind.Class; // Unknown / unmapped → Class (stereotype preserves the original)
            }
        }

        /// <summary>Default <see cref="EdgeKind"/> for an interchange edge type (frozen IR set).</summary>
        internal static EdgeKind MapIxEdge(IxEdgeType t)
        {
            switch (t)
            {
                case IxEdgeType.Association: return EdgeKind.Association;
                case IxEdgeType.DirectedAssociation: return EdgeKind.DirectedAssociation;
                case IxEdgeType.Aggregation: return EdgeKind.Aggregation;
                case IxEdgeType.Composition: return EdgeKind.Composition;
                case IxEdgeType.Generalization: return EdgeKind.Generalization;
                case IxEdgeType.Realization: return EdgeKind.Realization;
                case IxEdgeType.Dependency: return EdgeKind.Dependency;
                case IxEdgeType.NoteLink: return EdgeKind.NoteLink;
                case IxEdgeType.Extension: return EdgeKind.Extension;
                case IxEdgeType.Include: return EdgeKind.Include;
                case IxEdgeType.Extend: return EdgeKind.Extend;
                case IxEdgeType.Transition: return EdgeKind.Transition;
                case IxEdgeType.MessageSync: return EdgeKind.MessageSync;
                case IxEdgeType.MessageAsync: return EdgeKind.MessageAsync;
                case IxEdgeType.MessageReply: return EdgeKind.MessageReply;
                default: return EdgeKind.Association;
            }
        }

        /// <summary>Render an <see cref="IxMember"/> as the on-canvas member signature convention.</summary>
        internal static string ComposeIxMember(IxMember m)
        {
            if (m == null) return null;
            if (!string.IsNullOrEmpty(m.RawText)) return m.RawText;
            var sb = new StringBuilder();
            switch (m.Visibility)
            {
                case IxVisibility.Private: sb.Append('-'); break;
                case IxVisibility.Protected: sb.Append('#'); break;
                case IxVisibility.Package: sb.Append('~'); break;
                default: sb.Append('+'); break;
            }
            sb.Append(m.Name);
            if (m.IsOperation)
            {
                sb.Append('(');
                for (int i = 0; i < m.Parameters.Count; i++)
                {
                    if (i > 0) sb.Append(", ");
                    sb.Append(m.Parameters[i].Name);
                    if (!string.IsNullOrEmpty(m.Parameters[i].Type)) sb.Append(" : ").Append(m.Parameters[i].Type);
                }
                sb.Append(')');
            }
            if (!string.IsNullOrEmpty(m.Type)) sb.Append(" : ").Append(m.Type);
            if (!string.IsNullOrEmpty(m.DefaultValue)) sb.Append(" = ").Append(m.DefaultValue);
            return sb.ToString();
        }

        /// <summary>Build editable review rows from a parsed interchange model.</summary>
        internal static void BuildIxReviewRows(IxModel ix, out List<IxCommitNode> nodes, out List<IxCommitEdge> edges)
        {
            nodes = new List<IxCommitNode>();
            edges = new List<IxCommitEdge>();
            if (ix == null) return;

            foreach (var el in ix.Elements)
            {
                if (el == null) continue;
                var membersSb = new StringBuilder();
                foreach (var lit in el.EnumLiterals)
                {
                    if (membersSb.Length > 0) membersSb.Append('\n');
                    membersSb.Append(lit);
                }
                foreach (var m in el.Members)
                {
                    string sig = ComposeIxMember(m);
                    if (string.IsNullOrWhiteSpace(sig)) continue;
                    if (membersSb.Length > 0) membersSb.Append('\n');
                    membersSb.Append(sig.Trim());
                }
                nodes.Add(new IxCommitNode
                {
                    Source = el,
                    Kind = MapIxElement(el.Type),
                    Name = string.IsNullOrWhiteSpace(el.Name) ? el.Id : el.Name.Trim(),
                    MembersText = membersSb.ToString(),
                    Notes = el.Documentation ?? "",
                });
            }
            foreach (var e in ix.Edges)
            {
                if (e == null) continue;
                edges.Add(new IxCommitEdge
                {
                    Source = e,
                    Kind = MapIxEdge(e.Type),
                    FromId = e.FromId,
                    ToId = e.ToId,
                    Label = e.Label ?? "",
                });
            }
        }

        /// <summary>
        /// Materialize the reviewed rows onto the active package through the authoring verbs (same path as the
        /// code / DB imports, so undo and persistence behave identically), then auto-layout by diagram family.
        /// Members split on newlines / ';' become Field (no parens) or Function (parens) children; notes land in
        /// CodeDoc; <paramref name="sourceTag"/> (e.g. <c>image://…</c>) stamps provenance on every created node.
        /// Returns a human summary for the canvas hint.
        /// </summary>
        internal string CommitIxReview(List<IxCommitNode> nodes, List<IxCommitEdge> edges,
            string family, string sourceTag)
        {
            if (nodes == null || nodes.Count == 0) return "nothing to import";
            if (!ImportEnsurePackage()) return "couldn't create a package to import into";

            var created = new Dictionary<string, ElementId>();   // IxElement.Id → canvas id
            const float colW = 260f, rowH = 210f, originX = -400f, originY = 190f;
            int gridIndex = 0, madeNodes = 0, madeEdges = 0, skippedEdges = 0;

            foreach (var row in nodes)
            {
                if (row == null || !row.Include || string.IsNullOrWhiteSpace(row.Name)) continue;

                _ctl.EnterAddNode(row.Kind);
                var id = _ctl.CommitAddNode(_activePackage, ImportUniqueName(row.Name.Trim()));
                if (!id.IsValid) { _ctl.EnterSelect(); continue; }
                row.CreatedId = id;

                if (!string.IsNullOrWhiteSpace(row.Source?.Stereotype))
                    _ctl.SetMeta(id, null, row.Source.Stereotype.Trim());
                if (!string.IsNullOrWhiteSpace(row.Notes))
                    _ctl.SetCodeDoc(id, row.Notes.Trim());
                if (!string.IsNullOrEmpty(sourceTag))
                    _ctl.SetSourceFile(id, sourceTag);

                // Members: one signature per line (';' also accepted) — parens ⇒ operation.
                if (!string.IsNullOrWhiteSpace(row.MembersText))
                {
                    foreach (var raw in row.MembersText.Split('\n', ';'))
                    {
                        string sig = raw.Trim();
                        if (sig.Length == 0) continue;
                        var memberKind = sig.Contains("(") ? ElementKind.Function : ElementKind.Field;
                        _ctl.EnterAddNode(memberKind);
                        _ctl.CommitAddNode(id, sig);
                    }
                }

                _ctl.EnterSelect();
                _pos[id] = new Vector2(originX + (gridIndex % 4) * colW, originY - (gridIndex / 4) * rowH);
                _ctl.SetZLayer(id, _activeLayer);
                if (row.Source != null && !created.ContainsKey(row.Source.Id)) created[row.Source.Id] = id;
                gridIndex++;
                madeNodes++;
            }

            if (edges != null)
            {
                foreach (var row in edges)
                {
                    if (row == null || !row.Include) continue;
                    ElementId fromId, toId;
                    if (!created.TryGetValue(row.FromId ?? "", out fromId)
                        || !created.TryGetValue(row.ToId ?? "", out toId)
                        || fromId == toId) { skippedEdges++; continue; }

                    _ctl.EnterConnect(CommitStyle.OneShot, row.Kind);
                    _ctl.BeginConnect(fromId);
                    var edge = _ctl.CommitConnect(toId);
                    if (!edge.IsValid) { skippedEdges++; continue; }
                    if (!string.IsNullOrWhiteSpace(row.Label)
                        || !string.IsNullOrEmpty(row.Source?.FromMultiplicity)
                        || !string.IsNullOrEmpty(row.Source?.ToMultiplicity))
                        _ctl.SetEdgeMeta(edge, row.Label,
                            row.Source != null ? row.Source.FromMultiplicity : null,
                            row.Source != null ? row.Source.ToMultiplicity : null);
                    madeEdges++;
                }
            }

            _ctl.EnterSelect();
            SetSelected(ElementId.None);
            switch (family)
            {
                case "sequence": AutoArrangeSequence(); break;
                case "state":
                case "activity":
                case "mindmap": AutoLayout("hierarchy"); break;
                default: AutoLayout("grid"); break;
            }

            string note = $"imported {madeNodes} node(s), {madeEdges} link(s) from image";
            if (skippedEdges > 0) note += $" ({skippedEdges} link(s) skipped — endpoint excluded or invalid)";
            Flash(note);
            return note;
        }

        // ================================================================== whole-file import flows

        /// <summary>Pick a PlantUML file, parse it to the IR, and materialize it onto the canvas.</summary>
        private void ImportPlantUml()
        {
            CloseMenu();
            string path = BrowseOpenInterchange("Import PlantUML", "puml,plantuml,pu,iuml");
            if (string.IsNullOrEmpty(path)) { Flash("import cancelled"); return; }
            try
            {
                if (!File.Exists(path)) { Flash("file not found: " + path); return; }
                MaterializeInterchange(PlantUmlReader.Parse(File.ReadAllText(path)), path);
            }
            catch (InterchangeException ex) { Flash("PlantUML import failed: " + ex.Message); }
            catch (IOException ex) { Flash("PlantUML import failed: " + ex.Message); }
        }

        /// <summary>Pick an XMI file, parse it to the IR, and materialize it onto the canvas.</summary>
        private void ImportXmi()
        {
            CloseMenu();
            string path = BrowseOpenInterchange("Import XMI", "xmi,xml");
            if (string.IsNullOrEmpty(path)) { Flash("import cancelled"); return; }
            try
            {
                if (!File.Exists(path)) { Flash("file not found: " + path); return; }
                MaterializeInterchange(XmiReader.Parse(File.ReadAllText(path)), path);
            }
            catch (InterchangeException ex) { Flash("XMI import failed: " + ex.Message); }
            catch (IOException ex) { Flash("XMI import failed: " + ex.Message); }
        }

        /// <summary>Pick a Mermaid file, parse it, materialize it, then optionally recover missed colors via the LLM.</summary>
        private void ImportMermaid()
        {
            CloseMenu();
            string path = BrowseOpenInterchange("Import Mermaid", "mmd,mermaid");
            if (string.IsNullOrEmpty(path)) { Flash("import cancelled"); return; }
            try
            {
                if (!File.Exists(path)) { Flash("file not found: " + path); return; }
                string text = File.ReadAllText(path);
                MaterializeInterchange(MermaidReader.Parse(text), path);
                MaybeOfferMermaidStyleAssist(text); // enrichment only — import already succeeded above
            }
            catch (InterchangeException ex) { Flash("Mermaid import failed: " + ex.Message); }
            catch (IOException ex) { Flash("Mermaid import failed: " + ex.Message); }
        }

        /// <summary>Pick an EA <c>.qea</c> project (a SQLite file), read it to the IR, and materialize it.</summary>
        private void ImportQea()
        {
            CloseMenu();
            string path = BrowseOpenInterchange("Import EA project (.qea)", "qea");
            if (string.IsNullOrEmpty(path)) { Flash("import cancelled"); return; }
            try
            {
                if (!File.Exists(path)) { Flash("file not found: " + path); return; }
                MaterializeInterchange(EaQeaReader.Read(path), path); // binary SQLite — the reader opens the path
            }
            catch (InterchangeException ex) { Flash("EA import failed: " + ex.Message); }
            catch (IOException ex) { Flash("EA import failed: " + ex.Message); }
        }

        // ------------------------------------------------------------------ materialize IR → canvas

        /// <summary>Kind for a whole-file import — like <see cref="MapIxElement"/> but a package is a real container
        /// (a tab), not a diagram folder-node, so <c>RebuildFromModel</c> can draw its children.</summary>
        private static ElementKind ImportKindFor(IxElementType t) =>
            t == IxElementType.Package ? ElementKind.Package : MapIxElement(t);

        /// <summary>
        /// Rebuild the canvas from an <see cref="IxModel"/> the way <c>ApplyDto</c> rebuilds from a saved DTO: reset
        /// the world, mint elements parent-before-child (mapping IR ids → fresh ids), add members / enum literals as
        /// compartment children, apply per-node colors, connect edges, and place nodes from the first authored
        /// diagram (falling back to <c>AutoLayout("source")</c> when the IR carries no authored geometry). Not undoable.
        /// </summary>
        private void MaterializeInterchange(IxModel model, string sourcePath)
        {
            if (model == null || model.Elements == null || model.Elements.Count == 0)
            { Flash("nothing to import from " + Path.GetFileName(sourcePath)); return; }

            NewWorld(); // fresh model + empty history + cleared geometry, like ApplyDto

            // A non-member element with no resolvable parent needs a package home — the canvas only draws direct
            // children of the active package (see RebuildFromModel). Detect those "root orphans" (empty or dangling
            // ParentId, non-package) and, if any, mint one wrapper package for them. Real root packages stay tabs.
            var presentIds = new HashSet<string>(StringComparer.Ordinal);
            foreach (var probe in model.Elements)
                if (probe != null && !string.IsNullOrEmpty(probe.Id)) presentIds.Add(probe.Id);
            bool hasRootPackage = false, hasRootOrphan = false;
            foreach (var probe in model.Elements)
            {
                if (probe == null) continue;
                bool rootish = string.IsNullOrEmpty(probe.ParentId) || !presentIds.Contains(probe.ParentId);
                if (!rootish) continue;
                if (probe.Type == IxElementType.Package) hasRootPackage = true;
                else hasRootOrphan = true;
            }
            ElementId fallbackPackage = ElementId.None;
            if (hasRootOrphan)
            {
                _ctl.EnterAddNode(ElementKind.Package);
                string pkgName = (hasRootPackage || string.IsNullOrWhiteSpace(model.Name)) ? "Imported" : model.Name.Trim();
                fallbackPackage = _ctl.CommitAddNode(ElementId.None, pkgName);
            }

            // Mint elements parent-before-child, mapping IR ids → freshly minted element ids.
            var idMap = new Dictionary<string, ElementId>(StringComparer.Ordinal);
            int made = 0;
            foreach (var ix in OrderIxByDepth(model.Elements))
            {
                if (ix == null) continue;
                var kind = ImportKindFor(ix.Type);

                ElementId parent = ElementId.None;
                if (!string.IsNullOrEmpty(ix.ParentId) && idMap.TryGetValue(ix.ParentId, out var mapped)) parent = mapped;
                else if (kind != ElementKind.Package && fallbackPackage.IsValid) parent = fallbackPackage;

                _ctl.EnterAddNode(kind);
                var nid = _ctl.CommitAddNode(parent, string.IsNullOrEmpty(ix.Name) ? ix.Type.ToString() : ix.Name);
                if (!nid.IsValid) { _ctl.EnterSelect(); continue; }
                if (!string.IsNullOrEmpty(ix.Id)) idMap[ix.Id] = nid;
                made++;

                if (ix.IsAbstract) _ctl.SetAbstract(nid, true);
                if (!string.IsNullOrEmpty(ix.Stereotype)) _ctl.SetMeta(nid, null, ix.Stereotype);
                if (!string.IsNullOrEmpty(ix.Documentation)) _ctl.SetDescription(nid, ix.Documentation);
                if (!string.IsNullOrEmpty(ix.ExternalUuid)) _ctl.SetDeepLink(nid, ix.ExternalUuid, null);
                ApplyColorsToNode(nid, ix.FillColor, ix.LineColor, ix.TextColor);

                AddIxMembers(nid, ix);

                if (KindInfo.IsDiagramNode(kind)) _ctl.SetZLayer(nid, _activeLayer);
            }
            _ctl.EnterSelect();

            // Edges — resolve both endpoints, then connect (validity-checked; an invalid pairing is skipped).
            int edgesMade = 0;
            if (model.Edges != null)
                foreach (var ix in model.Edges)
                {
                    if (ix == null || string.IsNullOrEmpty(ix.FromId) || string.IsNullOrEmpty(ix.ToId)) continue;
                    if (!idMap.TryGetValue(ix.FromId, out var from) || !idMap.TryGetValue(ix.ToId, out var to)) continue;

                    _ctl.EnterConnect(CommitStyle.OneShot, MapIxEdge(ix.Type));
                    _ctl.BeginConnect(from);
                    var edge = _ctl.CommitConnect(to);
                    if (!edge.IsValid) continue;
                    edgesMade++;
                    if (!string.IsNullOrEmpty(ix.Label) || !string.IsNullOrEmpty(ix.FromMultiplicity)
                        || !string.IsNullOrEmpty(ix.ToMultiplicity))
                        _ctl.SetEdgeMeta(edge, ix.Label, ix.FromMultiplicity, ix.ToMultiplicity);
                }
            _ctl.EnterSelect();

            // Geometry — apply the first authored diagram's placements (IR is top-left, Y-down; the canvas stores a
            // node's centre with Y-up, so add half-extents and flip Y). No authored geometry ⇒ lay out by source.
            IxDiagram authored = null;
            if (model.Diagrams != null)
                foreach (var d in model.Diagrams)
                    if (d != null && d.LayoutProvenance == IxLayoutProvenance.Authored) { authored = d; break; }

            int placed = 0;
            if (authored != null && authored.Nodes != null)
                foreach (var pl in authored.Nodes)
                {
                    if (pl == null || string.IsNullOrEmpty(pl.ElementId)) continue;
                    if (!idMap.TryGetValue(pl.ElementId, out var nid)) continue;
                    if (pl.Width > 0f && pl.Height > 0f)
                    {
                        _pos[nid] = new Vector2(pl.X + pl.Width * 0.5f, -(pl.Y + pl.Height * 0.5f));
                        _size[nid] = new Vector2(pl.Width, pl.Height);
                    }
                    else
                    {
                        _pos[nid] = new Vector2(pl.X, -pl.Y);
                    }
                    placed++;
                }

            _selectedId = ElementId.None;
            _selectedEdge = EdgeId.None;
            _ctl.ClearHistory();  // an import is a load, not an undoable edit
            RebuildFromModel();   // build tabs + nodes; EnsureActivePackage runs here so a tab is always active
            if (placed == 0) AutoLayout("source"); // no authored geometry — arrange by source, like DB / code import

            Flash($"imported {made} element(s), {edgesMade} edge(s) from {Path.GetFileName(sourcePath)}");
        }

        /// <summary>
        /// Add an element's IR members as compartment children: enum literals become bare-name Field children (the
        /// form the enum renderer and code import both use); other members keep their original text when the reader
        /// preserved it, else compose to the canonical Rose/Sparx signature so they parse back losslessly on export.
        /// </summary>
        private void AddIxMembers(ElementId owner, IxElement ix)
        {
            if (ix.Type == IxElementType.Enum && ix.EnumLiterals != null)
                foreach (var literal in ix.EnumLiterals)
                {
                    if (string.IsNullOrWhiteSpace(literal)) continue;
                    _ctl.EnterAddNode(ElementKind.Field);
                    _ctl.CommitAddNode(owner, literal.Trim());
                }

            if (ix.Members == null) return;
            foreach (var m in ix.Members)
            {
                if (m == null || string.IsNullOrWhiteSpace(m.Name)) continue;
                var memberKind = m.IsOperation ? ElementKind.Function : ElementKind.Field;
                string sig;
                if (!string.IsNullOrEmpty(m.RawText))
                {
                    sig = m.RawText.Trim(); // reader kept the original source text — lossless
                }
                else
                {
                    var parts = new MemberParts
                    {
                        Visibility = MapVisibility(m.Visibility),
                        Name = m.Name.Trim(),
                        Type = m.Type,
                        Parameters = m.IsOperation ? ComposeIxParams(m.Parameters) : "",
                        DefaultValue = m.IsOperation ? "" : m.DefaultValue,
                        IsStatic = m.IsStatic,
                        IsAbstract = m.IsAbstract,
                    };
                    sig = UmlMemberSignature.Compose(memberKind, parts);
                }
                _ctl.EnterAddNode(memberKind);
                var mid = _ctl.CommitAddNode(owner, sig);
                if (mid.IsValid && !string.IsNullOrWhiteSpace(m.ExternalUuid))
                    _ctl.SetDeepLink(mid, m.ExternalUuid, null);
            }
        }

        // ================================================================== whole-file export flows

        /// <summary>Emit PlantUML from the whole canvas and show it in the shared code viewer with a save button.</summary>
        private void ExportPlantUml() => ExportText("PlantUML", "plantuml", "puml", PlantUmlWriter.Write, false);

        /// <summary>Emit XMI from the whole canvas.</summary>
        private void ExportXmi() => ExportText("XMI", "xml", "xmi", XmiWriter.Write, false);

        /// <summary>Emit Mermaid from the whole canvas.</summary>
        private void ExportMermaid() => ExportText("Mermaid", "mermaid", "mmd", MermaidWriter.Write, false);

        private void ExportSelectionPlantUml() => ExportText("PlantUML", "plantuml", "puml", PlantUmlWriter.Write, true);
        private void ExportSelectionXmi() => ExportText("XMI", "xml", "xmi", XmiWriter.Write, true);
        private void ExportSelectionMermaid() => ExportText("Mermaid", "mermaid", "mmd", MermaidWriter.Write, true);

        /// <summary>Shared text-format export: build the IR (whole model or just the selection), write it, and show
        /// it in the shared code viewer with a save-to-file button (mirrors GenerateLiquibaseChangelog).</summary>
        private void ExportText(string label, string language, string extNoDot,
            Func<IxModel, string> writer, bool selectionOnly)
        {
            CloseMenu();
            if (selectionOnly && _selection.Count == 0) { Flash("select elements to export"); return; }
            try
            {
                string name = InterchangeDiagramName();
                string title = (selectionOnly ? "Export selection → " : "Export ") + label + "   —   " + name;
                string status = selectionOnly
                    ? _selection.Count + " selected element(s) — copy or save"
                    : label + " source — copy or save";
                string text = writer(BuildInterchangeModel(selectionOnly));
                ShowCodeViewer(title, text, status, ElementId.None, null, language: language,
                    onSaveToFile: t => SaveInterchangeToFile(t, "Save " + label, name + "." + extNoDot, extNoDot),
                    saveToFileLabel: "Save ." + extNoDot + "…");
            }
            catch (InterchangeException ex) { Flash(label + " export failed: " + ex.Message); }
        }

        /// <summary>
        /// Write the whole canvas to an EA <c>.qea</c> project by cloning the bundled StreamingAssets template and
        /// populating it. The writer owns the SQLite work; here we pick the output path and check the template.
        /// (No selection-only variant — a .qea is a whole project, not a diagram fragment.)
        /// </summary>
        private void ExportQea()
        {
            CloseMenu();
            string name = InterchangeDiagramName();
            string outPath = BrowseSaveInterchange("Save EA project (.qea)", name + ".qea", "qea");
            if (string.IsNullOrEmpty(outPath)) { Flash("export cancelled"); return; }

            string templatePath = Path.Combine(Application.streamingAssetsPath, "Interchange/ea-template.qea");
            if (!File.Exists(templatePath))
            {
                Flash("EA template missing — add ea-template.qea under StreamingAssets/Interchange (" + templatePath + ")");
                return;
            }

            try
            {
                EaQeaWriter.Write(BuildInterchangeModel(false), templatePath, outPath);
                Flash("exported EA project → " + outPath);
            }
            catch (InterchangeException ex) { Flash("EA export failed: " + ex.Message); }
            catch (IOException ex) { Flash("EA export failed: " + ex.Message); }
        }

        /// <summary>Render the current scene view to a PNG file. Selection-bounds cropping is deferred (3-D nodes have
        /// no flat screen rect), so this captures the whole framed diagram — same idiom as <c>CopySelectionAsPng</c>.</summary>
        private void ExportSelectionPng()
        {
            CloseMenu();
            if (_selection.Count == 0) { Flash("select elements to export as PNG"); return; }
            string name = InterchangeDiagramName();
            string path = BrowseSaveInterchange("Export selection as PNG", name + ".png", "png");
            if (string.IsNullOrEmpty(path)) { Flash("export cancelled"); return; }
            StartCoroutine(CaptureSceneToPngFile(path));
        }

        // TODO(interchange): crop the PNG to the selection's bounding rect. Deferred because the diagram renders in
        // 3-D and selected nodes have no flat screen rect to frame (mirrors the CopySelectionAsPng limitation).
        private IEnumerator CaptureSceneToPngFile(string path)
        {
            yield return new WaitForEndOfFrame(); // capture after the frame is fully drawn (menu already closed)

            var cam = _scene != null ? _scene.Camera : null;
            if (cam == null) { Flash("no scene camera to capture"); yield break; }

            int w = Mathf.Max(1, Screen.width), h = Mathf.Max(1, Screen.height);
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32);
            var prevTarget = cam.targetTexture;
            var prevActive = RenderTexture.active;
            cam.targetTexture = rt;
            cam.Render();

            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0f, 0f, w, h), 0, 0);
            tex.Apply();

            cam.targetTexture = prevTarget;
            RenderTexture.active = prevActive;

            byte[] png = tex.EncodeToPNG();
            Destroy(tex);
            rt.Release();
            Destroy(rt);

            try { File.WriteAllBytes(path, png); Flash("exported PNG → " + path); }
            catch (Exception ex) { Flash("PNG export failed: " + ex.Message); }
        }

        // ------------------------------------------------------------------ canvas → IR

        /// <summary>
        /// Build the format-neutral IR from the canvas. When <paramref name="selectionOnly"/> the model is limited to
        /// the selected elements plus their member children and ancestor package chain, and only edges whose BOTH
        /// endpoints are included. Non-member elements become <see cref="IxElement"/>s (Field/Function children →
        /// <see cref="IxMember"/>s; an enum's Field children → literals; per-node style → color fields), and the
        /// current node geometry is captured as one authored <see cref="IxDiagram"/> (inverse of the import mapping).
        /// </summary>
        private IxModel BuildInterchangeModel(bool selectionOnly = false)
        {
            HashSet<ElementId> included = selectionOnly ? ComputeSelectionClosure() : null;

            string diagramName = InterchangeDiagramName();
            var model = new IxModel { Name = diagramName };
            var byId = new Dictionary<string, IxElement>(StringComparer.Ordinal);

            // Pass 1: non-member elements → IxElements (with members / enum literals / colors).
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind)) continue;
                if (included != null && !included.Contains(el.Id)) continue;

                var type = IxTypeFromKind(el.Kind, out var mapped);
                string stereotype = el.Stereotype;
                if (!mapped && string.IsNullOrEmpty(stereotype)) stereotype = el.Kind.ToString(); // keep a breadcrumb

                var ix = new IxElement
                {
                    Id = el.Id.Value,
                    ExternalUuid = el.DeepLinkUuid,
                    Type = type,
                    Name = el.Name,
                    Stereotype = stereotype,
                    IsAbstract = el.IsAbstract,
                    Documentation = el.Description,
                };
                if (_styles.TryGetValue(el.Id, out var st) && st.Has)
                {
                    // Only emit colors the node actually carries — never invent them for an unstyled node.
                    ix.FillColor = "#" + ColorUtility.ToHtmlStringRGB(st.Fill);
                    ix.LineColor = "#" + ColorUtility.ToHtmlStringRGB(st.Border);
                    ix.TextColor = "#" + ColorUtility.ToHtmlStringRGB(st.Text);
                }
                BuildIxMembers(el, ix, included);
                model.Elements.Add(ix);
                if (!string.IsNullOrEmpty(el.Id.Value)) byId[el.Id.Value] = ix;
            }

            // Pass 2: containment, once every included element has an IxElement to point at.
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind) || !el.Parent.IsValid) continue;
                if (byId.TryGetValue(el.Id.Value, out var ix) && byId.ContainsKey(el.Parent.Value))
                    ix.ParentId = el.Parent.Value;
            }

            // Edges — element ids double as IR ids; keep only those with BOTH endpoints included.
            foreach (var e in _model.Edges)
            {
                if (!byId.ContainsKey(e.From.Value) || !byId.ContainsKey(e.To.Value)) continue;
                model.Edges.Add(new IxEdge
                {
                    Id = e.Id.Value,
                    Type = IxEdgeTypeFromKind(e.Kind),
                    FromId = e.From.Value,
                    ToId = e.To.Value,
                    Label = e.Label,
                    FromMultiplicity = e.SourceMultiplicity,
                    ToMultiplicity = e.TargetMultiplicity,
                });
            }

            // Geometry — one authored diagram; centre (Y-up) back to top-left (Y-down) with half-extents.
            var diagram = new IxDiagram { Id = "d1", Name = diagramName, LayoutProvenance = IxLayoutProvenance.Authored };
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind) || !byId.ContainsKey(el.Id.Value)) continue;
                if (!_pos.TryGetValue(el.Id, out var centre)) continue;
                float w = 0f, h = 0f;
                if (_size.TryGetValue(el.Id, out var s)) { w = s.x; h = s.y; }

                var placement = new IxNodePlacement { ElementId = el.Id.Value };
                if (w > 0f && h > 0f)
                {
                    placement.X = centre.x - w * 0.5f;
                    placement.Y = -centre.y - h * 0.5f;
                    placement.Width = w;
                    placement.Height = h;
                }
                else
                {
                    placement.X = centre.x;
                    placement.Y = -centre.y;
                }
                diagram.Nodes.Add(placement);
            }
            model.Diagrams.Add(diagram);

            return model;
        }

        /// <summary>Selected elements + their member children + their ancestor package chain (the export closure).</summary>
        private HashSet<ElementId> ComputeSelectionClosure()
        {
            var inc = new HashSet<ElementId>();
            foreach (var id in _selection)
            {
                if (!_model.TryGet(id, out var el)) continue;
                inc.Add(id);
                foreach (var childId in el.ChildIds)
                    if (_model.TryGet(childId, out var c) && KindInfo.IsMember(c.Kind)) inc.Add(childId);
                var p = el.Parent;
                int guard = 0;
                while (p.IsValid && _model.TryGet(p, out var pe))
                {
                    inc.Add(p);
                    p = pe.Parent;
                    if (++guard > 100000) break;
                }
            }
            return inc;
        }

        /// <summary>Emit an element's Field/Function children as IR members (an enum's Field children as literals).
        /// When <paramref name="included"/> is set, only children in that set are emitted (selection export).</summary>
        private void BuildIxMembers(ModelElement el, IxElement ix, HashSet<ElementId> included)
        {
            bool isEnum = el.Kind == ElementKind.Enum;
            foreach (var childId in el.ChildIds)
            {
                if (included != null && !included.Contains(childId)) continue;
                if (!_model.TryGet(childId, out var c)) continue;
                if (c.Kind == ElementKind.Field)
                {
                    var parts = UmlMemberSignature.Parse(ElementKind.Field, c.Name);
                    if (isEnum)
                    {
                        if (!string.IsNullOrWhiteSpace(parts.Name)) ix.EnumLiterals.Add(parts.Name);
                        continue;
                    }
                    ix.Members.Add(new IxMember
                    {
                        IsOperation = false,
                        Visibility = InvVisibility(parts.Visibility),
                        Name = parts.Name,
                        Type = parts.Type,
                        DefaultValue = parts.DefaultValue,
                        IsStatic = parts.IsStatic,
                        IsAbstract = parts.IsAbstract,
                        RawText = c.Name,
                        ExternalUuid = c.DeepLinkUuid,
                    });
                }
                else if (c.Kind == ElementKind.Function)
                {
                    var parts = UmlMemberSignature.Parse(ElementKind.Function, c.Name);
                    var m = new IxMember
                    {
                        IsOperation = true,
                        Visibility = InvVisibility(parts.Visibility),
                        Name = parts.Name,
                        Type = parts.Type, // return type
                        IsStatic = parts.IsStatic,
                        IsAbstract = parts.IsAbstract,
                        RawText = c.Name,
                        ExternalUuid = c.DeepLinkUuid,
                    };
                    ParseIxParams(parts.Parameters, m.Parameters);
                    ix.Members.Add(m);
                }
            }
        }

        /// <summary>Canvas kind → IR element type. <paramref name="mapped"/> is false for kinds with no IR equivalent.</summary>
        private static IxElementType IxTypeFromKind(ElementKind k, out bool mapped)
        {
            mapped = true;
            switch (k)
            {
                case ElementKind.Package:
                case ElementKind.PackageNode: return IxElementType.Package;
                case ElementKind.Class: return IxElementType.Class;
                case ElementKind.Interface: return IxElementType.Interface;
                case ElementKind.Enum: return IxElementType.Enum;
                case ElementKind.Struct: return IxElementType.Struct;
                case ElementKind.DataType: return IxElementType.DataType;
                case ElementKind.EntityTable: return IxElementType.Table;
                case ElementKind.Note: return IxElementType.Note;
                case ElementKind.Artifact: return IxElementType.Artifact;
                case ElementKind.Boundary: return IxElementType.Boundary;
                case ElementKind.Actor: return IxElementType.Actor;
                case ElementKind.UseCase: return IxElementType.UseCase;
                case ElementKind.State: return IxElementType.State;
                case ElementKind.StateStart: return IxElementType.StateStart;
                case ElementKind.StateEnd: return IxElementType.StateEnd;
                case ElementKind.Activity: return IxElementType.Activity;
                case ElementKind.Decision: return IxElementType.Decision;
                case ElementKind.ForkJoin: return IxElementType.ForkJoin;
                case ElementKind.FlowFinal: return IxElementType.FlowFinal;
                case ElementKind.Component: return IxElementType.Component;
                case ElementKind.DeploymentNode: return IxElementType.DeploymentNode;
                case ElementKind.Database: return IxElementType.Database;
                case ElementKind.Cloud: return IxElementType.Cloud;
                case ElementKind.Lifeline: return IxElementType.Lifeline;
                case ElementKind.MindNode: return IxElementType.MindNode;
                default: mapped = false; return IxElementType.Unknown;
            }
        }

        /// <summary>Canvas edge kind → IR edge type. Behavioral / message / exotic kinds collapse to the nearest IR relation.</summary>
        private static IxEdgeType IxEdgeTypeFromKind(EdgeKind k) => k switch
        {
            EdgeKind.Association => IxEdgeType.Association,
            EdgeKind.DirectedAssociation => IxEdgeType.DirectedAssociation,
            EdgeKind.Aggregation => IxEdgeType.Aggregation,
            EdgeKind.Composition => IxEdgeType.Composition,
            EdgeKind.Generalization => IxEdgeType.Generalization,
            EdgeKind.Realization => IxEdgeType.Realization,
            EdgeKind.Dependency => IxEdgeType.Dependency,
            EdgeKind.NoteLink => IxEdgeType.NoteLink,
            EdgeKind.Extension => IxEdgeType.Extension,
            EdgeKind.Include => IxEdgeType.Include,
            EdgeKind.Extend => IxEdgeType.Extend,
            EdgeKind.Transition => IxEdgeType.Transition,
            EdgeKind.MessageSync => IxEdgeType.MessageSync,
            EdgeKind.MessageAsync => IxEdgeType.MessageAsync,
            EdgeKind.MessageReply => IxEdgeType.MessageReply,
            EdgeKind.Consumes => IxEdgeType.Dependency,       // «consumes» usage has no distinct IR relation
            EdgeKind.SketchConnector => IxEdgeType.Association,
            _ => IxEdgeType.Unknown,                           // SysML / BPMN / DMN / Archi — no v1 IR equivalent
        };

        private static UmlVisibility MapVisibility(IxVisibility v) => v switch
        {
            IxVisibility.Private => UmlVisibility.Private,
            IxVisibility.Protected => UmlVisibility.Protected,
            IxVisibility.Package => UmlVisibility.Package,
            _ => UmlVisibility.Public,
        };

        private static IxVisibility InvVisibility(UmlVisibility v) => v switch
        {
            UmlVisibility.Private => IxVisibility.Private,
            UmlVisibility.Protected => IxVisibility.Protected,
            UmlVisibility.Package => IxVisibility.Package,
            _ => IxVisibility.Public,
        };

        // ------------------------------------------------------------------ per-node colors ↔ style store

        /// <summary>
        /// Apply source colors to a node's style entry. <see cref="NodeStyle"/> is an all-or-nothing override, so a
        /// partial color spec is completed with the tool's own defaults for the channels the source left out (via
        /// <see cref="NodeColors"/> + the kind hue) — that is the tool default, not an invented color. Returns true
        /// when at least one color was supplied.
        /// </summary>
        private bool ApplyColorsToNode(ElementId nid, string fillHex, string lineHex, string textHex)
        {
            if (string.IsNullOrEmpty(fillHex) && string.IsNullOrEmpty(lineHex) && string.IsNullOrEmpty(textHex))
                return false;
            if (!_model.TryGet(nid, out var el)) return false;

            NodeColors(el, out var fill, out var text);                     // tool default fill + text for this kind
            ColorUtility.TryParseHtmlString(KindInfo.Hue(el.Kind), out var border); // saturated kind hue = default border
            if (_styles.TryGetValue(nid, out var existing) && existing.Has)
            { fill = existing.Fill; border = existing.Border; text = existing.Text; } // start from any prior override

            if (TryParseHtmlColor(fillHex, out var f)) fill = f;
            if (TryParseHtmlColor(lineHex, out var l)) border = l;
            if (TryParseHtmlColor(textHex, out var t)) text = t;

            _styles[nid] = new NodeStyle { Has = true, Fill = fill, Border = border, Text = text };
            return true;
        }

        private static bool TryParseHtmlColor(string hex, out Color c)
        {
            c = default;
            if (string.IsNullOrWhiteSpace(hex)) return false;
            string s = hex.Trim();
            if (!s.StartsWith("#")) s = "#" + s;
            return ColorUtility.TryParseHtmlString(s, out c);
        }

        // ------------------------------------------------------------------ optional LLM style assist (Mermaid import)

        /// <summary>
        /// After a Mermaid import, if the source declared styling (classDef / style / :::class / cssClass) yet some
        /// elements ended up uncolored, kick off an OPTIONAL background LLM pass to recover their intended colors.
        /// Pure enrichment: the import has already succeeded, and deterministic colors are never overwritten.
        /// </summary>
        private void MaybeOfferMermaidStyleAssist(string rawMermaid)
        {
            if (string.IsNullOrEmpty(LlmSettings.BaseUrl)) return; // needs an endpoint
            if (!MermaidHasStyleHints(rawMermaid)) return;         // no style-ish lines → nothing to recover

            bool anyUncolored = false;
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind) || el.Kind == ElementKind.Package) continue;
                if (_styles.TryGetValue(el.Id, out var st) && st.Has) continue; // deterministic already colored it
                anyUncolored = true; break;
            }
            if (anyUncolored) StartCoroutine(RunMermaidStyleAssist(rawMermaid));
        }

        private static bool MermaidHasStyleHints(string src)
        {
            if (string.IsNullOrEmpty(src)) return false;
            return src.IndexOf("classDef", StringComparison.OrdinalIgnoreCase) >= 0
                || src.IndexOf(":::", StringComparison.Ordinal) >= 0
                || src.IndexOf("cssClass", StringComparison.OrdinalIgnoreCase) >= 0
                || src.IndexOf("\nstyle ", StringComparison.OrdinalIgnoreCase) >= 0
                || src.StartsWith("style ", StringComparison.OrdinalIgnoreCase);
        }

        private IEnumerator RunMermaidStyleAssist(string rawMermaid)
        {
            var names = new List<string>();
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind) || el.Kind == ElementKind.Package) continue;
                if (_styles.TryGetValue(el.Id, out var st) && st.Has) continue;
                if (!string.IsNullOrEmpty(el.Name)) names.Add(el.Name);
            }
            if (names.Count == 0) yield break;

            const string sys =
                "You are a diagram styling assistant. You are given Mermaid source and a list of element names whose " +
                "fill/line/text colors a deterministic parser could not resolve. Infer each element's colors ONLY from " +
                "explicit styling in the source (classDef, style, :::class, cssClass). Return ONLY strict JSON: an " +
                "object mapping element name to {\"fill\":\"#RRGGBB\",\"line\":\"#RRGGBB\",\"text\":\"#RRGGBB\"}. Omit " +
                "any element (or channel) you cannot determine from the source. No commentary, no markdown fences.";
            var user = new StringBuilder();
            user.Append("Mermaid source:\n").Append(rawMermaid).Append("\n\nElements needing colors:\n");
            foreach (var n in names) user.Append("- ").Append(n).Append('\n');

            using (var req = LlmClient.BuildChatRequest(sys, user.ToString()))
            {
                req.timeout = 60;
                yield return req.SendWebRequest();
                if (req.result != UnityWebRequest.Result.Success) { Flash("style assist skipped — LLM unreachable"); yield break; }
                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                { Flash("style assist skipped (" + apiError + ")"); yield break; }

                int applied = ApplyMermaidStyleJson(content);
                if (applied > 0) { RebuildFromModel(); Flash($"style assist colored {applied} more element(s)"); }
                else Flash("style assist found no extra colors");
            }
        }

        /// <summary>
        /// Defensively apply the LLM's <c>{name:{fill,line,text}}</c> JSON to still-uncolored elements: for each such
        /// element, locate its name key, slice its object, and pull any <c>#RRGGBB</c> values out. Unknown names and
        /// malformed entries are ignored; deterministic colors (elements that already have a style) are untouched.
        /// </summary>
        private int ApplyMermaidStyleJson(string json)
        {
            if (string.IsNullOrWhiteSpace(json)) return 0;
            int applied = 0;
            foreach (var el in _model.Elements)
            {
                if (KindInfo.IsMember(el.Kind) || el.Kind == ElementKind.Package) continue;
                if (_styles.TryGetValue(el.Id, out var st) && st.Has) continue; // deterministic wins
                if (string.IsNullOrEmpty(el.Name)) continue;

                int k = json.IndexOf("\"" + el.Name + "\"", StringComparison.Ordinal);
                if (k < 0) k = json.IndexOf("\"" + el.Name + "\"", StringComparison.OrdinalIgnoreCase);
                if (k < 0) continue;
                int open = json.IndexOf('{', k);
                if (open < 0) continue;
                int close = json.IndexOf('}', open + 1);
                if (close < 0) continue;
                string obj = json.Substring(open, close - open + 1);

                if (ApplyColorsToNode(el.Id, FindJsonHex(obj, "fill"), FindJsonHex(obj, "line"), FindJsonHex(obj, "text")))
                    applied++;
            }
            return applied;
        }

        private static string FindJsonHex(string obj, string key)
        {
            var m = Regex.Match(obj, "\"" + key + "\"\\s*:\\s*\"(#?[0-9A-Fa-f]{6})\"");
            return m.Success ? m.Groups[1].Value : null;
        }

        // ------------------------------------------------------------------ member-parameter (de)composition

        /// <summary>Compose IR operation parameters into the canonical "name : Type = default" list (skips a return param).</summary>
        private static string ComposeIxParams(List<IxParam> ps)
        {
            if (ps == null || ps.Count == 0) return "";
            var sb = new StringBuilder();
            bool first = true;
            foreach (var p in ps)
            {
                if (p == null) continue;
                if (!string.IsNullOrEmpty(p.Direction) && p.Direction.Equals("return", StringComparison.OrdinalIgnoreCase))
                    continue; // the return type rides on IxMember.Type, not the parameter list
                if (!first) sb.Append(", ");
                first = false;
                sb.Append(string.IsNullOrWhiteSpace(p.Name) ? "arg" : p.Name.Trim());
                if (!string.IsNullOrWhiteSpace(p.Type)) sb.Append(" : ").Append(p.Type.Trim());
                if (!string.IsNullOrWhiteSpace(p.DefaultValue)) sb.Append(" = ").Append(p.DefaultValue.Trim());
            }
            return sb.ToString();
        }

        /// <summary>Split a "name : Type = default" parameter list back into IR parameters (inverse of <see cref="ComposeIxParams"/>).</summary>
        private static void ParseIxParams(string parameters, List<IxParam> into)
        {
            if (string.IsNullOrWhiteSpace(parameters)) return;
            foreach (var raw in parameters.Split(','))
            {
                string part = raw.Trim();
                if (part.Length == 0) continue;
                string def = null;
                int eq = part.IndexOf('=');
                if (eq >= 0) { def = part.Substring(eq + 1).Trim(); part = part.Substring(0, eq).Trim(); }
                var p = new IxParam { Direction = "in", DefaultValue = def };
                int colon = part.IndexOf(':');
                if (colon >= 0)
                {
                    p.Name = part.Substring(0, colon).Trim();
                    p.Type = part.Substring(colon + 1).Trim();
                }
                else
                {
                    p.Name = part;
                }
                into.Add(p);
            }
        }

        // ------------------------------------------------------------------ helpers

        /// <summary>Order IR elements parent-before-child by containment depth (mirrors <c>OrderByDepth</c>).</summary>
        private static List<IxElement> OrderIxByDepth(List<IxElement> els)
        {
            var byId = new Dictionary<string, IxElement>(StringComparer.Ordinal);
            foreach (var e in els)
                if (e != null && !string.IsNullOrEmpty(e.Id)) byId[e.Id] = e;

            int Depth(IxElement e)
            {
                int d = 0, guard = 0;
                var cur = e;
                while (cur != null && !string.IsNullOrEmpty(cur.ParentId) && byId.TryGetValue(cur.ParentId, out var par))
                {
                    d++; cur = par;
                    if (++guard > 100000) break;
                }
                return d;
            }

            var list = new List<IxElement>(els);
            list.Sort((a, b) => Depth(a).CompareTo(Depth(b)));
            return list;
        }

        /// <summary>The current diagram's display name — the active package's name, else the open file's base name.</summary>
        private string InterchangeDiagramName()
        {
            if (_activePackage.IsValid && _model.TryGet(_activePackage, out var pkg)
                && !string.IsNullOrWhiteSpace(pkg.Name))
                return pkg.Name.Trim();
            string fromFile = Path.GetFileNameWithoutExtension(CurrentPath);
            return string.IsNullOrWhiteSpace(fromFile) ? "diagram" : fromFile;
        }

        /// <summary>Write exported text to a picked path, preserving the format's extension. Flashes the result.</summary>
        private void SaveInterchangeToFile(string text, string title, string defaultName, string ext)
        {
            string path = BrowseSaveInterchange(title, defaultName, ext);
            if (string.IsNullOrEmpty(path)) { Flash("save cancelled"); return; }
            try
            {
                File.WriteAllText(path, text ?? "");
                Flash("saved → " + path);
            }
            catch (Exception ex) { Flash("save failed: " + ex.Message); }
        }

        // Format-aware pickers. The shared BrowseForOpenFile / BrowseForSaveFile force a .json (or .yaml) extension,
        // so interchange gets its own that carries the right filter; the macOS-player branch reuses OsascriptPath.
        private static string BrowseOpenInterchange(string title, string extCsv)
        {
#if UNITY_EDITOR
            return UnityEditor.EditorUtility.OpenFilePanel(title, "", extCsv) ?? "";
#else
            if (Application.platform == RuntimePlatform.OSXPlayer)
                return OsascriptPath("POSIX path of (choose file with prompt \"" + title.Replace("\"", "") + "\")");
            return "";
#endif
        }

        private static string BrowseSaveInterchange(string title, string defaultName, string ext)
        {
#if UNITY_EDITOR
            string baseName = string.IsNullOrEmpty(defaultName) ? "diagram" : Path.GetFileNameWithoutExtension(defaultName);
            return UnityEditor.EditorUtility.SaveFilePanel(title, "", baseName, ext) ?? "";
#else
            if (Application.platform == RuntimePlatform.OSXPlayer)
            {
                string nm = (string.IsNullOrEmpty(defaultName) ? "diagram." + ext : defaultName).Replace("\"", "");
                return OsascriptPath("POSIX path of (choose file name with prompt \"" + title.Replace("\"", "") +
                    "\" default name \"" + nm + "\")");
            }
            return Path.Combine(Application.persistentDataPath, string.IsNullOrEmpty(defaultName) ? "diagram." + ext : defaultName);
#endif
        }
    }
}
