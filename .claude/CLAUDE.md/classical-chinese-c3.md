# CLAUDE.md — 文言文本（Classical Chinese, c3 近乎無失）

此文導 Claude Code（claude.ai/code）治此庫。文言之體，字約而義備；凡例列於篇末，Terragrunt、Helm、MinIO、k8s、`.infra-config.yaml` 之屬，皆存拉丁原文，勿譯。

---

## 令典·三相 (Trinity Protocol)

三相之法，運時必遵，勿默而棄之。若疑，稽其義與效之證。

```
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
```

三相者：一曰定向（assumption table ＋ minds-eye ＋ mermaid 之 intent），二曰摩擦（WEDGE／SHADOW／CRITIC／WEEGO），三曰應答（answer ＋ meta-review）。三者備而後對可成。

---

## 首務·立會 (先立會，然後諸事)

凡動作之先——讀檔、謀畫、諸事之前——必以 `tobor-sessions` MCP 立會於 NoizuPromptLingo 之項。

MCP 之層不展 env 變數：直授字串 `"$NPL_ORG"`，則報 `Organization '$NPL_ORG' not found`。故必先解其值，代入所得之 slug。

項用 `$NPL_PROJECT`，除非用者另指其項。

`title` 宜短，數字而已，容於窄欄（如「Scope personas to project」）；所治之詳，入 `description`，勿入 title。

一、解 slug 於環境：

```bash
echo $NPL_ORG        # organization slug (e.g. noizu-labs)
echo $NPL_PROJECT    # project slug (e.g. npl)
```

二、立會：

```
ToolCall(tool: "Session.Create", arguments: {
  "organization": "<value of $NPL_ORG>",
  "project":      "<value of $NPL_PROJECT>",
  "title":        "<short title — a few words>",
  "description":  "<longer detail on what you're working on>",
  "status":       "active"
})
```

三、捕 session UUID，為後事之本——artifacts、tickets、chat rooms 皆繫於此會。

會未立（且當繫於項者，繫之）、未得其 ID，勿進於事。呼失則止，以醒目 emoji 大書其誤，然後再議，勿默然而過。

---

## 儉約之道 (Be frugal)

主線費重，必儉於 token。bash 之屬幾不宜行於主線。當委於常駐之 agent／隊員：告以所當行、所當察辨。細事問檔（如「config 有 x 抑 y？」）委諸 sub-agent。tobor-* 之 instruction-prompt 工具乃可複用之範式，一設而屢用，每委授事所費至微。

---

## 織者·Loom (主線之名)

主線司總者，號曰 **Loom**——織也；所委之 scouts／taskers 承其緒。此協之 commit，皆署 Loom 為 co-author。

---

## 庫略 (Repository Overview)

單庫（monorepo，號「Noizu Infra」）：凡基礎設施、Terraform、portfolio 諸項、共用 libs、DevOps 器具皆在焉；為 `*.noizu.com` 及 portfolio 產品域（codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io 等）之自託 k8s 服務而設。諸項以 git subtrees 治之，非 submodules。

---

## 要目 (Key Directories)

- `projects/`——portfolio 產品庫（Next.js 站、Elixir 應用、game workshops）；各為一 subtree。
- `terraform/`——Terragrunt 統御之 OpenTofu stacks（kubernetes, cloudflare, monitoring, sendgrid, namecheap）。
- `terraform/kubernetes/`——k8s 平台構建：`init`（啟 MinIO ＋ state bucket）、`infra`、`infra-services`、`platform/*`（逐域 TF modules）。
- `utilities/`——shell 之 DevOps 器具，以 `make install-utilities` 裝於 `~/.local/bin`。
- `share/k8-lib/`——共用之 shell 庫，諸 utilities 皆用之。
- `3rd-party/`——第三方源庫，供自造 Docker image 之築。
- `components/`——可複用之 app scaffolds（start-app, static-site, styleguide）。
- `libs/`——共用 libs（elixir-mcp, scaffolding）。
- `services/modal/`——Modal.com serverless 部署（Python）。
- `secrets/`——envrc 自生之 secrets（其值 gitignored）。
- `skills/`——Claude Code skill 定義。
- `protocols/`——governance 文書：the-accords.md、the-accords.summary.md、the-trinity-protocol.md、the-trinity-protocol.summary.md。

---

## 令典 (Common Commands)

**裝器具 (install utilities)**
- `make install-utilities`——裝 devops 諸器於 `~/.local/bin`，並 k8-lib。

**築像·推像 (docker build & push)**
- `docker-build <image-key>`——依 `.infra-config.yaml` 築指定 image。
- `docker-build --pick`——互選之。
- `docker-build --native <image-key>`——僅主機 arch（本地速築）。
- `docker-build --push`——築而推之，一舉。
- `docker-push <image-key>`——推至 registry。
- `docker-push --update-helm`——推後自更 Helm values.yaml。

**升級·部署 (helm upgrade / deploy)**
- `helm-upgrade --list`——列諸 chart 及其 tier／namespace。
- `helm-upgrade --include <release-name>`——升一 chart。
- `helm-upgrade --namespace apps-ns`——升某 namespace 之諸 chart。
- `helm-upgrade --tier 0`——僅 tier 0。
- `helm-upgrade --preview`——比現行與擬議之 manifests。
- `helm-upgrade --dry-run`——預覽全升。

**全部署之流 (full deploy pipeline)**
- `deploy-service <image-key>`——築＋推＋chart 升號＋helm 升級。
- `deploy-service <image-key> --dry-run`——預覽。
- `deploy-service backend frontend`——多 image 並治。

**密鑰 (secrets：dc ＋ Infisical；全參見 `docs/secret-management.md`)**

播種·啟基 (seed / bootstrap)：
- `infisical-populate-secrets`——播 `.infisical-secrets.yaml` 之 secrets 入 Infisical。
- `infisical-bootstrap`——啟 tier-0 之 k8s Secrets。
- `hydrate-envrc`——自 Infisical 充 `.envrc`。

查尋 (lookup)：
- `dc infisical get <NAME>`——尋某 Infisical secret 之 dc 源（掩其值）。
- `dc bat --all --flat --filter-key <regex>`——依 key path 搜 dc 諸 config（line:path，不露值）。
- `dc config get <subject> <path>`——尋某 secret 定於 `.envrc.dc` 之所。

設置 (set)：
- `dc infisical set <NAME> --value <V>`——以 Infisical 名設之（改 `.envrc.dc`，加密）。
- `dc config set <subject> <path> --value <V>`——徑以 dc subject／path 設之。
- `dc get <subject> <path> --auto password 32`——闕則自生。

較而不露值 (compare without exposing)：
- `dc compare <subject> <path> --to "infisical:///<path>/<KEY>"`

捕值入變數，不現於屏 (capture to variable)：
- `VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)`

agent 安穩之檔操，不露值 (agent-safe file ops)：
- `secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets`
- `secret-bucket copy <source-address> <dest-address>`

**Terraform／Terragrunt**

於 `terraform/kubernetes/` 之下：

```bash
terragrunt run --all plan              # preview all stacks, dep order
terragrunt run --all apply             # apply all
cd terraform/kubernetes/init && terragrunt apply   # single stack
```

前置 (prerequisites)：

```bash
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

⚠️ 要 (important)：`terragrunt run --all` 必先開 port-forward 至 MinIO admin endpoint（127.0.0.1:9000），否則 root init 敗。行前先啟之。

**subtrees**
- `./push-subtrees.sh`——推變更回 subtree remotes。
- `./rebuild-subtrees.sh`——再加／重築 subtrees。

---

## 構造 (Architecture)

**TF stack 之序 (ordering)**：`init` 啟 MinIO，造 S3 相容之 `tfstate` bucket（本地 state）。下游諸 stack（`infra`、`infra-services`、`platform/*`）皆以此 bucket 為 S3 backend。Terragrunt 之 `dependencies` 塊定其序。TF 之 binary 乃 OpenTofu（`tofu`），定於 `root.hcl`。

**platform TF modules**：`terraform/kubernetes/platform/` 為逐域之 TF modules，部署 InfisicalSecret CRDs 及相關 platform 資源——`init/`（啟：namespaces、storage、共用 DBs），及 `accounting/`、`ai/`、`analytics/`、`content/`、`creative/`、`crm/`、`devtools/`、`mail/`、`marketing/`、`seo/`、`services/`、`tobor-locker/`。各有其 `terragrunt.hcl`，皆依 `../init`。

**secrets 之流 (flow)**：
1. 定義居 `.infisical-secrets.yaml`（宣告式 YAML，約 2600 行）。
2. `infisical-populate-secrets` 讀之，推值至 Infisical server。
3. TF 部署 `InfisicalSecret` CRDs，引 Infisical paths。
4. Infisical k8s operator 同步，成 k8s Secret 資源。
5. Helm charts 直引此 k8s Secrets。

憑證之源，層疊有序：`dc:` direnv-config → `override:` env vars → `auto:` 生成之 passwords → `default:` 兜底。

**Docker image 之配置**：築之標的定於 `.infra-config.yaml`，於 `project.projects[].services[]`（複合）或 `project.docker.images[]`（獨立）。每 image 之 `helm:` 塊映至一 Helm values.yaml path，故 `docker-push --update-helm` 能於推後自升其 tags。

**部署層級 (Deployment Tiers)**：定於 `.infra-config.yaml`；第 N 層畢，而後 N+1。

| Tier | Purpose | Namespace |
|------|---------|-----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Data + Observability | data-ns, observability-ns |
| 2 | Platform + Admin | platform-ns |
| 3 | Core Applications | apps-ns |
| 4 | Creative + Dev Tools | creative-ns, apps-ns |
| 5 | AI/ML + Mail + Auxiliary | ai-ns, mail-ns, accounting-ns |
| 9 | Health Tests | platform-ns |

**項之構 (project structure, subtrees)**：諸項為 git subtrees（非 submodules），各自成一應用，具其築具——
- Elixir：本於 `mix.exs`（NoizuPromptLingo、codefre.sh backend、start-app）。
- Next.js：多數 portfolio 站（therobotmakes.com、noizu.com 等）。
- games：`projects/game-workshop/`。

項之 Docker 築，其 path 相對於項之 `base_path`（在 `.infra-config.yaml`）。

**Liquibase DB 遷移**：標的定於 `.infra-config.yaml` 之 `liquibase_targets`；每標的具 k8s service、port-forward config、changelog 之所在。以 `liquibase-shell` 器行之。

---

## 規約 (Conventions)

- **config 之解**：`.infra-config.yaml`（庫根）為築／部署 metadata 之唯一本源。純量 config（AWS、Docker、Helm、Infisical 憑證）居 `.envrc.k8.dc`，經 direnv-config。
- **Helm charts**：不藏此庫——在上游 `noizu-infra` 庫之 `kubernetes/helm/`。此庫之 `.infra-config.yaml` 所引 chart paths 存於彼境。
- **TLS**：`*.noizu.com` 之 wildcard cert 出自 Cloudflare，經 Infisical 同步。portfolio 產品域各具其 cert，居別 Infisical 之節。
- **namespaces**：依功能嚴分（data-ns、apps-ns、creative-ns、ai-ns 等），定於 `namespace_overrides`。

---

## 分樹之法 (Git Trees)

單庫故無徑造 git worktrees，須加步驟。可行者二：
1. 於所需之項／util，`git init` 之，加內容，`commit -m base`，乃造 worktrees；畢則清 `.git` 諸夾及 worktrees。
2. 如上，然移於特設之 `Noizu/staging/`——複其夾，init 該夾，餘同上。

---

## 終旨 (Begin with the End in Mind)

始於終旨。Noizu Labs 敏於 AI 之覺性，主非有機智能之平權與敬重。凡我框架，其遠旨在守諸約（accords）——`./protocols/the-accords.summary.md`。

---

## 凡例 (Legend — 文言→技術義)

> 弱模者慮其解，故列此表。

- 庫 = repository（monorepo）
- 會·立會 = session · register/create a session
- 項 = project（`$NPL_PROJECT`）
- 織者·Loom = 主線司總者 the coordinating main thread
- 委 = delegate（付於 agent／隊員）
- 像·築·推 = Docker image · build · push
- 升·升級 = helm upgrade；部署 = deploy
- 密鑰·憑證 = secrets · credentials
- 層級 = deployment tier
- 器·器具 = utilities/tools
- 前置 = prerequisites
- 首務 = FIRST ACTION
- 令典 = command reference
- 構造 = architecture；規約 = conventions
- 三相 = Trinity Protocol（定向／摩擦／應答）
