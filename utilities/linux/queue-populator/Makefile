.PHONY: compile test install clean

UNAME_S := $(shell uname -s)

compile:
ifeq ($(UNAME_S),Linux)
	cargo build --release
else
	@echo "queue-populator: skipped on $(UNAME_S) (Linux-only PipeWire utility)"
endif

test:
ifeq ($(UNAME_S),Linux)
	cargo test
else
	@echo "queue-populator: tests skipped on $(UNAME_S) (Linux-only PipeWire utility)"
endif

install:
ifeq ($(UNAME_S),Linux)
	./install.sh
else
	@echo "queue-populator: install skipped on $(UNAME_S) (Linux-only PipeWire utility)"
endif

clean:
	cargo clean
