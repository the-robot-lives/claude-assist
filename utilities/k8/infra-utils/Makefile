INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: compile test install install-completions

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in infra-init deploy-one-off deploy-service open-dashboard add-import-permissions infra-config; do \
		install -m 755 "bin/$$f" "$(INSTALL_DIR)/$$f"; \
		echo "✓ Installed $$f"; \
	done
	@$(MAKE) install-completions

install-completions:
	@DATA_DIR="$${XDG_DATA_HOME:-$$HOME/.local/share}"; \
	BASH_DIR="$$DATA_DIR/bash-completion/completions"; \
	ZSH_DIR="$$DATA_DIR/zsh/site-functions"; \
	if ! mkdir -p "$$BASH_DIR" "$$ZSH_DIR" 2>/dev/null; then \
		echo "infra-utils: cannot write completion dirs; skipping."; \
		exit 0; \
	fi; \
	cp completions/deploy-service.bash "$$BASH_DIR/deploy-service"; \
	cp completions/_deploy-service "$$ZSH_DIR/_deploy-service"; \
	cp completions/infra-config.bash "$$BASH_DIR/infra-config"; \
	cp completions/_infra-config "$$ZSH_DIR/_infra-config"; \
	echo "infra-utils: completions installed (bash-completion + zsh)"; \
	if ! grep -qs "zsh/site-functions" "$$HOME/.zshrc" 2>/dev/null; then \
		echo "infra-utils: zsh users — add to .zshrc before compinit:"; \
		echo "  fpath=($$ZSH_DIR \$$fpath)"; \
	fi
