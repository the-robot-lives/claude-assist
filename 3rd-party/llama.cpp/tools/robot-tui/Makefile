# robot-tui — build/run shortcuts.
#
# Runs from anywhere:  make -C <this dir> <target>
# All paths are absolute, so cwd doesn't matter. Override MODEL to use a
# different gguf:  make -C <dir> run MODEL=/path/to/other.gguf

NOIZU := /Users/keithbrings/Work/Space/Infra/Noizu
LLAMA := $(NOIZU)/3rd-party/llama.cpp
BUILD := $(LLAMA)/build
TUI   := $(LLAMA)/tools/robot-tui
BIN   := $(TUI)/target/release/robot-tui
MODEL ?= $(NOIZU)/projects/therobotgguf/convert/work/qwen3.5-0.8b-therobot-L3.gguf

# the Rust build script reads this to locate the prebuilt llama.cpp libs
export ROBOT_LLAMA_BUILD := $(BUILD)

.PHONY: all build shim rebuild clean run log help

all: build ## build the TUI (default)

help: ## list targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | sort

shim: ## rebuild the C sampler/logging shim (robot-ffi)
	cmake --build $(BUILD) --target robot-ffi -j

build: ## build the Rust binary (release)
	cargo build --release --manifest-path $(TUI)/Cargo.toml

rebuild: shim build ## rebuild shim + binary

clean: ## cargo clean (forces bindgen + full recompile)
	cargo clean --manifest-path $(TUI)/Cargo.toml

run: build ## build then launch the TUI
	$(BIN) -m $(MODEL)

log: ## tail the redirected llama/ggml log
	tail -f $(TUI)/robot-tui.log
