# The Robot Draft — build / run / test
#
# Unity has no native `make`; these targets wrap the editor's batch-mode entry points and the
# `build-mac.sh` wrapper so the project fits the monorepo's make-driven convention.
#
#   make build   # headless macOS .app  -> Builds/macOS/The Robot Draft.app
#   make run     # build if needed, then open the .app
#   make install # build if needed, then copy the .app into /Applications
#   make test    # run the EditMode test suite headless
#   make open    # open the existing build without rebuilding
#   make clean   # remove Builds/ and test results
#   make doctor  # report the editor that will be used and whether Mac Build Support is present
#   make purge-license  # kill a stuck/zombie Unity licensing client (fixes hangs on "Licensing is not yet initialized")
#   make doc-pointers   # regenerate docs/doc-pointer-db.json and expand markdown deeplinks
#
# Requires a local Unity editor matching ProjectSettings/ProjectVersion.txt (Mac Build Support is
# needed for `build`/`run`, not for `test`). Install via Unity Hub.

PROJECT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
HUB         := /Applications/Unity/Hub/Editor
APP_NAME    := The Robot Draft.app
APP_PATH    := $(PROJECT_DIR)/Builds/macOS/$(APP_NAME)
INSTALL_PATH := /Applications/$(APP_NAME)
DOC_POINTERS := $(PROJECT_DIR)/../../utilities/shell/misc-git-utils/bin/doc-pointers
PIN         := $(shell awk -F': *' '/^m_EditorVersion:/{print $$2}' "$(PROJECT_DIR)/ProjectSettings/ProjectVersion.txt")

# Editor for tests: prefer the pinned version, else the newest installed (Mac module not required).
TEST_EDITOR := $(firstword \
  $(wildcard $(HUB)/$(PIN)/Unity.app/Contents/MacOS/Unity) \
  $(shell ls -dt $(HUB)/*/Unity.app/Contents/MacOS/Unity 2>/dev/null | head -n1))

.PHONY: build run install open test clean doctor help purge-license doc-pointers doc-pointers-check install-doc-pointer-hook

help:
	@echo "The Robot Draft — make targets:"
	@echo "  build   headless macOS .app  -> Builds/macOS/$(APP_NAME)"
	@echo "  run     build if needed, then open the app"
	@echo "  install build if needed, then copy the app into /Applications"
	@echo "  open    open the existing build (no rebuild)"
	@echo "  test    run the EditMode test suite headless"
	@echo "  clean   remove Builds/ and test results"
	@echo "  doctor  show the editor that will be used"
	@echo "  purge-license  kill a stuck Unity licensing client (fixes build hangs)"
	@echo "  doc-pointers  regenerate doc pointer db and expand deeplink: links"
	@echo "  doc-pointers-check  verify doc pointer db/links are current"
	@echo "  install-doc-pointer-hook  install local pre-commit pointer check"
	@echo ""
	@echo "  pinned editor: $(PIN)"

build:
	@"$(PROJECT_DIR)/build-mac.sh"

# Build only if the app is missing, then (re)launch. Kills a running instance first so a freshly built
# binary actually starts — `open` alone just re-focuses an already-running app. (Shell-based, not a file
# prerequisite: the .app path has spaces, which Make would mis-split into targets and rebuild every time.)
run:
	@test -d "$(APP_PATH)" || "$(PROJECT_DIR)/build-mac.sh"
	@pkill -f "The Robot Draft.app/Contents/MacOS" 2>/dev/null || true
	@open "$(APP_PATH)"

open:
	@test -d "$(APP_PATH)" || { echo "No build yet — run 'make build' first." >&2; exit 1; }
	@open "$(APP_PATH)"

# Build if needed, then copy the .app into /Applications (ditto preserves the bundle's resource
# forks/metadata, unlike a plain cp -R). Replaces any existing install at that path.
install:
	@test -d "$(APP_PATH)" || "$(PROJECT_DIR)/build-mac.sh"
	@echo "Installing to $(INSTALL_PATH) ..."
	@rm -rf "$(INSTALL_PATH)"
	@ditto "$(APP_PATH)" "$(INSTALL_PATH)"
	@echo "Installed: $(INSTALL_PATH)"

test:
	@test -n "$(TEST_EDITOR)" || { \
	  echo "ERROR: no Unity editor found under $(HUB)." >&2; \
	  echo "  Install $(PIN) via Unity Hub." >&2; exit 1; }
	@mkdir -p "$(PROJECT_DIR)/Logs"
	@echo "Running EditMode tests with $(TEST_EDITOR) ..."
	@echo "  results: Logs/test-results.xml   log: Logs/test-run.log"
	@"$(TEST_EDITOR)" -batchmode -nographics -projectPath "$(PROJECT_DIR)" \
	  -runTests -testPlatform EditMode \
	  -testResults "$(PROJECT_DIR)/Logs/test-results.xml" \
	  -logFile "$(PROJECT_DIR)/Logs/test-run.log"
	@echo "Tests passed."

clean:
	@rm -rf "$(PROJECT_DIR)/Builds/macOS" "$(PROJECT_DIR)/Builds/build-macos.log" \
	        "$(PROJECT_DIR)/Logs/test-results.xml" "$(PROJECT_DIR)/Logs/test-run.log"
	@echo "Cleaned Builds/ and test results."

doctor:
	@echo "project:        $(PROJECT_DIR)"
	@echo "pinned editor:  $(PIN)"
	@echo "test editor:    $(if $(TEST_EDITOR),$(TEST_EDITOR),<none found>)"
	@if [ -d "$(HUB)/$(PIN)/Unity.app/Contents/PlaybackEngines/MacStandaloneSupport" ]; then \
	  echo "mac build supp: yes (pinned editor can build the .app)"; \
	else \
	  echo "mac build supp: NO on pinned editor — 'build' falls back via build-mac.sh; add 'Mac Build Support' in Unity Hub"; \
	fi
	@echo "installed:      $$(ls "$(HUB)" 2>/dev/null | tr '\n' ' ')"

# A zombie editor-bundled licensing client (left by a crashed/killed batch build) keeps the global
# mutex on the LicenseClient-<user> channel, so every new headless build fails to acquire it and hangs
# 60s on "Licensing is not yet initialized" before erroring out. This kills only the editor's bundled
# client (NOT Unity Hub's own UnityLicensingClient_V1, which lives elsewhere and serves a separate
# channel); the next build spawns a fresh one and connects in <1s.
purge-license:
	@if pkill -f "Hub/Editor/.*/UnityLicensingClient.app/Contents/MacOS/Unity.Licensing.Client" 2>/dev/null; then \
	  echo "Killed stuck Unity licensing client — rerun 'make build'."; \
	else \
	  echo "No stuck licensing client found."; \
	fi

doc-pointers:
	@"$(DOC_POINTERS)" --root "$(PROJECT_DIR)" --write

doc-pointers-check:
	@"$(DOC_POINTERS)" --root "$(PROJECT_DIR)" --check

install-doc-pointer-hook:
	@"$(DOC_POINTERS)" --root "$(PROJECT_DIR)" --install-hook
