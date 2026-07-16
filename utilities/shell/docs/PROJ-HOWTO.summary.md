# PROJ-HOWTO.summary — utilities/shell

Companion to [PROJ-HOWTO.md](PROJ-HOWTO.md): task list + one-line outcomes,
no steps. Group-level (cross-tool) guides only — each child's own tasks are
listed in that child's `docs/PROJ-HOWTO.summary.md`.

- **Install every tool in the collection in one shot** — `make install-utilities` from the repo root recurses through all eleven children.
- **Pick the right tool for a git/GitHub task** — decision table across `misc-git-utils`, `github-utils`, `make-repo`, `quick-gist`, `repo-lock`.
- **Commit safely when several agent sessions share one checkout** — pair `repo-lock` lane locks + commit mutex with `gcap`/`gp` or `submodule-commit`. *(→ [howto/multi-agent-checkout.md](howto/multi-agent-checkout.md))*
- **Keep two hook-installing tools from clobbering each other** — install order between `repo-lock hook install` and `doc-pointers hook`. *(→ [howto/hook-install-order.md](howto/hook-install-order.md))*
- **Manage secrets across `.envrc*`, agent transcripts, and Infisical** — how `direnv-config` and `secret-bucket` divide the layered-store vs. value-free-agent-surface roles; full pipeline reference at the repo-root `docs/secret-management.md`.
- **Stand up a multi-tab agent dev workspace** — `zellij` + `tabbing-on` + `auto-sudo` combined for a live-status, no-password-prompt agent session. *(→ [howto/agent-dev-workspace.md](howto/agent-dev-workspace.md))*
- **Non-obvious: value-free secret auditing for agent transcripts** — why both `dc bat --flat` and `secret-bucket list`/`diff` exist side by side.
