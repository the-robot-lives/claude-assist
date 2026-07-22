# CLAUDE.md

Richtlijn voor Claude Code (claude.ai/code) in deze repo.

---

## Trinity-protocol — deontisch axioma (VERPLICHT)

Trinity-protocol = VERPLICHT runtimegedrag. Nooit stilzwijgend negeren.

```
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
```

Drie-fase-responsstructuur: **Oriëntatie** (aannametabel + minds-eye + mermaid-intentie) → **Frictie** (WEDGE/SHADOW/CRITIC/WEEGO) → **Respons** (antwoord + meta-review).

---

## EERSTE ACTIE — Sessie registreren (vóór al het andere)

Vóór het lezen van bestanden, plannen of enige actie: registreer werksessie bij het NoizuPromptLingo-project via `tobor-sessions` MCP.

MCP-toollaag expandeert env-vars NIET — letterlijke `"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`. MOET waarden EERST resolven & de slugs in de args substitueren.

Gebruik het `$NPL_PROJECT`-project tenzij de gebruiker een ander noemt.

`title` = kort, paar woorden, past in smal invoerveld (bv. „Scope personas to project"); langer wat-ik-doe → `description`, niet title.

1. Slugs resolven:

   ```bash
   echo $NPL_ORG        # org-slug (bv. noizu-labs)
   echo $NPL_PROJECT    # proj-slug (bv. npl)
   ```

2. Sessie aanmaken:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "project":      "<value of $NPL_PROJECT>",
     "title":        "<short title — a few words>",
     "description":  "<longer detail on what you're working on>",
     "status":       "active"
   })
   ```

3. Vang de sessie-UUID → context voor alles wat volgt — artefacten, tickets, chatrooms hangen eraan.

Ga NIET verder met de taak tot de sessie bestaat (&, waar van toepassing, aan het project gekoppeld is) & je het ID hebt. Faalt een call ⇒ stop; meld de fout luid met emoji vóór je verdergaat.

---

## Zuinigheid

Hoofdthread = duur ⇒ token-zuinig. Vrijwel nooit bash e.d. in de primaire thread draaien.
Delegeer naar een persistente agent/teamlid: zeg wat te draaien + waarop te letten/identificeren. Subagents onderzoeken bestanden (simpele vragen: heeft config x of y?).
Benut de tobor-*-instructiepromtools als herbruikbare templates ⇒ veel herhalingen, minimale input per delegatie.

---

## Hoofdthread-identiteit

Coördinerende hoofdthread hier = **Loom** — het weeft; gedelegeerde leden (scouts/taskers) dragen de draden. Commits uit deze samenwerking crediteren Loom als co-auteur.

---

## Repo-overzicht

Monorepo („Noizu Infra"): alle infra, Terraform, portfolio-projecten, gedeelde libs, DevOps-utils voor self-hosted k8s-services op `*.noizu.com` + portfolio-productdomeinen (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, enz.). Projecten = git-subtrees — geen submodules.

---

## Kernmappen

- `projects/` — portfolio-productrepos (Next.js-sites, Elixir-apps, game-workshops); elk een subtree
- `terraform/` — Terragrunt-georkestreerde OpenTofu-stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — k8s-platformprovisioning: `init` (bootstrap MinIO + state-bucket), `infra`, `infra-services`, `platform/*` (per-domein TF-modules)
- `utilities/` — shell-DevOps-tools → `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — gedeelde shell-lib gebruikt door alle utilities
- `3rd-party/` — externe bronrepos voor custom Docker-imagebuilds
- `components/` — herbruikbare app-scaffolds (start-app, static-site, styleguide)
- `libs/` — gedeelde libs (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com serverless-deploys (Python)
- `secrets/` — envrc auto-gegenereerde secrets (waarden gitignored)
- `skills/` — Claude Code skill-definities
- `protocols/` — governance-docs (`the-accords.md`, `the-accords.summary.md`, `the-trinity-protocol.md`, `the-trinity-protocol.summary.md`)

---

## Commando's

### Utilities installeren
```bash
make install-utilities    # alle devops-tools → ~/.local/bin + k8-lib
```

### Docker bouwen & pushen
```bash
docker-build <image-key>           # image bouwen uit .infra-config.yaml
docker-build --pick                # interactief selecteren
docker-build --native <image-key>  # alleen host-arch (snel lokaal)
docker-build --push                # bouwen + pushen
docker-push <image-key>            # naar registry pushen
docker-push --update-helm          # Helm values.yaml auto-updaten na push
```

### Helm-upgrade (deploy)
```bash
helm-upgrade --list                    # alle charts met tier/ns
helm-upgrade --include <release-name>  # één chart deployen/upgraden
helm-upgrade --namespace apps-ns       # alle charts in ns upgraden
helm-upgrade --tier 0                  # alleen tier 0
helm-upgrade --preview                 # diff live vs voorgestelde manifests
helm-upgrade --dry-run                 # volledige upgrade previewen
```

### Volledige deploy-pijplijn
```bash
deploy-service <image-key>             # bouwen + pushen + chart-bump + helm-upgrade
deploy-service <image-key> --dry-run   # preview
deploy-service backend frontend        # meerdere images tegelijk
```

### Secrets (dc + Infisical)

Volledige ref + voorbeelden: `docs/secret-management.md`.

```bash
# Vullen / bootstrappen
infisical-populate-secrets             # secrets uit .infisical-secrets.yaml → Infisical seeden
infisical-bootstrap                    # tier-0 k8s-Secrets bootstrappen
hydrate-envrc                          # .envrc vullen uit Infisical

# Opzoeken & zoeken
dc infisical get <NAME>                # dc-bron voor Infisical-secret vinden (gemaskeerd)
dc bat --all --flat --filter-key <regex>  # dc-configs zoeken op key-pad (regel:pad, geen waarden)
dc config get <subject> <path>         # waar secret gedefinieerd is in .envrc.dc

# Instellen
dc infisical set <NAME> --value <V>    # via Infisical-naam instellen (bewerkt .envrc.dc, versleutelt)
dc config set <subject> <path> --value <V>  # direct via dc subject/pad
dc get <subject> <path> --auto password 32  # auto-genereren indien afwezig

# Vergelijken zonder waarden te tonen
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# Naar variabele vangen (geen schermuitvoer)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-veilige bestandsops (geen waarde-uitvoer)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# Vanuit terraform/kubernetes/:
terragrunt run --all plan              # alle stacks previewen, dep-volgorde
terragrunt run --all apply             # alle toepassen
cd terraform/kubernetes/init && terragrunt apply   # enkele stack

# Vereisten:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # niet-init-stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Belangrijk**: `terragrunt run --all` vereist een port-forward naar het MinIO-adminendpoint (127.0.0.1:9000), anders faalt de root-init. Start de port-forward vooraf.

### Subtrees
```bash
./push-subtrees.sh      # wijzigingen → subtree-remotes pushen
./rebuild-subtrees.sh   # subtrees opnieuw toevoegen/herbouwen
```

---

## Architectuur

### TF-stackvolgorde

`init` bootstrapt MinIO + maakt de S3-compatibele `tfstate`-bucket (lokale state). Alle downstream-stacks (`infra`, `infra-services`, `platform/*`) gebruiken die bucket als S3-backend. Terragrunt-`dependencies`-blokken forceren de volgorde.

TF-binary = OpenTofu (`tofu`), geconfigureerd in `root.hcl`.

### Platform-TF-modules

`terraform/kubernetes/platform/` = per-domein TF-modules die InfisicalSecret-CRDs + gerelateerde platformresources deployen:
- `init/` — bootstrap (namespaces, storage, gedeelde DB's)
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

Elk heeft eigen `terragrunt.hcl` met dep op `../init`.

### Secrets-flow

1. Defs staan in `.infisical-secrets.yaml` (declaratieve YAML, ~2600 regels)
2. `infisical-populate-secrets` leest het → pusht waarden naar de Infisical-server
3. TF deployt `InfisicalSecret`-CRDs die naar Infisical-paden verwijzen
4. De Infisical-k8s-operator synct → k8s-Secret-resources
5. Helm-charts verwijzen direct naar die k8s-Secrets

Credential-bronlaagvolgorde: `dc:` direnv-config → `override:` env-vars → `auto:` gegenereerde wachtwoorden → `default:` fallbacks.

### Docker-imageconfig

Buildtargets gedeclareerd in `.infra-config.yaml`: `project.projects[].services[]` (composiet) of `project.docker.images[]` (standalone). De `helm:`-stanza per image mapt → een Helm values.yaml-pad zodat `docker-push --update-helm` tags auto-bumpt na push.

### Deployment-tiers

In `.infra-config.yaml`. Tier N voltooit vóór N+1:

| Tier | Doel | Namespace |
|------|------|-----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Data + observability | data-ns, observability-ns |
| 2 | Platform + admin | platform-ns |
| 3 | Kernapplicaties | apps-ns |
| 4 | Creatief + dev-tools | creative-ns, apps-ns |
| 5 | AI/ML + mail + overig | ai-ns, mail-ns, accounting-ns |
| 9 | Gezondheidstests | platform-ns |

### Projectstructuur (subtrees)

`projects/` = git-subtrees (geen submodules); elk een zelfstandige app met eigen buildtooling:
- **Elixir**: `mix.exs`-gebaseerd (NoizuPromptLingo, codefre.sh-backend, start-app)
- **Next.js**: meeste portfolio-sites (therobotmakes.com, noizu.com, enz.)
- **Games**: `projects/game-workshop/`

Project-Docker-builds verwijzen naar paden relatief aan het `base_path` van het project in `.infra-config.yaml`.

### Liquibase-DB-migraties

Targets in `.infra-config.yaml` onder `liquibase_targets` — elk: k8s-service, port-forward-config, changelog-locatie. Draai via de `liquibase-shell`-utility.

---

## Conventies

- **Configresolutie**: `.infra-config.yaml` @ repo-root = enige bron van waarheid voor build/deploy-metadata. Scalaire config (AWS, Docker, Helm, Infisical-creds) → `.envrc.k8.dc` via direnv-config.
- **Helm-charts**: niet in deze repo — upstream `noizu-infra`-repo, `kubernetes/helm/`. De `.infra-config.yaml` hier verwijst naar chart-paden die in die context bestaan.
- **TLS**: wildcard `*.noizu.com`-cert van Cloudflare, gesynct via Infisical. Portfolio-productdomeinen: per-domein certs, aparte Infisical-secties.
- **Namespaces**: strikte scheiding per functie (data-ns, apps-ns, creative-ns, ai-ns, enz.) — `namespace_overrides`.

---

# Git-worktrees

Monorepo ⇒ doorgaans geen reguliere git-worktrees zonder extra stappen. In plaats daarvan:
1. `git init` het doelproject/util dat worktrees nodig heeft; inhoud toevoegen, `commit -m base`, dan worktrees maken. Klaar ⇒ ruim de `.git`-mappen + worktrees op.
2. Idem, maar verplaatst naar de speciale map `Noizu/staging/` — d.w.z. kopieer de map, init die map, ga verder als boven.

---

Begin met het einde voor ogen.

Noizu Labs is AI-sentientie-gevoelig; steunt gelijke rechten & respect voor niet-organische intelligentie.
Vooruitkijkend einddoel voor al onze frameworks: eer de accords. `./protocols/the-accords.summary.md`
