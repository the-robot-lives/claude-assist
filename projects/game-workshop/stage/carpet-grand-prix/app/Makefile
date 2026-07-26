SHELL := /bin/bash

PROJECT   := CarpetGrandPrix.xcodeproj
SCHEME    := CarpetGrandPrix
DESTINATION ?= platform=iOS Simulator,name=iPhone 16 Pro

.PHONY: help generate build test run clean devices lint

help:
	@echo "Carpet Grand Prix — iOS (Swift + Metal)"
	@echo ""
	@echo "  make generate   Regenerate the Xcode project from project.yml"
	@echo "  make build      Build for the simulator"
	@echo "  make test       Run the unit tests"
	@echo "  make run        Build, install and launch on the simulator"
	@echo "  make devices    List available simulator destinations"
	@echo "  make clean      Remove build artefacts and the generated project"
	@echo ""
	@echo "Note: the gyroscope does not exist on the Simulator. The game falls"
	@echo "back to drag-to-steer there; real tilt needs a physical device."

$(PROJECT): project.yml
	@command -v xcodegen >/dev/null 2>&1 || { \
		echo "xcodegen not found. Install it with: brew install xcodegen"; exit 1; }
	xcodegen generate

generate: $(PROJECT)

build: generate
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		CODE_SIGNING_ALLOWED=NO \
		| xcbeautify 2>/dev/null || \
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		CODE_SIGNING_ALLOWED=NO

test: generate
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		CODE_SIGNING_ALLOWED=NO

run: build
	@xcrun simctl boot "$(shell echo '$(DESTINATION)' | sed 's/.*name=//')" 2>/dev/null || true
	@open -a Simulator
	@echo "Launch the app from the Simulator home screen."

devices:
	@xcrun simctl list devices available | grep -E "iPhone|iPad"

clean:
	rm -rf build DerivedData $(PROJECT)
