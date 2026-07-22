SHELL := /bin/bash

PROJECT_ROOT := $(CURDIR)
PORT ?= 4173
HOST ?= 127.0.0.1
PYTHON ?= python3
SWIFT ?= swift
GRADLE ?= gradle
ADB ?= adb
ANDROID_ACTIVITY ?= com.noizu.timely/.MainActivity
MACOS_APP_NAME ?= Timely
MACOS_EXECUTABLE := TimelyMac
MACOS_BUNDLE := $(PROJECT_ROOT)/dist/$(MACOS_APP_NAME).app
MACOS_INFO_PLIST := $(PROJECT_ROOT)/apps/macos/Resources/Info.plist
MACOS_ICON := $(PROJECT_ROOT)/apps/macos/Resources/Timely.icns
INSTALL_DIR ?= /Applications

.DEFAULT_GOAL := help

.PHONY: help
help:
	@printf "\nTimely targets\n"
	@printf "==============\n"
	@printf "  make serve              Serve web app + portal on http://$(HOST):$(PORT)\n"
	@printf "  make open-web-app       Print web app URL\n"
	@printf "  make open-web-portal    Print web portal URL\n"
	@printf "  make build-web          Syntax-check dependency-free web assets\n"
	@printf "  make build-local        Build/check web + Apple surfaces, skip Android\n"
	@printf "  make local-build        Alias that also creates dist/$(MACOS_APP_NAME).app\n"
	@printf "  make build-macos        Build macOS SwiftUI scaffold\n"
	@printf "  make build-macos-app    Build dist/$(MACOS_APP_NAME).app bundle\n"
	@printf "  make run-macos          Run macOS SwiftUI scaffold\n"
	@printf "  make build-osx          Alias for build-macos\n"
	@printf "  make run-osx            Alias for run-macos\n"
	@printf "  make build-ios          Build iOS SwiftUI scaffold with SwiftPM host check\n"
	@printf "  make run-ios            Run iOS companion scaffold with SwiftPM host check\n"
	@printf "  make build-android      Build Android debug APK through Gradle\n"
	@printf "  make install-android    Install Android debug APK through ADB\n"
	@printf "  make run-android        Launch installed Android app through ADB\n"
	@printf "  make install            Install dist/$(MACOS_APP_NAME).app into $(INSTALL_DIR)\n"
	@printf "  make build-all          Build/check every surface that local tools support\n"
	@printf "  make clean              Clean generated local build artifacts\n\n"

.PHONY: serve
serve:
	@printf "Serving Timely from %s on http://%s:%s\n" "$(PROJECT_ROOT)" "$(HOST)" "$(PORT)"
	$(PYTHON) -m http.server $(PORT) --bind $(HOST)

.PHONY: run-web run-web-app run-web-portal run-portal
run-web run-web-app run-web-portal run-portal: serve

.PHONY: open-web-app
open-web-app:
	@printf "http://$(HOST):$(PORT)/apps/web-app/\n"

.PHONY: open-web-portal
open-web-portal:
	@printf "http://$(HOST):$(PORT)/apps/web-portal/\n"

.PHONY: build-web
build-web:
	node --check apps/web-app/assets/app.js
	@printf "Web assets checked.\n"

.PHONY: build-macos
build-macos:
	$(SWIFT) build --package-path apps/macos

.PHONY: build-macos-app
build-macos-app: build-macos
	rm -rf "$(MACOS_BUNDLE)"
	mkdir -p "$(MACOS_BUNDLE)/Contents/MacOS"
	mkdir -p "$(MACOS_BUNDLE)/Contents/Resources"
	cp "$(MACOS_INFO_PLIST)" "$(MACOS_BUNDLE)/Contents/Info.plist"
	cp "$(MACOS_ICON)" "$(MACOS_BUNDLE)/Contents/Resources/Timely.icns"
	cp "apps/macos/.build/debug/$(MACOS_EXECUTABLE)" "$(MACOS_BUNDLE)/Contents/MacOS/$(MACOS_EXECUTABLE)"
	chmod 755 "$(MACOS_BUNDLE)/Contents/MacOS/$(MACOS_EXECUTABLE)"
	@printf "Built %s\n" "$(MACOS_BUNDLE)"

.PHONY: build-osx
build-osx: build-macos

.PHONY: run-macos
run-macos:
	$(SWIFT) run --package-path apps/macos

.PHONY: run-osx
run-osx: run-macos

.PHONY: build-ios
build-ios:
	$(SWIFT) build --package-path apps/ios

.PHONY: run-ios
run-ios:
	@printf "Running the iOS SwiftUI scaffold through SwiftPM's host build path.\n"
	@printf "For a real simulator run, create an Xcode iOS app target from apps/ios/Sources.\n"
	$(SWIFT) run --package-path apps/ios

.PHONY: build-android
build-android:
	$(GRADLE) -p apps/android :app:assembleDebug

.PHONY: install-android
install-android: build-android
	$(ADB) install -r apps/android/app/build/outputs/apk/debug/app-debug.apk

.PHONY: run-android
run-android:
	$(ADB) shell am start -n $(ANDROID_ACTIVITY)

.PHONY: build-apple
build-apple: build-macos build-ios

.PHONY: build-mobile
build-mobile: build-ios build-android

.PHONY: build-local
build-local: build-web build-macos build-ios

.PHONY: local-build
local-build: build-local build-macos-app

.PHONY: build-all
build-all: build-web build-macos build-ios build-android

.PHONY: install install-macos
install install-macos: build-macos-app
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALL_DIR)/$(MACOS_APP_NAME).app"
	ditto "$(MACOS_BUNDLE)" "$(INSTALL_DIR)/$(MACOS_APP_NAME).app"
	@printf "Installed %s\n" "$(INSTALL_DIR)/$(MACOS_APP_NAME).app"

.PHONY: clean
clean:
	$(SWIFT) package --package-path apps/macos clean
	$(SWIFT) package --package-path apps/ios clean
	rm -rf dist
	@printf "Android clean requires a working Gradle install; running best effort.\n"
	-$(GRADLE) -p apps/android clean
