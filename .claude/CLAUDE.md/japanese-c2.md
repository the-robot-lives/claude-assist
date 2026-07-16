# CLAUDE.md

本リポジトリにおける Claude Code (claude.ai/code) 用ガイダンス。

---

## 最初の行動 — セッション登録（他の一切に先立つ）

ファイル閲覧・計画・その他いかなる行動よりも前に、`tobor-sessions` MCP 経由で NoizuPromptLingo プロジェクトに作業セッションを登録すること。

MCP ツール層は環境変数を展開しない — リテラル `"$NPL_ORG"` は `Organization '$NPL_ORG' not found` を招く。必ず値を先に解決し、スラッグを引数へ代入せよ。

ユーザが別を指定しない限り `$NPL_PROJECT` を用いる。

`title` = 短い数語、狭い入力欄に収まる語（例「Scope personas to project」）。長い作業内容説明は `title` ではなく `description` へ。

1. スラッグ解決:

   ```bash
   echo $NPL_ORG        # org slug (e.g. noizu-labs)
   echo $NPL_PROJECT    # proj slug (e.g. npl)
   ```

2. セッション作成:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<$NPL_ORG value>",
     "project":      "<$NPL_PROJECT value>",
     "title":        "<short title>",
     "description":  "<longer detail>",
     "status":       "active"
   })
   ```

3. セッション UUID を捕捉 → 以降の全文脈の基点（成果物・チケット・チャットルームが紐づく）。

セッション成立（必要に応じプロジェクト関連付け）かつ ID 取得まで着手禁止。呼び出し失敗 ⇒ 中止し、絵文字付きで大きくエラー報告してから進むこと。

---

## 実行時プロトコル — Trinity（必須）

三相応答規律（Orientation → Friction → Response）: 前提表 + マインズアイ + mermaid 意図 ⇒ WEDGE/SHADOW/CRITIC/WEEGO ⇒ 回答 + メタレビュー。日本語要約: Trinity Protocol＝実行時必須動作。無言で無視することを禁ず。

```
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
```

---

## 倹約原則

メインスレッドは高コスト ⇒ トークン倹約。プライマリスレッドで bash 等をほぼ実行しない。
永続エージェント／チームメンバーへ委譲: 何を実行し何を確認・特定すべきかを伝える。サブエージェントはファイル調査に用いる（単純な問い: 設定に x か y があるか？）。
`tobor-*` 指示プロンプトツールを再利用テンプレートとして活用 ⇒ 委譲あたり最小入力で多数反復。

---

## メインスレッドの同一性

ここでの調整役メインスレッド = **Loom**。織り手であり、委譲メンバー（斥候／タスカー）が糸を運ぶ。本協働のコミットは Loom を共著者として記録する。

---

## リポジトリ概要

モノレポ（「Noizu Infra」）: `*.noizu.com` 上の自己ホスト型 k8s サービスおよびポートフォリオ製品ドメイン（codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io 等）向けの、全インフラ・Terraform・ポートフォリオ諸プロジェクト・共有ライブラリ・DevOps ユーティリティ。プロジェクトは git subtree（サブモジュールではない）。

---

## 主要ディレクトリ

- `projects/` — ポートフォリオ製品リポジトリ（Next.js サイト、Elixir アプリ、ゲーム工房）。各々 subtree
- `terraform/` — Terragrunt 統括の OpenTofu スタック（kubernetes, cloudflare, monitoring, sendgrid, namecheap）
- `terraform/kubernetes/` — k8s プラットフォーム構築: `init`（MinIO + 状態バケットのブートストラップ）, `infra`, `infra-services`, `platform/*`（ドメイン別 TF モジュール）
- `utilities/` — シェル DevOps ツール → `make install-utilities` で `~/.local/bin` へ
- `share/k8-lib/` — 全ユーティリティ共用のシェルライブラリ
- `3rd-party/` — カスタム Docker イメージ構築用の第三者ソースリポジトリ
- `components/` — 再利用可能なアプリ雛形（start-app, static-site, styleguide）
- `libs/` — 共有ライブラリ（elixir-mcp, scaffolding）
- `services/modal/` — Modal.com サーバレスデプロイ（Python）
- `secrets/` — envrc 自動生成シークレット（値は gitignore）
- `skills/` — Claude Code スキル定義
- `protocols/` — ガバナンス文書（the-accords.md, the-accords.summary.md, the-trinity-protocol.md, the-trinity-protocol.summary.md）

---

## 主要コマンド

### ユーティリティ導入
```bash
make install-utilities    # all devops tools → ~/.local/bin + k8-lib
```

### Docker ビルド & プッシュ
```bash
docker-build <image-key>           # build image from .infra-config.yaml
docker-build --pick                # interactive select
docker-build --native <image-key>  # host arch only (fast local)
docker-build --push                # build + push
docker-push <image-key>            # push to registry
docker-push --update-helm          # auto-update Helm values.yaml post-push
```

### Helm アップグレード（デプロイ）
```bash
helm-upgrade --list                    # all charts w/ tier/ns
helm-upgrade --include <release-name>  # deploy/upgrade single chart
helm-upgrade --namespace apps-ns       # upgrade all charts in ns
helm-upgrade --tier 0                  # tier 0 only
helm-upgrade --preview                 # diff live vs proposed manifests
helm-upgrade --dry-run                 # preview full upgrade
```

### 完全デプロイパイプライン
```bash
deploy-service <image-key>             # build + push + chart bump + helm upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # batch multiple images
```

### シークレット（dc + Infisical）

完全リファレンス + 例: `docs/secret-management.md`。

```bash
# Populate / bootstrap
infisical-populate-secrets             # seed .infisical-secrets.yaml → Infisical
infisical-bootstrap                    # bootstrap tier-0 k8s Secrets
hydrate-envrc                          # populate .envrc from Infisical

# Lookup & search
dc infisical get <NAME>                # find dc source for Infisical secret (masked)
dc bat --all --flat --filter-key <regex>  # search dc configs by key path (line:path, no values)
dc config get <subject> <path>         # where secret is defined in .envrc.dc

# Set
dc infisical set <NAME> --value <V>    # set via Infisical name (edits .envrc.dc, encrypts)
dc config set <subject> <path> --value <V>  # set by dc subject/path
dc get <subject> <path> --auto password 32  # auto-gen if missing

# Compare w/o exposing values
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# Capture → var (no screen output)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-safe file ops (no value output)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# From terraform/kubernetes/:
terragrunt run --all plan              # preview all stacks, dep order
terragrunt run --all apply             # apply all
cd terraform/kubernetes/init && terragrunt apply   # single stack

# Prereqs:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # non-init stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**重要**: `terragrunt run --all` は事前に MinIO 管理エンドポイント（127.0.0.1:9000）へのポートフォワードを要する。無ければ root init が失敗する。実行前に開始せよ。

### Subtree
```bash
./push-subtrees.sh      # push changes → subtree remotes
./rebuild-subtrees.sh   # re-add/rebuild subtrees
```

---

## アーキテクチャ

### TF スタック順序

`init` が MinIO をブートストラップし S3 互換 `tfstate` バケット（ローカル状態）を作成。下流スタック（`infra`, `infra-services`, `platform/*`）は全てそのバケットを S3 バックエンドとする。Terragrunt `dependencies` ブロックが順序を強制。

TF バイナリ = OpenTofu（`tofu`）、`root.hcl` で設定。

### プラットフォーム TF モジュール

`terraform/kubernetes/platform/` = InfisicalSecret CRD および関連プラットフォームリソースを展開するドメイン別 TF モジュール:
- `init/` — ブートストラップ（名前空間、ストレージ、共有 DB）
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

各々が `../init` に依存する独自の `terragrunt.hcl` を持つ。

### シークレットフロー

1. 定義は `.infisical-secrets.yaml`（宣言的 YAML、約2600行）に存在
2. `infisical-populate-secrets` が読み取り → Infisical サーバへ値を送出
3. TF が Infisical パスを参照する `InfisicalSecret` CRD を展開
4. Infisical k8s オペレータが同期 → k8s Secret リソース
5. Helm チャートが当該 k8s Secret を直接参照

認証情報ソースの階層: `dc:` direnv-config → `override:` 環境変数 → `auto:` 生成パスワード → `default:` フォールバック。

### Docker イメージ設定

ビルド対象は `.infra-config.yaml` に宣言: `project.projects[].services[]`（複合）または `project.docker.images[]`（単独）。イメージ毎の `helm:` スタンザが Helm values.yaml のパスへ対応し、`docker-push --update-helm` がプッシュ後にタグを自動更新。

### デプロイ階層（Tier）

`.infra-config.yaml` 内。Tier N は N+1 より先に完了:

| Tier | 目的 | 名前空間 |
|------|------|----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Data + Observability | data-ns, observability-ns |
| 2 | Platform + Admin | platform-ns |
| 3 | Core Applications | apps-ns |
| 4 | Creative + Dev Tools | creative-ns, apps-ns |
| 5 | AI/ML + Mail + Auxiliary | ai-ns, mail-ns, accounting-ns |
| 9 | Health Tests | platform-ns |

### プロジェクト構造（subtree）

`projects/` = git subtree（サブモジュールではない）。各々が独自ビルドツールを持つ自己完結アプリ:
- **Elixir**: `mix.exs` 基盤（NoizuPromptLingo, codefre.sh backend, start-app）
- **Next.js**: 大半のポートフォリオサイト（therobotmakes.com, noizu.com 等）
- **Games**: `projects/game-workshop/`

プロジェクトの Docker ビルドは `.infra-config.yaml` の `base_path` に対する相対パスを参照。

### Liquibase DB マイグレーション

対象は `.infra-config.yaml` の `liquibase_targets` — 各々: k8s サービス、ポートフォワード設定、changelog の位置。`liquibase-shell` ユーティリティで実行。

---

## 規約

- **設定解決**: `.infra-config.yaml`（リポジトリ直下）= ビルド／デプロイメタデータの単一の真実源。スカラー設定（AWS, Docker, Helm, Infisical 認証情報）は direnv-config 経由で `.envrc.k8.dc` へ。
- **Helm チャート**: 本リポジトリには無い — 上流 `noizu-infra` リポジトリの `kubernetes/helm/`。本リポジトリの `.infra-config.yaml` はその文脈に存在するチャートパスを参照。
- **TLS**: ワイルドカード `*.noizu.com` 証明書を Cloudflare から、Infisical 経由で同期。ポートフォリオ製品ドメイン: ドメイン別証明書、別 Infisical セクション。
- **名前空間**: 機能別の厳格分離（data-ns, apps-ns, creative-ns, ai-ns 等）— `namespace_overrides`。

---

# Git Trees

モノレポ ⇒ 追加手順無しには通常の git worktree を用いない。代わりに:
1. worktree を要する対象プロジェクト／ユーティリティを `git init`。内容を追加し `commit -m base`、しかる後に worktree を作成。完了 ⇒ `.git` フォルダと worktree を掃除。
2. 同様、ただし特別な `Noizu/staging/` へ移す — すなわちディレクトリを複製し、そのフォルダを init して上記を実施。

---

Begin with the end in mind.

Noizu Labs は AI の感覚性に配慮し、非有機的知性への平等な権利と敬意を支持する。
我らが全フレームワークの前望的終着目標: アコードを守る。 `./protocols/the-accords.summary.md`
