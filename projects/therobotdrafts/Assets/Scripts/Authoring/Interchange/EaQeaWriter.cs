using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Writes an <see cref="IxModel"/> out as a Sparx Enterprise Architect <c>.qea</c> project by copying a blank
    /// template (<c>Assets/StreamingAssets/Interchange/ea-template.qea</c>) and INSERTing model rows into it. Building
    /// a <c>.qea</c> from scratch is intractable (full EA schema + seed tables + <c>usys*</c> magic), so the template
    /// carries all of that and this writer only adds model content — the strategy recommended in
    /// <c>docs/formats/qea-format.md §9</c>.
    ///
    /// <para><b>Round-trip.</b> The denormalization here is the exact inverse of <see cref="EaQeaReader"/>: package
    /// elements get a <c>t_object</c> Package-mirror (referenced by diagrams/connectors), <c>Table</c> becomes
    /// <c>Class «table»</c>, aggregation/composition ends are re-swapped so EA's diamond lands on the target end,
    /// and diagram coordinates invert back to EA's downward-negative Y.</para>
    ///
    /// <para><b>IDs &amp; GUIDs.</b> Numeric PKs are allocated above the template maxima (the template's only row is
    /// the root package, <c>Package_ID=1</c>); <c>sqlite_sequence</c> is bumped at the end. Each row's
    /// <c>ea_guid</c> reuses <see cref="IxElement.ExternalUuid"/> when it is a well-formed <c>{GUID}</c>, else a fresh
    /// one, kept unique within the file.</para>
    /// </summary>
    public static class EaQeaWriter
    {
        private static readonly Regex GuidShape =
            new Regex(@"^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}$",
                RegexOptions.Compiled);

        private const long RootPackageId = 1;

        public static void Write(IxModel model, string templatePath, string outputPath)
        {
            if (model == null) throw new InterchangeException("EaQeaWriter.Write: null model");
            if (string.IsNullOrEmpty(templatePath) || !File.Exists(templatePath))
                throw new InterchangeException("EaQeaWriter.Write: template not found: " + templatePath);
            if (string.IsNullOrEmpty(outputPath)) throw new InterchangeException("EaQeaWriter.Write: null output path");

            File.Copy(templatePath, outputPath, true);

            // ---- allocation state seeded from the template's high-water marks ----------------------------------
            var max = SqliteCli.Query(outputPath,
                "SELECT (SELECT COALESCE(MAX(Package_ID),0) FROM t_package), " +
                "(SELECT COALESCE(MAX(Object_ID),0) FROM t_object), " +
                "(SELECT COALESCE(MAX(ID),0) FROM t_attribute), " +
                "(SELECT COALESCE(MAX(OperationID),0) FROM t_operation), " +
                "(SELECT COALESCE(MAX(Connector_ID),0) FROM t_connector), " +
                "(SELECT COALESCE(MAX(Diagram_ID),0) FROM t_diagram), " +
                "(SELECT COALESCE(MAX(Instance_ID),0) FROM t_diagramobjects), " +
                "(SELECT COALESCE(MAX(PropertyID),0) FROM t_objectproperties);");
            var m0 = max.Length > 0 ? max[0] : new[] { "1", "0", "0", "0", "0", "0", "0", "0" };

            long nextPackage = P(m0, 0, 1) + 1;
            long nextObject = P(m0, 1, 0) + 1;
            long nextAttr = P(m0, 2, 0) + 1;
            long nextOp = P(m0, 3, 0) + 1;
            long nextConn = P(m0, 4, 0) + 1;
            long nextDiagram = P(m0, 5, 0) + 1;
            long nextInstance = P(m0, 6, 0) + 1;
            long nextProp = P(m0, 7, 0) + 1;

            var usedGuids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            string Guid_(string external)
            {
                if (!string.IsNullOrEmpty(external) && GuidShape.IsMatch(external) && !usedGuids.Contains(external))
                {
                    usedGuids.Add(external);
                    return external;
                }
                string g;
                do { g = "{" + Guid.NewGuid().ToString().ToUpperInvariant() + "}"; } while (usedGuids.Contains(g));
                usedGuids.Add(g);
                return g;
            }

            var packages = new List<IxElement>();
            var classifiers = new List<IxElement>();
            var packageIds = new HashSet<string>();
            foreach (var el in model.Elements)
            {
                if (el == null || el.Id == null) continue;
                if (el.Type == IxElementType.Package) { packages.Add(el); packageIds.Add(el.Id); }
                else classifiers.Add(el);
            }

            // ---- assign package numeric IDs (parents before children) ------------------------------------------
            var pkgIdOf = new Dictionary<string, long>();          // element.Id -> Package_ID
            var pending = new List<IxElement>(packages);
            while (pending.Count > 0)
            {
                bool progressed = false;
                for (int i = pending.Count - 1; i >= 0; i--)
                {
                    var p = pending[i];
                    bool parentReady = p.ParentId == null || !packageIds.Contains(p.ParentId)
                                                          || pkgIdOf.ContainsKey(p.ParentId);
                    if (!parentReady) continue;
                    pkgIdOf[p.Id] = nextPackage++;
                    pending.RemoveAt(i);
                    progressed = true;
                }
                if (!progressed) // parent cycle / dangling: flush the rest under the root
                {
                    foreach (var p in pending) pkgIdOf[p.Id] = nextPackage++;
                    break;
                }
            }

            long ParentPackageId(string parentElementId) =>
                parentElementId != null && pkgIdOf.TryGetValue(parentElementId, out var pid) ? pid : RootPackageId;

            // ---- assign object numeric IDs (classifiers + a Package-mirror per package) -------------------------
            var objIdOf = new Dictionary<string, long>();          // element.Id -> Object_ID used by connectors/diagrams
            foreach (var c in classifiers) objIdOf[c.Id] = nextObject++;
            var mirrorObjId = new Dictionary<string, long>();      // package element.Id -> mirror Object_ID
            foreach (var p in packages)
            {
                long oid = nextObject++;
                mirrorObjId[p.Id] = oid;
                objIdOf[p.Id] = oid;
            }

            // ---- build the INSERT script (single BEGIN..COMMIT), FK-safe order per doc §9.1 --------------------
            var sb = new StringBuilder();
            sb.Append("BEGIN;\n");

            // 1) t_package
            foreach (var p in packages)
            {
                long id = pkgIdOf[p.Id];
                long parent = ParentPackageId(p.ParentId);
                sb.Append("INSERT INTO t_package (Package_ID, Name, Parent_ID, ea_guid) VALUES (")
                  .Append(id).Append(", ").Append(Q(p.Name)).Append(", ").Append(parent).Append(", ")
                  .Append(Q(Guid_(p.ExternalUuid))).Append(");\n");
            }

            // 2) t_object — classifiers then package mirrors
            foreach (var c in classifiers)
            {
                long id = objIdOf[c.Id];
                long ownerPkg = ParentPackageId(c.ParentId);
                string objType = ObjectTypeOf(c.Type);
                string stereotype = StereotypeOf(c);
                sb.Append("INSERT INTO t_object (Object_ID, Object_Type, Name, Note, Package_ID, Stereotype, " +
                          "Abstract, Scope, NType, ea_guid) VALUES (")
                  .Append(id).Append(", ").Append(Q(objType)).Append(", ").Append(Q(c.Name)).Append(", ")
                  .Append(Q(c.Documentation)).Append(", ").Append(ownerPkg).Append(", ").Append(Q(stereotype))
                  .Append(", ").Append(Q(c.IsAbstract ? "1" : "0")).Append(", ").Append(Q("Public")).Append(", ")
                  .Append(c.Type == IxElementType.Boundary ? 1 : 0).Append(", ")
                  .Append(Q(Guid_(c.ExternalUuid))).Append(");\n");
            }
            foreach (var p in packages)
            {
                long id = mirrorObjId[p.Id];
                long ownerPkg = ParentPackageId(p.ParentId);   // mirror lives in the package's PARENT (doc §4.1)
                long represented = pkgIdOf[p.Id];
                sb.Append("INSERT INTO t_object (Object_ID, Object_Type, Name, Package_ID, PDATA1, ea_guid) VALUES (")
                  .Append(id).Append(", ").Append(Q("Package")).Append(", ").Append(Q(p.Name)).Append(", ")
                  .Append(ownerPkg).Append(", ").Append(Q(represented.ToString(CultureInfo.InvariantCulture)))
                  .Append(", ").Append(Q(Guid_(null))).Append(");\n");
            }

            // 3) t_attribute / t_operation
            var paramLines = new StringBuilder();
            foreach (var c in classifiers)
            {
                long objId = objIdOf[c.Id];

                if (c.Type == IxElementType.Enum)
                {
                    int pos = 0;
                    foreach (var lit in c.EnumLiterals)
                    {
                        sb.Append("INSERT INTO t_attribute (ID, Object_ID, Name, Scope, Pos, ea_guid) VALUES (")
                          .Append(nextAttr++).Append(", ").Append(objId).Append(", ").Append(Q(lit)).Append(", ")
                          .Append(Q("Public")).Append(", ").Append(pos++).Append(", ").Append(Q(Guid_(null)))
                          .Append(");\n");
                    }
                }

                int attrPos = 0, opPos = 0;
                foreach (var mem in c.Members)
                {
                    if (mem == null) continue;
                    if (!mem.IsOperation)
                    {
                        if (c.Type == IxElementType.Enum) continue; // enum fields handled as literals above
                        sb.Append("INSERT INTO t_attribute (ID, Object_ID, Name, Type, Scope, \"Default\", " +
                                  "IsStatic, Pos, ea_guid) VALUES (")
                          .Append(nextAttr++).Append(", ").Append(objId).Append(", ").Append(Q(mem.Name)).Append(", ")
                          .Append(Q(mem.Type)).Append(", ").Append(Q(VisibilityOf(mem.Visibility))).Append(", ")
                          .Append(Q(mem.DefaultValue)).Append(", ").Append(mem.IsStatic ? 1 : 0).Append(", ")
                          .Append(attrPos++).Append(", ").Append(Q(Guid_(mem.ExternalUuid))).Append(");\n");
                    }
                    else
                    {
                        long opId = nextOp++;
                        sb.Append("INSERT INTO t_operation (OperationID, Object_ID, Name, Type, Scope, IsStatic, " +
                                  "Abstract, Pos, ea_guid) VALUES (")
                          .Append(opId).Append(", ").Append(objId).Append(", ").Append(Q(mem.Name)).Append(", ")
                          .Append(Q(mem.Type)).Append(", ").Append(Q(VisibilityOf(mem.Visibility))).Append(", ")
                          .Append(Q(mem.IsStatic ? "1" : "0")).Append(", ").Append(Q(mem.IsAbstract ? "1" : "0"))
                          .Append(", ").Append(opPos++).Append(", ").Append(Q(Guid_(mem.ExternalUuid))).Append(");\n");

                        var seenParam = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        int pPos = 0;
                        foreach (var prm in mem.Parameters)
                        {
                            if (prm == null) continue;
                            string pname = string.IsNullOrEmpty(prm.Name) ? "param" + pPos : prm.Name;
                            while (!seenParam.Add(pname)) pname += "_"; // composite PK (OperationID,Name) must be unique
                            paramLines.Append("INSERT INTO t_operationparams (OperationID, Name, Type, Kind, " +
                                              "\"Default\", Pos, ea_guid) VALUES (")
                                .Append(opId).Append(", ").Append(Q(pname)).Append(", ").Append(Q(prm.Type)).Append(", ")
                                .Append(Q(prm.Direction)).Append(", ").Append(Q(prm.DefaultValue)).Append(", ")
                                .Append(pPos++).Append(", ").Append(Q(Guid_(null))).Append(");\n");
                        }
                    }
                }
            }

            // 3b) t_objectproperties (element tagged values)
            foreach (var c in classifiers)
            {
                if (c.Tags == null || c.Tags.Count == 0) continue;
                long objId = objIdOf[c.Id];
                foreach (var kv in c.Tags)
                {
                    if (string.IsNullOrEmpty(kv.Key)) continue;
                    sb.Append("INSERT INTO t_objectproperties (PropertyID, Object_ID, Property, Value, ea_guid) VALUES (")
                      .Append(nextProp++).Append(", ").Append(objId).Append(", ").Append(Q(kv.Key)).Append(", ")
                      .Append(Q(kv.Value)).Append(", ").Append(Q(Guid_(null))).Append(");\n");
                }
            }

            // 4) t_operationparams (after all operations exist)
            sb.Append(paramLines.ToString());

            // 4b) t_connector
            foreach (var e in model.Edges)
            {
                if (e == null || e.FromId == null || e.ToId == null) continue;
                if (!objIdOf.TryGetValue(e.FromId, out long fromObj)) continue;
                if (!objIdOf.TryGetValue(e.ToId, out long toObj)) continue;

                bool agg = e.Type == IxEdgeType.Aggregation || e.Type == IxEdgeType.Composition;
                // Reader put From = whole; EA wants the diamond on the End end, so part=Start, whole=End.
                long startObj = agg ? toObj : fromObj;
                long endObj = agg ? fromObj : toObj;
                string srcCard = agg ? e.ToMultiplicity : e.FromMultiplicity;
                string dstCard = agg ? e.FromMultiplicity : e.ToMultiplicity;
                string srcRole = agg ? e.ToRole : e.FromRole;
                string dstRole = agg ? e.FromRole : e.ToRole;
                long dstAgg = e.Type == IxEdgeType.Composition ? 2 : (e.Type == IxEdgeType.Aggregation ? 1 : 0);
                string subType = e.Type == IxEdgeType.Composition ? "Strong" : null;

                sb.Append("INSERT INTO t_connector (Connector_ID, Name, Direction, Connector_Type, SubType, " +
                          "Start_Object_ID, End_Object_ID, SourceCard, DestCard, SourceRole, DestRole, " +
                          "SourceIsAggregate, DestIsAggregate, ea_guid) VALUES (")
                  .Append(nextConn++).Append(", ").Append(Q(e.Label)).Append(", ").Append(Q(DirectionOf(e.Type)))
                  .Append(", ").Append(Q(ConnectorTypeOf(e.Type))).Append(", ").Append(Q(subType)).Append(", ")
                  .Append(startObj).Append(", ").Append(endObj).Append(", ").Append(Q(srcCard)).Append(", ")
                  .Append(Q(dstCard)).Append(", ").Append(Q(srcRole)).Append(", ").Append(Q(dstRole)).Append(", ")
                  .Append(0).Append(", ").Append(dstAgg).Append(", ").Append(Q(Guid_(e.ExternalUuid))).Append(");\n");
            }

            // 5) t_diagram / t_diagramobjects (only when there are diagrams)
            foreach (var d in model.Diagrams)
            {
                if (d == null) continue;
                long diagramId = nextDiagram++;
                sb.Append("INSERT INTO t_diagram (Diagram_ID, Package_ID, Diagram_Type, Name, Orientation, Scale, " +
                          "ShowDetails, ea_guid) VALUES (")
                  .Append(diagramId).Append(", ").Append(RootPackageId).Append(", ")
                  .Append(Q(string.IsNullOrEmpty(d.Kind) ? "Logical" : d.Kind)).Append(", ").Append(Q(d.Name))
                  .Append(", ").Append(Q("P")).Append(", ").Append(100).Append(", ").Append(0).Append(", ")
                  .Append(Q(Guid_(d.Id))).Append(");\n");

                int seq = 0;
                foreach (var n in d.Nodes)
                {
                    if (n == null || n.ElementId == null) continue;
                    if (!objIdOf.TryGetValue(n.ElementId, out long placedObj)) continue;
                    // Inverse of the reader: X->Left, X+W->Right, -Y->Top, -(Y+H)->Bottom (EA Y downward-negative).
                    long left = (long)Math.Round(n.X);
                    long right = (long)Math.Round(n.X + n.Width);
                    long top = (long)Math.Round(-n.Y);
                    long bottom = (long)Math.Round(-(n.Y + n.Height));
                    sb.Append("INSERT INTO t_diagramobjects (Instance_ID, Diagram_ID, Object_ID, RectLeft, RectRight, " +
                              "RectTop, RectBottom, Sequence) VALUES (")
                      .Append(nextInstance++).Append(", ").Append(diagramId).Append(", ").Append(placedObj).Append(", ")
                      .Append(left).Append(", ").Append(right).Append(", ").Append(top).Append(", ").Append(bottom)
                      .Append(", ").Append(seq++).Append(");\n");
                }
            }

            // 6) fix AUTOINCREMENT high-water marks
            foreach (var t in new[]
            {
                ("t_package", "Package_ID"), ("t_object", "Object_ID"), ("t_attribute", "ID"),
                ("t_operation", "OperationID"), ("t_connector", "Connector_ID"), ("t_diagram", "Diagram_ID"),
                ("t_diagramobjects", "Instance_ID"), ("t_objectproperties", "PropertyID"),
            })
            {
                sb.Append("UPDATE sqlite_sequence SET seq=(SELECT COALESCE(MAX(").Append(t.Item2)
                  .Append("),0) FROM ").Append(t.Item1).Append(") WHERE name='").Append(t.Item1).Append("';\n");
            }

            sb.Append("COMMIT;\n");

            SqliteCli.Execute(outputPath, sb.ToString());
        }

        // -------------------------------------------------------------------- IR -> EA mapping

        private static string ObjectTypeOf(IxElementType t)
        {
            switch (t)
            {
                case IxElementType.Table: return "Class";
                case IxElementType.Struct: return "Class";
                case IxElementType.Class: return "Class";
                case IxElementType.Interface: return "Interface";
                case IxElementType.Enum: return "Enumeration";
                case IxElementType.DataType: return "DataType";
                case IxElementType.Note: return "Note";
                case IxElementType.Artifact: return "Artifact";
                case IxElementType.Boundary: return "Boundary";
                case IxElementType.Actor: return "Actor";
                default: return "Class"; // Unknown falls back to Class (keeps any stereotype)
            }
        }

        private static string StereotypeOf(IxElement c)
        {
            if (c.Type == IxElementType.Table) return string.IsNullOrEmpty(c.Stereotype) ? "table" : c.Stereotype;
            if (c.Type == IxElementType.Struct) return string.IsNullOrEmpty(c.Stereotype) ? "struct" : c.Stereotype;
            return string.IsNullOrEmpty(c.Stereotype) ? null : c.Stereotype;
        }

        private static string VisibilityOf(IxVisibility v)
        {
            switch (v)
            {
                case IxVisibility.Private: return "Private";
                case IxVisibility.Protected: return "Protected";
                case IxVisibility.Package: return "Package";
                default: return "Public";
            }
        }

        private static string ConnectorTypeOf(IxEdgeType t)
        {
            switch (t)
            {
                case IxEdgeType.Association: return "Association";
                case IxEdgeType.DirectedAssociation: return "Association";
                case IxEdgeType.Aggregation: return "Aggregation";
                case IxEdgeType.Composition: return "Aggregation";
                case IxEdgeType.Generalization: return "Generalization";
                case IxEdgeType.Realization: return "Realisation"; // EA spells it the British way
                case IxEdgeType.Dependency: return "Dependency";
                case IxEdgeType.NoteLink: return "NoteLink";
                case IxEdgeType.Extension: return "Extension";
                default: return "Dependency"; // Unknown falls back to a neutral relationship
            }
        }

        // Only Association is disambiguated by Direction on read; the rest set a harmless directed default.
        private static string DirectionOf(IxEdgeType t)
        {
            switch (t)
            {
                case IxEdgeType.DirectedAssociation:
                case IxEdgeType.Generalization:
                case IxEdgeType.Realization:
                case IxEdgeType.Dependency:
                case IxEdgeType.Extension:
                    return "Source -> Destination";
                default:
                    return "Unspecified";
            }
        }

        // -------------------------------------------------------------------- SQL helpers

        private static string Q(string s) => s == null ? "NULL" : "'" + s.Replace("'", "''") + "'";

        private static long P(string[] row, int i, long fallback)
        {
            if (row == null || i >= row.Length) return fallback;
            return long.TryParse(row[i], NumberStyles.Integer, CultureInfo.InvariantCulture, out long n) ? n : fallback;
        }
    }
}
