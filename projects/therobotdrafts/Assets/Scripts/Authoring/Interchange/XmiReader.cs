using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Imports UML 2.x class models serialized as XMI 2.x into the neutral <see cref="IxModel"/>
    /// (docs/formats/xmi-format.md). Deliberately lenient on read: accepts both the <c>xmi:XMI</c>
    /// wrapper and a bare <c>uml:Model</c> root, every namespace family seen in the wild
    /// (schema.omg.org, www.omg.org/20131001, Eclipse), and all three type-reference encodings
    /// (attribute <c>type=</c>, nested <c>&lt;type xmi:idref&gt;</c>, nested <c>&lt;type href&gt;</c>).
    /// Dispatch is namespace-agnostic — elements are matched on local name and <c>xmi:type</c> is
    /// compared on the local part after ':'. Cross-references resolve in a mandatory second pass
    /// because ids are routinely referenced before they are defined (§0). XMI 1.x is a structurally
    /// different serialization and is rejected with an actionable message (§7). Pure C# + BCL
    /// (System.Xml.Linq); no engine references.
    /// </summary>
    public static class XmiReader
    {
        public static IxModel Parse(string xml)
        {
            if (string.IsNullOrWhiteSpace(xml))
                throw new InterchangeException("XMI input is empty.");

            // The glue hands us an already-decoded string (EA often declares windows-1252). A stray
            // BOM in front of the XML declaration would make XDocument.Parse throw — drop it.
            if (xml[0] == (char)0xFEFF) xml = xml.Substring(1);

            XDocument doc;
            try { doc = XDocument.Parse(xml); }
            catch (Exception ex)
            {
                throw new InterchangeException("XMI is not well-formed XML: " + ex.Message, ex);
            }

            var root = doc.Root;
            if (root == null) throw new InterchangeException("XMI document has no root element.");

            if (IsXmi1x(root))
                throw new InterchangeException(
                    "This file is XMI 1.x (UML 1.x) — a different serialization than this importer supports. " +
                    "Re-export the model from your tool as \"UML 2.x (XMI 2.1)\".");

            var modelRoot = FindModelRoot(root);
            if (modelRoot == null)
                throw new InterchangeException("No <uml:Model> / <uml:Package> root found in the XMI document.");

            var ctx = new Ctx { Model = new IxModel { Name = Plain(modelRoot, "name") } };

            // Pass 1 — index everything that carries an id (so forward references resolve) and every
            // property (ownedAttribute/ownedEnd), so association ends can be found in whichever of the
            // two legal locations they live (§4.3).
            IndexTree(modelRoot, ctx);

            // Pass 2 — materialize elements + edges against the now-complete id index.
            foreach (var child in modelRoot.Elements())
                if (child.Name.LocalName == "packagedElement" || child.Name.LocalName == "nestedClassifier")
                    EmitPackagedElement(child, null, ctx);

            // Standard notes live anywhere as <ownedComment>; each becomes a Note + NoteLink edges.
            foreach (var c in modelRoot.Descendants().Where(e => e.Name.LocalName == "ownedComment"))
                EmitComment(c, ctx);

            // EA's proprietary extension is ignored for semantics; we mine it only for documentation
            // fallbacks and diagram geometry (§6) — the latter exists nowhere else.
            foreach (var ext in root.DescendantsAndSelf().Where(e => e.Name.LocalName == "Extension"))
                ReadExtension(ext, ctx);

            return ctx.Model;
        }

        // --- pass 1: id / property / type-target index --------------------------------------------

        private static void IndexTree(XElement el, Ctx ctx)
        {
            foreach (var child in el.Elements())
            {
                string ln = child.Name.LocalName;
                string id = XmiId(child);
                string tl = LocalType(child);

                if (id != null && !ctx.ElemsById.ContainsKey(id)) ctx.ElemsById[id] = child;

                // Classifiers (anything a member can be typed by) become type-resolution targets.
                if ((ln == "packagedElement" || ln == "nestedClassifier") && id != null && IsClassifierType(tl))
                    ctx.TypeName[id] = Plain(child, "name") ?? id;

                // Association ends: index by id and record the owning class for class-owned ends.
                if ((ln == "ownedAttribute" || ln == "ownedEnd") && id != null)
                {
                    ctx.PropsById[id] = child;
                    if (ln == "ownedAttribute")
                    {
                        string owner = XmiId(el);
                        if (owner != null) ctx.PropOwner[id] = owner;
                    }
                }

                IndexTree(child, ctx);
            }
        }

        // --- pass 2: element + edge materialization -----------------------------------------------

        private static void EmitPackagedElement(XElement pe, string parentId, Ctx ctx)
        {
            string tl = LocalType(pe) ?? "";
            switch (tl)
            {
                case "Package":
                {
                    string id = EmitElement(pe, parentId, IxElementType.Package, ctx).Id;
                    foreach (var child in pe.Elements())
                        if (child.Name.LocalName == "packagedElement" || child.Name.LocalName == "nestedClassifier")
                            EmitPackagedElement(child, id, ctx);
                    break;
                }
                case "Class":
                case "AssociationClass":
                    EmitClassifier(pe, parentId, IxElementType.Class, ctx);
                    break;
                case "Interface":
                    EmitClassifier(pe, parentId, IxElementType.Interface, ctx);
                    break;
                case "DataType":
                    EmitClassifier(pe, parentId, IxElementType.DataType, ctx);
                    break;
                // Real UML metaclasses our writer uses for non-class-model kinds; a trdKind marker in
                // the extension may still refine these (e.g. Component stays Component).
                case "Artifact":
                    EmitClassifier(pe, parentId, IxElementType.Artifact, ctx);
                    break;
                case "Actor":
                    EmitClassifier(pe, parentId, IxElementType.Actor, ctx);
                    break;
                case "UseCase":
                    EmitClassifier(pe, parentId, IxElementType.UseCase, ctx);
                    break;
                case "Component":
                    EmitClassifier(pe, parentId, IxElementType.Component, ctx);
                    break;
                case "PrimitiveType":
                    // Registered as a type target already; only surfaces as an element if it has members.
                    if (HasMembers(pe)) EmitClassifier(pe, parentId, IxElementType.DataType, ctx);
                    break;
                case "Enumeration":
                {
                    var el = EmitElement(pe, parentId, IxElementType.Enum, ctx);
                    foreach (var lit in Kids(pe, "ownedLiteral"))
                        el.EnumLiterals.Add(Plain(lit, "name") ?? Synth("Literal", ctx));
                    break;
                }
                case "Association":
                    AssembleAssociation(pe, ctx);
                    break;
                case "Dependency":
                case "Usage":
                case "Abstraction":
                    EmitDependency(pe, ctx);
                    break;
                default:
                    // Never drop an element we do not recognize — keep it as Unknown.
                    EmitElement(pe, parentId, IxElementType.Unknown, ctx);
                    break;
            }
        }

        private static IxElement EmitElement(XElement pe, string parentId, IxElementType type, Ctx ctx)
        {
            var el = new IxElement
            {
                Id = XmiIdOrSynth(pe, ctx),
                ExternalUuid = XmiId(pe),
                Type = type,
                Name = Plain(pe, "name") ?? Synth("Anonymous", ctx),
                ParentId = parentId,
                IsAbstract = Bool(Plain(pe, "isAbstract")),
            };
            ctx.Model.Elements.Add(el);
            return el;
        }

        private static void EmitClassifier(XElement pe, string parentId, IxElementType type, Ctx ctx)
        {
            var el = EmitElement(pe, parentId, type, ctx);
            string id = el.Id;

            foreach (var attr in Kids(pe, "ownedAttribute"))
            {
                // A property carrying an association back-pointer is an association end (§4.3), not a
                // plain field — it is consumed by AssembleAssociation, so do not emit it as a member.
                if (Plain(attr, "association") != null) continue;
                el.Members.Add(BuildField(attr, ctx));
            }

            foreach (var op in Kids(pe, "ownedOperation"))
                el.Members.Add(BuildOperation(op, ctx));

            foreach (var g in Kids(pe, "generalization"))
                EmitGeneralization(g, id, ctx);

            foreach (var r in Kids(pe, "interfaceRealization"))
                EmitRealization(r, id, ctx);

            // Nested classifiers (either spelling) chain their ParentId to this classifier.
            foreach (var child in pe.Elements())
                if (child.Name.LocalName == "nestedClassifier" || child.Name.LocalName == "packagedElement")
                    EmitPackagedElement(child, id, ctx);
        }

        private static IxMember BuildField(XElement attr, Ctx ctx)
        {
            var m = new IxMember
            {
                IsOperation = false,
                Name = Plain(attr, "name"),
                Visibility = Vis(Plain(attr, "visibility")),
                IsStatic = Bool(Plain(attr, "isStatic")),
                DefaultValue = DefaultVal(attr, ctx),
                ExternalUuid = XmiId(attr),
                Type = ResolveType(attr, ctx),
            };
            // Non-default multiplicity rides along as a "[lower..upper]" suffix on the type (§3.1).
            var (lo, hi) = Multiplicity(attr);
            if (!(lo == "1" && hi == "1"))
                m.Type = (m.Type ?? "") + "[" + lo + ".." + hi + "]";
            return m;
        }

        private static IxMember BuildOperation(XElement op, Ctx ctx)
        {
            var m = new IxMember
            {
                IsOperation = true,
                Name = Plain(op, "name"),
                Visibility = Vis(Plain(op, "visibility")),
                IsStatic = Bool(Plain(op, "isStatic")),
                IsAbstract = Bool(Plain(op, "isAbstract")),
                ExternalUuid = XmiId(op),
            };
            foreach (var p in Kids(op, "ownedParameter"))
            {
                string dir = Plain(p, "direction");
                if (dir == "return")
                {
                    m.Type = ResolveType(p, ctx); // untyped return => null == void
                }
                else
                {
                    m.Parameters.Add(new IxParam
                    {
                        Name = Plain(p, "name"),
                        Type = ResolveType(p, ctx),
                        Direction = dir,
                        DefaultValue = DefaultVal(p, ctx),
                    });
                }
            }
            return m;
        }

        private static void EmitGeneralization(XElement g, string childId, Ctx ctx)
        {
            string general = Plain(g, "general") ?? IdrefChild(g, "general");
            if (general == null) return;
            string specific = Plain(g, "specific");
            ctx.Model.Edges.Add(new IxEdge
            {
                Id = XmiIdOrSynth(g, ctx),
                ExternalUuid = XmiId(g),
                Type = IxEdgeType.Generalization,
                FromId = specific ?? childId,
                ToId = general,
            });
        }

        private static void EmitRealization(XElement r, string classId, Ctx ctx)
        {
            string iface = Plain(r, "contract") ?? Plain(r, "supplier")
                           ?? IdrefChild(r, "contract") ?? IdrefChild(r, "supplier");
            if (iface == null) return;
            string client = Plain(r, "client") ?? IdrefChild(r, "client") ?? classId;
            ctx.Model.Edges.Add(new IxEdge
            {
                Id = XmiIdOrSynth(r, ctx),
                ExternalUuid = XmiId(r),
                Type = IxEdgeType.Realization,
                FromId = client,
                ToId = iface,
            });
        }

        private static void EmitDependency(XElement pe, Ctx ctx)
        {
            string client = FirstToken(Plain(pe, "client")) ?? IdrefChild(pe, "client");
            string supplier = FirstToken(Plain(pe, "supplier")) ?? IdrefChild(pe, "supplier");
            if (client == null && supplier == null) return;
            ctx.Model.Edges.Add(new IxEdge
            {
                Id = XmiIdOrSynth(pe, ctx),
                ExternalUuid = XmiId(pe),
                Type = IxEdgeType.Dependency,
                FromId = client,
                ToId = supplier,
                Label = Plain(pe, "name"),
            });
        }

        private static void AssembleAssociation(XElement pe, Ctx ctx)
        {
            var ends = Kids(pe, "memberEnd")
                .Select(m => XmiIdref(m) ?? Plain(m, "idref"))
                .Where(x => x != null)
                .ToList();
            if (ends.Count < 2) return;

            var a = EndInfoFor(ends[0], pe, ctx);
            var b = EndInfoFor(ends[1], pe, ctx);

            var edge = new IxEdge
            {
                Id = XmiIdOrSynth(pe, ctx),
                ExternalUuid = XmiId(pe),
                Label = Plain(pe, "name"),
            };

            EndInfo from, to;
            if (a.Aggregation == "composite" || b.Aggregation == "composite")
            {
                edge.Type = IxEdgeType.Composition;
                var agg = a.Aggregation == "composite" ? a : b;
                var other = a.Aggregation == "composite" ? b : a;
                from = other; to = agg; // From = whole (the non-aggregating end's classifier), To = part
            }
            else if (a.Aggregation == "shared" || b.Aggregation == "shared")
            {
                edge.Type = IxEdgeType.Aggregation;
                var agg = a.Aggregation == "shared" ? a : b;
                var other = a.Aggregation == "shared" ? b : a;
                from = other; to = agg;
            }
            else
            {
                int nav = (a.Navigable ? 1 : 0) + (b.Navigable ? 1 : 0);
                if (nav == 1)
                {
                    edge.Type = IxEdgeType.DirectedAssociation;
                    var target = a.Navigable ? a : b;   // navigable end = arrow target
                    var source = a.Navigable ? b : a;
                    from = source; to = target;
                }
                else
                {
                    edge.Type = IxEdgeType.Association;
                    from = a; to = b;
                }
            }

            edge.FromId = from.TypeId;
            edge.ToId = to.TypeId;
            edge.FromRole = from.Role;
            edge.ToRole = to.Role;
            edge.FromMultiplicity = MultStr(from.Lo, from.Hi);
            edge.ToMultiplicity = MultStr(to.Lo, to.Hi);
            ctx.Model.Edges.Add(edge);
        }

        private sealed class EndInfo
        {
            public string TypeId;   // classifier id at this end
            public string Role;     // end name
            public string Lo = "1";
            public string Hi = "1";
            public string Aggregation = "none";
            public bool Navigable;
        }

        private static EndInfo EndInfoFor(string endId, XElement assoc, Ctx ctx)
        {
            // The end Property is either an <ownedEnd> on the association or an <ownedAttribute> on a
            // class (indexed in pass 1). Look in both.
            XElement p = Kids(assoc, "ownedEnd").FirstOrDefault(x => XmiId(x) == endId);
            if (p == null) ctx.PropsById.TryGetValue(endId, out p);
            if (p == null) return new EndInfo { TypeId = endId };

            var (lo, hi) = Multiplicity(p);
            return new EndInfo
            {
                TypeId = RawTypeRef(p) ?? endId,
                Role = Plain(p, "name"),
                Lo = lo,
                Hi = hi,
                Aggregation = Plain(p, "aggregation") ?? "none",
                Navigable = ctx.PropOwner.ContainsKey(endId), // class-owned end => navigable (§4.3)
            };
        }

        private static void EmitComment(XElement c, Ctx ctx)
        {
            string body = Plain(c, "body") ?? Kids(c, "body").FirstOrDefault()?.Value;
            var note = new IxElement
            {
                Id = XmiIdOrSynth(c, ctx),
                ExternalUuid = XmiId(c),
                Type = IxElementType.Note,
                Name = Synth("Note", ctx),
                Documentation = body,
            };
            ctx.Model.Elements.Add(note);

            foreach (var target in AnnotatedIds(c))
                ctx.Model.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = note.Id, ToId = target });
        }

        private static IEnumerable<string> AnnotatedIds(XElement c)
        {
            string attr = Plain(c, "annotatedElement");
            if (!string.IsNullOrWhiteSpace(attr))
                foreach (var tok in attr.Split(new[] { ' ', '\t', '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries))
                    yield return tok;
            foreach (var ae in Kids(c, "annotatedElement"))
            {
                string idref = XmiIdref(ae);
                if (idref != null) yield return idref;
            }
        }

        // --- EA extension: documentation fallback + diagram geometry (§6) --------------------------

        private static void ReadExtension(XElement ext, Ctx ctx)
        {
            // (a) Per-element metadata refines the element the standard model already produced:
            //     documentation + stereotype fill in when absent; a trdKind marker restores an
            //     IxElementType that had to serialize as uml:Class (Table/Boundary/Struct/State/…).
            foreach (var block in ext.Elements().Where(e => e.Name.LocalName == "elements"))
                foreach (var el in block.Elements().Where(e => e.Name.LocalName == "element"))
                {
                    string idref = XmiIdref(el);
                    if (idref == null) continue;
                    var target = ctx.Model.Elements.FirstOrDefault(x => x.Id == idref || x.ExternalUuid == idref);
                    if (target == null) continue;
                    var props = el.Elements().FirstOrDefault(x => x.Name.LocalName == "properties");

                    string documentation = Plain(el, "documentation") ?? (props != null ? Plain(props, "documentation") : null);
                    if (!string.IsNullOrEmpty(documentation) && string.IsNullOrEmpty(target.Documentation))
                        target.Documentation = documentation;

                    string stereotype = Plain(el, "stereotype") ?? (props != null ? Plain(props, "stereotype") : null);
                    if (!string.IsNullOrEmpty(stereotype) && string.IsNullOrEmpty(target.Stereotype))
                        target.Stereotype = stereotype;

                    string kind = Plain(el, "trdKind") ?? (props != null ? Plain(props, "trdKind") : null);
                    if (!string.IsNullOrEmpty(kind) && Enum.TryParse(kind, out IxElementType parsed)
                        && Enum.IsDefined(typeof(IxElementType), parsed))
                        target.Type = parsed;
                    else if (!string.IsNullOrEmpty(stereotype) && target.Type == IxElementType.Class
                             && stereotype.Equals("table", StringComparison.OrdinalIgnoreCase))
                        target.Type = IxElementType.Table; // EA «table» class → ERD entity
                }

            // (b) Non-native edge kinds: a marked connector restores the exact IxEdgeType onto the
            //     Dependency the standard model produced.
            foreach (var block in ext.Elements().Where(e => e.Name.LocalName == "connectors"))
                foreach (var conn in block.Elements().Where(e => e.Name.LocalName == "connector"))
                {
                    string idref = XmiIdref(conn);
                    if (idref == null) continue;
                    var props = conn.Elements().FirstOrDefault(x => x.Name.LocalName == "properties");
                    string kind = Plain(conn, "trdKind") ?? (props != null ? Plain(props, "trdKind") : null);
                    if (string.IsNullOrEmpty(kind)) continue;
                    if (!Enum.TryParse(kind, out IxEdgeType ek) || !Enum.IsDefined(typeof(IxEdgeType), ek)) continue;
                    var edge = ctx.Model.Edges.FirstOrDefault(x => x.ExternalUuid == idref || x.Id == idref);
                    if (edge != null) edge.Type = ek;
                }

            // (c) diagrams — the only place layout coordinates live.
            foreach (var block in ext.Elements().Where(e => e.Name.LocalName == "diagrams"))
                foreach (var d in block.Elements().Where(e => e.Name.LocalName == "diagram"))
                {
                    var props = d.Elements().FirstOrDefault(e => e.Name.LocalName == "properties");
                    var dia = new IxDiagram
                    {
                        Id = XmiIdOrSynth(d, ctx),
                        LayoutProvenance = IxLayoutProvenance.Authored,
                        Name = props != null ? Plain(props, "name") : null,
                        Kind = props != null ? Plain(props, "type") : null,
                    };
                    foreach (var inner in d.Elements().Where(e => e.Name.LocalName == "elements"))
                        foreach (var ne in inner.Elements().Where(e => e.Name.LocalName == "element"))
                        {
                            string subject = Plain(ne, "subject");
                            string geom = Plain(ne, "geometry");
                            if (subject == null || geom == null) continue;
                            var g = ParseGeometry(geom);
                            dia.Nodes.Add(new IxNodePlacement
                            {
                                ElementId = subject,
                                X = g.Left,
                                Y = g.Top,
                                Width = g.Right - g.Left,
                                Height = g.Bottom - g.Top,
                            });
                        }
                    ctx.Model.Diagrams.Add(dia);
                }
        }

        private struct Geometry { public float Left, Top, Right, Bottom; }

        private static Geometry ParseGeometry(string s)
        {
            // "Left=70;Top=50;Right=160;Bottom=200;" — a delimited Key=Value string, not attributes.
            var g = new Geometry();
            foreach (var part in s.Split(';'))
            {
                if (part.Length == 0) continue;
                int eq = part.IndexOf('=');
                if (eq <= 0) continue;
                string key = part.Substring(0, eq).Trim();
                string val = part.Substring(eq + 1).Trim();
                if (!float.TryParse(val, NumberStyles.Float, CultureInfo.InvariantCulture, out float f)) continue;
                if (key.Equals("Left", StringComparison.OrdinalIgnoreCase)) g.Left = f;
                else if (key.Equals("Top", StringComparison.OrdinalIgnoreCase)) g.Top = f;
                else if (key.Equals("Right", StringComparison.OrdinalIgnoreCase)) g.Right = f;
                else if (key.Equals("Bottom", StringComparison.OrdinalIgnoreCase)) g.Bottom = f;
            }
            return g;
        }

        // --- type reference resolution (§5) --------------------------------------------------------

        /// <summary>Resolve a Property/Parameter type to a display name across all three encodings,
        /// preserving the raw reference when it does not resolve.</summary>
        private static string ResolveType(XElement node, Ctx ctx)
        {
            string form1 = Plain(node, "type"); // attribute id reference
            if (form1 != null) return ctx.TypeName.TryGetValue(form1, out var n1) ? n1 : form1;

            var typeEl = Kids(node, "type").FirstOrDefault();
            if (typeEl != null)
            {
                string idref = XmiIdref(typeEl);
                if (idref != null) return ctx.TypeName.TryGetValue(idref, out var n2) ? n2 : idref;
                string href = Plain(typeEl, "href");
                if (href != null) return HrefName(href);
            }
            return null; // untyped is legal
        }

        /// <summary>The raw classifier id at an association end (element ids, not display names).</summary>
        private static string RawTypeRef(XElement node)
        {
            string form1 = Plain(node, "type");
            if (form1 != null) return form1;
            var typeEl = Kids(node, "type").FirstOrDefault();
            if (typeEl == null) return null;
            return XmiIdref(typeEl) ?? Plain(typeEl, "href");
        }

        private static string HrefName(string href)
        {
            int hash = href.IndexOf('#');
            string frag = hash >= 0 ? href.Substring(hash + 1) : href;
            // EA bundles primitives as href fragments like "EAJava_int" / "EACSharp_string" — strip the
            // "EA<lang>_" bookkeeping prefix; otherwise the fragment (e.g. "String") is the type name.
            if (frag.StartsWith("EA", StringComparison.Ordinal))
            {
                int us = frag.IndexOf('_');
                if (us > 0 && us < frag.Length - 1) return frag.Substring(us + 1);
            }
            return frag;
        }

        private static (string lo, string hi) Multiplicity(XElement node)
        {
            string lo = "1", hi = "1";
            var lv = Kids(node, "lowerValue").FirstOrDefault();
            if (lv != null) lo = Plain(lv, "value") ?? "0"; // absent value on LiteralInteger => 0
            var uv = Kids(node, "upperValue").FirstOrDefault();
            if (uv != null)
            {
                string v = Plain(uv, "value");
                hi = (v == null || v == "*" || v == "-1") ? "*" : v; // */-1/absent => unbounded
            }
            return (lo, hi);
        }

        private static string MultStr(string lo, string hi) => lo == hi ? lo : lo + ".." + hi;

        private static string DefaultVal(XElement node, Ctx ctx)
        {
            var dv = Kids(node, "defaultValue").FirstOrDefault();
            if (dv == null) return null;
            string v = Plain(dv, "value");
            if (v != null) return v;
            var body = Kids(dv, "body").FirstOrDefault();
            if (body != null) return body.Value;
            string inst = Plain(dv, "instance") ?? XmiIdref(dv);
            if (inst != null) return ctx.TypeName.TryGetValue(inst, out var n) ? n : inst;
            return null;
        }

        // --- format detection ----------------------------------------------------------------------

        private static bool IsXmi1x(XElement root)
        {
            // Dotted xmi.id / xmi.version / xmi.idref, or an <XMI.content> wrapper, are 1.x tells (§7).
            foreach (var e in root.DescendantsAndSelf())
                foreach (var a in e.Attributes())
                {
                    string ln = a.Name.LocalName;
                    if (ln == "xmi.id" || ln == "xmi.idref") return true;
                    if (ln == "xmi.version" && a.Value.StartsWith("1.", StringComparison.Ordinal)) return true;
                }

            string ver = root.Attributes()
                .FirstOrDefault(a => a.Name.LocalName == "version" && NsIsXmi(a.Name.Namespace))?.Value;
            if (ver != null && ver.StartsWith("1.", StringComparison.Ordinal)) return true;

            if (root.Name.LocalName == "XMI" &&
                root.Elements().Any(e => e.Name.LocalName == "XMI.content" || e.Name.LocalName == "XMI.header"))
                return true;

            return false;
        }

        private static XElement FindModelRoot(XElement root)
        {
            if (IsModelRootName(root.Name.LocalName)) return root;
            if (root.Name.LocalName == "XMI")
            {
                var direct = root.Elements().FirstOrDefault(e => IsModelRootName(e.Name.LocalName));
                if (direct != null) return direct;
            }
            return root.Descendants().FirstOrDefault(e => IsModelRootName(e.Name.LocalName));
        }

        private static bool IsModelRootName(string ln) => ln == "Model" || ln == "Package" || ln == "Profile";

        private static bool IsClassifierType(string tl) =>
            tl == "Class" || tl == "Interface" || tl == "Enumeration" ||
            tl == "DataType" || tl == "PrimitiveType" || tl == "AssociationClass" ||
            tl == "Artifact" || tl == "Actor" || tl == "UseCase" || tl == "Component";

        private static bool HasMembers(XElement pe) =>
            pe.Elements().Any(e => e.Name.LocalName == "ownedAttribute" || e.Name.LocalName == "ownedOperation");

        // --- namespace-agnostic attribute readers --------------------------------------------------

        private static string Plain(XElement e, string localName)
            => e.Attributes().FirstOrDefault(a => a.Name.LocalName == localName && a.Name.Namespace == XNamespace.None)?.Value;

        private static string XmiId(XElement e) => XmiScoped(e, "id");
        private static string XmiIdref(XElement e) => XmiScoped(e, "idref");

        private static string XmiScoped(XElement e, string localName)
        {
            foreach (var a in e.Attributes())
                if (a.Name.LocalName == localName && NsIsXmi(a.Name.Namespace)) return a.Value;
            // Fallback: any prefixed (non-default-namespace) attribute of that local name.
            foreach (var a in e.Attributes())
                if (a.Name.LocalName == localName && a.Name.Namespace != XNamespace.None) return a.Value;
            return null;
        }

        /// <summary>Local part of xmi:type / xsi:type (the file's prefix is irrelevant), or null.</summary>
        private static string LocalType(XElement e)
        {
            string raw = null;
            foreach (var a in e.Attributes())
                if (a.Name.LocalName == "type" && (NsIsXmi(a.Name.Namespace) || NsIsXsi(a.Name.Namespace)))
                { raw = a.Value; break; }
            if (raw == null) return null;
            int i = raw.LastIndexOf(':');
            return i >= 0 ? raw.Substring(i + 1) : raw;
        }

        private static string IdrefChild(XElement e, string localName)
        {
            var child = Kids(e, localName).FirstOrDefault();
            return child != null ? (XmiIdref(child) ?? Plain(child, "idref")) : null;
        }

        private static bool NsIsXmi(XNamespace ns)
            => ns != XNamespace.None && ns.NamespaceName.IndexOf("XMI", StringComparison.OrdinalIgnoreCase) >= 0;

        private static bool NsIsXsi(XNamespace ns)
            => ns != XNamespace.None && ns.NamespaceName.IndexOf("XMLSchema-instance", StringComparison.OrdinalIgnoreCase) >= 0;

        private static IEnumerable<XElement> Kids(XElement e, string localName)
            => e.Elements().Where(x => x.Name.LocalName == localName);

        private static string FirstToken(string s)
        {
            if (string.IsNullOrWhiteSpace(s)) return null;
            int sp = s.IndexOfAny(new[] { ' ', '\t', '\n', '\r' });
            return sp < 0 ? s : s.Substring(0, sp);
        }

        // --- small value helpers -------------------------------------------------------------------

        private static bool Bool(string s) => s == "true";

        private static IxVisibility Vis(string s)
        {
            switch (s)
            {
                case "private": return IxVisibility.Private;
                case "protected": return IxVisibility.Protected;
                case "package": return IxVisibility.Package;
                default: return IxVisibility.Public; // default per §9
            }
        }

        private static string XmiIdOrSynth(XElement e, Ctx ctx)
            => XmiId(e) ?? ("synth_" + (++ctx.SynthSeq));

        private static string Synth(string prefix, Ctx ctx) => prefix + (++ctx.AnonSeq);

        // --- parse context -------------------------------------------------------------------------

        private sealed class Ctx
        {
            public IxModel Model;
            public readonly Dictionary<string, XElement> ElemsById = new Dictionary<string, XElement>();
            public readonly Dictionary<string, XElement> PropsById = new Dictionary<string, XElement>();
            public readonly Dictionary<string, string> PropOwner = new Dictionary<string, string>();
            public readonly Dictionary<string, string> TypeName = new Dictionary<string, string>();
            public int AnonSeq;
            public int SynthSeq;
        }
    }
}
