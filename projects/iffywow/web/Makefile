# iffywow web component — test/coverage instrumentation.
# Node's built-in runner covers the pure modules (coordinate, scene, util,
# registry). The Lit element + metadata extraction need a DOM — exercise those
# via `make serve` and the demo page's built-in round-trip verifier.

NODE ?= node

.PHONY: test coverage serve check clean

test:
	$(NODE) --test test/

coverage:
	$(NODE) --test --experimental-test-coverage test/

serve:
	@echo "open http://localhost:8080/demo/"
	python3 -m http.server 8080

check: test

clean:
	rm -rf coverage
