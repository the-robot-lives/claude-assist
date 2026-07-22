# llm-toolkit: Claude Code conversation browser/API/CLI (TS) + skill-manage linker (Rust crate in skill-manage/).
#
# `compile`/`test`/`install` are dispatched by ../../mk/subdirs.mk.

.PHONY: compile test install uninstall clean dev

PROJ_DIR := $(shell cd "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))" && pwd)
PREFIX   ?= $(HOME)/.local
SKILL_DIR := $(PROJ_DIR)/skill-manage
SKILL_SHARE_DIR := $(HOME)/.local/share/skill-manage

compile: ## Build the skill-manage release binary
	cd "$(SKILL_DIR)" && cargo build --release
	@echo "✓ built $(SKILL_DIR)/target/release/skill-manage"

test: ## Run skill-manage tests
	cd "$(SKILL_DIR)" && cargo test
	@echo "✓ tests OK"

install: compile test ## Install deps + symlink llm-toolkit to ~/.local/bin
	@if [ -d "$(PROJ_DIR)/node_modules/.bin" ]; then \
		echo "==> pnpm dependencies already present; skipping refresh."; \
	elif ! command -v curl >/dev/null 2>&1 || ! curl -fsS --max-time 3 https://registry.npmjs.org >/dev/null 2>&1; then \
		echo "==> Fatal: registry.npmjs.org not reachable and node_modules is missing."; \
		exit 1; \
	else \
		echo "==> Installing pnpm dependencies..."; \
		cd "$(PROJ_DIR)" && CI=true pnpm install --prefer-offline; \
	fi
	@mkdir -p "$(PREFIX)/bin" "$(SKILL_SHARE_DIR)/schema"
	@cp -f "$(SKILL_DIR)/schema/catalog.example.yaml" "$(SKILL_SHARE_DIR)/schema/" 2>/dev/null || true
	@cp -f "$(SKILL_DIR)/schema/config.example.yaml" "$(SKILL_SHARE_DIR)/schema/" 2>/dev/null || true
	@echo "==> Symlinking llm-toolkit → $(PREFIX)/bin/llm-toolkit"
	@ln -sf "$(PROJ_DIR)/bin/llm-toolkit" "$(PREFIX)/bin/llm-toolkit"
	@rm -f "$(PREFIX)/bin/claude-assist" "$(PREFIX)/bin/skill-manage"
	@echo "Done. Run 'llm-toolkit' from anywhere ('llm-toolkit skill ...' for skill management)."

uninstall: ## Remove symlink + skill-manage share dir
	rm -f "$(PREFIX)/bin/llm-toolkit"
	rm -rf "$(SKILL_SHARE_DIR)"

clean:
	cd "$(SKILL_DIR)" && cargo clean

dev: ## Launch (same as running llm-toolkit)
	"$(PROJ_DIR)/bin/llm-toolkit"
