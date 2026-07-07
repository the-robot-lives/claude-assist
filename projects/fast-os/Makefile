# fast-os phase-0 build. Requires: Rust (rustup.rs), python3.
# `make run` additionally requires QEMU (brew install qemu) —
# not needed when booting via UTM (see docs/utm-setup.md).

KERNEL_ELF := kernel/target/aarch64-unknown-none/release/fast-os-kernel
IMAGE      := kernel/target/aarch64-unknown-none/release/fast-os.img

QEMU    ?= qemu-system-aarch64
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S)-$(UNAME_M),Darwin-arm64)
  ACCEL := -accel hvf -cpu host
else
  ACCEL := -cpu cortex-a72
endif

.PHONY: all build image run clean help

all: image

help:
	@echo "make image   build the bootable kernel image (default; use with UTM)"
	@echo "make run     build + boot in QEMU CLI (exit: Ctrl-a x)"
	@echo "make clean   remove build artifacts"

build:
	cd kernel && cargo build --release

image: build
	python3 tools/elf2image.py $(KERNEL_ELF) $(IMAGE)
	@echo "[fast-os] kernel image for UTM/QEMU: $(abspath $(IMAGE))"

run: image
	$(QEMU) -M virt $(ACCEL) -m 512M -nographic -kernel $(IMAGE)

clean:
	cd kernel && cargo clean
