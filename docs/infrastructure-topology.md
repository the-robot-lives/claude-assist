# Infrastructure Topology

Diagrams showing traffic flow, service dependencies, and data-layer connections across the Noizu Kubernetes cluster.

---

## 1. Traffic Ingress Flow

Traffic enters via Cloudflare, hits the NGINX ingress controller (hostNetwork on `noizu-server`), and routes to services across namespaces.

```mermaid
flowchart TB
    Internet((Internet))
    CF[Cloudflare DNS + Proxy]
    NGINX["NGINX Ingress Controller\n(ingress-nginx ns, hostNetwork)"]

    Internet --> CF --> NGINX

    subgraph "infra"
        MinIO["MinIO S3\n9000/9001"]
        Registry["Docker Registry\n5000"]
    end

    subgraph "infisical"
        Infisical["Infisical\n8080"]
    end

    subgraph "platform-ns"
        Authentik["Authentik\n9000"]
        ArgoCD["ArgoCD"]
        Verdaccio["Verdaccio"]
        Headlamp["Headlamp"]
    end

    subgraph "observability-ns"
        SigNoz["SigNoz\n8080"]
        PostHog["PostHog"]
        Phoenix["Phoenix"]
        Metabase["Metabase"]
    end

    subgraph "apps-ns"
        Apps["Portfolio Apps\n(codefre.sh, aifighter,\ntherobotknows, etc.)"]
    end

    subgraph "creative-ns"
        Creative["Penpot, Webstudio,\nExcalidraw, Drawio,\nMermaid, Kroki, etc."]
    end

    subgraph "ai-ns"
        AI["Open-WebUI, Langfuse,\nLivebook, JupyterHub,\nWeaviate, Qdrant"]
    end

    subgraph "mail-ns"
        Mailu["Mailu"]
    end

    NGINX -->|"minio.noizu.com\nminio-console.noizu.com"| MinIO
    NGINX -->|"ops.noizu.com"| Registry
    NGINX -->|"infisical.noizu.com"| Infisical
    NGINX -->|"auth.noizu.com\nauth.derobot.is"| Authentik
    NGINX -->|"argocd.noizu.com"| ArgoCD
    NGINX -->|"apm.noizu.com"| SigNoz
    NGINX -->|"app domains"| Apps
    NGINX -->|"creative domains"| Creative
    NGINX -->|"ai domains"| AI
```

---

## 2. Namespace & Tier Overview

Deployment tiers control startup ordering. Tier N completes before N+1.

```mermaid
flowchart LR
    subgraph "Tier 0 — Secrets"
        T0[Infisical]
    end

    subgraph "Tier 1 — Data & Observability"
        direction TB
        T1D["infra-postgres + infra-valkey\nClickHouse + ZooKeeper\nplatform-postgres + platform-valkey\napp-postgres + app-valkey"]
        T1O["SigNoz\nOTel Collector\nPhoenix\nPostHog\nMetabase\nOneUptime"]
    end

    subgraph "Tier 2 — Platform & Admin"
        T2["Authentik\nArgoCD\nMinIO\nRegistry\nVerdaccio\nHeadlamp"]
    end

    subgraph "Tier 3 — Core Apps"
        T3["Portfolio sites\n(apps-ns)"]
    end

    subgraph "Tier 4 — Creative & DevTools"
        T4["Penpot, Webstudio\nExcalidraw, Drawio\nMermaid, Kroki\nChartDB, PlantUML"]
    end

    subgraph "Tier 5 — AI, Mail, Aux"
        T5["Open-WebUI, Langfuse\nLivebook, JupyterHub\nMailu, Accounting"]
    end

    subgraph "Tier 9 — Health"
        T9["Health Tests"]
    end

    T0 --> T1D & T1O --> T2 --> T3 --> T4 --> T5 --> T9
```

---

## 3. PostgreSQL — 3-Tier Split

Three independent PostgreSQL (TimescaleDB-HA + Apache AGE) instances, one per fixture group.

```mermaid
flowchart TB
    subgraph "infra ns"
        InfraPG["infra-postgres\n:5432 · 20Gi\nApps: authentik, infisical,\nphoenix, posthog"]
    end

    subgraph "platform ns"
        PlatPG["platform-postgres\n:5432\nApps: bottlecrm, docmost,\nghost, keygen, langfuse,\nlistmonk, mermaid, n8n,\nnextcloud, penpot, plane,\npostiz, taiga, webstudio"]
    end

    subgraph "apps ns"
        AppPG["app-postgres\n:5432\nApps: aifighter, codefresh,\nderobotis, gotta_cc, iotgo,\njailbreaking, noizu_site,\nstartapp, therobotknows,\ntherobotlives, therobotplans,\ntobornalp"]
    end

    subgraph "Infra Services (infra-services)"
        Authentik["Authentik"] --> InfraPG
        Infisical["Infisical"] --> InfraPG
        Phoenix["Phoenix"] --> InfraPG
        PostHog["PostHog"] --> InfraPG
    end

    subgraph "Platform Services (platform/*)"
        Docmost["Docmost"] --> PlatPG
        Penpot["Penpot"] --> PlatPG
        Taiga["Taiga"] --> PlatPG
        Plane["Plane"] --> PlatPG
        OtherPlat["Ghost, N8N, Langfuse,\nNextcloud, etc."] --> PlatPG
    end

    subgraph "App Services (apps/init)"
        AiFighter["AiFighter"] --> AppPG
        Codefresh["Codefre.sh"] --> AppPG
        OtherApps["Portfolio sites\n(8 more)"] --> AppPG
    end
```

Mailu and accounting run **dedicated** databases within their own namespaces.

### Infisical Secret Paths

| Tier | PostgreSQL Path | Valkey Path | Managed Secret |
|------|----------------|-------------|----------------|
| Infra | `/data/postgres` | `/data/valkey` | `postgres-secrets` |
| Platform | `/platform/postgres` | `/platform/valkey` | `platform-postgres-secrets` |
| Apps | `/apps/postgres` | `/apps/valkey` | `app-postgres-secrets` |

---

## 4. Valkey — 3-Tier Split

Three Valkey instances provide per-tier caching. No legacy Redis.

```mermaid
flowchart TB
    subgraph "infra ns"
        InfraVK["infra-valkey\nValkey 8.1 · ACL-enabled\n:6379 · 5Gi\nUsers: authentik, infisical, posthog"]
    end

    subgraph "platform ns"
        PlatVK["platform-valkey\nValkey 8.1 · password auth\n:6379 · 5Gi"]
    end

    subgraph "apps ns"
        AppVK["app-valkey\nValkey 8.1 · password auth\n:6379 · 5Gi"]
    end

    subgraph "observability-ns"
        PostHogRedis["posthog-redis\nRedis 7 · passwordless\n:6379 · 5Gi\n(ioredis ACL limitation)"]
    end

    Authentik["Authentik"] -->|"ACL user"| InfraVK
    Infisical["Infisical"] -->|"ACL user"| InfraVK
    PostHog_V["PostHog"] -->|"ACL user"| InfraVK
    PostHog_R["PostHog"] -->|"dedicated"| PostHogRedis

    PlatApps["Docmost, Penpot,\nBottleCRM, Excalidraw,\nNextcloud, Plane, etc."] --> PlatVK

    AppApps["AiFighter, Codefre.sh,\nPortfolio sites"] --> AppVK
```

### Summary Table

| Instance | Namespace | Auth | Consumers |
|----------|-----------|------|-----------|
| `infra-valkey` | infra | ACL per-user | Infisical, Authentik, PostHog |
| `platform-valkey` | platform | Password | Platform-tier apps (14 apps) |
| `app-valkey` | apps | Password | Portfolio sites (12 apps) |
| `posthog-redis` | observability-ns | None | PostHog only |
| ArgoCD embedded | platform-ns | Internal | ArgoCD state only |

---

## 5. ClickHouse & Analytics Pipeline

Two separate ClickHouse instances — shared infra and PostHog-dedicated — each with their own ZooKeeper.

```mermaid
flowchart TB
    subgraph "infra ns"
        CH["infra-clickhouse\nCH 25.5.6\nPorts: 9000/8123/9363\n50Gi data + 10Gi logs"]
        ZK["infra-zookeeper\nZK 3.7.1\nPort 2181\n5Gi"]
    end

    subgraph "observability-ns"
        SigNoz["SigNoz\n(query + alerting)"]
        OTel["OTel Collector\n(signal ingestion)"]

        PostHogCH["posthog-clickhouse\nCH 22.8.21.38 (LTS)\n(Kafka-engine compat)"]
        PostHogZK["posthog-zookeeper\nZK 3.9\nPort 2181"]
        PostHogKafka["posthog-kafka\nRedpanda\nPort 9092 · 20Gi"]
        PostHog["PostHog"]
    end

    CH -->|"replication coord"| ZK
    SigNoz -->|"HTTP :8123"| CH
    OTel -->|"traces/metrics/logs"| SigNoz

    PostHogCH --> PostHogZK
    PostHog --> PostHogCH
    PostHog --> PostHogKafka
    PostHogKafka --> PostHogCH
```

---

## 6. Object Storage (MinIO)

MinIO provides S3-compatible storage in the `infra` namespace. It serves as the Terraform remote state backend and general object storage.

```mermaid
flowchart LR
    MinIO["MinIO\n(infra ns)\n100Gi Longhorn\nPorts 9000/9001\nPinned: noizu-server"]

    TF["Terraform/Terragrunt\n(S3 backend)"]
    Apps["Application pods\n(artifact storage)"]
    Console["minio-console.noizu.com\n(Web UI)"]
    API["minio.noizu.com\n(S3 API)"]

    TF -->|"tfstate bucket"| MinIO
    Apps --> MinIO
    Console --> MinIO
    API --> MinIO
```

---

## 7. Full Data Layer Summary

End-to-end view of all data services across the 3-tier model.

```mermaid
flowchart TB
    subgraph "infra ns — Infrastructure Data"
        IPG["infra-postgres\n:5432 · 20Gi"]
        IVK["infra-valkey\n:6379 · 5Gi · ACL"]
        CH["infra-clickhouse\n:8123/:9000 · 50Gi"]
        ZK["infra-zookeeper\n:2181 · 5Gi"]
        MinIO_D["MinIO · S3 · 100Gi"]
    end

    subgraph "platform ns — Platform Data"
        PPG["platform-postgres\n:5432"]
        PVK["platform-valkey\n:6379 · 5Gi"]
        PMD["platform-mariadb\n:3306"]
        PMG["platform-mongodb\n:27017"]
    end

    subgraph "apps ns — App Data"
        APG["app-postgres\n:5432"]
        AVK["app-valkey\n:6379 · 5Gi"]
    end

    subgraph "observability-ns — Dedicated PostHog"
        PHR["posthog-redis · :6379"]
        PHCH["posthog-clickhouse · :8123"]
        PHZK["posthog-zookeeper · :2181"]
        PHK["posthog-kafka · :9092"]
    end

    subgraph "Consumers"
        IC["Infra Services\n(authentik, infisical,\nphoenix, posthog)"] --> IPG & IVK
        SC["SigNoz"] --> CH
        PC["PostHog"] --> PHR & PHCH & PHK
        PC -->|"ACL"| IVK
        PlatC["Platform Apps\n(14 apps)"] --> PPG & PVK
        PlatMC["MariaDB Apps\n(espocrm, ghost,\nmatomo, mautic, seonaut)"] --> PMD
        PlatGC["GrowthBook"] --> PMG
        AC["Portfolio Apps\n(12 apps)"] --> APG & AVK
        TFC["Terraform"] --> MinIO_D
    end

    CH --- ZK
    PHCH --- PHZK
```

---

## 8. Observability Pipeline

How telemetry flows from application pods through collection to dashboards.

```mermaid
flowchart LR
    subgraph "All Namespaces"
        Pods["Application Pods\n(traces, metrics, logs)"]
    end

    subgraph "observability-ns"
        OTel["OTel Collector"]
        SigNoz["SigNoz\n(apm.noizu.com)"]
        PostHog["PostHog\n(product analytics)"]
        Phoenix["Phoenix\n(error monitoring)"]
        Metabase["Metabase\n(BI dashboards)"]
        OneUptime["OneUptime\n(uptime monitoring)"]
    end

    subgraph "infra ns"
        CH["infra-clickhouse"]
        PG["infra-postgres"]
    end

    Pods -->|"OTLP"| OTel --> SigNoz --> CH
    Phoenix --> PG
    PostHog -->|"dedicated CH + Kafka"| PostHog
    Metabase --> PG
```

---

## 9. Authentication Flow

Authentik provides SSO (OIDC/SAML) for services that support it.

```mermaid
flowchart TB
    User((User))
    NGINX["NGINX Ingress"]

    subgraph "platform-ns"
        Authentik["Authentik\nauth.noizu.com\nauth.derobot.is"]
    end

    subgraph "infra ns"
        PG["infra-postgres"]
        VK["infra-valkey"]
    end

    subgraph "SSO-Enabled Services"
        ArgoCD_A["ArgoCD"]
        Grafana_A["SigNoz"]
        Apps_A["Apps with OIDC\n(Nextcloud, Plane, etc.)"]
    end

    User --> NGINX --> Authentik
    Authentik --> PG
    Authentik --> VK
    ArgoCD_A -->|"OIDC"| Authentik
    Grafana_A -->|"OIDC"| Authentik
    Apps_A -->|"OIDC/SAML"| Authentik
```

---

## 10. Secrets Flow

How secrets propagate from source of truth to running pods.

```mermaid
flowchart TB
    YAML[".infisical-secrets.yaml\n(declarative definitions)"]
    Populate["infisical-populate-secrets\n(CLI tool)"]
    Server["Infisical Server\n(infisical ns)"]
    TF["Terraform\n(InfisicalSecret CRDs)"]
    Operator["Infisical K8s Operator"]
    K8S["Kubernetes Secrets"]
    Pods["Application Pods"]

    YAML -->|"seed"| Populate -->|"push"| Server
    TF -->|"deploy CRDs\nreferencing paths"| Operator
    Operator -->|"sync from"| Server
    Operator -->|"create/update"| K8S
    K8S -->|"env vars / volume mounts"| Pods
```
