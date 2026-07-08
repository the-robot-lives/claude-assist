# TheRobotDrafts Example Diagrams Manifest

**Status:** Planning Phase  
**Total Diagram Types:** 47  
**Total Examples:** 141 (47 diagram types × 3 complexity levels)  

---

## Purpose

Provide a library of example diagrams that demonstrate best practices for each diagram type supported by TheRobotDrafts. Examples should be accessible, discoverable, and clonable as starting points for new diagrams.

---

## Example Storage Architecture

### Directory Structure
```
docs/diagrams/examples/
├── index.md                          # Main catalog and search interface
├── quick-start.md                    # How to find, access, and clone examples
├── README.md                         # This file - overview and navigation
├── tier1-codereverse/                # Core round-trip from code
│   ├── class-diagram/
│   │   ├── simple-banking-domain.puml
│   │   ├── medium-ecommerce-system.puml  
│   │   ├── complex-enterprise-app.puml
│   │   └── variants/
│   │       ├── interface-focused.puml
│   │       ├── inheritance-heavy.puml
│   │       └── composition-patterns.puml
│   ├── sequence-diagram/
│   ├── package-diagram/
│   ├── component-diagram/
│   ├── deployment-diagram/
│   └── erd-data-model/
├── tier2-modeling/                   # Full modeling coverage
│   ├── object-diagram/
│   ├── composite-structure/
│   ├── profile-diagram/
│   ├── usecase-diagram/
│   ├── activity-diagram/
│   ├── state-machine/
│   ├── communication-diagram/
│   ├── sysml-bdd/
│   ├── sysml-ibd/
│   ├── sysml-parametric/
│   ├── sysml-package/
│   ├── sysml-activity/
│   ├── sysml-requirement/
│   ├── bpmn-process/
│   ├── bpmn-collaboration/
│   ├── bpmn-choreography/
│   ├── dmn-decision/
│   ├── requirements-trace/
│   └── data-flow/
├── tier3-enterprise/                 # Enterprise architecture and specialized
│   ├── timing-diagram/
│   ├── interaction-overview/
│   ├── sysml-block-bdd/
│   ├── sysml-internal-bdd/
│   ├── archimate-strategy/
│   ├── archimate-business/
│   ├── archimate-application/
│   ├── archimate-technology/
│   ├── uaf-updm/
│   ├── togaf-adm/
│   ├── zachman/
│   ├── mindmap/
│   ├── gantt-kanban/
│   ├── wireframe/
│   ├── whiteboard/
│   ├── network/
│   ├── xsd-wsdl/
│   └── rose-realtime/
└── templates/                        # Clone-able starter templates
    ├── uml-class-basic.template
    ├── sequence-flow.template
    ├── bpmn-process.template
    ├── state-machine.template
    └── mindmap.template
```

---

## FileNaming Convention

- **Main examples**: `{complexity}-{domain}.puml`
  - Complexity: `simple`, `medium`, `complex`
  - Domain: descriptive use case (e.g., `banking-domain`, `ecommerce-system`)
- **Variants**: `{approach}/{mechanism}.puml`
  - Approach: architectural pattern or focus area
  - Mechanism: specific technique being demonstrated
- **Templates**: `{diagram-type}-{style}.template`
  - Style: basic, advanced, minimal, etc.

---

## Format Specifications

### PlantUML Files
- Standard `.puml` extension
- Include metadata header:
  ```plantuml
  @startuml
  !include https://raw.githubusercontent.com/TheRobotDrafts/examples/master/theme/theme.puml
  
  title Example Class Diagram - Simple Banking Domain
  author TheRobotDrafts Examples
  description Demonstrates basic class relationships, inheritance, and associations
  usecase Educational example showing fundamental UML class concepts
  complexity simple
  domain Banking
  
  ' Diagram content here...
  
  @enduml
  ```

### XMI Files (for interchange)
- `.xmi` extension for UML/SysML models
- Standard OMG XMI 2.5.1 format
- Compatible with Sparx EA, IBM Rational Rose, etc.

### Mermaid JS (alternative format)
- `.mmd` extension  
- Modern, web-friendly alternative to PlantUML
- Useful for GitHub integration and web rendering

---

## Access and Discovery System

### 1. Main Index (index.md)
- **Searchable catalog** with filters:
  - Diagram type (dropdown)
  - Complexity level (simple/medium/complex)
  - Domain/industry (banking, healthcare, IoT, etc.)
  - Technique/variant (pattern, mechanism)
- **Quick browse** by tier and diagram type
- **Preview thumbnails** showing key characteristics
- **Clone button** for each example

### 2. Quick Start Guide (quick-start.md)
- Step-by-step instructions for:
  - Finding the right example
  - Understanding the example structure  
  - Cloning and modifying for your needs
  - Common modification patterns

### 3. Breadcrumb Navigation
- Each example includes navigation path:
  - `Home > Tier 1 > Class Diagram > Simple > Banking Domain`
- Links to related examples and variants

### 4. Interactive Selection Matrix
- Visual matrix for quick selection:
  - Rows: Diagram Types
  - Columns: Complexity Levels
  - Cells: Link to example + badge count

---

## Cloning and Template System

### 1. Template Repository
- Base templates for common starting points
- Pre-configured with:
  - Standard UML shapes and styles
  - Common patterns and relationships
  - Best practice configurations

### 2. Clone Workflow
1. **Browse** examples catalog
2. **Select** suitable example/template
3. **Clone** creates copy in user workspace
4. **Customize** using drag-drop editing
5. **Export** to desired format

### 3. Smart Suggestions
- Suggest related examples based on:
  - Recently viewed diagrams
  - Similar domain patterns
  - Popular starting points

---

## Content Guidelines

### 1. Complexity Levels

**Simple Examples:**
- 3-7 elements total
- Single relationship type focus
- Clear, pedagogical progression
- Educational value over completeness

**Medium Examples:**
- 8-15 elements
- Multiple relationship types
- 1-2 advanced concepts
- Real-world scenario abstraction

**Complex Examples:**
- 16+ elements  
- Full feature set demonstrated
- Industry-standard patterns
- Production-level complexity

### 2. Domain Diversity
Cover multiple industries and problem domains:
- **Software**: Web apps, mobile apps, APIs
- **Business**: Banking, e-commerce, logistics
- **Systems**: IoT, embedded, robotics
- **Enterprise**: BPM, requirements, architecture
- **Cross-domain**: Integration patterns

### 3. Variant Coverage

For each diagram type, provide variants demonstrating:
- **Design patterns** (Factory, Observer, Strategy, etc.)
- **Architectural styles** (Layered, microservices, event-driven)
- **Notation variations** (alternative UML/SysML features)
- **Industry conventions** (specific to banking, healthcare, etc.)
- **Common mistakes** and correct alternatives

---

## Subagent Assignment Plan

### Phase 1: Infrastructure (3 subagents)
1. **File Structure Creation Agent**
   - Create directory hierarchy
   - Set up naming conventions
   - Create template structure
   
2. **Index and Navigation Agent** 
   - Build main index with search system
   - Create quick-start guide
   - Implement selection matrix
   
3. **Metadata and Standards Agent**
   - Define file format specifications
   - Create metadata templates
   - Establish content guidelines

### Phase 2: Tier 1 Examples (6 diagram types × 3 levels = 18 examples)
4. **Class Diagram Agent**
   - Simple: Banking domain (3 classes)
   - Medium: E-commerce system (8 classes)
   - Complex: Enterprise application (20+ classes)
   - Variants: Interface-focused, inheritance-heavy, composition patterns

5. **Sequence Diagram Agent**
   - Simple: Login flow (3 participants)
   - Medium: Order processing (5 participants)
   - Complex: Distributed system transaction (10+ participants)
   - Variants: Async patterns, error handling, concurrent flows

6. **Package Diagram Agent**
   - Simple: Single module structure
   - Medium: Multi-module layered architecture
   - Complex: Enterprise system with dependencies
   - Variants: Microservices, monolith, hybrid

Continue pattern for Component, Deployment, ERD...

### Phase 3: Tier 2 Examples (17 diagram types × 3 = 51 examples)
Assign subagents for each diagram type in tier2-modeling directory.

### Phase 4: Tier 3 Examples (24 diagram types × 3 = 72 examples)
Assign subagents for each diagram type in tier3-enterprise directory.

### Phase 5: Quality Assurance (2 subagents)
27. **Consistency Review Agent**
   - Review naming conventions
   - Validate metadata completeness
   - Check format consistency

28. **UX and Usability Agent**
   - Test navigation flows
   - Validate clone workflows
   - Verify preview quality

---

## Implementation Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Infrastructure | Week 1 | File structure, indexing system, metadata templates |
| Tier 1 Content | Weeks 2-4 | 18 core examples with variants |
| Tier 2 Content | Weeks 5-9 | 51 modeling examples with variants |
| Tier 3 Content | Weeks 10-15 | 72 enterprise/specialized examples |
| QA & Polish | Weeks 16-17 | Final review, documentation, launch |
| Total | 17 weeks | Complete example library system |

---

## Success Metrics

1. **Coverage**: 47 diagram types × 3 complexity levels = 141 minimum examples
2. **Discoverability**: <30 seconds to find relevant example
3. **Clonability**: Single-click clone to working diagram
4. **Quality**: All examples pass syntax validation and pattern review
5. **Documentation**: Complete quick-start and variant guides
6. **Performance**: Index loads in <2 seconds, previews load in <3 seconds

---

## Related Documentation

- `/docs/specs/diagram-catalog.md` - Authoritative diagram type catalog
- `/docs/specs/file-formats.md` - Import/export format specifications  
- `/docs/CONCEPTS.md` - Core concepts (bubbles, edges, projections)
- `/docs/ARCHITECTURE.md` - System architecture and implementation

---

**Next Steps**: Begin Phase 1 infrastructure setup by assigning subagents for file structure, indexing, and metadata systems.