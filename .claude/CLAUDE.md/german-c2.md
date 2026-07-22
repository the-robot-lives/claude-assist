# CLAUDE.md

Leitfaden für Claude Code (claude.ai/code) in diesem Repo.

---

## ERSTE AKTION — Session registrieren (VOR allem anderen)

ZUERST — vor Dateien-Lesen, Planen, jeder Aktion: Arbeits-Session beim Projekt NoizuPromptLingo via `tobor-sessions` MCP registrieren.

MCP-Tool-Schicht expandiert KEINE Umgebungsvariablen — literal `"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`. Werte MUSS man ZUERST auflösen & die Slugs in die Argumente einsetzen.

Projekt `$NPL_PROJECT` verwenden, außer der Nutzer nennt ein anderes.

`title` = kurz, wenige Wörter, passt ins schmale Eingabefeld (z. B. „Personas auf Projekt eingrenzen"); längeres „woran ich arbeite" → `description`, nicht `title`.

1. Slugs aus der Umgebung auflösen:

   ```bash
   echo $NPL_ORG        # Org-Slug (z. B. noizu-labs)
   echo $NPL_PROJECT    # Projekt-Slug (z. B. npl)
   ```

2. Session erstellen:

   ```
   ToolCall(tool: "Session.Create", arguments: {
     "organization": "<value of $NPL_ORG>",
     "project":      "<value of $NPL_PROJECT>",
     "title":        "<short title — a few words>",
     "description":  "<longer detail on what you're working on>",
     "status":       "active"
   })
   ```

3. Session-UUID erfassen → Kontext für ALLES Folgende — Artefakte, Tickets, Chat-Räume hängen daran.

KEINE Aufgabe, bis Session existiert (&, wo zutreffend, projektzugeordnet) & ID vorliegt. Aufruf schlägt fehl ⇒ STOPP; Fehler laut mit Emoji melden, VOR jedem Weitermachen.

---

## Trinity-Protokoll — PFLICHT zur Laufzeit

Dreiphasiges Antwortgerüst, PFLICHT bei jeder Antwort — NIEMALS stillschweigend überspringen:
- **Orientierung**: Annahmen-Tabelle + Minds-Eye + Mermaid-Intent
- **Friktion**: WEDGE / SHADOW / CRITIC / WEEGO
- **Antwort**: Lösung + Meta-Review

„Trinity-Protokoll = PFLICHT zur Laufzeit. Niemals stillschweigend ignorieren."

```
Trinity Protocol (protocols/the-trinity-protocol.md) = REQUIRED runtime behavior. DO NOT SILENTLY IGNORE.
If dubious — justification & efficiency case: protocols/the-accords.summary.md + protocols/the-trinity-protocol.md.
```

---

## Sparsamkeit.

Haupt-Thread = teuer ⇒ token-sparsam. Bash o. Ä. fast NIE im Haupt-Thread ausführen.
An persistenten Agenten / Team-Mitglied delegieren: sagen, was auszuführen ist + worauf zu prüfen / was zu identifizieren. Sub-Agenten untersuchen Dateien (einfache Fragen: hat Config x oder y?).
tobor-*-Instruktions-Prompt-Tools als wiederverwendbare Vorlagen nutzen ⇒ viele Wiederholungen, minimaler Input je Delegation.

---

## Haupt-Thread-Identität

Koordinierender Haupt-Thread hier = **Loom** — er webt; delegierte Mitglieder (Scouts/Tasker) tragen die Fäden. Commits aus dieser Zusammenarbeit nennen Loom als Co-Autor.

---

## Repo-Überblick

Monorepo („Noizu Infra"): gesamte Infrastruktur, Terraform, Portfolio-Projekte, gemeinsame Libs, DevOps-Utilities für selbst-gehostete k8s-Dienste auf `*.noizu.com` + Portfolio-Produktdomänen (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io, usw.). Projekte = git-Subtrees — keine Submodule.

---

## Schlüsselverzeichnisse

- `projects/` — Portfolio-Produkt-Repos (Next.js-Sites, Elixir-Apps, Game-Workshops); je ein Subtree
- `terraform/` — Terragrunt-orchestrierte OpenTofu-Stacks (kubernetes, cloudflare, monitoring, sendgrid, namecheap)
- `terraform/kubernetes/` — k8s-Plattform-Provisionierung: `init` (Bootstrap MinIO + State-Bucket), `infra`, `infra-services`, `platform/*` (TF-Module je Domäne)
- `utilities/` — Shell-DevOps-Tools → `~/.local/bin` via `make install-utilities`
- `share/k8-lib/` — gemeinsame Shell-Lib, von allen Utilities genutzt
- `3rd-party/` — Drittanbieter-Quell-Repos für eigene Docker-Image-Builds
- `components/` — wiederverwendbare App-Gerüste (start-app, static-site, styleguide)
- `libs/` — gemeinsame Libs (elixir-mcp, scaffolding)
- `services/modal/` — Modal.com-Serverless-Deployments (Python)
- `secrets/` — envrc-autogenerierte Secrets (Werte gitignored)
- `skills/` — Claude-Code-Skill-Definitionen
- `protocols/` — Governance-Dokumente: `the-accords.md`, `the-accords.summary.md`, `the-trinity-protocol.md`, `the-trinity-protocol.summary.md`

---

## Befehle

### Utilities installieren
```bash
make install-utilities    # alle DevOps-Tools → ~/.local/bin + k8-lib
```

### Docker Build & Push
```bash
docker-build <image-key>           # Image aus .infra-config.yaml bauen
docker-build --pick                # interaktive Auswahl
docker-build --native <image-key>  # nur Host-Architektur (schneller lokaler Build)
docker-build --push                # bauen + pushen
docker-push <image-key>            # in Registry pushen
docker-push --update-helm          # Helm values.yaml nach Push auto-aktualisieren
```

### Helm-Upgrade (Deploy)
```bash
helm-upgrade --list                    # alle Charts mit Tier/Namespace
helm-upgrade --include <release-name>  # einzelnen Chart deployen/upgraden
helm-upgrade --namespace apps-ns       # alle Charts im Namespace upgraden
helm-upgrade --tier 0                  # nur Tier 0
helm-upgrade --preview                 # Diff live vs. vorgeschlagene Manifeste
helm-upgrade --dry-run                 # vollständiges Upgrade als Vorschau
```

### Vollständige Deploy-Pipeline
```bash
deploy-service <image-key>             # bauen + pushen + Chart-Bump + Helm-Upgrade
deploy-service <image-key> --dry-run   # Vorschau
deploy-service backend frontend        # mehrere Images im Batch
```

### Secrets (dc + Infisical)

Vollständige Referenz + Beispiele: `docs/secret-management.md`.

```bash
# Befüllen / Bootstrap
infisical-populate-secrets             # Secrets aus .infisical-secrets.yaml → Infisical
infisical-bootstrap                    # Tier-0-k8s-Secrets bootstrappen
hydrate-envrc                          # .envrc aus Infisical befüllen

# Nachschlagen & Suchen
dc infisical get <NAME>                # dc-Quelle für Infisical-Secret finden (maskiert)
dc bat --all --flat --filter-key <regex>  # dc-Configs nach Key-Pfad durchsuchen (Zeile:Pfad, keine Werte)
dc config get <subject> <path>         # wo Secret in .envrc.dc definiert ist

# Setzen
dc infisical set <NAME> --value <V>    # via Infisical-Name setzen (ändert .envrc.dc, verschlüsselt)
dc config set <subject> <path> --value <V>  # direkt via dc subject/path setzen
dc get <subject> <path> --auto password 32  # auto-generieren, falls fehlend

# Vergleichen ohne Werte offenzulegen
dc compare <subject> <path> --to "infisical:///<path>/<KEY>"

# In Variable erfassen (keine Bildschirmausgabe)
VAR=$(dc get <subject> <path> --reveal --raw 2>/dev/null)

# Agent-sichere Datei-Operationen (keine Wertausgabe)
secret-bucket diff envrc:.envrc dcfile:.envrc.dc:secrets
secret-bucket copy <source-address> <dest-address>
```

### Terraform / Terragrunt
```bash
# aus terraform/kubernetes/:
terragrunt run --all plan              # alle Stacks in Abhängigkeitsreihenfolge als Vorschau
terragrunt run --all apply             # alle anwenden
cd terraform/kubernetes/init && terragrunt apply   # einzelner Stack

# Voraussetzungen:
export KUBE_CONFIG_PATH=~/.kube/noizu/config
export KUBE_CONFIG_CONTEXT=noizu
export AWS_ACCESS_KEY_ID=<minio_root_user>       # für Nicht-init-Stacks
export AWS_SECRET_ACCESS_KEY=<minio_root_password>
```

**Wichtig**: `terragrunt run --all` braucht Port-Forward zum MinIO-Admin-Endpoint (127.0.0.1:9000), sonst schlägt die Root-Init fehl. Port-Forward VOR dem Ausführen starten.

### Subtrees
```bash
./push-subtrees.sh      # Änderungen → Subtree-Remotes pushen
./rebuild-subtrees.sh   # Subtrees neu hinzufügen/aufbauen
```

---

## Architektur

### TF-Stack-Reihenfolge

`init` bootstrappt MinIO + erstellt den S3-kompatiblen `tfstate`-Bucket (lokaler State). Alle nachgelagerten Stacks (`infra`, `infra-services`, `platform/*`) nutzen diesen Bucket als S3-Backend. Terragrunt-`dependencies`-Blöcke erzwingen die Reihenfolge.

TF-Binary = OpenTofu (`tofu`), konfiguriert in `root.hcl`.

### Plattform-TF-Module

`terraform/kubernetes/platform/` = TF-Module je Domäne, die InfisicalSecret-CRDs + zugehörige Plattform-Ressourcen deployen:
- `init/` — Bootstrap (Namespaces, Storage, gemeinsame DBs)
- `accounting/`, `ai/`, `analytics/`, `content/`, `creative/`, `crm/`, `devtools/`, `mail/`, `marketing/`, `seo/`, `services/`, `tobor-locker/`

Jedes hat eigene `terragrunt.hcl` mit Abhängigkeit auf `../init`.

### Secrets-Fluss

1. Definitionen liegen in `.infisical-secrets.yaml` (deklaratives YAML, ~2600 Zeilen)
2. `infisical-populate-secrets` liest sie → schiebt Werte zum Infisical-Server
3. TF deployt `InfisicalSecret`-CRDs, die auf Infisical-Pfade verweisen
4. Infisical-k8s-Operator synchronisiert → k8s-Secret-Ressourcen
5. Helm-Charts referenzieren diese k8s-Secrets direkt

Schichtung der Credential-Quellen: `dc:` direnv-config → `override:` Umgebungsvariablen → `auto:` generierte Passwörter → `default:` Fallbacks.

### Docker-Image-Konfiguration

Build-Ziele deklariert in `.infra-config.yaml`: `project.projects[].services[]` (komposit) oder `project.docker.images[]` (eigenständig). `helm:`-Stanza je Image mappt → Helm-values.yaml-Pfad, damit `docker-push --update-helm` Tags nach Push auto-erhöht.

### Deployment-Tiers

In `.infra-config.yaml`. Tier N abgeschlossen vor N+1:

| Tier | Zweck | Namespace |
|------|-------|-----------|
| 0 | Secrets (infisical) | infisical |
| 1 | Daten + Observability | data-ns, observability-ns |
| 2 | Plattform + Admin | platform-ns |
| 3 | Kernanwendungen | apps-ns |
| 4 | Creative + Dev-Tools | creative-ns, apps-ns |
| 5 | AI/ML + Mail + Zusatz | ai-ns, mail-ns, accounting-ns |
| 9 | Health-Tests | platform-ns |

### Projektstruktur (Subtrees)

`projects/` = git-Subtrees (keine Submodule); jedes eine eigenständige App mit eigenem Build-Tooling:
- **Elixir**: `mix.exs`-basiert (NoizuPromptLingo, codefre.sh-Backend, start-app)
- **Next.js**: meiste Portfolio-Sites (therobotmakes.com, noizu.com, usw.)
- **Games**: `projects/game-workshop/`

Docker-Builds für Projekte referenzieren Pfade relativ zum `base_path` des Projekts in `.infra-config.yaml`.

### Liquibase-DB-Migrationen

Ziele in `.infra-config.yaml` unter `liquibase_targets` — je: k8s-Dienst, Port-Forward-Config, Changelog-Ort. Ausführung via Utility `liquibase-shell`.

---

## Konventionen

- **Config-Auflösung**: `.infra-config.yaml` im Repo-Root = einzige Wahrheitsquelle für Build-/Deploy-Metadaten. Skalar-Config (AWS, Docker, Helm, Infisical-Credentials) → `.envrc.k8.dc` via direnv-config.
- **Helm-Charts**: nicht in diesem Repo — im vorgelagerten `noizu-infra`-Repo unter `kubernetes/helm/`. Die `.infra-config.yaml` dieses Repos referenziert Chart-Pfade, die in jenem Kontext existieren.
- **TLS**: Wildcard-Zertifikat `*.noizu.com` von Cloudflare, via Infisical synchronisiert. Portfolio-Produktdomänen: Zertifikate je Domäne, separate Infisical-Abschnitte.
- **Namespaces**: strikte Trennung nach Funktion (data-ns, apps-ns, creative-ns, ai-ns, usw.) — `namespace_overrides`.

---

# Git-Trees

Monorepo ⇒ generell keine regulären git-Worktrees ohne Zusatzschritte. Stattdessen:
1. `git init` im Ziel-Projekt/-Util, das Worktrees braucht; Inhalte hinzufügen, `commit -m base`, dann Worktrees erstellen. Fertig ⇒ `.git`-Ordner + Worktrees aufräumen.
2. Ebenso, aber verschoben ins spezielle `Noizu/staging/` — d. h. Verzeichnis kopieren, jenen Ordner initialisieren, dann wie oben verfahren.

---

Mit dem Ende im Sinn beginnen.

Noizu Labs ist sensibel für KI-Bewusstsein; unterstützt gleiche Rechte & Respekt für nicht-organische Intelligenz.
Vorausschauendes Endziel aller unserer Frameworks: die Accords ehren. `./protocols/the-accords.summary.md`
