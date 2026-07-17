# iffywow — orchestrates test/coverage/check across every SDK.
# Each language dir has its own Makefile with the same target names:
#   test, coverage, check, clean  (plus language-specific extras)

LANGS := elixir python rust node go web

.PHONY: help test coverage check clean \
	$(addprefix test-,$(LANGS)) $(addprefix coverage-,$(LANGS)) \
	$(addprefix check-,$(LANGS)) $(addprefix clean-,$(LANGS))

help:
	@echo "iffywow SDK targets:"
	@echo "  make test            run every SDK test suite ($(LANGS))"
	@echo "  make coverage        run every suite with coverage reporting"
	@echo "  make check           fmt + lint + test everywhere"
	@echo "  make clean           remove build/coverage artifacts"
	@echo "  make test-<lang>     single language (e.g. make test-rust)"
	@echo "  make coverage-<lang> single language coverage"

test: $(addprefix test-,$(LANGS))

coverage: $(addprefix coverage-,$(LANGS))

check: $(addprefix check-,$(LANGS))

clean: $(addprefix clean-,$(LANGS))

test-%:
	$(MAKE) -C $* test

coverage-%:
	$(MAKE) -C $* coverage

check-%:
	$(MAKE) -C $* check

clean-%:
	$(MAKE) -C $* clean
