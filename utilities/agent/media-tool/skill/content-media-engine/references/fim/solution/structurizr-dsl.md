# Structurizr DSL — Model-as-Code C4 Architecture

Structurizr DSL is a text language that describes a single C4 **model** once (people, systems, containers, components, deployment nodes) and then defines multiple **views** over it. Unlike diagram-per-file tools, you build the model, then ask for a system-context view, a container view, a deployment view, etc., and the tool generates each. It exports to PlantUML, Mermaid, C4-PlantUML, DOT, WebSequence, and JSON, or renders in the Structurizr web/on-prem UI.

**Current Version**: Structurizr DSL v1.x (via `structurizr-cli` / `structurizr/lite`)  **License**: Apache-2.0 (DSL + CLI); cloud service is commercial  **Runtime**: JVM CLI, Docker (`structurizr/cli`, `structurizr/lite`), or the hosted service

## Official Resources & Documentation
- **DSL reference**: https://docs.structurizr.com/dsl
- **DSL language cookbook**: https://docs.structurizr.com/dsl/cookbook
- **C4 model**: https://c4model.com
- **CLI**: https://github.com/structurizr/cli
- **Structurizr Lite (self-host)**: https://docs.structurizr.com/lite
- **Example workspaces**: https://github.com/structurizr/examples

## Installation & Setup

### CLI (export to other formats)
```bash
# Homebrew
brew install structurizr-cli

# Docker: export a workspace to PlantUML
docker run --rm -v "$PWD:/usr/local/structurizr" structurizr/cli \
  export -workspace workspace.dsl -format plantuml/c4plantuml

# Other formats: mermaid, dot, websequencediagrams, json, ilograph, plantuml
structurizr-cli export -workspace workspace.dsl -format mermaid
```

### Structurizr Lite (interactive local viewer)
```bash
# Renders workspace.dsl from the mounted dir at http://localhost:8080
docker run --rm -p 8080:8080 -v "$PWD:/usr/local/structurizr" structurizr/lite
```

A workspace lives in a single `workspace.dsl` file (plus optional `!include` fragments, `!docs`, and `!adrs`).

## Core Syntax / API Reference

### Top-level shape
```text
workspace "Name" "Optional description" {

    model {
        # people, software systems, containers, components,
        # groups, and deployment environments
    }

    views {
        # one block per view + styles + themes
    }
}
```
`workspace`, `model`, and `views` are the three mandatory blocks. Keywords are case-insensitive; identifiers are case-sensitive.

### Model elements
```text
model {
    u = person "User" "A customer" "external"          // name, desc, tags
    admin = person "Administrator"

    s = softwareSystem "Banking Platform" "Core system" {
        web  = container "Web App" "Serves UI" "React"     // name, desc, technology
        api  = container "API" "Business logic" "Go"
        db   = container "Database" "Stores data" "PostgreSQL" "Database"

        api = container "API" {                            // block form for components
            router = component "Router" "Routes requests" "Express"
            auth   = component "Auth" "Validates tokens" "JWT"
        }
    }

    ext = softwareSystem "Payment Gateway" "3rd party" "External"
}
```
- `person <name> [description] [tags]`
- `softwareSystem <name> [description] [tags] { ... }`
- `container <name> [description] [technology] [tags] { ... }`
- `component <name> [description] [technology] [tags] { ... }`
- Assign an identifier (`web = container ...`) to reference it in relationships and views.

### Groups
```text
model {
    group "Internal" {
        api = softwareSystem "API"
        db  = softwareSystem "DB"
    }
    group "External" {
        pay = softwareSystem "Payments"
    }
}
```
`group "name" { ... }` is a visual/logical bucket; nested groups need `!identifiers hierarchical` or the `properties { "structurizr.groupSeparator" "/" }` setting.

### Relationships
```text
u   -> web "Uses" "HTTPS"                       // source -> dest "desc" "technology"
web -> api "Calls" "JSON/HTTPS" "async"         // + tags
api -> db  "Reads/Writes" "SQL"
api -> pay "Charges card" "REST" {
    tags "critical"
}
```
Grammar: `source -> destination "description" "technology" "tags"`. Only `->` and the destination are required. Relationships can be declared inside an element block (implicit source) or at model top level.

### Identifiers
```text
workspace {
    !identifiers hierarchical   // refer to elements by path: s.web, s.api.router
    model {
        s = softwareSystem "S" {
            web = container "Web"
        }
    }
}
```
Default is `flat` (each identifier unique across the whole workspace). `!identifiers hierarchical` scopes identifiers to their parent so you can reuse short names and reference via dotted paths.

### Views
```text
views {
    systemLandscape "Landscape" {
        include *
        autoLayout lr
    }
    systemContext s "Context" {
        include *
        autoLayout
    }
    container s "Containers" {
        include *
        autoLayout tb
    }
    component api "APIComponents" {
        include *
        autoLayout
    }
    dynamic s "LoginFlow" {
        u -> web "1. Opens app"
        web -> api "2. Authenticates"
        autoLayout
    }
    deployment s "Production" "ProdDeploy" {
        include *
        autoLayout
    }
    filtered "Context" include "external" "ExternalOnly"
    image api "diagram.png"                 // embed an external image as a view
    custom "Custom" "MyDiagram" {           // free-form element view
        include *
    }
}
```
View types: `systemLandscape`, `systemContext <system>`, `container <system>`, `component <container>`, `dynamic <scope>`, `deployment <system|*> <environment>`, `filtered <baseKey>`, `image`, and `custom`. First arg after the type is the scope element; the trailing string is the view **key**.

### Auto-layout vs manual
```text
container s {
    include *
    autoLayout lr 300 150      // rankDirection(tb|bt|lr|rl) rankSep nodeSep
}
```
`autoLayout` uses Graphviz-style ranking. Omit it to position elements manually in the Structurizr UI (positions persist in the workspace JSON). `include`/`exclude` control membership: `include *`, `include u web`, `exclude "external"`.

### Deployment environments
```text
model {
    prod = deploymentEnvironment "Production" {
        deploymentNode "AWS" "us-east-1" {
            deploymentNode "EKS" "Kubernetes 1.29" {
                api_inst = containerInstance api       // deploy a container
            }
            deploymentNode "RDS" "PostgreSQL 16" {
                db_inst = containerInstance db
            }
            infrastructureNode "ALB" "Application Load Balancer"
        }
        softwareSystemInstance ext                     // deploy a whole system
    }
}
```
`deploymentNode` nests arbitrarily; leaves are `containerInstance`, `softwareSystemInstance`, and `infrastructureNode`. Reference these in a `deployment` view.

## Supported View / Output Types (full enumeration)
- **System Landscape** — all people + systems in the enterprise.
- **System Context** — one system + its immediate users/dependencies.
- **Container** — containers inside a system.
- **Component** — components inside a container.
- **Dynamic** — ordered, numbered runtime collaboration.
- **Deployment** — infrastructure mapping per environment.
- **Filtered** — a base view with a tag include/exclude filter.
- **Image** — embed a rendered/external image as a view.
- **Custom** — free-form element diagram outside strict C4.
- **Export formats**: PlantUML, C4-PlantUML, Mermaid, DOT/Graphviz, WebSequenceDiagrams, Ilograph, and JSON (the canonical model).

## How-To (worked recipes)

### How to add colors, styling & themes (tag-driven styles)
Structurizr styles **by tag** in the `views { styles { ... } }` block. Every element/relationship has implicit tags (`Element`, `Person`, `Container`, `Relationship`) plus any you add:
```text
views {
    container s {
        include *
        autoLayout
    }

    styles {
        element "Element" {
            color #ffffff
            fontSize 22
        }
        element "Person" {
            shape person
            background #08427b
        }
        element "Container" {
            background #1168bd
        }
        element "Database" {
            shape cylinder
            background #2e7d32
        }
        element "External" {
            background #999999
        }
        element "critical" {
            background #b22222
            border dashed
        }
        relationship "Relationship" {
            color #707070
            dashed true
            thickness 2
        }
        relationship "async" {
            color #8e44ad
            dashed true
        }
    }
}
```
Element style keys: `background`, `color`, `stroke`, `border` (`solid|dashed|dotted`), `shape` (`box`, `roundedBox`, `circle`, `ellipse`, `hexagon`, `cylinder`, `person`, `robot`, `folder`, `component`, `pipe`, `webBrowser`, `mobileDevicePortrait/Landscape`), `icon`, `fontSize`, `width`, `height`, `opacity`, `metadata`, `description`. Relationship keys: `color`, `thickness`, `dashed`, `style`, `routing` (`Direct|Orthogonal|Curved`), `fontSize`, `width`, `position`. Attach a custom tag with `tags "critical"` on the element/relationship, then style that tag.

### How to apply a shared theme
```text
views {
    theme https://static.structurizr.com/themes/amazon-web-services-2023.04.30/theme.json
    # or several:
    themes https://example.com/theme-a.json https://example.com/theme-b.json
}
```
`theme <url>` / `themes <url> <url> ...` load remote style + icon packs (AWS, Azure, GCP, Kubernetes themes are published by Structurizr). Local `styles {}` still override themed values.

### How to write a full workspace (model + views + styles)
```text
workspace "Internet Banking" "C4 model of the banking platform" {

    model {
        customer = person "Customer" "A retail banking customer"

        banking = softwareSystem "Internet Banking System" {
            spa = container "Single-Page App" "Banking UI in the browser" "React"
            api = container "API Application" "Banking features via REST" "Go" {
                signin = component "Sign-In Controller" "Handles auth" "Go"
                accounts = component "Accounts Controller" "Account queries" "Go"
            }
            db = container "Database" "Users, accounts, transactions" "PostgreSQL" "Database"
        }

        mainframe = softwareSystem "Mainframe Banking" "Core account system" "External"
        email = softwareSystem "E-mail System" "Microsoft Exchange" "External"

        customer -> spa "Uses" "HTTPS"
        spa -> api "Calls" "JSON/HTTPS"
        api -> db "Reads/Writes" "SQL"
        api -> mainframe "Uses" "XML/HTTPS"
        api -> email "Sends mail via" "SMTP"

        prod = deploymentEnvironment "Production" {
            deploymentNode "AWS" "us-east-1" {
                deploymentNode "EKS" "Kubernetes" {
                    containerInstance api
                    containerInstance spa
                }
                deploymentNode "RDS" "PostgreSQL 16" {
                    containerInstance db
                }
            }
        }
    }

    views {
        systemContext banking "Context" {
            include *
            autoLayout lr
        }
        container banking "Containers" {
            include *
            autoLayout lr
        }
        component api "APIComponents" {
            include *
            autoLayout
        }
        deployment banking prod "ProdDeployment" {
            include *
            autoLayout
        }

        styles {
            element "Person" { shape person; background #08427b; color #ffffff }
            element "Container" { background #1168bd; color #ffffff }
            element "Database" { shape cylinder }
            element "External" { background #999999; color #ffffff }
            relationship "Relationship" { dashed false; thickness 2 }
        }
    }
}
```

### How to attach docs, ADRs, includes, and constants
```text
workspace {
    !constant ORG "Acme Corp"
    !include model-fragment.dsl
    model { }
    views {
        !docs docs        // Markdown/AsciiDoc under ./docs
        !adrs adrs        // architecture decision records under ./adrs
    }
}
```
`!constant NAME "value"` then `${NAME}` interpolation; `!include path-or-url` splices another DSL fragment; `!docs`/`!adrs` fold documentation and ADRs into the workspace.

## Do's and Don'ts

### ✅ Do
- Define the model once and derive many views — that's the whole point; don't copy elements per diagram.
- Give every element an identifier (`api = container ...`) and wire relationships between identifiers.
- Style by **tag** in `styles {}`; add semantic tags (`"Database"`, `"critical"`) rather than hand-coloring each element.
- Use `autoLayout` for first drafts; switch to manual positioning (Lite/cloud) only when you need control, and it persists.
- Turn on `!identifiers hierarchical` in large workspaces so you can reuse short names under different parents.
- Keep the workspace in one `workspace.dsl` and split large models with `!include` fragments.

### ❌ Don't
- Don't declare the same real-world element twice — reference the single identifier everywhere.
- Don't put styling inside `model {}` — element/relationship styles live in `views { styles { ... } }`.
- Don't rely on the hosted cloud for private teams without a subscription; use `structurizr/lite` locally for free.
- Don't expect general-purpose diagrams — Structurizr is C4/architecture-scoped; use `plantuml.md`/`mermaid.md` for flowcharts, ER, gantt, etc.
- Don't forget the view **key** (trailing string) — omitting it makes automation/diffs harder and can collide.
- Don't hardcode absolute theme URLs you can't reach in CI — vendor or cache theme JSON for reproducible exports.

## Styling, Theming & Customization
- **`styles { element "tag" { ... } relationship "tag" { ... } }`** — the core styling surface, tag-matched.
- **Shapes & icons**: `shape` (box/cylinder/person/hexagon/pipe/webBrowser/…), `icon <url|data-uri>` per tag.
- **Themes**: `theme <url>` / `themes <url> ...` for published palettes (AWS/Azure/GCP/Kubernetes) plus your local overrides.
- **Branding**: `configuration { branding { logo <url>; font "Name" <url> } }` for org logo/typography.
- **Terminology**: `configuration { terminology { person "Actor"; softwareSystem "System"; container "Service" } }` renames C4 vocabulary in output.
- **Properties & perspectives**: `properties { "key" "value" }` on elements; `perspectives { "Security" "desc" }` add cross-cutting annotations surfaced in the UI.

## Advanced Features
- **Multiple export targets** from one model: PlantUML, C4-PlantUML, Mermaid, DOT, Ilograph, JSON.
- **Dynamic views** with explicit ordering for runtime/sequence-like flows.
- **Deployment modeling** with nested nodes, instances, and infrastructure nodes across environments.
- **Filtered views** to produce focused variants (`filtered <base> include|exclude "tag"`).
- **`!docs` / `!adrs`** embed Markdown/AsciiDoc documentation and ADRs alongside the model.
- **Scripting/automation**: the JSON workspace is the API; CI can export SVGs or push to Structurizr on-premises.
- **`!plugin` / `!script`** hooks (CLI) run Groovy/Kotlin/JS to programmatically mutate the workspace.

## Common Pitfalls & Troubleshooting
- **"Element not found" in a view** — the identifier is misspelled or out of scope; with hierarchical identifiers use the dotted path.
- **Empty diagram** — you forgot `include *` (or `include <ids>`) inside the view block.
- **Styles ignored** — the tag string must exactly match a tag on the element; check case and that the style is under `views { styles }`.
- **Export layout looks unpositioned** — PlantUML/Mermaid exports don't carry manual positions; use `autoLayout` for headless exports.
- **Theme not applied on export** — the CLI must fetch the theme URL; cache it locally or embed styles for offline builds.
- **Group nesting not showing** — enable `!identifiers hierarchical` or set the group separator property.

## Integration Notes
- **Structurizr Lite / on-prem** render `workspace.dsl` directly in a browser with manual layout persistence.
- **CI**: `structurizr-cli export` produces PlantUML/Mermaid/SVG artifacts; chain with `plantuml.jar` for PNG/SVG.
- **Docs pipelines**: export Mermaid for MkDocs/Docusaurus, or PlantUML for AsciiDoc/Confluence.
- **Round-trip with PlantUML**: export `c4plantuml` to hand a diagram to the `c4-plantuml.md` toolchain.

## Best For / Avoid For
`c4-architecture`, `model-as-code`, `multi-view-diagrams`, `deployment-modeling`, `architecture-as-code`, `adr-docs`, `git-versioned-architecture`

Avoid for: one-off single diagrams (the model overhead isn't worth it — use `c4-plantuml.md`), or non-architecture diagram types (flowcharts/ER/gantt → `plantuml.md`/`mermaid.md`).

## See Also
- [c4-plantuml.md](c4-plantuml.md) — direct C4 macros (a Structurizr export target)
- [plantuml.md](plantuml.md) — base engine + all non-C4 diagram types
- [uml-xmi.md](uml-xmi.md) — UML model interchange with modeling tools
- [mermaid.md](mermaid.md) — browser-native diagrams (a Structurizr export target)
- [graphviz.md](graphviz.md) — the DOT layout engine behind auto-layout
- [../use-case/diagram-generation.md](../use-case/diagram-generation.md) — choosing a diagram solution
- [../use-case/engineering-diagrams.md](../use-case/engineering-diagrams.md) — architecture/engineering diagram patterns
