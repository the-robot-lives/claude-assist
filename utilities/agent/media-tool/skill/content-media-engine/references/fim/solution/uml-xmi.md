# XMI (XML Metadata Interchange) — tool-neutral UML/MOF model serialization

XMI is the OMG standard XML syntax for serializing MOF-based metadata — in practice, UML models exchanged between modeling tools. It is a **model** interchange format, not a rendering format: a valid XMI file fully describes classes, associations, operations, and packages, but carries **no diagram geometry** unless an optional Diagram Interchange (`di`) block or a tool-specific extension is appended. Consumers are desktop modelers (Enterprise Architect, MagicDraw/Cameo, Papyrus, StarUML, Visual Paradigm) and code/model-transformation toolchains (Eclipse UML2/EMF, Acceleo, ATL).

**Current Version**: XMI 2.5.1 (OMG formal/2015-06-07); UML metamodel 2.5.1 (`20131001` namespace token)  **License**: OMG open specification (royalty-free)  **Runtime**: pure XML — parse with any XML/EMF/DOM library; no browser runtime

## Official Resources & Documentation
- **XMI Specification**: https://www.omg.org/spec/XMI/
- **UML Specification**: https://www.omg.org/spec/UML/
- **MOF (metamodel foundation)**: https://www.omg.org/spec/MOF/
- **Eclipse UML2 (reference implementation)**: https://projects.eclipse.org/projects/modeling.mdt.uml2
- **Eclipse Papyrus (open modeler)**: https://eclipse.dev/papyrus/
- **Model interchange test cases (OMG MIWG)**: https://github.com/omg-tc/miwg-test-cases
- **StarUML**: https://staruml.io/ · **Visual Paradigm**: https://www.visual-paradigm.com/

## Installation & Setup
XMI is data, not a package. You produce it by exporting from a tool, or author it by hand and import it.

### Consume/produce with Eclipse UML2 (Java / EMF)
```bash
# Eclipse Modeling Tools includes MDT/UML2; or via Maven:
#   org.eclipse.uml2:org.eclipse.uml2.uml
#   org.eclipse.emf:org.eclipse.emf.ecore.xmi
```

### Tool export paths
- **Enterprise Architect**: Project → Model Exchange → Export XMI (choose XMI 2.1 or 2.5.1; EA also writes an EA extension block with geometry).
- **MagicDraw/Cameo**: File → Export To → Eclipse UML2 (v5.x) XMI, or native `.mdzip`.
- **Papyrus / StarUML / Visual Paradigm**: File → Export → XMI.

### Validate a hand-authored file
```bash
xmllint --noout model.xmi          # well-formedness
# Round-trip check: import into Papyrus or EA; if it opens, ids resolve.
```

## Core Syntax / API Reference

### Root element and namespaces
Two legal root shapes exist. Prefer `<uml:Model>` as the document root for a single model (what most modern tools emit); use `<xmi:XMI>` as a wrapper when the document carries multiple top-level elements, profiles, or extensions.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<uml:Model xmi:version="20131001"
           xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
           xmlns:uml="http://www.omg.org/spec/UML/20131001"
           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xmi:id="_model_1" name="OrderDomain">
  <!-- packagedElements go here -->
</uml:Model>
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.1"
         xmlns:xmi="http://www.omg.org/XMI"
         xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML">
  <uml:Model xmi:id="_model_1" name="OrderDomain">
    <!-- ... -->
  </uml:Model>
</xmi:XMI>
```

Namespace tokens differ by lineage and this is the single biggest interchange pitfall:

| Lineage | `xmi:version` | `xmlns:uml` | `xmlns:xmi` |
|---|---|---|---|
| OMG UML 2.5.1 | `20131001` | `http://www.omg.org/spec/UML/20131001` | `http://www.omg.org/spec/XMI/20131001` |
| Eclipse UML2 5.x | `20131001` | `http://www.eclipse.org/uml2/5.0.0/UML` | `http://www.omg.org/spec/XMI/20131001` |
| Legacy XMI 2.1 | `2.1` | `http://www.omg.org/spec/UML/2.1` (or tool URI) | `http://www.omg.org/XMI` |

The element **structure is identical** across these; only the namespace URIs and version token change. When targeting a specific importer, match its expected `xmlns:uml` exactly — Papyrus expects the Eclipse URI, MagicDraw's UML2 export expects the Eclipse URI, EA accepts OMG or its own.

### Identity and referencing
- `xmi:id` — document-unique identifier on every element (tools use `_`-prefixed GUID-like strings). Required for anything referenced.
- `xmi:idref` — a reference to another element **within the same file**.
- `href` — a reference into **another resource** (e.g. the UML PrimitiveTypes library), of the form `resourceURI#fragmentId`.
- `xmi:type` — the metaclass of an element when it appears in a polymorphic containment slot (e.g. a `packagedElement` may be a `uml:Class` or a `uml:Association`). Some tools use `xsi:type` interchangeably; both are accepted by most importers.

### packagedElement — the polymorphic container
`packagedElement` is the containment feature of a Package (and of the Model). Its concrete kind is set by `xmi:type`:

```xml
<packagedElement xmi:type="uml:Package"       xmi:id="_p1"  name="domain"/>
<packagedElement xmi:type="uml:Class"         xmi:id="_c1"  name="Customer"/>
<packagedElement xmi:type="uml:Interface"     xmi:id="_i1"  name="Payable"/>
<packagedElement xmi:type="uml:Association"   xmi:id="_a1"/>
<packagedElement xmi:type="uml:Enumeration"   xmi:id="_e1"  name="Status"/>
<packagedElement xmi:type="uml:DataType"      xmi:id="_d1"  name="Money"/>
<packagedElement xmi:type="uml:PrimitiveType" xmi:id="_pt1" name="Currency"/>
<packagedElement xmi:type="uml:Actor"         xmi:id="_ac1" name="Shopper"/>
<packagedElement xmi:type="uml:UseCase"       xmi:id="_uc1" name="Place Order"/>
<packagedElement xmi:type="uml:Component"     xmi:id="_cm1" name="OrderService"/>
```

### Class members: attributes and operations
A `uml:Class` owns `ownedAttribute` (Property) and `ownedOperation` (Operation). Attribute types are given either by a same-file `type` idref or by an `<type>` child using `href` into a type library.

```xml
<packagedElement xmi:type="uml:Class" xmi:id="_c1" name="Customer">
  <ownedAttribute xmi:type="uml:Property" xmi:id="_c1_id" name="id"
                  visibility="private">
    <type xmi:type="uml:PrimitiveType"
          href="pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#Integer"/>
  </ownedAttribute>
  <ownedAttribute xmi:type="uml:Property" xmi:id="_c1_name" name="name"
                  visibility="private">
    <type xmi:type="uml:PrimitiveType"
          href="pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#String"/>
  </ownedAttribute>
  <ownedOperation xmi:type="uml:Operation" xmi:id="_c1_op1" name="place"
                  visibility="public">
    <ownedParameter xmi:type="uml:Parameter" xmi:id="_c1_op1_p1" name="order"
                    direction="in" type="_c2"/>
    <ownedParameter xmi:type="uml:Parameter" xmi:id="_c1_op1_ret" name="result"
                    direction="return">
      <type xmi:type="uml:PrimitiveType"
            href="pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#Boolean"/>
    </ownedParameter>
  </ownedOperation>
</packagedElement>
```

`direction` on a parameter is `in` (default), `out`, `inout`, or `return`. Exactly one `return` parameter carries the operation's result type.

### Multiplicity
Multiplicity bounds are child elements of the typed element (Property or Parameter), not attributes:

```xml
<ownedAttribute xmi:type="uml:Property" xmi:id="_c1_orders" name="orders" type="_c2">
  <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="_lo1" value="0"/>
  <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="_up1" value="*"/>
</ownedAttribute>
```

- Lower bound uses `uml:LiteralInteger`.
- Upper bound uses `uml:LiteralUnlimitedNatural`; `value="*"` means unbounded. Omitting both defaults to `1..1`.

### Generalization (inheritance)
A specialized classifier owns a `generalization` whose `general` idref points at the supertype.

```xml
<packagedElement xmi:type="uml:Class" xmi:id="_c3" name="VipCustomer">
  <generalization xmi:type="uml:Generalization" xmi:id="_g1" general="_c1"/>
</packagedElement>
```

Interface realization is `interfaceRealization` with `contract` (the interface) and `supplier`/`client` ends:

```xml
<packagedElement xmi:type="uml:Class" xmi:id="_c1" name="Customer">
  <interfaceRealization xmi:type="uml:InterfaceRealization" xmi:id="_ir1"
                        contract="_i1" supplier="_i1" client="_c1"/>
</packagedElement>
```

### Associations
An association names its ends via `memberEnd` idrefs. Ends owned by the association itself are `ownedEnd`; ends that are class attributes are ordinary `ownedAttribute` on the class carrying an `association` back-reference. Both patterns appear in the wild.

```xml
<!-- Class end owned as an attribute, pointing back to the association -->
<packagedElement xmi:type="uml:Class" xmi:id="_c1" name="Customer">
  <ownedAttribute xmi:type="uml:Property" xmi:id="_end_cust2order" name="orders"
                  type="_c2" association="_a1" aggregation="none">
    <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="_l2" value="0"/>
    <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="_u2" value="*"/>
  </ownedAttribute>
</packagedElement>

<packagedElement xmi:type="uml:Association" xmi:id="_a1" name="places">
  <memberEnd xmi:idref="_end_cust2order"/>
  <memberEnd xmi:idref="_end_order2cust"/>
  <!-- the "back" end owned by the association itself -->
  <ownedEnd xmi:type="uml:Property" xmi:id="_end_order2cust" name="customer"
            type="_c1" association="_a1">
    <lowerValue xmi:type="uml:LiteralInteger" xmi:id="_l3" value="1"/>
    <upperValue xmi:type="uml:LiteralInteger" xmi:id="_u3" value="1"/>
  </ownedEnd>
</packagedElement>
```

Aggregation is expressed on the **owning end** via `aggregation`:
- `aggregation="none"` — plain association (default).
- `aggregation="shared"` — aggregation (hollow diamond).
- `aggregation="composite"` — composition (filled diamond); the composite end is the whole.

Navigability: an end reachable via a class `ownedAttribute` is navigable; an end that is only an `ownedEnd` of the association is non-navigable. `navigableOwnedEnd` idrefs on the association can state this explicitly.

### Enumerations
```xml
<packagedElement xmi:type="uml:Enumeration" xmi:id="_e1" name="OrderStatus">
  <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="_el1" name="PENDING"/>
  <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="_el2" name="PAID"/>
  <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="_el3" name="SHIPPED"/>
</packagedElement>
```

### Referencing primitive types via href
UML PrimitiveTypes (String, Integer, Boolean, Real, UnlimitedNatural) live in a standard library resource. Reference them by `href`. The resource URI is tool-dependent:

```xml
<!-- Eclipse UML2 / Papyrus pathmap -->
<type xmi:type="uml:PrimitiveType"
      href="pathmap://UML_LIBRARIES/UMLPrimitiveTypes.library.uml#String"/>

<!-- OMG canonical URI -->
<type xmi:type="uml:PrimitiveType"
      href="http://www.omg.org/spec/UML/20131001/PrimitiveTypes.xmi#String"/>
```

If your importer does not resolve external libraries, declare your own `uml:PrimitiveType` packagedElements and reference them by same-file idref instead.

## Model Element Types (surface summary)
Structural: `uml:Package`, `uml:Model`, `uml:Class`, `uml:Interface`, `uml:DataType`, `uml:PrimitiveType`, `uml:Enumeration`, `uml:Component`, `uml:Property`, `uml:Operation`, `uml:Parameter`, `uml:Association`, `uml:AssociationClass`. Behavioral/use-case: `uml:Actor`, `uml:UseCase`, `uml:Extend`, `uml:Include`, `uml:Activity`, `uml:StateMachine`. Relationships: `uml:Generalization`, `uml:InterfaceRealization`, `uml:Dependency`, `uml:Realization`, `uml:Usage`. Profiles/stereotypes: `uml:Profile`, `uml:Stereotype`, `uml:Extension`, plus applied-stereotype elements in the profile's own namespace.

## How-To (worked recipes)

### How to model a complete class diagram (two classes + association + inheritance)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<uml:Model xmi:version="20131001"
           xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
           xmlns:uml="http://www.omg.org/spec/UML/20131001"
           xmi:id="_m1" name="Shop">
  <packagedElement xmi:type="uml:Class" xmi:id="_c1" name="Customer">
    <ownedAttribute xmi:type="uml:Property" xmi:id="_c1a1" name="orders" type="_c2"
                    association="_a1" aggregation="none">
      <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="_lv1" value="0"/>
      <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="_uv1" value="*"/>
    </ownedAttribute>
  </packagedElement>
  <packagedElement xmi:type="uml:Class" xmi:id="_c2" name="Order"/>
  <packagedElement xmi:type="uml:Class" xmi:id="_c3" name="VipCustomer">
    <generalization xmi:type="uml:Generalization" xmi:id="_g1" general="_c1"/>
  </packagedElement>
  <packagedElement xmi:type="uml:Association" xmi:id="_a1" name="places">
    <memberEnd xmi:idref="_c1a1"/>
    <memberEnd xmi:idref="_a1e2"/>
    <ownedEnd xmi:type="uml:Property" xmi:id="_a1e2" name="customer" type="_c1"
              association="_a1">
      <lowerValue xmi:type="uml:LiteralInteger" xmi:id="_lv2" value="1"/>
      <upperValue xmi:type="uml:LiteralInteger" xmi:id="_uv2" value="1"/>
    </ownedEnd>
  </packagedElement>
</uml:Model>
```

### How to express a composition (whole owns parts)
```xml
<packagedElement xmi:type="uml:Class" xmi:id="_ord" name="Order">
  <ownedAttribute xmi:type="uml:Property" xmi:id="_ord_lines" name="lines"
                  type="_line" aggregation="composite">
    <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="_cl" value="1"/>
    <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="_cu" value="*"/>
  </ownedAttribute>
</packagedElement>
<packagedElement xmi:type="uml:Class" xmi:id="_line" name="OrderLine"/>
```
The `composite` end is the whole (Order); deleting an Order deletes its OrderLines.

### How to model a use-case slice (actor, use case, association)
```xml
<packagedElement xmi:type="uml:Actor"   xmi:id="_ac1" name="Shopper"/>
<packagedElement xmi:type="uml:UseCase" xmi:id="_uc1" name="Place Order"/>
<packagedElement xmi:type="uml:UseCase" xmi:id="_uc2" name="Authenticate"/>
<packagedElement xmi:type="uml:Association" xmi:id="_uca1">
  <memberEnd xmi:idref="_uca1e1"/>
  <memberEnd xmi:idref="_uca1e2"/>
  <ownedEnd xmi:type="uml:Property" xmi:id="_uca1e1" type="_ac1" association="_uca1"/>
  <ownedEnd xmi:type="uml:Property" xmi:id="_uca1e2" type="_uc1" association="_uca1"/>
</packagedElement>
<!-- «include»: Place Order includes Authenticate -->
<packagedElement xmi:type="uml:UseCase" xmi:id="_uc1b" name="Place Order">
  <include xmi:type="uml:Include" xmi:id="_inc1" addition="_uc2"/>
</packagedElement>
```

### How to apply a stereotype (profile application)
Stereotype instances live in the profile's namespace and reference the base element via `base_<Metaclass>`:
```xml
<xmi:XMI xmi:version="20131001"
         xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
         xmlns:uml="http://www.omg.org/spec/UML/20131001"
         xmlns:ProfileX="http://example.com/profiles/ProfileX">
  <uml:Model xmi:id="_m1" name="Svc">
    <packagedElement xmi:type="uml:Class" xmi:id="_svc" name="OrderService"/>
  </uml:Model>
  <!-- applied stereotype instance -->
  <ProfileX:Service xmi:id="_st1" base_Class="_svc" tier="domain"/>
</xmi:XMI>
```

### How to add diagram layout / control appearance (Diagram Interchange & tool extensions)
Pure XMI has no coordinates, colors, or fonts. Two mechanisms carry appearance, and both are optional add-ons keyed by `xmi:id` back-references into the model:

**1. Tool-specific extension** — the common real-world case. Enterprise Architect writes an `<xmi:Extension extender="Enterprise Architect">` block containing `<diagrams>` with per-element geometry. IDs must match the model elements.
```xml
<xmi:Extension extender="Enterprise Architect" extenderID="6.5">
  <diagrams>
    <diagram xmi:id="_dg1">
      <properties name="Domain Model" type="Logical"/>
      <elements>
        <element geometry="Left=40;Top=60;Right=200;Bottom=160;"
                 subject="_c1" seqno="1"/>
        <element geometry="Left=320;Top=60;Right=460;Bottom=140;"
                 subject="_c2" seqno="2"/>
      </elements>
    </diagram>
  </diagrams>
</xmi:Extension>
```

**2. OMG UML Diagram Interchange (`di` / `umldi`)** — the standardized but less widely round-tripped option. A `Diagram` owns shape/edge nodes whose `modelElement` (or `sharedStyle`/`source`/`target`) idrefs point into the UML model, and each node carries a `Bounds`:
```xml
<xmi:XMI xmi:version="20131001"
         xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
         xmlns:uml="http://www.omg.org/spec/UML/20131001"
         xmlns:umldi="http://www.omg.org/spec/UML/20131001/UMLDI"
         xmlns:di="http://www.omg.org/spec/UML/20131001/DI"
         xmlns:dc="http://www.omg.org/spec/UML/20131001/DC">
  <uml:Model xmi:id="_m1" name="Shop">
    <packagedElement xmi:type="uml:Class" xmi:id="_c1" name="Customer"/>
    <packagedElement xmi:type="uml:Class" xmi:id="_c2" name="Order"/>
  </uml:Model>
  <umldi:UMLDiagram xmi:id="_d1" name="Domain">
    <umldi:UMLShape xmi:id="_s1" modelElement="_c1">
      <dc:Bounds x="40"  y="60" width="160" height="100"/>
    </umldi:UMLShape>
    <umldi:UMLShape xmi:id="_s2" modelElement="_c2">
      <dc:Bounds x="320" y="60" width="140" height="80"/>
    </umldi:UMLShape>
  </umldi:UMLDiagram>
</xmi:XMI>
```
Note the parallel with BPMN's `bpmndi`/`dc`/`di` — same OMG Diagram Definition foundation. Colors/fonts in DI are carried by an optional `di:Style` / `sharedStyle` node; support is thin, so most tools keep appearance in their own extension. **Guidance for machine authoring: emit the model faithfully and, if geometry is needed, prefer the target tool's extension format over generic DI, because DI round-trips poorly across vendors.**

## Do's and Don'ts

### ✅ Do
- Match the importer's exact `xmlns:uml` and `xmi:version` — e.g. `http://www.eclipse.org/uml2/5.0.0/UML` for Papyrus/MagicDraw-UML2, `http://www.omg.org/spec/UML/20131001` for OMG-canonical.
- Give every referenced element a unique `xmi:id`; use stable, meaningful ids (`_Customer`, `_a1e2`) so diffs are readable.
- Set `xmi:type` on every `packagedElement` and every `ownedEnd`/`ownedAttribute` that lives in a polymorphic slot.
- Put multiplicity in `lowerValue`/`upperValue` child elements, using `uml:LiteralUnlimitedNatural value="*"` for the unbounded upper bound.
- Declare aggregation on the correct end: `composite` on the whole.
- Keep model (`uml:*`) and diagram (`umldi`/extension) as separate concerns with matching ids.

### ❌ Don't
- Don't write `type="String"` as a bare name — types must be an idref to a declared type or an `href` into a type library. A literal string is not a resolvable reference.
- Don't mix namespace lineages in one file (OMG `uml:` root but Eclipse `href` pathmaps, or vice-versa) — importers resolve one or the other.
- Don't put `x/y/width/height` on `uml:Class` — geometry belongs in DI/extension nodes, never on model elements.
- Don't dangle idrefs: an `xmi:idref`/`general`/`type`/`memberEnd` pointing at a missing id silently drops the element in most tools.
- Don't assume diagram layout survives a round trip — generic DI is frequently lost; state that layout is best-effort.
- Don't rely on one vendor's stereotype/profile URIs importing into another without the profile resource present.

## Styling, Theming & Customization
Because appearance is out-of-band, "styling" an XMI model means controlling the **Diagram Interchange** payload:
- **Geometry**: `dc:Bounds x/y/width/height` per shape; `di:waypoint` (in DI) or geometry strings (EA extension) per edge.
- **Colors/fonts**: `di:Style` nodes (fill/stroke/font) in standard DI, or tool attributes (EA `<style>`/`appearance`, MagicDraw presentation elements). These are keyed to model ids and are tool-portable only within the emitting tool's family.
- **Diagram set**: multiple `UMLDiagram`/`<diagram>` nodes can reference overlapping model subsets — the model is authored once, laid out many ways.

## Advanced Features
- **Profiles & stereotypes**: `uml:Profile` with `uml:Stereotype` + `uml:Extension`; applied instances in the profile namespace with `base_<Metaclass>`.
- **Model libraries / imports**: `elementImport`, `packageImport`, and `href` into external `.uml` resources let one file reference shared types.
- **MOF beyond UML**: any Ecore/MOF metamodel can be XMI-serialized (Eclipse `.ecore` is XMI); the UML metaclasses shown here are just the most common instance.
- **Transformations**: XMI is the input to MDA pipelines (ATL, QVT, Acceleo) that generate code or other models.

## Common Pitfalls & Troubleshooting
- **Blank import**: usually a namespace mismatch — the importer didn't recognize `xmlns:uml`. Try the tool's exact URI.
- **Types show as `<undefined>`**: unresolved `href` (missing PrimitiveTypes library) or a bare-name `type`. Declare local `uml:PrimitiveType`s and idref them.
- **Associations render but ends are wrong**: `memberEnd` order and `ownedEnd` vs class-owned `ownedAttribute` confusion; ensure each end has a `type` and an `association` back-ref.
- **Lost layout after A→B→A**: expected for generic DI; keep a tool-native copy if geometry matters.
- **XMI 2.1 vs 2.5.1**: older files (`xmi:version="2.1"`, `xmlns:xmi="http://www.omg.org/XMI"`) and newer (`20131001`) are not byte-compatible; convert by re-exporting from a tool that reads both (EA).
- **`xsi:type` vs `xmi:type`**: some emitters use `xsi:type`; declare both `xmlns:xmi` and `xmlns:xsi` and most importers accept either.

## Integration Notes
- **Eclipse EMF/UML2** is the de-facto validation oracle — if Papyrus opens your file, ids resolve.
- **bpmn-moddle-style tooling** does not read XMI; UML and BPMN are different OMG serializations (see bpmn-xml.md).
- For rendering to an image, a modeling tool or an XMI→SVG transform is required; XMI itself is not directly rasterizable.

## Best For / Avoid For
`uml-model-interchange`, `mda`, `model-transformation`, `tool-integration`, `model-repository` — choose XMI when a **semantically complete UML model** must move between tools or feed code generation.

Avoid for: quick human-authored diagrams (use PlantUML/Mermaid), pixel-exact layout portability (extensions are vendor-locked), or anything that only needs a picture. If you want a rendered class diagram from text, PlantUML or Mermaid is far cheaper.

## See Also
- [bpmn-xml.md](bpmn-xml.md) — sibling OMG XML interchange (processes), shares the `dc`/`di` Diagram Interchange foundation
- [plantuml.md](plantuml.md) — text-authored UML; the pragmatic alternative when you don't need model interchange
- [c4-plantuml.md](c4-plantuml.md) — C4 architecture layer over PlantUML
- [structurizr-dsl.md](structurizr-dsl.md) — model-as-code architecture DSL
- [mermaid.md](mermaid.md) — lightweight text diagrams incl. class/use-case
- [../use-case/diagram-generation.md](../use-case/diagram-generation.md) — choosing a diagram/model format for a task
