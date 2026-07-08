INSTALL_DIR ?= $(HOME)/.local/bin
LIB_INSTALL_DIR ?= $(HOME)/.local/share/start-app-scaffold

.PHONY: compile test install

compile:
	@true

test:
	@bash -n lib/repo-root.sh && echo "✓ lib/repo-root.sh"
	@for f in init-proj-scaffold build-start-app-tarball start-app-scaffold llm-merge-start-app; do \
		bash -n "bin/$$f" && echo "✓ bin/$$f"; \
	done

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in init-proj-scaffold build-start-app-tarball start-app-scaffold llm-merge-start-app; do \
		install -m 755 "bin/$$f" "$(INSTALL_DIR)/$$f"; \
		echo "✓ Installed $$f"; \
	done
	@mkdir -p $(LIB_INSTALL_DIR)
	@install -m 644 lib/repo-root.sh "$(LIB_INSTALL_DIR)/repo-root.sh"
	@echo "✓ Installed lib/repo-root.sh -> $(LIB_INSTALL_DIR)/repo-root.sh"
