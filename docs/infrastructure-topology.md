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
        Apps["40+ App Pods\n(Docmost, Taiga, Plane,\nGhost, N8N, Nextcloud,\nPortfolio sites, etc.)"]
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
        T1D["PostgreSQL\nValkey\nClickHouse\nZooKeeper\nMySQL\nMongoDB"]
        T1O["SigNoz\nOTel Collector\nPhoenix\nPostHog\nMetabase\nOneUptime"]
    end

    subgraph "Tier 2 — Platform & Admin"
        T2["Authentik\nArgoCD\nMinIO\nRegistry\nVerdaccio\nHeadlamp"]
    end

    subgraph "Tier 3 — Core Apps"
        T3["40+ applications\n(apps-ns)"]
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

## 3. PostgreSQL Connections

All applications share a single `infra-timescaledb` instance (TimescaleDB-HA + Apache AGE) in `data-ns` on port 5432. Each app has its own database.

```mermaid
flowchart LR
    PG["infra-timescaledb\n(data-ns:5432)\nTimescaleDB-HA + AGE\n20Gi Longhorn"]

    subgraph "infisical"
        Infisical["Infisical\ndb: infisical"]
    end

    subgraph "platform-ns"
        Authentik["Authentik\ndb: authentik"]
    end

    subgraph "observability-ns"
        Phoenix["Phoenix\ndb: phoenix"]
        PostHog_PG["PostHog\ndb: posthog"]
        Langfuse_O["Langfuse\ndb: langfuse"]
    end

    subgraph "apps-ns"
        Docmost["Docmost\ndb: docmost"]
        Taiga["Taiga\ndb: taiga"]
        Plane["Plane\ndb: plane"]
        Ghost["Ghost\ndb: ghost"]
        N8N["N8N\ndb: n8n"]
        Nextcloud["Nextcloud\ndb: nextcloud"]
        Listmonk["Listmonk\ndb: listmonk"]
        Postiz["Postiz\ndb: postiz"]
        BottleCRM["BottleCRM\ndb: bottlecrm"]
        PortfolioApps["Portfolio Apps\n(aifighter, gotta_cc,\niotgo, noizu_site,\njailbreaking, etc.)"]
    end

    subgraph "creative-ns"
        Penpot["Penpot\ndb: penpot"]
        Webstudio["Webstudio\ndb: webstudio"]
        Mermaid_App["Mermaid\ndb: mermaid"]
    end

    subgraph "ai-ns"
        Langfuse_AI["Langfuse\ndb: langfuse"]
    end

    Infisical --> PG
    Authentik --> PG
    Phoenix --> PG
    PostHog_PG --> PG
    Docmost & Taiga & Plane --> PG
    Ghost & N8N & Nextcloud --> PG
    Listmonk & Postiz & BottleCRM --> PG
    PortfolioApps --> PG
    Penpot & Webstudio & Mermaid_App --> PG
    Langfuse_AI --> PG
```

Mailu runs a **dedicated PostgreSQL** instance within `mail-ns` — it does not share the infra database.

---

## 4. Redis / Valkey Connections

Three distinct Redis-compatible instances serve different consumers.

```mermaid
flowchart TB
    subgraph "data-ns"
        Valkey["infra-valkey\n(Valkey 8.1-alpine)\nPort 6379 · ACL-enabled\n5Gi Longhorn"]
        SharedRedis["shared-redis\n(legacy Redis)\nPort 6379"]
    end

    subgraph "observability-ns"
        PostHogRedis["posthog-redis\n(Redis 7-alpine)\nPort 6379 · No password\n5Gi Longhorn"]
    end

    subgraph "Valkey ACL Users"
        direction TB
        VU1["posthog → infra-valkey"]
        VU2["authentik → infra-valkey"]
        VU3["infisical → infra-valkey"]
    end

    subgraph "PostHog Redis Consumer"
        PostHog["PostHog\n(observability-ns)"]
    end

    subgraph "Apps using shared-redis"
        AppRedis["General app caching\n(apps-ns pods referencing\nshared-redis.data-ns)"]
    end

    Infisical_V["Infisical\n(infisical ns)"] -->|"ACL user: infisical"| Valkey
    Authentik_V["Authentik\n(platform-ns)"] -->|"ACL user: authentik"| Valkey
    PostHog_V["PostHog\n(observability-ns)"] -->|"ACL user: posthog"| Valkey

    PostHog -->|"passwordless\n(ioredis ACL limitation)"| PostHogRedis

    AppRedis --> SharedRedis
```

### Summary Table

| Instance | Namespace | Image | Auth | Consumers |
|----------|-----------|-------|------|-----------|
| `infra-valkey` | data-ns | valkey/valkey:8.1-alpine | ACL per-user passwords | Infisical, Authentik, PostHog |
| `shared-redis` | data-ns | redis (legacy) | Password | General app caching (apps-ns) |
| `posthog-redis` | observability-ns | redis:7-alpine | None (passwordless) | PostHog only |
| ArgoCD embedded | platform-ns | Built into ArgoCD chart | Internal | ArgoCD state only |

---

## 5. ClickHouse & Analytics Pipeline

Two separate ClickHouse instances — shared infra and PostHog-dedicated — each with their own ZooKeeper.

```mermaid
flowchart TB
    subgraph "data-ns"
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

End-to-end view of all data services and their consumers.

```mermaid
flowchart TB
    subgraph "data-ns — Shared Data Layer"
        PG["infra-timescaledb\nPostgreSQL 17 + AGE\n:5432 · 20Gi"]
        VK["infra-valkey\nValkey 8.1\n:6379 · 5Gi"]
        SR["shared-redis\nRedis (legacy)\n:6379"]
        CH["infra-clickhouse\nClickHouse 25.5\n:8123/:9000 · 50Gi"]
        ZK["infra-zookeeper\nZK 3.7.1\n:2181 · 5Gi"]
        MinIO_D["MinIO\n(infra ns)\nS3 · 100Gi"]
    end

    subgraph "observability-ns — Dedicated PostHog Stack"
        PHR["posthog-redis\n:6379 · 5Gi"]
        PHCH["posthog-clickhouse\nCH 22.8 · :8123"]
        PHZK["posthog-zookeeper\n:2181"]
        PHK["posthog-kafka\nRedpanda · :9092 · 20Gi"]
    end

    subgraph "Consumers"
        Infisical_C["Infisical"] -->|PG + Valkey| PG & VK
        Authentik_C["Authentik"] -->|PG + Valkey| PG & VK
        SigNoz_C["SigNoz"] -->|ClickHouse| CH
        PostHog_C["PostHog"] -->|dedicated stack| PHR & PHCH & PHK
        PostHog_C -->|Valkey ACL| VK
        Apps_C["40+ Apps"] -->|PostgreSQL| PG
        Apps_C -->|"shared-redis"| SR
        Creative_C["Creative Apps"] -->|PostgreSQL| PG
        AI_C["AI Services"] -->|PostgreSQL| PG
        TF_C["Terraform"] -->|S3 state| MinIO_D
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

    subgraph "data-ns"
        CH["infra-clickhouse"]
        PG["infra-timescaledb"]
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

    subgraph "data-ns"
        PG["infra-timescaledb"]
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
