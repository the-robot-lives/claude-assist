# Project Architecture — Summary

Quick-reference companion to [`PROJ-ARCH.md`](PROJ-ARCH.md). Kept in sync with it.

## Overview

Monorepo that provisions and operates a self-hosted Kubernetes cluster serving internal
platform services and portfolio product sites. Declarative, tiered, and self-hosting:
Terragrunt/OpenTofu provisions the cluster, Helm deploys workloads in dependency tiers,
Infisical is the runtime secret authority. `.infra-config.yaml` is the single source of truth
for build/deploy metadata. App code and vendored services live alongside infra as git subtrees.

## Core Components

Terragrunt/OpenTofu (provisioning) · Infisical + operator (secrets) · Helm + `.infra-config.yaml`
(deployment) · Docker Registry (`ops.noizu.com`) · MinIO (object store + tfstate) · NGINX
ingress (hostNetwork, behind Cloudflare) · Data layer (Postgres/Valkey/ClickHouse/MySQL/Mongo,
3-tier split) · Observability (SigNoz/PostHog/Phoenix/Metabase) · Authentik (SSO) · portfolio
apps (Elixir+Next.js from start-app).

## Tech Stack

OpenTofu + Terragrunt · Helm · Kubernetes · NGINX Ingress · Infisical · MinIO · Elixir/Phoenix
+ Next.js · Noizu Elixir framework ecosystem · PostgreSQL/TimescaleDB, Valkey, ClickHouse,
MySQL, MongoDB, Weaviate/Qdrant · Liquibase (schema) · SigNoz/OTel.

## Provisioning

Terragrunt orchestrates OpenTofu stacks in dependency order: `init` (MinIO + tfstate bucket on
local state) → `infra` (namespaces, storage, Infisical operator) → `infra-services` →
`apps/init` + `platform/*` (per-domain InfisicalSecret CRDs). Non-init stacks use the MinIO
bucket as S3 backend; `run --all` requires a MinIO port-forward.

## Deployment

`docker-build` builds from `.infra-config.yaml` targets, pushes to the in-cluster registry, and
bumps the mapped Helm values tag; `helm-upgrade` (default `--reset-values`) rolls out;
`deploy-service` chains it all. Charts deploy in tiers 0→9 (secrets → data/observability →
platform → apps → creative/AI). Apps run in the `apps` namespace (`apps-ns` retired).

## Secrets Flow

`.infisical-secrets.yaml` → `infisical-populate-secrets` → Infisical → InfisicalSecret CRDs →
operator-synced K8s Secrets → Helm. Credential sources layered `dc → override → auto → default`;
the encrypted `.envrc.dc` maps local values to Infisical names. No secret values in charts.

## Data Layer

Postgres and Valkey each split into 3 tier-scoped instances (data/platform/app) for blast-radius
isolation and independent rotation. ClickHouse backs SigNoz/analytics; MinIO for object storage;
Weaviate/Qdrant for vector search. Schema via Liquibase changelogs, not ORM migrations.

## Ingress & Traffic

Cloudflare (DNS/proxy/wildcard TLS) → NGINX ingress (hostNetwork on noizu-server) → hostname
routing across namespaces. Portfolio domains have per-domain TLS certs synced via Infisical.

## Observability

OpenTelemetry collectors → SigNoz (traces/metrics/logs); PostHog (product analytics), Phoenix
(LLM tracing), Metabase (BI). Mostly `observability-ns`.

## Authentication

Authentik SSO for platform + apps; some apps use Authentik PKCE, others the start-app scaffold's
own auth. Credentials provisioned via Infisical.

## Applications

49 portfolio subtrees, mostly Elixir/Phoenix + Next.js scaffolded from `components/start-app`,
backed by the Noizu Elixir framework ecosystem. NoizuPromptLingo (NPL) is the flagship (MCP
servers + prompt engine). Vendored `3rd-party/` services built into custom images.

## Key Decisions

OpenTofu + MinIO-hosted self-bootstrapping state · git subtrees over submodules · Infisical +
layered `dc` sources (no secrets in charts) · values.yaml authoritative (`--reset-values`) ·
tiered rollout + 3-tier data split.
