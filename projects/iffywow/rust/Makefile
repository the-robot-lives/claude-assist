# iffywow Rust SDK — test/coverage instrumentation.
# Coverage via cargo-llvm-cov (install once: cargo install cargo-llvm-cov).

.PHONY: test coverage coverage-html coverage-lcov lint fmt check clean

test:
	cargo test

coverage:
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		{ echo "cargo-llvm-cov not installed — run: cargo install cargo-llvm-cov"; exit 1; }
	cargo llvm-cov --summary-only

coverage-html:
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		{ echo "cargo-llvm-cov not installed — run: cargo install cargo-llvm-cov"; exit 1; }
	cargo llvm-cov --html
	@echo "open target/llvm-cov/html/index.html"

coverage-lcov:
	@command -v cargo-llvm-cov >/dev/null 2>&1 || \
		{ echo "cargo-llvm-cov not installed — run: cargo install cargo-llvm-cov"; exit 1; }
	cargo llvm-cov --lcov --output-path coverage.lcov

lint:
	cargo clippy --all-targets -- -D warnings

fmt:
	cargo fmt --check

check: fmt lint test

clean:
	cargo clean
	rm -f coverage.lcov
