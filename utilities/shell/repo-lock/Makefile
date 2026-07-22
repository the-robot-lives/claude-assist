INSTALL_DIR := $(HOME)/.local/bin

.PHONY: compile test install clean

compile:
	@cargo build --quiet --release --bin repo-lock

test:
	@cargo fmt --check
	@cargo build --quiet
	@cargo test --quiet

install:
	@mkdir -p $(INSTALL_DIR)
	@cargo build --quiet --release --bin repo-lock
	@install -m 755 target/release/repo-lock "$(INSTALL_DIR)/repo-lock"
	@echo "✓ repo-lock → $(INSTALL_DIR)/"

clean:
	@cargo clean
