.PHONY: install-utilities install \
        trd-build trd-run trd-test trd-open trd-clean trd-doctor \
        rtui-build rtui-run rtui-shim rtui-rebuild rtui-clean rtui-log \
        doc-pointers doc-pointers-check doc-pointers-annotate

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

# --- doc-pointers (root DB) — canonical scoped invocation for the monorepo root.
# Never sweeps projects/ (therobotdrafts owns its own DB). Keep flags in sync with
# utilities/shell/misc-git-utils/docs/howto/doc-pointers-annotate.md.
DOC_POINTERS_SCOPE = --include utilities --include share --include libs \
        --include components --include docs \
        --exclude utilities/agent/run-claude/repos \
        --exclude components/styleguide/app/out

doc-pointers:
	doc-pointers build --root . $(DOC_POINTERS_SCOPE) --write

doc-pointers-check:
	doc-pointers build --root . $(DOC_POINTERS_SCOPE) --check

doc-pointers-annotate:
	doc-pointers annotate --root . $(DOC_POINTERS_SCOPE) --write
