# The Robot Draft — build / run / test
#
# Unity has no native `make`; these targets wrap the editor's batch-mode entry points and the
# `build-mac.sh` wrapper so the project fits the monorepo's make-driven convention.
#
#   make build   # headless macOS .app  -> Builds/macOS/The Robot Draft.app
#   make run     # build if needed, then open the .app
#   make test    # run the EditMode test suite headless
#   make open    # open the existing build without rebuilding
#   make clean   # remove Builds/ and test results
#   make doctor  # report the editor that will be used and whether Mac Build Support is present
#
# Requires a local Unity editor matching ProjectSettings/ProjectVersion.txt (Mac Build Support is
# needed for `build`/`run`, not for `test`). Install via Unity Hub.

PROJECT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
HUB         := /Applications/Unity/Hub/Editor
APP_NAME    := The Robot Draft.app
APP_PATH    := $(PROJECT_DIR)/Builds/macOS/$(APP_NAME)
PIN         := $(shell awk -F': *' '/^m_EditorVersion:/{print $$2}' "$(PROJECT_DIR)/ProjectSettings/ProjectVersion.txt")

# Editor for tests: prefer the pinned version, else the newest installed (Mac module not required).
TEST_EDITOR := $(firstword \
  $(wildcard $(HUB)/$(PIN)/Unity.app/Contents/MacOS/Unity) \
  $(shell ls -dt $(HUB)/*/Unity.app/Contents/MacOS/Unity 2>/dev/null | head -n1))

.PHONY: build run open test clean doctor help

help:
	@echo "The Robot Draft — make targets:"
	@echo "  build   headless macOS .app  -> Builds/macOS/$(APP_NAME)"
	@echo "  run     build if needed, then open the app"
	@echo "  open    open the existing build (no rebuild)"
	@echo "  test    run the EditMode test suite headless"
	@echo "  clean   remove Builds/ and test results"
	@echo "  doctor  show the editor that will be used"
	@echo ""
	@echo "  pinned editor: $(PIN)"

build:
	@"$(PROJECT_DIR)/build-mac.sh"

run: $(APP_PATH)
	@open "$(APP_PATH)"

# Build only if the app is missing; `make build` forces a rebuild.
$(APP_PATH):
	@"$(PROJECT_DIR)/build-mac.sh"

open:
	@test -d "$(APP_PATH)" || { echo "No build yet — run 'make build' first." >&2; exit 1; }
	@open "$(APP_PATH)"

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
