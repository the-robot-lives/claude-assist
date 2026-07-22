# Sites

Every site/service deployed from this monorepo: portfolio products (`.infra-config.yaml` → `project.projects[]`) and internal platform services (`terraform/kubernetes/platform/*`, `infra-services/`, `infra/`, `init/`).

## Portfolio product sites

| Site | Project Path | Components | Notes |
|---|---|---|---|
| [noizu.com](https://noizu.com) | projects/noizu.com | backend, frontend | Company site (Next.js + backend); API at [api.noizu.com](https://api.noizu.com) |
| [infra.noizu.com](https://infra.noizu.com) | projects/infra.noizu.com | web (static) | Infra portal |
| [codefre.sh](https://codefre.sh) | projects/codefre.sh | backend, frontend, web-landing | API at [api.codefre.sh](https://api.codefre.sh) |
| [starter.therobotlives.com](https://starter.therobotlives.com) (start-app) | components/start-app | backend, frontend | Reusable app scaffold instance, not an independent product domain |
| [aifighter.com](https://aifighter.com) | projects/aifighter.com | backend, frontend | API at [api.aifighter.com](https://api.aifighter.com) |
| [bladeofeternity.com](https://bladeofeternity.com) | projects/bladeofeternity.com | backend, web | |
| [derobot.is](https://derobot.is) | projects/derobot.is | teaser | |
| [designing.derobot.is](https://designing.derobot.is) | projects/designing.derobot.is | backend, frontend | API at [api.designing.derobot.is](https://api.designing.derobot.is) |
| [gotta.cc](https://gotta.cc) | projects/gotta.cc | backend, frontend | API at [api.gotta.cc](https://api.gotta.cc) |
| [iotgo.io](https://iotgo.io) | projects/iotgo.io | backend, frontend | API at [api.iotgo.io](https://api.iotgo.io) |
| [jailbreakingsite.com](https://jailbreakingsite.com) | projects/jailbreakingsite.com | backend, frontend | API at [api.jailbreakingsite.com](https://api.jailbreakingsite.com) |
| [noizurpg.com](https://noizurpg.com) | projects/noizurpg.com | web | |
| [robots-unite.com](https://robots-unite.com) | projects/robots-unite.com | web | |
| [therobotknows.com](https://therobotknows.com) | projects/therobotknows.com | backend, frontend | API at [api.therobotknows.com](https://api.therobotknows.com) |
| [therobotlives.com](https://therobotlives.com) | projects/therobotlives.com | backend, frontend | API at [api.therobotlives.com](https://api.therobotlives.com) |
| [foryou.therobotlives.com](https://foryou.therobotlives.com) | projects/foryou.therobotlives.com | backend, frontend | Sub-site of therobotlives.com |
| [therobotmakes.com](https://therobotmakes.com) | projects/therobotmakes.com | web, web-sumi-e | Two static builds |
| [therobotplans.com](https://therobotplans.com) | projects/therobotplans.com | backend, frontend | API at [api.therobotplans.com](https://api.therobotplans.com) |
| [tobornalp.com](https://tobornalp.com) | projects/tobornalp.com | backend, frontend | Shares `therobotplans` Helm chart; SSO-only auth ([[tobornalp-sso-only-no-existing-users]]) |
| [mcp.derobot.is](https://mcp.derobot.is) (domain key: npl-mcp) | projects/NoizuPromptLingo | server, frontend | NPL MCP server; tobor-locker merged in |
| robotwars (no live domain — helm placeholder `app.example.com`) | projects/game-workshop/stage/robotwars | frontend | game-workshop stage project, not yet assigned a real domain |

## Internal platform services

Self-hosted tools provisioned via Terraform, exposed on `*.noizu.com` (mail stack is the one exception, on `*.therobotlives.com`). All share a wildcard `*.noizu.com` TLS cert unless noted.

### platform/accounting
| Site | Terraform | Purpose |
|---|---|---|
| [accounting.noizu.com](https://accounting.noizu.com) | `platform/accounting/erpnext.tf` | ERPNext — ERP suite (accounting, invoicing, ops) |
| [kimai.noizu.com](https://kimai.noizu.com) | `platform/accounting/kimai.tf` | Kimai — time tracking |

### platform/ai
| Site | Terraform | Purpose |
|---|---|---|
| [jupyter.noizu.com](https://jupyter.noizu.com) | `platform/ai/jupyterhub.tf` | JupyterHub — multi-user notebooks |
| [kitten-tts.noizu.com](https://kitten-tts.noizu.com) | `platform/ai/kitten-tts.tf` | Kitten TTS — lightweight CPU text-to-speech |
| [chatterbox-tts.noizu.com](https://chatterbox-tts.noizu.com) | `platform/ai/chatterbox-tts.tf` | Chatterbox TTS — OpenAI-compatible GPU TTS |
| [nb.noizu.com](https://nb.noizu.com) | `platform/ai/livebook.tf` | Livebook — Elixir interactive notebooks |
| [webui.noizu.com](https://webui.noizu.com) | `platform/ai/open-webui.tf` | Open WebUI — LLM chat frontend |
| [inference.noizu.com](https://inference.noizu.com) | `platform/ai/open-webui.tf` | LiteLLM proxy — OpenAI-compatible inference proxy |
| [langfuse.noizu.com](https://langfuse.noizu.com) | `platform/ai/langfuse.tf` | Langfuse — LLM observability/tracing |
| [weaviate.noizu.com](https://weaviate.noizu.com) | `platform/ai/weaviate.tf` | Weaviate — vector database |
| — (internal `:6333`/`:6334`, no ingress) | `platform/ai/qdrant.tf` | Qdrant — vector store, feeds RAG pipelines |
| — (internal `:8000`, no ingress) | `platform/ai/vllm.tf` | vLLM — GPU embedding server (e5-mistral-7b-instruct) |

### platform/analytics
| Site | Terraform | Purpose |
|---|---|---|
| [matomo.noizu.com](https://matomo.noizu.com) | `platform/analytics/matomo.tf` | Matomo — web analytics |
| [growthbook.noizu.com](https://growthbook.noizu.com) | `platform/analytics/growthbook.tf` | GrowthBook — feature flags / A-B testing |

### platform/content
| Site | Terraform | Purpose |
|---|---|---|
| [docmost.noizu.com](https://docmost.noizu.com) | `platform/content/docmost.tf` | Docmost — wiki/docs |
| [ghost.noizu.com](https://ghost.noizu.com) | `platform/content/ghost.tf` | Ghost — blog CMS |
| [nextcloud.noizu.com](https://nextcloud.noizu.com) | `platform/content/nextcloud.tf` | Nextcloud — file sync/collaboration |

### platform/creative
| Site | Terraform | Purpose |
|---|---|---|
| [chartdb.noizu.com](https://chartdb.noizu.com) | `platform/creative/chartdb.tf` | ChartDB — DB schema visualizer |
| [drawio.noizu.com](https://drawio.noizu.com) | `platform/creative/drawio.tf` | draw.io — diagramming |
| [mermaid.noizu.com](https://mermaid.noizu.com) | `platform/creative/mermaid.tf` | Mermaid Live Editor |
| [excalidraw.noizu.com](https://excalidraw.noizu.com) | `platform/creative/excalidraw.tf` | Excalidraw — collaborative whiteboard |
| [mydraft.noizu.com](https://mydraft.noizu.com) | `platform/creative/mydraft.tf` | MyDraft — wireframing |
| [plantuml.noizu.com](https://plantuml.noizu.com) | `platform/creative/plantuml.tf` | PlantUML server |
| [kroki.noizu.com](https://kroki.noizu.com) | `platform/creative/kroki.tf` | Kroki — unified diagram-render API |
| [penpot.noizu.com](https://penpot.noizu.com) | `platform/creative/penpot.tf` | Penpot — design/prototyping |
| [webstudio.noizu.com](https://webstudio.noizu.com) | `platform/creative/webstudio.tf` | Webstudio — visual web builder |

### platform/crm
| Site | Terraform | Purpose |
|---|---|---|
| [espocrm.noizu.com](https://espocrm.noizu.com) | `platform/crm/espocrm.tf` | EspoCRM |
| [bottlecrm.noizu.com](https://bottlecrm.noizu.com) | `platform/crm/bottlecrm.tf` | BottleCRM |

### platform/devtools
| Site | Terraform | Purpose |
|---|---|---|
| [code.noizu.com](https://code.noizu.com) | `platform/devtools/code-server.tf` | code-server — VS Code in browser |
| [livecodes.noizu.com](https://livecodes.noizu.com) | `platform/devtools/livecodes.tf` | LiveCodes — code playground |

### platform/mail (on `*.therobotlives.com`, not `*.noizu.com`)
| Site | Terraform | Purpose |
|---|---|---|
| [mail-admin.therobotlives.com](https://mail-admin.therobotlives.com) | `platform/mail/admin.tf` | Mailu Admin — mail user mgmt, DKIM |
| [webmail.therobotlives.com](https://webmail.therobotlives.com) | `platform/mail/roundcube.tf` | Roundcube — webmail client |
| [mta-sts.therobotlives.com](https://mta-sts.therobotlives.com) | `platform/mail/mta-sts.tf` | MTA-STS policy host |
| — (SMTP/IMAP externalIPs, no HTTP ingress) | `platform/mail/front.tf` | Mailu Front — mail protocol proxy |
| — (internal, no ingress) | `dovecot.tf`, `postfix.tf`, `rspamd.tf` | Dovecot / Postfix / Rspamd |

### platform/marketing
| Site | Terraform | Purpose |
|---|---|---|
| [listmonk.noizu.com](https://listmonk.noizu.com) | `platform/marketing/listmonk.tf` | Listmonk — newsletter/mailing list |
| [mautic.noizu.com](https://mautic.noizu.com) | `platform/marketing/mautic.tf` | Mautic — marketing automation |

### platform/observability
| Site | Terraform | Purpose |
|---|---|---|
| [uptime.noizu.com](https://uptime.noizu.com) | `platform/observability/oneuptime.tf` | OneUptime — uptime monitoring + incident mgmt |

### platform/seo
| Site | Terraform | Purpose |
|---|---|---|
| [seonaut.noizu.com](https://seonaut.noizu.com) | `platform/seo/seonaut.tf` | SEOnaut — SEO auditing |
| [serpbear.noizu.com](https://serpbear.noizu.com) | `platform/seo/serpbear.tf` | SerpBear — SEO rank tracker |

### infra-services/
| Site | Terraform | Purpose |
|---|---|---|
| [argocd.noizu.com](https://argocd.noizu.com) | `infra-services/argocd.tf` | ArgoCD — GitOps CD |
| [auth.noizu.com](https://auth.noizu.com) / [auth.derobot.is](https://auth.derobot.is) | `infra-services/authentik.tf` | Authentik — identity provider |
| [headlamp.noizu.com](https://headlamp.noizu.com) | `infra-services/headlamp.tf` | Headlamp — Kubernetes dashboard |
| [infisical.noizu.com](https://infisical.noizu.com) | `infra-services/infisical.tf` | Infisical — secrets manager |
| [eval.noizu.com](https://eval.noizu.com) | `infra-services/phoenix.tf` | Arize Phoenix — LLM eval/observability |
| [posthog.noizu.com](https://posthog.noizu.com) | `infra-services/posthog.tf` | PostHog — product analytics |
| [apm.noizu.com](https://apm.noizu.com) | `infra-services/signoz.tf` | SigNoz — observability UI/backend |
| [npm.noizu.com](https://npm.noizu.com) | `infra-services/verdaccio.tf` | Verdaccio — private npm registry |
| [keygen.noizu.com](https://keygen.noizu.com) / keygen.derobot.is | `infra-services/variables.tf` | Keygen proxy — **NOT deployed**, vars only, no ingress found |

### infra/ (data tier)
| Site | Terraform | Purpose |
|---|---|---|
| [ops.noizu.com](https://ops.noizu.com) | `infra/registry.tf` | Private Docker registry (basic-auth); backs `ops.noizu.com/...` image refs used across the cluster |

### init/ (root cluster bootstrap)
| Site | Terraform | Purpose |
|---|---|---|
| [minio.noizu.com](https://minio.noizu.com) | `init/minio.tf` | MinIO S3 API — backs TF remote state + app storage (e.g. Penpot) |
| [minio-console.noizu.com](https://minio-console.noizu.com) | `init/minio.tf` | MinIO web admin console |
| Longhorn | `init/longhorn.tf` | No ingress hostname — internal-only / kubectl port-forward |

## Other projects/ subtrees without an `.infra-config.yaml` domain entry

Present under `projects/` but not (yet) wired as deployable domains above: `bloggerscompete.com`, `bookmarkflow.com`, `genai.dev`, `intellectparadox.ai`, `jailbreakingsite.com` (site-reviewer variant: `site-reviewer.derobot.is`), `noizu-intellect`, `proto.derobot.is`, `therobotdrafts`, `therobotgguf`, `therobotknows.com` variants, `therobotlearns.com`, `therobotpaints`, `therobotqas.com`, `therobotremembers`, `therobotsdayjob.com`, `therobotsrise.com`, `thesocialflywheel.com`, `vibeucation.com`, plus non-domain tooling dirs (`mcp-host`, `beam-os`, `fast-os`, `mockup-mcp`, `therobotbrowses`, `therobotdisassembles`, `theWaitcher`, `kopigajj`, `hyprriceitsnice`, `iffywow`, `rokos-coin`, `end-of-hell`, `backburner`, `game-workshop` (parent dir), `NoizuPromptLingo.deprecated`, `NoizuPromptLingo.old`).
