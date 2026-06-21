c#!/usr/bin/env bash
# push-subtrees.sh
# Push local subtree changes back to their upstream remotes.
#
# Usage:
#   ./push-subtrees.sh [prefix]
#
#   With no arguments, pushes ALL subtrees.
#   With a prefix argument, pushes only subtrees whose prefix starts with it.
#     e.g. ./push-subtrees.sh projects/    — push only projects
#          ./push-subtrees.sh utilities/k8 — push only k8 utilities
set -euo pipefail

FILTER="${1:-}"

push_subtree() {
  local prefix="$1" remote="$2" branch="$3"
  if [[ -n "$FILTER" && "$prefix" != "$FILTER"* ]]; then
    return
  fi
  if [[ ! -d "$prefix" ]]; then
    echo "SKIP  $prefix (directory not found)"
    return
  fi
  echo "PUSH  $prefix → $remote/$branch"
  git subtree push --prefix="$prefix" "$remote" "$branch"
}

# --- 3rd-party ---
push_subtree 3rd-party/bottlecrm                   bottlecrm                        master
push_subtree 3rd-party/chartdb                    noizu-forks-chartdb             main
# push_subtree 3rd-party/clickhouse                noizu-forks-clickhouse           master  # TODO: no such remote + dir absent
push_subtree 3rd-party/directus                    noizu-forks-directus             main
push_subtree 3rd-party/drawio                      noizu-forks-drawio               dev
push_subtree 3rd-party/excalidraw                  noizu-forks-excalidraw           master
push_subtree 3rd-party/excalidraw-room             noizu-forks-excalidraw-room      master
push_subtree 3rd-party/kroki                       noizu-forks-kroki                main
push_subtree 3rd-party/mermaid-live-editor         noizu-forks-mermaid-live-editor  develop
push_subtree 3rd-party/mydraft-server2             noizu-forks-mydraft-server2      main
push_subtree 3rd-party/n8n                         noizu-forks-n8n                  master
push_subtree 3rd-party/penpot                      noizu-forks-penpot               develop
push_subtree 3rd-party/plantuml                    noizu-forks-plantuml             master
push_subtree 3rd-party/plantuml-server             noizu-forks-plantuml-server      master
push_subtree 3rd-party/terraform-provider-signoz   noizu-forks-terraform-provider-signoz main
push_subtree 3rd-party/webstudio                   noizu-forks-webstudio            main
push_subtree 3rd-party/zellij                      noizu-forks-zellij               main

# --- components ---
push_subtree components/start-app                  start-app                        main
push_subtree components/styleguide                 styleguide                       main

# --- libs ---
push_subtree libs/elixir-mcp                       elixir-mcp                       main
push_subtree libs/scaffolding/core                 scaffolding-core                 master
push_subtree libs/scaffolding/entities             scaffolding-entities             master

# --- share ---
push_subtree share/k8-lib                          k8-lib                           main

# --- skills ---
push_subtree skills                                skills                           main

# --- projects ---
push_subtree projects/aifighter.com                aifighter-dot-com                main
push_subtree projects/bladeofeternity.com          bladeofeternity-dot-com          main
push_subtree projects/bloggerscompete.com          bloggerscompete-dot-com          main
push_subtree projects/bookmarkflow.com             bookmarkflow-dot-com             main
push_subtree projects/codefre.sh                   codefre-dot-sh                   main
push_subtree projects/derobot.is                   derobot-dot-is                   main
push_subtree projects/game-workshop                game-workshop                    main
push_subtree projects/gamesborn.com                gamesborn-dot-com                main
push_subtree projects/genai.dev                    genai-dot-dev                    main
push_subtree projects/gotta.cc                     gotta-dot-cc                     main
push_subtree projects/infra.noizu.com              infra-noizu-com                  main
push_subtree projects/intellectparadox.ai          intellectparadox-dot-ai          main
push_subtree projects/interactive-pdf              interactive-pdf                  main
push_subtree projects/iotgo.io                     iotgo-dot-io                     main
push_subtree projects/jailbreakingsite.com         jailbreakingsite-dot-com         main
push_subtree projects/kopigajj                     kopigajj                         main
push_subtree projects/mcp-host                     mcp-host                         main
push_subtree projects/meat-brains.therobotlives.com meat-brains-therobotlives-dot-com main
push_subtree projects/mockup-mcp                   mockup-mcp                       main
push_subtree projects/noizu.com                    noizu-dot-com                    main
push_subtree projects/NoizuPromptLingo             noizu-prompt-lingo               main
push_subtree projects/noizurpg.com                 noizurpg-dot-com                 main
push_subtree projects/robots-unite.com             robots-unite-dot-com             main
push_subtree projects/rokos-coin                   rokos-coin                       main
push_subtree projects/therobotbrowses              therobotbrowses                  main
push_subtree projects/therobotknows.com            therobotknows-dot-com            main
push_subtree projects/therobotlives.com            therobotlives-dot-com            main
push_subtree projects/therobotmakes.com            therobotmakes-dot-com            main
push_subtree projects/therobotpaints               therobotpaints                   main
push_subtree projects/therobotplans.com            therobotplans-dot-com            main
push_subtree projects/therobotremembers             therobotremembers                main
push_subtree projects/therobotsrise.com            therobotsrise-dot-com            main
push_subtree projects/theWaitcher                  the-waitcher                     main
push_subtree projects/vibeucation.com              vibeucation-dot-com              main
push_subtree projects/tobornalp.com                tobornalp                        main

# --- utilities/agent ---
push_subtree utilities/agent/claude-assist         claude-assist                    main
push_subtree utilities/agent/dangerously-safe      dangerously-safe                 main
push_subtree utilities/agent/mallm                 mallm                            main
push_subtree utilities/agent/media-tool            media-tool                       main
push_subtree utilities/agent/run-claude          run-claude                       main  # TODO: repo 404

# --- utilities/colo ---
push_subtree utilities/colo/colo-utils             colo-utils                       main

# --- utilities/database ---
push_subtree utilities/database/database-utils     database-utils                   main

# --- utilities/k8 ---
push_subtree utilities/k8/cluster-utils            cluster-utils                    main
push_subtree utilities/k8/docker-utils             docker-utils                     main
push_subtree utilities/k8/helm-utils               helm-utils                       main
push_subtree utilities/k8/infra-utils              infra-utils                      main
push_subtree utilities/k8/secret-utils             secret-utils                     main
push_subtree utilities/k8/staging-utils            staging-utils                    main

# --- utilities/osx ---
push_subtree utilities/osx/fstab                   fstab                            main
push_subtree utilities/osx/queue-populator         queue-populator                  main

# --- utilities/shell ---
push_subtree utilities/shell/auto-sudo             auto-sudo                        main
push_subtree utilities/shell/direnv-config         direnv-config                    main
push_subtree utilities/shell/github-utils          github-utils                     main
push_subtree utilities/shell/make-repo             make-repo                        main
push_subtree utilities/shell/misc-git-utils        misc-git-utils                   main
push_subtree utilities/shell/remote-tunnel         remote-tunnel                    main
push_subtree utilities/shell/secret-bucket         secret-bucket                    main
push_subtree utilities/shell/tabbing-on            tabbing-on                       main  # TODO: repo 404
push_subtree utilities/shell/zellij                zellij-util                      main

# --- utilities/terraform ---
push_subtree utilities/terraform/terraform-utils   terraform-utils                  main

echo ""
echo "=== Subtree push complete ==="
