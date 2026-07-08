using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.State
{
    /// <summary>
    /// The in-code baseline of system-owned aspect definitions. These are always present, <c>SystemOwned=true</c>,
    /// and serve as the predefined-scope ladder (global / per-ElementKind / per-ElementKind+GraphType) plus a few
    /// examples (<c>rank</c>, <c>ranking</c>, <c>user-ranking</c>). A user edit writes a new version to the
    /// SQLite registry (see <see cref="AspectRegistry"/>); "revert to system" resets the head back to version 1.
    /// Mirrors the <c>GlobalCatalog.DefaultStereotypes</c> pattern.
    /// </summary>
    public static class SystemAspects
    {
        /// <summary>The baseline system aspect definitions (version 1, SystemOwned). Never mutated.</summary>
        public static readonly AspectDef[] Defaults = Build();

        private static AspectDef[] Build()
        {
            var list = new List<AspectDef>();

            // --- a global aspect every node gets (system baseline) ---
            list.Add(Def("note", "Free-text note attached to any element.", AspectScope.Global,
                emit: new EmitFlags(false, false, true, true), // comment + meta
                Field("text", AspectFieldType.String, @default: "", locked: false)));

            // --- the user's worked example: a ranking aspect with typed fields ---
            list.Add(Def("rank", "Popularity ranking derived from votes.", AspectScope.Global,
                emit: new EmitFlags(true, true, false, true), // annotate + doc-tag + meta
                Field("votes", AspectFieldType.Int, @default: "0", locked: false),
                Field("average", AspectFieldType.Float, @default: "0.0", locked: false),
                Field("scale", AspectFieldType.Int, @default: "5", locked: true))); // scale is fixed

            list.Add(Def("ranking", "Named ranking category an element belongs to (e.g. china).", AspectScope.Global,
                emit: new EmitFlags(true, false, false, true),
                Field("category", AspectFieldType.Options, "cn,us,eu,jp", "cn", locked: false),
                Field("weight", AspectFieldType.Float, @default: "1.0", locked: false)));

            list.Add(Def("user-ranking", "Per-user ranking override on a node.", AspectScope.Global,
                emit: new EmitFlags(true, true, false, true),
                Field("user", AspectFieldType.String, @default: "", locked: false),
                Field("rank", AspectFieldType.Float, @default: "0.0", locked: false)));

            // --- a per-ElementKind example: ERD database tables get an ERD aspect (EntityTable, not the wireframe Table widget) ---
            list.Add(Def("erd-table", "ERD table metadata.", AspectScope.ElementType, ElementKind.EntityTable,
                emit: new EmitFlags(false, false, true, true),
                Field("schema", AspectFieldType.String, @default: "public", locked: false),
                Field("engine", AspectFieldType.Options, "postgres,mysql,sqlite", "postgres", locked: false)));

            // --- a per-ElementKind+GraphType example: Class nodes in an ERD graph ---
            list.Add(Def("erd-entity", "Entity-in-ERD-graph metadata.", AspectScope.ElementTypeAndGraph,
                ElementKind.Class, GraphType.Erd,
                emit: new EmitFlags(false, true, true, true),
                Field("historized", AspectFieldType.Bool, @default: "false", locked: false)));

            return list.ToArray();
        }

        // --- builder helpers keep Defaults terse ---

        private static AspectDef Def(string name, string description, AspectScope scope,
            EmitFlags emit, params AspectFieldDef[] fields)
        {
            return new AspectDef
            {
                Name = name,
                Description = description,
                Scope = scope,
                Emit = emit,
                Fields = new List<AspectFieldDef>(fields),
                Version = 1,
                SystemOwned = true,
            };
        }

        private static AspectDef Def(string name, string description, AspectScope scope,
            ElementKind elementType, EmitFlags emit, params AspectFieldDef[] fields)
        {
            var d = Def(name, description, scope, emit, fields);
            d.ElementType = elementType;
            return d;
        }

        private static AspectDef Def(string name, string description, AspectScope scope,
            ElementKind elementType, GraphType graphType, EmitFlags emit, params AspectFieldDef[] fields)
        {
            var d = Def(name, description, scope, elementType, emit, fields);
            d.GraphType = graphType;
            return d;
        }

        private static AspectFieldDef Field(string name, AspectFieldType type,
            string restriction = null, string @default = null, bool locked = false)
        {
            return new AspectFieldDef
            {
                Name = name,
                Type = type,
                Restriction = restriction,
                Default = @default,
                Locked = locked,
            };
        }
    }
}
