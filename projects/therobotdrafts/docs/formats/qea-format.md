# Sparx Enterprise Architect `.qea` File Format

Implementer-oriented reference for reading and writing Sparx Systems Enterprise
Architect `.qea` project files, reverse-engineered from a real backend design
model (`oqo.qea`, EA 16+).

> **TL;DR** — A `.qea` file is an ordinary **SQLite 3 database** carrying EA's
> full relational schema (~160 tables). "QEA" = **Q**t-based EA using a
> **SQLite** repository (the successor to the Access `.eap` / `.eapx` format and
> the Firebird `.feap`). All model content lives in `t_*` tables; a handful of
> `usys*` tables carry structural/version magic. There are **no triggers or
> views** — only tables and indexes. Primary keys are `INTEGER … AUTOINCREMENT`,
> so `sqlite_sequence` matters. **Do not generate a file from scratch: ship a
> pre-seeded empty template `.qea` and INSERT rows into it** (see
> [§9](#9-minimal-valid-file--generation-strategy)).

---

## 1. Container facts

| Property | Value |
|----------|-------|
| Physical format | SQLite 3.x database (`file … SQLite 3.x database`) |
| Written-by version (sample) | SQLite 3.37.2 |
| Open read-only | `sqlite3 "file:/path/to/model.qea?mode=ro"` |
| Encoding | UTF-8 |
| Table count | ~160 (`t_*` model tables, `usys*`/`usys_*` system tables) |
| Triggers / Views | **none** |
| Indexes | many (`ix_*` perf indexes, `uq_*`/`sqlite_autoindex_*` uniqueness) |
| Autoincrement | Yes — every core PK is `INTEGER … AUTOINCREMENT`; counters in `sqlite_sequence` |

All `TEXT` columns are declared `COLLATE NOCASE`. GUID/timestamp columns are
plain `TEXT`. Booleans are `INTEGER` (0/1). Colours are `INTEGER` (Windows BGR,
`-1` = default).

Open the file with any SQLite library. EA itself uses WAL at runtime but ships a
committed rollback-journal DB; treat it as a normal SQLite file — always `COMMIT`
and checkpoint before handing the file back.

---

## 2. Table map

### 2.1 Data-bearing tables in this sample (the ones an importer/exporter touches)

| Table | Rows | Role |
|-------|-----:|------|
| `t_datatypes` | 694 | **Seed** — language/DBMS datatype catalog (ships with template) |
| `t_xref` | 591 | Applied stereotypes + style/appearance/misc cross-refs (see [§6](#6-t_xref--stereotype-application--style-store)) |
| `t_attribute` | 421 | Class attributes = **DB table columns** in a data model |
| `t_objectproperties` | 250 | Element **tagged values** (Owner, Tablespace, DBVersion, funcdef…) |
| `t_object` | 141 | **Elements**: classes, packages(as elements), notes, boundaries, artifacts |
| `t_stereotypes` | 130 | **Seed** — stereotype catalog |
| `t_operationparams` | 124 | Operation parameters = **FK/PK column lists** in a data model |
| `t_operation` | 121 | Class operations = **PK/FK/index constraints** in a data model |
| `t_diagramobjects` | 118 | Element **placement** on diagrams (rectangles) |
| `t_operationtag` | 99 | Tagged values on operations (FK `Delete`/`Update` rules…) |
| `t_objecttypes` | 80 | **Seed** — legal `Object_Type` vocabulary |
| `t_connector` | 63 | **Relationships** (Association/Dependency/Extension/NoteLink…) |
| `t_diagramlinks` | 62 | Connector **routing/appearance** per diagram |
| `t_connectortypes` | 30 | **Seed** — legal `Connector_Type` vocabulary |
| `t_template` | 28 | **Seed** — diagram/UML templates |
| `t_package` | 16 | **Package tree** (the model's spine) |
| `t_diagramtypes` | 15 | **Seed** — legal `Diagram_Type` vocabulary |
| `t_diagram` | 15 | **Diagrams** |
| `t_cardinality` | 7 | **Seed** — multiplicity dropdown values |
| `t_taggedvalue` | 2 | Legacy/base-class tagged values (rarely used; prefer `t_*tag`) |
| `t_attributetag` | 1 | Tagged values on attributes |

Plus many small **seed reference tables** (`t_propertytypes`, `t_constants`,
`t_statustypes`, `t_efforttypes`, `t_complexitytypes`, `t_primitives`,
`t_genopt`, `t_ecf`/`t_tcf`, …) that arrive pre-populated in a fresh EA project
and are **not touched** by a model importer/exporter.

### 2.2 System / structural tables

| Table | Purpose |
|-------|---------|
| `usys_system` | Key→value project config & EA feature-flag "magic" (109 rows). Contains `ProjectGUID`. |
| `usys_schema` | **Schema-version marker via its column name** — the single column is `V1558` (= schema rev 1558). Table holds **0 rows**; the *column name* is the version. |
| `usysTables` | Table registry with `RelOrder` (relational/insert order) + `FromVer`/`ToVer`. |
| `usysOldTables` | Rename/upgrade map (legacy → current table names). |
| `usysQueries` | Internal query rename/fix map. |
| `sqlite_sequence` | AUTOINCREMENT high-water marks — **must be kept ≥ max(PK)**. |
| `t_version` | Version-control / element-XML store (empty here). |

### 2.3 Security tables — empty here, safe to leave empty

`t_secuser`, `t_secgroup`, `t_secpolicies`, `t_secpermission`, `t_seclocks`, … all
have **0 rows**. `usys_system.UserSecurity=1` is a feature-registration flag, not
"security enabled." A valid file needs no security rows.

---

## 3. GUID & identity conventions

- **`ea_guid`** — every element/feature/diagram/connector carries one. Format is
  a **Microsoft registry GUID wrapped in braces, uppercase hex except that the
  4th group is often lowercase**, e.g. `{B34F500B-730D-40b1-BFA6-0A00825BCDB5}`.
  EA is tolerant of all-upper or all-lower, but match the `{8-4-4-4-12}` shape
  and keep the braces. Generate with any UUIDv4 and wrap in `{}`.
- **`ProjectGUID`** (in `usys_system`) identifies the whole repository:
  `{5DDA19E3-A949-4bbf-9438-39492A2126EF}`.
- **Numeric PKs** (`Object_ID`, `Package_ID`, `Connector_ID`, `OperationID`,
  attribute `ID`, `Diagram_ID`, `Instance_ID`, `PropertyID`) are the internal FK
  currency. **`ea_guid` is the stable external identity**; numeric IDs are local
  to the file. When merging/importing, map on `ea_guid`, allocate fresh numeric
  IDs, and fix up `sqlite_sequence`.
- Cross-refs in `t_xref` use **GUIDs** (`Client`/`Supplier`), not numeric IDs.

---

## 4. Core model tables

### 4.1 `t_package` — the package tree (model spine)

```sql
CREATE TABLE t_package
(
    Package_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Name TEXT NULL COLLATE NOCASE,
    Parent_ID INTEGER NULL DEFAULT 0,          -- parent Package_ID; 0 under root
    CreatedDate TEXT NULL DEFAULT (datetime('now','localtime')) COLLATE NOCASE,
    ModifiedDate TEXT NULL DEFAULT (datetime('now','localtime')) COLLATE NOCASE,
    Notes TEXT NULL COLLATE NOCASE,
    ea_guid TEXT NULL COLLATE NOCASE,
    XMLPath TEXT NULL COLLATE NOCASE,
    IsControlled INTEGER NULL DEFAULT 0,
    LastLoadDate TEXT NULL COLLATE NOCASE,
    LastSaveDate TEXT NULL COLLATE NOCASE,
    Version TEXT NULL COLLATE NOCASE,
    Protected INTEGER NULL DEFAULT 0,
    PkgOwner TEXT NULL COLLATE NOCASE,
    UMLVersion TEXT NULL COLLATE NOCASE,
    UseDTD INTEGER NULL DEFAULT 0,
    LogXML INTEGER NULL DEFAULT 0,
    CodePath TEXT NULL COLLATE NOCASE,
    Namespace TEXT NULL COLLATE NOCASE,
    TPos INTEGER NULL,                          -- tree sort position
    PackageFlags TEXT NULL COLLATE NOCASE,      -- "isModel=…;VICON=…;..." style string
    BatchSave INTEGER NULL,
    BatchLoad INTEGER NULL
)
```

- Hierarchy is `Parent_ID → Package_ID`. The **root model package** has
  `Parent_ID = 0`. There can be several roots (here: `Model` and `Swift`, both
  `Parent_ID=0`). The root `Model` package (`Package_ID=1`) is special and has
  **no mirror element row** in `t_object` (see 4.2).
- **Every non-root package is mirrored by a `t_object` row** of
  `Object_Type='Package'` so the package can appear on diagrams and own
  connectors. The mirror element's `t_object.PDATA1 = t_package.Package_ID`
  (as a string), and its `t_object.Package_ID = the parent package`. This
  double-bookkeeping is the single most error-prone part of writing a `.qea`.

Sample hierarchy from `oqo.qea`:

```
1  Model                          (root)
 2   OQO App Classes
 29  PostgreSQL Model Structure
  30  Conceptual Data Model
  31  Logical Data Model
  32  OQOApp                       (the PostgreSQL schema)
   33 Functions   34 Queries   35 Sequences   36 Tables   37 Views
   38 Connections 42 Minimialist
5  Swift                          (root; a UML profile package)
 14  Swift Sterotypes → 18 Swift Sterotypes
```

### 4.2 `t_object` — elements (57 columns)

```sql
CREATE TABLE t_object
(
    Object_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Object_Type TEXT NULL COLLATE NOCASE,   -- Class | Package | Note | Boundary | Artifact | Interface | Enumeration | …
    Diagram_ID INTEGER NULL DEFAULT 0,      -- "child diagram" for composite elements (usually 0)
    Name TEXT NULL COLLATE NOCASE,
    Alias TEXT NULL COLLATE NOCASE,
    Author TEXT NULL COLLATE NOCASE,
    Version TEXT NULL DEFAULT '1.0' COLLATE NOCASE,
    Note TEXT NULL COLLATE NOCASE,          -- NOTE: singular "Note" here (vs "Notes" elsewhere!)
    Package_ID INTEGER NULL DEFAULT 0,      -- owning package (FK t_package.Package_ID)
    Stereotype TEXT NULL COLLATE NOCASE,    -- display stereotype (also mirrored into t_xref, see §6)
    NType INTEGER NULL DEFAULT 0,           -- element sub-kind discriminator (e.g. Boundary shapes)
    Complexity TEXT NULL DEFAULT '2' COLLATE NOCASE,
    Effort INTEGER NULL DEFAULT 0,
    Style TEXT NULL COLLATE NOCASE,         -- element-level appearance string (often empty)
    Backcolor INTEGER NULL DEFAULT 0,
    BorderStyle INTEGER NULL DEFAULT 0,
    BorderWidth INTEGER NULL DEFAULT 0,
    Fontcolor INTEGER NULL DEFAULT 0,
    Bordercolor INTEGER NULL DEFAULT 0,
    CreatedDate TEXT NULL DEFAULT (datetime('now','localtime')) COLLATE NOCASE,
    ModifiedDate TEXT NULL DEFAULT (datetime('now','localtime')) COLLATE NOCASE,
    Status TEXT NULL COLLATE NOCASE,        -- e.g. 'Proposed'
    Abstract TEXT NULL COLLATE NOCASE,      -- '0'/'1'
    Tagged INTEGER NULL DEFAULT 0,
    PDATA1 TEXT NULL COLLATE NOCASE,        -- overloaded: for Package elements = Package_ID it represents
    PDATA2 TEXT NULL COLLATE NOCASE,
    PDATA3 TEXT NULL COLLATE NOCASE,
    PDATA4 TEXT NULL COLLATE NOCASE,
    PDATA5 TEXT NULL COLLATE NOCASE,        -- for classifiers: classifier GUID/id refs
    Concurrency TEXT NULL COLLATE NOCASE,
    Visibility TEXT NULL COLLATE NOCASE,
    Persistence TEXT NULL COLLATE NOCASE,
    Cardinality TEXT NULL COLLATE NOCASE,
    GenType TEXT NULL COLLATE NOCASE,       -- code/DB language, e.g. 'PostgreSQL'
    GenFile TEXT NULL COLLATE NOCASE,
    Header1 TEXT NULL COLLATE NOCASE,
    Header2 TEXT NULL COLLATE NOCASE,
    Phase TEXT NULL COLLATE NOCASE,
    Scope TEXT NULL COLLATE NOCASE,         -- Public | Private | Protected | Package
    GenOption TEXT NULL COLLATE NOCASE,
    GenLinks TEXT NULL COLLATE NOCASE,
    Classifier INTEGER NULL,                -- classifier Object_ID (typed elements)
    ea_guid TEXT NULL COLLATE NOCASE,
    ParentID INTEGER NULL,                  -- generalization parent Object_ID (0 = none)
    RunState TEXT NULL COLLATE NOCASE,
    Classifier_guid TEXT NULL COLLATE NOCASE,
    TPos INTEGER NULL,
    IsRoot INTEGER NULL DEFAULT 0,
    IsLeaf INTEGER NULL DEFAULT 0,
    IsSpec INTEGER NULL DEFAULT 0,
    IsActive INTEGER NULL DEFAULT 0,
    StateFlags TEXT NULL COLLATE NOCASE,
    PackageFlags TEXT NULL COLLATE NOCASE,
    Multiplicity TEXT NULL COLLATE NOCASE,
    StyleEx TEXT NULL COLLATE NOCASE,       -- extended appearance "key=val;…"
    ActionFlags TEXT NULL COLLATE NOCASE,
    EventFlags TEXT NULL COLLATE NOCASE
)
```

**`Object_Type` values in this sample** (the full legal vocabulary lives in
`t_objecttypes`, 80 rows — Action, Activity, Actor, Artifact, Boundary, Class,
Component, Constraint, DataType, Entity, Enumeration, Interface, Node, Note,
Object, Package, Port, State, UseCase, …):

| `Object_Type` | Count | Notes |
|---------------|------:|-------|
| `Class` | 104 | The workhorse. Stereotyped `table`(75), `struct`(9), `stereotype`(9), `function`(4), `Metaclass`(1), `view`(1) |
| `Package` | 14 | Mirror elements for `t_package` rows (see 4.1) |
| `Boundary` | 11 | Visual grouping frames on diagrams (`NType=1`) |
| `Note` | 7 | Free text; text is in `Note`; `Name` empty |
| `Artifact` | 4 | Stereotyped `database connection`(3), `EAReportSpecification`(1) |
| `Constraint` | 1 | |

> **No `Interface` or `Enumeration` elements exist in this sample** — it is a
> pure relational data model. An importer must still handle those types since
> `t_objecttypes` permits them and typical class models use them.

**Key relationships out of `t_object`:**
- attributes: `t_attribute.Object_ID = t_object.Object_ID`
- operations: `t_operation.Object_ID = t_object.Object_ID`
- generalization (extends): `t_object.ParentID` (numeric) **and/or** a
  `Generalization` connector — EA writes both for classes.
- typed-by classifier: `Classifier` (Object_ID) / `Classifier_guid`.
- tagged values: `t_objectproperties.Object_ID`.

### 4.3 `t_attribute` — attributes / DB columns

```sql
CREATE TABLE t_attribute
(
    Object_ID INTEGER NULL DEFAULT 0,       -- owning element (FK t_object.Object_ID)
    Name TEXT NULL COLLATE NOCASE,
    Scope TEXT NULL COLLATE NOCASE,         -- Public | Private | Protected | Package
    Stereotype TEXT NULL COLLATE NOCASE,    -- e.g. 'column' for DB tables (also in t_xref)
    Containment TEXT NULL COLLATE NOCASE,
    IsStatic INTEGER NULL DEFAULT 0,
    IsCollection INTEGER NULL DEFAULT 0,
    IsOrdered INTEGER NULL DEFAULT 0,
    AllowDuplicates INTEGER NULL DEFAULT 0,
    LowerBound TEXT NULL COLLATE NOCASE,    -- multiplicity, e.g. '1'
    UpperBound TEXT NULL COLLATE NOCASE,    -- e.g. '1'
    Container TEXT NULL COLLATE NOCASE,
    Notes TEXT NULL COLLATE NOCASE,
    Derived TEXT NULL COLLATE NOCASE,       -- '0'/'1'
    ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,   -- attribute PK
    Pos INTEGER NULL,                       -- ordering within the element (0-based)
    GenOption TEXT NULL COLLATE NOCASE,
    Length INTEGER NULL,                    -- DB column length
    Precision INTEGER NULL,
    Scale INTEGER NULL,
    Const INTEGER NULL,
    Style TEXT NULL COLLATE NOCASE,
    Classifier TEXT NULL COLLATE NOCASE,    -- Object_ID of the type element, if typed by a classifier
    'Default' TEXT NULL COLLATE NOCASE,     -- default value (reserved word → quoted)
    Type TEXT NULL COLLATE NOCASE,          -- type name: 'uuid','jsonb','date' (DB) or a class name
    ea_guid TEXT NULL COLLATE NOCASE,
    StyleEx TEXT NULL COLLATE NOCASE        -- e.g. 'volatile=0;union=0;...'
)
```

- In a **data model**, each attribute is a **table column**; `Type` holds the
  SQL type (`uuid`, `jsonb`, `date`, `varchar`, …) and `Stereotype='column'`.
- Order columns by `Pos`.
- `Classifier` (attribute) is a *string* holding the Object_ID of a class when
  the attribute is typed by another element; empty for primitive/SQL types.

### 4.4 `t_operation` + `t_operationparams` + `t_operationtag`

In a UML class these are methods/parameters. In an EA **data model** they encode
**DB constraints**: an operation stereotyped `PK`/`FK`/`index`/`unique` with its
participating columns listed as parameters.

```sql
CREATE TABLE t_operation
(
    OperationID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Object_ID INTEGER NULL DEFAULT 0,       -- owning element (FK t_object.Object_ID)
    Name TEXT NULL COLLATE NOCASE,          -- e.g. 'pk_user_session', 'FK_user_session_user'
    Scope TEXT NULL COLLATE NOCASE,
    Type TEXT NULL COLLATE NOCASE,          -- return type (empty for constraints)
    ReturnArray TEXT NULL COLLATE NOCASE,
    Stereotype TEXT NULL COLLATE NOCASE,    -- 'PK' | 'FK' | 'index' | 'unique' | user stereotypes
    IsStatic TEXT NULL COLLATE NOCASE,
    Concurrency TEXT NULL COLLATE NOCASE,
    Notes TEXT NULL COLLATE NOCASE,
    Behaviour TEXT NULL COLLATE NOCASE,
    Abstract TEXT NULL COLLATE NOCASE,
    GenOption TEXT NULL COLLATE NOCASE,
    Synchronized TEXT NULL COLLATE NOCASE,
    Pos INTEGER NULL,
    Const INTEGER NULL,
    Style TEXT NULL COLLATE NOCASE,
    Pure INTEGER NULL DEFAULT 0,
    Throws TEXT NULL COLLATE NOCASE,
    Classifier TEXT NULL COLLATE NOCASE,    -- return classifier Object_ID
    Code TEXT NULL COLLATE NOCASE,
    IsRoot INTEGER NULL DEFAULT 0,
    IsLeaf INTEGER NULL DEFAULT 0,
    IsQuery INTEGER NULL DEFAULT 0,
    StateFlags TEXT NULL COLLATE NOCASE,
    ea_guid TEXT NULL COLLATE NOCASE,
    StyleEx TEXT NULL COLLATE NOCASE
)

CREATE TABLE t_operationparams
(
    OperationID INTEGER NOT NULL DEFAULT 0,     -- FK t_operation.OperationID
    Name TEXT NOT NULL COLLATE NOCASE,          -- param / participating-column name
    Type TEXT NULL COLLATE NOCASE,              -- param type (e.g. 'uuid')
    'Default' TEXT NULL COLLATE NOCASE,
    Notes TEXT NULL COLLATE NOCASE,
    Pos INTEGER NULL DEFAULT 0,
    Const INTEGER NULL,
    Style TEXT NULL COLLATE NOCASE,
    Kind TEXT NULL COLLATE NOCASE,              -- 'in' | 'out' | 'inout' | 'return'
    Classifier TEXT NULL COLLATE NOCASE,
    ea_guid TEXT NULL COLLATE NOCASE,
    StyleEx TEXT NULL COLLATE NOCASE,
    CONSTRAINT pk_operationparams PRIMARY KEY (OperationID,Name)   -- composite PK, NO autoincrement
)
```

> **`t_operationparams` has a composite PK `(OperationID, Name)` and is the only
> core table without an autoincrement surrogate** — two params on one operation
> cannot share a name.

`t_operationtag` (identical shape to `t_attributetag`/`t_connectortag`) stores
tagged values on operations. In this data model, FK operations carry referential
rules:

```
ElementID=117  Property='property'  VALUE='Delete No Action=1;Update No Action=1;'
ElementID=117  Property='Delete'    VALUE='No Action'
ElementID=117  Property='Update'    VALUE='No Action'
```

(`ElementID` here = `t_operation.OperationID`.)

**Worked example — element `user_session` (`Object_ID=160`, a PostgreSQL table):**

- `t_object`: `Object_Type='Class'`, `Stereotype='table'`, `GenType='PostgreSQL'`, `Package_ID=42`.
- 8 attributes (columns) ordered by `Pos`: `identifier uuid`, `user_identifier
  uuid`, `user_credential_identifier uuid`, `user_device_identifier uuid`,
  `snapshot jsonb`, `created_on date`, `modified_on date`, `deleted_on date`.
- 7 operations (constraints): `pk_user_session`(PK), and FK/index pairs
  `FK_user_session_user`+`IXFK_user_session_user`, …_user_credential, …_user_device.
- Each FK operation's `t_operationparams` row names the participating column
  (`user_identifier uuid`, `Kind='in'`); the PK operation's param is `identifier`.
- FK `Delete`/`Update` rules live in `t_operationtag`.

### 4.5 `t_objectproperties` — element tagged values

```sql
CREATE TABLE t_objectproperties
(
    PropertyID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Object_ID INTEGER NULL DEFAULT 0,       -- FK t_object.Object_ID
    Property TEXT NULL COLLATE NOCASE,      -- tag name
    Value TEXT NULL COLLATE NOCASE,         -- tag value ('<memo>' → long text stored in Notes)
    Notes TEXT NULL COLLATE NOCASE,
    ea_guid TEXT NULL COLLATE NOCASE
)
```

Common tag names seen: `DBVersion`(80), `Owner`(80), `Tablespace`(75) — one set
per DB table; `DBMS='PostgreSQL'`, `DefaultOwner='public'`, `funcdef`/`viewdef`
(SQL body of functions/views, `Value='<memo>'` with real text in `Notes`),
`ConnectionOptions`/`OtherSchemas` (on `database connection` artifacts),
`SSDefaultToolbox`, `DocumentOptions`.

### 4.6 Tag tables (`t_attributetag`, `t_operationtag`, `t_connectortag`)

All three share one shape (note `ElementID` + upper-case `VALUE`/`NOTES`):

```sql
CREATE TABLE t_operationtag        -- and t_attributetag, t_connectortag identically
(
    PropertyID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    ElementID INTEGER NULL DEFAULT 0,       -- FK to the owner's PK (OperationID / attribute ID / Connector_ID)
    Property TEXT NULL COLLATE NOCASE,
    VALUE TEXT NULL COLLATE NOCASE,
    NOTES TEXT NULL COLLATE NOCASE,
    ea_guid TEXT NULL COLLATE NOCASE
)
```

`t_taggedvalue` (composite-string PK, `BaseClass`, `TagValue`) is the older
generic tag store; EA still writes a couple of rows but prefers the per-feature
`t_*tag` tables. Read both; write to `t_*tag`.

---

## 5. `t_connector` — relationships (79 columns)

```sql
CREATE TABLE t_connector
(
    Connector_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Name TEXT NULL COLLATE NOCASE,
    Direction TEXT NULL COLLATE NOCASE,         -- 'Source -> Destination' | 'Unspecified' | …
    Notes TEXT NULL COLLATE NOCASE,
    Connector_Type TEXT NULL COLLATE NOCASE,    -- Association | Dependency | Generalization | Extension | NoteLink | …
    SubType TEXT NULL COLLATE NOCASE,
    SourceCard TEXT NULL COLLATE NOCASE,        -- source multiplicity, e.g. '0..*'
    SourceAccess TEXT NULL COLLATE NOCASE,
    SourceElement TEXT NULL COLLATE NOCASE,
    DestCard TEXT NULL COLLATE NOCASE,          -- dest multiplicity, e.g. '1'
    DestAccess TEXT NULL COLLATE NOCASE,
    DestElement TEXT NULL COLLATE NOCASE,
    SourceRole TEXT NULL COLLATE NOCASE,        -- role name at source end
    SourceRoleType TEXT NULL COLLATE NOCASE,
    SourceRoleNote TEXT NULL COLLATE NOCASE,
    SourceContainment TEXT NULL COLLATE NOCASE,
    SourceIsAggregate INTEGER NULL DEFAULT 0,   -- 0 none | 1 shared | 2 composite
    SourceIsOrdered INTEGER NULL DEFAULT 0,
    SourceQualifier TEXT NULL COLLATE NOCASE,
    DestRole TEXT NULL COLLATE NOCASE,
    DestRoleType TEXT NULL COLLATE NOCASE,
    DestRoleNote TEXT NULL COLLATE NOCASE,
    DestContainment TEXT NULL COLLATE NOCASE,
    DestIsAggregate INTEGER NULL DEFAULT 0,
    DestIsOrdered INTEGER NULL DEFAULT 0,
    DestQualifier TEXT NULL COLLATE NOCASE,
    Start_Object_ID INTEGER NULL DEFAULT 0,     -- FK t_object.Object_ID (source)
    End_Object_ID INTEGER NULL DEFAULT 0,       -- FK t_object.Object_ID (destination)
    Top_Start_Label TEXT, Top_Mid_Label TEXT, Top_End_Label TEXT,
    Btm_Start_Label TEXT, Btm_Mid_Label TEXT, Btm_End_Label TEXT,
    Start_Edge INTEGER NULL DEFAULT 0,
    End_Edge INTEGER NULL DEFAULT 0,
    PtStartX INTEGER, PtStartY INTEGER, PtEndX INTEGER, PtEndY INTEGER,
    SeqNo INTEGER NULL DEFAULT 0,               -- sequence-diagram ordering
    HeadStyle INTEGER NULL DEFAULT 0,
    LineStyle INTEGER NULL DEFAULT 0,
    RouteStyle INTEGER NULL DEFAULT 0,
    IsBold INTEGER NULL DEFAULT 0,
    LineColor INTEGER NULL DEFAULT 0,
    Stereotype TEXT NULL COLLATE NOCASE,
    VirtualInheritance TEXT NULL COLLATE NOCASE,
    LinkAccess TEXT NULL COLLATE NOCASE,
    PDATA1 TEXT, PDATA2 TEXT, PDATA3 TEXT, PDATA4 TEXT, PDATA5 TEXT,
    DiagramID INTEGER NULL DEFAULT 0,           -- "home" diagram (0 = model-level)
    ea_guid TEXT NULL COLLATE NOCASE,
    SourceConstraint TEXT, DestConstraint TEXT,
    SourceIsNavigable INTEGER, DestIsNavigable INTEGER,
    IsRoot INTEGER, IsLeaf INTEGER, IsSpec INTEGER,
    SourceChangeable TEXT, DestChangeable TEXT,
    SourceTS TEXT, DestTS TEXT,
    StateFlags TEXT, ActionFlags TEXT,
    IsSignal INTEGER, IsStimulus INTEGER,
    DispatchAction TEXT,
    Target2 INTEGER,
    StyleEx TEXT,
    SourceStereotype TEXT, DestStereotype TEXT,
    SourceStyle TEXT, DestStyle TEXT,
    EventFlags TEXT
)
```

**`Connector_Type` values in this sample** (legal vocabulary is `t_connectortypes`,
30 rows — Aggregation, Association, Assembly, Collaboration, ControlFlow,
Dependency, Deployment, Extension, Generalization, InformationFlow, Instantiation,
Nesting, Notelink, ObjectFlow, Package, Realisation, Sequence, StateFlow, UseCase, …):

| `Connector_Type` | Count | Meaning in this model |
|------------------|------:|-----------------------|
| `Association` | 39 | FK relationships between tables. `Start_Object_ID`→child, `End_Object_ID`→parent; cardinality in `SourceCard`/`DestCard`; role name in `SourceRole`/`DestRole` (e.g. `FK_group_member_group` / `PK_group`) |
| `Extension` | 9 | UML-profile `«extend»` from a stereotype element to the `Metaclass` element (`End_Object_ID=56`) |
| `Dependency` | 8 | Package/element dependencies (e.g. profile package → stereotype defs) |
| `NoteLink` | 7 | Anchors a `Note` element to what it annotates |

- Endpoints are **numeric `Object_ID`s** (`Start_Object_ID`, `End_Object_ID`).
- Generalization/inheritance is expressed as a `Generalization` connector **and**
  `t_object.ParentID`; EA data models here use FK Associations instead.
- `DiagramID` is a convenience "home diagram" pointer; the authoritative per-diagram
  appearance is in `t_diagramlinks` (§7.3). A connector with `DiagramID=0` still
  renders wherever a `t_diagramlinks` row references it.

---

## 6. `t_xref` — stereotype application & style store

```sql
CREATE TABLE t_xref
(
    XrefID TEXT NOT NULL COLLATE NOCASE PRIMARY KEY,   -- own GUID
    Name TEXT NULL COLLATE NOCASE,          -- 'Stereotypes' | 'CustomProperties' | style key…
    Type TEXT NULL COLLATE NOCASE,          -- 'element property' | 'attribute property' | 'operation property' | 'connector property' | 'diagram property'…
    Visibility TEXT NULL COLLATE NOCASE,
    Namespace TEXT NULL COLLATE NOCASE,
    Requirement TEXT NULL COLLATE NOCASE,
    'Constraint' TEXT NULL COLLATE NOCASE,
    Behavior TEXT NULL COLLATE NOCASE,
    'Partition' TEXT NULL COLLATE NOCASE,
    Description TEXT NULL COLLATE NOCASE,    -- the payload (see below)
    Client TEXT NULL COLLATE NOCASE,        -- ea_guid of the element this row applies to
    Supplier TEXT NULL COLLATE NOCASE,
    Link TEXT NULL COLLATE NOCASE
)
```

`t_xref` is EA's catch-all cross-reference/serialization store. **The row count
(591) is dominated by stereotype applications.** For each element/feature that
has a *profiled* stereotype, EA writes a row:

```
Name='Stereotypes'
Type='attribute property'  (or 'element property' | 'operation property' | 'connector property')
Client=<ea_guid of the attribute/element/operation/connector>
Description='@STEREO;Name=column;FQName=EAUML::column;@ENDSTEREO;...'
```

`Type` distribution here: `attribute property`(364), `element property`(106),
`operation property`(76), `connector property`(35), `diagram properties`(6),
`diagram property`(2), `package property`(1), `SMLS`(1).

**Importer note:** the plain `Stereotype` *column* on `t_object`/`t_attribute`/…
drives label display, but a stereotype only binds to a **UML profile** (and picks
up its shape/tagged-value defaults) when the matching `t_xref` `@STEREO;…` row
exists. For a faithful export of profiled stereotypes (`column`, `table`,
`struct`, `Metaclass`, `profile`, `stereotype`), write **both** the column and
the `t_xref` row. For a bare, unprofiled diagram you can set only the column.

---

## 7. Diagram tables

### 7.1 `t_diagram`

```sql
CREATE TABLE t_diagram
(
    Diagram_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    Package_ID INTEGER NULL DEFAULT 1,      -- owning package
    ParentID INTEGER NULL DEFAULT 0,
    Diagram_Type TEXT NULL COLLATE NOCASE,  -- 'Logical' | 'Package' | 'Class' | 'Sequence' | 'Use Case' | …
    Name TEXT NULL COLLATE NOCASE,
    Version TEXT NULL DEFAULT '1.0' COLLATE NOCASE,
    Author TEXT NULL COLLATE NOCASE,
    ShowDetails INTEGER NULL DEFAULT 0,
    Notes TEXT NULL COLLATE NOCASE,
    Stereotype TEXT NULL COLLATE NOCASE,
    AttPub INTEGER NOT NULL DEFAULT 1,
    AttPri INTEGER NOT NULL DEFAULT 1,
    AttPro INTEGER NOT NULL DEFAULT 1,
    Orientation TEXT NULL DEFAULT 'P' COLLATE NOCASE,   -- 'P' portrait | 'L' landscape
    cx INTEGER NULL DEFAULT 0,              -- canvas size
    cy INTEGER NULL DEFAULT 0,
    Scale INTEGER NULL DEFAULT 100,
    CreatedDate TEXT, ModifiedDate TEXT,
    HTMLPath TEXT NULL COLLATE NOCASE,
    ShowForeign INTEGER NOT NULL DEFAULT 1,
    ShowBorder INTEGER NOT NULL DEFAULT 1,
    ShowPackageContents INTEGER NOT NULL DEFAULT 1,
    PDATA TEXT NULL COLLATE NOCASE,
    Locked INTEGER NOT NULL DEFAULT 0,
    ea_guid TEXT NULL COLLATE NOCASE,
    TPos INTEGER NULL,
    Swimlanes TEXT NULL COLLATE NOCASE,     -- swimlane def string
    StyleEx TEXT NULL COLLATE NOCASE        -- 'ExcludeRTF=0;DocAll=0;HideQuals=0;…;SaveTag=…'
)
```

`Diagram_Type` here: `Logical`(14) + `Package`(1). `StyleEx` carries a
`;`-delimited option string; EA stamps a `SaveTag=<hex>` on save (optional to
reproduce). Legal types are in `t_diagramtypes` (15 rows).

### 7.2 `t_diagramobjects` — element placement (rectangles)

```sql
CREATE TABLE t_diagramobjects
(
    Diagram_ID INTEGER NULL DEFAULT 0,      -- FK t_diagram.Diagram_ID
    Object_ID INTEGER NULL DEFAULT 0,       -- FK t_object.Object_ID
    RectTop INTEGER NULL DEFAULT 0,
    RectLeft INTEGER NULL DEFAULT 0,
    RectRight INTEGER NULL DEFAULT 0,
    RectBottom INTEGER NULL DEFAULT 0,
    Sequence INTEGER NULL DEFAULT 0,        -- Z-order (higher = drawn first / behind)
    ObjectStyle TEXT NULL COLLATE NOCASE,   -- 'DUID=…;HideIcon=0;ImageID=0;…'
    Instance_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
)
```

**Coordinate convention (important):** EA's diagram Y-axis grows **downward as
increasingly negative**. `RectLeft < RectRight`, but `RectTop > RectBottom`
numerically (top edge is the *less* negative). Example row:
`RectLeft=753, RectRight=879, RectTop=-192, RectBottom=-348` →
width `= RectRight-RectLeft = 126`, height `= RectTop-RectBottom = 156`.
Compute width/height as `Right-Left` and `Top-Bottom`; do not assume all-positive
coordinates. `ObjectStyle` is a `;`-delimited style string; `DUID` is a per-placement
diagram-unique id EA generates.

### 7.3 `t_diagramlinks` — connector routing/appearance per diagram

```sql
CREATE TABLE t_diagramlinks
(
    DiagramID INTEGER NULL,                 -- FK t_diagram.Diagram_ID
    ConnectorID INTEGER NULL DEFAULT 0,     -- FK t_connector.Connector_ID
    Geometry TEXT NULL COLLATE NOCASE,      -- 'SX=..;SY=..;EX=..;EY=..;EDGE=..;$LLB=;LLT=;…'
    Style TEXT NULL COLLATE NOCASE,         -- appearance string
    Hidden INTEGER NOT NULL DEFAULT 0,
    Path TEXT NULL COLLATE NOCASE,          -- custom waypoints, e.g. 'x:y;x:y;' (often empty = auto-route)
    Instance_ID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
)
```

`Geometry` encodes end offsets (`SX/SY` source, `EX/EY` dest), the attach `EDGE`
(1=top,2=right,3=bottom,4=left, per observed values), and label-position slots
(`LLB/LLT/LMT/LMB/LRT/LRB`). `Path` holds manual bend points; empty means EA
auto-routes. A connector is only visible on a diagram when a `t_diagramlinks`
row references it (mirror of `t_diagramobjects` for elements).

---

## 8. How it all fits together

```
t_package (tree: Parent_ID → Package_ID)
   │  (non-root packages mirrored as…)
   └── t_object (Object_Type='Package', PDATA1 = its Package_ID)
t_object  (elements; Package_ID → owning package)
   ├── t_attribute        Object_ID → t_object.Object_ID          (columns)
   ├── t_operation        Object_ID → t_object.Object_ID          (constraints)
   │      └── t_operationparams  OperationID → t_operation.OperationID   (columns in constraint)
   │      └── t_operationtag     ElementID   → t_operation.OperationID   (FK rules, etc.)
   ├── t_attributetag     ElementID → t_attribute.ID
   ├── t_objectproperties Object_ID → t_object.Object_ID          (tagged values)
   └── t_xref             Client = t_object.ea_guid               (profiled stereotypes, styles)
t_connector (Start_Object_ID / End_Object_ID → t_object.Object_ID)
   ├── t_connectortag     ElementID → t_connector.Connector_ID
   └── t_xref             Client = t_connector.ea_guid
t_diagram (Package_ID → t_package.Package_ID)
   ├── t_diagramobjects   Diagram_ID → t_diagram; Object_ID → t_object   (placement)
   └── t_diagramlinks     DiagramID  → t_diagram; ConnectorID → t_connector (routing)
```

The **model tree** (Browser) is `t_package` + `t_object`. The **diagrams** are a
separate presentation layer that *references* elements/connectors by numeric ID;
an element can appear on many diagrams or none. Deleting a diagram never deletes
model elements.

---

## 9. Minimal valid file & generation strategy

### Recommendation: **ship an empty template, INSERT into it.** Do not build from scratch.

A `.qea` that EA will open cleanly requires **the complete schema (~160 tables +
all indexes)** plus **fully populated seed reference tables** and **the `usys*`
magic**. Reproducing all of that by hand in an exporter is a large, brittle
surface. The robust approach:

1. Keep a **committed, blank `empty.qea`** in the repo (create it once from EA:
   *New Project → save as `.qea`* with zero user content, or `VACUUM INTO` a
   fresh copy of a known-good empty EA base). This template already contains:
   - the full DDL for every `t_*`/`usys*` table and every index,
   - seed data: `t_datatypes`(694), `t_stereotypes`(130), `t_objecttypes`(80),
     `t_connectortypes`(30), `t_diagramtypes`(15), `t_cardinality`(7),
     `t_propertytypes`, `t_primitives`, `t_constants`, `t_genopt`, `t_ecf`/`t_tcf`,
     `t_template`, …,
   - `usys_schema` with its version-encoding column name (`V1558` here),
   - `usysTables`/`usysOldTables`/`usysQueries`,
   - `usys_system` with the ~109 EA feature flags + a `ProjectGUID`,
   - the root `Model` package row in `t_package` (Package_ID=1, Parent_ID=0).
2. On export, **copy the template** to the output path, open it read-write, and
   INSERT the model rows in FK-safe order (below). Regenerate a fresh
   `ProjectGUID` if you want a distinct repository identity.
3. Fix `sqlite_sequence` (below), `COMMIT`, and checkpoint/close.

**What actually makes a file "valid enough to open":**
- The schema and indexes must exist. EA validates the schema rev via
  `usys_schema` (the column-name marker) and the `usys_system` `EA###Updates`
  flags — mismatches trigger an upgrade prompt or a refusal. Copying a template
  from the target EA version sidesteps this entirely.
- Seed tables (`t_datatypes`, `t_stereotypes`, `t_objecttypes`,
  `t_connectortypes`, `t_diagramtypes`, `t_cardinality`) must be present or
  dropdowns/type-resolution break. These are static per EA version → keep them
  in the template.
- Security tables may stay empty.
- At least the root `Model` package (`t_package` Package_ID=1) should exist so
  the Browser has a root.

**Generating from scratch is possible but not worth it:** you would have to
reproduce every seed row and every `usys_system` flag verbatim for the exact EA
version, and any drift risks EA rejecting or "repairing" the file. Prefer the
template-copy approach; fall back to scratch only if you must be dependency-free,
in which case snapshot the full `.dump` of an empty EA `.qea` and replay it.

### 9.1 INSERT ordering for export (FK-safe)

There are **no DB-level foreign keys** (all relationships are logical), so SQLite
won't stop you — but ordering keeps referential integrity and matches EA's own
`usysTables.RelOrder`:

```
1. t_package            (parents before children: order by Parent_ID depth)
2. t_object             (+ its Package-mirror rows; set ParentID after all objects exist)
3. t_attribute
   t_operation
   t_diagram
   t_objectproperties
4. t_operationparams
   t_connector          (needs Start/End Object_IDs to exist)
   t_diagramobjects     (needs Diagram_ID + Object_ID)
   t_diagramlinks       (needs Diagram_ID + Connector_ID)
5. t_attributetag / t_operationtag / t_connectortag
   t_xref               (stereotype applications; Client = element ea_guid)
```

`usysTables.RelOrder` for these tables (EA's own hint): `t_package`=1,
`t_object`=3, `t_diagram`/`t_operation`/`t_objectproperties`=5,
`t_attribute`/`t_connector`/`t_diagramlinks`/`t_diagramobjects`/`t_operationparams`=6,
`t_xref`=7.

### 9.2 Autoincrement / `sqlite_sequence`

Every core PK is `AUTOINCREMENT`. Either let SQLite assign IDs (omit the PK in
INSERT) **or** insert explicit IDs and then bump `sqlite_sequence` so EA's next
allocation doesn't collide:

```sql
-- after bulk insert with explicit IDs:
UPDATE sqlite_sequence SET seq = (SELECT MAX(Object_ID) FROM t_object) WHERE name='t_object';
-- …repeat for t_package, t_attribute(ID), t_operation, t_connector,
--   t_diagram, t_diagramobjects, t_diagramlinks, t_objectproperties, t_operationtag …
```

Observed high-water marks in the sample (`sqlite_sequence`): `t_object`=229,
`t_attribute`=492, `t_connector`=87, `t_operation`=134, `t_diagram`=40,
`t_diagramobjects`=236, `t_diagramlinks`=78, `t_objectproperties`=309,
`t_package`=42, `t_operationtag`=109 — all safely above `MAX(pk)` (EA leaves gaps).

### 9.3 `usys_system` magic worth knowing

Key→value rows that matter: `ProjectGUID` (repository identity — regenerate for a
new repo), `EA###Updates` flags (`EA300`…`EA1310Updates` = schema-migration
checkpoints; keep from template), `Version=4.01`, and dozens of feature
registrations (`EAGUID`, `TaggedVals`, `Stereotypes`, `Namespace`, `CodeGen`,
`DDL`, …) all set to `1`. Treat this table as opaque template content; only
`ProjectGUID` is worth rewriting.

---

## 10. Notes on this specific sample (`oqo.qea`)

- **What it is:** a backend design model for an app called **"OQO App"**,
  primarily a **PostgreSQL data model** (`GenType='PostgreSQL'`, `DBMS`
  tagged value = PostgreSQL).
- **Content scale:** 16 packages, 141 elements (**104 classes — 75 of them DB
  tables** e.g. `user_session`, `user_profile`, `user_media`, `user_match`,
  `group_member`, `community_note_vote`; plus 9 `struct`, 9 `stereotype`, 4
  `function`, 1 `view`, 1 `Metaclass`), 421 attributes (columns), 121 operations
  (PK/FK/index constraints), 63 connectors (39 FK Associations), and **15
  diagrams** (14 `Logical` + 1 `Package`) named *OQO App, PostgreSQL Model
  Structure, Traceability, Conceptual Model, Logical Model, Database A, Functions,
  Queries, Sequences, Tables, Views, View Dependency, Connections, Minimialist*.
- **Profiles:** a `Swift` root package holds a small UML profile ("Swift
  Sterotypes") with `Metaclass`/`stereotype`/`struct` elements and `Extension`
  connectors — a good exercise for stereotype/`t_xref` round-tripping.
- **Good fixture because** it covers: package nesting, the package-mirror-element
  pattern, class↔attribute↔operation↔param chains, FK Associations with
  cardinality/roles, operation tagged values (FK rules), element tagged values
  (Owner/Tablespace/DBVersion, `funcdef`/`viewdef` memos), Notes+NoteLinks,
  Boundary grouping frames, Artifacts (DB connections), multiple diagrams with
  real coordinates, and profiled stereotypes in `t_xref`.
- **Does NOT exercise:** `Interface`/`Enumeration` elements, `Generalization`
  connectors, `Sequence` diagrams, security, or version control — an importer
  must still handle these from the `t_objecttypes`/`t_connectortypes` vocabulary.

---

## Appendix A — Quick reference: type vocabularies observed

**`Object_Type`** (this file): `Class`, `Package`, `Boundary`, `Note`,
`Artifact`, `Constraint`. (Legal set = `t_objecttypes`, 80 rows.)

**Class `Stereotype`** (this file): `table`, `struct`, `stereotype`, `function`,
`view`, `Metaclass`. **Artifact `Stereotype`**: `database connection`,
`EAReportSpecification`. **Package `Stereotype`**: `Database`, `DataModel`,
`profile`.

**`Connector_Type`** (this file): `Association`, `Extension`, `Dependency`,
`NoteLink`. (Legal set = `t_connectortypes`, 30 rows.)

**`Diagram_Type`** (this file): `Logical`, `Package`. (Legal set =
`t_diagramtypes`, 15 rows.)

**`t_cardinality`** dropdown values: `*`, `0`, `0..*`, `0..1`, `1`, `1..`, `1..*`.

**Operation `Stereotype`** in data models: `PK`, `FK`, `index`, `unique`.

**Attribute `Stereotype`** in data models: `column`.
