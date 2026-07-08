using System;
using System.Collections.Generic;
using System.Globalization;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Reads a Sparx Enterprise Architect <c>.qea</c> project (a SQLite database) into the format-neutral
    /// <see cref="IxModel"/> IR. See <c>docs/formats/qea-format.md</c> for the reverse-engineered schema.
    ///
    /// <para>The reader shells out to <c>sqlite3</c> (<see cref="SqliteCli"/>) rather than binding a managed
    /// driver. It touches only model tables — <c>t_package</c>, <c>t_object</c>, <c>t_attribute</c>,
    /// <c>t_operation(+params)</c>, <c>t_connector</c>, <c>t_diagram(+objects)</c>, <c>t_objectproperties</c> —
    /// and ignores the security/system/seed tables.</para>
    ///
    /// <para><b>Identity.</b> A model element's <see cref="IxElement.Id"/> and <see cref="IxElement.ExternalUuid"/>
    /// are both the EA <c>ea_guid</c>. Numeric EA IDs are file-local FK currency and never leak into the IR.</para>
    ///
    /// <para><b>Package mirrors.</b> Every non-root package is mirrored by a <c>t_object</c> row of
    /// <c>Object_Type='Package'</c> so it can appear on diagrams / own connectors. Those mirror rows are not emitted
    /// as elements; instead the reader maps <c>mirror Object_ID → the package's ea_guid</c> so connectors and diagram
    /// placements that reference a mirror resolve to the package element.</para>
    ///
    /// <para><b>NULL vs empty.</b> The reader treats a SQL NULL and an empty string identically (both mean "absent"
    /// for every UML field here), so it reads columns directly and collapses empties to null via <see cref="S"/>;
    /// it does not need <see cref="SqliteCli.NullSentinel"/>.</para>
    /// </summary>
    public static class EaQeaReader
    {
        public static IxModel Read(string qeaPath)
        {
            if (string.IsNullOrEmpty(qeaPath)) throw new InterchangeException("EaQeaReader.Read: null path");

            var model = new IxModel();

            // ---- packages: build the tree, pick the root, emit the rest as Package elements -------------------
            var pkgName = new Dictionary<long, string>();
            var pkgParent = new Dictionary<long, long>();
            var pkgGuid = new Dictionary<long, string>();
            long rootPackageId = long.MaxValue;

            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Package_ID, Parent_ID, Name, ea_guid FROM t_package ORDER BY Package_ID;"))
            {
                long id = L(r, 0);
                long parent = L(r, 1);
                pkgName[id] = S(F(r, 2));
                pkgParent[id] = parent;
                pkgGuid[id] = S(F(r, 3));
                if (parent == 0 && id < rootPackageId) rootPackageId = id; // EA's model root is the lowest Parent_ID=0 (==1)
            }
            if (rootPackageId == long.MaxValue)
                throw new InterchangeException("EaQeaReader: no root package (t_package has no Parent_ID=0 row)");

            model.Name = pkgName.TryGetValue(rootPackageId, out var rn) ? rn : "Model";

            bool IsRootRef(long pkgId) => pkgId == 0 || pkgId == rootPackageId;
            string PackageParentId(long parentPkgId) =>
                IsRootRef(parentPkgId) ? null : (pkgGuid.TryGetValue(parentPkgId, out var g) ? g : null);

            foreach (var kv in pkgGuid)
            {
                long id = kv.Key;
                if (id == rootPackageId) continue;
                model.Elements.Add(new IxElement
                {
                    Id = kv.Value,
                    ExternalUuid = kv.Value,
                    Type = IxElementType.Package,
                    Name = pkgName[id],
                    ParentId = PackageParentId(pkgParent[id]),
                });
            }

            // ---- objects: classifiers/notes/etc as elements; Package mirrors only feed the resolution map -----
            // objectGuid maps any Object_ID (classifier OR package mirror) to the ea_guid a connector/placement
            // that references it should resolve to.
            var objectGuid = new Dictionary<long, string>();
            var elementByObjectId = new Dictionary<long, IxElement>();

            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Object_ID, Object_Type, Name, Note, Stereotype, Abstract, Package_ID, PDATA1, ea_guid " +
                "FROM t_object;"))
            {
                long objId = L(r, 0);
                string type = S(F(r, 1)) ?? "";
                string name = S(F(r, 2));
                string note = S(F(r, 3));
                string stereotype = S(F(r, 4));
                bool isAbstract = S(F(r, 5)) == "1";
                long ownerPkg = L(r, 6);
                string pdata1 = S(F(r, 7));
                string guid = S(F(r, 8));

                if (string.Equals(type, "Package", StringComparison.OrdinalIgnoreCase))
                {
                    // Mirror: resolve to the represented package's ea_guid (PDATA1 = its Package_ID).
                    if (long.TryParse(pdata1, NumberStyles.Integer, CultureInfo.InvariantCulture, out long reps)
                        && pkgGuid.TryGetValue(reps, out var pg))
                        objectGuid[objId] = pg;
                    continue;
                }

                var el = new IxElement
                {
                    Id = guid,
                    ExternalUuid = guid,
                    Type = MapObjectType(type, stereotype),
                    Name = name,
                    Stereotype = stereotype,
                    IsAbstract = isAbstract,
                    Documentation = note,
                    ParentId = IsRootRef(ownerPkg) ? null : (pkgGuid.TryGetValue(ownerPkg, out var opg) ? opg : null),
                };
                model.Elements.Add(el);
                objectGuid[objId] = guid;
                elementByObjectId[objId] = el;
            }

            // ---- attributes → members (or enum literals for Enumeration elements) ------------------------------
            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Object_ID, ID, Name, Type, \"Default\", Scope, IsStatic, ea_guid " +
                "FROM t_attribute ORDER BY Object_ID, Pos, ID;"))
            {
                long objId = L(r, 0);
                if (!elementByObjectId.TryGetValue(objId, out var owner)) continue;

                string name = S(F(r, 2));
                if (owner.Type == IxElementType.Enum)
                {
                    if (!string.IsNullOrEmpty(name)) owner.EnumLiterals.Add(name);
                    continue;
                }

                owner.Members.Add(new IxMember
                {
                    IsOperation = false,
                    Name = name,
                    Type = S(F(r, 3)),
                    DefaultValue = S(F(r, 4)),
                    Visibility = MapVisibility(S(F(r, 5))),
                    IsStatic = S(F(r, 6)) == "1",
                    ExternalUuid = S(F(r, 7)),
                });
            }

            // ---- operations → members, then params -------------------------------------------------------------
            var operationById = new Dictionary<long, IxMember>();
            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT OperationID, Object_ID, Name, Type, Scope, IsStatic, Abstract, ea_guid " +
                "FROM t_operation ORDER BY Object_ID, Pos, OperationID;"))
            {
                long opId = L(r, 0);
                long objId = L(r, 1);
                if (!elementByObjectId.TryGetValue(objId, out var owner)) continue;

                var op = new IxMember
                {
                    IsOperation = true,
                    Name = S(F(r, 2)),
                    Type = S(F(r, 3)),
                    Visibility = MapVisibility(S(F(r, 4))),
                    IsStatic = S(F(r, 5)) == "1",
                    IsAbstract = S(F(r, 6)) == "1",
                    ExternalUuid = S(F(r, 7)),
                };
                owner.Members.Add(op);
                operationById[opId] = op;
            }

            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT OperationID, Name, Type, Kind, \"Default\" FROM t_operationparams ORDER BY OperationID, Pos;"))
            {
                long opId = L(r, 0);
                if (!operationById.TryGetValue(opId, out var op)) continue;
                op.Parameters.Add(new IxParam
                {
                    Name = S(F(r, 1)),
                    Type = S(F(r, 2)),
                    Direction = S(F(r, 3)),
                    DefaultValue = S(F(r, 4)),
                });
            }

            // ---- element tagged values -------------------------------------------------------------------------
            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Object_ID, Property, Value FROM t_objectproperties ORDER BY PropertyID;"))
            {
                long objId = L(r, 0);
                if (!elementByObjectId.TryGetValue(objId, out var owner)) continue;
                string prop = S(F(r, 1));
                if (string.IsNullOrEmpty(prop)) continue;
                owner.Tags[prop] = S(F(r, 2)) ?? "";
            }

            // ---- connectors → edges ----------------------------------------------------------------------------
            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Connector_ID, Name, Direction, Connector_Type, SubType, Start_Object_ID, End_Object_ID, " +
                "SourceCard, DestCard, SourceRole, DestRole, SourceIsAggregate, DestIsAggregate, ea_guid " +
                "FROM t_connector;"))
            {
                long startId = L(r, 5), endId = L(r, 6);
                if (!objectGuid.TryGetValue(startId, out var startGuid)) continue;
                if (!objectGuid.TryGetValue(endId, out var endGuid)) continue;

                string eaType = S(F(r, 3)) ?? "";
                string direction = S(F(r, 2));
                string subType = S(F(r, 4));
                long srcAgg = L(r, 11), dstAgg = L(r, 12);
                var type = MapConnectorType(eaType, direction, subType, srcAgg, dstAgg);

                string srcCard = S(F(r, 7)), dstCard = S(F(r, 8));
                string srcRole = S(F(r, 9)), dstRole = S(F(r, 10));

                // Aggregation/Composition: EA marks the whole/diamond end with the aggregate flag (and defaults it to
                // the target/End end). The IR wants From = whole, To = part, so swap ends + cards + roles when the
                // whole is the End. (No aggregations exist in the fixture — this path follows the doc, unverified.)
                bool wholeIsStart = srcAgg != 0 && dstAgg == 0;
                bool swap = (type == IxEdgeType.Aggregation || type == IxEdgeType.Composition) && !wholeIsStart;

                var edge = new IxEdge
                {
                    Id = startGuid + "->" + endGuid, // stable-enough local id; ExternalUuid carries EA identity
                    ExternalUuid = S(F(r, 13)),
                    Type = type,
                    FromId = swap ? endGuid : startGuid,
                    ToId = swap ? startGuid : endGuid,
                    Label = S(F(r, 1)),
                    FromMultiplicity = swap ? dstCard : srcCard,
                    ToMultiplicity = swap ? srcCard : dstCard,
                    FromRole = swap ? dstRole : srcRole,
                    ToRole = swap ? srcRole : dstRole,
                };
                model.Edges.Add(edge);
            }

            // ---- diagrams + placements -------------------------------------------------------------------------
            var diagramById = new Dictionary<long, IxDiagram>();
            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Diagram_ID, Name, Diagram_Type, ea_guid FROM t_diagram ORDER BY Diagram_ID;"))
            {
                long dId = L(r, 0);
                var d = new IxDiagram
                {
                    Id = S(F(r, 3)),
                    Name = S(F(r, 1)),
                    Kind = S(F(r, 2)),
                    LayoutProvenance = IxLayoutProvenance.Authored, // coordinates come straight from EA
                };
                model.Diagrams.Add(d);
                diagramById[dId] = d;
            }

            foreach (var r in SqliteCli.Query(qeaPath,
                "SELECT Diagram_ID, Object_ID, RectLeft, RectRight, RectTop, RectBottom " +
                "FROM t_diagramobjects ORDER BY Diagram_ID, Instance_ID;"))
            {
                long dId = L(r, 0), objId = L(r, 1);
                if (!diagramById.TryGetValue(dId, out var d)) continue;
                if (!objectGuid.TryGetValue(objId, out var g)) continue;

                // EA Y grows downward as increasingly negative: RectTop > RectBottom, both usually negative.
                // Normalize to the IR's top-left / Y-downward-positive convention.
                float left = L(r, 2), right = L(r, 3), top = L(r, 4), bottom = L(r, 5);
                d.Nodes.Add(new IxNodePlacement
                {
                    ElementId = g,
                    X = left,
                    Y = -top,
                    Width = right - left,
                    Height = top - bottom,
                });
            }

            return model;
        }

        // -------------------------------------------------------------------- mapping helpers

        private static IxElementType MapObjectType(string objectType, string stereotype)
        {
            switch ((objectType ?? "").Trim().ToLowerInvariant())
            {
                case "class":
                    return string.Equals(stereotype, "table", StringComparison.OrdinalIgnoreCase)
                        ? IxElementType.Table : IxElementType.Class;
                case "interface": return IxElementType.Interface;
                case "enumeration": return IxElementType.Enum;
                case "note": return IxElementType.Note;
                case "boundary": return IxElementType.Boundary;
                case "artifact": return IxElementType.Artifact;
                case "actor": return IxElementType.Actor;
                default: return IxElementType.Unknown;
            }
        }

        private static IxVisibility MapVisibility(string scope)
        {
            switch ((scope ?? "").Trim().ToLowerInvariant())
            {
                case "private": return IxVisibility.Private;
                case "protected": return IxVisibility.Protected;
                case "package": return IxVisibility.Package;
                default: return IxVisibility.Public;
            }
        }

        private static IxEdgeType MapConnectorType(string ct, string direction, string subType, long srcAgg, long dstAgg)
        {
            switch ((ct ?? "").Trim().ToLowerInvariant())
            {
                case "association":
                    return string.Equals(direction, "Source -> Destination", StringComparison.OrdinalIgnoreCase)
                        ? IxEdgeType.DirectedAssociation : IxEdgeType.Association;
                case "aggregation":
                    bool composite = string.Equals(subType, "Strong", StringComparison.OrdinalIgnoreCase)
                        || string.Equals(subType, "Composite", StringComparison.OrdinalIgnoreCase)
                        || srcAgg == 2 || dstAgg == 2;
                    return composite ? IxEdgeType.Composition : IxEdgeType.Aggregation;
                case "generalization": return IxEdgeType.Generalization;
                case "realisation":
                case "realization": return IxEdgeType.Realization;
                case "dependency":
                case "usage": return IxEdgeType.Dependency;
                case "notelink": return IxEdgeType.NoteLink;
                case "extension": return IxEdgeType.Extension;
                default: return IxEdgeType.Unknown;
            }
        }

        // -------------------------------------------------------------------- cell accessors

        private static string F(string[] row, int i) => i < row.Length ? row[i] : null;

        // Collapse NULL sentinel and empty string to null (both = "absent" in this IR).
        private static string S(string cell)
        {
            if (cell == null || cell.Length == 0) return null;
            if (cell == SqliteCli.NullSentinel) return null;
            return cell;
        }

        private static long L(string[] row, int i)
        {
            string v = F(row, i);
            return long.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out long n) ? n : 0;
        }
    }
}
