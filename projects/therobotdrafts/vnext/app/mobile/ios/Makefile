SHELL := /bin/bash

PROJECT := RobotDrafts.xcodeproj
SCHEME := RobotDrafts
DESTINATION ?= generic/platform=iOS Simulator

.PHONY: help generate build test clean devices

help:
	@echo "The Robot Draft - iPhone/iPad"
	@echo ""
	@echo "  make generate   Regenerate the Xcode project from project.yml"
	@echo "  make build      Build for the simulator"
	@echo "  make test       Run unit tests"
	@echo "  make devices    List available simulator destinations"
	@echo "  make clean      Remove generated build state"

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
		CODE_SIGNING_ALLOWED=NO

test: generate
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		CODE_SIGNING_ALLOWED=NO

devices:
	xcrun simctl list devices available | grep -E "iPhone|iPad"

clean:
	rm -rf build DerivedData $(PROJECT)
