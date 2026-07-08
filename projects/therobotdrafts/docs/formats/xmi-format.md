# XMI (XML Metadata Interchange) — UML 2.x Interchange Reference

Implementation reference for a C# (`System.Xml`) **importer** and **exporter** of UML 2.x
class models via XMI. Written to interoperate with two real-world flavors:

- **(a) Plain OMG UML 2.5 / XMI 2.x** — what Eclipse UML2/Papyrus, MagicDraw, Modelio,
  and spec-conformant tools emit.
- **(b) Sparx Enterprise Architect "UML 2.x (XMI 2.1)"** — the dominant flavor in the
  wild. EA is our primary interop target; when the two flavors disagree, we favor EA
  compatibility because most `.xmi` files this tool will see come from EA.

> **TL;DR for implementers**
> - **Export target:** XMI 2.1, `<xmi:XMI>` root, `schema.omg.org` namespaces (the exact
>   dialect EA emits and round-trips), **no EA `<xmi:Extension>` block** by default.
> - **Import:** be lenient. Accept both `<xmi:XMI>` and `<uml:Model>` roots, both the
>   `schema.omg.org/spec/UML/2.1` and `www.omg.org/spec/UML/20131001` namespace families,
>   and **three** different ways of writing a type reference. Ignore everything inside
>   `<xmi:Extension>` except (optionally) diagram geometry.
> - Resolve all cross-references in a **second pass** — `xmi:id` targets are frequently
>   defined after the reference that points at them.

---

## 0. Terminology & the one hard rule

XMI serializes a MOF/UML model as XML. Every model element that has identity is an XML
element carrying an `xmi:id` (a document-unique string). Anything that *references* another
element does so by repeating that id — as an attribute value (`general="_id"`), as a nested
element with `xmi:idref="_id"`, or as an `href` into another document.

**The one hard rule that trips up naive parsers:** the element that owns an `xmi:id` and the
elements that reference it can appear in **any order**, and references routinely point
*forward* to ids not yet seen. A single-pass parser that resolves references inline will fail
on real files. Build the id → object map first, resolve references second.

---

## 1. Document structure, namespaces, and versions

### 1.1 Two legal roots

**A. `<xmi:XMI>` wrapper root** (EA always uses this; the spec's canonical form):

```xml
<?xml version="1.0" encoding="windows-1252"?>
<xmi:XMI xmi:version="2.1"
         xmlns:uml="http://schema.omg.org/spec/UML/2.1"
         xmlns:xmi="http://schema.omg.org/spec/XMI/2.1">
  <xmi:Documentation exporter="Enterprise Architect" exporterVersion="6.5"/>
  <uml:Model xmi:type="uml:Model" name="EA_Model" visibility="public">
    <packagedElement .../>
  </uml:Model>
  <xmi:Extension extender="Enterprise Architect" extenderID="6.5">
    ...
  </xmi:Extension>
</xmi:XMI>
```

**B. Bare `<uml:Model>` root** (common from Eclipse-family tools when exporting a single model):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<uml:Model xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI"
           xmlns:uml="http://www.eclipse.org/uml2/5.0.0/UML"
           xmi:id="_model" name="myModel">
  <packagedElement xmi:type="uml:Class" xmi:id="_c1" name="myClass"/>
</uml:Model>
```

An importer must accept **either**: if the document element local-name is `XMI`, descend to
find the child whose local-name is `Model` (or `Package`); if the document element local-name
is `Model`/`Package`/`Profile`, treat it as the model root directly. Do not hard-code the
prefix — match on **local name + namespace**, never on the literal string `uml:Model`.

### 1.2 Namespace families seen in the wild

XMI/UML have used several namespace URIs across versions. These are **not** interchangeable
string-wise but map to the same conceptual metamodel. Match by *family*, not exact string.

| Tool / era | `xmi` namespace | `uml` namespace | `xmi:version` |
|---|---|---|---|
| **EA "UML 2.1 (XMI 2.1)"** (most common) | `http://schema.omg.org/spec/XMI/2.1` | `http://schema.omg.org/spec/UML/2.1` | `2.1` |
| EA newer builds | `http://schema.omg.org/spec/XMI/2.1` | `http://schema.omg.org/spec/UML/2.1.1` | `2.1` |
| OMG canonical UML 2.5 / XMI 2.5.1 | `http://www.omg.org/spec/XMI/20131001` | `http://www.omg.org/spec/UML/20131001` | `2.5` (or absent) |
| OMG interim (2.4.x) | `http://www.omg.org/spec/XMI/20110701` | `http://www.omg.org/spec/UML/20110701` | `2.4.1` |
| Eclipse UML2 / Papyrus | `http://www.omg.org/XMI` | `http://www.eclipse.org/uml2/5.0.0/UML` (or `4.0.0`, `3.0.0`) | `2.0`/`20131001` |
| StarUML 1.x export | `http://schema.omg.org/spec/XMI/2.1` | `http://schema.omg.org/spec/UML/2.0` | `2.1` |

**Importer strategy:** collect the document's namespace declarations; classify each as the
`xmi` family (URI path contains `/XMI` or ends `/XMI`) or the `uml` family (path contains
`/UML` or an Eclipse `.../UML`). Bind an `XmlNamespaceManager` to whatever the file actually
declares. Do **not** assume a fixed prefix — some files use `UML:` (uppercase, XMI 1.x
legacy) and 2.x files use `uml:`. See §2.1 on how to read `xmi:type`, which embeds a prefix.

> The `lutaml/xmi` parser normalizes every input namespace version to a single canonical
> version (`20131001`) before processing. Adopting the same "normalize on read" approach in
> C# keeps the rest of the importer version-agnostic.

### 1.3 `xmi:id`, `xmi:type`, `xmi:idref`

- **`xmi:id`** — document-unique identity of an element. Format is tool-specific and opaque:
  - EA: GUID-derived, prefixed by element kind — `EAID_...` for elements/connectors,
    `EAPK_...` for packages, `EAID_dst...`/`EAID_src...` for association ends, `EAJava_int`
    for its bundled primitive types. Example: `xmi:id="EAID_9A8D9208_9B22_4b92_B666_A175C1D03C7B"`.
    Underscores replace GUID hyphens/braces. **Treat as opaque strings** — never parse them.
  - Eclipse/OMG: `_` + base64-ish token, e.g. `_IXlH8a86EdieaYgxtVWN8Q`, or human tokens
    like `ID_myClass`.
  - StarUML: `AAAAAAFQ8HFzEDDWFvw=` (base64 with trailing `=`).
- **`xmi:type`** — the metaclass of an element, as a **QName** using the `uml`/`xmi` prefix:
  `xmi:type="uml:Class"`, `xmi:type="uml:Property"`, `xmi:type="uml:LiteralInteger"`. Older
  files sometimes use `xmi:type="uml:Class"` on `<packagedElement>` while a few use a bare
  child element name; treat the `xmi:type` attribute as authoritative when present.
  **Some tools emit `xsi:type` instead of `xmi:type`** for the same purpose — accept both.
- **`xmi:idref`** — an in-document reference to another element's `xmi:id`. Used both for real
  model cross-references (`<type xmi:idref="_c2"/>`) and, inside the EA extension, to point a
  duplicate `<element>`/`<connector>` back at its model counterpart.

---

## 2. Model elements (`packagedElement`)

A UML `Package`, `Class`, `Interface`, `Enumeration`, `DataType`, `PrimitiveType`, and
`Association` are all serialized as `<packagedElement>` children, discriminated by
`xmi:type`. Packages nest packagedElements; classes nest their members. This is the entire
containment backbone of a class model.

```xml
<packagedElement xmi:type="uml:Package" xmi:id="EAPK_1" name="Domain" visibility="public">

  <packagedElement xmi:type="uml:Class" xmi:id="_Car" name="Car"
                   visibility="public" isAbstract="false">
    ...members...
  </packagedElement>

  <packagedElement xmi:type="uml:Interface" xmi:id="_IDrivable" name="Drivable"
                   visibility="public"/>

  <packagedElement xmi:type="uml:Enumeration" xmi:id="_Color" name="Color">
    <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="_c_red"   name="RED"/>
    <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="_c_blue"  name="BLUE"/>
  </packagedElement>

  <packagedElement xmi:type="uml:DataType"      xmi:id="_Money"  name="Money"/>
  <packagedElement xmi:type="uml:PrimitiveType" xmi:id="_int"    name="int"/>

  <packagedElement xmi:type="uml:Association"   xmi:id="_assoc1" .../>
</packagedElement>
```

**Common attributes on packagedElements:**

| Attribute | Values | Notes |
|---|---|---|
| `xmi:type` | `uml:Package`, `uml:Class`, `uml:Interface`, `uml:Enumeration`, `uml:DataType`, `uml:PrimitiveType`, `uml:Association`, `uml:AssociationClass`, … | Discriminator. Required in practice. |
| `xmi:id` | opaque string | Required. |
| `name` | string | Optional for anonymous elements (e.g. many associations have no name). |
| `visibility` | `public` \| `private` \| `protected` \| `package` | Optional; default `public`. |
| `isAbstract` | `true` \| `false` | On classes; default `false`. Absent means false. |
| `isLeaf`, `isFinalSpecialization` | `true`/`false` | Usually ignorable. |

**Nesting:** classes may be nested inside classes (`nestedClassifier` in strict UML, but EA
and most tools just place them as further `packagedElement`s inside the owning package).
Packages may nest arbitrarily deep. Build a containment tree keyed by `xmi:id`.

---

## 3. Class members

### 3.1 `ownedAttribute` (`uml:Property`)

```xml
<ownedAttribute xmi:type="uml:Property" xmi:id="_Car_speed" name="speed"
                visibility="private" isStatic="false" isReadOnly="false"
                isDerived="false" isOrdered="false" isUnique="true">
  <!-- TYPE: one of the three forms in §5 -->
  <type xmi:idref="_int"/>
  <!-- MULTIPLICITY: lowerValue / upperValue (see below) -->
  <lowerValue xmi:type="uml:LiteralInteger"           xmi:id="_lv1" value="0"/>
  <upperValue xmi:type="uml:LiteralUnlimitedNatural"  xmi:id="_uv1" value="1"/>
  <!-- DEFAULT VALUE (optional) -->
  <defaultValue xmi:type="uml:LiteralString" xmi:id="_dv1" value="0"/>
</ownedAttribute>
```

Key points:

- **`type`** — three interchangeable encodings; see §5. A property with no type at all is
  legal (untyped) — do not crash.
- **Multiplicity** — encoded as child `<lowerValue>` and `<upperValue>` value-specifications,
  **not** as attributes:
  - `lowerValue` is usually `xmi:type="uml:LiteralInteger"` with `value="0"` or `value="1"`.
  - `upperValue` is usually `xmi:type="uml:LiteralUnlimitedNatural"` with `value="1"` for a
    single-valued end or `value="*"` (sometimes `value="-1"`) for unbounded.
  - **Absent `lowerValue`/`upperValue` means `1..1`.** A common gotcha: EA frequently omits
    both for a plain `0..1` or `1` attribute, and sometimes writes only `upperValue`. Default
    missing lower to 0 or 1 per your policy; missing upper to 1.
  - `value="*"` and `value="-1"` both mean unbounded (`*`) for `LiteralUnlimitedNatural`.
    An absent `value` attribute on a `LiteralUnlimitedNatural` also conventionally means `*`;
    an absent `value` on a `LiteralInteger` means `0`.
- **`isStatic`** — `true`/`false`; default false. (EA also mirrors this in its extension.)
- **`defaultValue`** — a nested value-spec; read `value` when the `xmi:type` is one of
  `uml:LiteralString`, `uml:LiteralInteger`, `uml:LiteralBoolean`, `uml:LiteralReal`,
  `uml:LiteralNull`. For `uml:InstanceValue`/`uml:OpaqueExpression`, read `instance`/`body`.
- `aggregation` on a property means the property is an **association end** (see §4.3), not a
  plain field. `aggregation="none"` = plain reference/field; `composite`/`shared` = it's the
  owning side of a composition/aggregation.
- `association="_assocId"` on a property links it to its owning `uml:Association`.

### 3.2 `ownedOperation` (`uml:Operation`)

```xml
<ownedOperation xmi:type="uml:Operation" xmi:id="_Car_drive" name="drive"
                visibility="public" isStatic="false" isAbstract="false"
                isQuery="false" concurrency="sequential">
  <!-- parameters in declared order; direction distinguishes args from return -->
  <ownedParameter xmi:type="uml:Parameter" xmi:id="_p1" name="distance" direction="in">
    <type xmi:idref="_int"/>
  </ownedParameter>
  <ownedParameter xmi:type="uml:Parameter" xmi:id="_pr" direction="return">
    <type xmi:idref="_bool"/>
  </ownedParameter>
</ownedOperation>
```

- **Parameters** are ordered `<ownedParameter>` children. Their `direction` is
  `in` (default), `inout`, `out`, or **`return`**. The return type is the parameter (or
  parameters) with `direction="return"` — there is normally exactly one; if none exists the
  operation returns void.
- Parameter `type` uses the same three encodings as attributes (§5). Untyped return =
  effectively `void`.
- EA sometimes writes the return as a parameter named `return` and sometimes leaves it
  unnamed — key off `direction`, not the name.
- Parameter multiplicity uses `lowerValue`/`upperValue` exactly like attributes.

### 3.3 `ownedLiteral` (`uml:EnumerationLiteral`)

Children of an `<packagedElement xmi:type="uml:Enumeration">`. Just `xmi:id` + `name`
(order = declaration order). Occasionally carries a `<specification>` value for an explicit
underlying value — usually ignorable for a class model.

---

## 4. Relationships

### 4.1 Generalization (inheritance)

Serialized as a **nested `<generalization>` inside the *specific* (child) classifier**,
pointing at the parent via `general`:

```xml
<packagedElement xmi:type="uml:Class" xmi:id="_SportsCar" name="SportsCar">
  <generalization xmi:type="uml:Generalization" xmi:id="_g1" general="_Car"/>
</packagedElement>
```

- `general="_Car"` is an `xmi:id` reference to the superclass — resolve in pass 2.
- The *specific* end is implicit (it is the owning classifier). Some tools additionally emit
  a redundant `specific="_SportsCar"` attribute — ignore it or use it as a cross-check.
- StarUML instead emits a standalone `<generalization … specific="…" general="…"/>` with
  both ends as attributes. Accept both placements: if `specific` is present use it, else use
  the owning classifier.

### 4.2 Interface realization

A class realizing an interface emits a nested `<interfaceRealization>`:

```xml
<packagedElement xmi:type="uml:Class" xmi:id="_Car" name="Car">
  <interfaceRealization xmi:type="uml:InterfaceRealization" xmi:id="_ir1"
                        client="_Car" supplier="_IDrivable" contract="_IDrivable"/>
</packagedElement>
```

- `contract`/`supplier` → the realized interface's id; `client` → the implementing class.
  Treat `contract` (or `supplier` if `contract` is missing) as the interface reference.
- Some exporters (and XMI 1.x) instead model this as a top-level `uml:Realization` /
  `uml:Dependency` with `client`/`supplier`. Handle the nested form first; optionally sweep
  for standalone realizations.

### 4.3 Associations — the messy part

A `uml:Association` is a `<packagedElement xmi:type="uml:Association">` with **two member
ends**, each of which is a `uml:Property`. The two properties can live in **different
places**, and this is the single biggest source of importer bugs.

Two independent axes:

1. **`memberEnd`** — the association *always* lists its two ends by id:
   ```xml
   <packagedElement xmi:type="uml:Association" xmi:id="_assoc1" name="drives">
     <memberEnd xmi:idref="_end_driver"/>
     <memberEnd xmi:idref="_end_car"/>
   </packagedElement>
   ```
2. **Where each end Property is physically defined** — two options per end:
   - **`ownedEnd`** — the end Property is a child of the `<packagedElement uml:Association>`
     itself (association-owned end; the class does **not** get a field for it).
   - **`ownedAttribute`** — the end Property is a child of the *class* at that end
     (class-owned/navigable end; the class *does* get a field). The property carries
     `association="_assoc1"` back-pointing to the association.

**EA's characteristic pattern** for a navigable-one-direction association: it puts **one end
as an `ownedAttribute` on the class** (the navigable target end) and **the other end as an
`ownedEnd` on the association** (the non-navigable source end). A conformant importer must
gather ends from *both* locations.

Full EA-style example (Car —> Engine, Car navigable to engine, composition):

```xml
<!-- The class owns the navigable end as an attribute -->
<packagedElement xmi:type="uml:Class" xmi:id="_Car" name="Car">
  <ownedAttribute xmi:type="uml:Property" xmi:id="_end_engine" name="engine"
                  visibility="private" association="_assoc1" aggregation="composite">
    <type xmi:idref="_Engine"/>
    <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="_l" value="1"/>
    <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="_u" value="1"/>
  </ownedAttribute>
</packagedElement>

<!-- The association lists both ends and owns the non-navigable one -->
<packagedElement xmi:type="uml:Association" xmi:id="_assoc1">
  <memberEnd xmi:idref="_end_engine"/>
  <memberEnd xmi:idref="_end_car"/>
  <ownedEnd xmi:type="uml:Property" xmi:id="_end_car" name="" visibility="public"
            association="_assoc1" aggregation="none">
    <type xmi:idref="_Car"/>
  </ownedEnd>
</packagedElement>
```

**How to reconstruct an association (algorithm):**

1. For each `uml:Association`, read its two `<memberEnd xmi:idref>` values → `endIdA`, `endIdB`.
2. Resolve each end id to a Property object. That Property is found **either** as an
   `ownedEnd` inside this association **or** as an `ownedAttribute` on some class (which you
   indexed in pass 1). Look in both.
3. Each end Property gives you: its **type** (the classifier at that end), its
   **multiplicity** (`lowerValue`/`upperValue`), its **aggregation** (`none`/`shared`/
   `composite`), and its **owner** (the class it's an attribute of, if any → that end is
   navigable from that class). An end that is an `ownedEnd` on the association (not owned by a
   class) is **non-navigable**.
4. **Navigability:** In UML 2.x, an end is navigable iff its Property is owned by the class at
   the *opposite* end (i.e. is that class's `ownedAttribute`). Ends owned by the association
   (`ownedEnd`) are non-navigable. EA also writes a `navigableOwnedEnd` reference on the
   association for explicitly-navigable association-owned ends — honor it if present. As a
   pragmatic fallback, treat an end whose Property is a class `ownedAttribute` as navigable.
5. **Aggregation → relationship kind:**
   - both ends `aggregation="none"` → plain **association**;
   - one end `aggregation="shared"` → **aggregation** (hollow diamond on the shared end);
   - one end `aggregation="composite"` → **composition** (filled diamond on the composite
     end). The diamond sits on the end that declares the aggregation.

**Direct/attribute-only associations:** many EA class diagrams model a simple "has-a" as a
plain typed `ownedAttribute` with **no** `uml:Association` packagedElement at all (the
attribute's `type` is another class). Treat a class-typed attribute as an implicit
directed association if you want to surface it as an edge.

---

## 5. Type-reference resolution (the three encodings)

A `type` on a Property/Parameter is written one of three ways. **The importer must handle all
three**; the exporter should pick one (we recommend the nested `xmi:idref` form for local
types, `href` for external primitives).

**Form 1 — `type` as an XML attribute (id reference):**
```xml
<ownedAttribute name="speed" type="_int" .../>
```
`type="_int"` is an `xmi:id` reference to a classifier in the same document. (StarUML and some
EA elements use this.) Resolve in pass 2.

**Form 2 — nested `<type>` element with `xmi:idref` (most common, incl. EA local types):**
```xml
<ownedAttribute name="speed">
  <type xmi:idref="_int"/>
</ownedAttribute>
```

**Form 3 — nested `<type>` element with `href` (external / library types):**
```xml
<ownedAttribute name="name">
  <type xmi:type="uml:PrimitiveType"
        href="http://schema.omg.org/spec/UML/2.1/uml.xml#String"/>
</ownedAttribute>
```
The `href` is `documentURI#fragment`. The **fragment after `#`** is the type identity. Seen in
the wild:
- OMG UML primitive library: `...uml.xml#String`, `#Integer`, `#Boolean`, `#Real`,
  `#UnlimitedNatural` — fragment is the human-readable type name.
- Eclipse pathmap: `pathmap://UML2_LIBRARIES/UML2PrimitiveTypes.library.uml2#_IXlH8a86EdieaYgxtVWN8Q`
  — fragment is an opaque id; map by the well-known library URL + a lookup table, or fall
  back to "unresolved external primitive named per the URI's last path segment".

**Resolution algorithm:**
1. If a `type=`/`general=`/`idref` value matches a known local `xmi:id` → bind to that object.
2. Else if it's an `href` with a fragment that names a primitive (`String`/`Integer`/…) →
   bind to a synthetic built-in primitive of that name.
3. Else → keep the raw reference string as an "unresolved external type" placeholder so
   round-trips don't lose data. **Never drop the attribute/operation because its type didn't
   resolve.**

**EA primitive types:** EA bundles a `EA_PrimitiveTypes_Package` (or `Java`/`C#`-flavored
packages) of `<packagedElement xmi:type="uml:PrimitiveType" xmi:id="EAJava_int" name="int"/>`
elements, and attributes reference them via `<type xmi:idref="EAJava_int"/>`. So EA primitives
usually resolve via **Form 2** against ids like `EAJava_int`, `EAJava_String`,
`EAnone_void`, etc. — index those packagedElements like any other classifier.

---

## 6. Enterprise Architect specifics — the `<xmi:Extension>` block

After (or interleaved with) the standard `<uml:Model>`, EA appends a proprietary
`<xmi:Extension extender="Enterprise Architect">` that **duplicates** the model as
`<elements>`, `<connectors>`, and `<diagrams>`, carrying EA-only metadata (author, dates,
stereotypes, styling) and **all diagram layout**. Everything here references the standard
model by `xmi:idref`; it introduces no new model semantics a lenient importer must honor.

**A lenient importer can ignore the entire `<xmi:Extension>` block** and reconstruct the full
class model from the standard `<uml:Model>` portion alone. The only reason to read it is
**diagram geometry** (positions/sizes), which exists *nowhere else*.

### 6.1 `<elements>` — per-element metadata (mirrors packagedElements)

```xml
<xmi:Extension extender="Enterprise Architect" extenderID="6.5">
  <elements>
    <element xmi:idref="_Car" xmi:type="uml:Class" name="Car" scope="public">
      <properties isSpecification="false" sType="Class" nType="0" scope="public"
                  documentation="A car."/>
      <project author="jw" version="1.0" created="2018-01-02 09:05:22"
               modified="2018-01-02 09:07:34" complexity="1" status="Proposed"/>
      <attributes>...</attributes>
      <operations>...</operations>
      <links>...</links>
    </element>
  </elements>
```

- `<element xmi:idref="...">` points back at the standard element. **`xmi:idref`, not
  `xmi:id`** — strict XMI treats an `xmi:idref`-bearing tag as a reference, not a new object,
  so generic XMI parsers must be told to *not* skip these. In C# with `System.Xml` you read
  the extension subtree manually, so this is a non-issue — just walk `<element>` children.
- `documentation=` here is where EA stashes element notes/comments (the standard UML
  `<ownedComment>` is often *not* emitted; if you want notes, read them here).

### 6.2 `<connectors>` — associations/generalizations/dependencies with EA metadata

```xml
  <connectors>
    <connector xmi:idref="_assoc1">
      <source xmi:idref="_Car">
        <model ea_localid="1" type="Class" name="Car"/>
        <role visibility="public" targetScope="instance"/>
        <type multiplicity="1" aggregation="composite" containment="Unspecified"/>
      </source>
      <target xmi:idref="_Engine">
        <model ea_localid="2" type="Class" name="Engine"/>
        <role visibility="public" targetScope="instance"/>
        <type multiplicity="0..1" aggregation="none"/>
      </target>
      <properties ea_type="Association" direction="Source -> Destination"/>
      <appearance linemode="3" linecolor="..." linewidth="0" seqno="1"/>
    </connector>
  </connectors>
```

- `<connector xmi:idref>` → the standard `uml:Association`/`uml:Generalization` id.
- `<source>`/`<target>` `xmi:idref` → the connected elements. `aggregation`, `multiplicity`,
  and `direction` here **duplicate** what the standard model already encodes — use the
  standard model as source of truth; the connector is a convenience/cross-check only.
- `<properties ea_type="...">` values include `Association`, `Aggregation`, `Generalization`,
  `Dependency`, `Realisation`, `Composition`, `Nesting`, `Sequence` (for sequence diagrams).

### 6.3 `<diagrams>` — the only place diagram layout lives

```xml
  <diagrams>
    <diagram xmi:id="EAID_0E029ABF_C35A_49e3_9EEA_FFD4F32780A8">
      <model package="EAPK_1" localID="12" owner="EAPK_1"/>
      <properties name="Domain Class Diagram" type="Logical"/>
      <project author="jw" version="1.0" created="..." modified="..."/>
      <elements>
        <element geometry="Left=70;Top=50;Right=160;Bottom=200;"
                 subject="EAID_9A8D9208_9B22_4b92_B666_A175C1D03C7B"
                 seqno="2" style="..."/>
        <element geometry="Left=290;Top=50;Right=380;Bottom=200;"
                 subject="_Engine" seqno="1"/>
      </elements>
    </diagram>
  </diagrams>
</xmi:Extension>
```

**Diagram geometry format** — the load-bearing detail if you want layout:
- Each `<element>` in a diagram has `subject="<xmi:idref of the model element>"` and
  `geometry="Left=L;Top=T;Right=R;Bottom=B;"` — a **semicolon-delimited, `Key=Value`**
  string, **not** XML attributes. Parse it by splitting on `;` then `=`.
  - `x = Left`, `y = Top`, `width = Right - Left`, `height = Bottom - Top`.
  - Coordinates are in EA's diagram units (pixels), origin top-left.
- Connector geometry (edge waypoints) also appears as `geometry="SX=..;SY=..;EX=..;EY=..;..."`
  on diagram connector entries (`SX/SY` = source point, `EX/EY` = end point).
- `type="Logical"` (class diagram), `"Sequence"`, `"Use Case"`, `"Component"`, etc.

**XMI 1.1 note:** in EA's *XMI 1.1* export the same layout is instead in
`<UML:DiagramElement geometry="..." subject="..." style="..."/>` elements (uppercase `UML:`
prefix, dotted `xmi.id`). The draw.io EA importer, for instance, reads `UML:DiagramElement`
`geometry`/`subject` and `UML:AssociationEnd` `type`. See §8.

### 6.4 What a lenient importer ignores in the extension

Safe to skip entirely unless you specifically want the feature: `<project>` audit metadata,
`<paths>`, `<times>`, `<flags>`, `<xrefs>`, `<style>`/`<styleex>`, `<tags>`, `<modelDocument>`,
matrix/profile blocks, `<primitivetypes>` bookkeeping (you already have the packagedElement
primitives), and all `linecolor`/`linewidth`/`font` styling. None of it changes the class
model.

---

## 7. XMI 1.1 (UML 1.3/1.4) — detection and handling

Older EA exports and legacy tools emit **XMI 1.x**, a structurally different format. Detect
and either up-convert minimally or reject cleanly.

**How to detect:**
- Root/attr `xmi.version="1.1"` or `"1.2"` (note the **dot**: `xmi.version`, and ids are
  **`xmi.id`** / **`xmi.idref`** with a dot, not colon).
- Element prefix is uppercase **`UML:`** (`<UML:Class>`, `<UML:Attribute>`, `<UML:Model>`).
- Metaclass is the **element name itself**, not an `xmi:type` attribute.
- Structure is `<XMI><XMI.header/><XMI.content>...</XMI.content></XMI>`.

**Key structural differences vs 2.x:**

| Concern | XMI 2.x | XMI 1.x |
|---|---|---|
| Id attribute | `xmi:id` (colon) | `xmi.id` (dot) |
| Reference | `xmi:idref` / attribute id | `xmi.idref` (dot) |
| Metaclass | `xmi:type="uml:Class"` attribute | element name `<UML:Class>` |
| Class member | `ownedAttribute`/`ownedOperation` | `<UML:Attribute>`/`<UML:Operation>` wrapped in `<UML:Classifier.feature>` |
| Type ref | `type`/`<type xmi:idref>`/`href` | `<UML:StructuralFeature.type><UML:Class xmi.idref="..."/>` |
| Multiplicity | `lowerValue`/`upperValue` value-specs | `<UML:MultiplicityRange lower="0" upper="1"/>` (attributes) |
| Association ends | `memberEnd`/`ownedEnd`/`ownedAttribute` | `<UML:AssociationEnd multiplicity="..." aggregation="..." type="..."/>` |
| Diagram layout | extension `geometry="Left=..;"` | `<UML:DiagramElement geometry="..." subject="..."/>` |

**Recommendation:** implement the 2.x path fully. For 1.x, **detect and reject with a clear
message** ("XMI 1.x is not supported; re-export from EA as *UML 2.x (XMI 2.1)*") unless
first-class 1.x support is a stated requirement — the two formats share almost no parsing code
and a half-hearted 1.x reader silently drops data. If you must accept 1.x, write a separate
reader that maps `<UML:MultiplicityRange lower/upper>` and `<UML:AssociationEnd>` into the same
in-memory model.

---

## 8. Export guidance — a minimal, maximally-importable XMI 2.1 document

**Chosen export dialect:** XMI **2.1**, `<xmi:XMI>` wrapper root, `schema.omg.org` namespaces,
GUID-free but stable `xmi:id`s, **no** EA extension block. Rationale: this is byte-for-byte the
family EA itself writes and re-imports without complaint, and every other UML 2.x tool
(Papyrus, MagicDraw, Modelio) accepts XMI 2.1. Emitting the newer `www.omg.org/spec/UML/
20131001` URIs is also valid and slightly more "standard," but some EA builds are pickier about
it, so we default to the `schema.omg.org/2.1` strings and make the namespace a single
configurable constant.

### 8.1 Required skeleton

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.1"
         xmlns:uml="http://schema.omg.org/spec/UML/2.1"
         xmlns:xmi="http://schema.omg.org/spec/XMI/2.1">
  <xmi:Documentation exporter="TheRobotDrafts" exporterVersion="1.0"/>
  <uml:Model xmi:type="uml:Model" xmi:id="MODEL_ROOT" name="Model" visibility="public">
    <!-- packagedElements here -->
  </uml:Model>
</xmi:XMI>
```

Notes:
- Include `xmi:version="2.1"` on the root; include the `<xmi:Documentation>` stanza (EA and
  others display the exporter; some importers key readiness off it).
- Give **every** element a stable, unique `xmi:id`. Use a deterministic scheme (e.g. GUIDs,
  or `EL_` + a monotonic counter, or a hash of the qualified name) so re-exports are stable
  and diffs are small. Avoid characters that need XML escaping; ids should match
  `[A-Za-z_][A-Za-z0-9_.-]*`.
- Write `xmi:type` on every typed element (`packagedElement`, `ownedAttribute`,
  `ownedOperation`, `lowerValue`, etc.). Omitting it makes some importers guess.

### 8.2 Full annotated export example (class model)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xmi:XMI xmi:version="2.1"
         xmlns:uml="http://schema.omg.org/spec/UML/2.1"
         xmlns:xmi="http://schema.omg.org/spec/XMI/2.1">
  <xmi:Documentation exporter="TheRobotDrafts" exporterVersion="1.0"/>

  <uml:Model xmi:type="uml:Model" xmi:id="MODEL_ROOT" name="Domain" visibility="public">

    <!-- Built-in primitives we reference (self-contained; no external href needed) -->
    <packagedElement xmi:type="uml:PrimitiveType" xmi:id="PT_int"     name="int"/>
    <packagedElement xmi:type="uml:PrimitiveType" xmi:id="PT_String"  name="String"/>
    <packagedElement xmi:type="uml:PrimitiveType" xmi:id="PT_boolean" name="boolean"/>

    <packagedElement xmi:type="uml:Package" xmi:id="PKG_Domain" name="Domain" visibility="public">

      <!-- Interface -->
      <packagedElement xmi:type="uml:Interface" xmi:id="IF_Drivable" name="Drivable"
                       visibility="public">
        <ownedOperation xmi:type="uml:Operation" xmi:id="OP_drive" name="drive"
                        visibility="public">
          <ownedParameter xmi:type="uml:Parameter" xmi:id="P_ret" direction="return">
            <type xmi:idref="PT_boolean"/>
          </ownedParameter>
        </ownedOperation>
      </packagedElement>

      <!-- Enumeration -->
      <packagedElement xmi:type="uml:Enumeration" xmi:id="EN_Color" name="Color"
                       visibility="public">
        <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="EL_red"  name="RED"/>
        <ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="EL_blue" name="BLUE"/>
      </packagedElement>

      <!-- Abstract base class -->
      <packagedElement xmi:type="uml:Class" xmi:id="CL_Vehicle" name="Vehicle"
                       visibility="public" isAbstract="true">
        <ownedAttribute xmi:type="uml:Property" xmi:id="A_wheels" name="wheels"
                        visibility="protected" isStatic="false">
          <type xmi:idref="PT_int"/>
          <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="A_wheels_lo" value="1"/>
          <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="A_wheels_hi" value="1"/>
        </ownedAttribute>
      </packagedElement>

      <!-- Concrete class: extends Vehicle, realizes Drivable, composes Engine -->
      <packagedElement xmi:type="uml:Class" xmi:id="CL_Car" name="Car"
                       visibility="public" isAbstract="false">

        <generalization xmi:type="uml:Generalization" xmi:id="G_Car_Vehicle"
                        general="CL_Vehicle"/>

        <interfaceRealization xmi:type="uml:InterfaceRealization" xmi:id="IR_Car"
                              client="CL_Car" supplier="IF_Drivable" contract="IF_Drivable"/>

        <ownedAttribute xmi:type="uml:Property" xmi:id="A_color" name="color"
                        visibility="private">
          <type xmi:idref="EN_Color"/>
        </ownedAttribute>

        <!-- navigable composition end owned by Car -->
        <ownedAttribute xmi:type="uml:Property" xmi:id="END_engine" name="engine"
                        visibility="private" association="AS_CarEngine"
                        aggregation="composite">
          <type xmi:idref="CL_Engine"/>
          <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="END_engine_lo" value="1"/>
          <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="END_engine_hi" value="1"/>
        </ownedAttribute>

        <ownedOperation xmi:type="uml:Operation" xmi:id="OP_startEngine" name="startEngine"
                        visibility="public">
          <ownedParameter xmi:type="uml:Parameter" xmi:id="OP_se_ret" direction="return">
            <type xmi:idref="PT_boolean"/>
          </ownedParameter>
        </ownedOperation>
      </packagedElement>

      <packagedElement xmi:type="uml:Class" xmi:id="CL_Engine" name="Engine"
                       visibility="public"/>

      <!-- Association: the non-navigable back-end is owned here -->
      <packagedElement xmi:type="uml:Association" xmi:id="AS_CarEngine" name="powertrain"
                       visibility="public">
        <memberEnd xmi:idref="END_engine"/>
        <memberEnd xmi:idref="END_car"/>
        <ownedEnd xmi:type="uml:Property" xmi:id="END_car" name="car"
                  visibility="public" association="AS_CarEngine" aggregation="none">
          <type xmi:idref="CL_Car"/>
          <lowerValue xmi:type="uml:LiteralInteger"          xmi:id="END_car_lo" value="1"/>
          <upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="END_car_hi" value="1"/>
        </ownedEnd>
      </packagedElement>

    </packagedElement>
  </uml:Model>
</xmi:XMI>
```

This document imports cleanly into EA (as UML 2.1 XMI), Papyrus, and MagicDraw. It uses:
- the association pattern EA itself favors (one end `ownedAttribute`, one end `ownedEnd`);
- self-contained primitive types (no fragile external `href`s);
- nested `<type xmi:idref>` references (Form 2), the most universally accepted encoding.

### 8.3 The EA extension block — include it or not?

**Recommendation: skip it (or emit a minimal one).** Tradeoffs:

- **Skip** (default): simplest, fully valid, all *semantic* content survives. **Cost:** when
  EA imports the file it lays diagrams out with an auto-layout — your **diagram geometry is
  lost**, because EA reads element positions *only* from the extension's `<diagrams>` block.
- **Minimal extension:** if preserving layout in EA matters, emit just
  `<xmi:Extension extender="Enterprise Architect"><diagrams><diagram>…<element
  geometry="Left=..;Top=..;Right=..;Bottom=..;" subject="<id>"/>…</diagrams></xmi:Extension>`
  with one `<element>` per shown node (and optionally connectors with `SX/SY/EX/EY`). You do
  **not** need to duplicate `<elements>`/`<connectors>` metadata for geometry to take — EA
  keys node placement off `subject`+`geometry`. Keep the `subject` ids identical to the model
  `xmi:id`s.
- Emitting a *partial/incorrect* extension is worse than none — EA may reject or mis-key it.
  If unsure, ship without the extension and accept auto-layout on the EA side.

---

## 9. Importer cheat-sheet (element → attribute map)

Match on **local name** (namespace-agnostic) and read `xmi:type` (or `xsi:type`) as the
discriminator. `→id` = value is an `xmi:id` reference to resolve in pass 2.

| Local element | `xmi:type` | Attributes to read | Children to read |
|---|---|---|---|
| `Model` / `Package` root | `uml:Model`/`uml:Package` | `xmi:id`, `name` | `packagedElement*` |
| `packagedElement` (package) | `uml:Package` | `xmi:id`, `name`, `visibility` | nested `packagedElement*` |
| `packagedElement` (class) | `uml:Class` | `xmi:id`, `name`, `visibility`, `isAbstract` | `ownedAttribute*`, `ownedOperation*`, `generalization*`, `interfaceRealization*` |
| `packagedElement` (interface) | `uml:Interface` | `xmi:id`, `name`, `visibility` | `ownedOperation*`, `ownedAttribute*` |
| `packagedElement` (enum) | `uml:Enumeration` | `xmi:id`, `name` | `ownedLiteral*` |
| `packagedElement` (datatype/primitive) | `uml:DataType`/`uml:PrimitiveType` | `xmi:id`, `name` | (attrs) |
| `packagedElement` (association) | `uml:Association` | `xmi:id`, `name` | `memberEnd*`(→id), `ownedEnd*` |
| `ownedAttribute` | `uml:Property` | `xmi:id`, `name`, `visibility`, `isStatic`, `isReadOnly`, `isDerived`, `aggregation`, `association`(→id), `type`(→id, Form 1) | `type`(→id/href), `lowerValue`, `upperValue`, `defaultValue` |
| `ownedOperation` | `uml:Operation` | `xmi:id`, `name`, `visibility`, `isStatic`, `isAbstract`, `isQuery` | `ownedParameter*` |
| `ownedParameter` | `uml:Parameter` | `xmi:id`, `name`, `direction` (`in`/`out`/`inout`/`return`), `type`(→id) | `type`(→id/href), `lowerValue`, `upperValue` |
| `ownedLiteral` | `uml:EnumerationLiteral` | `xmi:id`, `name` | — |
| `generalization` | `uml:Generalization` | `xmi:id`, `general`(→id), `specific`(→id, optional) | — |
| `interfaceRealization` | `uml:InterfaceRealization` | `xmi:id`, `client`(→id), `supplier`(→id), `contract`(→id) | — |
| `memberEnd` | — | `xmi:idref`(→id) | — |
| `ownedEnd` | `uml:Property` | as `ownedAttribute` | `type`, multiplicity |
| `type` (nested) | (optional) | `xmi:idref`(→id) **or** `href` | — |
| `lowerValue` | `uml:LiteralInteger` | `value` (default 0) | — |
| `upperValue` | `uml:LiteralUnlimitedNatural` | `value` (`*`/`-1`/absent = unbounded) | — |
| `defaultValue` | `uml:Literal*`/`uml:InstanceValue` | `value` / `instance`(→id) | — |

**Enum of `visibility`:** `public` \| `private` \| `protected` \| `package` (default `public`).
**Enum of `aggregation`:** `none` (default) \| `shared` \| `composite`.
**Enum of `direction`:** `in` (default) \| `inout` \| `out` \| `return`.

---

## 10. C# / `System.Xml` implementation notes

- **Parser choice:** `XmlDocument` (DOM) is simplest given the two-pass requirement and the
  need to jump around by id. For very large models, an `XmlReader` first pass to build the
  id-index followed by targeted DOM sub-reads works but is rarely worth it.
- **Namespaces:** build an `XmlNamespaceManager` from the *actual* declarations on the root
  element (enumerate `root.Attributes` for `xmlns:*`). Register whatever prefix the file uses
  for the `xmi` and `uml` families. Then select with the file's prefixes, **or** avoid XPath
  prefix pain entirely by iterating `element.ChildNodes` and comparing `node.LocalName`
  (namespace-agnostic) — recommended, because prefixes and namespace URIs vary across the
  dialects in §1.2.
- **Reading `xmi:type`:** it's a QName string like `"uml:Class"`. Read the raw attribute
  value and compare on the **local part** after `:` (`value.Split(':').Last()`), since the
  prefix (`uml`) is file-dependent. Fall back to reading `xsi:type` if `xmi:type` is absent.
  To read the attribute itself, use `elem.GetAttribute("type", xmiNamespaceUri)` **and** try
  the `xsi` namespace; some tools put `type` in the `xsi` namespace.
- **Reading `xmi:id`/`xmi:idref`:** `elem.GetAttribute("id", xmiNamespaceUri)` and
  `GetAttribute("idref", xmiNamespaceUri)`. Guard for the XMI-1.x dotted form (`xmi.id`) if
  you support detection — those are **not** namespaced attributes, they're literal
  `xmi.id`/`xmi.idref` attribute names.
- **Two-pass:** Pass 1 — walk the whole `packagedElement` tree, instantiate every element,
  and populate `Dictionary<string, ModelElement>` keyed by `xmi:id` (include `ownedEnd`
  properties, they're referenced by `memberEnd`). Pass 2 — resolve `general`, `type`,
  `memberEnd`, `supplier`/`contract`, association ends. Keep unresolved references as
  placeholder objects, don't throw.
- **Writing (export):** `XmlWriter` with `XmlWriterSettings { Indent = true }`. Declare the
  two namespaces once on the root; write `xmi:type`, `xmi:id`, etc. with
  `WriteAttributeString("type", xmiNs, "uml:Class")`. Because `xmi:type` values embed the
  `uml:` prefix, ensure the `uml` prefix is actually declared (write it explicitly on the
  root via `WriteAttributeString("xmlns", "uml", null, umlNs)`).
- **Encoding:** honor the declared XML encoding on read (EA often emits `windows-1252`);
  always write UTF-8.

---

## 11. Top interop pitfalls (read this before coding)

1. **Forward references** — ids are referenced before they're defined. Two-pass resolution is
   mandatory, not optional (§0).
2. **Three type encodings** — attribute `type=`, nested `<type xmi:idref>`, nested
   `<type href>`. Miss any one and a subset of files loses all typing (§5).
3. **Association ends split across two locations** — EA puts one end as a class
   `ownedAttribute` and one as the association's `ownedEnd`. Gather ends from both; use
   `memberEnd` as the authoritative list of which two properties are the ends (§4.3).
4. **Namespace/prefix variance** — `schema.omg.org/spec/UML/2.1` vs
   `www.omg.org/spec/UML/20131001` vs Eclipse URIs; prefix `uml:` vs `UML:`. Match on local
   name, not literal QNames (§1.2, §10).
5. **`xmi:type` prefix is file-relative** — compare the local part after `:`, and accept
   `xsi:type` as a synonym (§10).
6. **Multiplicity defaults** — missing `lowerValue`/`upperValue` means `1`; `value="*"`,
   `value="-1"`, and absent-`value` on `LiteralUnlimitedNatural` all mean unbounded (§3.1).
7. **`xmi:idref` inside the EA extension** — strict/generic XMI parsers skip idref-bearing
   tags as references; when hand-walking the extension you must intentionally read them
   (§6.1). But better: **ignore the extension for semantics** and read it only for geometry.
8. **Diagram layout lives only in the extension** — if you export without an EA extension,
   EA re-lays-out on import; there is no standard place for coordinates (§6.3, §8.3).
9. **Diagram geometry is a delimited string, not attributes** — `geometry="Left=..;Top=..;
   Right=..;Bottom=..;"`; parse by `;`/`=`. Width/height are `Right-Left`/`Bottom-Top` (§6.3).
10. **XMI 1.x is a different format** — dotted `xmi.id`, `UML:` element-name metaclasses,
    `MultiplicityRange`, `AssociationEnd`. Detect and reject (or route to a separate reader);
    do not feed it to the 2.x path (§7).
11. **Untyped/unnamed elements are legal** — anonymous associations, untyped parameters,
    typeless properties. Never crash or drop them; keep placeholders.
12. **Comments/notes** — standard UML `<ownedComment>` is often absent; EA hides notes in the
    extension's `documentation=` attribute. Read there if you need descriptions (§6.1).

---

## 12. Sources

- OMG, *MOF 2 / XMI Mapping Specification* v2.1 and v2.5.1 —
  <https://www.omg.org/spec/XMI/2.1/PDF>, <https://www.omg.org/spec/XMI/2.5.1/PDF/>
- Sparx Systems, *Export to XMI* / *Import from XMI* (EA User Guide 17.1) —
  <https://sparxsystems.com/enterprise_architect_user_guide/17.1/model_exchange/exporttoxmi.html>,
  <https://sparxsystems.com/enterprise_architect_user_guide/17.1/model_exchange/importxmi.html>
- Sparx Systems, *Export/Import with XMI FAQ* — <https://sparxsystems.com/support/faq/import_xmi.html>
- SDMetrics, *Parsing the XMI Extensions of Enterprise Architect* —
  <https://www.sdmetrics.com/blog/2018/01/parsing-the-xmi-extensions-of-enterprise-architect/>,
  and *Custom XMI import* — <https://www.sdmetrics.com/CustomXMI.html>
- `lutaml/xmi` — OMG XMI parser tuned for Enterprise Architect UML 1.5 & 2.x —
  <https://github.com/lutaml/xmi>
- `gobravedave/XMI-Samples` — real EA XMI 2.1 exports (root/namespace/extension verified here) —
  <https://github.com/gobravedave/XMI-Samples>
- `jmcklondonuk/drawio_enterprise_architect_integration` — EA XMI 1.1 diagram-geometry parser
  (`UML:DiagramElement`, `geometry`, `subject`, `UML:AssociationEnd`) —
  <https://github.com/jmcklondonuk/drawio_enterprise_architect_integration/>
- Metanorma, *Working with Enterprise Architect* (diagrams from XMI) —
  <https://www.metanorma.org/blog/2024-08-26-working-with-enterprise-architect/>
- ArgoUML wiki, *UML2, Profiles and XMI* —
  <https://argouml-tigris-org.github.io/tigris/wiki-argouml/wiki/UML2,_Profiles_and_XMI.html>
- Talend/Qlik Data Catalog, *Sparx EA via UML 2.x XMI — Import/Export bridge* —
  <https://help.qlik.com/talend/en-US/talend-data-catalog/8.0/Content/MIROmgUml2XmiImport.SparxEAImport.htm>
</content>
</invoke>
