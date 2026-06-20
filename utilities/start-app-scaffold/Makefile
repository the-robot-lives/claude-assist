INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: compile test install

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in init-proj-scaffold build-start-app-tarball; do \
		install -m 755 "bin/$$f" "$(INSTALL_DIR)/$$f"; \
		echo "✓ Installed $$f"; \
	done
