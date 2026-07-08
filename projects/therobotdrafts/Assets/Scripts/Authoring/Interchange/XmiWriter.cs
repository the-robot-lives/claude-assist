using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Linq;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Exports the neutral <see cref="IxModel"/> as XMI 2.1 (docs/formats/xmi-format.md §8) — the
    /// exact dialect Enterprise Architect emits and round-trips: an <c>xmi:XMI</c> wrapper, the
    /// <c>schema.omg.org</c> namespace family, self-contained primitive types (no fragile external
    /// hrefs), nested <c>&lt;type xmi:idref&gt;</c> references, and the EA-favored association pattern.
    /// Ids are stable — the element's <see cref="IxElement.ExternalUuid"/> when present, otherwise a
    /// deterministic NCName derived from its <see cref="IxElement.Id"/>. The EA <c>xmi:Extension</c> is
    /// emitted only when the model carries authored diagram geometry, which lives nowhere else.
    /// Pure C# + BCL (System.Xml.Linq); no engine references.
    /// </summary>
    public static class XmiWriter
    {
        public static string Write(IxModel model)
        {
            if (model == null) throw new InterchangeException("Cannot write a null model to XMI.");
            return new W(model).Run();
        }

        private sealed class W
        {
            private static readonly XNamespace UmlNs = "http://schema.omg.org/spec/UML/2.1";
            private static readonly XNamespace XmiNs = "http://schema.omg.org/spec/XMI/2.1";

            private readonly IxModel _model;
            private readonly Dictionary<string, string> _wid = new Dictionary<string, string>();        // IxElement.Id -> xmi:id
            private readonly Dictionary<string, string> _idByName = new Dictionary<string, string>();     // element Name -> xmi:id (type resolution)
            private readonly Dictionary<string, IxElement> _byId = new Dictionary<string, IxElement>();
            private readonly Dictionary<string, XElement> _xelById = new Dictionary<string, XElement>();
            private readonly Dictionary<string, string> _primIdByName = new Dictionary<string, string>(); // synthesized primitive name -> id
            private readonly List<XElement> _primitives = new List<XElement>();
            private readonly List<(string id, string kind)> _connectorMarkers = new List<(string, string)>(); // non-native edge kinds
            private int _seq;

            public W(IxModel model) { _model = model; }

            public string Run()
            {
                // 1. Assign a stable xmi:id to every element and index names for type resolution.
                foreach (var el in _model.Elements)
                {
                    string id = !string.IsNullOrEmpty(el.ExternalUuid) ? Nc(el.ExternalUuid) : "TRD_" + Nc(el.Id);
                    _wid[el.Id ?? id] = id;
                    if (el.Id != null) _byId[el.Id] = el;
                    if (!string.IsNullOrEmpty(el.Name) && !_idByName.ContainsKey(el.Name)) _idByName[el.Name] = id;
                }

                // 2. Build the XElement for each structural element (members resolve types here, which is
                //    what discovers the synthesized primitive-type packagedElements).
                foreach (var el in _model.Elements)
                {
                    if (el.Type == IxElementType.Note) continue;
                    _xelById[el.Id] = BuildElement(el);
                }

                var modelEl = new XElement(UmlNs + "Model",
                    TypeA("uml:Model"),
                    IdA("MODEL_ROOT"),
                    new XAttribute("name", string.IsNullOrEmpty(_model.Name) ? "Model" : _model.Name));

                // 3. Self-contained primitives first, then structural elements nested per ParentId.
                foreach (var p in _primitives) modelEl.Add(p);
                foreach (var el in _model.Elements)
                {
                    if (el.Type == IxElementType.Note) continue;
                    var xe = _xelById[el.Id];
                    XElement parent = (el.ParentId != null && _xelById.TryGetValue(el.ParentId, out var pxe)) ? pxe : modelEl;
                    parent.Add(xe);
                }

                // 4. Edges and notes.
                EmitEdges(modelEl);
                EmitNotes(modelEl);

                // 5. Envelope.
                var xmi = new XElement(XmiNs + "XMI",
                    new XAttribute(XNamespace.Xmlns + "uml", UmlNs.NamespaceName),
                    new XAttribute(XNamespace.Xmlns + "xmi", XmiNs.NamespaceName),
                    new XAttribute(XmiNs + "version", "2.1"),
                    new XElement(XmiNs + "Documentation",
                        new XAttribute("exporter", "TheRobotDrafts"),
                        new XAttribute("exporterVersion", "1.0")),
                    modelEl);

                // The EA extension now carries three kinds of side-channel metadata: element
                // stereotype/kind/documentation, non-native edge kinds, and authored diagram geometry.
                // Emit it only if it ended up with content.
                var extension = BuildExtension();
                if (extension.HasElements) xmi.Add(extension);

                var doc = new XDocument(new XDeclaration("1.0", "UTF-8", null), xmi);
                return Serialize(doc);
            }

            // --- structural elements ---------------------------------------------------------------

            private XElement BuildElement(IxElement el)
            {
                var xe = new XElement("packagedElement", TypeA("uml:" + MetaOf(el.Type)), IdA(_wid[el.Id]));
                if (!string.IsNullOrEmpty(el.Name)) xe.Add(new XAttribute("name", el.Name));
                if (el.IsAbstract) xe.Add(new XAttribute("isAbstract", "true"));

                if (el.Type == IxElementType.Enum)
                {
                    int i = 0;
                    foreach (var lit in el.EnumLiterals)
                        xe.Add(new XElement("ownedLiteral",
                            TypeA("uml:EnumerationLiteral"), IdA(_wid[el.Id] + "_l" + (i++)),
                            new XAttribute("name", lit ?? "")));
                }
                else if (IsClassifier(el.Type))
                {
                    foreach (var m in el.Members)
                        xe.Add(m.IsOperation ? BuildOperation(el, m) : BuildField(el, m));
                }
                return xe;
            }

            private XElement BuildField(IxElement owner, IxMember m)
            {
                string mid = MemberId(owner, m);
                var a = new XElement("ownedAttribute", TypeA("uml:Property"), IdA(mid));
                if (!string.IsNullOrEmpty(m.Name)) a.Add(new XAttribute("name", m.Name));
                if (m.Visibility != IxVisibility.Public) a.Add(new XAttribute("visibility", VisStr(m.Visibility)));
                if (m.IsStatic) a.Add(new XAttribute("isStatic", "true"));

                var (baseType, lo, hi) = SplitMult(m.Type);
                AddType(a, baseType);
                AddMult(a, mid, lo, hi);
                if (m.DefaultValue != null)
                    a.Add(new XElement("defaultValue", TypeA("uml:LiteralString"), IdA(mid + "_dv"),
                        new XAttribute("value", m.DefaultValue)));
                return a;
            }

            private XElement BuildOperation(IxElement owner, IxMember m)
            {
                string mid = MemberId(owner, m);
                var o = new XElement("ownedOperation", TypeA("uml:Operation"), IdA(mid));
                if (!string.IsNullOrEmpty(m.Name)) o.Add(new XAttribute("name", m.Name));
                if (m.Visibility != IxVisibility.Public) o.Add(new XAttribute("visibility", VisStr(m.Visibility)));
                if (m.IsStatic) o.Add(new XAttribute("isStatic", "true"));
                if (m.IsAbstract) o.Add(new XAttribute("isAbstract", "true"));

                // Return parameter first when the operation is typed, then the ins in declared order.
                if (m.Type != null)
                {
                    var ret = new XElement("ownedParameter", TypeA("uml:Parameter"), IdA(mid + "_ret"),
                        new XAttribute("direction", "return"));
                    AddType(ret, m.Type);
                    o.Add(ret);
                }
                int pi = 0;
                foreach (var p in m.Parameters)
                {
                    string pid = mid + "_p" + (pi++);
                    var pe = new XElement("ownedParameter", TypeA("uml:Parameter"), IdA(pid));
                    if (!string.IsNullOrEmpty(p.Name)) pe.Add(new XAttribute("name", p.Name));
                    if (!string.IsNullOrEmpty(p.Direction)) pe.Add(new XAttribute("direction", p.Direction));
                    AddType(pe, p.Type);
                    if (p.DefaultValue != null)
                        pe.Add(new XElement("defaultValue", TypeA("uml:LiteralString"), IdA(pid + "_dv"),
                            new XAttribute("value", p.DefaultValue)));
                    o.Add(pe);
                }
                return o;
            }

            private void AddType(XElement parent, string typeName)
            {
                if (string.IsNullOrEmpty(typeName)) return;
                string id = _idByName.TryGetValue(typeName, out var eid) ? eid : GetOrCreatePrimitive(typeName);
                parent.Add(new XElement("type", IdrefA(id)));
            }

            private string GetOrCreatePrimitive(string name)
            {
                if (_primIdByName.TryGetValue(name, out var pid)) return pid;
                pid = "PT_" + Nc(name);
                _primIdByName[name] = pid;
                _primitives.Add(new XElement("packagedElement",
                    TypeA("uml:PrimitiveType"), IdA(pid), new XAttribute("name", name)));
                return pid;
            }

            private void AddMult(XElement parent, string id, string lo, string hi)
            {
                if (lo == null) return;
                parent.Add(new XElement("lowerValue", TypeA("uml:LiteralInteger"), IdA(id + "_lo"),
                    new XAttribute("value", lo)));
                parent.Add(new XElement("upperValue", TypeA("uml:LiteralUnlimitedNatural"), IdA(id + "_hi"),
                    new XAttribute("value", hi)));
            }

            // --- edges -----------------------------------------------------------------------------

            private void EmitEdges(XElement modelEl)
            {
                foreach (var e in _model.Edges)
                {
                    switch (e.Type)
                    {
                        case IxEdgeType.Generalization:
                            AddChildEdge(e.FromId, new XElement("generalization",
                                TypeA("uml:Generalization"), IdA(EdgeId(e)),
                                new XAttribute("general", Wid(e.ToId))));
                            break;

                        case IxEdgeType.Realization:
                            AddChildEdge(e.FromId, new XElement("interfaceRealization",
                                TypeA("uml:InterfaceRealization"), IdA(EdgeId(e)),
                                new XAttribute("client", Wid(e.FromId)),
                                new XAttribute("supplier", Wid(e.ToId)),
                                new XAttribute("contract", Wid(e.ToId))));
                            break;

                        case IxEdgeType.Dependency:
                            modelEl.Add(BuildDependency(e, EdgeId(e)));
                            break;

                        case IxEdgeType.NoteLink:
                            // A note's link is carried by <ownedComment annotatedElement>. A NoteLink with
                            // no actual Note on either side is emitted as a marked Dependency so its kind
                            // survives the round trip.
                            if (!IsNote(e.FromId) && !IsNote(e.ToId))
                            {
                                string nid = EdgeId(e);
                                modelEl.Add(BuildDependency(e, nid));
                                _connectorMarkers.Add((nid, IxEdgeType.NoteLink.ToString()));
                            }
                            break;

                        case IxEdgeType.Association:
                        case IxEdgeType.DirectedAssociation:
                        case IxEdgeType.Aggregation:
                        case IxEdgeType.Composition:
                            modelEl.Add(BuildAssociation(e));
                            break;

                        default:
                            // Every other kind (Extension, Include, Extend, Transition, Message*, Unknown)
                            // has no native UML 2.1 construct — serialize as a Dependency that preserves
                            // client/supplier/name, and stash the exact kind in the extension so nothing
                            // vanishes on round trip.
                            string did = EdgeId(e);
                            modelEl.Add(BuildDependency(e, did));
                            _connectorMarkers.Add((did, e.Type.ToString()));
                            break;
                    }
                }
            }

            private XElement BuildDependency(IxEdge e, string id)
            {
                var dep = new XElement("packagedElement", TypeA("uml:Dependency"), IdA(id));
                if (!string.IsNullOrEmpty(e.Label)) dep.Add(new XAttribute("name", e.Label));
                if (e.FromId != null) dep.Add(new XAttribute("client", Wid(e.FromId)));
                if (e.ToId != null) dep.Add(new XAttribute("supplier", Wid(e.ToId)));
                return dep;
            }

            private XElement BuildAssociation(IxEdge e)
            {
                string aid = EdgeId(e);
                var assoc = new XElement("packagedElement", TypeA("uml:Association"), IdA(aid));
                if (!string.IsNullOrEmpty(e.Label)) assoc.Add(new XAttribute("name", e.Label));

                string e1 = aid + "_e1", e2 = aid + "_e2";
                assoc.Add(new XElement("memberEnd", IdrefA(e1)));
                assoc.Add(new XElement("memberEnd", IdrefA(e2)));

                if (e.Type == IxEdgeType.Composition || e.Type == IxEdgeType.Aggregation)
                {
                    // The diamond sits on the whole. Reader recovers From=whole from the NON-aggregating
                    // end's type, so the aggregation attribute goes on the To (part) end.
                    string agg = e.Type == IxEdgeType.Composition ? "composite" : "shared";
                    assoc.Add(EndProp(e1, "ownedEnd", Wid(e.FromId), e.FromRole, e.FromMultiplicity, "none", aid));
                    assoc.Add(EndProp(e2, "ownedEnd", Wid(e.ToId), e.ToRole, e.ToMultiplicity, agg, aid));
                }
                else if (e.Type == IxEdgeType.DirectedAssociation)
                {
                    // Navigable target end lives as an ownedAttribute on the source class; the source end
                    // lives as an ownedEnd on the association. That asymmetry is how the reader recovers
                    // one-way navigability.
                    assoc.Add(EndProp(e1, "ownedEnd", Wid(e.FromId), e.FromRole, e.FromMultiplicity, "none", aid));
                    var navEnd = EndProp(e2, "ownedAttribute", Wid(e.ToId), e.ToRole, e.ToMultiplicity, "none", aid);
                    AddChildEnd(e.FromId, navEnd);
                }
                else
                {
                    assoc.Add(EndProp(e1, "ownedEnd", Wid(e.FromId), e.FromRole, e.FromMultiplicity, "none", aid));
                    assoc.Add(EndProp(e2, "ownedEnd", Wid(e.ToId), e.ToRole, e.ToMultiplicity, "none", aid));
                }
                return assoc;
            }

            private XElement EndProp(string endId, string local, string typeId, string role, string mult, string agg, string assocRef)
            {
                var p = new XElement(local, TypeA("uml:Property"), IdA(endId));
                if (!string.IsNullOrEmpty(role)) p.Add(new XAttribute("name", role));
                if (assocRef != null) p.Add(new XAttribute("association", assocRef));
                if (agg != null && agg != "none") p.Add(new XAttribute("aggregation", agg));
                if (typeId != null) p.Add(new XElement("type", IdrefA(typeId)));
                var (lo, hi) = SplitEndMult(mult);
                AddMult(p, endId, lo, hi);
                return p;
            }

            private void EmitNotes(XElement modelEl)
            {
                // Gather each note's annotated targets from its outgoing NoteLink edges.
                var targets = new Dictionary<string, List<string>>();
                foreach (var e in _model.Edges)
                {
                    if (e.Type != IxEdgeType.NoteLink || !IsNote(e.FromId) || e.ToId == null) continue;
                    if (!targets.TryGetValue(e.FromId, out var list)) targets[e.FromId] = list = new List<string>();
                    list.Add(e.ToId);
                }

                foreach (var el in _model.Elements)
                {
                    if (el.Type != IxElementType.Note) continue;
                    var oc = new XElement("ownedComment", TypeA("uml:Comment"), IdA(_wid[el.Id]));
                    if (el.Documentation != null) oc.Add(new XAttribute("body", el.Documentation));
                    if (targets.TryGetValue(el.Id, out var list) && list.Count > 0)
                        oc.Add(new XAttribute("annotatedElement", string.Join(" ", list.Select(Wid))));
                    modelEl.Add(oc);
                }
            }

            private void AddChildEdge(string fromId, XElement edge)
            {
                if (fromId != null && _xelById.TryGetValue(fromId, out var xe)) xe.Add(edge);
            }

            private void AddChildEnd(string classId, XElement end)
            {
                if (classId != null && _xelById.TryGetValue(classId, out var xe)) xe.Add(end);
            }

            // --- EA extension: element metadata + non-native edge kinds + diagram geometry (§6) ------

            private XElement BuildExtension()
            {
                var ext = new XElement(XmiNs + "Extension",
                    new XAttribute("extender", "TheRobotDrafts"),
                    new XAttribute("extenderID", "TheRobotDrafts"));

                // (a) Per-element metadata: stereotype, documentation, and a kind marker for any
                //     IxElementType that had to fall back to uml:Class (Table/Boundary/Struct/State/…).
                var metaEls = new List<XElement>();
                foreach (var el in _model.Elements)
                {
                    if (el.Type == IxElementType.Note) continue;
                    bool needKind = NeedsKindMarker(el.Type);
                    bool hasStereo = !string.IsNullOrEmpty(el.Stereotype);
                    bool hasDoc = !string.IsNullOrEmpty(el.Documentation);
                    if (!needKind && !hasStereo && !hasDoc) continue;

                    var props = new XElement("properties");
                    if (hasStereo) props.Add(new XAttribute("stereotype", el.Stereotype));
                    if (hasDoc) props.Add(new XAttribute("documentation", el.Documentation));
                    if (needKind) props.Add(new XAttribute("trdKind", el.Type.ToString()));
                    metaEls.Add(new XElement("element",
                        IdrefA(_wid[el.Id]), TypeA("uml:" + MetaOf(el.Type)), props));
                }
                if (metaEls.Count > 0)
                {
                    var elements = new XElement("elements");
                    foreach (var e in metaEls) elements.Add(e);
                    ext.Add(elements);
                }

                // (b) Non-native edge kinds recorded as connectors keyed by the Dependency id we emitted.
                if (_connectorMarkers.Count > 0)
                {
                    var connectors = new XElement("connectors");
                    foreach (var cm in _connectorMarkers)
                        connectors.Add(new XElement("connector", IdrefA(cm.id),
                            new XElement("properties", new XAttribute("trdKind", cm.kind))));
                    ext.Add(connectors);
                }

                // (c) Authored diagram geometry — the only place layout coordinates live.
                if (_model.Diagrams != null && _model.Diagrams.Count > 0)
                {
                    var diagrams = new XElement("diagrams");
                    foreach (var dia in _model.Diagrams)
                    {
                        var d = new XElement("diagram", IdA(!string.IsNullOrEmpty(dia.Id) ? Nc(dia.Id) : "DIA_" + (_seq++)));
                        var props = new XElement("properties");
                        if (dia.Name != null) props.Add(new XAttribute("name", dia.Name));
                        if (dia.Kind != null) props.Add(new XAttribute("type", dia.Kind));
                        d.Add(props);

                        var elems = new XElement("elements");
                        foreach (var n in dia.Nodes)
                        {
                            float right = n.X + n.Width, bottom = n.Y + n.Height;
                            string geom = "Left=" + F(n.X) + ";Top=" + F(n.Y) +
                                          ";Right=" + F(right) + ";Bottom=" + F(bottom) + ";";
                            elems.Add(new XElement("element",
                                new XAttribute("geometry", geom),
                                new XAttribute("subject", Wid(n.ElementId))));
                        }
                        d.Add(elems);
                        diagrams.Add(d);
                    }
                    ext.Add(diagrams);
                }
                return ext;
            }

            // --- helpers ---------------------------------------------------------------------------

            private XAttribute IdA(string id) => new XAttribute(XmiNs + "id", id);
            private XAttribute IdrefA(string id) => new XAttribute(XmiNs + "idref", id);
            private XAttribute TypeA(string qname) => new XAttribute(XmiNs + "type", qname);

            private string Wid(string id) => id != null && _wid.TryGetValue(id, out var w) ? w : id;
            private bool IsNote(string id) => id != null && _byId.TryGetValue(id, out var e) && e.Type == IxElementType.Note;

            private string EdgeId(IxEdge e) =>
                !string.IsNullOrEmpty(e.ExternalUuid) ? Nc(e.ExternalUuid)
                : !string.IsNullOrEmpty(e.Id) ? "TRD_" + Nc(e.Id)
                : "TRD_edge" + (_seq++);

            private string MemberId(IxElement owner, IxMember m) =>
                !string.IsNullOrEmpty(m.ExternalUuid) ? Nc(m.ExternalUuid) : _wid[owner.Id] + "_m" + (_seq++);

            /// <summary>Peel a "[lower..upper]" (or "[n]") multiplicity suffix off a member type.</summary>
            private static (string baseType, string lo, string hi) SplitMult(string type)
            {
                if (type == null || !type.EndsWith("]", StringComparison.Ordinal)) return (type, null, null);
                int lb = type.LastIndexOf('[');
                if (lb < 0) return (type, null, null);
                string inner = type.Substring(lb + 1, type.Length - lb - 2);
                string baseType = type.Substring(0, lb);
                if (baseType.Length == 0) baseType = null;
                var (lo, hi) = SplitEndMult(inner);
                return (baseType, lo ?? "1", hi ?? "1");
            }

            /// <summary>Split "lo..hi" or single "n" into (lo, hi); empty input yields (null, null).</summary>
            private static (string lo, string hi) SplitEndMult(string mult)
            {
                if (string.IsNullOrEmpty(mult)) return (null, null);
                int dd = mult.IndexOf("..", StringComparison.Ordinal);
                if (dd < 0) return (mult, mult);
                return (mult.Substring(0, dd), mult.Substring(dd + 2));
            }

            // Element kinds that have a real UML 2.1 metaclass are emitted as it (and recovered from
            // it on read); every other kind falls back to uml:Class and rides a trdKind marker.
            private static string MetaOf(IxElementType t)
            {
                switch (t)
                {
                    case IxElementType.Package: return "Package";
                    case IxElementType.Interface: return "Interface";
                    case IxElementType.Enum: return "Enumeration";
                    case IxElementType.DataType: return "DataType";
                    case IxElementType.Artifact: return "Artifact";
                    case IxElementType.Actor: return "Actor";
                    case IxElementType.UseCase: return "UseCase";
                    case IxElementType.Component: return "Component";
                    default: return "Class"; // Class/Struct/Table/Boundary/State/… serialize as uml:Class
                }
            }

            // Inverse of MetaOf for the metaclasses we emit; anything else reads back as Class.
            internal static IxElementType MetaToType(string meta)
            {
                switch (meta)
                {
                    case "Package": return IxElementType.Package;
                    case "Interface": return IxElementType.Interface;
                    case "Enumeration": return IxElementType.Enum;
                    case "DataType": return IxElementType.DataType;
                    case "Artifact": return IxElementType.Artifact;
                    case "Actor": return IxElementType.Actor;
                    case "UseCase": return IxElementType.UseCase;
                    case "Component": return IxElementType.Component;
                    default: return IxElementType.Class;
                }
            }

            // True when the metaclass alone cannot recover the IxElementType (needs a trdKind marker).
            private static bool NeedsKindMarker(IxElementType t) =>
                t != IxElementType.Note && MetaToType(MetaOf(t)) != t;

            // Any element that is not a Package/Enum/Note carries members losslessly.
            private static bool IsClassifier(IxElementType t) =>
                t != IxElementType.Package && t != IxElementType.Enum && t != IxElementType.Note;

            private static string VisStr(IxVisibility v)
            {
                switch (v)
                {
                    case IxVisibility.Private: return "private";
                    case IxVisibility.Protected: return "protected";
                    case IxVisibility.Package: return "package";
                    default: return "public";
                }
            }

            private static string F(float f) => f.ToString("0.###", CultureInfo.InvariantCulture);

            /// <summary>Sanitize an arbitrary string into a valid XML NCName so ids never need escaping.</summary>
            private static string Nc(string s)
            {
                if (string.IsNullOrEmpty(s)) return "x";
                var sb = new StringBuilder(s.Length + 1);
                for (int i = 0; i < s.Length; i++)
                {
                    char c = s[i];
                    bool ok = char.IsLetterOrDigit(c) || c == '_' || c == '-' || c == '.';
                    sb.Append(ok ? c : '_');
                }
                char c0 = sb[0];
                if (!(char.IsLetter(c0) || c0 == '_')) sb.Insert(0, '_');
                return sb.ToString();
            }

            private static string Serialize(XDocument doc)
            {
                var settings = new XmlWriterSettings
                {
                    Indent = true,
                    IndentChars = "  ",
                    OmitXmlDeclaration = false,
                    Encoding = new UTF8Encoding(false),
                };
                var sw = new Utf8StringWriter();
                using (var xw = XmlWriter.Create(sw, settings))
                    doc.Save(xw);
                return sw.ToString();
            }

            private sealed class Utf8StringWriter : StringWriter
            {
                public override Encoding Encoding => Encoding.UTF8;
            }
        }
    }
}
