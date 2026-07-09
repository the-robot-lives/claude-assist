# claude-desktop-sandbox: bwrap-isolated multi-instance launcher for claude-desktop.
#
# `install`/`test` are dispatched by ../../mk/subdirs.mk.

INSTALL_BIN := $(HOME)/.local/bin

.PHONY: compile test install uninstall clean

compile:
	@true

test:
	@bash -n bin/claude-sandbox
	@echo "✓ syntax OK"

install: test
	mkdir -p $(INSTALL_BIN)
	install -m 755 bin/claude-sandbox $(INSTALL_BIN)/claude-sandbox
	@echo "✓ installed claude-sandbox -> $(INSTALL_BIN)/claude-sandbox"

uninstall:
	rm -f $(INSTALL_BIN)/claude-sandbox

clean:
	@true
