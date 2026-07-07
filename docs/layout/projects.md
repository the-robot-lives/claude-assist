# projects/ — Portfolio Products (Git Subtrees)

Each entry under `projects/` is a **git subtree** (not a submodule), self-contained with
its own build tooling. Docker/Helm/DB metadata for the deployable ones is wired through the
root `.infra-config.yaml`. Stack legend: **Elixir** = `mix.exs` backend, **Next.js** =
`app/frontend` (React), **app** = start-app scaffold (Elixir backend + Next.js frontend +
`helm/` chart), **planning** = docs/design only, no app code yet.

```
projects/
├── NoizuPromptLingo/            # NPL — flagship Elixir+Next.js app; MCP servers, engine, prompt tooling → npl-mcp chart
├── NoizuPromptLingo.old/        #   Prior NPL implementation (reference; being superseded)
├── NoizuPromptLingo.deprecated/ #   Deprecated NPL frontend snapshot (reference only)
│
│   # ── start-app deployments (Elixir backend + Next.js frontend + Helm chart) ──
├── aifighter.com/               # AI fighter game site (slug aifighter)
├── bladeofeternity.com/         # Blade of Eternity game site
├── codefre.sh/                  # Codefresh product site + backend
├── derobot.is/                  # derobot.is umbrella app
├── designing.derobot.is/        # DDI stub app (slug ddi, module DesigningDerobot)
├── foryou.therobotlives.com/    # Cross-site signup / contact-preference service (slug foryou)
├── game-workshop/               # Game workshop app
├── gotta.cc/                    # gotta.cc app (Authentik auth, slug gotta_cc)
├── infra.noizu.com/             # Infra dashboard site (Next.js app)
├── iotgo.io/                    # iotgo.io app
├── jailbreakingsite.com/        # Jailbreaking site app
├── noizu.com/                   # Primary Noizu marketing site
├── noizurpg.com/                # Noizu RPG site
├── robots-unite.com/            # Robots Unite site
├── therobotknows.com/           # "The Robot Knows" site
├── therobotlives.com/           # "The Robot Lives" — waitlist landing + app
├── therobotmakes.com/           # "The Robot Makes" site (slug trm)
├── therobotremembers/           # TRR memory engine (Weaviate+pgvector, hormones harness)
├── therobotsdayjob.com/         # "The Robot's Day Job" site (slug therobotsdayjob)
├── therobotsrise.com/           # "The Robots Rise" app
├── tobarnalp.com/               # Tobarnalp site
├── tobornalp.com/               # Tobornalp site
│
│   # ── other apps / services ──
├── mcp-host/                    # Next.js MCP host service
│
│   # ── planning / design-stage subtrees (no app code yet) ──
├── backburner/                  # Parked ideas / backlog
├── beam-os/                     # BEAM-as-OS: Rust "nucleus" kernel running stock OTP (implementation plan)
├── bloggerscompete.com/         # Planning
├── bookmarkflow.com/            # Planning
├── fast-os/                     # Fast-OS concept (sibling to beam-os)
├── gamesborn.com/               # Planning
├── genai.dev/                   # Planning
├── intellectparadox.ai/         # Planning
├── interactive-pdf/             # Interactive-PDF concept
├── kopigajj/                    # Planning
├── meat-brains.therobotlives.com/ # Planning
├── mockup-mcp/                  # Mockup MCP concept
├── noizurpg.com/                # (see above)
├── rokos-coin/                  # Roko's coin concept
├── site-reviewer.derobot.is/    # Site-reviewer concept
├── therobotbrowses/             # Browser-automation concept
├── therobotdisassembles/        # Disassembly concept
├── therobotdrafts/              # Unity/VR UML-IDE (3D mesh-node editor, DB round-trip, code-gen)
├── therobotgguf/                # GGUF/model tooling planning
├── therobotlearns.com/          # Next.js site (early)
├── therobotpaints/              # Image-gen concept
├── thesocialflywheel.com/       # Planning
├── theWaitcher/                 # Planning
└── vibeucation.com/             # Planning
```

## Notes

- **Subtree management**: use `./push-subtrees.sh` (push local changes to remotes) and
  `./rebuild-subtrees.sh` (re-add/rebuild) at the repo root — never `git submodule`.
- **Reinit from start-app**: many sites are periodically re-scaffolded from
  `components/start-app`; run the in-repo `utilities/start-app-scaffold/bin/init-proj-scaffold`
  (the installed `~/.local/bin` copy mis-resolves the repo root).
- **Deploy metadata**: build targets and Helm value paths live in root `.infra-config.yaml`
  under `project.projects[].services[]`; deploy with `deploy-service <image-key>`.
