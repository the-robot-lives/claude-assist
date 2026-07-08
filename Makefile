.PHONY: install-utilities install \
        trd-build trd-run trd-test trd-open trd-clean trd-doctor \
        rtui-build rtui-run rtui-shim rtui-rebuild rtui-clean rtui-log

install-utilities:
	@HOME_DIR="$(HOME)"; \
	WRITE_CHECK="$$HOME_DIR/.local/.install-utilities-write-check"; \
	if [ -z "$$HOME_DIR" ]; then \
		HOME_DIR="/tmp"; \
	fi; \
	if [ ! -w "$$HOME_DIR" ] || ! mkdir -p "$$HOME_DIR/.local" "$$HOME_DIR/.config/direnv" "$$HOME_DIR/.local/share" "$$HOME_DIR/.local/bin" 2>/dev/null; then \
		HOME_DIR="/tmp"; \
	fi; \
	mkdir -p "$$HOME_DIR/.local/bin" "$$HOME_DIR/.local/share" "$$HOME_DIR/.config/direnv/lib" "$$HOME_DIR/.config/zellij/layouts" 2>/dev/null || true; \
	touch "$$WRITE_CHECK" 2>/dev/null && rm -f "$$WRITE_CHECK" || HOME_DIR="/tmp"; \
	CI=true HOME="$$HOME_DIR" $(MAKE) -C utilities install

install: install-utilities

# --- The Robot Draft (Unity/VR) — delegate to projects/therobotdrafts/Makefile ---
trd-build trd-run trd-test trd-open trd-clean trd-doctor:
	@$(MAKE) -C projects/therobotdrafts $(patsubst trd-%,%,$@)

# --- robot-tui (therobot terminal UI) — delegate to the crate Makefile ---
rtui-build rtui-run rtui-shim rtui-rebuild rtui-clean rtui-log:
	@$(MAKE) -C 3rd-party/llama.cpp/tools/robot-tui $(patsubst rtui-%,%,$@)
