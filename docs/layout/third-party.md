# 3rd-party/ — Third-Party Source for Custom Docker Builds

Vendored upstream source repos (git subtrees) built into custom Docker images for
self-hosting. Build/push all of them with `utilities/push-3rd-party-images.sh`; individual
images are declared in root `.infra-config.yaml`.

```
3rd-party/
├── bottlecrm/                  # CRM (backend + frontend)
├── chartdb/                    # Database schema visualizer
├── codex/                      # OpenAI Codex CLI (Rust) — vendored build
├── directus/                   # Headless CMS / data platform
├── drawio/                     # Diagram editor
├── excalidraw/                 # Whiteboard / sketch editor
├── excalidraw-room/            #   Excalidraw collaboration server
├── kroki/                      # Diagram-as-code gateway (mermaid, bpmn, vega, wavedrom, …)
├── llama.cpp/                  # LLM inference engine (custom image builds)
├── mermaid-live-editor/        # Mermaid live editor
├── mydraft-server2/            # mydraft collaboration server
├── n8n/                        # Workflow automation platform
├── penpot/                     # Open-source design & prototyping
├── plantuml/                   # PlantUML (library/source)
├── plantuml-server/            #   PlantUML rendering server
├── terraform-provider-signoz/  # Custom SigNoz Terraform provider
├── webstudio/                  # Visual web builder
└── zellij/                     # Terminal multiplexer (custom build)
```

> These are large upstream trees. Treat their internal layout as owned by upstream; this repo
> only cares about the Dockerfile(s) and the `.infra-config.yaml` image mappings.
