using System;
using System.Collections.Generic;

namespace TheRobotDraft.Authoring.Interchange
{
    // Format-neutral interchange IR (docs/specs/file-formats.md §7). Readers parse a
    // foreign format into an IxModel; writers emit a foreign format from one. Format
    // code never touches AuthoringModel/UmlCanvas — materialization lives in the
    // UmlCanvas.Interchange partial, which is the only place Ix* maps to ElementKind,
    // EdgeKind, and UmlMemberSignature.
    //
    // Contract implemented by the format modules in this folder:
    //   PlantUmlReader.Parse(string text)                       -> IxModel
    //   PlantUmlWriter.Write(IxModel model)                     -> string
    //   XmiReader.Parse(string xml)                             -> IxModel
    //   XmiWriter.Write(IxModel model)                          -> string
    //   MermaidReader.Parse(string text)                        -> IxModel
    //   MermaidWriter.Write(IxModel model)                      -> string
    //   EaQeaReader.Read(string qeaPath)                        -> IxModel
    //   EaQeaWriter.Write(IxModel model, string templatePath, string outputPath)
    // All throw InterchangeException on malformed/unsupported input.
    // Readers populate element colors only when the source carries them; writers
    // emit styling deterministically from the color fields (never invent colors).

    public sealed class InterchangeException : Exception
    {
        public InterchangeException(string message) : base(message) { }
        public InterchangeException(string message, Exception inner) : base(message, inner) { }
    }

    public enum IxElementType
    {
        Package, Class, Interface, Enum, Struct, DataType,
        Table,      // ERD entity (EA Class stereotyped «table»)
        Note, Artifact, Boundary, Actor,
        Unknown
    }

    public enum IxEdgeType
    {
        Association, DirectedAssociation, Aggregation, Composition,
        Generalization, Realization, Dependency, NoteLink, Extension,
        Unknown
    }

    public enum IxVisibility { Public, Private, Protected, Package }

    public enum IxLayoutProvenance { Authored, Synthesized }

    public sealed class IxModel
    {
        public string Name;
        public List<IxElement> Elements = new List<IxElement>();
        public List<IxEdge> Edges = new List<IxEdge>();
        public List<IxDiagram> Diagrams = new List<IxDiagram>();
    }

    public sealed class IxElement
    {
        public string Id;                 // format-local id (PlantUML alias, xmi:id, ea_guid) — unique within the model
        public string ExternalUuid;       // stable external identity (EA GUID / xmi:id) preserved into DeepLinkUuid for round-trips
        public IxElementType Type = IxElementType.Class;
        public string Name;               // display name (no signature encoding)
        public string ParentId;           // enclosing package/classifier Id; null = model root
        public string Stereotype;
        public bool IsAbstract;
        public string Documentation;
        public string GenericParams;      // e.g. "T" or "K,V"; null when non-generic
        public List<IxMember> Members = new List<IxMember>();
        public List<string> EnumLiterals = new List<string>();
        public Dictionary<string, string> Tags = new Dictionary<string, string>(); // tagged values / format extras
        // Visual styling, "#RRGGBB" (or null = format/tool default). Populated on
        // parse only when the source declares it; emitted deterministically on write.
        public string FillColor;
        public string LineColor;
        public string TextColor;
        public string StyleClass;         // source style-class name (e.g. Mermaid classDef) for stable re-emission
    }

    public sealed class IxMember
    {
        public bool IsOperation;          // false = field/attribute
        public IxVisibility Visibility = IxVisibility.Public;
        public string Name;
        public string Type;               // field type or operation return type; null = untyped/void
        public bool IsStatic;
        public bool IsAbstract;
        public string DefaultValue;
        public List<IxParam> Parameters = new List<IxParam>(); // operations only
        public string RawText;            // original source text, kept for lossless round-trip when parsing is heuristic
        public string ExternalUuid;
    }

    public sealed class IxParam
    {
        public string Name;
        public string Type;
        public string Direction;          // "in" | "out" | "inout" | "return" | null
        public string DefaultValue;
    }

    public sealed class IxEdge
    {
        public string Id;
        public string ExternalUuid;
        public IxEdgeType Type = IxEdgeType.Association;
        // Direction convention (normalize on parse, denormalize on write):
        //   Generalization: From = child/specific, To = parent/general
        //   Realization:    From = implementing classifier, To = interface
        //   Composition/Aggregation: From = whole/owner (diamond side), To = part
        //   DirectedAssociation/Dependency: From = source, To = target (arrow at To)
        public string FromId;
        public string ToId;
        public string Label;
        public string FromMultiplicity;   // e.g. "1", "0..*"
        public string ToMultiplicity;
        public string FromRole;
        public string ToRole;
    }

    public sealed class IxDiagram
    {
        public string Id;
        public string Name;
        public string Kind;               // source-format diagram kind, free text (e.g. "Logical", "Package")
        public IxLayoutProvenance LayoutProvenance = IxLayoutProvenance.Synthesized;
        public List<IxNodePlacement> Nodes = new List<IxNodePlacement>();
    }

    public sealed class IxNodePlacement
    {
        public string ElementId;          // IxElement.Id
        public float X;                   // top-left, Y grows downward
        public float Y;
        public float Width;
        public float Height;
    }
}
